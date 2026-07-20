# Tier C Implementation Plan

| Field | Value |
| --- | --- |
| Status | **W5 nearly complete / in progress** (2026-07-17) — TC-9 UI wiring landed; checklist + `.eml` association open |
| Scope | Power-user differentiation ([COMPETITIVE_ANALYSIS.md](COMPETITIVE_ANALYSIS.md) §4, Tier C) |
| Prerequisite | Tier A complete; most items synergize with Tier B |
| Last updated | 2026-07-17 (W5 desktop UI wiring landed — TC-9 nearly complete) |

Tier C is where ByteMail **wins** against Outlook, Aqua, and Spark for the target audience: privacy-conscious, local-first, technically literate users who want control without cloud AI lock-in.

---

## 1. Tier C scope

| # | Capability | Today | Target |
| --- | --- | --- | --- |
| C1 | **Sync profiles (full SPEC §8.2)** | **Landed (W3)** | Folder scope, body policy, attachment cap per profile |
| C2 | **Per-account retention** | **Landed (W3)** | Account overrides + profile assignment |
| C3 | **Windows desktop power (full)** | **Nearly complete (W5)** | Keymap, tray DI, find/print/EML/detach UI landed; `.eml` association + checklist open |
| C4 | **DB encryption at rest** | Opt-in backlog | SQLCipher + unlock UX |
| C5 | **Focus management UX** | Scorer + overrides in DB | Full override UI, domain/sender rules editor |
| C6 | **Sync transparency** | **Landed (W3)** | In-app job queue viewer, sync status per account |
| C7 | **Privacy controls (HTML)** | **Phase 1 landed (W3)** | Block remote images (default on); per-message load |
| C8 | **Notification granularity** | Basic TA-6 | Per-account mute, quiet hours, priority senders |
| C9 | **IMAP autoconfig** | Manual host entry | ISPDB / SRV discovery in add-account |
| C10 | **Schedule send** | — | Outbox `send_after` timestamp |
| C11 | **Find in message** | — | Ctrl+F in reading pane |
| C12 | **Export / print** | — | Save `.eml`, print message |
| C13 | **Widget depth** | List/counter/actions | Theme variants, per-folder widget config |
| C14 | **Network-aware sync** | **Landed (W3)** | WiFi vs mobile intervals; push on cellular opt-in |
| C15 | **Account diagnostics** | **Landed (W3)** | Per-account sync health merged into sync status sheet |

**Tier C complete when:** power users can tune sync/retention per account, encrypt the local DB, operate mail keyboard-only on Windows, inspect sync jobs, block remote images, schedule sends, and onboard IMAP without hand-typing server names.

---

## 2. Design principles

| Principle | Implication |
| --- | --- |
| **Control without clutter** | Advanced settings grouped; sane defaults match Tier A/B |
| **Local truth visible** | Show what SQLite has vs what provider owes |
| **No cloud dependency** | Focus, retention, templates stay on-device |
| **One settings architecture** | `AppSettings` + per-account `AccountSettings` blob — extend once |

---

## 3. Phase overview

```text
TC-0 Settings & profile schema v10 ──────────────────────────┐
                                                             │
TC-1 Sync profiles + per-account retention ◄── SPEC §8.2     │
                                                             │
TC-2 Network-aware sync policy ◄── sync_engine               │
                                                             │
TC-3 DB encryption ◄── parallel; touches database.dart once  │
                                                             │
TC-4 Focus override UI ◄── focus_override_registry           │
                                                             │
TC-5 Sync transparency UI ◄── jobs table (exists)            │
                                                             │
TC-6 HTML privacy controls ◄── html_email_body (touch once)  │
                                                             │
TC-7 Notification settings ◄── extend TA-6 NotificationSvc   │
                                                             │
TC-8 Autoconfig ◄── add_account_sheet + account_service      │
                                                             │
TC-9 Desktop power pack ◄── mail_workspace + desktop/        │
  keymap, tray native, multi-window, .eml, Ctrl+F, print      │
                                                             │
TC-10 Schedule send ◄── outbox schema extension              │
                                                             │
TC-11 Widget enhancements ◄── widget_snapshot_service        │
                                                             │
TC-12 Account health panel ◄── diagnostics_service           │
```

---

## 4. TC-0 — Settings & profile schema

