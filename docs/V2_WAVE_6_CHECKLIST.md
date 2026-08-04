# Wave 6 — Cross-Account DnD Copy Checklist

> **Status:** **E10 GO** (2026-08-04) — P0–P3 landed; Renee QA **659/659**; Page inventory refreshed. **Awaiting E11** operator dogfood. Parent plan: [V2_PLAN.md](V2_PLAN.md). Prior: [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md) (**complete**). Design: [V2_WAVE_6_TESLA_DESIGN.md](V2_WAVE_6_TESLA_DESIGN.md). QA: [V2_WAVE_6_QA.md](V2_WAVE_6_QA.md).

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
                         → Wave 6b: CalDAV/CardDAV write (copy targets)
                         → Wave 6c: recurring event copy semantics
                         → Wave 7: Trish extras (last)
```

## Locked product decisions (Trish, 2026-08-04)

| # | Decision |
| --- | --- |
| W6-1 | **Local duplicate first** — copy creates a new Drift row under target account + calendar/list; remote push is async via sync jobs |
| W6-2 | **Desktop:** drag source → drop target (calendar lane / contact list). **Mobile:** long-press → bottom sheet picker (“Copy to calendar…” / “Copy to list…”) |
| W6-3 | Job types **`events_copy`** and **`contacts_copy`** already reserved in [pim_sync_jobs.dart](../lib/sync/pim_sync_jobs.dart); [SyncEngine](../lib/sync/sync_engine.dart) handlers are **no-ops today** |
| W6-4 | **Same UX** for events and contacts — shared picker/sheet patterns where sensible |
| W6-5 | **Out of Wave 6 MVP:** recurring series/instance semantics → **Wave 6c**; organizer/meeting copy rules; event attachments; mail cross-account copy |
| W6-6 | **D1 locked:** Graph + Google create/push **in MVP**. DAV-as-target = **local duplicate only** + honest “not synced yet” UI until **Wave 6b** CalDAV/CardDAV write |
| W6-7 | **Wave 6b** = CalDAV/CardDAV **create-only** write for copy targets (~8–12 eng-days); full update/delete push may extend 6b or trail |
| W6-8 | **Wave 6c** = recurring **event** series/instance copy semantics (this occurrence vs series vs expand-and-copy) — after 6 + 6b so create paths exist on all providers |
| W6-9 | **Corporate Graph / microsoft.com** work accounts = **post–Wave 6** research → incremental version (not 6 / 6b / 6c) |

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
| [dav_pim_provider.dart](../lib/protocol/dav_pim_provider.dart) | **Read-only** CardDAV/CalDAV | Wave 6: local-only target + label; **Wave 6b:** PUT create |
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
| **D1** | **Provider matrix** — Graph↔Graph / Graph↔Google / Google↔Google MVP; DAV → Wave 6b | **Locked** 2026-08-04 — § Provider matrix |
| **D2** | **Job payload schema** — `events_copy` / `contacts_copy` JSON in job metadata (source id, target accountId, target collection id, optional field overrides) | **Done** — [V2_WAVE_6_TESLA_DESIGN.md](V2_WAVE_6_TESLA_DESIGN.md) § D2 (`localEventId` / `localContactId` + target collection ids; DAV = no enqueue) |
| **D3** | **Provider create APIs** — Graph POST event/contact; Google Calendar + People insert; error mapping → BLoC | **Done** — design § D3 (`createEvent` / `createContact` → `PimRemoteCreateResult`; ProtocolException / GraphAuthException → job failed) |
| **D4** | **Idempotency** — new local `providerId` on copy; map remote id on push success; retry-safe | **Done** — design § D4 (`local:{uuid}` → in-place rewrite; skip `local:*` on full-pull soft-delete) |

### P1 — Data plane (Tesla + Jules)

| ID | Task | Exit |
| --- | --- | --- |
| **E1** | `DriftPimStore.duplicateEventToCalendar` — clone event + attendees (strip organizer-only fields per W6-5) | **Done** (Tesla) — strips RRULE; attendees `isOrganizer: false`; `test/pim_store_test.dart` |
| **E2** | `DriftPimStore.createLocalContact` + `duplicateContactToList` — emails/phones copied | **Done** (Tesla) — + `rewrite*ProviderId` / `getEvent`/`getContact` |
| **E3** | `SyncEngine` `_handleCopyEvent` / `_handleCopyContact` — resolve provider, POST, upsert returned providerId | **Done** (Tesla) — Graph/Google create; DAV no-op; `local:*` soft-delete guard; `test/pim_copy_sync_engine_test.dart` |
| **E4** | Enqueue copy jobs from cubit/service layer; surface copy-in-progress / error in UI state | **Partial** — [`PimCopyService`](../lib/sync/pim_copy_service.dart) ready for Jules; cubit/DnD UI + sync-sheet copy labels → P2 |

### P2 — Desktop DnD (Jules + Andi)

| ID | Task | Exit |
| --- | --- | --- |
| **E5** | Calendar: draggable event in month/week/agenda; drop targets on calendar lanes (respect `isSelectedForDisplay`) | **Done** (widget tests) — Windows manual → E11 |
| **E6** | People: draggable contact row; drop on contact list header/lane | **Done** (widget tests) — Windows manual → E11 |
| **E7** | Cross-account visual feedback — drag avatar, invalid-target affordance, undo snackbar optional | **Done** (lanes + reject affordance + event Undo) — E11 polish OK |

### P3 — Mobile fallback (Andi)

| ID | Task | Exit |
| --- | --- | --- |
| **E8** | Event long-press → “Copy to calendar…” sheet (account + calendar picker) | **Done** (widget tests) — Android manual → E11 |
| **E9** | Contact long-press → “Copy to list…” sheet | **Done** (widget tests) — Android manual → E11 |

### P4 — QA & docs (Renee + Page)

| ID | Task | Exit |
| --- | --- | --- |
| **E10** | Renee QA pass — [V2_WAVE_6_QA.md](V2_WAVE_6_QA.md) (**GO** / NO-GO) | **GO** — **659/659**; Page inventory refreshed |
| **E11** | Operator dogfood — Trish cross-account copy on principal Google + Graph calendars/contacts | Pending — matrix in QA doc |

## Provider matrix (D1 — **locked** 2026-08-04)

| Source \ Target | Graph | Google | DAV (Runbox) |
| --- | --- | --- | --- |
| **Graph** | ✅ MVP | ✅ MVP | ⏸ Wave 6b (local-only + label in Wave 6) |
| **Google** | ✅ MVP | ✅ MVP | ⏸ Wave 6b (local-only + label in Wave 6) |
| **DAV** | ⏸ Wave 6b | ⏸ Wave 6b | ⏸ Wave 6b |

> Wave 6 ships Graph ↔ Google remote push. DAV-as-target: **local duplicate only** + honest UI until Wave 6b write-back.

## Exit criteria (wave complete)

- [ ] Copy event from account A calendar → account B calendar: appears locally immediately; remote push completes async
- [ ] Copy contact from list A → list B (cross-account): same pattern
- [ ] Desktop DnD works on Windows for events + contacts
- [ ] Mobile long-press copy sheet works on Android
- [ ] No network calls from widgets — all via repository + sync jobs
- [x] Renee **GO** + Page test inventory updated
- [ ] Trish operator **GO** on E11 dogfood
- [ ] [V2_PLAN.md](V2_PLAN.md) §14 exit checkbox for cross-account copy checked

## Explicitly out of Wave 6

| Item | Disposition |
| --- | --- |
| **Calendar series / recurring event copy** (this occurrence vs series vs expand) | **Wave 6c** — not a Tasks module |
| CalDAV/CardDAV write (create for copy targets) | **Wave 6b** |
| Organizer meeting / attendee re-invite on copy | Later / Wave 6c+ if needed |
| Event attachments on copy | Later |
| Mail message / folder cross-account copy | Not PIM Wave 6 |
| `events_push` / `contacts_push` for local CRUD edits | Separate CRUD wave if needed |
| Corporate Graph (`microsoft.com` / Entra org tenants) | **Post–Wave 6** research → incremental version |

## Follow-on waves (locked sequencing)

### Wave 6b — CalDAV/CardDAV write (copy targets)

| Item | Notes |
| --- | --- |
| Scope | Create-only PUT for events + contacts when DAV is the **copy target**; rewrite `providerId`/etag; guard unpushed `local:*` from full-pull soft-delete |
| LOE | ~8–12 eng-days (Tesla-heavy) |
| Depends on | Wave 6 copy UX + job plumbing |
| Out | Full update/delete push (may trail 6b); free/busy; ACLs |

### Wave 6c — Calendar series / recurring event copy semantics

| Item | Notes |
| --- | --- |
| Scope | Copy UX for **recurring calendar events** (RRULE / series-master vs instance): this occurrence · entire series · copy-as-new independent series. Graph `seriesMaster`/occurrence, Google `recurringEventId`, DAV RRULE fidelity. |
| Why **6c** (not fold into 6b) | Non-trivial LOE — cross-provider identity, exception instances, UX disambiguation, and create-path differences. Fold into 6b only if a later spike shows ≤2 eng-days after 6b create lands. |
| Depends on | Wave 6 (+ preferably 6b so DAV series copy can push) |
| Not in scope | A separate **Tasks** module — “recurring” here means **calendar series only**. If Synesis ever ships tasks, they are **Maybe/Someday / V-Next**: a **basic local to-do list** whose agenda can also show calendar items (“stop for bread and eggs”) — **not** a productivity system; that stays **Phronesis**. **Voice / assistant capture** (in-car; Gemini / Siri / peers) is **V-SometimeSoonish** and pairs with that Tasks surface if it lands — not Wave 6/6c. |

### Post–Wave 6 — Corporate Graph research (incremental version)

| Item | Notes |
| --- | --- |
| Scope | Research spike for **work/school Graph** accounts (e.g. `microsoft.com`, Entra org tenants): admin consent, publisher verification, tenant policies, Conditional Access, shared mailboxes if needed |
| Timing | **After** Wave 6 family; **not** 6 / 6b / 6c |
| Disposition | Stub for an **incremental version** plan (likely V2.x); Page opens research brief when operator prioritizes |

## Phase-gate routing

```text
(1) Discovery  — Steve + Page context; Tesla D2–D4 design (D1 locked)
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
| [V2_WAVE_6_TESLA_DESIGN.md](V2_WAVE_6_TESLA_DESIGN.md) | Tesla D2–D4 job payload, create APIs, idempotency, soft-delete race |
| [V2_WAVE_6_QA.md](V2_WAVE_6_QA.md) | Renee E10 QA — **GO** (2026-08-04) |
| [DEFECTS.md](../DEFECTS.md) | New defects logged during implementation |

---

*Planning opened 2026-08-04 after Wave 6P exit (`6b0f3d7`, **645 tests**). **D1 locked** (Graph + Google MVP; DAV → 6b). Tesla design signed 2026-08-04. P0–P3 landed; **E10 GO** at **659 tests** (2026-08-04). Page inventory refreshed; **awaiting E11** operator dogfood for wave exit.*
