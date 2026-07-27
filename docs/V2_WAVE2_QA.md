# Wave 2 / V2.0a P1 — Renee QA notes

| Field | Value |
| --- | --- |
| Reviewed | 2026-07-27 |
| Commits | `eac846c` (scopes + display-pref preserve + stable ids) → `b526e70` (Graph PIM provider + SyncEngine handlers) |
| Checklist | [V2_WAVE2_CHECKLIST.md](V2_WAVE2_CHECKLIST.md) |
| Prior constraints | [V2_0A_P0_QA.md](V2_0A_P0_QA.md) §Wave 2 |
| Tests | **530** green (Tesla report) |
| Verdict | **GO** Wave 2 exit · **GO** Wave 3 handoff |

Review is checklist + P0-QA constraint audit against `b526e70` (on top of `eac846c`). No Wave 3 implementation.

---

## Verdict

| Gate | Decision | Notes |
| --- | --- | --- |
| **Wave 2 exit** | **GO** | Graph contacts + calendars bootstrap/incremental operational; OAuth scopes + re-consent docs; display prefs preserved; stable ids; push/copy remain no-op; mail path additive-only. |
| **Wave 3 handoff** (meeting-mail bridge) | **GO** | Unblocked. Wave 3 owns ICS / accept-decline; must not regress Graph mail or PIM read sync. |
| Wave 4+ | N/A | CardDAV/CalDAV, Calendar/People UI, DnD copy correctly deferred. |

No Pri-1 / data-safety blockers for P1 Graph read sync.

---

## Checklist matrix

| Requirement | Status | Evidence |
| --- | --- | --- |
| `Contacts.Read` + `Calendars.Read` in OAuth | Pass | `GraphAuthConfig.scopes`; `test/oauth_identity_manager_test.dart` |
| Entra / operator docs | Pass | README Entra section + re-consent note; QUICK_START |
| Re-consent path (existing accounts) | Pass* | Docs require re-sign-in; `updateGraphCredentials` enqueues PIM bootstrap; insufficient-scope calls fail the job (not silent success). *No in-app “missing PIM scope” detector — residual below. |
| New Graph account → PIM bootstrap | Pass | `AccountService.addGraphAccount` → `_enqueueGraphPimBootstrap`; `SyncEngine.enqueuePimBootstrap` Graph-only |
| 8 bootstrap/incremental handlers | Pass | `SyncEngine` cases for all eight; `GraphPimProvider` + fan-out contacts/events jobs |
| Push/copy no-op | Pass | Fall-through `return null`; `pim_sync_jobs_noop_test.dart`; sync-engine test enqueues `contacts_push` without side effects |
| Display prefs preserve | Pass | `DriftPimStore.upsertContactLists` / `upsertCalendars` use `Value.absent()`; store tests + contacts bootstrap sync test |
| Stable ids / no dupe storm | Pass | `PimIds.stableLocalId`; store upsert-by-`(accountId, providerId)`; provider + engine tests assert stable ids / single row |
| Denormalized `accountId` on contacts/events | Pass | Mapper sets `accountId` from job/account; soft-delete paths preserve parent account |
| Cursor keys | Pass | `pim:contacts:{listId}`, `pim:events:{calId}` written; metadata markers `pim:contact_list:{accountId}`, `pim:calendar:{accountId}` (account-scoped — see residual) |
| `contact_fts` on contact write | Pass (infra) | DB triggers on `contacts` insert/update/delete; Graph path uses store upserts |
| Event window past 90d / future 365d | Pass | `kGraphEventHorizonPast` / `kGraphEventHorizonFuture`; class doc on `GraphPimProvider`; `calendarView` bootstrap path; unit test asserts `calendarView` + datetime query params |
| Mail path unbroken | Pass | `resolveProvider` / mail job cases unchanged; PIM via `resolvePim` + `pimStore`; 530 tests green |
| No Calendar/People/picker UI | Pass | Absent from `lib/ui` |
| Focused Graph PIM tests | Pass | `test/graph_pim_provider_test.dart`, `test/graph_pim_sync_engine_test.dart`, store preserve/stable-id cases |

