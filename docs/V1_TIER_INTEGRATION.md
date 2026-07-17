# V1 Tier Integration Review

| Field | Value |
| --- | --- |
| Status | Active — **W0 landed** (2026-07-16); **W1 landed** (2026-07-17); **W2 landed** (2026-07-17); **W3 landed** (2026-07-17); **W5 landed** (2026-07-17); **W6 unlocked / planned** |
| Purpose | Reduce redundant file touches; merge adjacent tier work |
| Inputs | [TIER_A_PLAN.md](TIER_A_PLAN.md), [TIER_B_PLAN.md](TIER_B_PLAN.md), [TIER_C_PLAN.md](TIER_C_PLAN.md) |
| Last updated | 2026-07-17 (W5 landed; W6 unlocked; `.eml` ProgId deferred packaging) |

You are **not** shipping iterative Tier A → B → C releases. V1 should land as one client worth dogfooding for months. This document reorganizes the three tier plans into **integration waves** that touch each subsystem once.

---

## 1. Executive summary

| Problem | Solution |
| --- | --- |
| Three compose refactors (TA-2, TB-12, TB-13) | **One Compose System** wave |
| Four list/query refactors (TA filters implicit, TB-0, TB-1, TB-2, TB-11) | **One MessageQuery** wave up front |
| Two layout refactors (TB-9, TC-9 multi-window) | **One MailWorkspace Layout** wave |
| Two notification builds (TA-6, TC-7) | **One NotificationService** with full settings |
| Two onboarding refactors (TA-5 OAuth, TC-8 autoconfig) | **One Add Account** wave |
| Schema migrations v5–v10 in pieces | **Consolidated schema v5** (single migration batch) |
| `html_email_*` touched for privacy + rich mail | **One HTML pipeline** wave |

**Recommended V1 structure:** 8 integration waves (W0–W7), not 22 isolated tier phases.

---

## 2. Subsystem touch map (before consolidation)

Shows how many tier phases originally touched the same files:

| Subsystem / file area | Tier A | Tier B | Tier C | Total touches |
| --- | --- | --- | --- | --- |
| `database.dart` / migrations | TA-0 (v5–8) | TB-0 (v9) | TC-0 (v10), TC-3 | **4** |
| `mail_provider.dart` + adapters | TA-0, TA-3, TA-4 | TB-1, TB-6, TB-10 | TC-8 | **4** |
| `mailbox_cubit.dart` / `mailbox_state.dart` | TA-1, TA-3 | TB-0–5, TB-11 | — | **3+** |
| `drift_mail_repository.dart` | TA-0 | TB-0 | TC-1 | **3** |
| `compose_sheet` / compose model | TA-2, TA-3 | TB-6, TB-12, TB-13 | TC-10 | **5** |
| `mail_workspace.dart` | TA-1 shortcuts | TB-9 | TC-9 | **3** |
| `message_list_pane.dart` | TA-1 star column | TB-1–2, TB-7, TB-14 | — | **4** |
| `reading_pane.dart` | TA-1, TA-3 | TB-4, TB-8 | TC-11 Ctrl+F | **4** |
| `sync_engine.dart` | TA-6 detect | TB-10 | TC-1, TC-2, TC-5 | **4** |
| `add_account_sheet.dart` | TA-5 | — | TC-8 | **2** |
| `html_email_body.dart` | — | TB-12 read | TC-6 | **2** |
| `appearance_sheet` / settings | TA-6 basic | TB-9 layout | TC-1, TC-3, TC-7 | **4** |
| `mime/` module | TA-0, TA-3 | TB-12 | TC-6 | **3** |
| Notifications | TA-6 | — | TC-7 | **2** |

**Goal:** Each row → **1 integration wave** per subsystem.

---

## 3. Work moved between tiers (consolidation decisions)

### 3.1 Move **into Tier A / W0** (do earlier — was Tier B or C)

