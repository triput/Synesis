# Wave 1 — V2.0a P0 Checklist (local PIM schema)

> **Status:** **In progress** (2026-07-27). Parent plan: [V2_PLAN.md](V2_PLAN.md) §5–§7.

Wave 1 scope is **P0 only** — expanded local PIM schema foundations for multi-contact-list and multi-calendar collections, sync job type hooks, and thin read stores. No Graph/CardDAV adapters, no Calendar/People UI, no cross-account DnD copy (Wave 6).

## Sequence

```text
Wave 0 ✅ → Wave H ✅ → ★ Wave 1 (P0) ← in progress
                         → Wave 2: Graph PIM (P1)
                         → Wave 3: meeting-mail bridge (P2)
                         → Wave 4: CardDAV/CalDAV (P3–P4)
                         → Wave 5: picker + Calendar UI (P5–P6)
                         → Wave 6: cross-account DnD copy
```

## Product requirements baked into P0 (not UI)

These operator requirements shape schema and later waves; Wave 1 stores foundations only.

### Multi-calendar

- [ ] Many calendars per account and across accounts; events FK to `calendarId`
- [ ] Display prefs on `calendars`: `colorArgb`, optional `colorOverrideArgb`, `isSelectedForDisplay`, `sortIndex`
- [ ] App setting `calendarViewMode`: `overlay` | `sideBySide` (for P6 UI)
- [ ] Per-calendar sync cursor keys (e.g. `pim:calendar:{id}`)

### Multi-contact-list

- [ ] Many contact lists / address books per account and across accounts; contacts FK to `contactListId`
- [ ] Display prefs on `contact_lists`: optional `colorArgb`, `isSelectedForDisplay`, `sortIndex`
- [ ] Per-list sync cursor keys (e.g. `pim:contact_list:{id}`)

### Cross-account copy (Wave 6 — document only in P0)

- [ ] Reserved job names documented: `contacts_push`, `contacts_copy`, `events_push`, `events_copy`
- [ ] No DnD / copy UI in Wave 1

## Schema v7 deliverables

- [ ] `schemaVersion` **7** with migration from **6**; fresh install OK
- [ ] `contact_lists` — `accountId`, `providerId`, `name`, `colorArgb?`, `isDefault`, `isSelectedForDisplay`, `sortIndex?`
- [ ] `contacts` — `accountId`, **`contactListId`** FK, `providerId`, name fields, `company`, `notes`, `etag`, `updatedAt`, `deletedAt?`
- [ ] `contact_emails`, `contact_phones`
- [ ] `calendars` — `accountId`, `providerId`, `name`, `colorArgb`, `colorOverrideArgb?`, `isDefault`, `isSelectedForDisplay`, `sortIndex?`
- [ ] `events` — `accountId`, **`calendarId`** FK, `providerId`, title/body, start/end epoch ms, `allDay`, location, `rrule`, `reminderMinutes`, `etag`, `updatedAt`, `deletedAt?`
- [ ] `event_attendees` (P2 meeting bridge without second schema bump)
- [ ] `contact_fts` — FTS5 + triggers mirroring `message_fts`
- [ ] No FK from mail `messages` → contacts
- [ ] Encryption-at-rest path still opens DB after migration

## Sync job types

No-op handlers wired in `SyncEngine._processJob` so enqueue cannot crash:

- [ ] `contact_lists_bootstrap` / `contact_lists_incremental`
- [ ] `contacts_bootstrap` / `contacts_incremental`
- [ ] `calendars_bootstrap` / `calendars_incremental`
- [ ] `events_bootstrap` / `events_incremental`
- [ ] Reserved (no-op or log-only until later): `contacts_push`, `contacts_copy`, `events_push`, `events_copy`

Do **not** enqueue from account-add in P0 unless trivial; leave to Wave 2 (Graph PIM).

## Domain / repository

- [ ] Thin domain models + Drift stores for lists, calendars, contacts, events
- [ ] Query helpers: events for selected calendars; contacts for selected lists; calendars grouped by account
- [ ] No Calendar module UI; no People module UI; no compose picker UI

## Verification

- [ ] Migration upgrade-from-v6 test
- [ ] Empty-store queries; multi-list / multi-calendar fixture queries
- [ ] Job no-op dispatch tests
- [ ] `flutter analyze` — 0 errors on touched code
- [ ] Focused + full `flutter test` green

## Docs

- [x] [V2_PLAN.md](V2_PLAN.md) — Wave 1 in progress; operator waves 1–6; multi-cal / multi-list requirements; DnD copy = Wave 6
- [x] [ROADMAP.md](ROADMAP.md) — Wave 1 in progress
- [x] This checklist created

## Out of Wave 1

- Graph Contacts/Calendar HTTP (Wave 2 / P1)
- ICS / accept-decline meeting bridge (Wave 3 / P2)
- CardDAV/CalDAV / Runbox (Wave 4 / P3–P4)
- Compose picker / Calendar UI / overlay-side-by-side chrome (Wave 5 / P5–P6)
- Cross-account DnD copy UX (Wave 6)
- DEF-050 mark-read context menu
- Wave H residuals (dogfood smokes, KGP) — tracked in [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md)

## Wave 1 exit criteria (gate)

- [ ] schemaVersion 7 migrates cleanly from 6; fresh install OK
- [ ] PIM tables + contact FTS present; multi-calendar and multi-list columns present; encryption-at-rest path still opens
- [ ] New job types dispatch without throwing; reserved push/copy names documented
- [ ] Focused + full `flutter test` green; analyze 0 errors
- [ ] Docs updated; Wave 1 committed on `v2.0`
- [ ] Explicit handoff: Wave 2 Tesla (Graph PIM) + Jules CardDAV discovery spike unblocked; Wave 5 owns overlay/side-by-side UI; Wave 6 owns DnD copy

## Team routing

| Role | Wave 1 work |
| --- | --- |
| Steve | Orchestrate; exit gate |
| Jules | Schema + stores + migration |
| Andi | Tests, headers, mechanical follow-ups |
| Tesla | Job type design + SyncEngine no-op arms; per-collection cursor keys |
| Renee | Migration/edge QA (incl. multi-list/cal fixtures) |
| Page | V2_PLAN / ROADMAP / this checklist |
