# Synesis V1.5 Plan — Post-V1 Adjacency Bundle

| Field | Value |
| --- | --- |
| Status | **V1.5 complete** (2026-07-27) — Waves A–F + dogfood UI; `flutter test` 499 passed |
| Supersedes | Former “V1.1 = D6 only” first post-V1 bundle |
| Prerequisite | V1 exit signed off (2026-07-22) |
| Next major | **V2** = PIM (contacts & calendar) — unchanged |
| Owners | Steve (orchestrate) · Jules / Tesla (impl) · Renee (QA) · Page (docs) |
| Last updated | 2026-07-27 |

## 1. Why V1.5 (not V1.1)

Operator triage (2026-07-22) promoted the first post-V1 ship from a thin **V1.1 D6-only** patch to a **V1.5 adjacency bundle**: all items previously tagged **V1.1 or V1.2** under D6, plus dogfood UI that was blocking daily use. Rationale: dogfood friction + Graph large-attachment frequency make a second thin release (V1.1 then V1.2) less useful than one cohesive mail-polish release before PIM.

**Still locked out of V1.5:** shared mailbox, PST import, PGP/S/MIME, PIM, cloud AI, new phone OS.

## 2. Locked decisions (2026-07-22)

| # | Decision |
| --- | --- |
| 1 | First post-V1 product ship = **V1.5** (not a separate V1.1 + V1.2 pair) |
| 2 | **D6-3 Graph large attachment upload** is **in** — operator hits the cap often |
| 3 | Scope = former **V1.1 + V1.2 D6** tags + named dogfood UI (§3) |
| 4 | No shared mailbox / enterprise crypto / PIM in V1.5 |
| 5 | PST import remains **after V1.5** unless migration becomes acquisition channel |
| 6 | V2 headline remains **PIM** |

## 3. Scope table

### 3.1 D6 adjacency (all former V1.1 + V1.2)

| ID | Feature | Est. | Priority in V1.5 |
| --- | --- | --- | --- |
| **D6-3** | **Graph large attachment upload session** | 1–2 wk | **Must** (operator) |
| D6-1 | Unlimited multi-window desktop | 1–2 wk | Must |
| D6-2 | Per-account image block + domain whitelist | ~1 wk | Must |
| D6-6 | Save as PDF (in addition to EML) | 3–5 d | Must |
| D6-4 | Template variables (`{{name}}`, etc.) | 3–5 d | Must (ex-V1.2) |
| D6-5 | Server-side snooze | 1–2 wk | Must (ex-V1.2) |
| D6-7 | Advanced tracker blocking | ~1 wk | Must (ex-V1.2) |
| D6-8 | Windows toast actions (archive/delete) | ~1 wk | Must (ex-V1.2) |

### 3.2 Dogfood / UI (from V1.1 triage)

| ID | Feature | Est. | Priority in V1.5 |
| --- | --- | --- | --- |
| **UI-P30** | Hold / pause auto-mark for in-view message | S–M | **Must** (Pri-1 dogfood) |
| **UI-P28** | Auto-mark settings (delay / off) | S | Must (ships with P30) |
| **UI-P29** | One-click clear active filters | XS | Must |
| **UI-P21** | Settings organized by functional area | M | Must |
| UI-P22 | Search results show message datetime | S | Should |
| UI-P23 | Folder context menu: mark all read/unread | S | Should |
| UI-P25 | Discoverable per-message multi-select | S | Could → defer if schedule slips |

### 3.3 Explicitly out of V1.5

| Item | Disposition |
| --- | --- |
| Shared mailboxes | Enterprise / later |
| PST / MSG import | After V1.5 (locked) |
| OpenPGP / S/MIME | Enterprise SKU |
| Contacts / calendar (PIM) | **V2** |
| Galaxy Watch / iOS / macOS / Linux | V2 / V2+ |
| Perf test suite, Android focus track, health dashboard | Parallel tooling — not product gate |
| UI-P24 Ctrl+A, UI-P26 remote Seen | Bugfix if broken in dogfood; not scheduled as V1.5 features |

## 4. Suggested wave order (implementation)

Rough order to minimize thrash (not a hard gate until kickoff):

```text
Wave A  Dogfood UX     ── UI-P30 + UI-P28 + UI-P29
Wave B  Settings IA    ── UI-P21 (+ UI-P22/P23 if cheap in-pass)
Wave C  Graph attach   ── D6-3 (must; Tesla-led)
Wave D  Desktop power  ── D6-1 multi-window · D6-6 PDF · D6-8 toast actions
Wave E  Privacy read   ── D6-2 image whitelist · D6-7 tracker blocking
Wave F  Compose depth  ── D6-4 template vars · D6-5 server snooze
         → V1.5 exit checklist + regression on V1 E2E matrix
```

