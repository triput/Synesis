# Synesis Defects Log

| Priority | Meaning |
| --- | --- |
| Pri-1 | Blocks daily use or data safety — fix immediately |
| Pri-2 | Important but not urgent — schedule soon |
| Pri-3 | Nice-to-have / polish |

---

## Open

> Android dogfood folder/drawer polish (2026-07-27): account chips, folder-picker sheet, title-bar **Show folders** → sheet.
>
> **V2 Wave 7 / Trish extras parking lot** (2026-07-27): operator enhancement backlog (Pri-2 / Pri-2.5 / Pri-3) parked for **Wave 7 — Final polish / Trish extras** — last if time permits; not V2.0 critical path. See [V2_PLAN.md](V2_PLAN.md) § Wave 7. **Trish calendar asks (2026-08-03):** [DEF-075](#def-075--calendar-week--weekdays-views) week/weekdays views; [DEF-076](#def-076--calendar-show-day-of-year--week-of-year) day-of-year + week-of-year. **Trish V-Next (2026-08-03):** [DEF-078](#def-078--phone-quick-reply-density--settings-toggle) phone Quick Reply; [DEF-044](#def-044--home-screen-list-widget-per-account-mail--open-in-app-aquamail-bar) per-account list widgets (AquaMail bar) — **Pri-2**. **Trish Pri-3 (2026-08-04):** [DEF-079](#def-079--contact-postal-addresses--open-in-map-apps) contact postal addresses + Maps/Waze. **Wave 6 E11 dogfood (2026-08-04):** [DEF-080](#def-080--gmail-imap-too-many-simultaneous-connections-on-body-fetch).

### DEF-080 — Gmail IMAP: Too many simultaneous connections on body fetch

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | Open |
| Target | Post–Wave 6 / sync hardening (Tesla) |
| Area | `ImapSmtpMailProvider`, `ProviderRegistry`, `ImapIdleService`, `SyncEngine._withProvider`, `MessageBodyCache` |
| Platforms | Windows (repro), Android likely same account |
| Logged | 2026-08-04 |
| Found by | **Trish** (Wave 6 E11 desktop dogfood — Gmail XOAUTH) |
| Related | IMAP IDLE; Gmail connection cap (~15 per account across clients) |

**Summary**  
**Trish:** Opening a Gmail message on desktop shows reading-pane error:

`ProtocolException: Unable to fetch the IMAP message body.`  
`Cause: [ALERT] Too many simultaneous connections. (Failure)`

**Expected**  
Body fetch reuses a single per-account IMAP session (or waits/queues) so Gmail’s simultaneous-connection limit is not exceeded by Synesis alone; transient ALERT should retry with backoff.

**Actual**  
`ProviderRegistry.resolve` returns a **new** `ImapSmtpMailProvider` (new `ImapClient`) on every resolve. `ImapIdleService` holds one long-lived connection; sync jobs `_withProvider` open another then dispose; UI body fetch resolves yet another. Combined with phone/other IMAP clients, Gmail rejects with `[ALERT] Too many simultaneous connections`.

**Notes**  
Not Wave 6 DnD scope — mail path. Workaround for dogfood: wait for sync idle, retry open; temporarily stop phone Synesis / other IMAP clients on that mailbox if needed. Fix direction: per-account provider/session cache + serialized IMAP ops (or share IDLE connection for fetches) + ALERT-specific retry.

---

### DEF-079 — Contact postal addresses + open in map apps

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open (enhancement) |
| Target | **V-Next** |
| Area | PIM contacts schema / `DriftPimStore`; Graph / Google / CardDAV address mapping; People UI; `url_launcher` (or equiv.) deep links |
| Platforms | Windows, Android (map apps vary by platform) |
| Logged | 2026-08-04 |
| Found by | **Trish** |
| Related | Wave 2/G contact sync; People workspace |

**Summary**  
**Trish:** When providers supply physical / postal addresses on contacts, Synesis should store and show them in People. Ideally tap-to-open in Google Maps, Waze, or other installed map apps (platform chooser / deep links).

**Expected**  
- Persist structured or display-ready address when Graph / Google / CardDAV ADR (or equivalent) is present.
- People detail shows address(es); action to open in an external map app.
- No inventing addresses; skip when absent.

**Actual**  
Contacts map emails/phones primarily; postal addresses are not a first-class People surface yet.

**Notes**  
Non-urgent Pri-3 — not Wave 6 / 6b / 6c.

---

### DEF-078 — Phone Quick Reply: reclaim reading space + settings toggle

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | Open (enhancement) |
| Target | **V-Next** |
| Area | `lib/ui/shell/reading_pane.dart`, `QuickReplyBar` (`message_attachments_panel.dart`), `AppSettingsCubit` / settings UI |
| Platforms | Phone / narrow (desktop Quick Reply stays valuable) |
| Logged | 2026-08-03 |
| Found by | **Trish** (Wave 6P E7 dogfood) |
| Related | [DEF-069](#def-069--reading-pane-remote-images-banner--quick-reply-overflow-33px), closed [DEF-066](#def-066--quick-reply-send-clipped--horizontal-overflow-on-android) |

**Summary**  
**Trish:** On phone (e.g. Galaxy S26 Ultra), Quick Reply + Send eat too much reading pane — often ~6 lines of body visible. Desktop Quick Reply is fine and should stay.

1. **Density / placement** — Whether Quick Reply is on or off, the compose chrome must sit farther down so substantially more message body is readable on first paint (toolbar + attachments already compete; QR must not dominate).
2. **Settings toggle** — User-facing setting to enable/disable Quick Reply. When **off**, reclaim that vertical space entirely for reading (no empty QR slab).

**Expected**  
- Setting (e.g. “Show Quick Reply”) persisted via app settings; default can stay on for desktop, prefer off or compact on phone (product decision at implement).
- Phone reading pane prioritizes body height; QR is compact or collapsed when enabled.
- Desktop behavior remains the current always-useful strip unless the same setting hides it.

**Actual**  
`showQuickReply` is layout/policy only (not trash, etc.) — no settings flag; QR bar is a persistent bottom chunk on phone reading.

**Notes**  
Pri-2 **V-Next** — not Wave 6P/6 critical path. Keep desktop love; fix phone pain.

---

### DEF-077 — New event Calendar dropdown overflows long account labels (~286px)

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-08-03) — Trish dogfood GO (`87ec66a`) |
| Area | `lib/ui/calendar/calendar_workspace.dart` (`_EventEditorForm` calendar `DropdownButtonFormField`) |
| Platforms | Android (phone); any narrow width |
| Logged | 2026-08-03 |
| Found by | Trish (Wave 6P E7 dogfood screenshot) |
| Related | [DEF-074](#def-074--calendar-day-sheet-add-event-clipped-by-android-system-nav), closed Edit-account dropdown overflow pattern |

**Summary**  
New event sheet: Calendar field shows yellowjacket `OVERFLOWED BY ~286 PIXELS` when calendar name + account label is long (e.g. `trish@trishputnam.com (TP@T…)`).

**Root cause**  
`DropdownButtonFormField` without `isExpanded: true` — selected-item `Text` ellipsis never gets a bounded width.

**Fix**  
`isExpanded: true` + `maxLines: 1` / `TextOverflow.ellipsis` on item labels (same pattern as Edit account).

---

### DEF-076 — Calendar: show day-of-year and week-of-year

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open (enhancement) |
| Target wave | **Wave 7 / Trish extras** |
| Area | `lib/ui/calendar/calendar_workspace.dart` (header / day chrome) |
| Platforms | All |
| Logged | 2026-08-03 |
| Found by | **Trish** (product ask during Wave 6P dogfood) |
| Related | [DEF-075](#def-075--calendar-week--weekdays-views), [DEF-071](#def-071--calendar-module-should-default-to-today) |

**Summary**  
**Trish:** Surface **day of the year** (1–365/366) and **week of the year** (ISO week preferred unless product picks locale week) in Calendar chrome — e.g. near the month/week label or on the focused day. Operator actually uses these numbers in daily work.

**Expected**  
Visible ordinals for the focused date (and optionally today): `Day 216` / `Week 32` (exact copy TBD). Update when navigating months/weeks/days.

**Actual**  
Calendar shows month name + year (and Agenda) only — no DOY / WOY.

**Notes**  
Pri-3 polish, but **operator-used** — keep on Wave 7 Trish bullet list; don’t silently drop.

---

### DEF-075 — Calendar: Week and Weekdays views

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open (enhancement) |
| Target wave | **Wave 7 / Trish extras** |
| Area | `lib/ui/calendar/calendar_workspace.dart`, `CalendarCubit` / `CalendarState` (view toggle beyond Month/Agenda) |
| Platforms | All |
| Logged | 2026-08-03 |
| Found by | **Trish** (product ask during Wave 6P dogfood) |
| Related | [DEF-071](#def-071--calendar-module-should-default-to-today), [DEF-076](#def-076--calendar-show-day-of-year--week-of-year) |

**Summary**  
**Trish:** Add Calendar view options for **Week** (7-day) and **Weekdays** (Mon–Fri) alongside existing Month and Agenda.

**Expected**  
View switcher (or equivalent) offers Month / Week / Weekdays / Agenda; Week and Weekdays show timed events in a usable column layout; navigation advances by week.

**Actual**  
Only **Month** and **Agenda** (`showAgenda` toggle). Wave 5 shipped “month + week/agenda” in the plan sense of Agenda, not a true week grid.

**Notes**  
Pri-3 Wave 7 Trish extras — honest scope creep; not V2.0 critical path.

---

### DEF-074 — Calendar day sheet “Add event” clipped by Android system nav

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-08-03) — Trish dogfood GO (`87ec66a`) |
| Area | `lib/ui/calendar/calendar_workspace.dart` (`showDayEventsSheet`, `showEventEditorSheet`) |
| Platforms | Android |
| Logged | 2026-08-03 |
| Found by | Trish (Wave 6P E7 dogfood screenshot) |
| Related | Closed [DEF-065](#def-065--compose--full-reply-send-clipped-by-android-system-navigation-bar), [DEF-070](#def-070--calendar-month-view-header-right-overflow--day-cell-bottom-overflow) |

**Summary**  
Day-events bottom sheet: **+ Add event** sits under the Android system navigation / gesture bar and is hard to tap.

**Root cause**  
Sheet padding used `viewInsets.bottom` (keyboard) only, not `viewPadding.bottom` (system nav). Modal sheets are above Scaffold `SafeArea`, so workspace SafeArea does not protect sheet chrome.

**Fix**  
Capture `viewPadding.bottom` from the **caller** context (modal sheet MediaQuery often reports 0), then pad with `viewInsets + systemBottom` on day sheet and event editor sheet.

---

### DEF-073 — Graph listAttachments 400: contentId not on microsoft.graph.attachment

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-08-03) — Trish dogfood GO (`87ec66a`) |
| Area | `lib/protocol/graph_mail_provider.dart` (`listAttachments`) |
| Platforms | Graph / Exchange accounts (Android dogfood + all) |
| Logged | 2026-08-03 |
| Found by | Trish (Wave 6P E7 dogfood screenshot) |
| Related | [DEF-069](#def-069--reading-pane-remote-images-banner--quick-reply-overflow-33px) |

**Summary**  
Opening a Graph message with attachments shows  
`ProtocolException(400): Parsing OData Select and Expand failed: Could not find a property named 'contentId' on type 'microsoft.graph.attachment'.`  
in the reading pane (attachments strip).

**Root cause**  
`$select=…,contentId` is validated against the polymorphic base type `microsoft.graph.attachment`. `contentId` is declared only on `microsoft.graph.fileAttachment`.

**Fix**  
Use OData cast: `microsoft.graph.fileAttachment/contentId` (`kGraphAttachmentListSelect`).

---

### DEF-072 — People “Back to contacts” does not leave contact detail

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-08-03) — Trish dogfood GO (`87ec66a`) |
| Area | `lib/ui/people/people_workspace.dart` (`_PeopleListOnly`, `_ContactDetailPage`), `PeopleCubit.selectContact` |
| Platforms | Android (phone / narrow) |
| Logged | 2026-08-03 |
| Found by | Trish (Wave 6P E7 dogfood) |
| Related | [DEF-071](#def-071--calendar-module-should-default-to-today) |

**Summary**  
On People contact detail, **Back to contacts** appears to do nothing — detail stays on screen.

**Root cause**  
Mobile detail was a conditional widget swap (`selected != null ? detail : list`) with no nested route. Clearing selection alone proved unreliable in dogfood; in-flight `selectContact` email/phone loads could also race the clear.

**Fix**  
Nested declarative `Navigator` pages for list → detail; Back pops / clears selection; selection epoch ignores stale loads after clear.

---

### DEF-071 — Calendar module should default to Today

| Field | Value |
| --- | --- |
| Priority | **Pri-2.5** (enhancement) |
| Status | Open (enhancement) |
| Target | **V-Soon / V-Next** (prefer over Wave 7 unless pulled forward) |
| Area | `lib/ui/calendar/calendar_workspace.dart`, `CalendarCubit` / `CalendarState` (`showAgenda`, `focusedMonth`, `goToToday`) |
| Platforms | All |
| Logged | 2026-08-03 |
| Found by | Trish (product ask during Wave 6P dogfood) |
| Related | Closed Wave 5 Calendar UI; [DEF-070](#def-070--calendar-month-view-header-right-overflow--day-cell-bottom-overflow) |

**Summary**  
Opening the Calendar module should land on **Today** by default — not a cold month-grid entry that requires tapping Today. Prefer Agenda (or a dedicated Today / day surface) centered on the current date; month grid remains available via the existing Month/Agenda toggle.

**Expected**  
First paint of Calendar focuses today (date + useful “what’s on today” surface). Exact chrome (Agenda-first vs day sheet vs new Today view) decided at implementation; persist last view only if product later wants that override.

**Actual**  
Calendar opens on the month grid for `focusedMonth` (typically current month) with `showAgenda == false`. `goToToday` exists but is operator-initiated.

**Notes**  
Enhancement backlog — dogfood UX preference, not a layout defect. Parked **V-Soon / V-Next**; may pull into Wave 7 only if operator bandwidth after Waves 6P/6.

---

### DEF-070 — Calendar month view: header RIGHT overflow + day-cell BOTTOM overflow

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-08-03) — Trish dogfood GO (`87ec66a`) |
| Area | `lib/ui/calendar/calendar_workspace.dart` (`_CalendarHeader`, `_DayCell`, `_MonthGridView`) |
| Platforms | Android (phone) |
| Logged | 2026-08-03 |
| Found by | Trish (Wave 6P E7 dogfood screenshot) |
| Related | [DEF-069](#def-069--reading-pane-remote-images-banner--quick-reply-overflow-33px) |

**Summary**  
Calendar month view on phone: `RIGHT OVERFLOWED BY ~203 PIXELS` on the chrome row (month nav + Today + Month/Agenda), plus pervasive `BOTTOM OVERFLOWED BY ~0.76 PIXELS` (and small variants) in day cells with event chips.

**Root cause**  
1. Single header `Row` packed fixed 160px month label, chevrons, Today, and a wide `SegmentedButton` — ~500dp intrinsic vs ~332dp usable.  
2. Day cells always painted up to 3 chips in a non-flex `Column` inside a tight 6-row `childAspectRatio` grid; fractional text metrics overflow by &lt;1px.

**Fix**  
Narrow (&lt;520dp) header stacks month nav / Today+toggle; month label `Expanded`; day cells size chip count to remaining height via `LayoutBuilder` + non-scrolling `ListView`; taller cells for 6-row months.

---

### DEF-069 — Reading pane: remote-images banner + Quick Reply overflow (~33px)

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-08-03) — Trish dogfood GO (`87ec66a`) |
| Area | `lib/ui/shell/message_body_view.dart`, `lib/ui/shell/message_attachments_panel.dart` (`QuickReplyBar`) |
| Platforms | Android |
| Logged | 2026-08-03 |
| Found by | Trish (Wave 6P E7 dogfood screenshot) |
| Related | Closed [DEF-066](#def-066--quick-reply-send-clipped--horizontal-overflow-on-android) |

**Summary**  
Open message with remote images blocked + Quick Reply: yellow/black ribbon `BOTTOM OVERFLOWED BY 33 PIXELS` between the banner and the Quick Reply field. “Remote images blocked” crushed into a one-letter-wide vertical column beside “Load images for this message.”

**Root cause**  
1. Banner `Row`: long `TextButton` took intrinsic width; `Expanded` label got ~0 flex → vertical letter stack; banner taller than the 72px budget when stacked.  
2. DEF-066 added `viewPadding.bottom` to `QuickReplyBar` while the reading pane already sits above `ModuleNavigationBar` / Scaffold body — double-counting system insets (~48px) and starving the body `Column`.

**Fix**  
Stack / `Flexible` banner layout under ~420 dp; raise banner height budget to 96px; Quick Reply insets = keyboard `viewInsets.bottom` only.

---

### DEF-068 — Add account sheet overflows (BOTTOM OVERFLOWED BY ~85px)

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-08-03) — Trish dogfood GO (`87ec66a`) |
| Area | `lib/ui/account/add_account_sheet.dart` |
| Platforms | Android |
| Logged | 2026-08-03 |
| Found by | Trish (Wave 6P E7 dogfood screenshot) |
| Related | [DEF-063](#def-063--manage-accounts-sheet-overflows-no-scroll-yellowblack-stripes) |

**Summary**  
Add account (Microsoft tab) showed yellow/black ribbon: `BOTTOM OVERFLOWED BY 85 PIXELS` over Accent color. Jules had flagged this sheet as still using `viewInsets`-only padding after the compose/accounts sweep.

**Root cause**  
Fixed `SizedBox(height: 0.85 * screen)` plus a `Column` with title, blurb, tabs, email, display name, and `AccountColorPicker` **above** `Expanded` `TabBarView` — fixed chrome taller than remaining space on phone.

**Fix**  
Sheet sized from `LayoutBuilder` max height + `SafeArea`; identity fields (display/accent/address) moved into each tab’s `ListView` so only title+TabBar stay fixed.

---

### DEF-067 — Reinstall / clear-data option that preserves accounts and local mailbox

| Field | Value |
| --- | --- |
| Priority | **Pri-3** (enhancement; dogfood friction) |
| Status | Open |
| Target wave | **Wave 7 / Trish extras** (or post-V2 release prep) |
| Area | Backup/export of accounts + encrypted DB; Android clear-data / sideload reinstall path |
| Platforms | Android first (also Windows useful) |
| Logged | 2026-08-03 |
| Found by | Trish (Wave 6P E7 dogfood) |

**Summary**  
Operator must repeatedly clear Synesis and re-add real accounts when clean-installing dogfood APKs. Wants an option to **reinstall/upgrade while preserving accounts and local mail/PIM data** (or an explicit backup → restore flow), so test accounts can be wiped without redoing OAuth for production accounts.

**Expected**  
Documented path (settings action and/or sideload checklist): export/backup credentials+DB (or “preserve data on uninstall” guidance), restore on next install; or “Reset demo data only” without wiping linked accounts.

**Actual**  
Clean install / clear storage wipes everything; operator re-auths and re-adds accounts each cycle.

**Notes**  
Not urgent for V2.0 critical path. Touches secure storage, DB encryption keys, and OAuth tokens — design carefully (Tesla + Jules). Related: encryption-at-rest, account remove WIPE confirmation.

---

### DEF-063 — Manage Accounts sheet overflows (no scroll; yellow/black stripes)

| Field | Value |
| --- | --- |
| Priority | **Pri-1** (blocks multi-account dogfood on phone) |
| Status | **Closed** (2026-08-03) — Trish dogfood: hamburger drawer ribbon gone |
| Area | `lib/ui/shell/folder_sidebar.dart` (drawer), `lib/ui/shell/mail_navigation_drawer.dart`; also account sheets from earlier passes |
| Platforms | Android (also narrow Windows sheets) |
| Logged | 2026-08-03 |
| Found by | Trish (Wave 6P E7 Android dogfood) |
| Related | [DEF-039](#def-039--remove-account-confirmation-dialog-overflows), closed [DEF-040](#def-040--edit-account-sheet-overflows) / [DEF-059](#def-059--edit-account-re-authenticate-button-vertically-clipped) |
| Tests | `test/account_sheets_overflow_test.dart`; drawer overflow case in `test/mail_navigation_drawer_test.dart` |

**Summary**  
Yellow/black overflow ribbon on Android. Passes 1–3 treated Manage/Edit account sheets. **Operator screenshot (2026-08-03):** hamburger drawer — `BOTTOM OVERFLOWED BY 49 PIXELS` over Snoozed / ACCOUNTS, with Compose…Settings footer still visible.

**Root cause (pass 4)**  
`MailNavigationDrawer` footer (7 ListTiles) left a short `Expanded` for `FolderSidebar`. Sidebar used `Column` of fixed MAIL tiles + inner `Expanded`; when allocated height &lt; fixed MAIL block (~49px short), Flutter painted the overflow ribbon. No scroll.

**Fix (pass 4)**  
`embeddedInDrawer` `FolderSidebar` is a single `ListView` (MAIL + ACCOUNTS); `_DrawerAccountsBody` shrink-wraps inside it.

**Also (2026-08-03):** Settings → Accounts **empty** state overflowed by **15px** (`EmptyState` in tight `Expanded`). `EmptyState` now scrolls when height-bounded; empty Manage Accounts uses `ListView`.

---

**Summary**  
With **3 accounts**, Manage Accounts / Edit Account showed Flutter yellow/black overflow stripes. No usable scroll on phone.

**Root cause (pass 1)**  
Modal `primaryScroll` existed but Settings → Accounts used shrink-wrap embed that still overflowed.

**Root cause (pass 2 — still ribbon after rebuild)**  
Sheets used a **fixed `SizedBox(height: 0.85 * screen)`** (or equivalent) **inside `SafeArea` + extra `viewPadding` padding**, so the forced height exceeded the parent's max constraint → vertical overflow ribbon. Edit Account also used `ListTile` + trailing `DropdownButton` ("Default (default)") which **horizontally overflows** ~360dp phones.

**Fix (pass 2)**  
`LayoutBuilder` + `ConstrainedBox(maxHeight: parent * 0.95)`; form/list use `Expanded` + `ListView`; sync profile `DropdownButtonFormField(isExpanded)`; account card ellipsis; compact icon buttons. **Still ribbon on device.**

**Root cause (pass 3)**  
Compound layout debt, not a single missed widget:

1. **Loose max height on modal sheets** — `ConstrainedBox(maxHeight: …)` does not give `Column`+`Expanded` a tight height the way a modal + drag-handle `Stack` needs; production now uses `SizedBox(height: layoutMax * 0.95)` from the already-padded `LayoutBuilder` max (fallback subtracts `padding`/`viewInsets`, never raw `0.9 * screen`).
2. **Edit Account sticky footer too tall** — signatures + templates + Save stayed outside the `ListView`; on short phones / open keyboard the non-flex column exceeded the sheet → vertical ribbon. Secondary actions moved into the scroll body; only Save stays sticky.
3. **Custom color dialog** — `SizedBox(width: 360)` ignored dialog insets on ~360dp phones (horizontal overflow risk).
4. **Settings wide Accounts** — `primaryScroll` body lacked a tight height bound from the rail pane `LayoutBuilder`.

**Fix (pass 3)**  
Tight `SizedBox` sheet chrome; Edit Account scrollable secondary actions; color dialog `min(360, width - 48)`; Settings Accounts `SizedBox(height: constraints.maxHeight)`; phone widget guards in `account_sheets_overflow_test.dart`.

---

### DEF-065 — Compose / full reply Send clipped by Android system navigation bar

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-08-03) |
| Area | `lib/ui/compose/compose_sheet.dart` |
| Platforms | Android |
| Logged | 2026-08-03 |
| Found by | Trish (Wave 6P E7 Android dogfood) |
| Related | Closed [DEF-022](#def-022--compose-send-hung-on-sending-android) |

**Summary**  
Full reply / compose bottom sheet: Send button not visible; could not scroll to last lines of body. Android gesture navigation bar ate bottom chrome.

**Root cause**  
Sheet padding used `viewInsets` (keyboard) only, not `viewPadding` (system nav). Unconstrained `SingleChildScrollView` grew behind nav bar; Send row scrolled off-screen.

**Fix**  
`SafeArea` + `viewPadding.bottom` on modal wrapper; `ConstrainedBox(maxHeight: ~92%)`; sticky footer Row (Save draft / Send) outside scroll body.

---

### DEF-066 — Quick Reply Send clipped / horizontal overflow on Android

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-08-03) |
| Area | `lib/ui/shell/message_attachments_panel.dart` (`QuickReplyBar`), `lib/ui/shell/reading_pane.dart` |
| Platforms | Android |
| Logged | 2026-08-03 |
| Found by | Trish (Wave 6P E7 Android dogfood) |
| Related | Closed [DEF-001](#def-001--workspace-ctrl-shortcuts-only-fire-when-quick-reply-has-focus) |

**Summary**  
Quick Reply appeared broken — Send not tappable, field clipped by system nav, possible yellow/black overflow on narrow widths.

**Root cause**  
`QuickReplyBar` Row (field + full-reply icon + Send) had no `viewPadding.bottom` and could horizontally overflow (~360 dp). No `TextInputAction.send` / `onSubmitted`.

**Fix**  
Responsive stack layout under 360 dp; keyboard send action; clearer full-reply icon. Initial `viewPadding.bottom` inset was **wrong for in-scaffold reading pane** (double-count with module nav) — corrected under [DEF-069](#def-069--reading-pane-remote-images-banner--quick-reply-overflow-33px) to keyboard `viewInsets` only.

---

### DEF-064 — Ship Synesis public OAuth client IDs for distribution builds

| Field | Value |
| --- | --- |
| Priority | **Pri-1** (blocks handoff / store / friend builds) |
| Status | Open |
| Target | Release prep / pre-distribution gate (not Wave 6 DnD) |
| Area | `lib/auth/oauth_public_clients.dart`, CI/release build, README |
| Platforms | Windows + Android |
| Logged | 2026-08-03 |
| Found by | Trish (product question during 6P dogfood) |
| Related | Closed [DEF-038](#def-038--microsoft--google-sign-in-missing-in-dogfood-build-pri-1) |

**Summary**  
Product path is: end users Sign in with Synesis-owned **public** Entra + Google clients baked into `oauth_public_clients.dart`. Those defaults are currently **empty** (GitHub push-protection / scrub). Dev overrides (`oauth_local.json` / dart-defines) work on Windows from the repo cwd but **do not** ship inside a plain `flutter build apk`. Android dogfood therefore shows “Google OAuth is not configured in this build,” blocking People/Calendar re-auth.

**Expected**  
Official / friend-handoff builds carry Synesis public client IDs (Desktop + Android package/SHA clients). End users never need `oauth_local.json`. CI may inject IDs at build time if git must stay scrubbed.

**Actual**  
Empty shipped defaults + naked debug APK → OAuth UI disabled on device; calendar PIM re-auth blocked.

**Notes**  
Public/native PKCE IDs are not confidential secrets; still avoid careless public gist dumps. Android needs a Google OAuth Android client matching `net.livebytes.synesis` + signing cert SHA-1 per keystore (debug vs release). Track as release-prep before distributing beyond operator.

---

### DEF-050 — Right-click mark read on message list (solo vs thread)

| Field | Value |
| --- | --- |
| Priority | **Pri-2.5** |
| Status | Open (enhancement) |
| Target wave | **Wave 7 / Trish extras** |
| Area | `lib/ui/shell/message_list_pane.dart` (`_MessageRow`, `_ThreadRow`), `MailboxCubit.setUnreadBulk` |
| Platforms | All (desktop right-click; phone long-press) |
| Logged | 2026-07-27 |

**Summary**  
Operator wants a context-menu **Mark read** action on message rows in the list/inbox screen. **Solo message:** mark that message read immediately. **Conversation thread** (2+ messages in the row): prompt **“This message or entire thread?”** and apply read state to the chosen scope.

**Expected**  
Per-row context menu (right-click / long-press) with Mark read; thread rows disambiguate message-only vs whole-thread via a short confirmation; reuse existing local + provider Seen paths (`setUnreadBulk`).

**Actual**  
Message rows expose mark read/unread only via multi-select bulk toolbar and keyboard shortcuts. Folder tree already has mark-all-read context menus (`folder_sidebar.dart`); list rows do not.

**Notes**  
Enhancement backlog — not urgent, not blocking daily use. **Target wave: Wave 7 / Trish extras** (final polish bucket; honest scope creep). Related: [DEF-007](#def-007--sync-header-refresh-can-overwrite-local-readunread), [DEF-009](#def-009--rapid-concurrent-mark-readunread-has-no-in-flight-guard); closed [DEF-034](#def-034--no-auto-mark-as-read-after-viewing-a-message) (auto-mark on read dwell).

---

### DEF-051 — Bcc addresses written into outbound SMTP MIME headers

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | Open |
| Area | `lib/mime/multipart_builder.dart` (`buildMultipartMessage`), `ImapSmtpMailProvider.sendEnvelope` / `_appendToSentBestEffort` |
| Platforms | All IMAP/SMTP |
| Logged | 2026-07-27 |
| Found by | Renee (SMTP send audit, v2.0) |

**Summary**  
Outbound MIME built for SMTP includes a `Bcc:` header whenever the envelope has BCC recipients. That header is part of the SMTP `DATA` payload (and the best-effort IMAP Sent APPEND). RFC-correct SMTP clients keep BCC only on the envelope (`RCPT TO`) and omit it from headers visible to To/Cc recipients / stored copies that leave the MUA.

**Evidence**  
`multipart_builder.dart` writes `Bcc: ${envelope.bcc.join(', ')}` into the hand-built MIME. `sendEnvelope` correctly passes BCC into enough_mail `recipients:` (so delivery works), but does not strip the header before `sendMessage` / Sent APPEND. Many MTAs strip BCC before delivery; that is not guaranteed, and Sent copies retain the leak for anyone with mailbox access.

**Expected**  
MIME `DATA` / Sent APPEND omit `Bcc:`; BCC remains only in the SMTP recipient list (and Graph `bccRecipients`).

**Actual**  
`Bcc:` is serialized into the message bytes.

**Notes**  
Localized fix candidate (omit Bcc header in builder; optionally strip before APPEND). Do not thrash outbox while Wave 1 PIM is in flight unless operator prioritizes. Related: closed DEF-022 (multi-recipient BCC support), DEF-048 (explicit `recipients:`).

---

### DEF-052 — Cc/Bcc-only send injects account address as To

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open |
| Area | `lib/protocol/imap_smtp_mail_provider.dart` (`sendEnvelope`), `lib/mime/multipart_builder.dart`, `lib/protocol/graph_mail_provider.dart` (`_buildOutgoingMessage`) |
| Platforms | IMAP/SMTP and Graph |
| Logged | 2026-07-27 |
| Found by | Renee (SMTP send audit, v2.0) |

**Summary**  
Compose allows send with empty To when Cc and/or Bcc are set. Both providers then synthesize a To recipient equal to the sending account address so the MIME builder / Graph payload always has a non-empty To list.

**Evidence**  
- `buildMultipartMessage` throws if `envelope.to.isEmpty`.  
- `ImapSmtpMailProvider.sendEnvelope` sets `to: <String>[user]` when To is empty but Cc/Bcc are not.  
- Graph `_buildOutgoingMessage` uses `toClean.isNotEmpty ? toClean : <String>[envelope.from]` for `toRecipients`.

**Impact**  
1. Visible `To:` header shows the sender (unexpected UX / may confuse recipients and filters).  
2. SMTP `RCPT TO` includes the sender — self-copy of every Cc/Bcc-only send.  
3. Not a hard send failure, but a correctness footgun if dogfood uses Cc-only.

**Expected**  
Allow empty To when Cc/Bcc present; omit To header or emit `To: undetermined-recipients:;` / empty To per common MUA practice; do not add self as To unless the user did.

**Notes**  
Fix needs multipart builder + IMAP/SMTP + Graph alignment. Low urgency vs Wave 1 PIM.

---

### DEF-053 — SMTP send residual risk (post DEF-045/047/048 audit)

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open (investigation / watchlist) |
| Area | Compose → outbox → `SyncEngine._sendOutbox` → `ImapSmtpMailProvider.sendEnvelope` → `actionableSendError` |
| Platforms | IMAP/SMTP (esp. Google Workspace XOAUTH2) |
| Logged | 2026-07-27 |
| Found by | Renee (SMTP send audit, v2.0) |

**Verdict**  
No additional Pri-1 “send hard-fails for valid To” smoking gun beyond closed DEF-045 / DEF-047 / DEF-048. Remaining issues are footguns, privacy (DEF-051), Cc-only correctness (DEF-052), and diagnosis/coverage gaps. Operator “can’t quite pin down” symptoms are most likely intermittent **From/alias/policy** failures (still surface raw `Server said:` after DEF-047) or residual UX confusion — not another empty-`recipientAddresses` class bug (DEF-048 path is explicit `recipients:` + `from:`).

**Hottest paths**  
1. `compose_sheet._queueSend` → outbox `queued` → `send_outbox` job → `_awaitOutboxOutcome` (45s + `kickFresh`)  
2. `OutgoingMessageBuilder.build` → `buildMultipartMessageInIsolate` → `MimeMessage.parseFromData` → `smtp.sendMessage(..., recipients:, from:)`  
3. `actionableSendError` bucket order (auth → TLS → network → sender → no-recipients → Graph header → recipient → size)

**Residual risks (code-backed)**  
| Risk | Evidence | Severity |
| --- | --- | --- |
| BCC header leak | DEF-051 | Pri-2 |
| Cc/Bcc-only synthetic To | DEF-052 | Pri-3 |
| Missing attachment blobs silently omitted | `OutgoingMessageBuilder.build` skips null blob paths; only missing *files* throw in multipart | Pri-2 soft (send succeeds without attachment) |
| No client `Message-ID` on SMTP MIME | `multipart_builder` omits Message-ID (server may add; reply threading to own Sent weaker) | Pri-3 |
| Error-bucket overbreadth | Auth bucket matches bare `token` / `oauth` / `401`; TLS bucket matches bare `tls` — possible miscategorization if server text is odd | Pri-3 |
| Legacy `MailProvider.send` / default `sendEnvelope` | No 45s step timeouts; MessageBuilder path (not hand MIME). Sync uses IMAP/Graph overrides — low live risk | Pri-3 |
| DEF-047 doc inconsistency | Early investigation claimed parse populated `recipientAddresses`; DEF-048 proved that wrong for hand-built MIME | Docs only (closed) |

**Test coverage**  
Present: `send_error_messages_test.dart` (047/048/049 buckets), `mime_builder_test.dart` (DEF-048 parse quirk), `sync_engine_send_outbox_test.dart` (failure surfacing / multi-recipient).  
Gaps: no integration test that IMAP `sendEnvelope` passes `recipients:`/`from:`; no Cc-only / BCC-header assertions; no missing-blob attachment omit; no XOAUTH vs password SMTP auth unit; no reply `In-Reply-To`/`References` on IMAP MIME regression.

**Recommended dogfood probes (Trish)**  
1. Normal To send on Workspace IMAP (`trish@trishputnam.com` → external) — confirm success **and** that any failure banner shows honest `Server said:` (From/alias vs RCPT).  
2. Reply on IMAP (not Graph) — confirm threading headers present in Sent / recipient client.  
3. Cc-only (empty To) — observe whether self appears in To and receives a copy (DEF-052).  
4. Bcc + one To — inspect raw source at recipient: is `Bcc:` visible? (DEF-051).  
5. Attachment send — delete/move blob mid-compose or corrupt ref; confirm fail vs silent drop.  
6. Outbox Retry after forced airplane-mode fail — reclaim `sending`→`queued`, actionable error, successful retry.  
7. Schedule-send past `sendAfter` — fires on next kick, not stuck queued forever.

**Related closed**  
DEF-022, DEF-023, DEF-045, DEF-047, DEF-048, DEF-049 (Graph-only).

---

### DEF-054 — Resizable mail panes on Windows (drag vertical splitters)

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open (enhancement) |
| Target wave | **Wave 7 / Trish extras** |
| Area | `lib/ui/shell/mail_workspace.dart` (account rail), `lib/ui/shell/mail_split_layout.dart` (folder sidebar / list / reading), `lib/ui/theme/density.dart` (`sidebarWidth`, `listWidth`) |
| Platforms | Windows desktop (primary); consider macOS/Linux parity after Windows dogfood |
| Logged | 2026-07-27 |

**Summary**  
Operator wants Outlook-style **draggable vertical splitters** between the desktop mail panes so horizontal widths can be adjusted on demand: account rail | folder sidebar | message list | reading pane (reading-pane-right layout). Good-to-have polish — makes daily use more comfortable; not a showstopper.

**Expected**  
Drag handles between adjacent panes resize them within sensible min/max bounds; widths persist across sessions (e.g. `AppSettings` or layout prefs); Visual Focus and reading-pane top/bottom modes remain coherent; no overflow regressions on narrow windows.

**Actual**  
W5 desktop shell uses fixed widths: account rail ~88px, folder sidebar and list widths from density tokens (`SizedBox` / `sidebarWidth` / `listWidth` in `MailSplitLayout`). No user-resizable splitters.

**Notes**  
Enhancement backlog — not urgent, not blocking daily use or Wave 2 PIM. **Target wave: Wave 7 / Trish extras** (Outlook-style splitters when Trish has bandwidth). Related: [W5_WINDOWS_CHECKLIST](W5_WINDOWS_CHECKLIST.md) (fixed four-pane layout landed); [UI enhancement sweep](ROADMAP.md#ui-enhancement-sweep-planui_enhancement_sweepmd).

---

### DEF-055 — Show sent items in conversation threads

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | Open (enhancement) |
| Target wave | **Wave 7 / Trish extras** |
| Area | `lib/mailbox/message_list_projector.dart`, `lib/ui/mailbox/mailbox_cubit.dart`, `lib/ui/mailbox/mailbox_state.dart`, folder/message query paths |
| Platforms | All |
| Logged | 2026-07-27 |

**Summary**  
Operator loses track of which conversations they’ve responded to and where their replies sit in the thread. Wants an option to **include Sent items** in conversation threading / thread view so outbound replies appear in context with the rest of the conversation.

**Expected**  
User-toggle (e.g. settings or folder/view option) merges Sent-folder messages into thread groups when they share the same thread key; expanded thread rows show operator replies in chronological order alongside received mail; Sent-only browsing still works when the toggle is off.

**Actual**  
Thread projection groups messages from the active folder/query only. Sent replies typically live under Sent and are not surfaced inside Inbox/other-folder thread rows, so conversation context is incomplete for “did I reply?” triage.

**Notes**  
Enhancement backlog — important for daily mail triage but not blocking Wave 2 PIM. **Target wave: Wave 7 / Trish extras.** Related: [DEF-042](#def-042--expandcollapse-chevron-and-1-badge-on-single-message-threads) (thread chrome); `ThreadDisplayMode` / `MessageListProjector`.

---

### DEF-056 — Thread/list sort: oldest first vs newest first

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | Open (enhancement) |
| Target wave | **Wave 7 / Trish extras** |
| Area | `lib/mailbox/message_list_projector.dart` (`_compareNewestFirst`), `lib/query/message_query.dart`, `lib/ui/settings/` (list sort preference), `lib/ui/shell/message_list_pane.dart` |
| Platforms | All |
| Logged | 2026-07-27 |

**Summary**  
Operator wants a **sort direction control** for message lists and threaded conversation views: **Show oldest first** or **Show newest first** (user-selectable).

**Expected**  
Setting or per-view toggle persists preference; flat and threaded list sections honor the chosen order (including within expanded thread children); date section headers remain coherent for both directions.

**Actual**  
List projection and query paths sort **newest-first** only (`_compareNewestFirst` in `MessageListProjector`; `message_query.dart` newest-first sort). No user-facing oldest-first option.

**Notes**  
Enhancement backlog — improves triage workflows (bottom-up vs top-down reading) but not urgent. **Target wave: Wave 7 / Trish extras.** Related: [DEF-055](#def-055--show-sent-items-in-conversation-threads) (thread view completeness).

---

### DEF-057 — Windows Settings AXTree console spam (“Nodes left pending by the update”)

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open (tracking) |
| Area | `lib/ui/settings/` (NavigationRail section swaps, Dropdown/overlays); Flutter Windows `accessibility_bridge` / Chromium AXTree |
| Platforms | Windows (debug builds) |
| Logged | 2026-07-27 |
| Found by | Trish (dogfood); Renee (triage) |

**Summary**  
Known Flutter Windows engine noise while browsing Settings: repeated `accessibility_bridge` errors when semantics subtrees reparent during NavigationRail section body replacement and Dropdown/overlay attach-detach. UI remains functional; not a Synesis Semantics misuse.

**Symptom**  
While browsing Settings on Windows debug, console repeats:

`[ERROR:flutter/shell/platform/common/accessibility_bridge.cc(114)] Failed to update ui::AXTree, error: Nodes left pending by the update: …`

(and same at line 65). DevTools VM service URLs in the same console are normal debug noise — not part of this defect.

**Root cause hypothesis**  
Flutter Windows `accessibility_bridge` / Chromium AXTree cannot atomically reparent semantics nodes during large Settings subtree swaps (NavigationRail section body replacement) and Dropdown/overlay attach-detach. Upstream family: [flutter#98099](https://github.com/flutter/flutter/issues/98099), [flutter#182444](https://github.com/flutter/flutter/issues/182444), [flutter#175041](https://github.com/flutter/flutter/issues/175041).

**App assessment**  
Not Synesis Semantics misuse — Settings uses ordinary Material; only intentional Semantics is color swatch in `account_color_picker`. No safe app fix; do not `ExcludeSemantics` the shell.

**Disposition**  
Track only. Ignore console spam unless Narrator/UIA clients actually break (then escalate). Recheck after Flutter engine upgrades.

**Repro**  
Windows debug → open Settings → click rail sections rapidly and/or open dropdowns/sheets.

---

### DEF-058 — Graph `invalid_grant` on token refresh surfaces as failed job with useless Retry

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | Open |
| Area | `lib/auth/oauth_identity_manager.dart` (`_postToken`, `getValidAccessToken`); `lib/sync/sync_engine.dart` (`_processJobSafely`); `lib/ui/sync/sync_status_sheet.dart`; `lib/protocol/graph_mail_provider.dart` (`GraphAuthException`) |
| Platforms | All Graph / Microsoft accounts |
| Logged | 2026-07-27 |
| Found by | Trish (dogfood, Jobs sheet); Renee (triage) |

**Summary**  
After V2 Graph scope expansion (`Contacts.Read`, then `Calendars.ReadWrite`), a Microsoft account (`tputnam@cctplays.org`) failed `full_folder` with:

`Bad state: Microsoft token endpoint failed (400): {"error":"invalid_grant",…}`

Jobs sheet shows **Retry**; no in-sheet re-sign-in CTA.

**Root cause**  
1. `OAuthIdentityManager._postToken` throws a raw `StateError` on non-2xx token responses, including AAD `invalid_grant` during refresh-token exchange (`getValidAccessToken` → `_exchangeGraphRefreshToken`).  
2. `SyncEngine._processJobSafely` persists `error.toString()` as the job `lastError` — no classification for auth-terminal failures.  
3. `GraphAuthException` only covers Graph API HTTP 401 after bearer reject (`graph_mail_provider` / `graph_pim_provider`); refresh-endpoint `invalid_grant` never becomes that type.  
4. Jobs **Retry** only requeues + `kick()` — same dead refresh token → same 400 loop.

**Expected vs actual (dogfood)**  
- **Expected after V2 scope bumps:** existing Graph accounts need interactive re-consent (`Edit account → Re-authenticate with Microsoft`). Documented in README / QUICK_START / V2_PLAN / Wave 2–3 QA residuals.  
- **`invalid_grant` specifically:** refresh grant revoked/expired or AAD requiring interaction — not fixed by silent refresh or job Retry. Scope expansion alone more often yields Graph **403 insufficient privileges** on PIM calls while refresh still works; either path needs re-auth.  
- **Actual:** opaque `Bad state: …` job error + Retry that cannot succeed until credentials rotate.

**UX gap**  
No “Sign in again” from failed job or account-health row. Re-auth exists only under Appearance → Manage accounts → Edit account → **Re-authenticate with Microsoft**.

**Related UX friction (separate defect)**  
Operator also saw the Edit-account **Re-authenticate with Microsoft** control clipped/overflowed in layout — worsens the only dogfood recovery path. Tracked/fixed as **[DEF-059](#def-059--edit-account-re-authenticate-button-vertically-clipped)** (layout only; do not conflate with token-endpoint mapping work here).

**Dogfood workaround**  
Appearance → Manage accounts → Edit account for the Graph account → **Re-authenticate with Microsoft** → consent new scopes → Sync / Retry once tokens are rotated.

**Disposition**  
Not docs-only: file as product gap. Immediate operator path is re-auth (above). Code follow-up (schedule soon / Wave 7 polish or auth hardening):

1. Parse token-endpoint JSON; map `invalid_grant` / `interaction_required` / `consent_required` to a dedicated auth-failure type (extend or parallel `GraphAuthException`).  
2. SyncEngine (and Jobs / account health UI) surface **needs re-auth** copy + CTA to Edit account / launch re-auth instead of (or beside) Retry.  
3. Optionally suppress Retry or label it ineffective when `lastError` is auth-terminal.

Related: Wave 2 QA residual “No automatic UI when token lacks PIM scopes”; closed DEF-005 (job error surfacing); SPEC account/auth “force re-auth with clear UI”.

**Repro**  
1. Graph account signed in before Wave 2/3 scopes (or with revoked refresh).  
2. Upgrade to Wave 4/5+ build; trigger folder sync (`full_folder`).  
3. Observe failed job with `Microsoft token endpoint failed (400)` / `invalid_grant`.  
4. Tap Retry → fails again with the same error.  
5. Edit account → re-auth → sync succeeds.

---

### DEF-011 — IMAP edit ignores host/port/user changes without a new password

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | Open |
| Area | `lib/ui/account/edit_account_sheet.dart`, `AccountService.updateImapCredentials` |
| Platforms | All |
| Logged | 2026-07-14 |

**Summary**  
Edit account only calls `updateImapCredentials` when the password field is non-empty. Host, port, username, and SMTP fields are silently ignored if the user leaves the password blank, even though helper text says those fields can be updated independently.

**Expected**  
Partial credential updates apply without requiring password re-entry, or the UI disables non-password fields until a password is supplied.

**Actual**  
Only metadata (label/accent) saves; IMAP connection settings appear saved but are unchanged.

---

### DEF-012 — Concurrent duplicate account remove has no service guard

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open |
| Area | `AccountService.removeAccount`, `remove_account_dialog.dart` |
| Platforms | All |
| Logged | 2026-07-14 |

**Summary**  
The remove dialog sets `_busy` locally, but two parallel remove flows (e.g. rapid double-submit or two surfaces) can both pass confirmation and call `removeAccount`. Second wipe is mostly idempotent but can race credential deletion vs sync.

**Expected**  
Serialize per-account removal or no-op when the account row is already gone.

**Actual**  
No mutex or post-wipe existence check in the service layer.

---

### DEF-013 — Stale selectedMessageId falls back to first list row

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open |
| Area | `lib/ui/mailbox/mailbox_state.dart` (`selectedMessage` getter) |
| Platforms | All |
| Logged | 2026-07-14 |

**Summary**  
When `selectedMessageId` is not present in the current `messages` list, `selectedMessage` returns `messages.first` instead of `null`. After sync refresh or filter changes, the reading pane can show the wrong message while selection highlight may disagree.

**Expected**  
Missing selection id yields no selected message until the user picks one.

**Actual**  
First visible row is treated as selected.

**Notes**  
`onAccountRemoved` now clears selection when the removed account owned the primary or bulk selection (fixed in quality gate). This getter fallback can still mis-route the reading pane on unrelated refreshes.

---

### DEF-014 — removeAccount succeeds when account id is unknown

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open |
| Area | `AccountService.removeAccount` |
| Platforms | All |
| Logged | 2026-07-14 |

**Summary**  
If `listAccounts` does not contain the requested id, `removeAccount` still calls `wipeAccount` and returns without error. Credential deletion is skipped because `credentialsRef` is unknown.

**Expected**  
Either idempotent no-op with explicit logging, or a not-found error for mistyped ids.

**Actual**  
Silent success; callers cannot distinguish removed vs already-gone.

---

### DEF-015 — Header fetch loading/error state is global, not per message

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | **Closed** (2026-08-03) — Wave 6P P1: `headersLoadingMessageId` / `headersErrorMessageId` per message |
| Area | `MailboxState.headersLoadingMessageId`, `headersErrorMessageId`, `message_headers_sheet.dart` |
| Platforms | All |
| Logged | 2026-07-14 |

**Summary**  
`ensureHeadersCached` drives a single workspace-wide `isLoadingHeaders` / `headersErrorMessage` pair. The sheet mitigates most cross-message bleed by only showing spinner/error when the viewed message has empty `rawHeaders`, but rapid switches between uncached messages can still show the wrong spinner/error until the latest fetch settles.

**Expected**  
Loading and error indicators scoped to the message id being fetched/viewed.

**Actual**  
One global flag and error string shared across all header-sheet opens.

**Notes**  
Renee quality gate on header details view (2026-07-14). No user-visible defect when the viewed message already has cached raw headers.

---

### DEF-016 — Empty header response is not retried in-session

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open |
| Area | `MailboxCubit.ensureHeadersCached` (`_fetchedHeaderIds`) |
| Platforms | All |
| Logged | 2026-07-14 |

**Summary**  
When the provider returns null/blank raw headers, the message id is added to `_fetchedHeaderIds` and further `ensureHeadersCached` calls skip the network for the rest of the app session.

**Expected**  
Transient empty responses (or later server recovery) can be retried on sheet reopen or manual refresh.

**Actual**  
User sees “No raw headers were returned by the server.” until app restart, even though fetch failures (exceptions) do allow retry.

---

### DEF-017 — To/Cc rows require cached raw headers

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open |
| Area | `message_headers_sheet.dart` |
| Platforms | All |
| Logged | 2026-07-14 |

**Summary**  
Parsed To/Cc lines are extracted only from `messages.raw_headers` via `parseRawHeaderValue`. Synced header metadata does not include recipient lists, so those rows stay hidden until on-demand header fetch completes (or forever for demo/unlinked messages).

**Expected**  
Recipients visible from synced metadata when available, with raw block as enrichment.

**Actual**  
From/Subject/Date/Message-ID show from local model; To/Cc appear only after raw header cache population.

---

### DEF-018 — Demo messages cannot on-demand fetch headers

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open |
| Area | `MailboxCubit.ensureHeadersCached`, sample mailbox data |
| Platforms | All |
| Logged | 2026-07-14 |

**Summary**  
Messages without `providerId` short-circuit header fetch. The sheet shows static local fields and the “Connect a linked account…” raw-header placeholder.

**Expected**  
Clear UX distinction between demo vs linked-account mail (acceptable) or seeded demo raw blocks for QA.

**Actual**  
No provider-backed fetch path for sample messages; documented as intentional gap in ROADMAP landing notes.

---

### DEF-007 — Sync header refresh can overwrite local read/unread

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | **Closed** (2026-08-03) — Wave 6P P1: merge policy in `drift_message_store.dart` (local read + pending unread push) |
| Area | `SyncEngine._toMailMessage`, `DriftMessageStore.upsertMessages`, `MailboxCubit.setUnreadBulk` |
| Platforms | All |
| Logged | 2026-07-14 |

**Summary**  
Mark read/unread persists locally and pushes to the provider, but the next folder/inbox sync re-upserts message headers with remote `isRead`. If sync runs before the server reflects the change (or push failed silently), `refresh()` restores the old unread flag and folder counts from the remote snapshot.

**Expected**  
Local user intent wins until the server confirms the new read state (e.g. tombstone/pending flag, merge policy, or post-push incremental sync).

**Actual**  
`upsertMessages` always writes `unread` from the incoming header with no merge against a newer local toggle.

**Notes**  
Observed during Renee quality gate on mark read/unread. Optimistic cubit state can also be replaced on any `watchChanges()` refresh after sync.

---

### DEF-009 — Rapid concurrent mark read/unread has no in-flight guard

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open |
| Area | `MailboxCubit.setUnreadBulk` |
| Platforms | All |
| Logged | 2026-07-14 |

**Summary**  
Overlapping `setUnreadBulk` calls (double Ctrl+U, bulk toolbar + keyboard) can interleave optimistic emits and provider pushes from stale `state.messages`, producing transient wrong UI or out-of-order server updates.

**Expected**  
Serialize per-message or per-account read-state mutations, or cancel/supersede in-flight work.

**Actual**  
Each call runs to completion independently with no mutex or generation token.

---

### DEF-039 — Remove Account confirmation dialog overflows

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | **Closed** (2026-08-03) |
| Area | `lib/ui/account/remove_account_dialog.dart` |
| Platforms | Android (likely all narrow widths) |
| Logged | 2026-07-23 |

**Summary**  
Yellow/black Flutter overflow stripes appeared in the Remove Account confirmation pop-up (dogfood on Android).

**Fix**  
Dialog `content` wrapped in `SingleChildScrollView` (DEF-063 overflow sweep, 2026-08-03).

---

### DEF-044 — Home-screen list widget: per-account mail + open in app (AquaMail bar)

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | Open (enhancement) |
| Target | **V-Next** |
| Area | Android widgets (`SynesisWidgetProvider`, `WidgetSnapshotService`); enhancement |
| Platforms | Android |
| Logged | 2026-07-24 |
| Updated | 2026-08-03 — **Trish:** per-account widget; quality bar = **AquaMail**; bumped **Pri-2 / V-Next** (operator uses widgets daily) |
| Found by | Trish (dogfood; refreshed ask 2026-08-03) |

**Summary**  
**Trish:** Need real home-screen widgets — especially **one widget instance pinned to a specific account** that shows actual mail (subjects/senders/snippets as appropriate) and **tapping a row opens that message in Synesis**. Quality bar: **AquaMail’s widgets** (usable list, account-scoped, deep-link into the app). Operator uses these heavily when available.

Existing ask (2026-07-24): configurable account/folder list widget; current Synesis widget is counter + latest subject + Inbox/Compose only (`synesis_widget.xml`); list snapshot data exists (`synesis_widget.list`) but is not rendered as a clickable list UI.

**Expected**  
- Configurable list widget scoped to an **account** (and optionally folder).  
- Multiple widget instances (different accounts) supported.  
- Rows show real local mail from snapshots; tap → deep-link / open message in app.  
- Refresh from local DB after sync (no full Flutter UI wake for routine updates — SPEC widget path).  
- UX/polish aiming at AquaMail-class usefulness, not a decorative unread badge.

**Actual**  
Only the summary widget ships; no configurable account-scoped clickable list widget.

**Notes**  
**V-Next Pri-2** (bumped from Wave 7 Pri-3 on 2026-08-03). Related SPEC § Android widgets (`home_widget` + snapshot table). Pairs with phone reading UX ([DEF-078](#def-078--phone-quick-reply-density--settings-toggle)) as operator daily-driver polish.

---

### DEF-046 — Hamburger opens full drawer; prefer folders-only sheet (enhancement)

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | Open (enhancement) |
| Target wave | **Wave 7 / Trish extras** |
| Area | `mail_workspace.dart` title-bar menu, `MailNavigationDrawer` / `FolderSidebar` |
| Platforms | Android (phone) |
| Logged | 2026-07-24 |

**Summary**  
On the main list screen, the hamburger currently opens the full navigation drawer (brand header + folders + footer actions). Edge-swipe already opens that full drawer. Operator preference: hamburger should open a **folders-only** view; keep swipe for the full drawer.

**Expected**  
Hamburger → compact folders/accounts navigation. Swipe-from-left → full drawer (compose, outbox, settings, etc.).

**Actual**  
Hamburger and swipe both open the same full drawer.

**Notes**  
Enhancement for the next UI pass — not a defect. Pill outbox affordance stays; drawer Outbox entry landed separately (2026-07-24). **Target wave: Wave 7 / Trish extras** (hamburger behavior polish; hybrid A partial relief already landed).

**Related (2026-07-27)** — Drawer account IA (hybrid A) landed in `FolderSidebar` `embeddedInDrawer`: horizontal account chips (one-tap → Inbox via `selectAccount`) + compact **FOLDERS** launch tile that opens a tall folder-picker bottom sheet for the active account (avoids crushing the tree between MAIL and footer on large phones). Phone `_TitleBar` and list **Show folders** both open that same sheet directly (no drawer hop); reading has no hamburger so the title control is the main in-message escape. Last-active account retained when Unified/virtual views are selected. Desktop multi-expand sidebar unchanged. Does not close DEF-046 (hamburger folders-only sheet still open).

---

### DEF-062 — Calendar event chips lack translucent calendar-color backgrounds

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | **Partial** (event tint shipped 2026-07-27; color-override picker deferred) |
| Area | `lib/ui/calendar/calendar_workspace.dart` (month chips + agenda rows); store already has `Calendar.colorArgb` / `colorOverrideArgb` |
| Platforms | All |
| Logged | 2026-07-27 |
| Found by | Trish (enhancement request) |

**Summary**  
Operator wants calendar events/items highlighted with a **translucent calendar color** background (text accent acceptable as fallback). Sync already maps Graph/Google/DAV colors into `Calendar.colorArgb`; UI only showed small color dots on month chips and agenda leading indicators.

**Investigation**  
1. **Store/sync:** Present — Drift `calendars.color_argb` + `color_override_argb`; Graph/Google defaults + remote color mapping; DAV default blue; `Calendar.effectiveColorArgb`; cubit `setCalendarColorOverride` wired to store.  
2. **UI before fix:** Color dots on month event rows, agenda tiles, side-by-side lane headers, and picker switches — no translucent event fill.  
3. **Gap:** Painting only (not sync). User color override in picker is API-ready but has no UI.

**Shipped (partial)**  
Month grid event chips and agenda/day-sheet rows use left accent border + theme-aware translucent wash from `effectiveColorArgb`; body text stays `ThemeTokens.text` for contrast. Picker still shows color dots only.

**Deferred**  
Simple color override control in `showCalendarPickerSheet` (long-press / swatch) — cubit/store ready; not shipped this pass.

**Notes**  
Pri-3 polish; Tesla not needed (fields already exist).

---

## Closed

### DEF-061 — Google Calendar PIM 403 after fresh revoke + re-add (tokeninfo fail-open / GCP API)

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | **Closed** (2026-07-27) |
| Fixed | 2026-07-27 (`9015452`, `cee24c3`) |
| Area | `lib/auth/oauth_identity_manager.dart` (fail-closed tokeninfo, PIM preflight, refresh tokeninfo); `lib/protocol/google_pim_provider.dart` (403 reason parsing); `lib/account/account_service.dart` |
| Platforms | All Google XOAUTH accounts (People + Calendar PIM) |
| Logged | 2026-07-27 |
| Found by | Trish (dogfood); Renee (triage); Tesla (fix) |

**Summary**  
After Wave G (`f4c21b0`), Google Calendar/People sync returned `403` / insufficient authentication scopes — even after full revoke, third-party access removal, restart, and re-add with Contacts + Calendar checked. Google Account showed Gmail + Contacts + Calendar granted; mail worked while PIM failed.

**Root cause**  
**Primary operator cause:** **Google Calendar API** and/or **People API** were not enabled (or stale) on the OAuth client's GCP project. Google returned scope-flavored `403`s (`ACCESS_TOKEN_SCOPE_INSUFFICIENT`, `SERVICE_DISABLED` / `accessNotConfigured`) that looked like a consent/token loop.

**App gaps fixed along the way:**  
1. **`9015452`** — stale refresh-token handling; insufficient alone after full revoke/re-add.  
2. **`cee24c3`** — fail-closed tokeninfo (POST), Calendar/People preflight at sign-in, refresh tokeninfo verification, distinct `SERVICE_DISABLED` vs `ACCESS_TOKEN_SCOPE_INSUFFICIENT` messaging in 403 handlers.

**Why `9015452` was insufficient (evidence)**  
1. Sign-in validated scopes via `tokenInfoScope ?? tokens.scope` — **fail-open**. If tokeninfo failed, Synesis trusted the token-endpoint `scope` string and persisted the AT while Calendar API still rejected it.  
2. Refresh only checked scopes when the token response included a non-empty `scope` field.  
3. 403 handler collapsed scope-like bodies into “revoke again” copy and dropped Google `details[].reason`. Disabled Calendar API on the OAuth client's GCP project was misread as a consent loop.  
4. IMAP XOAUTH2 uses the same AT accessor — mail working while calendar fails is compatible with mail-scoped token or Calendar API disabled.

**Fix**  
1. Fail-closed: interactive sign-in **requires** tokeninfo (POST, dual host); no token-endpoint-only fallback.  
2. Refresh always verifies via tokeninfo (or refuses to persist).  
3. Post-consent **PIM preflight** (`calendarList?maxResults=1` + `contactGroups?pageSize=1`) before saving credentials.  
4. Accept read-equivalent scope alternatives (`calendar.readonly`, `contacts`) with exact token match.  
5. Persist Google add via `replaceGoogleToken` (require RT).  
6. 403 messages include `reason` / `status` and GCP enablement checklist when service is disabled.

**Resolution**  
Trish dogfood confirmed Google Calendar/People working after disabling + re-enabling **Google Calendar API** + **People API** on the GCP project for the Synesis OAuth client (2026-07-27).

**Operator GCP checklist (for future dogfood)**  
1. Cloud Console → project that owns `SYNESIS_GOOGLE_CLIENT_ID`.  
2. **APIs & Services → Enabled APIs** — enable **Google Calendar API** (`calendar-json.googleapis.com`) and **People API** (`people.googleapis.com`).  
3. Full-restart Synesis; re-auth if scopes were expanded after Wave G.  
4. Sign-in preflight surfaces `SERVICE_DISABLED` or missing scopes immediately — Jobs sheet 403 should not be the first signal.

**Verification**  
`flutter test test/oauth_identity_manager_test.dart test/account_service_test.dart test/google_pim_provider_test.dart`; operator dogfood GO (2026-07-27).

**Related**  
DEF-058 (useless Retry UX class); closed DEF-059.

---

### DEF-060 — Calendar (and People) display toggles appear stuck on

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | **Closed** (2026-07-27) |
| Fixed | 2026-07-27 |
| Area | `lib/ui/calendar/calendar_workspace.dart` (`showCalendarPickerSheet`), `lib/ui/people/people_workspace.dart` (`showContactListPickerSheet`), `CalendarCubit.setCalendarSelected` / `PeopleCubit.setContactListSelected` |
| Platforms | All |
| Logged | 2026-07-27 |
| Found by | Trish (dogfood) |

**Summary**  
Operator could not turn off specific calendars in the Calendar module picker (tune icon → switches). Toggles looked inert / snapped back.

**Root cause**  
Wave 5 wired store + cubit correctly (`isSelectedForDisplay`, `setCalendarDisplayPrefs`, `listEventsInRange(selectedCalendarsOnly: true)`). The picker bottom sheet closed over a **frozen** `CalendarState` and did not `BlocBuilder`-listen to `CalendarCubit`. `SwitchListTile` is controlled — `onChanged` wrote prefs, but the sheet never rebuilt with the new `value`, so switches appeared stuck. Same pattern in the People contact-list picker.

**Fix**  
1. Rebuild picker sheets from live cubit state via `BlocBuilder`.  
2. Await `refresh()` after display-pref writes so the sheet updates immediately.  
3. Regression: `test/calendar_cubit_test.dart` — `showCalendarPickerSheet (DEF-060)`.

**Repro (before fix)**  
1. Calendar → tune → toggle a calendar off.  
2. Switch stays on (or snaps back); after close, workspace may already have filtered events if `watchChanges` refreshed — UI feedback in-sheet was broken either way.

**Verification**  
`flutter test test/calendar_cubit_test.dart`

---

### DEF-059 — Edit Account Re-authenticate button vertically clipped

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | **Closed** (2026-07-27) |
| Fixed | 2026-07-27 |
| Area | `lib/ui/account/edit_account_sheet.dart` |
| Platforms | All (Graph edit; dogfood screenshot Windows) |
| Logged | 2026-07-27 |
| Found by | Trish (dogfood); noted under DEF-058 |

**Summary**  
On Graph **Edit account**, the filled **Re-authenticate with Microsoft** button showed only its bottom half — visually swallowed under the **Use profile retention** switch. Label **Re-authenticate (optional)** remained visible; Manage signatures / templates / Save below looked fine.

**Root cause**  
Fixed `Column` kept sync profile + retention (and the re-auth *label*) outside an `Expanded` → `ListView` that held only the credential controls. Tall chrome above left a tiny `Expanded` viewport that clipped the re-auth `FilledButton`.

**Fix**  
Put metadata + credential fields in one scrollable `Expanded` `ListView`; keep signatures / templates / Save as a sticky footer. Also addresses general Edit Account overflow from [DEF-040](#def-040--edit-account-sheet-overflows). Separate from DEF-058 (`invalid_grant` / Jobs Retry UX).

---

### DEF-040 — Edit Account sheet overflows

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | **Closed** (2026-07-27) |
| Fixed | 2026-07-27 |
| Area | `lib/ui/account/edit_account_sheet.dart` |
| Platforms | Android (likely all narrow widths) |
| Logged | 2026-07-23 |

**Summary**  
Yellow/black Flutter overflow stripes appear on the Edit Account screen (dogfood on Android). Non-blocking for continued dogfood.

**Expected**  
Sheet content fits the viewport or scrolls when the keyboard/small height requires it; no overflow indicators.

**Actual**  
Layout overflows on the Edit Account UI.

**Resolution**  
Same scroll restructure as **DEF-059**: form body scrolls inside `Expanded` `ListView`; action buttons stay sticky. DEF-039 (Remove Account dialog) remains open.

---

### DEF-049 — Graph reply send fails: In-Reply-To not allowed on internetMessageHeaders

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-07-27) |
| Area | `lib/protocol/graph_mail_provider.dart` (`_buildOutgoingMessage`), `lib/outbox/send_error_messages.dart` |
| Platforms | Microsoft Graph (Exchange / M365); replies with `inReplyTo` / `references` set |
| Logged | 2026-07-27 |

**Summary**  
Compose Reply for a Graph account failed with `Send failed: The internet message header name 'In-Reply-To' should start with 'x-' or 'X-'. Check account SMTP settings and try again.` Subject `Re: …`; threading fields present. (Operator initially suspected IMAP/SMTP; the exception text is Graph `InvalidInternetMessageHeader`.)

**Root cause**  
`GraphMailProvider._buildOutgoingMessage` put RFC `In-Reply-To` and `References` into Graph `internetMessageHeaders`. That collection only accepts **custom** headers whose names start with `x-` / `X-`. Standard headers are rejected client-side by Graph before send. IMAP/SMTP path (`buildMultipartMessage`) writing those headers as raw MIME is fine and unrelated. DEF-047 / DEF-048 were SMTP recipient/sender mapping issues — different failure mode.

**Resolution**  
1. Map reply threading to MAPI extended properties (`String 0x1042` In-Reply-To, `String 0x1039` References) via `singleValueExtendedProperties`; do not set standard names on `internetMessageHeaders`.  
2. `actionableSendError`: bucket Graph header-rejection phrases so the UI does not blame "SMTP settings".  
3. Regression tests: Graph sendMail payload shape; error-copy mapping.

**Verification**  
`flutter test test/graph_mail_provider_upload_session_test.dart test/send_error_messages_test.dart` — 14/14 pass. **Operator verified fixed 2026-07-27** (Graph reply send succeeds in dogfood).

**Follow-up**  
Ideal long-term: Graph `createReply` / `createReplyAll` when a Graph message id is available (Outlook conversationId threading). Extended properties preserve RFC headers for other clients.

---

### DEF-041 — Message list star/expand chrome steals horizontal space (phone)

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | **Closed** (2026-07-27) |
| Area | `lib/ui/shell/message_list_pane.dart` (`_ThreadRow` / `_MessageRow`) |
| Platforms | Android (narrow widths; likely all phone layouts) |
| Logged | 2026-07-23 |

**Summary**  
On the Unified Inbox message list, the leading star and thread expand/collapse controls (plus their tap targets/padding) consume a large share of row width. Sender and subject start too far right and truncate heavily (e.g. “LinkedIn Job Ale…”, “Director of Quality Engineeri…”), even when vertical space is fine. Non-blocking but annoying in daily dogfood.

**Expected**  
On narrow widths, leading chrome is compact (smaller targets and/or denser layout) so sender/subject retain most of the row; optional: move star to trailing or overflow menu on phone.

**Actual (before fix)**  
Star + chevron column pushes content mid-screen; primary text is chronically ellipsized.

**Resolution**  
Compact density shrinks leading star/expand tap targets (16px / 22px constraints) in `lib/ui/shell/message_list_pane.dart`.

---

### DEF-042 — Expand/collapse chevron and “1” badge on single-message threads

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | **Closed** (2026-07-27) |
| Area | `lib/ui/shell/message_list_pane.dart` (`_ThreadRow`), conversation/thread projection |
| Platforms | Android (also desktop if same row chrome) |
| Logged | 2026-07-23 |

**Summary**  
Single messages rendered as threads still show the expand/collapse chevron and a thread-count badge of **1**. Expanding a one-message “thread” feels doubled/redundant and wastes chrome (see also DEF-041).

**Expected**  
Expand control and count badge only appear when a thread has **2+** messages. Solo messages use flat row chrome (no chevron, no “1” badge).

**Actual (before fix)**  
Every visible row shows chevron + “1”, including non-threaded singles.

**Resolution**  
Expand chevron + count badge only when `thread.count >= 2` in `lib/ui/shell/message_list_pane.dart`.

---

### DEF-047 — Compose Send fails with "recipient rejected" for valid addresses (miscategorized SMTP error)

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-07-24) |
| Area | `lib/outbox/send_error_messages.dart`, `lib/protocol/imap_smtp_mail_provider.dart` |
| Platforms | Android (IMAP/SMTP, incl. Google Workspace XOAUTH2) |
| Logged | 2026-07-24 |

**Summary**
After DEF-045 fixed the hung "Sending…" state, mail reached SMTP but Compose showed `Send failed: the server rejected a recipient address. Check To/Cc and try again.` for a plainly valid send (`trish@trishputnam.com` → `trish@silverhelmet.com`). The copy comes from `actionableSendError` in `send_error_messages.dart`.

**Investigation**
Traced the full recipient pipeline end to end and found it correct: `_toController.text` is stored verbatim on the outbox row, `DriftOutboxStore._recipientListForStorage` / `splitOutboxRecipients` round-trip comma/semicolon/JSON lists without mangling addresses, `OutgoingMessageBuilder.build` and `ImapSmtpMailProvider.sendEnvelope` build a correct `To:` header, and `enough_mail`'s `MimeMessage.recipientAddresses` parses it correctly for `RCPT TO`. The To field is a plain `TextField` bound only to typed text — it never carries an account id or stale value.

**Root cause**
`actionableSendError` matched bare SMTP status codes (`550`, `551`, `553`) and the substring `recipient` to decide the error was recipient-related. But SMTP servers — especially Gmail/Workspace — reuse the same 5xx code ranges for **envelope-sender** (`MAIL FROM`) rejections, e.g. `553 5.7.1 <addr>... Sender address rejected: not owned by user` (mismatched/unverified "Send mail as" alias) or `554 5.7.1 Unauthenticated email is not accepted due to domain's DMARC policy` (SPF/DKIM/DMARC policy failure on the From domain). Both contain `553`/`554` and neither is a recipient problem, so the bucket matched first and produced a confusing, actively misleading "check To/Cc" message — hiding the real cause and wasting the operator's troubleshooting time on the wrong field. Separately, `ImapSmtpMailProvider.sendEnvelope`/`send` did not pass an explicit `from:` to `enough_mail`'s `smtp.sendMessage`, leaving `MAIL FROM` to be re-derived from the rendered MIME's `From` header instead of the resolved envelope address directly — a correctness gap that could allow sender/recipient diagnosis to diverge from what Synesis actually intended to send.

**Resolution**
1. `send_error_messages.dart`: added a sender/envelope-from bucket (checked **before** the recipient bucket) matching Gmail/Workspace sender-rejection and DMARC/SPF phrases (`sender address rejected`, `not owned by user`, `dmarc`, `spf`, `5.7.1`/`5.7.25`-`5.7.27`, etc.), mapped to guidance about verifying the "Send mail as" alias and domain SPF/DKIM/DMARC — instead of telling the user to check To/Cc for a From-address problem.
2. Every bucket now appends a sanitized, length-capped raw server detail (`(Server said: ...)`) so the actual SMTP response is visible in the UI for any future ambiguous case, not just the ones an explicit bucket happens to name.
3. `imap_smtp_mail_provider.dart`: `sendEnvelope` and `send` now pass `from: MailAddress(null, ...)` explicitly to `smtp.sendMessage`, so `MAIL FROM` always equals the resolved account/envelope address rather than being re-derived from re-parsed MIME headers.
4. Added regression tests in `send_error_messages_test.dart` covering sender-address-rejected, DMARC/SPF, and genuine-recipient-rejection cases (asserting the recipient bucket is *not* hit for sender-policy errors, and that raw server detail is surfaced).

**Verification**
`flutter test test/send_error_messages_test.dart test/sync_engine_send_outbox_test.dart test/mime_builder_test.dart test/mail_provider_capabilities_test.dart test/provider_dispose_test.dart` — 24/24 pass. `dart analyze` clean on touched files. `flutter build apk --debug` succeeds.

**Follow-up for the operator**
Because the real SMTP error text couldn't be captured from the live device in this pass, the next actual failure on this account will now show the *raw* server response in the Compose error banner. If it reads "Sender address rejected" / "not owned by user" / mentions DMARC/SPF, the fix is on the Google Workspace admin side (verify `trishputnam.com` as a "Send mail as" alias, or confirm SPF/DKIM/DMARC authorize Google) rather than in the app.

---

### DEF-048 — SMTP `500 no recipients` from empty MimeMessage.recipientAddresses

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-07-24) |
| Area | `lib/protocol/imap_smtp_mail_provider.dart` (`sendEnvelope`), enough_mail `SmtpClient.sendMessage` |
| Platforms | All IMAP/SMTP |
| Logged | 2026-07-24 |

**Summary**
After DEF-047, Compose still failed with `Send failed: … Check To/Cc … (Server said: 500 no recipients)` for `trish@trishputnam.com` → `trish@silverhelmet.com`. The To field was filled correctly.

**Root cause**
`sendEnvelope` builds MIME via `buildMultipartMessage` (raw headers including `To:`), then `MimeMessage.parseFromData`. enough_mail's `SmtpClient.sendMessage` uses `message.recipientAddresses` unless `recipients:` is passed. Parsed messages from our hand-built MIME leave `to`/`cc`/`bcc` empty, so enough_mail throws a **client-side** `SmtpException` with response text `500 no recipients` *before* any real SMTP RCPT. DEF-047's investigation incorrectly assumed parse populated recipients; the live `Server said: 500 no recipients` string is that exact enough_mail guard.

**Resolution**
Pass explicit `recipients:` (To+Cc+Bcc as `MailAddress` list) and `from:` to `smtp.sendMessage`. Map `500 no recipients` / `no recipients` in `actionableSendError` to a non-"check To/Cc" message. Regression: hand-built MIME → parse leaves `recipientAddresses` empty (documents the quirk).

---

### DEF-045 — Compose Send stuck grayed (“Sending…”) / mail never delivered

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-07-24) |
| Area | `compose_sheet.dart`, `SyncEngine.kick`, `ImapSmtpMailProvider.sendEnvelope`, `NetworkSyncPolicy.allowPoll`, `drift_sync_job_store.claimPendingJobs` |
| Platforms | Android (also any IMAP/SMTP path) |
| Logged | 2026-07-24 |

**Summary**  
Compose Send stayed on a gray **Sending…** state and messages were never received. Valid addresses were not the gate — button only disables while `_busy`.

**Root causes (combined)**  
1. Compose awaited unbounded `syncEngine.kick()` (hung SMTP/IMAP or long prior sync → busy forever).  
2. Autosave could demote `queued` → `draft`, so `send_outbox` found nothing to send.  
3. Empty `connectivity_plus` results refused all poll/send kicks.  
4. SMTP connect/auth/send had no timeouts.  
5. `send_outbox` could sit behind older incremental jobs in the claim FIFO.

**Resolution**  
Bounded kick wait + `kickFresh` on timeout; cancel/guard autosave so it cannot demote in-flight sends; treat empty connectivity as online for poll; 45s SMTP step timeouts; claim priority prefers `send_outbox` / `push_message_action`.

---

### DEF-043 — Compose formatting toolbar overflows (~10px)

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | **Closed** (2026-07-24) |
| Area | `lib/ui/compose/compose_sheet.dart` (Bold/Italic/Link/Attach/Schedule row) |
| Platforms | Android (narrow widths) |
| Logged | 2026-07-24 |

**Summary**  
Compose sheet formatting row showed Flutter hazard stripes (“OVERFLOWED BY 9.6 PIXELS”), clipping the Schedule control.

**Resolution**  
Toolbar row uses a horizontally scrollable leading cluster plus Schedule/clear trailing actions so narrow widths no longer overflow.

---

### DEF-033 — Google / Workspace add shows no folders (collapsed + empty LIST race)

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-07-23) |
| Area | `MailboxCubit.selectAccount`, `add_account_sheet`, `AccountService.addGoogleImapAccount`, `ProviderRegistry`, `folder_sidebar` |
| Platforms | Android (also desktop) |
| Logged | 2026-07-23 |

**Summary**  
After Sign in with Google (including Workspace custom domains), the folder tree looked empty: accounts were never auto-expanded on select, add-account did not select the new account or open the sidebar, Inbox was not seeded before bootstrap LIST finished, and credentials_ref recovery only matched `@gmail.com` / `@googlemail.com`.

**Resolution**  
`selectAccount` expands the account; Google/Microsoft add opens the sidebar and selects the new account; seed Inbox on Google add; recover `google:$id` for IMAP accounts with stored Google tokens; sidebar “Syncing folders…” empty hint.

---

### DEF-038 — Microsoft / Google Sign-in missing in dogfood build (Pri-1)

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-07-18) |
| Area | `oauth_config_resolver.dart`, `main.dart`, Add Account sheet, README |
| Platforms | Windows (also Android once IDs present) |
| Logged | 2026-07-18 |

**Summary**  
Operator dogfood build showed Microsoft/Google tabs but no **Sign in with …** buttons. OAuth was gated only on compile-time `--dart-define` client IDs; plain `flutter run` baked empty IDs.

**Resolution**  
`OAuthConfigResolver` merges dart-define → OS environment → gitignored `oauth_local.json`. Clearer unconfigured copy on Add Account. Example: `oauth_local.json.example`. Operator must still supply Entra + Google public client IDs once.

---

### DEF-034 — No auto-mark-as-read after viewing a message

| Field | Value |
| --- | --- |
| Priority | Pri-2 |
| Status | **Closed** (2026-07-18) |
| Area | `lib/ui/shell/auto_mark_as_read.dart`, `lib/ui/shell/reading_pane.dart` |
| Platforms | All |
| Logged | 2026-07-17 |
| Closed | 2026-07-18 |
| Wave | **W7** |
| Related | [UI-P27](UI_ENHANCEMENT_SWEEP.md); post-V1 [UI-P28](UI_ENHANCEMENT_SWEEP.md) remains open |

**Resolution**  
`AutoMarkAsReadController` starts a **5s** dwell timer when an unread message is selected in the reading pane; on fire it calls the existing `onMarkRead` path (local + provider Seen). Selection change / dispose / already-read cancels the timer. Default ON with fixed delay (no Appearance toggle — UI-P28). Coverage: `test/auto_mark_as_read_test.dart`.

---

### DEF-037 — Windows build fails STL1011 on flutter_local_notifications_windows

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-07-17) |
| Area | `windows/CMakeLists.txt`, `flutter_local_notifications_windows` |
| Platforms | Windows (VS 18 / recent MSVC) |
| Logged | 2026-07-17 |

**Summary**  
After W6 added `flutter_local_notifications` (Android), Windows debug builds failed compiling the transitive `flutter_local_notifications_windows` FFI plugin: `STL1011` / `static assertion failed` on deprecated `<experimental/coroutine>`.

**Resolution**  
Define `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` in `windows/CMakeLists.txt`. Windows new-mail toasts remain on `local_notifier`; the Flutter notifications package is only used on Android at runtime.

---

### DEF-036 — Print PDF uses Helvetica (no Unicode / em dash)

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | **Closed** (2026-07-17) |
| Area | `lib/desktop/message_print_service.dart`, `assets/fonts/` |
| Platforms | Windows (print PDF path) |
| Logged | 2026-07-17 |

**Summary**  
Print logged `Helvetica has no Unicode support` / `Unable to find a font to draw "—" (U+2014)` because `pw.Document` used the default Type1 Helvetica theme.

**Resolution**  
Embed OpenSans Regular/Bold as Flutter assets and apply `ThemeData.withFont` (+ `fontFallback`) on the print document per [dart_pdf Fonts Management](https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management).

---

### DEF-035 — Print fails on long HTML bodies (widget exceeds page height)

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | **Closed** (2026-07-17) |
| Area | `lib/desktop/message_print_service.dart` |
| Platforms | Windows (print PDF path) |
| Logged | 2026-07-17 |

**Summary**  
Printing a long message (e.g. LinkedIn job alert) threw `Widget won't fit into the page as its height (…) exceed a page height (708.0)`. The PDF body was a single non-spanning `pw.Text` inside `MultiPage`.

**Resolution**  
Strip HTML to plain text, emit per-line `pw.Paragraph` chunks (with ~3000-char soft splits) so `MultiPage` can paginate. Regression: long-body case in `test/message_print_service_test.dart`.

---

### DEF-032 — Unread folder badge stale after mark-read

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | **Closed** (2026-07-17) |
| Area | `lib/mailbox/message_action_service.dart`, `lib/sync/sync_engine.dart` |
| Platforms | All |
| Logged | 2026-07-17 |

**Summary**  
Marking a message read updated message rows but the folder unread badge often stayed unchanged. Optimistic folder deltas skipped messages with a null `folderId`, and folder-list sync `upsertFolders` could overwrite local unread counts with stale server totals.

**Resolution**  
`_resolveFolderIdForUnread` falls back to the open folder / inbox when `folderId` is missing. After `setUnreadBulk`, reload folders from DB (which recounts). After sync `upsertFolders`, call `recountUnreadCounts(accountId:)` so badges match local message flags.

---

### DEF-033 — Print reported failure when dialog cancelled or HWND unavailable

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | **Closed** (2026-07-17) |
| Area | `lib/ui/shell/reading_pane.dart`, `lib/desktop/message_print_service.dart` |
| Platforms | Windows |
| Logged | 2026-07-17 |

**Summary**  
Reading-pane Print often showed "Printing dialog did not complete." Opening PrintDlg during overflow-menu teardown returned false (null HWND). Cancel was treated the same as failure.

**Resolution**  
Pre-build PDF bytes before `layoutPdf`. Delay/retry once after menu close. On continued false, fall back to `shareMessagePdf` when available; otherwise snackbar "Print cancelled." (not the scary incomplete message).

---

### DEF-031 — All workspace keyboard shortcuts dead after HTML widget fallback

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-07-17) |
| Area | `lib/desktop/keyboard_intents.dart`, `lib/ui/shell/mail_workspace.dart` |
| Platforms | Windows |
| Logged | 2026-07-17 |

**Summary**  
After falling back to `flutter_widget_from_html`, clicking the reading pane focused a read-only `SelectableText`/`EditableText`. `isEditingText` treated any `EditableText` as typing and skipped every shortcut. Separately, `Focus.onKeyEvent` alone missed keys when primary focus was null.

**Resolution**  
`isEditingText` ignores `readOnly` EditableText (selection surfaces). Restored `HardwareKeyboard.addHandler` for workspace chords (still gated by settings + editing check).

---

### DEF-001 — Workspace Ctrl shortcuts only fire when Quick Reply has focus

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | **Closed** (2026-07-17, W5) |
| Area | Desktop keyboard shortcuts (`lib/ui/shell/mail_workspace.dart`, `lib/desktop/keyboard_intents.dart`) |
| Platforms | Windows (reproduced); Android TBD |
| Logged | 2026-07-14 |

**Summary**  
With keyboard shortcuts enabled, Ctrl+J / Ctrl+K / Ctrl+N / Ctrl+F work when the reading-pane **Quick Reply** field has focus, but do not function when focus is elsewhere in the mailbox workspace (message list, sidebar, title bar, etc.).

**Resolution**  
Replaced process-global `HardwareKeyboard` registration with route-root `Focus.onKeyEvent` on the workspace. Ancestor-only `EditableText` detection (no descendant walk) so list/sidebar focus no longer false-positives as “editing.” Quick Reply field was removed earlier; stale summary text retained for history.

---

### DEF-008 — Ctrl+U toggles only the primary message, not bulk selection

| Field | Value |
| --- | --- |
| Priority | **Pri-3** |
| Status | **Closed** (2026-07-17, W5) |
| Area | `MessageActionService.toggleSelectedUnread`, `MailboxCubit.toggleSelectedUnread` |
| Platforms | Desktop |
| Logged | 2026-07-14 |

**Summary**  
After Ctrl/Shift multi-select, Ctrl+U still called `toggleSelectedUnread()` on the single `selectedMessageId`, ignoring `selectedMessageIds`.

**Resolution**  
`toggleSelectedUnread` now resolves `_actionTargets` and applies one uniform bulk state via `setUnreadBulk` (any unread → all read; else all unread).

---

### DEF-030 — Main reading pane HTML fails with webview_creation_failed

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-07-17) |
| Area | `lib/ui/shell/html_email_body.dart` |
| Platforms | Windows |
| Logged | 2026-07-17 |

**Summary**  
After W5 HTML fallback work, some main-shell messages showed `Unable to render HTML message` with `PlatformException(webview_creation_failed, … CreateCoreWebView2CompositionController failed)`. Fallback only matched `unsupported_platform` / `environment_creation_failed`, so composition failures rendered as a hard error instead of the in-app HTML viewer.

**Resolution**  
Treat `webview_creation_failed` (and CoreWebView2 composition HRESULT text) as widget-HTML fallback triggers via `htmlEmailShouldUseWidgetFallback`.

---

### DEF-029 — Detached message window: double subject chrome + WebView unsupported_platform

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-07-17) |
| Area | `lib/desktop/detached_message_app.dart`, `lib/ui/shell/html_email_body.dart`, `lib/ui/shell/reading_pane.dart`, `lib/main.dart` |
| Platforms | Windows |
| Logged | 2026-07-17 |

**Summary**  
“Open in new window” showed the subject in both the AppBar and ReadingPane, and HTML bodies failed with `PlatformException(unsupported_platform)` because WebView2 Graphics Capture often cannot initialize on secondary `desktop_multi_window` engines. The same message rendered correctly in the main shell. “Show main window” also had no main-engine handler.

**Expected**  
Detached reader shows one content header; body remains readable (HTML or plain fallback); Show main focuses the primary window.

**Actual (before fix)**  
Duplicate subject chrome; empty body with unsupported_platform error; Show main was a no-op.

**Resolution**  
Slim AppBar title to “Synesis” and set OS title from the subject; on WebView `unsupported_platform` / `environment_creation_failed`, fall back to **`flutter_widget_from_html`** (layout-preserving in-app HTML, not plain text); hide “Open in new window” in detached mode; register `show_main_window` on the main engine. Tests: `test/html_email_fallback_test.dart`. True WebView2 parity in secondary engines remains a known platform limit.

---

### DEF-028 — IMAP empty-folder FETCH fails; ProtocolException hides cause

| Field | Value |
| --- | --- |
| Priority | **Pri-1** |
| Status | **Closed** (2026-07-17) |
| Area | `lib/protocol/imap_smtp_mail_provider.dart`, `lib/protocol/mail_provider.dart` |
| Platforms | All (IMAP) |
| Logged | 2026-07-17 |

**Summary**  
`full_folder` sync failed with opaque `ProtocolException: Unable to list recent IMAP messages.` while the same IMAP account worked in another client. Root causes: (1) `enough_mail` `fetchRecentMessages` issues `FETCH 1:0` on empty mailboxes; (2) `ProtocolException.toString()` dropped `cause`, so Sync Status and SMTP actionable copy could not show the real error. Stale sockets also failed list with no reconnect retry.

**Expected**  
Empty folders sync as zero messages; Sync Status / send errors include the underlying IMAP/SMTP cause; one reconnect retry on connection-lost list failures.

**Actual (before fix)**  
Empty or mis-reported-empty folders failed the job; UI showed only the wrapper message; SMTP fell through to generic “check SMTP settings.”

**Resolution**  
Skip `fetchRecentMessages` when `messagesExists < 1`; treat invalid-messageset as empty; force-reconnect once on connection-lost list errors; append `Cause:` in `ProtocolException.toString()`. Tests: `test/protocol_exception_test.dart`, `test/imap_list_recent_helpers_test.dart`, nested-cause case in `test/send_error_messages_test.dart`.

---

### DEF-027 — enough_mail prints Invalid day for asctime UTC Date headers

| Field | Value |
| --- | --- |
| Priority | Pri-3 |
| Status | Closed |
| Fixed | 2026-07-17 |
| Area | `mail_date_parser.dart`, IMAP `_headerFromMessage` |

**Summary**  
IMAP list/sync hit Date headers like `Tue Aug 20 15:10:06 UTC 2019`. enough_mail’s `DateCodec` treated `Tue` as the day-of-month, `print`ed `Invalid day Tue in date …`, and fell back to “now”.

**Fix**  
Parse Date headers with a tolerant helper (asctime/`UTC`, RFC 5322, ISO, HTTP-date) before calling `decodeDate()`.

### DEF-026 — Domain-scoped junk and Focus overrides

| Field | Value |
| --- | --- |
| Priority | Pri-2 |
| Status | Closed |
| Fixed | 2026-07-17 |
| Area | `AddressMatchScope`, reading pane / bulk menus, `MailboxCubit` |

**Summary**  
Sender-only Focus/junk actions were insufficient when multiple addresses share a domain.

**Fix**  
Junk and Focused/Other actions open a Sender (default) vs Entire domain menu. Domain Focus upserts `FocusRuleMatchType.domain`; domain junk expands the move to all local matching mail (Not junk limited to junk-folder matches).

### DEF-025 — Manual Focused/Other and discoverable Not Junk

| Field | Value |
| --- | --- |
| Priority | Pri-2 |
| Status | Closed |
| Fixed | 2026-07-17 |
| Area | `MailboxCubit.markFocusBucket`, reading pane, bulk toolbar, Focus override wiring |

**Summary**  
Users could not correct Focus scoring mistakes, and Not Junk was easy to miss (reading pane only while already in Junk).

**Fix**  
Reading-pane and bulk **Focused** / **Other** actions upsert a per-sender `focus_rules` override and reclassify matching local mail; sync/header scoring honors those overrides. Bulk **Not junk** appears when multi-selecting in the Junk folder.

### DEF-024 — Focus/Other never classified synced mail

| Field | Value |
| --- | --- |
| Priority | Pri-1 |
| Status | Closed |
| Fixed | 2026-07-17 |
| Area | `SyncEngine._toMailMessage`, `RuleBasedFocusScorer`, IMAP/Graph list headers |

**Summary**  
Synced messages were always stored as `FocusBucket.focused`. The rule-based scorer existed only in unit tests, so newsletters and advertising never appeared under Other.

**Fix**  
Score at ingest using List-Id / List-Unsubscribe / Precedence / Feedback-ID / X-Mailer / noreply-style local parts / subject heuristics; providers fetch classification headers during list; kick reclassifies already-stored rows; header fetch updates the bucket when raw headers arrive.

### DEF-023 — Outbox queue badge not inspectable

| Field | Value |
| --- | --- |
| Priority | Pri-2 |
| Status | Closed |
| Fixed | 2026-07-17 |
| Area | title bar pills, `outbox_sheet.dart`, outbox delete APIs |

**Summary**  
The amber “N queued” pill showed pending sends with no way to inspect recipients/subject, surface SMTP errors, retry, or discard stuck items. Sync could still read “Up to date” while mail sat in the outbox.

**Fix**  
Tappable queued/failed/status pills open an Outbox sheet listing active items with error copy, Retry, Discard, Clear queued/failed, and Retry send now. Repository adds `countFailedOutbox` / `deleteOutbox*`; status label reports waiting-to-send counts.

### DEF-022 — Silent IMAP outbox send / recipient truncation

| Field | Value |
| --- | --- |
| Priority | Pri-1 |
| Status | Closed |
| Fixed | 2026-07-17 |
| Area | `MailProvider.send`, `ImapSmtpMailProvider`, `GraphMailProvider`, `SyncEngine._sendOutbox`, compose outbox enqueue |

**Summary**  
Outbox SMTP failures were marked on the row but the sync job still completed as success, so the UI showed nothing. `MailProvider.send` took a single `to` string (Cc never sent); `MailAddress.parse` kept only the first address. Stuck `sending` outbox rows were never reclaimed; empty To was allowed on compose.

**Fix**  
Multi-recipient `send({to, cc, bcc})` for Graph and IMAP/SMTP; outbox enqueue stores JSON address arrays; send path splits comma/semicolon lists; `_sendOutbox` throws when any item fails so the job surfaces as failed; reclaim `sending`→`queued` on kick; compose keeps the sheet open on failure and shows an actionable in-sheet error (auth / SMTP host / recipient); sync stores the same actionable `lastError`; sync status mentions failed outbox.

### DEF-021 — Folder list incomplete; trash/junk/archive actions failed without create path

| Field | Value |
| --- | --- |
| Priority | Pri-1 |
| Status | Closed |
| Fixed | 2026-07-17 |
| Area | IMAP/Graph `listFolders`, `SyncEngine`, `resolveFolderByRole`, `MailboxCubit.ensureSystemFolder` |

**Summary**  
Accounts often showed only Inbox because IMAP listed non-recursively and mapped only the inbox role, while Graph well-known role probes could abort the whole folder list. Delete/Archive/Junk then failed with “No trash/junk/archive folder” and offered no create path.

**Fix**  
Recursive IMAP LIST + SPECIAL-USE role mapping; resilient Graph pagination/well-known lookups; broader local name heuristics; confirm dialog to create missing system folders then retry the action.

### DEF-020 — Search sheet disposed TextEditingController during dismiss animation

| Field | Value |
| --- | --- |
| Priority | Pri-1 |
| Status | Closed |
| Fixed | 2026-07-17 |
| Area | `lib/ui/search/search_sheet.dart`, `lib/ui/compose/compose_sheet.dart` |

**Summary**  
`showSearchSheet` created a `TextEditingController` outside the route and called `dispose()` as soon as `showModalBottomSheet` completed. The sheet was still rebuilding during the dismiss animation, which threw “TextEditingController was used after being disposed,” then cascaded into layout/overflow failures and a lost device connection. Compose used the same anti-pattern.

**Fix**  
Own controllers in StatefulWidget `State.dispose()` for search and compose sheets (after the route is fully gone). Search also ignores stale async FTS results after unmount.

### DEF-019 — Reading pane hardcoded navy ignored active themes

| Field | Value |
| --- | --- |
| Priority | Pri-2 |
| Status | Closed |
| Fixed | 2026-07-16 |
| Area | `lib/theme/theme_tokens.dart`, `lib/ui/shell/reading_pane.dart`, `lib/ui/compose/compose_sheet.dart` |

**Summary**  
Empty and populated reading-pane surfaces used a hardcoded `#0C1228` navy fill, so Light, Solarized, Black, and other built-ins never tinted the reading pane. Account badge text also blended toward `Colors.white`.

**Fix**  
Added a required `content` token to all built-in palettes; reading pane empty/populated surfaces and accent wash now use `t.content` / theme-aware indigo blend; badge text blends toward `t.text`; and compose message surfaces use the active theme's content token.

**Notes**  
Regression: `test/theme_tokens_test.dart` (exact five-pack palettes, `content` in `copyWith`/`lerp`). Sweep: [UI-L8](UI_ENHANCEMENT_SWEEP.md) / [UI-P4](UI_ENHANCEMENT_SWEEP.md) landed 2026-07-16. Custom user themes remain [UI-P16](UI_ENHANCEMENT_SWEEP.md) (**W7**).

### DEF-010 — Account removal did not delete secure credentials

| Field | Value |
| --- | --- |
| Priority | Pri-1 |
| Status | Closed |
| Fixed | 2026-07-14 |
| Area | `AccountService`, `DiagnosticsService`, `SecureCredentialStore` |

**Summary**  
`DriftMailRepository.wipeAccount` cleared SQLite rows but no user-facing remove flow existed and secure-store secrets were never deleted, leaving orphaned IMAP passwords and Graph tokens on device after a local wipe.

**Fix**  
`AccountService.removeAccount` reads `credentialsRef` before wipe, calls `wipeAccount`, then `SecureCredentialStore.deleteCredentials`. UI gated by typed `WIPE {accountId}` confirmation via `DiagnosticsService.confirmationFor`.

### DEF-006 — Sync button appeared idle / stuck with no failure feedback

| Field | Value |
| --- | --- |
| Priority | Pri-1 |
| Status | Closed |
| Fixed | 2026-07-14 |
| Area | `SyncEngine`, sync jobs, Sync toolbar |

**Summary**  
Jobs left in `running` after a hang/crash were never reclaimed, so further syncs looked inert. Sync status could stay on “Syncing”, and the Sync button used mailbox `isLoading` (not real sync progress) with weak feedback.

**Fix**  
Reclaim orphaned running jobs at kick; `kickFresh()` for manual sync; Graph HTTP 45s timeout; clearer Sync snackbars (including “no linked accounts”).

### DEF-005 — Microsoft Graph account synced with no mail and no clear error

| Field | Value |
| --- | --- |
| Priority | Pri-1 |
| Status | Closed |
| Fixed | 2026-07-14 |
| Area | `GraphMailProvider.listFolders`, sync bootstrap |

**Summary**  
Adding a Graph account appeared to succeed but no messages loaded. Folder listing used `$select=…,wellKnownName`, which is beta-only on Graph v1.0 and returned HTTP 400. Bootstrap ran folder sync before inbox sync, so inbox never loaded. Failures only appeared vaguely as “Sync needs attention”.

**Fix**  
Drop `wellKnownName` from v1.0 `$select`; resolve inbox/sent/etc. roles via well-known folder paths. Make folder-list failures non-fatal for inbox sync. Surface the latest job error text in the sync status label.

### DEF-004 — HTML mail shown as plain text / raw links

| Field | Value |
| --- | --- |
| Priority | Pri-1 |
| Status | Closed |
| Fixed | 2026-07-14 |
| Area | IMAP `fetchBody`, reading pane (`MessageBodyView`) |

**Summary**  
After body fetch landed, multipart HTML mail (e.g. LinkedIn alerts) still looked like plain text with raw “View job” URLs. IMAP preferred `text/plain`, and the UI stripped/displayed HTML as text.

**Fix**  
Prefer `text/html` when fetching IMAP bodies; render HTML in a platform WebView (WebView2 texture on Windows, `webview_flutter` on Android) so complex mail/CSS lays out correctly; invalidate previously cached plain bodies for linked accounts (DB schema v2).

**Follow-up**  
`flutter_widget_from_html` was reverted — it threw `computeDryBaseline` / constraint errors on LinkedIn-style table layouts under Flutter 3.44.

### DEF-003 — IMAP headers sync but reading pane body stays empty

| Field | Value |
| --- | --- |
| Priority | Pri-1 |
| Status | Closed |
| Fixed | 2026-07-14 |
| Area | `MailboxCubit`, `DriftMailRepository`, IMAP `fetchBody` |

**Summary**  
After adding an IMAP account, message headers appeared but opening a message showed no body. Sync only persists headers/snippets; `MailProvider.fetchBody` was never called on open. IMAP also stores an empty snippet, so the preview-as-body fallback used for Graph was blank.

**Fix**  
On message open (and for the currently displayed message after refresh), fetch and cache the full body via the account provider. Header upsert preserves a previously cached body. HTML-only bodies are stripped to plain text for the reading pane.

### DEF-002 — Add Account Graph token field crashed (obscure + multiline)

| Field | Value |
| --- | --- |
| Priority | Pri-1 |
| Status | Closed |
| Fixed | 2026-07-14 |
| Area | `lib/ui/account/add_account_sheet.dart` |

**Summary**  
Opening Add Account asserted: obscured TextFields cannot be multiline. Graph token used `obscureText: true` with `maxLines: 6`.

**Fix**  
Removed obscure on the token field so multiline paste remains usable (token is still only held in memory/secure store after submit).
