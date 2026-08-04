# Wave 6 — Renee QA (Cross-Account DnD Copy)

> **Status:** **E10 complete — GO** (2026-08-04). Checklist: [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md). Design: [V2_WAVE_6_TESLA_DESIGN.md](V2_WAVE_6_TESLA_DESIGN.md).

| Field | Value |
| --- | --- |
| Reviewed | 2026-08-04 |
| Commits under review | `5fd3ca9` (Tesla P0/P1) · `772085f` (Andi P3 + P2 wiring) · `fca71e9` (Jules P2 DnD tests) · E10 fix commit (this gate) |
| Prior gate | Wave 6P exit (**645** tests) |
| Tests | **659/659 passed** (`flutter test`, Renee E10) |
| Verdict | **GO** Wave 6 engineering exit · **Ready for E11** operator dogfood |
| Operator dogfood (E11) | — (pending Trish) |

---

## Verdict

| Gate | Decision | Notes |
| --- | --- | --- |
| Local-first copy (store + enqueue) | **Pass** | `PimCopyService` duplicates in Drift then enqueues; cubits/widgets never call provider create APIs. |
| Graph / Google remote push | **Pass** | SyncEngine `_copyEvent` / `_copyContact` POST + in-place `rewrite*ProviderId`; idempotent when already remote. |
| DAV target honesty | **Pass** | No enqueue for `DavPimProvider`; snackbar + sheet subtitle “Local only — not synced yet”. |
| Soft-delete guard for `local:*` | **Pass** | Full-snapshot missing soft-delete skips `PimIds.isLocalProviderId`. |
| Undo before push | **Pass** (fixed E10) | Soft-deleted local rows are skipped by copy handlers (no remote create after Undo). |
| Desktop DnD | **Pass** (automated) | Widget tests for event + contact lane drops; Windows manual → E11. |
| Mobile copy sheets | **Pass** (automated) | Long-press → picker → copy; Android manual → E11. |
| Full regression | **Pass** | **659/659**. Net **+14** vs Wave 6P (645). |
| Wave 6 engineering exit (E10) | **GO** | No Pri-1 / data-safety blockers. |
| E11 dogfood handoff | **Ready** | See matrix below. |

No Pri-1 defects. Nothing added to `DEFECTS.md` for this wave.

---

## Scope under test

| Area | Result | Evidence |
| --- | --- | --- |
| Event copy local duplicate | Pass | `duplicateEventToCalendar` strips RRULE; attendees `isOrganizer: false`; `local:{uuid}` |
| Contact copy local duplicate | Pass | emails/phones copied via `createLocalContact` |
| `events_copy` / `contacts_copy` handlers | Pass | Graph MockClient POST + rewrite; DAV handler no-op; missing payload soft no-op |
| Idempotent rewrite | Pass | Already-remote `providerId` → no second POST |
| Soft-deleted skip (Undo) | Pass | E10: `deletedAt != null` → no POST (+ new unit test) |
| Full-pull preserves unpushed copies | Pass | Google-style missing soft-delete skips `local:*` |
| DAV no-enqueue | Pass | `PimCopyService` + sync-engine test |
| Desktop DnD | Pass | `pim_desktop_dnd_test.dart` (calendar + people) |
| Mobile sheets | Pass | `pim_copy_target_sheet_test.dart` |
| No network from widgets | Pass | UI → cubit → `PimCopyService` → job store; kick only after enqueue |
| Cross-account / cross-list | Pass | Fixture accounts A→B in DnD + sheet + service tests |
| Series / attachments / meeting re-invite | Out of scope | Wave 6c / later (W6-5) |

---

## Defensive review findings

| Gap | Severity | Disposition |
| --- | --- | --- |
| Undo snackbar soft-deleted copy while `events_copy` still pending → remote create | **Fixed E10** | Handlers skip `deletedAt != null`; test added. Contact snackbar has no Undo (N/A). |
| Create succeeded, rewrite crashed → retry may POST a second remote object | Medium — accepted MVP | Documented Tesla D4; mitigate by rewrite in same try (already adjacent). |
| Sync status sheet shows raw `events_copy` / `contacts_copy` type strings | Low | Polish later; jobs still visible and retryable. |
| Contact copy snackbar lacks Undo (events have it) | Low | Optional parity; not required for MVP. |
| Sheet `remotePushSupportedForAccount` resolves PIM provider (token/secure storage) per account | Info | Not a create/network from UI; acceptable for honesty labels. |
| Same-calendar / same-list drop rejected | Pass | `isValid*DropTarget` requires different collection id + selected-for-display. |
| Attendees held locally but omitted from Graph/Google POST | Pass / intentional | Avoids invite fan-out (W6-5). |
| RRULE stripped on copy | Pass / intentional | Wave 6c. |