**Goal:** Single migration for all Tier C configuration.

### Schema v10

| Table / column | Purpose |
| --- | --- |
| `sync_profiles` | `id`, `name`, `retention_days`, `folder_scope_json`, `body_policy`, `attachment_max_mb`, `is_default` |
| `accounts.sync_profile_id` | FK optional |
| `accounts.retention_days_override` | nullable int |
| `account_settings_json` | notification mute, push on cellular, etc. |
| `outbox.send_after` | nullable epoch ms (TC-10) |

### `AccountSettings` / `SyncProfile` Dart types

- `lib/settings/sync_profile.dart`
- Loaded by `AppSettingsCubit` + `AccountService`

### Exit criteria

- [ ] Migration v10 applies; defaults preserve current behavior
- [ ] One settings read path for account + profile merge

**Estimate:** 2–3 days

---

## 5. TC-1 — Sync profiles + per-account retention

**Status:** **Landed** (W3, 2026-07-17)

**Goal:** Full SPEC §8.2 beyond day counts.

### Sync profile knobs

| Knob | Implementation |
| --- | --- |
| Folder scope | `folder_scope_json`: `all` \| `inbox_sent` \| `[folderIds]` — bootstrap/incremental jobs skip out-of-scope folders |
| Body policy | `headers_only` \| `on_open` \| `proactive_recent` — controls `_ensureBodyCached` + sync prefetch |
| Attachment max MB | TA-3 attachment fetch respects profile |
| Retention days | `RetentionService.cleanup` uses profile or account override |

### UI

- Settings → Sync & Storage → Profiles (CRUD)
- `EditAccountSheet` → assign profile + retention override
- ROADMAP per-account retention **merged here**

### Exit criteria

- [x] Travel profile: 14-day retention, inbox-only, no proactive bodies
- [x] Pin + profile interaction tested (pins exempt)
- [x] Changing profile triggers optional cleanup job

**Estimate:** 5–7 days (actual: W3)  
**Depends on:** TC-0, Tier A TA-3 attachments for cap enforcement

---

## 6. TC-2 — Network-aware sync

**Status:** **Landed** (W3, 2026-07-17)

**Goal:** Aqua-style WiFi vs mobile policies.

### Policy

| Context | Behavior |
| --- | --- |
| WiFi / unmetered | Normal poll / IDLE (TB-10) |
| Cellular / metered | Longer poll when push disabled; **push on cellular when user enables** (see TB-10) |
| User override | Per-account “sync on mobile data” toggle |

### Implementation

- `connectivity_plus` package for network class
- `SyncEngine` reads policy before scheduling jobs
- Surface in `AccountSettings`

**Estimate:** 3–4 days (actual: W3)  
**Depends on:** TC-0, TB-10 for IDLE gating

---

## 7. TC-3 — DB encryption at rest

**Status:** **Landed** (W7, 2026-07-18) — SQLite3MultipleCiphers via `sqlite3` hooks; see [W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md).

**Goal:** Opt-in SQLCipher per locked ROADMAP decision.

### Work

| Piece | Detail |
| --- | --- |
| Library | `sqlcipher_flutter_libs` + Drift encrypted executor |
| Key | Passphrase or OS keychain (DPAPI / Android Keystore) |
| Unlock | Passphrase screen on cold start when enabled |
| Migration | Export → encrypt → import OR `sqlcipher_export` path — **spike first** |
| Attachments | Encrypt blob dir with same key when enabled |

### UX

- Settings → Privacy → Encrypt local database (irreversible warning)
- No key recovery — user must acknowledge

### Exit criteria

- [ ] Encrypted DB unreadable without key (file probe)
- [ ] Performance acceptable on 50k message test set
- [ ] Account wipe still works

**Estimate:** 7–10 days (migration risk)  
**Integration:** Run **before** large mail datasets in dogfood — see integration doc for ordering with schema v5–v10.

---

## 8. TC-4 — Focus override management UI

**Status:** **Landed** (W7, 2026-07-18) — `focus_rules_sheet.dart` + `deleteFocusRule`.

**Goal:** Make Focus scorer user-editable without SQL.

### UI

- Settings → Focus → per-account overrides list
- Add rule: sender / domain → Always Focused / Always Other
- Unified vs account scope per SPEC §8.3
- Bulk import deferred