**Ballpark:** ~6–10 weeks calendar if sequential; Waves A–C can overlap early with B.

**Wave A status (2026-07-22):** UI-P28, UI-P29, and UI-P30 landed in code (Jules).
See [UI_ENHANCEMENT_SWEEP.md](UI_ENHANCEMENT_SWEEP.md) for per-item acceptance
detail and status. Renee QA pass / targeted tests still pending before Wave A
is marked fully closed.

**Wave B status (2026-07-23):** UI-P21, UI-P22, and UI-P23 landed in code (Jules).
The old single-scroll `appearance_sheet.dart` is replaced by a sectioned
`SettingsShell` (`lib/ui/settings/settings_shell.dart`) with adaptive
NavigationRail/drill-down nav and a searchable catalog; search results now
show a `whenLabel` datetime; folder sidebar rows support right-click/long-press
"Mark all as read/unread" without opening the folder first. See
[UI_ENHANCEMENT_SWEEP.md](UI_ENHANCEMENT_SWEEP.md) for per-item acceptance
detail. Renee QA pass / full `flutter test` run still pending before Wave B is
marked fully closed.

**Wave C status (2026-07-23):** D6-3 landed in code (Tesla).
`GraphMailProvider.sendEnvelope` now branches on a new
`kGraphInlineAttachmentMaxBytes` (3 MiB) per-file threshold in
`lib/protocol/graph_mail_provider.dart`: attachments at or under the
threshold still go out as a single `POST /me/sendMail` with inline
base64 `contentBytes` (unchanged); once any attachment exceeds it, every
attachment for that send uses the upload-session path — `POST /me/messages`
draft (no attachments inline) → per-file `POST .../attachments/createUploadSession`
→ chunked `PUT` to the returned `uploadUrl` with `Content-Range` headers
(`kGraphUploadChunkSizeBytes` = 3,276,800 B chunks) → `POST .../send`. If the
upload session or send fails after the draft exists, the draft is
best-effort `DELETE`d so it doesn't leak into Drafts/Sent. The sync-profile
`attachmentMaxMb` cap in `compose_sheet.dart` is unchanged and remains the
absolute user-facing ceiling; Graph can now honor cap values well above the
old inline practical limit. `ImapSmtpMailProvider` send path is untouched.
New coverage: `test/graph_mail_provider_upload_session_test.dart` (small
inline path, large upload-session path, best-effort draft cleanup on
failure). Renee QA pass / full `flutter test` run still pending before Wave C
is marked fully closed.

**Wave D status (2026-07-23):** D6-1, D6-6, and D6-8 landed in code (Jules).

- **D6-1 Unlimited multi-window desktop** — `WindowsDetachedMessageWindowController`
  (`lib/desktop/detached_message_window_controller.dart`) no longer retargets
  a single shared window; every distinct message id gets its own
  `WindowController.create`, so any number of detached readers can stay open
  concurrently. Nice-to-have polish: if the same message id is already open,
  that window is brought to front (via its stable, native-truth `arguments`
  payload) instead of spawning a duplicate. `DetachedMessageApp` is
  unchanged — still `allowOpenInNewWindow: false` with the Noop controller,
  so a detached window cannot itself spawn further detached windows
  ([DEF-029](DEFECTS.md) HTML fallback stays in effect there).
- **D6-6 Save as PDF** — `saveMessageAsPdf` (`lib/desktop/message_print_service.dart`)
  mirrors `saveMessageAsEml`: builds PDF bytes via the existing
  `buildMessagePdf` and hands them to `FilePicker.saveFile` with a `.pdf`
  extension. Reading-pane overflow menu now shows **Save as PDF** directly
  below **Save as EML**, wired to a `_savePdf` handler that mirrors
  `_saveEml`'s cancel/success/error snackbars.
  `test/reading_pane_actions_test.dart` asserts the new menu item is present.
