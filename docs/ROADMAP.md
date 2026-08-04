<p align="center">
  <img src="branding/branding_logo_lockup_google.png" alt="synesis" width="360" />
</p>

# Synesis V1 Roadmap

| Field | Value |
| --- | --- |
| Status | **V1 complete** — exit signed off 2026-07-22; **V1.5 complete** (2026-07-27) |
| Spec | [SPEC.md](SPEC.md) v1.4 |
| Exit checklist | [V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md) — **signed off** |
| Product | Synesis |
| Platforms (v1) | Windows, Android |
| Last updated | 2026-08-04 (V2 Wave 6 **complete** — E10+E11 **GO**, **659 tests**; **Wave 6b** next — [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md)) |

This roadmap tracks implementation milestones. Requirements live in the SPEC; this file tracks status and exit criteria.

## Locked decisions

| Decision | Choice |
| --- | --- |
| Protocol strategy | Thin spikes of Graph + IMAP/SMTP early, then deepen together |
| State management | BLoC / Cubit ([AGENTS.md](../AGENTS.md)) |
| Sync push | Poll-first; Graph subscriptions later if cheap |
| Google auth | OAuth preferred; app-password fallback |
| Other IMAP | App-password / password first |
| DB encryption | Opt-in |
| Snooze | Local-only in v1 |
| Themes | All five selectors with full token packs |
| Account colors | Curated swatches + custom |
| Soft account cap | ~10 |
| Contacts / calendar | Post-v1 only |

## Milestone status

| ID | Milestone | Status | Exit criteria |
| --- | --- | --- | --- |
| M0 | Planning + BLoC foundation | Done | ROADMAP present; shell on BLoC; settings persist; tests green |
| M1 | Local data plane (Drift/SQLite) | Done | Cold start from DB; seed demo; restart restores mailbox offline |
| M2 | Dual protocol thin spike | Done | Graph + IMAP providers, secure creds, AccountService, bootstrap jobs |
| M3 | Sync engine deepen | Done | Durable jobs/cursors; incremental / remote_search / retention jobs |
| M4 | Compose / outbox / send | Done | Compose sheet queues outbox; send_outbox job via providers |
| M5 | Search (FTS5 + remote bridge) | Done | Local FTS search UI; remote_search job enqueued |
| M6 | Optional Focus | Done | Rule-based scorer + overrides + unit tests |
| M7 | Retention & sync profiles | Done | Retention dial in settings; RetentionService + cleanup job |
| M8 | Appearance completeness | Done | Five theme packs + density + account color picker |
| M9 | Android widgets | Done | Snapshot service + Kotlin AppWidgetProvider path |
| M10 | Windows desktop polish | Done | Tray preference + keyboard shortcuts (Ctrl+J/K/N/F) |
| M11 | Hardening & v1 gate | Done | Diagnostics service, wipe, exit checklist |
| M12 | Real account onboarding | Done | Add Graph/IMAP UI; AccountService wired; sync button; credential resolve aligned |

## Architecture (target)

```text
UI (BLoC) --read--> Repository (SQLite + FTS5) <--write-- SyncEngine
                                              ^
                                    widget_snapshots --> Android Kotlin
Sync Jobs --> GraphMailProvider | ImapSmtpMailProvider
Auth --> flutter_secure_storage
```

## How to run

```bash
flutter pub get
flutter run -d windows
flutter test
```

## Post-v1 & Tier D ([plan](TIER_D_PLAN.md))

Horizon backlog with promotion framework (V1.1 → V2 → enterprise). **V1.5 complete 2026-07-27** — see [V1_5_PLAN.md](V1_5_PLAN.md) §5. **V2 Wave 0 complete**; **Wave H complete**; **Wave 1 / V2.0a P0 complete** (2026-07-27, `00ebdef`); **Wave 2 complete** (2026-07-27, `b526e70`, 530 tests); **Wave 3 complete** (2026-07-27, 551 tests); **Wave 4 / V2.0b complete** (2026-07-27, `f2bd29b`, 556 tests) — [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md), [V2_WAVE4_QA.md](V2_WAVE4_QA.md) (**GO**). **Wave 5 / V2.0c complete** (2026-07-27, `73c181d`, 585 tests) — [V2_WAVE5_CHECKLIST.md](V2_WAVE5_CHECKLIST.md), [V2_WAVE5_QA.md](V2_WAVE5_QA.md) (**GO**). **Wave G / V2.0d complete** (2026-07-27, `f4c21b0`, **597 tests**) — [V2_WAVE_G_CHECKLIST.md](V2_WAVE_G_CHECKLIST.md), [V2_WAVE_G_QA.md](V2_WAVE_G_QA.md) (**GO**). **Wave 6P complete** (2026-08-04, **645 tests** — [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md)). **Wave 6 E10 GO** (2026-08-04, **659 tests**; E11 pending) — [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md), [V2_WAVE_6_QA.md](V2_WAVE_6_QA.md).

### Locked Tier D decisions

| # | Decision |
| --- | --- |
| 1 | **First post-V1 ship = V1.5** (full D6 ex-V1.1+V1.2 + dogfood UI; no shared mailbox) — *2026-07-22; supersedes “V1.1 = D6 only”* — [V1_5_PLAN.md](V1_5_PLAN.md) |
| 2 | **V2 headline = PIM** — Outlook-style modules; CardDAV/CalDAV day-one (Runbox); Graph-first order — [V2_PLAN.md](V2_PLAN.md). **Wave 0 complete**; **Wave H complete**; **Wave 1 complete**; **Wave 2 complete**; **Wave 3 complete**; **Wave 4 complete** (2026-07-27, `f2bd29b`, 556 tests); **Wave 5 complete** (2026-07-27, `73c181d`, 585 tests); **Wave G complete** (2026-07-27, `f4c21b0`, **597 tests**); **Wave 6P complete** (2026-08-04, **645 tests**); **Wave 6 E10 GO** (2026-08-04, **659 tests**; E11 operator dogfood pending) |
| 3 | **Enterprise crypto / shared mail / AI draft·summarize** — **Maybe/Someday** (not V2.0 critical path; AI paired with enterprise crypto if either is opted in) |
| 4 | **PST import** after V1.5 unless migration is acquisition channel |
| 5 | **Galaxy Watch** — **P3 / V2.1** (not V2.0 critical path) |
| 6 | **D6-3 Graph large attach** — **must-ship in V1.5** (operator hits cap often) |

### V2 operator waves (2026-07-27)

**Status:** **Wave G complete** (2026-07-27, `f4c21b0`, **597 tests**) — [V2_WAVE_G_CHECKLIST.md](V2_WAVE_G_CHECKLIST.md), [V2_WAVE_G_QA.md](V2_WAVE_G_QA.md) (**GO**). **Wave 6P complete** (2026-08-04, **645 tests** — [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md)). **Wave 6 complete** (2026-08-04, E10+E11 **GO**, **659 tests**) — [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md), [V2_WAVE_6_QA.md](V2_WAVE_6_QA.md). **Wave 6b** next. Full plan: [V2_PLAN.md](V2_PLAN.md).

V2.0a / V2.0b / V2.0c remain **release buckets**; operator execution follows this sequence:

