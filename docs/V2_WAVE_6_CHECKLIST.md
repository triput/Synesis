# Wave 6 — Cross-Account DnD Copy Checklist

> **Status:** **Planning** (2026-08-04) — discovery open; implementation **not started**. **645 tests** at Wave 6P exit. Parent plan: [V2_PLAN.md](V2_PLAN.md). Prior: [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md) (**complete**).

Wave 6 delivers **cross-account / cross-list copy** for **calendar events** and **contacts** — Outlook-style drag-and-drop on desktop, long-press → “Copy to…” sheet on mobile. Pattern is **local-first**: duplicate row in SQLite under the target account/collection, then enqueue **`events_copy`** / **`contacts_copy`** sync jobs for remote push. UI never blocks on network.

**Owners:** Jules + Andi (UI / cubits) · Tesla (SyncEngine handlers, provider create APIs) · Renee (QA) · Page (docs + test inventory).

## Sequence

```text
Wave 0 ✅ → Wave H ✅ → Wave 1 (P0) ✅
                         → Wave 2: Graph PIM (P1) ✅
                         → Wave 3: meeting-mail bridge (P2) ✅
                         → Wave 4: CardDAV/CalDAV (P3–P4) ✅
                         → Wave 5: picker + Calendar UI (P5–P6) ✅
                         → Wave G: Google People + Calendar API ✅
                         → Wave 6P: Performance UX (Sync Honesty) ✅
                         → ★ Wave 6: cross-account DnD copy ← active
                         → Wave 7: Trish extras (last)
```

## Locked product decisions (V2 plan — reaffirm at kickoff)

| # | Decision |
| --- | --- |
| W6-1 | **Local duplicate first** — copy creates a new Drift row under target account + calendar/list; remote push is async via sync jobs |
| W6-2 | **Desktop:** drag source → drop target (calendar lane / contact list). **Mobile:** long-press → bottom sheet picker (“Copy to calendar…” / “Copy to list…”) |
| W6-3 | Job types **`events_copy`** and **`contacts_copy`** already reserved in [pim_sync_jobs.dart](../lib/sync/pim_sync_jobs.dart); [SyncEngine](../lib/sync/sync_engine.dart) handlers are **no-ops today** |
| W6-4 | **Same UX** for events and contacts — shared picker/sheet patterns where sensible |
| W6-5 | **Out of Wave 6 MVP:** recurring series instance semantics, organizer/meeting copy rules, event attachments, mail cross-account copy |
| W6-6 | **Provider matrix (discovery gate D1):** Graph + Google create paths are **in scope**; CardDAV/CalDAV targets are **read-only today** — Tesla proposes write-back scope vs local-only target for Runbox |

## Discovery map (Steve — 2026-08-04)

| Area | Current state | Wave 6 touch |
| --- | --- | --- |
| [sync_engine.dart](../lib/sync/sync_engine.dart) | `contactsCopy` / `eventsCopy` → `return null` | Implement `_copyContact` / `_copyEvent` handlers |
| [drift_pim_store.dart](../lib/repository/drift/drift_pim_store.dart) | `createLocalEvent`, `upsertContacts` | Add **`createLocalContact`** + **`duplicateEventToCalendar`** / **`duplicateContactToList`** helpers |
| [calendar_cubit.dart](../lib/ui/calendar/calendar_cubit.dart) | Local CRUD; **no push** on create | Wire copy → store duplicate + `enqueueSyncJob(events_copy)` |
| [calendar_workspace.dart](../lib/ui/calendar/calendar_workspace.dart) | Month/week views; no DnD | `Draggable` event chips + `DragTarget` on calendar lanes |
| [people_workspace.dart](../lib/ui/people/people_workspace.dart) | List/detail; no DnD | `Draggable` contact rows + list drop targets / mobile sheet |
| [graph_pim_provider.dart](../lib/protocol/graph_pim_provider.dart) | Read sync + RSVP; `_postObject` exists | Tesla: `createEvent` / `createContact` POST payloads |
| [google_pim_provider.dart](../lib/protocol/google_pim_provider.dart) | Read sync | Tesla: Calendar Events.insert + People createContact |
| [dav_pim_provider.dart](../lib/protocol/dav_pim_provider.dart) | **Read-only** CardDAV/CalDAV | D1: write-back spike or defer DAV-as-target |
| Mail sidebar | [folder_sidebar.dart](../lib/ui/shell/folder_sidebar.dart) long-press pattern | Reuse context-menu / sheet patterns for mobile copy |

## Slices

| Slice | Goal | Owner(s) | Gate |
| --- | --- | --- | --- |
| **P0** | Discovery + Tesla integration design (job payload, provider matrix, store API) | Steve + Tesla | **Required** — D1–D4 |
| **P1** | Data plane — store copy helpers + SyncEngine copy handlers | Tesla → Jules | Required — E1–E4 |
| **P2** | Desktop DnD — Calendar + People workspaces | Jules + Andi | Required — E5–E7 |
| **P3** | Mobile copy sheet — long-press fallback | Andi | Required — E8–E9 |
| **P4** | Renee QA + Page docs + operator dogfood | Renee + Page | Wave exit — E10–E11 |

## Work breakdown

### P0 — Discovery & design (Tesla)

