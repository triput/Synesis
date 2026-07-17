# Tier A Implementation Plan

| Field | Value |
| --- | --- |
| Status | **TA-0 + TA-5 landed in W0** (2026-07-16); **TA-1 + TA-4 landed in W1** (2026-07-17); TA-2, TA-3, TA-6 remain |
| Scope | Table-stakes parity ([COMPETITIVE_ANALYSIS.md](COMPETITIVE_ANALYSIS.md) §4) |
| Baseline | SPEC v1.4, ROADMAP 2026-07-17, codebase audit |
| Last updated | 2026-07-17 (W1 completion gate) |

Tier A closes the gap between **“foundation landed”** and **“feels like a real mail client.”** Each phase has explicit exit criteria, a file blast radius, and tests. Phases are sequenced by dependency; some work can run in parallel where noted.

---

## 1. Tier A scope (recap)

| # | Capability | Today | Target |
| --- | --- | --- | --- |
| A1 | **Attachments** — view, download, compose | `hasAttachments` flag only | On-demand fetch, local cache, MIME send |
| A2 | **Reply / Reply-all / Forward** | **Landed (W1)** | Opens compose with `ComposePrefill` envelope (full HTML quote in W4) |
| A3 | **Delete / Archive / Move** | **Landed (W1)** | Optimistic local + provider sync; trash + recover + auto-purge |
| A4 | **Flag / star** | **Landed (W1)** | Toggle + list column + filter-ready column |
| A5 | **CC / BCC + quoted reply** | Plain To only | Full recipient envelope |
| A6 | **Signatures** | Missing | Per-account named signatures + default/none |
| A7 | **Junk / not junk** | **Landed (W1)** | Folder role + move actions |
| A8 | **Browser OAuth** | Manual Graph token paste | Entra + Google system-browser flow |
| A9 | **New-mail notifications** | Desktop callback seam only | Android + Windows user-visible alerts |

**Tier A complete when:** a user on Windows or Android can add an account via OAuth, receive a notification for new mail, open a message with attachments, star it, reply with signature and CC, archive or mark junk, and delete — with offline queue behavior preserved for send.

---

## 2. Architecture pattern (reuse mark-read)

Mark read/unread (`MailboxCubit` + `MailProvider.setRead`) is the **template** for all Tier A mutations:

```text
UI action
  → MailboxCubit (optimistic emit)
  → MailRepository (SQLite write)
  → MailProvider.* (best-effort remote)
  → on failure: revert OR enqueue sync_job `push_message_action`
```

| Layer | Responsibility |
| --- | --- |
| **UI** | Declarative; calls Cubit methods only |
| **MailboxCubit** | Optimistic state, selection advance on delete, error surfacing |
| **MailRepository** | Durable local truth; folder counts; FTS consistency |
| **MailProvider** | Graph / IMAP protocol mapping |
| **SyncEngine** | Retry failed pushes; detect new mail for notifications |
| **Compose / Outbox** | Durable send queue; extended envelope in schema v6+ |

New provider methods belong on `MailProvider` — not ad-hoc calls from widgets.

---

## 3. Phase overview

```text
TA-0 Foundations ─────────────────────────────────────────────┐
  schema v5/v6, MailProvider extensions, mime isolate stub     │
                                                                ▼
TA-1 Core message actions ◄── highest ROI, stubs exist today
  reply/forward wiring, delete/archive/move, star
                                                                │
TA-2 Compose envelope ◄──────── can start after TA-0 outbox shape
  CC/BCC, quote, signatures, unified compose modes              │
                                                                ▼
TA-3 Attachments ◄──────────── depends on TA-0 + TA-2 outbox MIME
  receive, reading pane, compose attach, send multipart         │
                                                                │
TA-4 Junk ◄─────────────────── depends on TA-1 move primitive   │
                                                                │
TA-5 OAuth ◄────────────────── **PRIORITY: Graph first**; parallel with TA-1 after schema
                                                                │
TA-6 Notifications ◄────────── parallel track; needs sync hook  │
```

**Parallel tracks:** **TA-5 OAuth (Microsoft Graph first)** starts immediately after TA-0 schema; TA-1 message actions in parallel once Graph auth lands. TA-6 can overlap W3/W6 in integrated build.