| Wave | Scope | Status | Maps to |
| --- | --- | --- | --- |
| **Wave 0** | Account identity (display names, rail labels) | **Complete** (2026-07-27) | Pre-PIM gate |
| **Wave H** | Dependency hygiene (SDK, pub, native/KGP) | **Complete** (2026-07-27) | Pre-V2.0a gate |
| **Wave 1** | P0 — expanded schema (multi-list contacts, multi-calendar, FTS, sync job no-ops) | **Complete** (2026-07-27, `00ebdef`) | **V2.0a P0** |
| **Wave 2** | P1 — Graph contacts + calendars (multi-list/cal sync) | **Complete** (2026-07-27, `b526e70`) | V2.0a P1 |
| **Wave 3** | P2 — meeting-mail bridge (ICS, RSVP, local `.ics` drafts) | **Complete** (2026-07-27, `7cbfdaa`, 551 tests) | V2.0a P2 |
| **Wave 4** | P3–P4 — CardDAV/CalDAV (Runbox) | **Complete** (2026-07-27, `f2bd29b`, 556 tests) | V2.0b |
| **Wave 5** | P5–P6 — compose picker + Calendar UI (multi-select overlay / side-by-side) | **Complete** (2026-07-27, `73c181d`, 585 tests) | V2.0c |
| **Wave G** | Google People + Calendar API (XOAUTH Google PIM) | **Complete** (2026-07-27, `f4c21b0`, **597 tests**) | V2.0d |
| **Wave 6P** | Performance UX (Sync Honesty) — honest spinners, non-blocking kick, UI-P11/P9 partial, DEF-007/015 | **Complete** (2026-08-04) — E1–E11 ✅ (**645 tests**); E11 isolate deferred | Pre–Wave 6 gate — [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md) |
| **Wave 6** | Cross-account DnD copy (events + contacts; Graph + Google push; DAV local-only until 6b) | **Complete** (2026-08-04) — E10+E11 **GO** (**659 tests**) | [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md) · [V2_WAVE_6_QA.md](V2_WAVE_6_QA.md) |
| **Wave 6b** | CalDAV/CardDAV create-only write for copy targets | **Next** | Runbox dogfood |
| **Wave 6c** | Calendar series / recurring event copy semantics | Planned after 6b | Calendar RRULE/series only — not Tasks |
| **Wave 7** | **Final polish / Trish extras** — UI niceties if time permits ([DEF-054](DEFECTS.md), [DEF-050](DEFECTS.md), [DEF-055](DEFECTS.md), [DEF-056](DEFECTS.md), [DEF-046](DEFECTS.md), overflow sweep; **Trish calendar:** [DEF-075](DEFECTS.md) Week/Weekdays, [DEF-076](DEFECTS.md) DOY/WOY; optional pull-forward [DEF-071](DEFECTS.md) Calendar→Today). **Widgets:** [DEF-044](DEFECTS.md) moved to **V-Next**. | Planned — **last** | Not V2.0 critical path |

**Locked PIM product requirements (operator):** multi-calendar and multi-contact-list across accounts; select 1+ to display; Outlook-like calendar overlay / side-by-side (Wave 5 UI); **Google Workspace PIM via People + Calendar API (Wave G — complete)**; cross-account copy via DnD (**Wave 6 — complete**, **659 tests**; **6b** DAV write next; **6c** calendar series). Corporate Graph / Entra org = **post–Wave 6** research.

### Confirmed post-V1 (from V1 + Tier D → V1.5)

- Unlimited multi-window desktop → **V1.5**
- Per-account remote image block + domain whitelist → **V1.5**
- Graph large attachment upload session → **V1.5 (must)**
- Auto-mark read dwell / disable + pause in-view (UI-P28/P30) → **V1.5**
- One-click clear filters (UI-P29), settings IA (UI-P21) → **V1.5**
- Template vars, server snooze, PDF export, tracker blocking, toast actions → **V1.5** (ex-V1.2)

Full scope: **[V1_5_PLAN.md](V1_5_PLAN.md)**.

### Tier D themes (default disposition)

| Theme | Examples | Target |
| --- | --- | --- |
| **D6 V1.5 adjacency** | Multi-window+, image whitelist, Graph large attach, PDF, snooze, trackers, toast actions | **V1.5** ([plan](V1_5_PLAN.md)) |
| **D1 PIM** | Contacts, calendar, meeting invites | **V2.0** ([V2_PLAN.md](V2_PLAN.md)) |
| **D2 Crypto** | OpenPGP, S/MIME | Maybe/Someday |
| **D3 Legacy** | PST/MSG import, POP3, shared mailboxes, EAS | Selective / after V1.5 |
| **D4 Collab & AI** | AI draft/summarize (Maybe/Someday, paired with D2 if opted in), on-device ML Focus, team inboxes | Low / V2+ |
| **D5 Platforms** | iOS, macOS, Linux after PIM; **Galaxy Watch V2.1 (P3)** | Platform roadmap |
| **D7 Power depth** | JMAP, server rules, unsubscribe helper, Graph webhooks, editable keyboard shortcuts | Cherry-pick after V1.5 |

### Maybe / Someday ([TIER_D_PLAN.md §16](TIER_D_PLAN.md#16-maybe--someday-unplanned-backlog))

Explicitly considered; **unplanned** — on radar to avoid re-debate. Includes: **AI draft/summarize** (Maybe/Someday, not V2.0 critical path), newsletter builder, consumer mail merge, team collab (co-edit/read receipts), EAS/on-prem, mail hosting, cloud Focus ranking, Windows shell widgets. **Synesis Tasks** (if ever): basic local to-do + agenda with calendar items only — full productivity stays **Phronesis**. **Voice / assistant capture** (**V-SometimeSoonish**): in-car voice; phone assistants (**Gemini**, **Siri**, and peers) to add/modify items — not V2.0. **Contact postal addresses** (**Pri-3 / V-Next**): store when providers supply ADR; open in Google Maps / Waze / other map apps.

Full item catalog: [TIER_D_PLAN.md](TIER_D_PLAN.md).

### Legacy post-v1 list (SPEC §12)

- Full contacts & calendar (see Tier D TD-A)
- POP3, iOS/macOS/Linux, ML Focus, PGP/S/MIME
- ~~Interactive Entra OAuth~~ — in V1 W0

## V1 integration — single delivery ([review](V1_TIER_INTEGRATION.md))

**Locked wave order (2026-07-16):** ~~W0~~ **W0 landed** → ~~W1~~ **W1 landed** → ~~W2~~ **W2 landed** → ~~W3~~ **W3 landed** → ~~W5~~ **W5 landed** → ~~W6~~ **W6 landed** → ~~W4~~ **W4 landed** → ~~W7~~ **W7 landed**

| Wave | Name | Status | Absorbs |
| --- | --- | --- | --- |
| **W0** | Platform base + Graph OAuth priority | **Landed** (2026-07-16) | TA-0, TB-0 schema, TC-0, TA-5, TC-8 shell |
| **W1** | Message actions + trash | **Landed** (2026-07-17) | TA-1, TA-4 (trash recover + auto-purge default 30d) |
| **W2** | List & navigation UX | **Landed** (2026-07-17) | TB-1, TB-2, TB-4, TB-5, TB-7, TB-11, TB-14, **[UI sweep W2](UI_ENHANCEMENT_SWEEP.md)** |
| **W3** | Sync, storage & privacy | **Landed** (2026-07-17) | TC-1, TC-2, TB-10, TC-5/12, TC-6 phase 1 |
| **W5** | Desktop shell | **Landed** (2026-07-17) | TB-9, TC-9 (detached window), **[UI sweep W5](UI_ENHANCEMENT_SWEEP.md)**, [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) |
| **W6** | Notifications | **Landed** (2026-07-17) | TA-6, TC-7, [W6_NOTIFICATIONS_CHECKLIST.md](W6_NOTIFICATIONS_CHECKLIST.md) passed (operator) |
| **W4** | Compose system (**last feature wave**) | **Landed** (2026-07-18) | TA-2, TA-3, TB-6, TB-12, TB-13, TC-10, **UI-P19/P20** (outbound font, sig images) |
| **W7** | Hardening & optional | **Landed** (2026-07-18) | TC-3, TC-4, TC-11, QA matrix, **[UI sweep W7](UI_ENHANCEMENT_SWEEP.md)** |

