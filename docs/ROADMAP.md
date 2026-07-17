# ByteMail V1 Roadmap

| Field | Value |
| --- | --- |
| Status | Active — foundation implemented |
| Spec | [SPEC.md](SPEC.md) v1.4 |
| Exit checklist | [V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md) |
| Product | ByteMail |
| Platforms (v1) | Windows, Android |
| Last updated | 2026-07-17 (W5 landed; W6 unlocked; `.eml` ProgId deferred packaging) |

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

Horizon backlog with promotion framework (V1.1 → V2 → enterprise). **Planning complete — decisions locked.**

### Locked Tier D decisions (2026-07-16)

| # | Decision |
| --- | --- |
| 1 | **V1.1 = D6 only** (no shared mailbox in first post-V1 bundle) |
| 2 | **V2 headline = PIM** (contacts & calendar) |
| 3 | **Enterprise SKU** — separate track (crypto + shared mail + S/MIME) |
| 4 | **PST import** after V1.1 unless migration is acquisition channel |
| 5 | **Galaxy Watch** — lightweight V2 companion (triage, not full client) |

### Confirmed post-V1 (from V1 + Tier D)

- Unlimited multi-window desktop (V1: single detached window only) → **V1.1 candidate**
- Per-account remote image block + domain whitelist (V1: global toggle) → **V1.1 candidate**
- Auto-mark read dwell / disable settings (V1: fixed 5s, default ON — [UI-P28](UI_ENHANCEMENT_SWEEP.md)) → **V1.1 candidate**

### Tier D themes (default disposition)

| Theme | Examples | Target |
| --- | --- | --- |
| **D6 V1.1 adjacency** | Multi-window+, image whitelist, Graph large attachments, PDF export | V1.1 triage after W7 |
| **D1 PIM** | Contacts, calendar, meeting invites | V2 |
| **D2 Crypto** | OpenPGP, S/MIME | Enterprise |
| **D3 Legacy** | PST/MSG import, POP3, shared mailboxes, EAS | Selective / V1.2+ |
| **D4 Collab & AI** | Cloud AI (non-goal), on-device ML Focus, team inboxes | Low / V2+ |
| **D5 Platforms** | iOS, macOS, Linux after PIM; **Galaxy Watch V2** | Platform roadmap |
| **D7 Power depth** | JMAP, server rules, unsubscribe helper, Graph webhooks, editable keyboard shortcuts | Cherry-pick |

### Maybe / Someday ([TIER_D_PLAN.md §16](TIER_D_PLAN.md#16-maybe--someday-unplanned-backlog))

Explicitly considered; **unplanned** — on radar to avoid re-debate. Includes: cloud AI, newsletter builder, consumer mail merge, team collab (co-edit/read receipts), EAS/on-prem, mail hosting, cloud Focus ranking, Windows shell widgets.

Full item catalog: [TIER_D_PLAN.md](TIER_D_PLAN.md).

### Legacy post-v1 list (SPEC §12)

- Full contacts & calendar (see Tier D TD-A)
- POP3, iOS/macOS/Linux, ML Focus, PGP/S/MIME
- ~~Interactive Entra OAuth~~ — in V1 W0

## V1 integration — single delivery ([review](V1_TIER_INTEGRATION.md))

**Locked wave order (2026-07-16):** ~~W0~~ **W0 landed** → ~~W1~~ **W1 landed** → ~~W2~~ **W2 landed** → ~~W3~~ **W3 landed** → ~~W5~~ **W5 landed** → W6 → **W4 (last)** → W7

