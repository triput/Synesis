# Wave 5 — V2.0c Checklist (Compose Picker + Calendar / People UI)



> **Status:** **Complete** (2026-07-27, `73c181d`) — P5–P6: compose contact picker (local FTS), Calendar module (month + week/agenda, local CRUD), People workspace, module switcher. Renee QA **GO** — [V2_WAVE5_QA.md](V2_WAVE5_QA.md) (**585/585** tests). Parent plan: [V2_PLAN.md](V2_PLAN.md). Prior: [V2_WAVE4_QA.md](V2_WAVE4_QA.md) **GO**. **Next after exit:** Wave 6 (cross-account DnD copy).



Wave 5 delivers **P5–P6**: Outlook-style module shell (Mail default), compose contact picker fed by local `contact_fts` across selected lists, Calendar workspace with multi-calendar display prefs, and People workspace. All UI reads/writes go through **local Drift only** — no network from widgets; `events_push` remains no-op; Graph RSVP (Wave 3) and DAV read-only sync (Wave 4) unchanged.



## Sequence



```text

Wave 0 ✅ → Wave H ✅ → Wave 1 (P0) ✅

                         → Wave 2: Graph PIM (P1) ✅

                         → Wave 3: meeting-mail bridge (P2) ✅

                         → Wave 4: CardDAV/CalDAV (P3–P4) ✅

                         → Wave 5: picker + Calendar UI (P5–P6) ✅

                         → ★ Wave 6: cross-account DnD copy ← next

```



## Locked product decisions (Wave 5 — 2026-07-27)



| # | Decision |

| --- | --- |

| W5-1 | **Compose contact picker** fed by local `contact_fts` + **selected contact lists only**; no network from widgets |

| W5-2 | **Calendar module:** month + week (or agenda); create/edit/delete against **local Drift only**; remote push **NOT** in Wave 5 (`events_push` remains no-op; Graph RSVP already exists; DAV read-only) |

| W5-3 | **People/Contacts** reachable via module switcher; **Mail remains default launch** |

| W5-4 | **Multi-calendar display:** consume `isSelectedForDisplay` + colors; wire existing `calendarViewMode` overlay vs side-by-side |

| W5-5 | **Multi-contact-list:** picker + People use `isSelectedForDisplay` lists |

| W5-6 | **Store gaps** Jules/Tesla fill: `searchContacts` (FTS), `listEventsInRange`, display-pref writers; DI for `DriftPimStore` |

| W5-7 | **Out of Wave 5:** Wave 6 DnD; CalDAV/CardDAV write-back; Galaxy Watch |



## Store APIs



- [x] `searchContacts` — FTS query scoped to `isSelectedForDisplay` contact lists (no network)

- [x] `listEventsInRange` — date-range query across selected calendars for month/week/agenda views

- [x] Display-pref writers — set `isSelectedForDisplay`, color overrides, sort index on contact lists and calendars

- [x] Local event CRUD helpers — insert/update/soft-delete events in Drift (no remote push enqueue)

- [x] Local contact read helpers — list/detail for People workspace from selected lists



## DI / Cubits



- [x] `DriftPimStore` wired through DI / `main.dart` for UI modules (not sync-only)

- [x] Calendar workspace Cubit — selected calendars, view mode, visible range, local CRUD actions

- [x] People workspace Cubit — selected lists, contact list/detail streams

- [x] Compose contact picker Cubit — FTS debounce, selected-list scope, recipient selection

- [x] Module shell state — active module (Mail / Calendar / People); Mail default on cold start



## Module switcher shell (Mail default)



- [x] Outlook-style module switcher (Mail · Calendar · People)

- [ ] Mail remains default launch surface; deep links / resume restore last module where appropriate *(Mail cold-start default verified; resume/deep-link restore deferred)*

- [x] No regression to existing mail navigation, account rail, or reading pane



## Compose contact picker (P5)



- [x] Picker UI in compose To/Cc/Bcc — typeahead over local FTS

- [x] Scope search to `isSelectedForDisplay` contact lists only (multi-list aware)

- [x] Select contact → populate recipient chip (email from `contact_emails`)

- [x] No HTTP/Graph/CardDAV calls from picker widgets



## Calendar workspace (P6)



- [x] Month view — events from `listEventsInRange` on selected calendars

- [x] Week or agenda view — same data source; operator picks one primary alternate layout

- [x] Create event — local Drift insert on chosen calendar; `events_push` not enqueued

- [x] Edit event — local update; preserve provider identity fields for synced rows

- [x] Delete event — local soft-delete; no CalDAV/Graph DELETE in Wave 5

- [x] Multi-calendar display — honor `isSelectedForDisplay` + per-calendar colors

- [x] `calendarViewMode` — overlay vs side-by-side wired from app settings



## People workspace



- [x] Contacts list from selected `isSelectedForDisplay` contact lists