---

## P0 → Wave 2 constraint close-out

| Constraint ([V2_0A_P0_QA.md](V2_0A_P0_QA.md)) | Resolution |
| --- | --- |
| Display prefs must survive sync upserts | **Closed** — store read-merge / `Value.absent()` on refresh (`eac846c`); covered by tests |
| Provider identity / no duplicate rows | **Closed for P1** — deterministic local ids + provider-id upsert; still no SQL `UNIQUE(account_id, provider_id)` (non-blocking residual) |
| Denormalized `accountId` consistency | **Closed for writers** — Graph mappers set matching account + collection FK |
| Cursor key convention | **Met** for per-collection contact/event deltas; metadata cursors are account-scoped (documented residual) |

---

## Residuals (non-blocking)

| Gap | Severity | Notes |
| --- | --- | --- |
| No automatic UI when token lacks PIM scopes | Low | 403 fails the job; operator docs require re-auth. Wave 3+ polish: map Graph “insufficient privileges” → actionable re-consent CTA |
| No DB `UNIQUE(account_id, provider_id)` | Low | Mitigated by `PimIds` + store lookup; optional schema bump later |
| Metadata cursor uses `{accountId}` not per-list/cal id | Info | Folders/calendars list has no Graph delta; timestamp marker under `pim:contact_list:{accountId}` / `pim:calendar:{accountId}` is intentional |
| Calendars bootstrap display-pref not asserted in sync-engine test | Low | Covered at store layer; contact-list prefs covered in engine test |
| Event window not yet echoed in V2_PLAN table | Info | Canonical docs: `GraphPimProvider` + this QA; Page may mirror 90d/365d into plan when convenient |
| `wipeAccount` PIM assertion still open from Wave 1 | Low | Unchanged; still recommended |

---

## Explicitly out of scope (confirmed absent — good)

- Calendar / People / compose picker UI
- ICS / accept-decline meeting bridge (Wave 3)
- CardDAV/CalDAV adapters (Wave 4)
- `Contacts.ReadWrite` / `Calendars.ReadWrite`
- Real `contacts_push` / `events_push` / copy handlers

---

## Inventory delta (for Page)

| Path | Cases (names / theme) | Kind | Maps to |
| --- | --- | --- | --- |
| `test/graph_pim_provider_test.dart` | stable folders/calendars; contacts delta+removed; calendarView window; HTTP 410 | unit | Wave 2 / P1 |
| `test/graph_pim_sync_engine_test.dart` | lists bootstrap→contacts job; contacts + display prefs + cursor; calendars→events + push no-op; Graph-only enqueue | unit/integration | Wave 2 / P1 |
| `test/pim_store_test.dart` | preserve-on-upsert lists/calendars; contact upsert no dupe | unit | Wave 2 foundation (`eac846c`) |
| `test/oauth_identity_manager_test.dart` | scopes contain Contacts.Read / Calendars.Read | unit | Wave 2 foundation |
| `test/pim_sync_jobs_noop_test.dart` | all 12 registered types still complete (handlers or no-op) | unit | Wave 2 |

Patch or regenerate `docs/V1_AUTOMATED_TEST_INVENTORY.csv` when convenient (V2 rows may live alongside until a V2 inventory exists).

---

## Handoff one-liners

- **Wave 3 (meeting-mail):** Unblocked. Bridge ICS ↔ local events; keep Graph mail + PIM read jobs green; do not enable write scopes unless product asks.
- **Operators:** Existing Graph accounts must re-sign-in after Wave 2+ builds so consent includes Contacts + Calendars.
- **Wave 5:** Owns Calendar / People chrome consuming display prefs already preserved by sync.
- **Wave 6:** Owns real copy/push handlers (names reserved, still no-op).

*Renee — Quality Engineering · 2026-07-27*