| Wave | Name | Status | Absorbs |
| --- | --- | --- | --- |
| **W0** | Platform base + Graph OAuth priority | **Landed** (2026-07-16) | TA-0, TB-0 schema, TC-0, TA-5, TC-8 shell |
| **W1** | Message actions + trash | **Landed** (2026-07-17) | TA-1, TA-4 (trash recover + auto-purge default 30d) |
| **W2** | List & navigation UX | **Landed** (2026-07-17) | TB-1, TB-2, TB-4, TB-5, TB-7, TB-11, TB-14, **[UI sweep W2](UI_ENHANCEMENT_SWEEP.md)** |
| **W3** | Sync, storage & privacy | **Landed** (2026-07-17) | TC-1, TC-2, TB-10, TC-5/12, TC-6 phase 1 |
| **W5** | Desktop shell | **Landed** (2026-07-17) | TB-9, TC-9 (detached window), **[UI sweep W5](UI_ENHANCEMENT_SWEEP.md)**, [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) |
| **W6** | Notifications | **Planned** (unlocked) | TA-6, TC-7 |
| **W4** | Compose system (**last feature wave**) | Planned | TA-2, TA-3, TB-6, TB-12, TB-13, TC-10, **UI-P19/P20** (outbound font, sig images) |
| **W7** | Hardening & optional | Planned | TC-3, TC-4, TC-11, QA matrix, **[UI sweep W7](UI_ENHANCEMENT_SWEEP.md)** |

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
- **Detached message window** — `WindowsDetachedMessageWindowController` + overflow **Open in new window** (V1 single-window retarget)
- **Manual checklist** — [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) passed (operator); Windows `.eml` Explorer ProgId **deferred** (packaging follow-up)

**Critical path:** **W0 landed** → **W1 landed** → **W2 landed** → **W3 landed** → **W5 landed** → **W6** → **W4** → W7. Live Graph OAuth dogfood is an operator checkpoint (Entra registration), not a W6 code blocker.  
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
| **Pri-2** | [DEF-007](DEFECTS.md) read-state sync flicker | Open | W2/W3 |
| **Pri-3** | Density/spacing pass | Open | **W7** |
| **Pri-3** | Empty states, loading skeletons, widget themes | Open | **W7** |
| **Pri-2** | Custom themes (multiple, fork built-ins) | Planned | **W7** | [UI-P16](UI_ENHANCEMENT_SWEEP.md) |
| **Pri-2** | Export / import settings (no secrets) | Planned | **W7** | [UI-P17](UI_ENHANCEMENT_SWEEP.md) |
| **Pri-2** | App-wide UI font (family, size, color) | Planned | **W7** | [UI-P18](UI_ENHANCEMENT_SWEEP.md) |
| **Pri-2** | Outbound message font | Planned | **W4** | [UI-P19](UI_ENHANCEMENT_SWEEP.md) |
| **Pri-2** | Signature images (HTML) | Planned | **W4** | [UI-P20](UI_ENHANCEMENT_SWEEP.md) |
| **Pri-2** | [DEF-034](DEFECTS.md) / UI-P27 auto-mark read (5s default ON) | Open | **W7** (V1 scope; **not W5 blocker**) |

Full inventory + backlog template: **[UI_ENHANCEMENT_SWEEP.md](UI_ENHANCEMENT_SWEEP.md)**.

## Tier A — table stakes ([plan](TIER_A_PLAN.md))

Competitive gap closure per [COMPETITIVE_ANALYSIS.md](COMPETITIVE_ANALYSIS.md). **W0 foundations + OAuth landed 2026-07-16; W1 message actions landed 2026-07-17; W2 list UX landed 2026-07-17; W3 sync landed 2026-07-17; W5 desktop shell landed 2026-07-17.**

| Phase | Milestone | Status | Depends on | Exit highlight |
| --- | --- | --- | --- | --- |
| **TA-0** | Foundations | **Landed** (2026-07-16) | — | Schema v5, `MailProvider` mutations, MIME isolate bootstrap |
| **TA-1** | Core message actions | **Landed** (2026-07-17, W1) | TA-0 | Reply, forward, delete, archive, move, star, trash recover + auto-purge wired |
| **TA-2** | Compose envelope | Planned (W4) | TA-0, TA-1 | CC/BCC, quote, signatures, quick reply |
| **TA-3** | Attachments | Planned (W4) | TA-0, TA-2 | View, download, compose attach, MIME send |
| **TA-4** | Junk mail | **Landed** (2026-07-17, W1) | TA-1 | Report junk / not junk via folder move |
| **TA-5** | Browser OAuth | **Landed in code** (2026-07-16) | TA-0 | Entra + Google PKCE; live Graph E2E = operator Entra registration |
| **TA-6** | Notifications | Planned (W6) | TA-0 | Android + Windows new-mail alerts |