- [x] Contact detail — name, emails, phones from local store

- [x] List/collection selector — toggle which address books appear (display prefs)

- [x] Read-only for remote-sourced contacts in Wave 5 (no CardDAV PUT)



## Settings: calendarViewMode UI



- [x] Settings surface for overlay vs side-by-side if not already exposed in UI

- [x] Persist via existing `AppSettingsCubit` / `calendarViewMode` enum

- [x] Calendar workspace reacts to setting changes



## Verification



- [x] Unit / widget tests: FTS search scope, date-range queries, display-pref writers, local event CRUD

- [x] Module switcher + picker widget tests where practical

- [x] `flutter analyze` — 0 errors on touched code

- [x] Full `flutter test` green — **585/585**

- [x] Graph PIM + DAV sync + mail regression unchanged



## Docs



- [x] This checklist exit marked complete

- [x] [V2_PLAN.md](V2_PLAN.md) / [ROADMAP.md](ROADMAP.md) — Wave 5 complete; Wave 6 next

- [x] [V2_WAVE5_QA.md](V2_WAVE5_QA.md) — Renee **GO**

- [ ] Runbox + Graph dogfood notes (operator — post-land script pending)

- [x] Automated-test inventory regeneration — `tool/generate_test_inventory.py` (**585 cases**)



## Out of Wave 5 MVP



- Cross-account / cross-list DnD copy (Wave 6)

- CalDAV/CardDAV write-back (PUT/PROPPATCH); `events_push` / `contacts_push` remote sync

- Galaxy Watch companion (V2.1)

- Free/busy, rooms/resources, shared calendar ACLs, Teams deep links

- CardDAV contact create/edit from People UI

- Recurrence editor depth beyond basic local fields (defer polish if needed)

- Wave 7 UI niceties (resizable panes, overflow sweeps, etc.)



## Wave 5 exit criteria (gate)



- [x] Compose picker resolves contacts from local FTS across selected lists; no widget-level network

- [x] Calendar module: month + week/agenda; local create/edit/delete; multi-calendar colors + overlay/side-by-side

- [x] People workspace lists contacts from selected lists; reachable via module switcher

- [x] Mail default launch; module switcher does not regress mail

- [x] Store APIs (`searchContacts`, `listEventsInRange`, display prefs) landed and DI-complete

- [x] Tests + analyze + full suite green; Graph/DAV/mail regression clean

- [x] Docs + Renee QA GO; inventory refresh; Wave 6 unblocked



## Team routing



| Role | Wave 5 work |

| --- | --- |

| Steve | Orchestrate; lock decisions; exit gate; commit |

| Jules | Module shell, Calendar/People UI, compose picker, settings surfacing |

| Tesla | Store API gaps (`searchContacts`, `listEventsInRange`, display-pref writers), DI wiring assist |

| Andi | Widget tests, UI glue, picker polish under Jules brief |

| Renee | QA — FTS scope, local CRUD boundaries, regression, GO/NO-GO |

| Page | Checklist / plan / roadmap / dogfood notes / inventory |



## Operator dogfood (Wave 5 — post-land)



1. **Graph account:** confirm contacts + calendars synced (Wave 2); open compose → picker finds a known contact by partial name/email; verify only selected lists contribute results.

2. **Runbox DAV account:** after Wave 4 sync, open People → contacts from Runbox address book appear; Calendar → Runbox events in month/week range.

3. **Local CRUD:** create a test event on a Graph calendar → appears in Calendar UI immediately; confirm it stays local (no remote push in Wave 5). Edit title/time; soft-delete — UI reflects change.

4. **Multi-calendar:** select 2+ calendars with distinct colors; toggle overlay vs side-by-side in Settings; verify both layouts render events correctly.

5. **Module switcher:** cold start lands on Mail; switch to Calendar and People; return to Mail without state loss on active account/folder.

6. **Meeting mail (Wave 3):** RSVP from reading pane still works; not broken by Calendar module landing.

7. Record UX gaps (recurrence, attachment on events, write-back desire) without credentials or raw PII.



## Residuals carried forward



- **Local-only writes (accepted Wave 5 MVP):** Calendar/People create/edit/delete persist in Drift only; `events_push` / `contacts_push` remain no-op — remote providers catch up in a later wave or Wave 6 copy flow.

- **DAV/Graph read sync unchanged:** Wave 4 full-pull reconciliation and Wave 2 display-pref preservation still apply; Wave 5 UI must not clobber provider-sourced rows on edit without explicit local-only semantics.

- **Cross-account copy deferred:** DnD and “Copy to calendar/list…” menu land in Wave 6, not Wave 5.

- **Resume/deep-link module restore:** not implemented; Mail cold-start default per W5-3 is verified.

- **Event editor calendar dropdown UX:** creating on a deselected calendar can hide the event from the visible grid until that calendar is re-selected — polish backlog (Wave 6/7).