**V1 wave mapping:** See [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md) — **W0 landed 2026-07-16**; **W1 landed 2026-07-17**; W2 unlocked; W4 compose is last.

| Phase | W0 / wave status (2026-07-17) |
| --- | --- |
| **TA-0** | **Landed** — schema v5, MailProvider mutations, MIME isolate |
| **TA-5** | **Landed in code** — Entra + Google PKCE; live Graph E2E = operator Entra registration |
| **TA-1, TA-4** | **Landed** — W1 message actions + junk + trash (2026-07-17) |
| **TA-2, TA-3, TA-6** | Not started — W4 / W6 |

---

## 4. TA-0 — Foundations

**Goal:** Shared contracts and schema so feature phases don't rework persistence.

### 4.1 Schema migration v5 — message flags & folder roles

| Change | Detail |
| --- | --- |
| `messages.starred` | `BOOL NOT NULL DEFAULT 0` |
| `folders.role` | Already exists; ensure `junk`, `archive`, `trash`, `sent`, `drafts` normalized on sync |
| Index | `(account_id, folder_id, when_epoch_ms)` — already useful; add `(account_id, starred)` if filter lands in Tier B |

**Files:** `lib/repository/database.dart`, run `build_runner`, update `drift_mail_repository.dart`, `domain/models.dart`.

### 4.2 Schema migration v6 — outbox envelope

Extend `outbox` (or add `outbox_envelope` JSON column):

| Column | Type | Purpose |
| --- | --- | --- |
| `cc_json` | TEXT | CC addresses |
| `bcc_json` | TEXT | BCC addresses |
| `compose_mode` | TEXT | `new`, `reply`, `reply_all`, `forward` |
| `in_reply_to` | TEXT nullable | Message-ID header |
| `references_json` | TEXT nullable | Threading refs |
| `attachment_refs_json` | TEXT nullable | Local blob IDs |
| `signature_id` | TEXT nullable | Selected signature |

### 4.3 Schema migration v7 — attachments (can ship with TA-3)

| Table | Columns |
| --- | --- |
| `attachments` | `id`, `message_id`, `provider_part_id`, `filename`, `mime_type`, `size_bytes`, `local_path` nullable, `fetched_at` nullable |
| `attachment_blobs` | `id`, `account_id`, `path`, `size_bytes`, `created_at` — for compose/outbox staging |

### 4.4 Schema migration v8 — signatures (can ship with TA-2)

| Table | Columns |
| --- | --- |
| `account_signatures` | `id`, `account_id`, `name`, `body_plain`, `body_html`, `is_default`, `sort_order` |
| `account_signature_assets` | `id`, `signature_id`, `local_path`, `content_id`, `mime_type` — [UI-P20](UI_ENHANCEMENT_SWEEP.md) |

### 4.5 `MailProvider` contract extensions

Add to `lib/protocol/mail_provider.dart`:

```dart
Future<void> setStarred(String providerId, {required bool starred, String? folderRemoteId});

Future<void> moveMessage(
  String providerId, {
  required String destinationFolderRemoteId,
  String? sourceFolderRemoteId,
});

Future<void> deleteMessage(
  String providerId, {
  String? folderRemoteId,
  bool permanent = false,
});

Future<List<RemoteAttachmentMeta>> listAttachments(
  String providerId, {
  String? folderRemoteId,
});

Future<List<int>> fetchAttachmentBytes(
  String providerId,
  String attachmentId, {
  String? folderRemoteId,
});

// Extend send — or add sendEnvelope(OutgoingEnvelope envelope)
```

| Provider | Delete | Archive | Move | Star | Attachments |
| --- | --- | --- | --- | --- | --- |
| **Graph** | `DELETE /messages/{id}` or move to `deleteditems` | `POST /messages/{id}/move` → `archive` | `POST .../move` | `PATCH` `flag` `flagged` | `GET /attachments`, `GET /attachments/{id}/$value` |
| **IMAP** | `UID STORE +EXPUNGE` or COPY to Trash | COPY to Archive + STORE `\Deleted` | `UID COPY` + `\Deleted` source | `UID STORE \Flagged` | `BODYSTRUCTURE` + `BODY.PEEK[]` |