- **D6-8 Windows toast actions (archive/delete)** — stays on `local_notifier`
  ([DEF-037](DEFECTS.md); Android untouched, still `flutter_local_notifications`).
  `NotificationPlatform.showNewMail` grew two optional parameters —
  `messageId` and a `NewMailToastActions` DTO (`onArchive`/`onDelete`
  callbacks) — populated by `NotificationService` only for **single-message**
  toasts; aggregated multi-message toasts stay body-only, matching the
  acceptance note. `WindowsNotificationAdapter` renders Archive/Delete as
  `LocalNotificationAction` buttons and maps `onClickAction`'s index back to
  the right callback. `AndroidNotificationAdapter` accepts and ignores the
  new parameters (still title/body only — no Android behavior change).
  `MessageActionService` gained ID-targeted `archiveMessageById` /
  `deleteMessageById` helpers (resolve the message from the repository, move
  it to the account's archive/trash folder, enqueue the same remote sync job
  the in-app paths use) for callers — namely the toast click handler in
  `main.dart` — that have no live `MailboxState` snapshot to work from.
  `main.dart` wires a dedicated `MessageActionService` instance (sharing the
  same repository/provider-resolver/sync-engine) into
  `NotificationService.onArchiveMessage` / `onDeleteMessage`; because these
  mutate the shared repository, the already-wired
  `MailboxCubit.attachDbWatch()` (`app.dart`) refreshes the mailbox UI the
  same way any in-app archive/delete action does — no extra plumbing needed.
  New/extended coverage: `test/notification_service_test.dart` (single vs.
  aggregated toast action wiring) and `test/mailbox_cubit_test.dart`
  (`MessageActionService` ID-targeted archive/delete, including no-op paths
  for an unknown message id or a missing destination folder).

Renee QA pass / full `flutter test` run still pending before Wave D is marked
fully closed.

**Wave E status (2026-07-23):** D6-2 and D6-7 landed in code (Jules).

- **D6-2 Per-account image block + domain whitelist** — global
  `AppSettingsState.blockRemoteImages` is unchanged; two new maps,
  `accountBlockRemoteImages` (`Map<String, bool>`, missing key inherits
  global) and `accountImageAllowlistDomains`
  (`Map<String, List<String>>`, case-insensitive suffix match via the new
  `lib/ui/shell/privacy_url_utils.dart` helpers), persist through
  `AppSettingsCubit`/`SettingsExportService` alongside the existing prefs.
  `applyRemoteImagePolicy` (`lib/ui/shell/remote_image_policy.dart`) grew an
  `allowlistDomains` parameter and now also rewrites `srcset` candidates, not
  just `src`/CSS `url()`. `mail_workspace.dart` → `ReadingPane` →
  `_ReadingPaneContent` resolve the *effective* per-message policy from the
  selected message's `accountId` before handing it to `MessageBodyView`. The
  Privacy & security settings section gained a per-account override dropdown
  (inherit / block / always allow) plus a domain-chip allowlist editor.
- **D6-7 Advanced tracker blocking** — new
  `AppSettingsState.blockTrackers` (default **true**, independent of
  `blockRemoteImages`) with a matching Privacy & security toggle. New
  `lib/ui/shell/tracker_blocking_policy.dart` carries a curated, local-only
  ESP/analytics host denylist (Mailchimp, SendGrid, HubSpot, Klaviyo, Google
  Analytics, etc.) plus common open-tracking path patterns
  (`/wf/open`, `pixel.gif`, …) and strips/rewrites matching `img src`,
  `srcset`, and CSS `url()` resources the same way `remote_image_policy.dart`
  does — D6-2 allowlisted hosts are exempted. `MessageBodyView` now runs
  `applyRemoteImagePolicy` then `applyTrackerBlockingPolicy` in sequence and
  shows a dedicated "Trackers blocked" banner when only the latter fired.
  `wrapHtmlEmailDocument` (`lib/ui/shell/html_email_document.dart`) always
  injects `<meta name="referrer" content="no-referrer">`. No WebView
  subresource interception is used, per scope.
  New/extended coverage: `test/remote_image_policy_test.dart` (allowlist +
  `srcset`), `test/tracker_blocking_policy_test.dart` (new), and
  `test/app_settings_cubit_test.dart` (D6-2/D6-7 persistence groups).

Renee QA pass / full `flutter test` run still pending before Wave E is marked
fully closed.

**Wave F status (2026-07-23):** D6-4 and D6-5 landed in code (Jules).