### Wiring

- `FocusOverrideRegistry` already exists — expose CRUD in `AppSettingsCubit`
- Widget unread split respects enablement (existing)

**Estimate:** 3–4 days

---

## 9. TC-5 — Sync transparency

**Status:** **Landed** (W3, 2026-07-17) — merged with TC-12 in `sync_status_sheet.dart`

**Goal:** FairEmail-level trust with better UX.

### In-app sync panel

| View | Data source |
| --- | --- |
| Per-account status | Last successful job, last error, cursor age |
| Job queue | `jobs` table: pending/running/failed with type + timestamp |
| Actions | Retry failed, force incremental, cancel running (best-effort) |

### Diagnostics extension

- Existing redacted export + optional “include job summary”

**Estimate:** 4–5 days (actual: W3)  
**Touch:** `diagnostics_service.dart`, `sync_status_sheet.dart`

---

## 10. TC-6 — HTML privacy controls

**Status:** **Phase 1 landed** (W3, 2026-07-17)

**Goal:** FairEmail-style reading privacy — phased delivery.

### Phase 1 (V1 / W3) — **Landed**

| Setting | Behavior |
| --- | --- |
| Global toggle | Block remote images — default **on** (`blockRemoteImages: true`); user can allow globally in Appearance |
| Per-message | “Load images for this message” for current session |

### Phase 2 (post-v1)

| Setting | Behavior |
| --- | --- |
| Per-account block | Block images for specific accounts (e.g. public/exposed inbox) |
| Domain whitelist | Always load images from whitelisted domains (e.g. `amazon.com`) |

### Implementation

- **Single touch** `html_email_document.dart` + `html_email_body.dart`
- Sanitize before WebView load
- Schema extension: `image_allowlist_domains` in account settings JSON (post-v1)

**Estimate:** 4–5 days phase 1 (actual: W3); phase 2 post-v1  
**Synergy:** TB-12 rich HTML compose shares MIME/HTML pipeline

---

## 11. TC-7 — Notification granularity

**Goal:** Extend Tier A `NotificationService` — do not build twice.

### Settings

| Setting | Default |
| --- | --- |
| Global notifications | on |
| Per-account enabled | on |
| Quiet hours | off (time range) |
| Notify for starred only | off |

### Logic

- Filter in `NotificationService.onNewMail` before platform post
- Android channels per account (optional)

**Estimate:** 2–3 days  
**Depends on:** Tier A TA-6

---

## 12. TC-8 — IMAP autoconfig

**Goal:** SPEC §6.5 — reduce manual server entry.

### Flow

1. User enters email address
2. Fetch Mozilla ISPDB / autoconfig XML / DNS SRV
3. Pre-fill IMAP/SMTP host, port, security
4. User confirms + auth (OAuth or password)

### Packages / approach

- HTTP fetch to `https://autoconfig.thunderbird.net/v1.1/{domain}` or Google autoconfig
- Fallback: provider hint table for gmail.com, outlook.com, etc.

### Exit criteria

- [ ] Common providers autofill correctly
- [ ] Manual override still available
- [ ] **Same `AddAccountSheet` refactor as TA-5 OAuth** — one onboarding pass

**Estimate:** 4–5 days  
**Integration:** Merge with TA-5 in add-account rewrite — see integration doc.

---

## 13. TC-9 — Windows desktop power pack

**Status:** **Nearly complete / in progress** (W5, 2026-07-17)

**Goal:** SPEC §7.6 complete — differentiate vs browser mail.

### Deliverables

| Feature | Detail |
| --- | --- |
| **Full keymap** | Document + implement: j/k, e archive, # delete, r reply, a reply-all, f forward, u mark unread, g go to folder, / search, ? help overlay |
| **DEF-001 fix** | `HardwareKeyboard` + `Focus` policy — workspace shortcuts work without quick-reply focus |
| **Native system tray** | `window_manager` + tray icon; minimize preference wired |
| **Detached message window** | Open message in **one** secondary window (V1 scope) |
| **Multi-window (unlimited)** | **Post-v1** — see ROADMAP |
| **Ctrl+F find** | In-message text search bar in reading pane |
| **Print** | `printing` package or platform print dialog |
| **`.eml` associate** | Windows file type registration; open → import to reading pane |
| **Schedule send UI** | If TC-10 done — compose picker |

