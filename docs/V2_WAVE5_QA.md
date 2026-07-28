# Wave 5 / V2.0c P5–P6 — Renee QA notes

| Field | Value |
| --- | --- |
| Reviewed | 2026-07-27 |
| Checklist | [V2_WAVE5_CHECKLIST.md](V2_WAVE5_CHECKLIST.md) |
| Prior gate | [V2_WAVE4_QA.md](V2_WAVE4_QA.md) |
| Tests | **585/585 passed** (`flutter test`, verified independently by Renee) |
| Analyze | **0 errors** — 89 issues, all pre-existing-style `info`/`warning` (see below) |
| Verdict | **GO** Wave 5 exit · **GO** Wave 6 handoff |

Wave 5 adds the Outlook-style module switcher (Mail default), a local-FTS
compose contact picker, and Calendar/People workspaces, all reading and
writing exclusively through the existing local `DriftPimStore`. The exit is
approved for the locked MVP: local-only Calendar CRUD (`events_push` remains
a no-op), read-only People/contacts, and no widget-level network access.

---

## Verdict

| Gate | Decision | Notes |
| --- | --- | --- |
| Local-first boundary | **Pass** | `CalendarCubit`, `PeopleCubit`, `ContactRecipientField`, and both workspaces import only `DriftPimStore`/`MailRepository`/domain models. Grepped `lib/ui/calendar`, `lib/ui/people`, `lib/ui/compose/contact_picker.dart` for Graph/DAV/HTTP symbols — only doc-comment mentions ("no CalDAV/Graph DELETE", "Sync a Graph or DAV account…") remain; zero executable network calls. |
| Soft-delete vs hard-delete | **Pass** | `softDeleteEvent` stamps `deletedAt`/`updatedAt` and is excluded by default from `listEvents`/`listEventsInRange` (`includeDeleted` opt-in only); no hard `DELETE` path added for events or contacts in this wave. Covered by `pim_store_test.dart`. |
| Selected lists/calendars scoping | **Pass** | `listContactsForSelectedLists`, `searchContacts(selectedListsOnly: true)`, `listEventsInRange` (default `selectedCalendarsOnly: true`) all scope correctly; verified against multi-account/multi-list fixtures and the hidden-vs-visible list/calendar tests in `pim_store_test.dart`. |
| Compose recipient format | **Pass** | `formatContactRecipient` quotes names containing `,`/`"`; cross-checked against `outbox_recipients.dart`'s `_splitAddressList`, which treats quoted spans as atomic — the two are provably compatible, not just probably. `contact_picker_test.dart` covers format/quote/token-insert edge cases. |
| Mail default / no regression | **Pass** | `ModuleShell` defaults to `AppModule.mail`; `MailWorkspace` is embedded unmodified inside an `IndexedStack`. `module_shell_test.dart` asserts Mail renders first and Calendar/People swap without losing Mail state; `widget_test.dart`'s "Synesis shell renders Unified Inbox" still passes. |
| Edge cases | **Pass** | Empty PIM (`listContactLists`/`listCalendars`/`listEvents*` all return `isEmpty` on fresh schema), `createLocalEvent` on a calendar-less account throws `StateError` (caught and surfaced via the editor's `_error` state — no crash), and `searchContacts('   ')` short-circuits before touching the DB. All three asserted directly in `pim_store_test.dart`. |
| DI / notify-refresh path | **Pass** | `main.dart` constructs one `DriftPimStore` sharing `DriftMailRepository.notifyChanges`/`watchChanges()` — no second change stream to drift out of sync. `app.dart` provides `DriftPimStore` via `RepositoryProvider` and wires `CalendarCubit`/`PeopleCubit` once at the app root via `MultiBlocProvider`, so `ModuleShell`'s `IndexedStack` reuses the same cubit instances across module switches (state survives Mail ↔ Calendar ↔ People). |
| Settings surfacing | **Pass** | `calendarViewMode` (overlay/side-by-side) is exposed via `SegmentedButton` in `settings_sections.dart`, catalogued in `settings_catalog.dart` for Settings search, and consumed live by `CalendarCubit` via an `AppSettingsCubit` stream subscription. |
| Full regression | **Pass** | 585/585 `flutter test`, independently executed. Graph PIM (Wave 2), meeting-mail bridge (Wave 3), and DAV sync (Wave 4) integration suites are all still green in the same run — no isolation/DI change broke prior waves. |

---

## Scope checked

| Area | Result | Evidence |
| --- | --- | --- |
| Domain/store additions | Pass | `lib/domain/pim.dart` adds `ContactSearchHit` only (additive); `DriftPimStore` adds `searchContacts`, `listEventsInRange`, `setContactListDisplayPrefs`, `setCalendarDisplayPrefs`, `createLocalEvent`/`updateLocalEvent`/`softDeleteEvent` — all new methods, no signature changes to Wave 1–4 call sites. |
| `searchContacts` | Pass | FTS (`contact_fts` + `bm25`) merged with a `LIKE` email fallback, de-duplicated, ordered FTS-first; scoped to `listSelectedContactLists` by default, `deletedAt.isNull()` always applied, `limit` respected. Blank query and non-positive `limit` short-circuit before any query executes. |
| `listEventsInRange` | Pass | Correct half-open interval overlap test (`start < rangeEnd && end > rangeStart`); `calendarIds` explicit override, `selectedCalendarsOnly` default, and `includeDeleted` all independently tested with before/overlap-start/inside/overlap-end/after fixtures. |
| Display-pref writers | Pass | `setContactListDisplayPrefs`/`setCalendarDisplayPrefs` write only non-null arguments (`Value.absent()` elsewhere) and survive a subsequent provider `upsert` (preserve-on-refresh contract unchanged from Wave 2). |
| Local event CRUD | Pass | `createLocalEvent` synthesizes `local:{uuid}` provider ids when omitted (keeps `(accountId, providerId)` identity), defaults to `findDefaultCalendar`, throws `StateError` with no calendars; `updateLocalEvent` always re-stamps `updatedAt`; `softDeleteEvent` is a pure local tombstone. None of the three enqueue a sync job. |
| `CalendarCubit` | Pass | Loads `listAccounts` + `listCalendars` + `listEventsInRange` for the focused month; `watchChanges()` subscription drives `refresh()` on every PIM write; `AppSettingsCubit.calendarViewMode` stream keeps `viewMode` live; both subscriptions cancelled in `close()`. |
| `PeopleCubit` | Pass | Debounced (250 ms) FTS search with stale-response guarding (`state.searchQuery != query` check before emitting); `selectContact` loads emails/phones and guards against a race if the selection changed mid-await; timer + stream subscription both cancelled in `close()`. |
| `ContactRecipientField` | Pass | Debounced (250 ms) per-token search with a monotonic `_requestId` to drop stale responses; clears suggestions on focus loss; reads `DriftPimStore` from `context` rather than owning a reference — matches the "no widget-level network" contract. |
| `ModuleShell` | Pass | `IndexedStack` keeps Mail/Calendar/People alive concurrently (no reload flicker); desktop rail vs mobile bottom-nav split on `isPortraitMobileLayout`; `Mail` is `AppModule.values.first` by enum order and the widget's default constructor argument. |
| Settings wiring | Pass | `CalendarViewMode.overlay`/`sideBySide` segmented control persists via `AppSettingsCubit.setCalendarViewMode`; catalogued for search. |
| Test coverage added | Pass | 18 cases in `pim_store_test.dart` (empty/multi/preserve/search/range/display-prefs/CRUD), 4 in `calendar_cubit_test.dart`, 11 in `contact_picker_test.dart`, 2 in `module_shell_test.dart`, plus `widget_test.dart` updated for the new `ModuleShell`/`DriftPimStore` constructor shape. |

---

## Risks and accepted residuals

| Risk | Severity | Disposition |
| --- | --- | --- |
| Creating an event from the day-detail sheet can target a calendar that is not `isSelectedForDisplay` | Low | The event editor's calendar dropdown lists **all** calendars (not just selected ones), and the "Add event" path is reachable from any day cell whenever `hasAnyCalendars` is true — even if the user has deselected every calendar for display (the FAB alone is gated on `hasSelectedCalendars`, but the day-sheet "Add event" button is not). A user who explicitly picks a deselected calendar in that dropdown will see the new event vanish from the grid immediately after save, because `listEventsInRange` defaults to `selectedCalendarsOnly: true`. No data loss — the event is safely persisted and reappears once its calendar is re-selected — but it is a confusing UX corner case. Recommend gating the dropdown to selected calendars, or auto-selecting a newly-targeted calendar, in a Wave 6/7 polish pass. |
| `CalendarCubit`/`PeopleCubit` eagerly query on every app launch | Low | Both cubits are constructed once at the `SynesisApp` root (not lazily per module visit) because `ModuleShell`'s `IndexedStack` builds all three module widgets immediately to support instant, flicker-free switching. This means `refresh()` fires for Calendar and People on cold start even for mail-only sessions. Cost is a handful of cheap local Drift queries (no network), and results are cached in Cubit state until the next `watchChanges()` tick — acceptable for MVP; revisit only if profiling shows a cold-start regression. |
| Local-only writes (unchanged from plan) | Low — accepted MVP | Calendar create/edit/delete persist in Drift only; `events_push` remains a no-op. Confirmed via code review (`createLocalEvent`/`updateLocalEvent`/`softDeleteEvent` never call `enqueueSyncJob`) and the `kLocalEventWriteNotice` snackbar/banner shown on every save. Matches W5-2 exactly; remote catch-up deferred to a later wave. |
| Contact/event writes from People/Calendar UI never touch CardDAV/Graph | Low — accepted MVP | Intentional per W5-3/W5-7; explicitly out of scope this wave. |
| Pre-existing `analyze` infos on touched files | Negligible | `calendar_cubit.dart` and `people_cubit.dart` each pick up 2 `prefer_initializing_formals` infos, consistent with the same lint firing across nearly every existing Cubit/service constructor in the codebase (not a new pattern introduced by Wave 5, and not an error). |

No Pri-1 defects found. Nothing added to `DEFECTS.md` for this wave.

---

## Explicitly out of scope (confirmed)

- Cross-account / cross-list drag-and-drop copy (Wave 6)
- CalDAV/CardDAV write-back (`PUT`/`PROPPATCH`); `events_push`/`contacts_push` remote sync
- Galaxy Watch companion (V2.1)
- Free/busy, rooms/resources, shared calendar ACLs, Teams deep links
- CardDAV contact create/edit from the People UI
- Recurrence editor depth beyond the basic local fields already on `CalendarEvent` (`rrule` is preserved on edit, not authored/edited in the UI)
- Wave 7 UI niceties (resizable panes, overflow sweeps, etc.)

---

## Inventory delta (for Page)

| Path | Cases / theme | Kind | Maps to |
| --- | --- | --- | --- |
| `test/pim_store_test.dart` | Empty-schema list helpers; multi-account/multi-list/multi-calendar selected-scope filtering; preserve-on-upsert for contact-list and calendar display prefs; contact upsert dedup by providerId; `searchContacts` FTS + email-LIKE + selected-list scoping + blank-query short-circuit; `listEventsInRange` overlap logic + selected/explicit/all-calendar scoping; display-pref partial-write writers; local event CRUD (create/default-calendar/no-calendar `StateError`/update/soft-delete) | unit | Wave 5 W5-6 (store gaps), W5-2 (local CRUD), W5-1/W5-5 (search scope) |
| `test/calendar_cubit_test.dart` | Month-range refresh; month navigation reload; local create+delete event round trip; `setCalendarSelected` display-pref toggle | bloc | Wave 5 W5-2, W5-4 |
| `test/contact_picker_test.dart` | `formatContactRecipient` (name+email, bare email, no-email → null, comma-quoting, embedded-quote escaping); `currentRecipientToken` parsing; `insertContactIntoField` chip insertion | unit | Wave 5 W5-1 (compose picker / recipient format compatibility) |
| `test/module_shell_test.dart` | Mail is the default module at launch (module rail present); switching to Calendar/People swaps the body without losing Mail | widget | Wave 5 W5-3 (module switcher, Mail default) |
| `test/widget_test.dart` | Updated for `ModuleShell`/`DriftPimStore` constructor shape; still asserts Unified Inbox renders by default | widget | Wave 5 regression guard (mail default, no shell regression) |

Existing regression coverage relied on for this gate:

| Path | Cases / theme | Kind | Maps to |
| --- | --- | --- | --- |
| `test/graph_pim_sync_engine_test.dart` | Graph PIM sync behavior unchanged | integration | Wave 5 Graph regression guard |
| `test/dav_pim_sync_engine_test.dart` | DAV PIM full-pull/soft-delete behavior unchanged | integration | Wave 5 DAV regression guard |
| `test/pim_sync_jobs_noop_test.dart` | `events_push`/`contacts_push` remain no-ops | unit | Wave 5 W5-2 remote-push boundary guard |

---

## Handoff to Wave 6

- **Wave 6:** **GO.** Cross-account/cross-list drag-and-drop copy can build on
  the same local `DriftPimStore` read/write surface introduced here; no
  additional store plumbing should be required beyond copy-specific create
  helpers.
- **Polish backlog:** Consider gating the event editor's calendar dropdown to
  `isSelectedForDisplay` calendars (or auto-selecting a newly targeted one) so
  a local-only create can never silently "disappear" from the visible grid.
- **Dogfood:** Operator-pending per the Wave 5 checklist's 7-step dogfood
  script (Graph/Runbox contact and calendar visibility, local CRUD staying
  local, multi-calendar overlay/side-by-side, module-switch state retention,
  Wave 3 RSVP non-regression).

*Renee — Quality Engineering · 2026-07-27*