Add `MailCapabilities.supportsMove`, `supportsPermanentDelete`, `supportsStar`.

### 4.6 MIME module bootstrap

Replace `lib/mime/mime.dart` placeholder with:

- `OutgoingEnvelope` value type
- `buildMultipartMessage(...)` using `enough_mail` `MimeMessage`
- `parseAttachmentParts(...)` — runs in **Isolate** (`compute` or dedicated `Isolate.run`)

### 4.7 Repository helpers

| Method | Purpose |
| --- | --- |
| `updateMessageStarred(ids, starred)` | Local flag |
| `moveMessages(ids, destFolderId)` | Update `folder_id`, adjust counts |
| `deleteMessages(ids)` | Remove rows + FTS + attachment refs |
| `resolveFolderByRole(accountId, role)` | Map `junk` / `archive` / `trash` |
| `enqueueOutboxEnvelope(OutgoingEnvelope)` | TA-2 |

### TA-0 exit criteria

- [x] Migrations apply cleanly from v4 → v5 (`schemaVersion` 5; consolidated v5 batch)
- [x] `MailProvider` extensions implemented for Graph + IMAP (capability flags + default `UnsupportedError`)
- [x] Unit tests for schema v5, MessageQuery defaults, MIME builder isolate
- [x] `flutter test` green (including `schema_v5_test`, `message_query_test`, `mime_builder_test`, `mail_provider_capabilities_test`)

**Landed:** 2026-07-16 (W0). Outbox envelope / attachment / signature tables created in v5 migration; feature UI ships in later waves (W4 / TA-2 / TA-3).

**Estimate:** 3–5 days

---

## 5. TA-1 — Core message actions

**Goal:** Wire existing reading-pane stubs; parity with mark-read UX.

### 5.2 Trash, recover, and auto-purge

| Rule | Behavior |
| --- | --- |
| Default delete | Move to trash folder (`deleteditems` / IMAP Trash) — **not** permanent |
| Recover | User moves message from Trash to Inbox (or any folder) **before** auto-purge |
| Auto-purge | Device setting `trash_retention_days` (default **30**). When message has been in trash ≥ N days, `trash_purge` job permanently deletes local + provider copy |
| `trashed_at` | Set on `messages` when entering trash; cleared on recover |
| Shift+Delete | Permanent delete immediately where provider supports |

### 5.3 MailboxCubit API

| Method | Behavior |
| --- | --- |
| `reply({bool replyAll})` | Opens compose sheet with mode + prefill |
| `forward()` | Compose mode forward + subject `Fw:` |
| `archiveSelected()` | Move to account `archive` folder role |
| `deleteSelected({bool permanent})` | Move to trash or hard delete per capability |
| `moveSelectedToFolder(folderId)` | Folder picker dialog |
| `toggleStarSelected()` | Flip `starred` optimistic + `setStarred` |

Bulk variants mirror `markRead` / `markUnread` (already have multi-select).

### 5.4 UI wiring

| Surface | Work |
| --- | --- |
| `reading_pane.dart` | Connect `_Action` buttons to Cubit |
| `mail_workspace.dart` | Keyboard: `Delete`, `E` archive, `R` reply, `Shift+R` reply-all, `F` forward, `S` star |
| `message_list_pane.dart` | Star icon column; optional swipe (defer to Tier B if tight) |
| Move dialog | Simple `AlertDialog` with folder list for active account |

### 5.5 Selection advance on delete

After delete/archive/move, select next message in list (fix related DEF-002 fallout).

### 5.6 Sync job fallback

New job type `push_message_action` with payload `{messageId, action, ...}` for offline or failed provider push.

### TA-1 exit criteria

- [x] Reply/Forward open compose (prefill via `ComposePrefill`; full HTML quote deferred to TA-2 / W4)
- [x] Delete removes from list locally; reappears only if provider rejects and job retries fail visibly
- [x] Archive moves to archive folder in sidebar + provider
- [x] Star toggles persist across restart (local SQLite + provider `setStarred`)
- [x] Trash recover works within retention window (`recoverSelected`)
- [x] Auto-purge removes messages after configured days in trash (`trash_purge` job)
- [x] `mailbox_cubit_test.dart` covers optimistic star, delete selection advance, junk move, trash folder query