- **D6-4 Template variables** — new pure helper
  `expandTemplatePlaceholders(String, TemplateVarContext)`
  (`lib/compose/template_placeholders.dart`) supports `{{name}}` /
  `{{first_name}}` (falls back to the first To recipient's email local-part
  when no display name is known), `{{email}}`, `{{from_name}}`,
  `{{from_email}}`, `{{subject}}`, and `{{date}}` (locale-free `Mon D, YYYY`
  formatting; no `intl` dependency). Tokens are case-insensitive and tolerate
  inner whitespace (`{{ NAME }}`); unknown tokens and tokens with no
  resolvable value are left unchanged. `ComposeSheet._insertTemplate` builds
  a `TemplateVarContext` from the sending account and the first parsed To
  recipient, then expands both the subject and body before insertion.
  `templates_sheet.dart`'s edit dialog lists the supported tokens as helper
  text. New coverage: `test/template_placeholders_test.dart`.
- **D6-5 Server-side snooze (best-effort)** — `snoozed_until` on the local
  message row stays the sole source of truth; no new Drift column/migration
  was needed. `MailCapabilities.supportsServerSnooze` (true for
  `GraphMailProvider`, false for `ImapSmtpMailProvider`) gates a new
  best-effort path in `MessageActionService`: on snooze, an account with
  server-snooze support gets its Snoozed folder resolved-or-created (via the
  existing `ensureSystemFolder` confirm-to-create flow — same UX as
  Trash/Junk/Archive) and the message is moved into it both locally and via
  an enqueued `push_message_action` move job, mirroring `archiveSelected`.
  `DriftAccountFolderStore.canonicalFolderRole` / folder-name and path-suffix
  heuristics now recognize a `snoozed` role so an existing "Snoozed" folder
  is found rather than re-created. On early manual un-snooze
  (`clearSnoozeSelected`) or on expiry, any message still parked in the
  Snoozed folder is best-effort moved back to Inbox (local + enqueued remote
  move); `MailboxCubit.refresh()` now calls the new
  `MessageActionService.resurfaceExpiredSnoozes()` instead of calling
  `MailRepository.clearExpiredSnoozes()` directly, so this move-back happens
  on every refresh and on the existing snooze-resurface timer. If the remote
  move cannot be resolved (no provider, no confirmation, or a request
  failure) the local snooze state still applies — IMAP accounts are
  unaffected and stay exactly as before (local-only). New coverage: a
  `MailboxCubit D6-5 server-side snooze` group in `test/mailbox_cubit_test.dart`
  covering the Graph-capable create/move/enqueue path, the non-capable
  (IMAP-like) local-only path, early clear-snooze move-back, and expiry
  resurface move-back.

Renee QA pass / full `flutter test` run still pending before Wave F is marked
fully closed.

**Dogfood UI (2026-07-27):** Android folder/drawer polish landed outside the
locked wave table — account chips in drawer, folder-picker bottom sheet,
title-bar + list **Show folders** → sheet; message-list row chrome fixes
([DEF-041](DEFECTS.md), [DEF-042](DEFECTS.md) closed). [DEF-046](DEFECTS.md)
(hamburger folders-only) remains open as enhancement.

## 5. Exit criteria (V1.5 complete)

- [x] D6-3: Graph compose can upload over sync-profile single-request cap via upload session
- [x] D6-1: Multiple concurrent detached mail windows on Windows
- [x] D6-2: Per-account remote image block + domain whitelist
- [x] D6-6: Save as PDF (reading-pane overflow, mirrors Save as EML)
- [x] D6-8: Windows toast Archive/Delete actions (single-message toasts only)
- [x] D6-4, D6-5, D6-7: Each feature meets its Tier D acceptance notes
- [x] UI-P28/P29/P30 + UI-P21 landed; UI-P22/P23 landed (Wave B, 2026-07-23)
- [x] Regression: full `flutter test` green (499, 2026-07-27); V1 exit checklist remains signed-off baseline — operator manual E2E optional smoke
- [x] Docs: ROADMAP / USER_GUIDE / SPEC deltas updated (Page, 2026-07-27)

## 6. Relationship to other docs

| Doc | Role |
| --- | --- |
| [TIER_D_PLAN.md](TIER_D_PLAN.md) | Horizon catalog; D6 detail; locked decisions updated for V1.5 |
| [ROADMAP.md](ROADMAP.md) | Living index — Post-v1 section points here |
| [UI_ENHANCEMENT_SWEEP.md](UI_ENHANCEMENT_SWEEP.md) | UI-P21–P30 acceptance text |
| [V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md) | V1 baseline (signed off) — regression source |
| [TIER_D_PLAN.md §2](TIER_D_PLAN.md#2-promotion-framework) | Promotion gates (already applied) |

---

*When kicking off implementation, open a short wave checklist per Wave A–F (same pattern as W4/W7).*