| ID | Task | Exit |
| --- | --- | --- |
| **D1** | **Provider matrix** — document which source→target pairs ship in MVP (Graph↔Graph, Graph↔Google, Google↔Google; DAV target TBD) | Written in this checklist § Provider matrix |
| **D2** | **Job payload schema** — `events_copy` / `contacts_copy` JSON in job metadata (source id, target accountId, target collection id, optional field overrides) | Draft in Tesla design note or inline here |
| **D3** | **Provider create APIs** — Graph POST event/contact; Google Calendar + People insert; error mapping → BLoC | API surface list + failure modes |
| **D4** | **Idempotency** — new local `providerId` on copy; map remote id on push success; retry-safe | Design signed by Tesla |

### P1 — Data plane (Tesla + Jules)

| ID | Task | Exit |
| --- | --- | --- |
| **E1** | `DriftPimStore.duplicateEventToCalendar` — clone event + attendees (strip organizer-only fields per W6-5) | Unit tests |
| **E2** | `DriftPimStore.createLocalContact` + `duplicateContactToList` — emails/phones copied | Unit tests |
| **E3** | `SyncEngine` `_handleCopyEvent` / `_handleCopyContact` — resolve provider, POST, upsert returned providerId | Integration tests with fakes |
| **E4** | Enqueue copy jobs from cubit/service layer; surface copy-in-progress / error in UI state | Jobs visible in sync sheet |

### P2 — Desktop DnD (Jules + Andi)

| ID | Task | Exit |
| --- | --- | --- |
| **E5** | Calendar: draggable event in month/week/agenda; drop targets on calendar lanes (respect `isSelectedForDisplay`) | Widget tests + Windows manual |
| **E6** | People: draggable contact row; drop on contact list header/lane | Widget tests + Windows manual |
| **E7** | Cross-account visual feedback — drag avatar, invalid-target affordance, undo snackbar optional | Operator acceptable |

### P3 — Mobile fallback (Andi)

| ID | Task | Exit |
| --- | --- | --- |
| **E8** | Event long-press → “Copy to calendar…” sheet (account + calendar picker) | Android manual |
| **E9** | Contact long-press → “Copy to list…” sheet | Android manual |

### P4 — QA & docs (Renee + Page)

| ID | Task | Exit |
| --- | --- | --- |
| **E10** | Renee QA pass — [V2_WAVE_6_QA.md](V2_WAVE_6_QA.md) (**GO** / NO-GO) | Test delta → Page inventory |
| **E11** | Operator dogfood — Trish cross-account copy on principal Google + Graph calendars/contacts | **GO** logged in QA doc |

## Provider matrix (D1 — draft pending Tesla sign-off)

| Source \ Target | Graph | Google | DAV (Runbox) |
| --- | --- | --- | --- |
| **Graph** | ✅ MVP | ✅ MVP | ⏸ D1 — needs CalDAV/CardDAV write |
| **Google** | ✅ MVP | ✅ MVP | ⏸ D1 |
| **DAV** | ⏸ D1 | ⏸ D1 | ⏸ D1 |

> **Default proposal:** Ship Graph + Google remote push in P1; DAV-as-target creates **local duplicate only** with sync job no-op + honest UI label until write-back lands (or a thin Wave 6b if Trish pulls DAV write forward).

## Exit criteria (wave complete)

- [ ] Copy event from account A calendar → account B calendar: appears locally immediately; remote push completes async
- [ ] Copy contact from list A → list B (cross-account): same pattern
- [ ] Desktop DnD works on Windows for events + contacts
- [ ] Mobile long-press copy sheet works on Android
- [ ] No network calls from widgets — all via repository + sync jobs
- [ ] Renee **GO** + Page test inventory updated
- [ ] Trish operator **GO** on E11 dogfood
- [ ] [V2_PLAN.md](V2_PLAN.md) §14 exit checkbox for cross-account copy checked

## Explicitly out of Wave 6

| Item | Disposition |
| --- | --- |
| Recurring event instance copy semantics | Later UX / Wave 7+ |
| Organizer meeting / attendee re-invite on copy | Later |
| Event attachments on copy | Later |
| Mail message / folder cross-account copy | Not PIM Wave 6 |
| Full CalDAV/CardDAV write-back (unless D1 pulls in) | Wave 6b or post-V2.0 |
| `events_push` / `contacts_push` for local CRUD edits | Separate CRUD wave if needed |

## Phase-gate routing

```text
(1) Discovery  — Steve + Page context; Tesla D1–D4 design
(2) Implement  — Tesla P1 → Jules/Andi P2–P3
(3) Quality    — Renee E10
(4) Docs       — Page inventory + V2_PLAN/ROADMAP
(5) Delivery   — Steve E11 operator sign-off
```

## Related docs

| Doc | Purpose |
| --- | --- |
| [V2_PLAN.md](V2_PLAN.md) | Parent plan §3 events/contacts copy |
| [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md) | Prior wave (complete) |
| [V2_WAVE_6_QA.md](V2_WAVE_6_QA.md) | Renee QA stub — create at P4 |
| [DEFECTS.md](../DEFECTS.md) | New defects logged during implementation |

---

*Planning opened 2026-08-04 after Wave 6P exit (`6b0f3d7`, **645 tests**). Implementation starts after operator approves D1 provider matrix.*