### Exit criteria

- [x] Keymap help overlay lists all bindings (`keymap_help_sheet.dart`)
- [x] DEF-001 — workspace shortcuts without text-field focus ([DEFECTS.md](DEFECTS.md) closed)
- [x] Tray minimize preference wired (`minimizeToTray` → `WindowsDesktopController` via `app.dart`)
- [ ] Tray minimize works on Windows release build — [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md)
- [x] `.eml` opens via launch argument + preview sheet
- [x] Title-bar **Open EML…** + reading-pane **Save as EML** (`message_file_service.dart`)
- [ ] Windows `.eml` file association (Explorer double-click — installer ProgId not in repo)
- [x] Detached message window opens from reading-pane overflow (`WindowsDetachedMessageWindowController`)
- [x] Ctrl+F find bar in reading pane (`findInMessageRequested` → plain + HTML find)
- [x] Print from reading-pane overflow (`message_print_service.dart`)

**Estimate:** 8–12 days (partial — 2026-07-17)  
**Layout note:** TB-9 / W5 layout refactor reserves extension points for post-v1 unlimited multi-window.

---

## 14. TC-10 — Schedule send

**Goal:** Spark-style delayed outbox delivery.

### Model

- `outbox.send_after` epoch ms; null = immediate
- `send_outbox` job skips until `now >= send_after`
- UI: compose datetime picker; outbox list shows scheduled time
- Offline: schedules locally; sends when time + network satisfied

**Estimate:** 3–4 days  
**Depends on:** TC-0 outbox column, Tier A outbox

---

## 15. TC-11 — Widget enhancements

**Goal:** Deepen Android widget advantage.

| Enhancement | Detail |
| --- | --- |
| Theme variants | Light/dark snapshot tokens in Kotlin layout |
| Folder-scoped widget | Config: pick account + folder |
| Focus split counter | Focused vs Other unread when enabled |
| Tap actions | Open specific folder deep link |

**Estimate:** 4–5 days

---

## 16. TC-12 — Account health panel

**Status:** **Landed** (W3, 2026-07-17) — merged into TC-5 sync status sheet (Accounts tab)

**Goal:** Per-account ops without full diagnostics export.

- Last sync time, last error, queued jobs count, credential status
- Buttons: re-auth, force sync, wipe (link existing dialog)
- Surface in `ManageAccountsSheet` detail row

**Estimate:** 2–3 days (actual: W3, merged with TC-5)  
**Synergy:** TC-5 sync panel — merged into one “Account & Sync” settings area

---

## 17. Testing matrix

| Phase | Focus |
| --- | --- |
| TC-1 | Profile folder scope skips sync; retention per account |
| TC-3 | Encrypt/migrate/open; wipe encrypted db |
| TC-6 | Remote images blocked; allowlist works |
| TC-8 | Autoconfig fixtures for major domains |
| TC-9 | Keymap integration test; manual Windows tray |
| TC-10 | Scheduled send fires after delay |

---

## 18. Schedule sketch (after Tier A + B core)

| Week | Focus |
| --- | --- |
| 1 | TC-0 + TC-1 sync profiles |
| 2 | TC-5 sync UI + TC-12 health + TC-4 focus UI |
| 3 | TC-6 privacy + TC-7 notifications + TC-8 autoconfig |
| 4 | TC-9 desktop pack (split across 2 weeks if needed) |
| 5 | TC-3 encryption spike + TC-10 schedule send |
| 6 | TC-11 widgets + TC-2 network policy |

---

## 19. Locked decisions (2026-07-16)

| # | Question | Locked choice |
| --- | --- | --- |
| 1 | DB encryption timing | After schema freeze; optional W7 |
| 2 | Remote images | **V1:** global toggle. **Post-v1:** per-account block + domain whitelist |
| 3 | Multi-window | **V1:** single detached window. **Post-v1:** unlimited desktop windows |
| 4 | Sync UI | Merge TC-5 + TC-12 |
| 5 | Schedule send | Local outbox delay only |

*Full list: [V1_TIER_INTEGRATION.md §12](V1_TIER_INTEGRATION.md#12-locked-decisions-2026-07-16).*

---

*See [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md) for unified V1 build ordering.*