**W0 landed (2026-07-16):**

- **Schema v5** — consolidated migration (`starred`, `thread_id`, `snoozed_until`, `trashed_at`, outbox envelope columns, attachments/signatures/sync_profiles tables); `test/schema_v5_test.dart`
- **`MessageQuery`** — composable list predicates; default query preserves pre-W0 inbox behavior; `test/message_query_test.dart`
- **`MailProvider` extensions** — Graph + IMAP `setStarred`, `moveMessage`, `deleteMessage`, `listAttachments`, `fetchAttachmentBytes`; capability flags + tests
- **MIME isolate** — `OutgoingEnvelope`, multipart builder in background isolate; `test/mime_builder_test.dart`
- **Graph OAuth** — PKCE browser flow, redirect capture, token refresh (`OAuthIdentityManager`); **live E2E** pending operator Entra app registration
- **Google OAuth** — PKCE + Gmail XOAUTH2 IMAP/SMTP; unit-tested token exchange/refresh
- **IMAP autoconfig** — Thunderbird ISPDB + domain `/.well-known` lookup in Add Account; `test/imap_autoconfig_test.dart`

**W1 landed (2026-07-17):**

- **Reading-pane actions** — reply, reply-all, forward (compose prefill), archive, move, star, delete (→ trash), recover, permanent delete, report junk / not junk; keyboard shortcuts (Delete, Shift+Delete, E, R, Shift+R, F, S)
- **`MailboxCubit` mutations** — optimistic local writes + `MailProvider` push + `push_message_action` job fallback; selection advance on delete/move
- **Trash semantics** — `trashed_at` on move to trash; recover to inbox; trash folder list via `MessageQuery.includeTrashed`
- **Trash auto-purge** — `trash_retention_days` setting (default 30, clamp 7–90); `trash_purge` sync job; `test/sync_engine_trash_purge_test.dart`
- **Junk (TA-4)** — `reportJunk` / `notJunk` via role folder move; context-aware reading-pane actions in junk/trash views
- **Star column** — list-pane toggle + reading-pane action
- **Tests** — `test/mailbox_cubit_test.dart` (star, delete, junk, trash folder query), `test/compose_prefill_test.dart`, `test/app_settings_cubit_test.dart`

**W2 landed (2026-07-17):**

- **Threading** — default threaded view; flat toggle in Appearance (`ThreadDisplayMode`); `MessageListProjector` groups by `(accountId, threadId)`; Graph `conversationId` + IMAP `References`/`In-Reply-To` via `resolveThreadId`
- **Filter bar + date sections** — `MessageViewFilter` chip bar; Outlook date buckets (Today, Yesterday, …); composes with Focus
- **Snooze + pin** — **local-only** `snoozed_until` / `pinned`; query exclusion; resurfacing on app open; no server folder move
- **Mobile gestures** — swipe defaults **right = archive**, **left = delete** (configurable); pull-to-refresh; portrait reading pager; [W2_AVD_CHECKLIST.md](W2_AVD_CHECKLIST.md)
- **Adaptive reading-pane toolbar** — icon+label actions at **≥520px** breakpoint
- **Virtual views** — sidebar Starred / Pinned / Snoozed via `MailboxVirtualView` + `MessageQuery`
- **Unread recount** — local folder badge recount from SQLite (`recountUnreadCounts`)
- **List polish (UI sweep)** — read-row dimming (UI-P2), pull-to-refresh (UI-P7), selection highlight (UI-P12)
- **Tests** — `test/message_list_projector_test.dart`, `test/message_filter_bar_test.dart`, `test/thread_id_test.dart`, `test/message_list_pane_gestures_test.dart`

**W3 landed (2026-07-17):**

- **Sync profiles** — `SyncProfile` domain type; `folder_scope_json` allowlist (roles/remoteIds); body policy; attachment max MB UI; per-account retention override in `EditAccountSheet`
- **Retention dial** — updates default sync profile + enqueues `retention_cleanup` job
- **Sync status sheet** — Jobs \| Accounts tabs; retry/cancel failed jobs; title-bar sync chip opens sheet; sync-now icon in title bar
- **Push / near-push** — Graph delta + cursor; IMAP IDLE; `connectivity_plus` network policy; `pushOnCellular` default **false**; `supportsPush: true` on Graph when delta path exists
- **Remote images (phase 1)** — `blockRemoteImages` default **true**; per-message “Load images for this message”; Appearance toggle
- **Tests** — `test/sync_status_sheet_test.dart`, `test/network_sync_policy_test.dart`, `test/remote_image_policy_test.dart`, `test/sync_engine_push_wake_test.dart`

**W5 landed (2026-07-17):**

- **Reading-pane layout (TB-9)** — Right / top / bottom via `MailSplitLayout`; persisted `readingPanePosition`; `test/mail_split_layout_test.dart`
- **Visual Focus** — collapses sidebar + list; persisted `visualFocusEnabled`; title bar + Ctrl+Shift+M
- **Keymap + DEF-001 (TC-9 / UI-P3)** — route-root `Focus.onKeyEvent` + `handleMailboxHardwareKey`; `?` help sheet; [DEF-001](DEFECTS.md) closed
- **Tray + minimizeToTray DI** — `WindowsDesktopController`; Appearance toggle → `AppSettingsCubit` → `app.dart` `BlocListener` → `setMinimizeToTrayEnabled`
- **Ctrl+F find in message** — `findInMessageRequested` → `ReadingPane` find bar; plain + HTML match navigation
- **Print / save EML / open in new window** — reading-pane overflow actions wired (`message_print_service`, `message_file_service`, detached window controller)
- **Open EML** — title-bar file picker + launch-with-`.eml`-arg → `eml_preview_sheet`
- **Detached message window** — `WindowsDetachedMessageWindowController` + overflow **Open in new window** (V1 single-window retarget; **superseded by V1.5 Wave D / D6-1** — unlimited concurrent detached windows, see [V1_5_PLAN.md](V1_5_PLAN.md))
- **Manual checklist** — [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) passed (operator); Windows `.eml` Explorer ProgId **deferred** (packaging follow-up)

**W6 landed (2026-07-17):**

- **`NotificationService`** — global off, per-account mute, quiet hours, starred-only, dedupe, aggregate toast; foreground suppress
- **Settings** — `AppSettingsCubit` notification prefs + title-bar **Notifications** sheet (`notifications_sheet.dart`)
- **Platform adapters** — `AndroidNotificationAdapter` (channel + permission); `WindowsNotificationAdapter` (native toast)
- **Foreground tracking** — `AppForegroundTracker` (Android); `DesktopController.isWindowFocused` (Windows)
- **`SyncEngine.onNewUnread`** — incremental inbox only; bootstrap and remote search do not notify
- **Tests** — `test/notification_service_test.dart`; settings group in `app_settings_cubit_test.dart`
- **Manual checklist** — [W6_NOTIFICATIONS_CHECKLIST.md](W6_NOTIFICATIONS_CHECKLIST.md) passed (operator)