---

## Checklist matrix (engineering)

| Requirement | Status | Evidence |
| --- | --- | --- |
| Copy event A→B appears locally immediately; push async (Graph/Google) | Pass (auto) | Store + service + engine tests; E11 confirms live |
| Copy contact list A→B same pattern | Pass (auto) | Same |
| Desktop DnD Windows | Pass (auto) / E11 manual | Widget tests green |
| Mobile long-press Android | Pass (auto) / E11 manual | Sheet tests green |
| No network from widgets | Pass | Code review + architecture |
| Renee GO + Page inventory | **GO** / **Done** | This doc + [TEST_INVENTORY.md](TEST_INVENTORY.md) (**659 cases**) |
| Trish E11 dogfood | Pending | Matrix below |
| V2_PLAN §14 exit checkbox | Hold for Steve after E11 | — |

---

## Operator dogfood matrix (E11 — Trish)

| # | Scenario | Expect |
| --- | --- | --- |
| 1 | Graph → Graph: drag event to other calendar | Local chip immediately; Sync sheet shows `events_copy` → done; remote calendar gains event |
| 2 | Graph → Google (or reverse): copy event | Same; verify both providers |
| 3 | Google → Google: copy contact across lists | Local row + `contacts_copy` → remote |
| 4 | Any → DAV (Runbox): copy event or contact | Local only; snackbar/sheet “not synced yet”; **no** copy job enqueued |
| 5 | Desktop Windows: invalid drop (source calendar / hidden) | Rejected affordance; no duplicate |
| 6 | Mobile Android: long-press → Copy to… | Sheet lists targets with DAV “Local only” subtitle |
| 7 | Undo event copy quickly after Graph target drop | Local row gone; **no** orphan remote event |
| 8 | Recurring source event | Copied as single independent event (no series) — expected |

**Ready for Trish E11?** **Yes** — engineering GO; live Graph↔Google + Windows/Android UX confirmation remains.

---

## Test delta (Renee → Page)

Baseline Wave 6P: **645**. E10 suite: **659** (+14).

| Path | Cases (names) | Kind | Maps to | Change |
| --- | --- | --- | --- | --- |
| `test/pim_copy_sync_engine_test.dart` | `events_copy POSTs Graph create and rewrites providerId`; `contacts_copy POSTs Graph create and rewrites providerId`; `events_copy is idempotent when providerId already remote`; `events_copy skips soft-deleted local row (undo before push)`; `enqueues events_copy for Graph target`; `does not enqueue for DAV target`; `Google-style missing soft-delete skips local provider ids` | unit/integration | Wave 6 P1 + E10 | **New** (7) |
| `test/pim_store_test.dart` | `duplicateEventToCalendar clones fields, strips rrule, attendees`; `createLocalContact + duplicateContactToList copies emails/phones`; `rewriteEventProviderId keeps local id stable` | unit | Wave 6 P1 store | **+3** (Wave 6 group) |
| `test/pim_desktop_dnd_test.dart` | `drag event chip onto lane drop copies locally`; `drag contact row onto list lane copies locally` | widget | Wave 6 P2 | **New** (2) |
| `test/pim_copy_target_sheet_test.dart` | `event long-press opens Copy to calendar sheet and copies`; `contact long-press opens Copy to list sheet and copies` | widget | Wave 6 P3 | **New** (2) |
| `test/pim_sync_jobs_noop_test.dart` | registered PIM job types include copy (existing suite; copy no longer pure no-op with payload) | unit | Wave 6 job registry | **Touched** (0 net cases) |

Regenerate or patch `docs/V1_AUTOMATED_TEST_INVENTORY.csv` via `tool/generate_test_inventory.py` (Page).

---

## Explicitly out of scope (confirmed)

- CalDAV/CardDAV write (**Wave 6b**)
- Recurring series/instance copy UX (**Wave 6c**)
- Organizer/meeting re-invite on copy; event attachments
- Mail cross-account copy
- Corporate Graph / Entra org tenants (post–Wave 6 research)

---

*E10 closed 2026-08-04 by Renee. Page inventory refreshed 2026-08-04. Handoff: Steve E11 operator sign-off.*