| Item | Was | Move to | Rationale |
| --- | --- | --- | --- |
| `MessageQuery` + schema `thread_id`, `snoozed_until` | TB-0 | **W0 Schema** | Every list feature needs one query API; avoid rewriting `listMessages` after TA-1 |
| `messages.starred` + `pinned` wiring plan | TA-0 / TB-5 | **W0 Schema** | Star in TA-1; pin UI can wait but column + query bit ready |
| Starred virtual view | TB-11 | **W2 List UX** with filters | Trivial once `MessageQuery.starredOnly` exists in W0 |
| Read-row dimming | TB-14 / UI sweep | **W2 List UX** | Same `message_list_pane` pass as date groups |
| Pull-to-refresh | TB-7 | **W2 List UX** | One mobile list pass |
| Per-account notification mute | TC-7 | **W6 Notifications** (with TA-6) | Build `NotificationService` once with full settings |
| Quiet hours | TC-7 | **W6 Notifications** | Same |
| `outbox.send_after` column | TC-10 / TC-0 | **W0 Schema** | Cheap column; schedule send UI in W4 Compose |
| Reply-all header parsing | TA-2 | **W4 Compose** | Needs robust `raw_headers` parse — do with threading refs in W1 |

### 3.2 Move **from Tier A to later waves** (defer without losing V1)

| Item | Was | Move to | Rationale |
| --- | --- | --- | --- |
| Quick reply (minimal) | TA-2 | **W4 Compose** | Same compose system; don’t ship half sheet then rewrite |
| Graph large attachment upload session | TA-3.1 | **W7 Hardening** | Cap size in W3; upload session if time |
| Junk folder UI polish | TA-4 | **W1 Actions** | Keep move primitive in W1; junk is just folder role |

### 3.3 Merge **Tier B + Tier C** (same wave)

| Combined wave | Items merged |
| --- | --- |
| **W3 Sync & storage** | TC-1 sync profiles + TC-2 network policy + TB-10 push + TC-5/TC-12 sync health UI |
| **W5 Desktop shell** | TB-9 layout + TC-9 keymap/tray/multi-window/Ctrl+F + DEF-001 |
| **W4 Compose** | TA-2 envelope + TA-3 attach + TB-6/12/13 + TC-10 + **UI-P19/P20** (outbound font, signature images) |
| **W6 Notifications** | TA-6 alerts + TC-7 granularity |
| **W0 Onboarding** | TA-5 OAuth + TC-8 autoconfig (same `AddAccountSheet`) |

### 3.4 Keep **Tier-exclusive** (no move)

| Item | Tier | Why separate |
| --- | --- | --- |
| DB encryption TC-3 | C | Large spike; optional opt-in; touches DB open path only |
| Widget enhancements TC-11 | C | Kotlin bridge; isolated |
| Focus override UI TC-4 | C | Independent settings surface |
| Conversation threading TB-1 | B | Complex UI; depends on W0 query only |
| HTML privacy TC-6 | C | Can ship with W3 after HTML body stable |

---

## 4. Consolidated V1 waves (W0–W7)

```text
W0  PLATFORM BASE + OAUTH — **LANDED 2026-07-16** ─────────────────────
    Schema v5 batch, MessageQuery, MailProvider mutations, MIME isolate
    Microsoft Entra OAuth code path ready (live E2E = operator Entra registration)
    Google OAuth + IMAP autoconfig landed in code

W1  MESSAGE ACTIONS — **LANDED 2026-07-17** ───────────────────────────
    Reply/forward/delete/archive/move/star/junk
    Trash + recover; configurable trash auto-purge (default 30 days)
    Keyboard shortcuts (core set)

W2  LIST & NAVIGATION UX — **LANDED 2026-07-17** ─────────────────────
    Threading (default on), filters, date groups, snooze, pin, swipes
    Adaptive reading-pane toolbar (520px); starred/pinned/snoozed views

W3  SYNC, STORAGE & PRIVACY — **LANDED 2026-07-17** ───────────────────
    Sync profiles + per-account retention + settable attachment max MB
    Push (IDLE / Graph delta); push on Android cellular = settings option
    Sync health / job viewer
    Remote images: global block toggle (per-account + domain whitelist → post-v1)

W5  DESKTOP SHELL — **LANDED 2026-07-17** ─────────────────────────────
    Reading-pane layout, Visual Focus, keymap (DEF-001), tray DI — landed
    Ctrl+F find bar, print/save/open EML, detached window UI, title-bar Open EML — landed
    [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) passed (operator); `.eml` ProgId deferred (packaging)

W6  NOTIFICATIONS — **UNLOCKED / PLANNED** ───────────────────────────
    Android + Windows alerts; per-account mute; quiet hours

W4  COMPOSE SYSTEM (last feature wave) ───────────────────────────────
    CC/BCC, quote, HTML signatures, rich text, templates
    Attachments view + compose + send (user-settable size cap)
    Drafts, schedule send, quick reply

W7  HARDENING & OPTIONAL ─────────────────────────────────────────────
    DB encryption opt-in (if ready), focus override UI, widgets, QA matrix
    Graph large attachment upload session (if over inline cap)
```