**Landed:** 2026-07-17 (W1). Quick-reply send and full quoted reply body remain W4 / TA-2 scope.

**Estimate:** 4–6 days  
**Depends on:** TA-0 provider extensions

---

## 6. TA-2 — Compose envelope

**Goal:** Replace minimal compose sheet with a mode-aware composer.

### 6.1 Unified compose model

```dart
enum ComposeMode { newMessage, reply, replyAll, forward }

class ComposeDraft {
  final ComposeMode mode;
  final String accountId;
  final List<String> to, cc, bcc;
  final String subject;
  final String body;
  final String? inReplyTo;
  final List<String> references;
  final String? signatureId;
  final List<LocalAttachmentRef> attachments;
  final MailMessage? sourceMessage; // for quote
}
```

### 6.2 UI (`compose_sheet.dart` → optional `compose_page.dart` on desktop)

| Field | Notes |
| --- | --- |
| To / Cc / Bcc | Expandable Cc/Bcc row |
| Subject | Auto `Re:` / `Fw:` prefix rules |
| Body | Quoted block below `---` or `>` prefix for reply |
| Signature | Dropdown: None / Default / named list |
| Attach | Paperclip (staged blobs; full send in TA-3) |

### 6.3 Signatures

| Piece | Detail |
| --- | --- |
| CRUD | `AccountSignaturesCubit` or methods on `AccountService` |
| Settings | Section in `EditAccountSheet` |
| Apply | Append on send after user body |
| **HTML** | **`body_html` supported** — render/sign with HTML when possible; plain fallback |
| **Images** | Logos/images in HTML sigs — [UI-P20](UI_ENHANCEMENT_SWEEP.md) (`account_signature_assets`, CID on send) |
| Default | One `is_default` per account; nullable = none |

### 6.4 Outbox + send job

- `send_outbox` reads envelope columns
- Graph: `sendMail` with `ccRecipients`, `bccRecipients`, `replyTo` / custom headers via `internetMessageHeaders` for `In-Reply-To`
- IMAP: SMTP `MimeMessage` with headers

### 6.5 Quick reply

Wire reading-pane quick-reply field → `ComposeDraft` reply mode → outbox (plain, no CC).

### TA-2 exit criteria

- [ ] Reply-all computes To/Cc from parsed headers (use `raw_headers` cache)
- [ ] Forward includes quoted body or attachment placeholder note
- [ ] CC/BCC delivered in test send (Graph + IMAP)
- [ ] Signature CRUD + default per account
- [ ] Quick reply queues outbox item
- [ ] Tests: subject prefix, recipient parsing, signature append

**Estimate:** 5–7 days  
**Depends on:** TA-0 outbox schema; TA-1 reply entry points  
**Parallel with:** TA-3 attachment UI shell

---

## 7. TA-3 — Attachments

**Goal:** SPEC §5.3 — fetch on demand; compose attach; retention-aware.

### 7.1 Receive path

```text
Message open (hasAttachments)
  → MailboxCubit.ensureAttachmentsCached(messageId)
  → job or inline: provider.listAttachments + fetchAttachmentBytes
  → write attachment_blobs under app support / attachments/{accountId}/{id}
  → upsert attachments table
```

### 7.2 Reading pane

- Attachment chip row under subject (filename, size, mime icon)
- Tap: open with `url_launcher` / `open_filex` if previewable; else save picker
- Loading / error states per attachment

### 7.3 Compose path

- File picker → copy to `attachment_blobs` staging
- Outbox `attachment_refs_json`
- `send_outbox`: build `multipart/mixed` in MIME isolate
- Graph: small attachments inline `< 3 MB`; larger = upload session (document in DEFECTS if deferred)

### 7.4 Retention

- `retention_cleanup` deletes orphan blobs when parent message pruned

### TA-3 exit criteria

- [ ] PDF/image attachment opens on Windows + Android
- [ ] Compose send with one attachment succeeds Graph + IMAP
- [ ] Offline compose with attachment queues until send
- Size limit enforced per **user-settable** `sync_profiles.attachment_max_mb` (W3); compose UI warns **larger files slow transmission**
- Graph: small attachments inline; over-cap → W7 upload session or clear error with cap hint
- [ ] Tests: MIME builder unit tests; repository attachment CRUD