**Implementation order:** [V1 waves W0–W7](V1_TIER_INTEGRATION.md) — not isolated tier phases.

**Locked decisions:** [TIER_A_PLAN.md §16](TIER_A_PLAN.md#16-locked-decisions-2026-07-16).

## Tier B — competitive parity ([plan](TIER_B_PLAN.md))

**Planning complete** — **TB-0 MessageQuery foundations landed in W0** (2026-07-16); **TB-1, TB-2, TB-4, TB-5, TB-7, TB-11, TB-14 landed in W2** (2026-07-17); **TB-10 push landed in W3** (2026-07-17); **TB-9 layout landed in W5** (2026-07-17). Remaining Tier B phases scheduled in W4.

| Phase | Milestone | Status | Depends on | Exit highlight |
| --- | --- | --- | --- | --- |
| **TB-0** | MessageQuery foundations | **Landed** (W0) | TA-0 / W0 | Single list pipeline + schema v5 query columns |
| **TB-1** | Conversation threading | **Landed** (2026-07-17, W2) | TB-0 | Thread groups + flat toggle (default threaded) |
| **TB-2** | Filters + date grouping | **Landed** (2026-07-17, W2) | TB-0 | `MessageViewFilter` + Today/Yesterday sections |
| **TB-4** | Snooze | **Landed** (2026-07-17, W2) | TB-0 | Local-only `snoozed_until`; query exclusion |
| **TB-5** | Pin UI | **Landed** (2026-07-17, W2) | TB-0 | Local pin; retention-exempt; virtual view |
| **TB-6** | Drafts | Planned (W4) | TA-2 | Autosave + Drafts folder sync |
| **TB-7** | Mobile gestures | **Landed** (2026-07-17, W2) | TA-1 | Swipe right=archive / left=delete; pull-to-refresh; AVD checklist |
| **TB-9** | Layout + Visual Focus | **Landed** (2026-07-17, W5) | — | Right/top/bottom + Visual Focus; checklist passed; draggable split deferred; `.eml` ProgId deferred (packaging) |
| **TB-10** | Push sync | **Landed** (2026-07-17, W3) | — | IMAP IDLE + Graph delta; network policy |
| **TB-11** | Starred view | **Landed** (2026-07-17, W2) | TB-0, TA-1 | Virtual starred folder |
| **TB-12** | Rich text compose | Planned (W4) | TA-2 | HTML compose + send |
| **TB-13** | Templates | Planned (W4) | TA-2 | Canned responses |
| **TB-14** | List polish | **Landed** (2026-07-17, W2) | — | Read dimming, pull-to-refresh, selection highlight |

## Tier C — differentiation ([plan](TIER_C_PLAN.md))

**Planning complete** — **TC-8 autoconfig landed in W0** (2026-07-16); **TC-1, TC-2, TC-5, TC-6 phase 1, TC-12 landed in W3** (2026-07-17); **TC-9 desktop power pack landed in W5** (2026-07-17). Remaining Tier C phases scheduled in W4, W6–W7.

| Phase | Milestone | Status | Exit highlight |
| --- | --- | --- | --- |
| **TC-0** | Settings + profile schema | **Partial (W0)** | `sync_profiles`, account overrides — schema v5 tables |
| **TC-1** | Sync profiles + per-account retention | **Landed** (2026-07-17, W3) | Full SPEC §8.2 — profiles, folder scope, body policy, attachment cap |
| **TC-2** | Network-aware sync | **Landed** (2026-07-17, W3) | WiFi vs mobile poll/IDLE; `pushOnCellular` default off |
| **TC-3** | DB encryption | Planned (W7) | SQLCipher opt-in |
| **TC-4** | Focus override UI | Planned (W7) | Domain/sender rules editor |
| **TC-5** | Sync transparency | **Landed** (2026-07-17, W3) | Job queue viewer + account health (merged TC-12) |
| **TC-6** | HTML privacy | **Phase 1 landed** (2026-07-17, W3) | Block remote images; per-message load; phase 2 post-v1 |
| **TC-7** | Notification granularity | Planned (W6) | Per-account mute, quiet hours |
| **TC-8** | IMAP autoconfig | **Landed (W0)** | ISPDB / domain well-known discovery |
| **TC-9** | Desktop power pack | **Landed** (2026-07-17, W5) | Keymap/tray/find/print/EML/detach UI landed; checklist passed; `.eml` ProgId deferred (packaging) |
| **TC-10** | Schedule send | Planned (W4) | Outbox `send_after` — column in schema v5; UI in W4 |
| **TC-11** | Widget depth | Planned (W7) | Folder-scoped + theme variants |
| **TC-12** | Account health panel | **Landed** (2026-07-17, W3) | Merged into sync status sheet |

## Tier D — horizon ([plan](TIER_D_PLAN.md))

**Planning complete** — post-V1; promotion into V1.1/V2 via [TIER_D_PLAN.md §2](TIER_D_PLAN.md#2-promotion-framework).

| Track | Examples | Default |
| --- | --- | --- |
| **V1.1 (D6)** | Multi-window+, image whitelist, large Graph attachments | First post-V1 bundle |
| **V2 (TD-A/E)** | Contacts, calendar, iOS | Major version |
| **Enterprise (TD-B/C)** | PGP/S/MIME, shared mailboxes, PST | Separate track |
| **Defer** | Maybe/Someday (§16), cloud AI, newsletter, mail merge | Unplanned radar |

**Locked:** V1.1 = D6 only · V2 = PIM · Enterprise SKU yes · Galaxy Watch V2 lightweight.

## Planned backlog (post-foundation)

Feature work captured for scheduling — **not implemented**. Requirements baseline in [SPEC.md](SPEC.md); this table tracks intent and likely scope only.

| Pri | Item | Status / notes |
| --- | --- | --- |
| **Pri-1** | **Edit and remove accounts** | **Landed (2026-07-14).** `ManageAccountsSheet` in Appearance settings; `EditAccountSheet` (label/accent/re-auth); `RemoveAccountDialog` with typed `WIPE {accountId}` gate. `AccountService` orchestrates metadata updates, credential rotation, and secure wipe (`DriftMailRepository.wipeAccount` + `SecureCredentialStore.deleteCredentials`). Post-remove: `MailboxCubit.onAccountRemoved`, `AppSettingsCubit.removeAccountFocus`, `WidgetSnapshotService.refreshAll()`. |
| **Pri-1** | **Cross-cutting message filter system** | **Not started.** User-defined view filters on the current folder/unified list — distinct from optional Focused/Other ([SPEC §8.3](SPEC.md#83-dual-layer-focus-mode-optional)) and from ephemeral FTS search ([SPEC §8.1](SPEC.md#81-tiered-search)). **Predicates:** read / unread; sender; recipient (to/cc); date range; keywords. **Nice-to-have / views:** Outlook-style date buckets as list groupings *or* view filters — Today, Yesterday, This week, Last week, This month, Last month, Older. **Likely architecture:** extend `MailboxState` + `MailboxCubit` with a composable `MessageFilter` (or equivalent) passed to `MailRepository.listMessages`; structured predicates (flags, addresses, `whenEpochMs` bounds) as Drift/SQL `WHERE` clauses; keyword leg may delegate to existing FTS5 path when free-text dominates, otherwise SQL `LIKE`/indexed columns for simple subject/from matches. Date buckets: implement as **UI section headers** over date-sorted rows (group-by in Cubit) *or* as **filter predicates** (mutually exclusive modes — product to pick default). Composes with existing `focusFilter` when Focus is enabled (both apply). Read/unread *filter* is separate from mark-read/unread actions (UI enhancement sweep). No SPEC section yet — add when scheduled. |
| **Pri-3** | **Header details view** | **Landed.** Reading-pane **Headers** action opens a bottom sheet with parsed fields (From, To/Cc when present in raw block, Subject, Date, Message-ID, account/folder) plus a scrollable monospace raw header block. Local-first from `messages.raw_headers`; on-demand provider fetch via `MailProvider.fetchHeaders` (Graph `internetMessageHeaders`, IMAP `BODY.PEEK[HEADER]`) with optional SQLite cache (schema v4). |
| **Pri-2** | **Per-account retention settings** | **Landed (2026-07-17, W3).** Per-account retention override + sync profile assignment in `EditAccountSheet`; device-wide retention dial updates default sync profile and enqueues cleanup. See [SPEC §8.2](SPEC.md#82-variable-retention-dials--sync-profiles). |
| **Pri-2** | **Junk mail filter** | **Landed (2026-07-17, W1 / TA-4).** Report junk / not junk via role-folder move; context-aware reading-pane when viewing junk. Distinct from optional Focus heuristics and from the cross-cutting message filter system (junk is folder/provider semantics). Optional client rules layer still deferred. |
| **Pri-1** | **Attachments (receive, view, compose)** | **Not started.** `hasAttachments` flag syncs today; no attachment metadata table, MIME fetch, storage, or UI. [SPEC §5.3](SPEC.md#53-body-and-attachment-strategy): fetch on demand; respect sync-profile max size; offline compose may queue local blobs. **Likely scope:** `attachments` table (messageId, partId, filename, mime, size, localPath, fetchedAt); `MailProvider.fetchAttachments` / `fetchAttachmentPart` (Graph `$value` / IMAP `BODY.PEEK[]`); isolate MIME parse/serialize; reading-pane attachment strip + preview/download; compose attach picker → outbox blob refs; retention prune with bodies. **Sequencing:** after stable body-on-open path (landed) and before heavy compose polish. |
| **Pri-2** | **Per-account signatures** | **Not started.** Multiple named signatures per account; per-account default (or none). Apply on compose/reply/quick-reply; user can override per message. **Likely scope:** `account_signatures` table or JSON in account settings; rich-text or plain + optional inline images deferred; settings UI in account edit sheet; compose signature picker + “none” option. Distinct from [SPEC §7.6](SPEC.md#76-windows-desktop-power-features) “templates / canned responses” (full message bodies) — signatures are trailing blocks appended to outgoing mail. |
| **Pri-2** | **Desktop reading-pane layout (Outlook-style)** | **Landed (2026-07-17, W5).** `MailSplitLayout` + persisted `readingPanePosition` (right/top/bottom). Visual Focus collapse landed. Ctrl+F find, print/save EML, detached window wired. [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) passed (operator). Draggable split divider deferred (TB-9.1). Windows `.eml` Explorer ProgId deferred (packaging). |
| **Pri-3** | **Optional encryption at rest (desktop DB)** | **Not started / decision doc.** Locked: opt-in ([§11 open question #4](SPEC.md#111-assumptions-baked-into-this-draft)). **In scope for v1.x:** SQLCipher (or Drift + `sqlcipher_flutter_libs`) wrapping the mail SQLite file; passphrase or OS keychain-derived key (Windows DPAPI). **Explicitly post-v1:** PGP/S/MIME message encryption ([Post-v1](#post-v1-not-scheduled)). TLS for IMAP/SMTP/Graph is baseline, not this item. |
| **Pri-3** | **Android emulator & device QA matrix** | **Not started.** Establish repeatable manual + CI smoke path on Android AVD alongside Windows. See [Android testing notes](#android-emulator-testing) below. |

**Suggested sequencing:** account edit/remove (Pri-1, landed) → header details (Pri-3, landed) → junk filter (Pri-2, landed W1) → per-account retention (Pri-2, landed W3) → **attachments (Pri-1)** → message filter system (Pri-1) → signatures (Pri-2) → desktop reading-pane layout (Pri-2). Encryption at rest is an architecture spike that can run in parallel once DB migration story is clear; Android emulator QA should start early for widget + secure-storage validation.

## Final wave (V1 exit / release readiness)

**Status:** Planned — **not started.** No implementation in this wave until all feature waves (W2–W7) and remaining **Planned backlog** Pri items above are landed or explicitly deferred for v1.

This is the last gate before v1 ship. It contains **no new product features** except fixes for debt uncovered during the refactoring pass. Track exit criteria in **[V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md)**; this section defines the work order to get there.

### Position relative to remaining backlog

| Backlog item | Status | Final wave relationship |
| --- | --- | --- |
| **Cross-cutting message filter system** (Pri-1) | Not started | Must land (or be deferred with SPEC note) **before** Final wave — E2E matrix includes filter scenarios when shipped |
| **Per-account retention** (Pri-2) | **Landed** (W3) | Already in product; E2E matrix includes retention when shipped |
| **Junk mail filter** (Pri-2 / TA-4) | **Landed** (W1) | Already in product; E2E matrix covers report junk / not junk |
| Attachments, signatures, layout, encryption | Mixed | Feature waves W2–W7 + backlog sequencing first; Final wave only polishes what shipped |

**Critical path to v1:** ~~W2~~ **W2 landed** → ~~W3~~ **W3 landed** → ~~W5~~ **W5 landed** → W6 → **W4** → W7 → remaining **Planned backlog** Pri items → **Final wave** → [V1 exit checklist](V1_EXIT_CHECKLIST.md) sign-off.

### Suggested order within the wave

| Step | Item | Scope | Notes |
| --- | --- | --- | --- |
| **FW-1** | Last refactoring pass | Polish and cleanup after feature landings; rename dead code, tighten APIs, align patterns with AGENTS.md; fix debt found in pass only — **no new product features** | Runs after W7 + backlog; unblocks stable coverage baselines |
| **FW-2** | Verify test code coverage | Measure (`flutter test --coverage` → `lcov` / IDE report); map gaps; raise floor on **critical paths**: sync engine, accounts/onboarding, `MailboxCubit`, Graph + IMAP providers | Target thresholds TBD after first measurement; block release on critical-path regressions |
| **FW-3a** | User documentation — comprehensive guide | End-user guide: accounts, folders, compose, search, Focus, settings, wipe, platform differences (Windows vs Android) | Can run **in parallel** with FW-3b and FW-4 |
| **FW-3b** | User documentation — quick start | Short “experienced user” path: install → add account → read/send → one settings tip; anti-TL;DR for users who skip long docs | Separate doc from FW-3a; cross-link both ways |
| **FW-4** | Final documentation update sweep | Align [SPEC.md](SPEC.md), this ROADMAP, [ARCHITECTURE_OVERVIEW.md](ARCHITECTURE_OVERVIEW.md), [README.md](../README.md), [DEFECTS.md](DEFECTS.md), and [V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md) with **shipped reality**; close or re-scope stale items | Parallel with FW-3a/3b; feeds checklist sign-off |
| **FW-5** | Comprehensive manual E2E test matrix | Recommended manual tests in **versionable spreadsheet form** — e.g. `docs/V1_MANUAL_E2E_MATRIX.csv` (importable into Excel / Google Sheets). **Automated** coverage is already cataloged in [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) — see [TEST_INVENTORY.md](TEST_INVENTORY.md) | **Last** as formal gate, or start earlier as a **living checklist** during W7/backlog QA and finalize here |
| **FW-6** | Reusable multi-agent system prompt / playbook | Distill Steve→Jules→Renee→Page→Tesla phase-gate workflow, wave-close rituals (test inventory handoff, DEFECTS, Gold Master headers, local-first/BLoC/Isolates stack rules), and Cursor agent roster into a **portable system prompt** suitable for seeding future projects (not ByteMail-specific product rules only — generalize rituals). Suggested artifact: `docs/MULTI_AGENT_SYSTEM_PROMPT.md` (and optionally a trimmed `.cursor`/Copilot agent starter). Owners: **Steve** (orchestrate) + **Page** (draft) with Renee contributing QA/inventory ritual language. | After FW-4 doc sweep (so rituals match shipped process); can run parallel with FW-5 finalize |

**Default sequencing:** FW-1 → FW-2 → (FW-3a ∥ FW-3b ∥ FW-4) → (FW-5 ∥ FW-6). FW-6 should run after FW-4; parallel with FW-5 is OK.

### FW-5 — Manual E2E matrix (planned artifact)

**Automated inventory (landed):** [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) + [TEST_INVENTORY.md](TEST_INVENTORY.md) — unit/widget/bloc catalog; `evaluation_status=Cataloged` ≠ runtime Pass.

**Manual E2E matrix (not created yet):** When scheduled, prefer `docs/V1_MANUAL_E2E_MATRIX.csv` under `docs/` so rows stay diffable in git. Import into Excel or Google Sheets for operator runs. Keep separate from the automated inventory.

**Coverage areas (as applicable to then-current product):**

- **Accounts** — Graph OAuth, Google OAuth, IMAP autoconfig, manual IMAP, edit/remove, wipe
- **Sync** — cold start offline, incremental catch-up, reconnect, job queue visibility (if landed)
- **Mailbox** — read/unread, star, move, archive, trash recover, permanent delete
- **Compose / send** — outbox queue, send failure surfaces, reply/forward prefill
- **Headers** — reading-pane headers sheet, raw block, provider fetch
- **Settings** — themes, density, retention (global + per-account if landed), tray/shortcuts (Windows)
- **Filters** — cross-cutting message filter system (if landed by FW-5)
- **Retention** — global dial + per-account overrides (if landed); pin exemption
- **Junk** — report junk / not junk (landed W1)
- **Platform** — Android widget snapshot, emulator smoke; Windows keyboard shortcuts

Each row: ID, area, precondition, steps, expected result, Graph / IMAP / both, Windows / Android / both, pass/fail, notes.

### FW-6 — Multi-agent system prompt (planned)

**Artifact (not created yet):** `docs/MULTI_AGENT_SYSTEM_PROMPT.md` — portable playbook for seeding future projects; optionally a trimmed `.cursor`/Copilot agent starter.

**Must capture:**

- **Leadership trifecta + Tesla routing** — Steve orchestrates; Jules (UI/BLoC), Renee (QA), Page (docs); Tesla for sync/network/isolates/DB
- **Phase gates** — Discovery → Implementation → Quality → Documentation → Delivery
- **Wave-close ritual** — Renee test inventory delta → Page CSV/xlsx refresh → Steve land gate
- **Quality & hygiene** — `DEFECTS.md` logging, Gold Master file headers, zero-placeholder code policy
- **Execution policy** — human confirmation before mutating shell commands, build runners, and destructive file ops
- **Stack phrasing** — stack-agnostic core where possible; ByteMail appendix for Flutter/Dart local-first, BLoC, and Isolates specifics

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

ByteMail layers encryption at different levels. Only **DB at-rest (opt-in)** is in near-term scope; message-level crypto is explicitly deferred.

| Layer | Status | Options / notes |
| --- | --- | --- |
| **In transit** | Baseline | TLS for IMAP/SMTP; HTTPS for Graph. System trust store; document pinning only if required. |
| **Secrets at rest** | Landed | OAuth tokens / passwords in `flutter_secure_storage` (not plain SQLite). |
| **Mail DB at rest** | Backlog (opt-in) | **SQLCipher** via Drift-compatible libs; passphrase UI + recovery warning. **Windows:** wrap key with DPAPI. **Android:** Keystore-backed key; weaker if user has no device lock. Alternative: rely on OS full-disk encryption only (weaker threat model). |
| **Attachment blobs** | Follows attachments | Store under app sandbox; optional extension: encrypt files with same DB key when SQLCipher enabled. |
| **E2E message (PGP / S/MIME)** | Post-v1 | High complexity (key management, compose UI, provider interop). Listed in Post-v1; do not conflate with DB encryption. |

**Recommendation:** Ship attachments + signatures first; run a short **encryption spike** (SQLCipher + Drift migration + unlock on startup) before marketing “encrypted mailbox” — default remains **unencrypted DB** per locked decision until user opts in.

## Risks / follow-ups

- **Live Graph OAuth dogfood** — code path landed; operator must register Entra app + redirect URIs ([README](../README.md#microsoft-graph-entra-setup)) and run with `BYTEMAIL_GRAPH_CLIENT_ID`
- Deeper IMAP IDLE and Graph change notifications
- Full Windows system tray native bindings beyond preference hooks
- End-to-end tests against real Graph/IMAP accounts
- Android emulator QA matrix — see dedicated section above
- SQLCipher / DB encryption spike (opt-in; depends on migration story)
- See [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md) for cross-tier consolidation and W0–W7 waves
- See **[UI_ENHANCEMENT_SWEEP.md](UI_ENHANCEMENT_SWEEP.md)** for polish backlog (add items in §6)
- See **Planned backlog (post-foundation)** above for attachments, signatures, layout, encryption, filters, retention, headers, and junk-mail features
- See **Final wave (V1 exit / release readiness)** above for pre-ship refactor, coverage, user docs, doc sweep, and manual E2E matrix
