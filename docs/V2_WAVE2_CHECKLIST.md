# Wave 2 — V2.0a P1 Checklist (Graph contacts + calendars)

> **Status:** **Complete** (2026-07-27, `b526e70` + `eac846c` foundation, 530 tests) — Tesla (Graph PIM sync); Renee QA **GO** — [V2_WAVE2_QA.md](V2_WAVE2_QA.md). Parent plan: [V2_PLAN.md](V2_PLAN.md) §8. Wave 1 exit: [V2_0A_P0_CHECKLIST.md](V2_0A_P0_CHECKLIST.md). Prior constraints: [V2_0A_P0_QA.md](V2_0A_P0_QA.md).

Wave 2 scope is **P1 only** — Microsoft Graph contacts and calendar sync into the Wave 1 local PIM schema (multi-list, multi-calendar). **No Calendar/People UI**, no compose picker, no push/copy jobs, no CardDAV/CalDAV adapters (Wave 4).

## Sequence

```text
Wave 0 ✅ → Wave H ✅ → Wave 1 (P0) ✅
                         → Wave 2: Graph PIM (P1) ✅
                         → ★ Wave 3: meeting-mail bridge (P2) ← next
                         → Wave 4: CardDAV/CalDAV (P3–P4)
                         → Wave 5: picker + Calendar UI (P5–P6)
                         → Wave 6: cross-account DnD copy
```

## OAuth scopes & re-consent

- [x] Graph OAuth request includes **`Contacts.Read`** and **`Calendars.Read`** (delegated) alongside existing mail scopes — `GraphAuthConfig.scopes` (`eac846c`)
- [x] Entra app registration documents the new permissions ([README](../README.md#microsoft-graph-entra-setup))
- [x] Existing Graph accounts trigger **re-consent** (re-auth) when tokens lack PIM scopes — documented re-sign-in path (Edit account → re-auth); scopes expanded in OAuth flow
- [x] New Graph account add enqueues PIM bootstrap jobs after successful consent — `_enqueueGraphPimBootstrap` in `AccountService`

## Graph sync deliverables

### Contact lists & contacts

- [x] `contact_lists_bootstrap` / `contact_lists_incremental` — Graph contact folders → `contact_lists`
- [x] `contacts_bootstrap` / `contacts_incremental` — contacts per list → `contacts`, `contact_emails`, `contact_phones`
- [x] `contact_fts` kept in sync on contact insert/update/delete — Drift FTS5 triggers on `contacts` table
- [x] Per-list cursor keys: `pim:contact_list:{id}`, `pim:contacts:{listId}`

### Calendars & events

- [x] `calendars_bootstrap` / `calendars_incremental` — Graph calendars → `calendars`
- [x] `events_bootstrap` / `events_incremental` — events per calendar → `events` (+ `event_attendees` stub where applicable)
- [x] **Event sync window:** past **90d** / future **365d** (`kGraphEventHorizonPast` / `kGraphEventHorizonFuture` in `graph_pim_provider.dart`)
- [x] Per-calendar cursor keys: `pim:calendar:{id}`, `pim:events:{calId}`

### Display prefs preserve (Renee constraint — blocking)

- [x] `upsertContactLists` / `upsertCalendars` **do not clobber** local `isSelectedForDisplay`, `sortIndex`, or calendar `colorOverrideArgb` on provider refresh
- [x] Read-merge or `Value.absent()` for display columns on Graph metadata upserts ([V2_0A_P0_QA.md](V2_0A_P0_QA.md) §Wave 2 constraints)

### Stable provider identity (Renee constraint — blocking)

- [x] Deterministic local ids and/or stable `providerId` mapping — no duplicate rows for the same remote contact list, calendar, contact, or event across sync runs
- [x] Denormalized `accountId` on contacts/events matches parent list/calendar account

## Sync engine integration

- [x] Bootstrap jobs enqueued on Graph account add / re-auth (after PIM scopes granted)
- [x] Incremental jobs run on sync cycle (same engine as mail; isolate-safe)
- [x] Reserved jobs remain no-op: `contacts_push`, `contacts_copy`, `events_push`, `events_copy`
- [x] Account wipe still clears PIM rows + cursors for removed account

## Verification

- [x] Focused unit/integration tests for Graph PIM adapters (mock Graph responses) — `test/graph_pim_provider_test.dart`, `test/graph_pim_sync_engine_test.dart`
- [x] Display-pref preserve test (upsert does not reset toggles) — `test/pim_store_test.dart`, `test/graph_pim_sync_engine_test.dart`
- [x] Stable-id test (re-sync does not duplicate rows) — `test/pim_store_test.dart`, `test/graph_pim_provider_test.dart`
- [x] `flutter analyze` — 0 errors on touched code
- [x] Full `flutter test` green — **530/530**; mail paths unchanged (no regression)

## Docs

- [x] [V2_PLAN.md](V2_PLAN.md) — Wave 2 complete; Wave 3 next; event window 90d/365d; re-consent in scopes
- [x] [ROADMAP.md](ROADMAP.md) — Wave 2 complete
- [x] This checklist — Wave 2 exit 2026-07-27
- [x] README / QUICK_START — Graph scope + re-consent note (operator-facing)
- [x] Renee QA sign-off — [V2_WAVE2_QA.md](V2_WAVE2_QA.md) (**GO** Wave 2 exit · **GO** Wave 3 handoff)

## Out of Wave 2

- Calendar module UI / People module UI / compose contact picker (Wave 5)
- ICS / accept-decline meeting bridge (Wave 3)
- CardDAV/CalDAV / Runbox (Wave 4)
- Cross-account DnD copy UX (Wave 6)
- Push/copy PIM jobs (Wave 5–6 unless CRUD lands earlier)
- `Contacts.ReadWrite` / `Calendars.ReadWrite` (read-only sync for P1)

## Wave 2 exit criteria (gate)

- [x] `Contacts.Read` + `Calendars.Read` in OAuth flow; re-consent path for existing accounts
- [x] Graph contact lists + contacts + calendars + events bootstrap/incremental jobs operational
- [x] Display prefs preserved across provider refresh
- [x] Stable provider ↔ local identity (no duplicate rows on re-sync)
- [x] Per-collection cursor keys written as documented
- [x] Full `flutter test` green (530/530); Graph **mail** sync unaffected
- [x] **No Calendar/People/picker UI** shipped
- [x] Docs updated; Wave 2 committed on `v2.0`; Wave 3 (meeting-mail bridge) unblocked

## Team routing

| Role | Wave 2 work |
| --- | --- |
| Steve | Orchestrate; exit gate |
| Tesla | Graph PIM adapters, scope bump, sync job handlers, enqueue wiring |
| Jules | CardDAV discovery spike (parallel — landed `9d5f750`) |
| Renee | QA — display-pref preserve, stable ids, mail regression — **signed off** |
| Page | V2_PLAN / ROADMAP / this checklist |