---

## 5. Wave detail & exit criteria

**Automated coverage:** Every wave’s automated tests are cataloged in [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) — filter by `wave` or `test_id`; see [TEST_INVENTORY.md](TEST_INVENTORY.md). Exit criteria below reference key test files; the inventory is canonical and avoids duplicating full lists here.

### W0 — Platform base + OAuth (priority)

**Status:** **Landed** (2026-07-16) — code + unit tests green; live Graph OAuth E2E requires operator Entra app registration ([README](../README.md#microsoft-graph-entra-setup)).  
**Duration estimate:** 2–3 weeks (actual: wave 0 complete)  
**Tier coverage:** TA-0, TB-0 (schema part), TC-0, **TA-5 (Microsoft Graph OAuth first)**, TC-8 shell

| Deliverable | Status | Exit |
| --- | --- | --- |
| Migration v5 single upgrade | **Landed** | Fresh install + upgrade from v4; `test/schema_v5_test.dart` |
| `MessageQuery` | **Landed** | Default query preserves pre-W0 list behavior; `test/message_query_test.dart` |
| `MailProvider` extensions | **Landed** | Graph + IMAP: star, move, delete, attachments list/fetch; capability tests |
| MIME module | **Landed** | Multipart builder runs in isolate; `test/mime_builder_test.dart` |
| **Entra OAuth E2E** | **Code ready** | PKCE browser flow, token refresh, redirect capture; live dogfood after Entra registration |
| Google OAuth | **Landed** | PKCE + XOAUTH2 IMAP/SMTP; `test/oauth_identity_manager_test.dart` |
| IMAP autoconfig (TC-8) | **Landed** | Thunderbird ISPDB + `/.well-known` lookup; `test/imap_autoconfig_test.dart` |

**W1 unlock:** W1 message actions may proceed now that W0 schema and OAuth code paths are landed. **Live Graph OAuth E2E** (add account → sync → send in a real mailbox) remains the operator checkpoint: register Entra app + redirect URIs, run with `BYTEMAIL_GRAPH_CLIENT_ID`, then confirm dogfood. Google OAuth and autoconfig do not block W1.

**Priority (unchanged):** Microsoft Graph OAuth must be dogfood-ready before W4; W1 can start in parallel with operator Entra validation.

---

### W1 — Message actions

**Status:** **Landed** (2026-07-17) — code + unit tests green; live Graph/IMAP round-trip dogfood recommended before W2 list UX.  
**Duration estimate:** 1–1.5 weeks (actual: wave 1 complete)  
**Tier coverage:** TA-1, TA-4

| Deliverable | Status | Exit |
| --- | --- | --- |
| All reading-pane actions wired | **Landed** | Reply, forward, archive, move, star, delete, junk/not-junk, recover, permanent delete — no empty action stubs (quick-reply send deferred to W4) |
| Optimistic + provider + job fallback | **Landed** | Same pattern as mark-read; `push_message_action` job type; `test/mailbox_cubit_test.dart` |
| Junk / not junk | **Landed** | `reportJunk` / `notJunk` via role folder move |
| **Trash + recover** | **Landed** | Delete → trash folder; `recoverSelected` restores; trash folder query via `MessageQuery.includeTrashed` |
| **Trash auto-purge** | **Landed** | `trash_retention_days` in appearance settings (default **30**); `trash_purge` job; `test/sync_engine_trash_purge_test.dart`, `test/app_settings_cubit_test.dart` |
| Keyboard shortcuts (core set) | **Landed** | Delete, Shift+Delete, E archive, R / Shift+R reply, F forward, S star in `mail_workspace.dart` |
| Compose prefill (reply/forward) | **Landed** | `ComposePrefill` thin envelope; full HTML quote in W4 — `test/compose_prefill_test.dart` |
| Star column (list) | **Landed** | Toggle in `message_list_pane.dart` |

**W2 unlock:** W2 list & navigation UX (threading, filters, date groups, snooze, pin, swipes) may proceed now that W1 message actions and trash semantics are landed. Live Graph OAuth E2E remains an operator checkpoint (Entra registration), not a W2 code blocker.

| Trash rule | Detail |
| --- | --- |
| Default delete | Move to trash (not permanent) |
| Recover | Move from Trash to Inbox (or any folder) before purge date |
| Shift+Delete | Permanent delete where provider supports |
| Auto-purge | Setting `trash_retention_days` (default 30); `trashed_at` on message when entering trash |

---

### W2 — List & navigation UX

**Status:** **Landed** (2026-07-17) — code + unit tests green; AVD manual pass documented in [W2_AVD_CHECKLIST.md](W2_AVD_CHECKLIST.md).  
**Duration estimate:** 2 weeks (actual: wave 2 complete)  
**Tier coverage:** TB-1, TB-2, TB-4, TB-5, TB-7, TB-11, TB-14

| Deliverable | Status | Exit |
| --- | --- | --- |
| Threaded + flat toggle | **Landed** | Default **threaded** via `AppSettingsState.threadDisplayMode`; flat toggle in Appearance; `MessageListProjector` groups by `(accountId, threadId)`; `test/message_list_projector_test.dart` |
| Filter bar + date sections | **Landed** | `MessageViewFilter` chip bar + sheet; `MessageListProjector` Outlook date buckets (Today, Yesterday, …); composes with Focus; `test/message_filter_bar_test.dart`, `test/message_query_test.dart` |
| Snooze + pin | **Landed** | **Local-only** — `snoozed_until` / `pinned` columns; `MessageQuery.excludeSnoozed`; resurfacing on app open; no server folder move |
| Mobile gestures | **Landed** | Swipe defaults: **right = archive**, **left = delete** (configurable in Appearance); pull-to-refresh; portrait reading pager; AVD checklist in [W2_AVD_CHECKLIST.md](W2_AVD_CHECKLIST.md) |
| Adaptive reading-pane toolbar | **Landed** | Icon+label actions at **≥520px** (`kReadingPaneWideBreakpoint`); compact icons below |
| Starred / pinned / snoozed virtual views | **Landed** | Sidebar entries via `MailboxVirtualView`; `MessageQuery.starredOnly` / `pinnedOnly` / `snoozedOnly` |
| Unread recount | **Landed** | `recountUnreadCounts()` from local messages; folder sidebar badges |
| `thread_id` from Graph / IMAP | **Landed** | Graph `conversationId`; IMAP `References` / `In-Reply-To` via `resolveThreadId`; `test/thread_id_test.dart` |

**W3 unlock:** W3 sync, storage & privacy may proceed now that W2 list UX is landed. **W2 ∥ W3** — list polish and sync/push work can run in parallel after W1.

---

### W3 — Sync, storage & privacy

**Status:** **Landed** (2026-07-17) — code + unit tests green; live IDLE/delta dogfood recommended on real Graph/IMAP accounts.  
**Duration estimate:** 2–3 weeks (actual: wave 3 complete)  
**Tier coverage:** TC-1, TC-2, TB-10, TC-5, TC-12, TC-6 (phase 1)

| Deliverable | Status | Exit |
| --- | --- | --- |
| Sync profiles affect jobs | **Landed** | `SyncProfile` domain type; `folder_scope_json` allowlist (roles/remoteIds); body policy; attachment max MB UI; per-account retention override; retention dial updates default profile + enqueues cleanup |
| **Attachment max MB** | **Landed** | User-settable per sync profile in Sync & Storage sheet; UI warns larger = slower send |
| Push or near-push | **Landed** | Graph delta + cursor; IMAP IDLE; `connectivity_plus` network policy; `pushOnCellular` default **false**; `supportsPush: true` on Graph when delta path exists |
| Sync panel | **Landed** | `SyncStatusSheet`: Jobs \| Accounts tabs; retry/cancel; title-bar sync chip opens sheet; sync-now icon in title bar |
| **Remote images (phase 1)** | **Landed** | `blockRemoteImages` default **true**; per-message “Load images for this message”; Appearance toggle; per-account + domain whitelist → **post-v1** |

**W5 landed / W6 unlock:** W5 desktop shell **landed** 2026-07-17 — [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) passed (operator); Windows `.eml` Explorer ProgId remains **deferred** (packaging follow-up, not a land blocker). **W6 Notifications unlocked.** W4 compose remains the last feature wave after W5 and W6.

---

### W4 — Compose system (last feature wave)

**Duration estimate:** 2–3 weeks  
**Tier coverage:** TA-2, TA-3, TB-6, TB-12, TB-13, TC-10

| Deliverable | Exit |
| --- | --- |
| One compose UI | All modes use `ComposeDraft` |
| Attachments E2E | Send image/PDF; respects user attachment cap; progress UX for large files |
| **HTML signatures** + rich text + templates | Formatting survives send; **signature images** (UI-P20) |
| Drafts + schedule | Autosave + delayed outbox |

**Placed last** so inbox/sync/desktop are dogfood-ready before the largest single subsystem touch.

---

### W5 — Desktop shell

**Status:** **Landed** (2026-07-17) — operator accepted [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md); `.eml` ProgId deferred (packaging)  
**Duration estimate:** 1.5–2 weeks (actual: wave 5 complete)  
**Tier coverage:** TB-9, TC-9, DEF-001

| Deliverable | Status | Exit |
| --- | --- | --- |
| 3 layout positions | **Landed** | Persisted — `MailSplitLayout`, `readingPanePosition`, widget tests |
| Visual Focus | **Landed** | Collapse sidebar/list; persisted `visualFocusEnabled`, Ctrl+Shift+M |
| Keymap + DEF-001 | **Landed** | Documented overlay; shortcuts without text focus; [DEF-001](DEFECTS.md) closed |
| Tray + `minimizeToTray` DI | **Landed** | Minimize/close → tray; show/quit menu — `WindowsDesktopController` + `app.dart` `BlocListener` |
| Ctrl+Shift+F / `/` search | **Landed** | Mailbox search sheet |
| Ctrl+F find in message | **Landed** | Match bar in reading pane; plain + HTML find |
| Print / save EML / open EML | **Landed** | Reading-pane + title-bar actions; overflow Print/Save EML/Open in new window |
| Launch with `.eml` arg | **Landed** | Preview sheet on startup — `main.dart` + `_LaunchHome` |
| **Detached message window** | **Landed** | One secondary window (V1) — `WindowsDetachedMessageWindowController` |
| Windows manual checklist | **Passed** (operator) | [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) — non-deferred sections accepted |
| Windows `.eml` association | **Deferred** (packaging) | Explorer double-click requires installer ProgId — follow-up, not a land blocker |

**Post-v1:** unlimited multi-window desktop — see ROADMAP Post-v1.

---

### W6 — Notifications

**Duration estimate:** 1 week  
**Tier coverage:** TA-6, TC-7

| Deliverable | Exit |
| --- | --- |
| New mail alerts | Android + Windows |
| Settings | Per-account + quiet hours |

---

### W7 — Hardening & optional

**Duration estimate:** 1–2 weeks  
**Tier coverage:** TC-3, TC-11, TC-4, UI sweep (W7 items), QA matrix

| Deliverable | Exit |
| --- | --- |
| SQLCipher opt-in | If spike successful |
| Focus override UI | CRUD rules |
| Widget polish | If time |
| **UI sweep** | Theme tokens, **custom themes**, **settings export**, **UI fonts**, density, empty states — [UI_ENHANCEMENT_SWEEP.md §8](UI_ENHANCEMENT_SWEEP.md#8-acceptance--sweep-done-for-v1) |
| **[DEF-034](DEFECTS.md) / UI-P27** auto-mark-as-read | **V1 scope, not a W5 blocker** — schedule with W7 polish (5s dwell, default ON; post-V1 configurability → UI-P28) |
| V1 exit checklist | Full SPEC acceptance |
| Multi-agent system prompt playbook | **Final wave FW-6** (after W7) — portable workflow prompt for future projects |

---

## 6. Revised schema — single migration v5

Consolidate TA-0 v5–8 + TB-0 v9 + TC-0 v10 into **one migration** for greenfield V1 build:

```text
messages:
  + starred BOOL
  + thread_id TEXT nullable
  + snoozed_until INT nullable
  + trashed_at INT nullable          # set when moved to trash; drives auto-purge
  + is_draft BOOL default 0
  + draft_sync_provider_id TEXT nullable

app_settings (or device_settings):
  + trash_retention_days INT default 30

outbox:
  + cc_json, bcc_json, compose_mode, in_reply_to, references_json
  + attachment_refs_json, signature_id
  + send_after INT nullable

attachments, attachment_blobs
account_signatures                    # body_plain + body_html (HTML signatures)
message_templates
sync_profiles                         # includes attachment_max_mb (user-settable)
custom_themes                          # UI-P16: base_theme_id + token_overrides_json
accounts.sync_profile_id, accounts.retention_days_override
# prefs (AppSettings): ui_font_*, outbound_font_* — UI-P18/P19
account_signature_assets               # UI-P20
```

**If upgrading from today's schema:** ship stepped migrations v5→v6 internally but implement in **one PR** before dogfood.

---

## 7. Dependency graph (waves)

```text
W0 (schema + OAuth — LANDED 2026-07-16)
  ├──► W1 message actions (LANDED 2026-07-17)
  ├──► W2 list UX (LANDED 2026-07-17)
  ├──► W3 sync & privacy (LANDED 2026-07-17)
  │         └──► W6 notifications
  W2 ──► W5 desktop shell (LANDED 2026-07-17)
  W1,W2,W3,W5,W6 ──► W4 compose (LAST feature wave)
  All ──► W7 hardening
```

**Critical path:** ~~W0~~ **W0 landed** → ~~W1~~ **W1 landed** → ~~W2~~ **W2 landed** → ~~W3~~ **W3 landed** → ~~W5~~ **W5 landed** → **W6** → **W4** → W7  
**Parallel:** **W6 unlocked** (2026-07-17); operator Graph OAuth validation (Entra registration) remains a dogfood checkpoint, not a W6 code blocker.

**Rationale for W4 last:** Reading, organizing, and Microsoft sync must be solid before the unified compose system (largest touch surface).

---

## 8. Tier-to-wave mapping reference

| Original phase | Wave |
| --- | --- |
| TA-0 | W0 |
| TA-1, TA-4 | W1 |
| TA-2, TA-3 | W4 |
| TA-5, TC-8 | W0 (scaffold) + W0 completion |
| TA-6, TC-7 | W6 |
| TB-0 | W0 |
| TB-1, TB-2, TB-4, TB-5, TB-7, TB-11, TB-14 | W2 |
| TB-6, TB-12, TB-13 | W4 |
| TB-9 | W5 |
| TB-10 | W3 |
| TC-0 | W0 |
| TC-1, TC-2 | W3 |
| TC-3 | W7 |
| TC-4 | W7 |
| TC-5, TC-12 | W3 |
| TC-6 | W3 | **Phase 1** global image toggle only; phase 2 post-v1 |
| TC-9 | W5 |
| TC-10 | W4 |
| TC-11 | W7 |

---

## 9. Redundant work explicitly eliminated

| Eliminated | Replaced by |
| --- | --- |
| Separate TB-11 starred phase | `MessageQuery.starredOnly` in W2 |
| TA-2 then TB-12 compose rewrites | W4 single compose system |
| TA-6 then TC-7 notification settings | W6 full `NotificationService` |
| TB-9 then TC-9 layout changes | W5 single `mail_workspace` refactor |
| Four migration waves | W0 schema v5 batch |
| Tier A-alpha / Tier B-beta releases | Wave checkpoints only — no partial releases |
| Duplicate filter systems (Focus vs user vs starred) | `MessageQuery` composable stack |

---

## 10. V1 complete definition (all tiers)

V1 is **not** “Tier A done.” V1 complete = **W0–W7 exit criteria met**, except:

| Optional at V1 gate | Wave |
| --- | --- |
| DB encryption | W7 — ship if spike passes; else document as W7.1 |
| Multi-window | W5 — single detached window (V1); unlimited → post-v1 |
| Graph webhook push | W3 — delta poll acceptable |
| Widget theme variants | W7 |

**V1 complete user story:** OAuth/autoconfig onboarding → push-ish sync with visible job health → threaded, filterable inbox → full compose with attachments → desktop layout + keymap → notifications with quiet hours → optional encrypted DB.

---

## 11. Schedule sketch (single team, full V1)

| Weeks | Waves |
| --- | --- |
| 1–3 | W0 Platform base + **Graph OAuth priority** |
| 4 | W1 Message actions (trash + recover + auto-purge) |
| 5–6 | W2 List UX ∥ W3 Sync (sequential or parallel) |
| 7 | W5 Desktop shell |
| 8 | W6 Notifications |
| 9–11 | **W4 Compose system (last)** |
| 12–13 | W7 Hardening + QA |

**~13 weeks** optimistic single senior dev.

---

## 12. Locked decisions (2026-07-16)

### Integration

| # | Decision | Locked choice |
| --- | --- | --- |
| 1 | Implementation model | **Waves** (W0–W7) |
| 2 | Schema migrations | **Single v5 batch** before dogfood |
| 3 | Wave order | **W4 compose last** — after W2, W3, W5, W6 |
| 4 | DB encryption in V1 gate? | **Optional W7** — do not block ship |
| 5 | Threading default | **On** — flat toggle in W2 |

### Tier A (mapped to waves)

| # | Decision | Locked choice |
| --- | --- | --- |
| 1 | Delete behavior | **Trash** default; recover before purge; **auto-purge after N days in trash (default 30)**; Shift+Delete = permanent where supported |
| 2 | Archive on IMAP without Archive folder | Folder picker fallback; no auto-create v1 |
| 3 | Signatures | **HTML signatures** when possible (`body_html` on `account_signatures`) |
| 4 | Attachment size limit | **User-settable** per sync profile; UI warns larger files slow transmission; Graph upload session in W7 if over inline cap |
| 5 | OAuth vs message actions | **OAuth first** (Microsoft Graph); message actions **parallel** once schema + Graph auth land |

### Tier B

| # | Decision | Locked choice |
| --- | --- | --- |
| 1 | Default inbox | Threaded with flat toggle |
| 2 | Snooze | Local only v1 |
| 3 | Rich editor | Spike `flutter_quill` |
| 4 | Push on Android cellular | **Supported** — **settings option** (not WiFi-only default) |
| 5 | Date groups + threads | Group by latest message in thread |

### Tier C

| # | Decision | Locked choice |
| --- | --- | --- |
| 1 | DB encryption timing | After schema freeze; optional W7 |
| 2 | Remote images | **V1:** global block/load toggle. **Post-v1:** per-account block + domain whitelist (e.g. amazon.com) |
| 3 | Multi-window | **V1:** single detached message window. **Post-v1:** unlimited multi-window desktop |
| 4 | Sync UI | Merge TC-5 + TC-12 |
| 5 | Schedule send | Local outbox delay only |

---

## 14. Relationship to Tier D

Items explicitly deferred to [TIER_D_PLAN.md](TIER_D_PLAN.md): unlimited multi-window, per-account image whitelist (phase 2), contacts/calendar, PGP/S/MIME, POP3, PST, cloud AI, platform expansion.

**V1.1 default bundle (D6):** multi-window+, image whitelist, Graph large attachments — triage after W7.

**Post-V1 program (locked):** V1.1 D6 only → V2 **PIM headline** + Galaxy Watch lightweight → **Enterprise SKU** parallel track. Maybe/Someday items: [TIER_D_PLAN.md §16](TIER_D_PLAN.md#16-maybe--someday-unplanned-backlog).

---

## 15. Next steps

1. ~~Resolve open decisions~~ — **locked above**  
2. ~~Approve W0 schema v5 field list~~ — **landed 2026-07-16** (`schemaVersion` 5)  
3. **Register Entra app + redirect URIs** — operator step for live Graph OAuth dogfood (code path ready)  
4. ~~Begin W0~~ — **W0 landed 2026-07-16**  
5. ~~Begin W1~~ — **W1 landed 2026-07-17** (TA-1 + TA-4 message actions, trash, keyboard shortcuts)  
6. ~~Begin W2~~ — **W2 landed 2026-07-17** (threading, filters, date groups, snooze, pin, swipes, virtual views)  
7. ~~Begin W3~~ — **W3 landed 2026-07-17** (sync profiles, retention, push, sync health, remote images phase 1)  
8. ~~Begin W5~~ — **W5 landed 2026-07-17** (desktop shell; [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) passed — operator; `.eml` ProgId deferred packaging)  
9. **Begin W6** — Notifications (unlocked 2026-07-17)  

---

*Tier scope documents remain valid as **what** to build; this document defines **how to order and bundle** for one V1 delivery.*