**Estimate:** 7–10 days  
**Depends on:** TA-0 MIME module, TA-2 outbox envelope

---

## 8. TA-4 — Junk mail

**Goal:** Minimal junk parity — overlaps TA-1 move primitive.

### 8.1 Folder exposure

- Ensure `junkemail` / IMAP `Junk` synced with `role = junk` (Graph mapping exists)
- Sidebar shows Junk under account

### 8.2 Actions

| Action | Implementation |
| --- | --- |
| **Report junk** | `moveMessage` → junk folder |
| **Not junk** | Move to inbox |

Optional: Graph `markAsJunk` API if move insufficient — evaluate during implementation.

### TA-4 exit criteria

- [x] Junk folder visible when provider exposes it (role `junk` in folder tree)
- [x] Report junk / not junk from reading pane (`reportJunk` / `notJunk`)
- [x] Message leaves current folder view optimistically
- [x] Tests: junk move covered in `mailbox_cubit_test.dart` (`reportJunk` → junk folder)

**Landed:** 2026-07-17 (W1).

**Estimate:** 2–3 days  
**Depends on:** TA-1 move

---

## 9. TA-5 — Browser OAuth

**Goal:** Remove manual token paste for production onboarding.

### 9.1 Microsoft Entra (Graph) — **priority**

**Locked:** OAuth ships before compose; Microsoft Graph must work for daily use. TA-5 is the **first vertical slice** after TA-0 schema.

| Piece | Choice |
| --- | --- |
| Flow | **Authorization code + PKCE** |
| Windows redirect | Loopback `http://127.0.0.1:{port}/callback` or custom scheme `bytemail://auth` |
| Android redirect | App link / custom scheme |
| Library | Evaluate `flutter_appauth`, `aad_oauth`, or thin `url_launcher` + local HTTP listener |
| Token storage | Existing `OAuthIdentityManager`; implement refresh via `oauth2` package |
| Config | `GraphAuthConfig` from env / build flavor — **never commit client secret** (public client PKCE) |

### 9.2 Google (IMAP)

| Piece | Choice |
| --- | --- |
| Flow | OAuth 2.0 PKCE for `https://mail.google.com/` scope |
| Fallback | Keep app-password path in `AddAccountSheet` |
| Token use | XOAUTH2 for IMAP/SMTP (`enough_mail` AUTHENTICATE PLAIN) |

### 9.3 UX

- Replace paste field with **Sign in with Microsoft / Google** buttons
- Clear error states: cancelled, denied, network
- Re-auth path in `EditAccountSheet`

### TA-5 exit criteria

- [x] Graph OAuth PKCE flow in code (`OAuthIdentityManager`, redirect capture, token refresh) — `test/oauth_identity_manager_test.dart`
- [x] Google OAuth IMAP/SMTP XOAUTH2 path in code
- [x] Sign in with Microsoft / Google buttons in `AddAccountSheet` (token paste dev fallback when Graph client ID unset)
- [x] Entra + Google registration runbooks in README
- [ ] **Operator checkpoint:** New Graph account via browser on Windows + Android with live Entra app registration (sync + send dogfood)

**Landed in code:** 2026-07-16 (W0). Live Graph OAuth E2E is blocked only on operator Entra app registration — not a code defect.

**Estimate:** 5–8 days (app registration + redirect URIs often dominate calendar time)  
**Depends on:** TA-0 only (auth is orthogonal)  
**Risk:** Entra admin consent in org tenants

---

## 10. TA-6 — New-mail notifications

**Goal:** User-visible alert when sync imports new unread messages.

### 10.1 Detection

In `SyncEngine` after incremental/folder upsert:

```dart
final List<MailMessage> newUnread = ... // compare before/after or use `isNew` from upsert
if (newUnread.isNotEmpty) NotificationService.instance.onNewMail(newUnread);
```

Deduplicate by `message.id`; respect per-account mute settings (basic toggle in appearance settings).

### 10.2 Platform

| Platform | Integration |
| --- | --- |
| **Android** | `flutter_local_notifications`; channel per account optional |
| **Windows** | `local_notifier` or `windows_notification` package; wire `WindowsDesktopController.showNewMailToast` |
| **Foreground** | Suppress or in-app snackbar only — product choice |

