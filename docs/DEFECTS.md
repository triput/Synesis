# ByteMail Defects Log

| Priority | Meaning |
| --- | --- |
| Pri-1 | Blocks daily use or data safety — fix immediately |
| Pri-2 | Important but not urgent — schedule soon |
| Pri-3 | Nice-to-have / polish |

---

## Open

### DEF-034 — No auto-mark-as-read after viewing a message

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | Open |
| Area | `lib/ui/shell/reading_pane.dart`, `lib/ui/mailbox/mailbox_cubit.dart`, `lib/mailbox/message_action_service.dart` |
| Platforms | All |
| Logged | 2026-07-17 |
| Wave | **V1** (schedule in **W7** polish or anytime after W5 lands) — **not a W5 blocker** |
| Related | [UI-P27](UI_ENHANCEMENT_SWEEP.md), post-V1 [UI-P28](UI_ENHANCEMENT_SWEEP.md) |

**Summary**  
Opening/selecting a message leaves it unread until the user manually marks it read. Users expect the message to mark read automatically after it has been open in the reading pane for a short dwell time.

**Expected (V1)**  
With auto-mark enabled by default: when an unread message remains the selected/open reading-pane message for **5 continuous seconds**, ByteMail marks it read locally and pushes Seen/read to the provider (same path as manual mark-read). Changing selection or closing before 5s cancels the timer. Already-read messages are no-ops. Detached/secondary windows should follow the same policy if they show a message.

**Actual**  
Read state changes only via explicit mark-read/unread actions (toolbar, shortcut, bulk).

**Out of scope for this defect (post-V1 — UI-P28)**  
User settings to change the dwell time or disable auto-marking. V1 ships fixed 5s, default ON (no Appearance toggle required for V1).

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
| Status | Open |
| Area | `MailboxState.isLoadingHeaders`, `MailboxState.headersErrorMessage`, `message_headers_sheet.dart` |
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

### DEF-007 — Sync header refresh can overwrite local read/unread

| Field | Value |
| --- | --- |
| Priority | **Pri-2** |
| Status | Open |
| Area | `SyncEngine._toMailMessage`, `DriftMailRepository.upsertMessages`, `MailboxCubit.setUnreadBulk` |
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

## Closed

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
Slim AppBar title to “ByteMail” and set OS title from the subject; on WebView `unsupported_platform` / `environment_creation_failed`, fall back to **`flutter_widget_from_html`** (layout-preserving in-app HTML, not plain text); hide “Open in new window” in detached mode; register `show_main_window` on the main engine. Tests: `test/html_email_fallback_test.dart`. True WebView2 parity in secondary engines remains a known platform limit.

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