**W4 landed (2026-07-18):** Compose system — **code landed**; operator inspection/validation **complete**; [W4_COMPOSE_CHECKLIST.md](W4_COMPOSE_CHECKLIST.md) checkbox tick-off pending (operator-owned).

**W7 landed (2026-07-18):** Hardening & optional — TC-4 Focus override UI, DEF-034/UI-P27 auto-mark, UI-P16/P17/P18 themes/export/fonts, density + empty states, TC-11 widget depth (timeboxed). **TC-3 encryption spike: shipped** (SQLite3MultipleCiphers via `sqlite3` hooks, opt-in, default unchanged) — see [W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md). Operator validation complete; [W7_HARDENING_CHECKLIST.md](W7_HARDENING_CHECKLIST.md) checkbox tick-off pending.

**Critical path:** **W0 landed** → **W1 landed** → **W2 landed** → **W3 landed** → **W5 landed** → **W6 landed** → **W4 landed** → **W7 landed** → **Final wave** (Phase G + V1 exit open). Live Graph OAuth dogfood is an operator checkpoint (Entra registration), not a wave blocker.  
**Locked decisions:** [V1_TIER_INTEGRATION.md §12](V1_TIER_INTEGRATION.md#12-locked-decisions-2026-07-16).

## UI enhancement sweep ([plan](UI_ENHANCEMENT_SWEEP.md))

Visual polish & mailbox interaction backlog — **active; add items in [§7 Backlog](UI_ENHANCEMENT_SWEEP.md#7-backlog--add-here)** (UI-P21–P28 include settings IA, search datetimes, folder mark-all, Ctrl+A, multi-select affordances, remote Seen sync, auto-mark read dwell + post-V1 settings).

| Pri | Item | Status | V1 wave |
| --- | --- | --- | --- |
| **Pri-1** | Mark read/unread, folder tree, account colors | **Landed** | — |
| **Pri-1** | Unread counts local recount | **Landed** (W2) | W2 |
| **Pri-2** | Read-row dimming | **Landed** (W2) | **W2** |
| **Pri-2** | Theme token polish (5 packs + `content`) | **Landed** (2026-07-16) | — | [UI-L8](UI_ENHANCEMENT_SWEEP.md), [DEF-019](DEFECTS.md) |
| **Pri-2** | [DEF-001](DEFECTS.md) shortcuts | **Closed** (W5, 2026-07-17) | **W5** |
| **Pri-2** | [DEF-007](DEFECTS.md) read-state sync flicker | Scheduled — Wave 6P | Wave 6P P1 |
| **Pri-3** | Density/spacing pass | **Landed** (W7) | **W7** |
| **Pri-3** | Empty states, loading skeletons, widget themes | **Partial** (W7) — empty states + widget theme tokens; skeletons deferred | **W7** |
| **Pri-2** | Custom themes (multiple, fork built-ins) | **Landed** (W7) | **W7** | [UI-P16](UI_ENHANCEMENT_SWEEP.md) |
| **Pri-2** | Export / import settings (no secrets) | **Landed** (W7) | **W7** | [UI-P17](UI_ENHANCEMENT_SWEEP.md) |
| **Pri-2** | App-wide UI font (family, size, color) | **Landed** (W7) | **W7** | [UI-P18](UI_ENHANCEMENT_SWEEP.md) |
| **Pri-2** | Outbound message font | **Partial** (W4) — default HTML font stack on send; user family/size/color prefs not shipped | **W4** | [UI-P19](UI_ENHANCEMENT_SWEEP.md) |
| **Pri-2** | Signature images (HTML) | **Landed** (W4) | **W4** | [UI-P20](UI_ENHANCEMENT_SWEEP.md) |
| **Pri-2** | [DEF-034](DEFECTS.md) / UI-P27 auto-mark read (5s default ON) | **Closed** (W7) | **W7** (V1 scope; **not W5 blocker**) |
| **Pri-2.5** | [DEF-050](DEFECTS.md) list right-click mark read (solo vs thread prompt) | Open | **Wave 7 / Trish extras** |
| **Pri-2** | [DEF-055](DEFECTS.md) include Sent items in conversation threads | Open (enhancement) | **Wave 7 / Trish extras** |
| **Pri-2** | [DEF-056](DEFECTS.md) thread/list sort oldest first vs newest first | Open (enhancement) | **Wave 7 / Trish extras** |
| **Pri-3** | [DEF-054](DEFECTS.md) resizable mail panes on Windows (drag vertical splitters) | Open | **Wave 7 / Trish extras** |
| **Pri-3** | [DEF-046](DEFECTS.md) hamburger → folders-only sheet (swipe keeps full drawer) | Open (enhancement) | **Wave 7 / Trish extras** |
| **Pri-3** | [DEF-039](DEFECTS.md) / [DEF-040](DEFECTS.md) account dialog overflow sweep | Open | **Wave 7 / Trish extras** |
| **Pri-2.5** | [DEF-071](DEFECTS.md) Calendar defaults to Today (Agenda / day-first) | Open (enhancement) | **V-Soon / V-Next** (Wave 7 optional pull-forward) |
| **Pri-2** | [DEF-078](DEFECTS.md) Phone Quick Reply density + settings toggle (**Trish**) | Open (enhancement) | **V-Next** |
| **Pri-2** | [DEF-044](DEFECTS.md) per-account home-screen list widget + open in app (**Trish** / AquaMail bar) | Open (enhancement) | **V-Next** (bumped from Wave 7 Pri-3) |
| **Pri-3** | [DEF-075](DEFECTS.md) Calendar Week + Weekdays views (**Trish**) | Open (enhancement) | **Wave 7 / Trish extras** |
| **Pri-3** | [DEF-076](DEFECTS.md) Calendar day-of-year + week-of-year (**Trish**) | Open (enhancement) | **Wave 7 / Trish extras** |
| **Pri-3** | [DEF-079](DEFECTS.md) Contact postal addresses when provided + open in Maps / Waze / peers (**Trish**) | Open (enhancement) | **V-Next** |
| **Pri-3** | [DEF-081](DEFECTS.md) Calendar pills: temporary show/hide in current view; reset on leave (**Trish**) | Open (enhancement) | **V-Next** |

Full inventory + backlog template: **[UI_ENHANCEMENT_SWEEP.md](UI_ENHANCEMENT_SWEEP.md)**.

## Tier A — table stakes ([plan](TIER_A_PLAN.md))

Competitive gap closure per [COMPETITIVE_ANALYSIS.md](COMPETITIVE_ANALYSIS.md). **W0 foundations + OAuth landed 2026-07-16; W1 message actions landed 2026-07-17; W2 list UX landed 2026-07-17; W3 sync landed 2026-07-17; W5 desktop shell landed 2026-07-17.**

| Phase | Milestone | Status | Depends on | Exit highlight |
| --- | --- | --- | --- | --- |
| **TA-0** | Foundations | **Landed** (2026-07-16) | — | Schema v5, `MailProvider` mutations, MIME isolate bootstrap |
| **TA-1** | Core message actions | **Landed** (2026-07-17, W1) | TA-0 | Reply, forward, delete, archive, move, star, trash recover + auto-purge wired |
| **TA-2** | Compose envelope | **Landed** (W4, 2026-07-18) | TA-0, TA-1 | CC/BCC, quote, signatures, quick reply |
| **TA-3** | Attachments | **Landed** (W4, 2026-07-18) | TA-0, TA-2 | View, download, compose attach, MIME send |
| **TA-4** | Junk mail | **Landed** (2026-07-17, W1) | TA-1 | Report junk / not junk via folder move |
| **TA-5** | Browser OAuth | **Landed in code** (2026-07-16) | TA-0 | Entra + Google PKCE; live Graph E2E = operator Entra registration |
| **TA-6** | Notifications | **Landed** (W6, 2026-07-17) | TA-0 | Android + Windows new-mail alerts; [W6_NOTIFICATIONS_CHECKLIST.md](W6_NOTIFICATIONS_CHECKLIST.md) passed |

**Implementation order:** [V1 waves W0–W7](V1_TIER_INTEGRATION.md) — not isolated tier phases.

**Locked decisions:** [TIER_A_PLAN.md §16](TIER_A_PLAN.md#16-locked-decisions-2026-07-16).

## Tier B — competitive parity ([plan](TIER_B_PLAN.md))

**Planning complete** — **TB-0 MessageQuery foundations landed in W0** (2026-07-16); **TB-1, TB-2, TB-4, TB-5, TB-7, TB-11, TB-14 landed in W2** (2026-07-17); **TB-10 push landed in W3** (2026-07-17); **TB-9 layout landed in W5** (2026-07-17); **TB-6, TB-12, TB-13 landed in W4** (2026-07-18).

| Phase | Milestone | Status | Depends on | Exit highlight |
| --- | --- | --- | --- | --- |
| **TB-0** | MessageQuery foundations | **Landed** (W0) | TA-0 / W0 | Single list pipeline + schema v5 query columns |
| **TB-1** | Conversation threading | **Landed** (2026-07-17, W2) | TB-0 | Thread groups + flat toggle (default threaded) |
| **TB-2** | Filters + date grouping | **Landed** (2026-07-17, W2) | TB-0 | `MessageViewFilter` + Today/Yesterday sections |
| **TB-4** | Snooze | **Landed** (2026-07-17, W2) | TB-0 | Local-only `snoozed_until`; query exclusion |
| **TB-5** | Pin UI | **Landed** (2026-07-17, W2) | TB-0 | Local pin; retention-exempt; virtual view |
| **TB-6** | Drafts | **Landed** (W4, 2026-07-18) | TA-2 | Local autosave (outbox `draft`); server Drafts sync stretch |
| **TB-7** | Mobile gestures | **Landed** (2026-07-17, W2) | TA-1 | Swipe right=archive / left=delete; pull-to-refresh; AVD checklist |
| **TB-9** | Layout + Visual Focus | **Landed** (2026-07-17, W5) | — | Right/top/bottom + Visual Focus; checklist passed; draggable split deferred; `.eml` ProgId deferred (packaging) |
| **TB-10** | Push sync | **Landed** (2026-07-17, W3) | — | IMAP IDLE + Graph delta; network policy |
| **TB-11** | Starred view | **Landed** (2026-07-17, W2) | TB-0, TA-1 | Virtual starred folder |
| **TB-12** | Rich text compose | **Landed** (W4, 2026-07-18) | TA-2 | HTML compose + send |
| **TB-13** | Templates | **Landed** (W4, 2026-07-18) | TA-2 | Canned responses |
| **TB-14** | List polish | **Landed** (2026-07-17, W2) | — | Read dimming, pull-to-refresh, selection highlight |

## Tier C — differentiation ([plan](TIER_C_PLAN.md))

**Planning complete** — **TC-8 autoconfig landed in W0** (2026-07-16); **TC-1, TC-2, TC-5, TC-6 phase 1, TC-12 landed in W3** (2026-07-17); **TC-9 desktop power pack landed in W5** (2026-07-17); **TC-7 landed in W6** (2026-07-17); **TC-3, TC-4, TC-11 landed in W7** (2026-07-18); **TC-10 landed in W4** (2026-07-18).

| Phase | Milestone | Status | Exit highlight |
| --- | --- | --- | --- |
| **TC-0** | Settings + profile schema | **Partial (W0)** | `sync_profiles`, account overrides — schema v5 tables |
| **TC-1** | Sync profiles + per-account retention | **Landed** (2026-07-17, W3) | Full SPEC §8.2 — profiles, folder scope, body policy, attachment cap |
| **TC-2** | Network-aware sync | **Landed** (2026-07-17, W3) | WiFi vs mobile poll/IDLE; `pushOnCellular` default off |
| **TC-3** | DB encryption | **Landed** (2026-07-18, W7 spike → ship) | SQLite3MultipleCiphers opt-in via `sqlite3` hooks (no `sqlcipher_flutter_libs` needed); passphrase in OS keystore, in-place migration. See [W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md) |
| **TC-4** | Focus override UI | **Landed** (W7, 2026-07-18) | Domain/sender rules editor |
| **TC-5** | Sync transparency | **Landed** (2026-07-17, W3) | Job queue viewer + account health (merged TC-12) |
| **TC-6** | HTML privacy | **Phase 1 landed** (2026-07-17, W3) | Block remote images; per-message load; phase 2 post-v1 |
| **TC-7** | Notification granularity | **Landed** (W6, 2026-07-17) | Per-account mute, quiet hours; checklist passed |
| **TC-8** | IMAP autoconfig | **Landed (W0)** | ISPDB / domain well-known discovery |
| **TC-9** | Desktop power pack | **Landed** (2026-07-17, W5) | Keymap/tray/find/print/EML/detach UI landed; checklist passed; `.eml` ProgId deferred (packaging) |
| **TC-10** | Schedule send | **Landed** (W4, 2026-07-18) | Outbox `send_after` gated in SyncEngine; schedule UI in compose |
| **TC-11** | Widget depth | **Partial** (W7 timeboxed) | Theme tokens + Focused/Other unread split; folder-scoped config deferred |
| **TC-12** | Account health panel | **Landed** (2026-07-17, W3) | Merged into sync status sheet |

## Tier D — horizon ([plan](TIER_D_PLAN.md))

**Planning complete** — post-V1; promotion into V1.1/V2 via [TIER_D_PLAN.md §2](TIER_D_PLAN.md#2-promotion-framework).

| Track | Examples | Default |
| --- | --- | --- |
| **V1.5 (D6 + dogfood UI)** | Multi-window+, image whitelist, large Graph attachments, PDF, snooze, trackers, toast actions, UI-P28–P30/P21 | **Complete** (2026-07-27) — [V1_5_PLAN.md](V1_5_PLAN.md) |
| **V2.0 (TD-A)** | **Wave 0:** account identity — **complete**. **Wave H:** dependency hygiene — **complete**. **Wave 1:** P0 schema — **complete** (2026-07-27). **Wave 2 complete:** Graph PIM; **Wave 3 complete:** meeting-mail bridge (551 tests); **Wave 4 complete:** CardDAV/CalDAV (556 tests); **Wave 5 complete:** picker + Calendar/People UI (585 tests); **Wave G complete:** Google People + Calendar API (`f4c21b0`, **597 tests**); **Wave 6P next** (Sync Honesty); **Wave 6** (DnD copy) after 6P | Major version — [V2_PLAN.md](V2_PLAN.md) |
| **V2.1** | Galaxy Watch (P3), PIM polish | After V2.0 |
| **Defer** | Enterprise crypto/shared mail, AI draft/summarize, Maybe/Someday (§16) | Unplanned radar |

**Locked:** V1.5 adjacency · V2.0 = PIM (+ CardDAV/CalDAV + **Google PIM Wave G**) · **Wave 0 complete · Wave H complete · Wave 1 complete · Wave 2 complete · Wave 3 complete · Wave 4 complete (556 tests) · Wave 5 complete (585 tests) · Wave G complete (`f4c21b0`, 597 tests) · Wave 6P next · Wave 6 after 6P** · Watch = V2.1 P3 · Enterprise + AI = Maybe/Someday · D6-3 must-ship.

## Planned backlog (post-foundation)

Feature work captured for scheduling. Requirements baseline in [SPEC.md](SPEC.md); this table tracks intent and status (including items landed in later waves).

| Pri | Item | Status / notes |
| --- | --- | --- |
| **Pri-1** | **Edit and remove accounts** | **Landed (2026-07-14).** `ManageAccountsSheet` in Appearance settings; `EditAccountSheet` (label/accent/re-auth); `RemoveAccountDialog` with typed `WIPE {accountId}` gate. `AccountService` orchestrates metadata updates, credential rotation, and secure wipe (`DriftMailRepository.wipeAccount` + `SecureCredentialStore.deleteCredentials`). Post-remove: `MailboxCubit.onAccountRemoved`, `AppSettingsCubit.removeAccountFocus`, `WidgetSnapshotService.refreshAll()`. |
| **Pri-1** | **Cross-cutting message filter system** | **Landed (code, Final wave Phase B, 2026-07-18).** Extends W2 `MessageViewFilter` / `MessageQuery` — `recipientContains`, named **saved filters** (device-local prefs, soft cap 20), Saved sheet (apply / save / rename / delete). Date buckets remain **UI section headers** only. Distinct from Focus ([SPEC §8.3](SPEC.md#83-dual-layer-focus-mode-optional)) and FTS search ([SPEC §8.1](SPEC.md#81-tiered-search)); see [SPEC §8.6](SPEC.md#86-message-list-filters-view-predicates). |
| **Pri-3** | **Header details view** | **Landed.** Reading-pane **Headers** action opens a bottom sheet with parsed fields (From, To/Cc when present in raw block, Subject, Date, Message-ID, account/folder) plus a scrollable monospace raw header block. Local-first from `messages.raw_headers`; on-demand provider fetch via `MailProvider.fetchHeaders` (Graph `internetMessageHeaders`, IMAP `BODY.PEEK[HEADER]`) with optional SQLite cache (schema v4). |
| **Pri-2** | **Per-account retention settings** | **Landed (2026-07-17, W3).** Per-account retention override + sync profile assignment in `EditAccountSheet`; device-wide retention dial updates default sync profile and enqueues cleanup. See [SPEC §8.2](SPEC.md#82-variable-retention-dials--sync-profiles). |
| **Pri-2** | **Junk mail filter** | **Landed (2026-07-17, W1 / TA-4).** Report junk / not junk via role-folder move; context-aware reading-pane when viewing junk. Distinct from optional Focus heuristics and from the cross-cutting message filter system (junk is folder/provider semantics). Optional client rules layer still deferred. |
| **Pri-1** | **Attachments (receive, view, compose)** | **Landed (W4, 2026-07-18).** `attachments` / `attachment_blobs` tables; provider list/fetch; reading-pane strip + download; compose paperclip → staged blobs → MIME send; sync-profile MB cap gate. [SPEC §5.3](SPEC.md#53-body-and-attachment-strategy). Operator validation complete; [W4_COMPOSE_CHECKLIST.md](W4_COMPOSE_CHECKLIST.md) checkbox tick-off pending. |
| **Pri-2** | **Per-account signatures** | **Landed (W4, 2026-07-18).** Named HTML/plain signatures per account + default/none; compose picker; signature image assets (CID→data-URI on send, [UI-P20](UI_ENHANCEMENT_SWEEP.md)). Operator validation complete; checkbox tick-off pending. |
| **Pri-2** | **Desktop reading-pane layout (Outlook-style)** | **Landed (2026-07-17, W5).** `MailSplitLayout` + persisted `readingPanePosition` (right/top/bottom). Visual Focus collapse landed. Ctrl+F find, print/save EML, detached window wired. [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) passed (operator). Draggable split divider deferred (TB-9.1). Windows `.eml` Explorer ProgId deferred (packaging). |
| **Pri-1** | **Optional encryption at rest (desktop DB)** | **Landed (2026-07-18, W7 spike → ship).** Locked: opt-in ([§11 open question #4](SPEC.md#111-assumptions-baked-into-this-draft)). Ships as **SQLite3MultipleCiphers** via `sqlite3` package hooks (`sqlcipher_flutter_libs` confirmed obsolete/no-op for our 3.x `sqlite3` — not needed); `DbEncryptionConfig` (prefs flag + `flutter_secure_storage` passphrase) + `DbEncryptionMigrator` (in-place `VACUUM INTO`/`rekey`, backup + integrity check + rollback) + "Encryption" settings sheet with irreversible-loss warning. Restart required to apply (no live DB hot-swap in V1 — documented boundary, not a gap). See [W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md). **Explicitly post-v1:** PGP/S/MIME message encryption ([Post-v1](#post-v1-not-scheduled)). TLS for IMAP/SMTP/Graph is baseline, not this item. |
| **Pri-2** | **App icon & branding assets** | **Landed / wired (Final wave Phase A, 2026-07-18).** Locked: stealth lowercase `synesis` wordmark (Option B) + **Data Envelope v2** icon + **minimal Android splash** (obsidian + centered v2; first-frame dismiss; **no Windows splash**). Windows `.ico`, Android adaptive + notification mono, in-app title-bar wordmark — see **[branding/README.md](branding/README.md)** + **[FINAL_WAVE_PLAN.md](FINAL_WAVE_PLAN.md)**. |
| **Pri-3** | **Android emulator & device QA matrix** | **Not started.** Establish repeatable manual + CI smoke path on Android AVD alongside Windows. See [Android testing notes](#android-emulator-testing) below. V1 smoke only — deeper battery / UX track is **Post-V1** (below). |
| **Pri-1** | **Hold / pause auto-mark for in-view message** | **Landed (V1.5 Wave A, 2026-07-22).** **[UI-P30](UI_ENHANCEMENT_SWEEP.md)** + **[UI-P28](UI_ENHANCEMENT_SWEEP.md)** auto-mark settings. |
| **Pri-2** | **One-click clear active filters** | **Landed (V1.5 Wave A, 2026-07-22).** **[UI-P29](UI_ENHANCEMENT_SWEEP.md)** — chip × / toolbar Clear resets ephemeral `userFilter`. |
| **Pri-2** | **Performance test suite** (**Post-V1**) | **Not a V1 blocker.** Spreadsheet-cataloged like automated tests — columns: `perf_id`, area, platform, scenario, metric, budget, harness, status. Harness: microbench + timeline on fixture DBs first; friend-and-family traces later. Mirror [TEST_INVENTORY.md](TEST_INVENTORY.md) pattern; generate script later (same shape as `tool/generate_test_inventory.py`). |
| **Pri-2** | **Android focus track** (**Post-V1**) | **Not a V1 blocker** (battery is the headline concern, still scheduled post-ship). Battery life (sync / IDLE / push / wakelocks / Doze), visual/UX density vs Windows, leftover widget / deep-link polish. Device + AVD matrix spreadsheet-backed (extends the Pri-3 smoke matrix above). Distinct from Final-wave branding wire-up and FW-5 E2E smoke. |
| **Pri-3** | **Project health dashboard** (**Adjacent tooling** / Post-V1) | **Not a product feature — reusable meta tooling.** Docs-only idea for now; spin up after V1 while operator dogfoods. Surfaces wave/todo progress, test-inventory CSV signals, future perf-suite metrics, and related health. Reusable beyond Synesis. Stub: **[POST_V1_HEALTH_DASHBOARD.md](POST_V1_HEALTH_DASHBOARD.md)**. Not a V1 or Final-wave deliverable. |

**Suggested sequencing:** account edit/remove (Pri-1, landed) → header details (Pri-3, landed) → junk filter (Pri-2, landed W1) → per-account retention (Pri-2, landed W3) → desktop reading-pane layout (Pri-2, landed W5) → **attachments + signatures (Pri-1/Pri-2, landed W4)** → **W7 hardening (landed)** → **Final wave** (branding + filter system + FW-1…FW-6). Encryption at rest shipped in W7; Android emulator QA continues into Final-wave E2E. **V1.5 complete (2026-07-27).** **V2 Wave 1 complete** — see [V2_PLAN.md](V2_PLAN.md), [V2_0A_P0_CHECKLIST.md](V2_0A_P0_CHECKLIST.md), and [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md). **Wave 2 (Graph PIM) complete** (2026-07-27, `b526e70`, 530 tests) — [V2_WAVE2_CHECKLIST.md](V2_WAVE2_CHECKLIST.md). **Wave 3 (meeting-mail bridge) complete** (2026-07-27, 551 tests) — [V2_WAVE3_CHECKLIST.md](V2_WAVE3_CHECKLIST.md). **Wave 4 (CardDAV/CalDAV) complete** (2026-07-27, `f2bd29b`, 556 tests) — [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md); Renee GO [V2_WAVE4_QA.md](V2_WAVE4_QA.md). **Wave 5 complete** (2026-07-27, `73c181d`, 585 tests) — [V2_WAVE5_CHECKLIST.md](V2_WAVE5_CHECKLIST.md); Renee GO [V2_WAVE5_QA.md](V2_WAVE5_QA.md). **Wave G complete** (2026-07-27, `f4c21b0`, **597 tests**) — [V2_WAVE_G_CHECKLIST.md](V2_WAVE_G_CHECKLIST.md); Renee GO [V2_WAVE_G_QA.md](V2_WAVE_G_QA.md). **Wave 6P next** (Performance UX / Sync Honesty — [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md)). **Wave 6** (cross-account DnD copy) after 6P. **Post-V1:** performance test suite + Android focus track (Pri-2). **Adjacent tooling (Pri-3):** project health dashboard — [POST_V1_HEALTH_DASHBOARD.md](POST_V1_HEALTH_DASHBOARD.md).

## Final wave (V1 exit / release readiness)

**Status:** **Complete** — Phases A–G **landed**; V1 exit **signed off 2026-07-22**. Plan: **[FINAL_WAVE_PLAN.md](FINAL_WAVE_PLAN.md)**.

This is the last gate before v1 ship. Track exit criteria in **[V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md)** (**signed off**). Classic FW-1…FW-6 remain release-readiness work; the Final wave **also absorbed**:

- **Pri-1 cross-cutting message filter system** (Phase B — extend `MessageViewFilter` / saved presets; see plan §4)
- **Pri-2 branding wire-up** (Phase A — wordmark B, Data Envelope v2, minimal Android splash; skip Windows splash)

FW-1 still forbids *ad-hoc* new features; filters and branding are **named Final-wave phases**, not sneaked into the refactor pass.

**Operator status (2026-07-22):** W4 + W7 checklists **signed off**; FW-5 matrix **finalized Pass**; V1 exit **signed off**.

### Position relative to remaining backlog

| Backlog item | Status | Final wave relationship |
| --- | --- | --- |
| **Cross-cutting message filter system** (Pri-1) | **Landed** (Phase B, 2026-07-18) | E2E includes filter scenarios — [FW-5 living draft](V1_MANUAL_E2E_MATRIX.csv) |
| **Per-account retention** (Pri-2) | **Landed** (W3) | Already in product; E2E matrix includes retention |
| **Junk mail filter** (Pri-2 / TA-4) | **Landed** (W1) | Already in product; E2E covers report junk / not junk |
| Attachments, signatures, layout, encryption | Attach/sig **landed W4**; layout **landed W5**; encryption **landed W7** | Operator validation complete; checkbox tick-off pending |
| **App icon & branding** (Pri-2) | **Landed / wired** (Phase A, 2026-07-18) | [branding/README.md](branding/README.md) + E2E branding smoke rows |

**Critical path to v1:** ~~W2~~ **W2 landed** → ~~W3~~ **W3 landed** → ~~W5~~ **W5 landed** → ~~W6~~ **W6 landed** → ~~W4~~ **W4 landed** → ~~W7~~ **W7 landed** → ~~Final wave~~ **Final wave complete** ([FINAL_WAVE_PLAN.md](FINAL_WAVE_PLAN.md)) → ~~[V1 exit checklist](V1_EXIT_CHECKLIST.md)~~ **signed off 2026-07-22**.

### Suggested order within the wave

Full phased kickoff (branding → filters → FW-* → checklist payback): **[FINAL_WAVE_PLAN.md](FINAL_WAVE_PLAN.md)**. Classic FW steps below remain valid inside that plan (Phases C–G).

| Step | Item | Scope | Notes |
| --- | --- | --- | --- |
| **FW-1** | Last refactoring pass | Polish and cleanup after feature landings; rename dead code, tighten APIs, align patterns with AGENTS.md; fix debt found in pass only — **no new product features** (filters/branding are separate Final-wave phases) | After W7 code + branding/filter phases; unblocks stable coverage baselines |
| **FW-2** | Verify test code coverage | Measure (`flutter test --coverage` → `lcov` / IDE report); map gaps; raise floor on **critical paths**: sync engine, accounts/onboarding, `MailboxCubit`, Graph + IMAP providers, `MessageQuery` / filters | Target thresholds TBD after first measurement; block release on critical-path regressions |
| **FW-3a** | User documentation — comprehensive guide | End-user guide: accounts, folders, compose, search, Focus, **filters**, settings, wipe, platform differences (Windows vs Android) | Can run **in parallel** with FW-3b, FW-3c, and FW-4 |
| **FW-3b** | User documentation — quick start | Short “experienced user” path: install → add account → read/send → one settings tip; anti-TL;DR for users who skip long docs | Separate doc from FW-3a; cross-link both ways |
| **FW-3c** | **Dart-in-Synesis beginner guide** | Engineer/onboarding tour: how this repo uses Dart/Flutter (Cubits, Drift, SyncEngine, providers) — artifact [`DART_IN_SYNESIS.md`](DART_IN_SYNESIS.md) | Can land **early** once feature waves stabilize; owners **Page** (+ Steve review); cross-link from [README](../README.md) and [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md) |
| **FW-4** | Final documentation update sweep | Align [SPEC.md](SPEC.md), this ROADMAP, [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md), [README.md](../README.md), [DEFECTS.md](DEFECTS.md), and [V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md) with **shipped reality**; close or re-scope stale items | Parallel with FW-3a/3b; feeds checklist sign-off |
| **FW-5** | Comprehensive manual E2E test matrix | Recommended manual tests in **versionable spreadsheet form** — e.g. `docs/V1_MANUAL_E2E_MATRIX.csv` (importable into Excel / Google Sheets). **Automated** coverage is already cataloged in [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) — see [TEST_INVENTORY.md](TEST_INVENTORY.md) | **Last** as formal gate, or start earlier as a **living checklist** during W7/Final QA and finalize here |
| **FW-6** | Reusable multi-agent system prompt / playbook | Distill Steve→Jules→Renee→Page→Tesla phase-gate workflow, wave-close rituals (test inventory handoff, DEFECTS, Gold Master headers, local-first/BLoC/Isolates stack rules), and Cursor agent roster into a **portable system prompt** suitable for seeding future projects (not Synesis-specific product rules only — generalize rituals). Suggested artifact: `docs/MULTI_AGENT_SYSTEM_PROMPT.md` (and optionally a trimmed `.cursor`/Copilot agent starter). Owners: **Steve** (orchestrate) + **Page** (draft) with Renee contributing QA/inventory ritual language. | After FW-4 doc sweep (so rituals match shipped process); can run parallel with FW-5 finalize |

**Default sequencing:** **Phase A branding** → **Phase B filters** → FW-1 → FW-2 → (FW-3a ∥ FW-3b ∥ **FW-3c** ∥ FW-4) → (FW-5 ∥ FW-6); ~~Phase F checklist payback~~ **landed 2026-07-18**. Details: [FINAL_WAVE_PLAN.md](FINAL_WAVE_PLAN.md). **FW-3c** may land before FW-1 when waves are stable enough to avoid churn; FW-6 should run after FW-4; parallel with FW-5 is OK.

### FW-5 — Manual E2E matrix (planned artifact)

**Automated inventory (landed):** [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) + [TEST_INVENTORY.md](TEST_INVENTORY.md) — unit/widget/bloc catalog; `evaluation_status=Cataloged` ≠ runtime Pass.

**Manual E2E matrix (finalized):** [`V1_MANUAL_E2E_MATRIX.csv`](V1_MANUAL_E2E_MATRIX.csv) — all rows Pass (operator sign-off 2026-07-22). Includes filter + branding + live-mail rows. Keep separate from the automated inventory.

**Coverage areas (as applicable to then-current product):**

- **Accounts** — Graph OAuth, Google OAuth, IMAP autoconfig, manual IMAP, edit/remove, wipe
- **Sync** — cold start offline, incremental catch-up, reconnect, job queue visibility (if landed)
- **Mailbox** — read/unread, star, move, archive, trash recover, permanent delete
- **Compose / send** — outbox queue, send failure surfaces, reply/forward prefill
- **Headers** — reading-pane headers sheet, raw block, provider fetch
- **Settings** — themes, density, retention (global + per-account if landed), tray/shortcuts (Windows)
- **Filters** — cross-cutting message filter system (Final wave Phase B — ephemeral + saved)
- **Retention** — global dial + per-account overrides (if landed); pin exemption
- **Junk** — report junk / not junk (landed W1)
- **Platform** — Android widget snapshot, emulator smoke; Windows keyboard shortcuts

Each row: ID, area, precondition, steps, expected result, Graph / IMAP / both, Windows / Android / both, pass/fail, notes.

### FW-6 — Multi-agent system prompt

**Artifact:** [`MULTI_AGENT_SYSTEM_PROMPT.md`](MULTI_AGENT_SYSTEM_PROMPT.md) — portable playbook (Phase E draft; review after FW-4 stabilizes).

**Must capture:**

- **Leadership trifecta + Tesla routing** — Steve orchestrates; Jules (UI/BLoC), Renee (QA), Page (docs); Tesla for sync/network/isolates/DB
- **Phase gates** — Discovery → Implementation → Quality → Documentation → Delivery
- **Wave-close ritual** — Renee test inventory delta → Page CSV/xlsx refresh → Steve land gate
- **Quality & hygiene** — `DEFECTS.md` logging, Gold Master file headers, zero-placeholder code policy
- **Execution policy** — human confirmation before mutating shell commands, build runners, and destructive file ops
- **Stack phrasing** — stack-agnostic core where possible; Synesis appendix for Flutter/Dart local-first, BLoC, and Isolates specifics

## Android emulator testing

Manual and automated validation on Android AVD complements the Windows-first dev loop. Not a feature — a **quality gate** for the v1 Android surface (widgets, secure storage, adaptive layout, background sync policy).

| Topic | Notes |
| --- | --- |
| **Setup** | Android Studio SDK + AVD (API 34+ recommended); `flutter doctor`; `flutter emulators` / `flutter run -d <emulator-id>`. |
| **What to exercise** | Cold start + offline mailbox; add-account flows; folder sidebar + list/detail navigation; compose → outbox → send; home-screen widget snapshot refresh after sync; theme/density on small vs unfolded landscape. |
| **Platform deltas vs Windows** | `flutter_secure_storage` Android options; no system tray; IMAP poll intervals more conservative (battery); WebView/HTML body rendering on mobile WebView; back-gesture vs desktop keyboard shortcuts. |
| **CI (optional)** | Headless emulator in CI is heavy; minimum bar is `flutter test` on host + periodic manual AVD pass; consider Firebase Test Lab or self-hosted emulator job for widget/integration smoke later. |
| **Accounts** | Use dedicated test Graph/IMAP accounts; avoid production mail on shared emulators; document creds in local-only env (never commit). |

## Encryption options (discussion)

Synesis layers encryption at different levels. Only **DB at-rest (opt-in)** is in near-term scope; message-level crypto is explicitly deferred.

| Layer | Status | Options / notes |
| --- | --- | --- |
| **In transit** | Baseline | TLS for IMAP/SMTP; HTTPS for Graph. System trust store; document pinning only if required. |
| **Secrets at rest** | Landed | OAuth tokens / passwords in `flutter_secure_storage` (not plain SQLite). |
| **Mail DB at rest** | Backlog (opt-in) | **SQLCipher** via Drift-compatible libs; passphrase UI + recovery warning. **Windows:** wrap key with DPAPI. **Android:** Keystore-backed key; weaker if user has no device lock. Alternative: rely on OS full-disk encryption only (weaker threat model). |
| **Attachment blobs** | Follows attachments | Store under app sandbox; optional extension: encrypt files with same DB key when SQLCipher enabled. |
| **E2E message (PGP / S/MIME)** | Post-v1 | High complexity (key management, compose UI, provider interop). Listed in Post-v1; do not conflate with DB encryption. |

**Recommendation:** Ship attachments + signatures first; run a short **encryption spike** (SQLCipher + Drift migration + unlock on startup) before marketing “encrypted mailbox” — default remains **unencrypted DB** per locked decision until user opts in.

## Risks / follow-ups

- **Live Graph OAuth dogfood** — code path landed; operator must register Entra app + redirect URIs ([README](../README.md#microsoft-graph-entra-setup)) and run with `SYNESIS_GRAPH_CLIENT_ID`
- Deeper IMAP IDLE and Graph change notifications
- Full Windows system tray native bindings beyond preference hooks
- End-to-end tests against real Graph/IMAP accounts
- Android emulator QA matrix — see dedicated section above
- SQLCipher / DB encryption spike (opt-in; depends on migration story)
- See [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md) for cross-tier consolidation and W0–W7 waves
- See **[UI_ENHANCEMENT_SWEEP.md](UI_ENHANCEMENT_SWEEP.md)** for polish backlog (add items in §6)
- See **Planned backlog (post-foundation)** above for attachments, signatures, layout, encryption, filters, retention, headers, and junk-mail features
- See **Final wave (V1 exit / release readiness)** above and **[FINAL_WAVE_PLAN.md](FINAL_WAVE_PLAN.md)** for branding, filter system, refactor, coverage, user docs, doc sweep, manual E2E matrix, and multi-agent playbook