### 10.3 Settings

| Setting | Default |
| --- | --- |
| Notifications enabled | on |
| Per-account enable | all on |
| Quiet hours | off (Tier B) |

### TA-6 exit criteria

- [ ] New mail after sync shows notification on Android AVD + Windows
- [ ] Tap notification opens app to message (deep link `bytemail://message/{id}` optional)
- [ ] No notification for read mail or re-sync duplicates
- [ ] Widget refresh still independent of Flutter wake
- [ ] Tests: dedupe unit test; mock `NotificationService`

**Estimate:** 4–6 days  
**Depends on:** Sync engine hook (any phase after TA-0)

---

## 11. Testing matrix

| Phase | Unit | Widget | Manual |
| --- | --- | --- | --- |
| TA-0 | migrations, MIME builder, provider capability flags | — | — |
| TA-1 | Cubit optimistic actions, folder role resolver | reading pane buttons enabled | Graph + IMAP delete/archive/star |
| TA-2 | recipient parse, signature append, subject rules | compose fields | send reply-all with CC |
| TA-3 | MIME multipart, attachment repo | attachment chips | open PDF, send image |
| TA-4 | junk folder resolve | — | report junk round-trip |
| TA-5 | token refresh mock | — | full OAuth both platforms |
| TA-6 | dedupe, mute rules | — | AVD + Windows toast |

---

## 12. Dependencies to add (planning)

| Package | Phase | Purpose |
| --- | --- | --- |
| `file_picker` | TA-3 | Compose attach |
| `open_filex` or `url_launcher` | TA-3 | Open attachments |
| `flutter_appauth` or `oauth2` | TA-5 | OAuth PKCE |
| `flutter_local_notifications` | TA-6 | Android alerts |
| `local_notifier` | TA-6 | Windows toasts |

**Action:** User approval before `pubspec.yaml` changes per AGENTS.md execution policy.

---

## 13. Risks & mitigations

| Risk | Mitigation |
| --- | --- |
| Graph large attachment upload | User-settable cap; inline below cap; upload session W7; always show transmission warning |
| IMAP folder naming variance for Junk/Archive | Role assignment on sync; fallback folder picker |
| OAuth redirect on Windows store build | Register loopback + custom scheme early |
| MIME in isolate complexity | Start with send-only isolate; parse can be sync for small parts |
| TA-3 blocks Tier A “complete” | Ship TA-1+TA-2 first as **Tier A-alpha** usable daily driver |

---

## 14. Schedule sketch (single developer, optimistic)

| Week | Focus |
| --- | --- |
| 1 | TA-0 + TA-1 |
| 2 | TA-2 + start TA-5 OAuth |
| 3 | TA-3 attachments |
| 4 | TA-4 junk + TA-6 notifications + OAuth finish |
| 5 | Hardening, Android AVD pass, DEF-001 shortcuts |

**Tier A-alpha (usable):** end of week 2 — actions + compose + signatures, attachments still missing.  
**Tier A-complete:** end of week 4–5.

---

## 15. ROADMAP integration

When scheduling begins, promote each phase to ROADMAP milestone IDs **TA-0 … TA-6** and check off against this document. Do not duplicate scope in ROADMAP tables — link here.

---

## 16. Locked decisions (2026-07-16)

| # | Question | Locked choice |
| --- | --- | --- |
| 1 | Delete default | **Trash** + recover; **auto-purge after N days in trash (default 30)**; Shift+Delete permanent |
| 2 | Archive on IMAP without Archive folder | Folder picker fallback; no auto-create v1 |
| 3 | HTML signatures | **Yes** — `body_html` on signatures when possible |
| 4 | Attachment size limit | **User-settable** per sync profile; warn that larger = slower send |
| 5 | OAuth vs message actions | **OAuth first (Graph)**; message actions parallel after schema + Graph auth |

*Full cross-tier locked list: [V1_TIER_INTEGRATION.md §12](V1_TIER_INTEGRATION.md#12-locked-decisions-2026-07-16).*

---

*Prepared for Jules (implementation), Renee (test plans), Page (SPEC § updates when TA-0 locks schema).*
