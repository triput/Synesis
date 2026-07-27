# Wave 1 / V2.0a P0 — Renee QA notes

| Field | Value |
| --- | --- |
| Reviewed | 2026-07-27 |
| Commit | `00ebdef` (schema v7 PIM foundations) |
| Checklist | [V2_0A_P0_CHECKLIST.md](V2_0A_P0_CHECKLIST.md) |
| Verdict | **GO** Wave 1 exit · **GO** Wave 2 handoff (with constraints) |

Jules reported 516 tests green; this review is checklist + multi-collection requirements + migration/edge audit (read of schema, stores, sync no-ops, tests). No Wave 2 implementation.

---

## Verdict

| Gate | Decision | Notes |
| --- | --- | --- |
| **Wave 1 exit** | **GO** | Schema v7, multi-list/cal columns, FKs, FTS, job no-ops, stores, `calendarViewMode`, and focused tests meet P0 exit. Residuals below are non-blocking. |
| **Wave 2 handoff** (Tesla Graph PIM) | **GO** | Unblocked. Tesla **must** honor display-pref and identity constraints below. Jules CardDAV discovery spike may run in parallel. |
| Wave 5 / Wave 6 | N/A | Overlay/side-by-side UI and DnD copy remain correctly deferred. |

No Pri-1 / data-safety blockers found for local schema foundations.

---

## Checklist matrix (product + schema)

| Requirement | Status | Evidence |
| --- | --- | --- |
| Many calendars / events FK `calendarId` | Pass | `Calendars` / `Events` in `database.dart`; migration `from < 7` |
| Calendar display prefs + `calendarViewMode` | Pass | Columns + `CalendarViewMode` in settings / export |
| Per-calendar cursor keys | Pass | `PimSyncJobs.calendarCursorKey` / `eventsCursorKey` |
| Many contact lists / contacts FK `contactListId` | Pass | `ContactLists` / `Contacts` |
| Contact-list display prefs | Pass | `colorArgb?`, `isSelectedForDisplay`, `sortIndex` |
| Per-list cursor keys | Pass | `contactListCursorKey` / `contactsCursorKey` |
| Reserved push/copy jobs | Pass | Documented + registered no-ops; not enqueued on account-add |
| schemaVersion 7 + 6→7 migration | Pass | `schemaVersion => 7`; `test/schema_migration_v6_to_v7_test.dart` |
| `contact_fts` + triggers | Pass | `_createContactFts` on create + upgrade |
| `event_attendees` present | Pass | Table + store upsert/list |
| No mail `messages` → contacts FK | Pass | Absent by design |
| Sync no-ops in `SyncEngine` | Pass | All 12 `PimSyncJobs.allRegistered` types; `pim_sync_jobs_noop_test.dart` |
| Thin stores + selected helpers | Pass | `DriftPimStore`; `pim_store_test.dart` multi-account fixtures |
| Account wipe includes PIM | Pass (code) | `wipeAccount` deletes attendees → events → calendars → emails/phones → contacts → lists |
| Encryption path still opens | Pass (inferred) | Open path unchanged; v7 only `CREATE TABLE` / indexes / FTS — no dedicated encrypt+migrate co-test |

---

## Gaps / residuals (non-blocking for Wave 1)

### Wave 2 constraints (Tesla — treat as acceptance for P1)

1. **Display prefs must survive sync upserts**  
   `upsertContactLists` / `upsertCalendars` write `isSelectedForDisplay`, `sortIndex`, and calendar `colorOverrideArgb` on every conflict update. A naive Graph refresh that re-upserts server metadata will **clobber** user toggles. Preserve local display columns (read-merge or `Value.absent()` for those fields on provider refresh).

2. **Provider identity / uniqueness**  
   No `UNIQUE(account_id, provider_id)` (or equivalent) on `contact_lists`, `calendars`, `contacts`, or `events`. Duplicate local rows for the same remote object are possible if Wave 2 generates new local ids per run. Prefer deterministic local ids (e.g. account-scoped) and/or a later unique index + schema bump before ship.

3. **Denormalized `accountId` on contacts/events**  
   Rows carry both `accountId` and collection FK with no CHECK that they match the parent list/calendar. Sync writers must keep them consistent; mismatched rows break wipe/filter assumptions.

4. **Cursor `folderId` convention**  
   Docs say use collection id as `sync_cursors.folder_id`. Account wipe already deletes all cursors for the account — good. Ensure Graph jobs write the documented keys (`pim:contact_list:…`, `pim:contacts:…`, `pim:calendar:…`, `pim:events:…`).

### Test / coverage residuals (ok to land in Wave 2+)

| Gap | Severity | Suggestion |
| --- | --- | --- |
| `wipeAccount` not asserted for PIM tables | Low | Extend wipe fixture with list/contact/calendar/event rows |
| Soft-delete (`deletedAt`) filter untested | Low | Assert `listContacts` / `listEvents` hide deleted by default |
| `contact_fts` triggers not exercised | Low | Insert/update/delete contact → FTS row present/updated/gone |
| `calendarViewMode` no dedicated unit test | Low | Cubit / export round-trip |
| Encrypted DB + v6→v7 co-test | Low | Optional; architecture does not special-case PIM |

### Product / later-wave notes (not P0 defects)

- **`contact_fts` indexes name/company/notes only** — not email/phone. Compose picker (Wave 5 / V2 exit) may need FTS expansion or join search.
- **No FTS query helper** on `DriftPimStore` yet — expected for P0; Wave 5 owns picker search.
- **FK without `ON DELETE CASCADE`** — acceptable; wipe paths delete children manually. Direct parent deletes without orphans handling remain footguns for sync code.
- **Checklist claim “encryption-at-rest path still opens”** — not separately proven for v7; rely on unchanged `_openConnection` + migration SQL shape.

---

## Explicitly out of scope (confirmed absent — good)

- Graph / CardDAV adapters
- Account-add enqueue of PIM jobs
- Calendar / People / picker UI
- Cross-account DnD copy UI (reserved job names only)

---

## Inventory delta (for Page)

| Path | Cases | Kind | Maps to |
| --- | --- | --- | --- |
| `test/schema_migration_v6_to_v7_test.dart` | opens v6 → migrates to v7 with PIM tables | unit | Wave 1 / P0 |
| `test/pim_store_test.dart` | empty queries; multi-list/cal selected filters | unit | Wave 1 / P0 |
| `test/pim_sync_jobs_noop_test.dart` | cursor keys; all registered jobs no-op success; unknown fails | unit | Wave 1 / P0 |

Regenerate or patch `docs/V1_AUTOMATED_TEST_INVENTORY.csv` when convenient (V2 rows may live alongside V1 inventory until a V2 inventory exists).

---

## Handoff one-liners

- **Tesla (Wave 2):** Graph contacts + calendars against this schema; preserve display prefs; pick stable provider↔local identity; enqueue bootstrap/incremental (not push/copy yet unless CRUD lands).
- **Jules:** CardDAV discovery spike unblocked in parallel.
- **Wave 5:** Owns overlay / side-by-side chrome consuming `calendarViewMode` + `isSelectedForDisplay`.
- **Wave 6:** Owns DnD copy + real `contacts_copy` / `events_copy` handlers.

*Renee — Quality Engineering · 2026-07-27*
