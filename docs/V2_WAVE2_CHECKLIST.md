# Wave 2 — V2.0a P1 Checklist (Graph contacts + calendars)

> **Status:** **In progress** (2026-07-27 kickoff) — Tesla (Graph PIM sync). Parent plan: [V2_PLAN.md](V2_PLAN.md) §8. Wave 1 exit: [V2_0A_P0_CHECKLIST.md](V2_0A_P0_CHECKLIST.md). Renee handoff constraints: [V2_0A_P0_QA.md](V2_0A_P0_QA.md).

Wave 2 scope is **P1 only** — Microsoft Graph contacts and calendar sync into the Wave 1 local PIM schema (multi-list, multi-calendar). **No Calendar/People UI**, no compose picker, no push/copy jobs, no CardDAV/CalDAV adapters (Wave 4).

## Sequence

```text
Wave 0 ✅ → Wave H ✅ → Wave 1 (P0) ✅
                         → ★ Wave 2: Graph PIM (P1) ← in progress
                         → Wave 3: meeting-mail bridge (P2)
                         → Wave 4: CardDAV/CalDAV (P3–P4)
                         → Wave 5: picker + Calendar UI (P5–P6)
                         → Wave 6: cross-account DnD copy
```

## OAuth scopes & re-consent

- [ ] Graph OAuth request includes **`Contacts.Read`** and **`Calendars.Read`** (delegated) alongside existing mail scopes
- [ ] Entra app registration documents the new permissions ([README](../README.md#microsoft-graph-entra-setup))
- [ ] Existing Graph accounts trigger **re-consent** (re-auth) when tokens lack PIM scopes — no silent failure
- [ ] New Graph account add enqueues PIM bootstrap jobs after successful consent

## Graph sync deliverables

### Contact lists & contacts

- [ ] `contact_lists_bootstrap` / `contact_lists_incremental` — Graph contact folders → `contact_lists`
- [ ] `contacts_bootstrap` / `contacts_incremental` — contacts per list → `contacts`, `contact_emails`, `contact_phones`
- [ ] `contact_fts` kept in sync on contact insert/update/delete
- [ ] Per-list cursor keys: `pim:contact_list:{id}`, `pim:contacts:{listId}`

### Calendars & events

- [ ] `calendars_bootstrap` / `calendars_incremental` — Graph calendars → `calendars`
- [ ] `events_bootstrap` / `events_incremental` — events per calendar → `events` (+ `event_attendees` stub where applicable)
- [ ] Per-calendar cursor keys: `pim:calendar:{id}`, `pim:events:{calId}`

### Display prefs preserve (Renee constraint — blocking)

- [ ] `upsertContactLists` / `upsertCalendars` **do not clobber** local `isSelectedForDisplay`, `sortIndex`, or calendar `colorOverrideArgb` on provider refresh
- [ ] Read-merge or `Value.absent()` for display columns on Graph metadata upserts ([V2_0A_P0_QA.md](V2_0A_P0_QA.md) §Wave 2 constraints)

### Stable provider identity (Renee constraint — blocking)

- [ ] Deterministic local ids and/or stable `providerId` mapping — no duplicate rows for the same remote contact list, calendar, contact, or event across sync runs
- [ ] Denormalized `accountId` on contacts/events matches parent list/calendar account

## Sync engine integration

- [ ] Bootstrap jobs enqueued on Graph account add / re-auth (after PIM scopes granted)
- [ ] Incremental jobs run on sync cycle (same engine as mail; isolate-safe)
- [ ] Reserved jobs remain no-op: `contacts_push`, `contacts_copy`, `events_push`, `events_copy`
- [ ] Account wipe still clears PIM rows + cursors for removed account

## Verification

- [ ] Focused unit/integration tests for Graph PIM adapters (mock Graph responses)
- [ ] Display-pref preserve test (upsert does not reset toggles)
- [ ] Stable-id test (re-sync does not duplicate rows)
- [ ] `flutter analyze` — 0 errors on touched code
- [ ] Full `flutter test` green — **mail paths unchanged** (no regression)

## Docs

- [x] [V2_PLAN.md](V2_PLAN.md) — Wave 2 in progress; re-consent note
- [x] [ROADMAP.md](ROADMAP.md) — Wave 2 in progress
- [x] This checklist — kickoff 2026-07-27
- [x] README / QUICK_START — Graph scope + re-consent note (operator-facing)
- [ ] Renee QA sign-off artifact when implementation lands

## Out of Wave 2

- Calendar module UI / People module UI / compose contact picker (Wave 5)
- ICS / accept-decline meeting bridge (Wave 3)
- CardDAV/CalDAV / Runbox (Wave 4)
- Cross-account DnD copy UX (Wave 6)
- Push/copy PIM jobs (Wave 5–6 unless CRUD lands earlier)
- `Contacts.ReadWrite` / `Calendars.ReadWrite` (read-only sync for P1)

## Wave 2 exit criteria (gate)

- [ ] `Contacts.Read` + `Calendars.Read` in OAuth flow; re-consent path for existing accounts
- [ ] Graph contact lists + contacts + calendars + events bootstrap/incremental jobs operational
- [ ] Display prefs preserved across provider refresh
- [ ] Stable provider ↔ local identity (no duplicate rows on re-sync)
- [ ] Per-collection cursor keys written as documented
- [ ] Full `flutter test` green; Graph **mail** sync unaffected
- [ ] **No Calendar/People/picker UI** shipped
- [ ] Docs updated; Wave 2 committed on `v2.0`; Wave 3 (meeting-mail bridge) unblocked

## Team routing

| Role | Wave 2 work |
| --- | --- |
| Steve | Orchestrate; exit gate |
| Tesla | Graph PIM adapters, scope bump, sync job handlers, enqueue wiring |
| Jules | CardDAV discovery spike (parallel, optional this wave) |
| Renee | QA — display-pref preserve, stable ids, mail regression |
| Page | V2_PLAN / ROADMAP / this checklist |
