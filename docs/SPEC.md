# ByteMail Technical Specification

| Field | Value |
| --- | --- |
| Document | Technical Specification & Architecture Blueprint |
| Version | 1.4 |
| Status | Draft |
| Last updated | 2026-07-14 |

---

## 1. Overview

ByteMail is a local-first email client for Windows and Android, built with Flutter (Dart). The UI reads exclusively from a local SQLite cache. A background sync engine updates that cache over Microsoft Graph (Outlook/Exchange) or IMAP/SMTP (Google and independent accounts), so transient network failures do not block reading or composing against already-synced mail.

### 1.1 Goals

- Deliver one Flutter codebase with native performance on Windows (x86/x64) and Android (ARM).
- Keep the UI responsive by confining sync, protocol I/O, and MIME work to background Dart Isolates.
- Support fast local search via SQLite FTS5, with optional on-demand remote archive search.
- Provide a multi-account workspace: unified inbox and per-account isolation.
- Support reliable offline compose/send via a durable outbox.
- Expose Android home-screen widgets that read local storage without launching the full Flutter UI.
- Expose desktop power ergonomics on Windows (keyboard-first navigation, multi-window, trays/toasts where specified).

### 1.2 Non-goals (v1.0)

- iOS / macOS / Linux clients.
- Full desktop widget parity on Windows (Android widgets only in v1; Windows may use tray/toast affordances only).
- POP3 as a production protocol in v1 (schema readiness only; see §5.2 and §12).
- Full contacts and calendar (CardDAV/CalDAV or provider-native equivalents) as a product surface — planned for a future version; explicitly out of scope for v1 (see §12).
- Exchange ActiveSync (EAS), full MAPI, or proprietary Outlook offline protocols outside Graph.
- End-to-end PGP or S/MIME unless explicitly added in a later milestone.
- Server-side ByteMail hosting or ByteMail-operated mail servers.
- Built-in cloud AI drafting, summarization, or cloud-side ranking (on-device scoring hooks may exist; see §8.3).
- Replacing provider web UIs for files or non-mail productivity surfaces.

---

## 2. Scope

### 2.1 In scope (v1.0)

| Area | Summary |
| --- | --- |
| Platforms | Windows desktop; Android phone/tablet |
| Accounts | Microsoft (Outlook/Exchange via Graph); Google and independent IMAP/SMTP |
| Onboarding | Provider detection / autoconfig; Graph OAuth; Google OAuth and IMAP app-password fallback |
| Auth | OAuth2 via a unified identity manager; tokens in `flutter_secure_storage` |
| Storage | Local SQLite + FTS5; local-first read path; optional encrypted-at-rest for desktop DB |
| Sync | Job-queue sync engine with durable cursors; Isolates for I/O and MIME |
| Protocols | Capability-flagged `MailProvider` adapters (Graph vs IMAP/SMTP) |
| Outbox | Offline compose/send with durable queue and conflict policy |
| Bodies / attachments | Headers+snippet on sync; body on open; attachments on demand; size limits in sync profiles |
| UI | Unified inbox, per-account views, adaptive layouts, keyboard-first desktop UX; themes + density settings |
| Appearance | Theme pack (Light, Solarized Light, Dark jewel-tone default, Black, Solarized Dark); account color controls; Calm default density with Compact option |
| Search | Local FTS5 as-you-type; remote bridge with documented merge/expiry contract |
| Retention | Device-configurable retention windows plus sync profiles (folders, bodies, pin rules) |
| Focus | Optional Focused/Other (per-account + separate Unified setting); rule-based scorer + overrides + pluggable seam + visual focus layout |
| Widgets | Android: list, counter, and action-matrix via snapshot table / Kotlin (no Flutter wake for badges) |
| Ops | Local diagnostics log exportable for support |

### 2.2 Out of scope (v1.0)

See §1.2. Explicit deferrals protect v1 timeline: POP3 runtime, iOS, full contacts/calendar, EAS, PGP/S/MIME, cloud AI. Contacts and calendar are intentional follow-on product milestones, not abandoned scope.

---

## 3. Platforms & Performance Targets

| Target | Requirement |
| --- | --- |
| Windows | Flutter desktop; x86/x64 |
| Android | Flutter mobile; ARM |
| UI responsiveness | Aim for smooth 60 fps interaction during normal local browsing; sync and MIME must not run on the UI isolate |
| Offline read | Previously synced messages, folders, and search results remain available when the network is unavailable |
| Offline send | Compose and queue sends when offline; retry per outbox policy (§8.5) |
| Network errors | Transient connectivity failures must not surface blocking “connection lost” flows that prevent use of the local cache |
| Local search latency | Typing into search SHOULD keep local result updates within ~100 ms p95 after debounce for typical inbox sizes (measure in implementation; tune debounce/index) |
| Cold start | First paint from local DB without waiting for a network round-trip |
| Sync catch-up | After flaky connectivity, incremental sync resumes from durable cursors without full mailbox rebuild unless UIDVALIDITY/delta reset requires it |

**Assumption:** “Native performance” means shipping as a compiled Flutter app (not a WebView wrapper), not a contractual CPU/FPS SLA beyond the responsiveness targets above.

### 3.1 Windows desktop surface (v1)

- System tray / minimize-to-tray behavior (exact default TBD in UX design; must be configurable).
- Window sizing persistence and comfortable multi-monitor split-pane use.
- Optional open/associate of `.eml` files into the reading/compose flow.
- Toast / OS notification affordances for new mail when the app is backgrounded (not home-screen widgets).
- Keyboard-first navigation as a first-class Windows requirement (§7.5).

### 3.2 Success metrics (implementation gates)

| Metric | Intent |
| --- | --- |
| Local search p95 | Fast FTS path under representative datasets |
| Time-to-first-paint | Local cache usable before sync completes |
| Sync catch-up time | Bounded recovery after network restoration on mobile |
| Outbox eventual send | Queued messages succeed or surface actionable failure |
| Widget freshness | Android badges/list reflect last successful sync commit without opening Flutter UI |

---

## 4. Architecture

### 4.1 Stack

| Layer | Choice | Notes |
| --- | --- | --- |
| UI | Flutter (Dart) | Single codebase for Windows and Android |
| Domain modules | Dart (see §4.2) | Auth, adapters, sync jobs, MIME, repository, FTS, UI state |
| Core / sync runtime | Dart Isolates | Sync I/O and MIME off the UI isolate; Isolates are a runtime detail, not the module boundary |
| Database | SQLite + FTS5 | Local index and full-text search |
| Secure storage | `flutter_secure_storage` | OAuth tokens and related secrets |
| Android widgets | `home_widget` + Kotlin bridge | Widgets read snapshot/DB path without waking full Flutter UI |

### 4.2 Module boundaries

Isolates MUST NOT be the primary architectural cut. The codebase SHALL organize around these modules:

| Module | Responsibility |
| --- | --- |
| Account / Auth | Account lifecycle; OAuth2 Identity Manager; token refresh; re-auth |
| Protocol adapters | `MailProvider` implementations (Graph, IMAP/SMTP); capability flags |
| Sync engine | Job queue, backoff, durable cursors, conflict application |
| MIME pipeline | Parse/serialize messages and attachments off the UI isolate |
| Repository | SQLite access; transactions; change notifications |
| Query / FTS | Local search; remote-bridge result ingestion hooks |
| Focus scoring | Rule-based scorer + override registry; pluggable interface |
| UI state | Presentation models fed only from local repository/query layer |
| Diagnostics | Structured local logs for sync/auth failures |

Protocol and widget code MUST NOT tightly couple to Flutter widgets; Windows vs Android differences stay at platform adapters.

### 4.3 Local-first data flow

```text
[ UI isolate ] --read only--> [ Repository / SQLite (+ FTS5) ] <--write-- [ Sync Isolates ]
                                      ^
                                      |
                    [ Widget snapshot table ] <-- Kotlin / home_widget (Android)
```

1. The UI (main isolate) reads exclusively from the local SQLite cache via the Repository.
2. Background sync Isolates execute jobs: fetch/push mail, parse MIME, write to SQLite, update cursors.
3. UI subscribes to DB change streams or a thin `MailStore` notifier — never to raw isolate UI callbacks that build widgets.
4. Android widgets read a small exported snapshot (preferred) or a constrained DB read path via Kotlin, without starting the Flutter engine for badge/list refreshes.

### 4.4 Isolate communication boundary

- Use a typed command/event bus (or equivalent isolate messaging package) between UI and sync workers.
- Commands: e.g. `EnqueueSync`, `EnqueueSend`, `RunRemoteSearch`, `ApplyRetentionCleanup`.
- Events: e.g. `SyncProgress`, `AccountNeedsReauth`, `OutboxItemFailed`.
- Sync Isolates MUST NOT push Flutter widgets or BuildContexts.

### 4.5 Protocol adapter interface (`MailProvider`)

Graph and IMAP diverge on flags, folders, deltas, push, and search. All providers MUST implement a shared adapter surface with capability flags to avoid growing `if (microsoft)` branches.

**Illustrative surface**

- `listFolders`, `deltaSync` / incremental sync, `searchRemote`, `send`, `watch` / push registration (if supported)
- Capability flags examples: `supportsServerSearch`, `supportsPush`, `supportsPartialBody`, `supportsFlag*`, `supportsMove`

Adapters translate provider ids into local stable identities and surface capability-driven UI (e.g. hide Remote Bridge when `supportsServerSearch` is false).

### 4.6 Sync job queue and durable cursors

Sync work MUST be modeled as idempotent jobs persisted in SQLite, not only in-memory loops.

| Job type (illustrative) | Purpose |
| --- | --- |
| `bootstrap` | Initial account hierarchy and recent mail |
| `incremental` | Delta / UID-based catch-up |
| `full_folder` | Targeted folder rebuild after invalidation |
| `remote_search` | On-demand archive search + ingest |
| `send_outbox` | Deliver queued outbound messages |
| `retention_cleanup` | Enforce retention / sync-profile pruning |

**Cursors**

- Per-account (and per-folder where required) durable cursors: Graph delta tokens; IMAP UID + UIDVALIDITY (and related markers).
- Process kill / OS memory reclaim MUST allow resume from persisted job + cursor state without silent data loss.
- UIDVALIDITY or delta reset MUST trigger a defined rebuild path and a diagnostics log entry.

### 4.7 Hybrid connectivity engine

| Provider class | Transport | Rationale |
| --- | --- | --- |
| Microsoft (Outlook / Exchange Online via Graph) | Microsoft Graph over HTTPS | Prefer Graph over IMAP for Microsoft accounts for reliability under flaky mobile networks and Graph token refresh |
| Google & independent | IMAP + SMTP (TLS) | Standard secure mail channels |
| Auth (all OAuth-capable) | Unified OAuth2 Identity Manager | Tokens stored via `flutter_secure_storage` |

**Assumption:** “Microsoft accounts” in v1 means accounts that can authenticate to Microsoft Graph for mail. Legacy on-prem Exchange without Graph is out of scope for v1 unless product revises §11.

### 4.8 Observability

- Maintain a local diagnostics log (ring buffer or capped files) covering: sync errors, UIDVALIDITY/delta resets, token refresh failures, outbox permanent failures, remote search failures.
- User-exportable diagnostics package for support (redact tokens and message bodies by default; include account ids, provider type, job ids, timestamps, error codes).

---

## 5. Data Model Notes

Exact DDL may evolve; the following entities are required.

### 5.1 Required concepts / tables

| Concept | Purpose |
| --- | --- |
| `accounts` | Provider type, display identity, color, credentials reference, capabilities cache |
| `folders` | Per-account folder tree; unified inbox is a view, not a server mailbox |
| `messages` | Headers, snippet, body refs, flags, folder/account FKs, provider ids |
| `fts` | FTS5 virtual table(s): at least subject, from/to, indexed body text |
| `rules` / focus overrides | Always Focus / Always Other by sender and/or domain (scoped per account or global as designed) |
| focus preferences | `focus_enabled` for Unified workspace + `focus_enabled` per account (§8.3) |
| `outbox` | Pending sends/drafts-in-flight with retry metadata |
| `sync_state` / jobs / cursors | Job queue rows and durable sync cursors |
| `storage_type` | Discriminator for synced vs future local-only (§5.2) |
| `widget_snapshots` | Denormalized rows for Android widget process reads |
| retention / sync profile settings | Device retention window + folder/body/attachment policy |

### 5.2 `storage_type` flag

Schemas MUST include a `storage_type` (or equivalent) discriminator so that a future desktop POP3 “download-and-delete / local-only” mode can be added without a breaking redesign.

| Value (illustrative) | Meaning |
| --- | --- |
| `synced` | Normal IMAP/Graph mailbox mirror |
| `local_only` | Reserved for future POP3 / local-only storage |

v1.0 does not implement POP3 runtime behavior; only schema readiness is required.

### 5.3 Body and attachment strategy

| Stage | Default policy |
| --- | --- |
| Sync | Headers + snippet (and flags); optional partial body only if provider/capability and sync profile allow |
| Open message | Fetch and cache full body on demand |
| Attachments | Fetch on demand; respect per-profile max size; may omit from travel profiles |
| Retention | Prune bodies/attachments/messages per retention + sync profile; pinned threads/accounts exempt |

### 5.4 Security-sensitive data

- OAuth refresh/access tokens MUST NOT be stored in plain SQLite.
- Tokens and other secrets MUST use `flutter_secure_storage` (or platform equivalent backing stores it wraps).
- Desktop SHOULD support an encrypted-at-rest option for the mail DB (SQLCipher or OS-backed equivalent); exact mechanism is an implementation decision.
- Certificate / TLS policy for IMAP MUST be documented (system trust store by default; pinning only if product requires).
- Account removal MUST wipe local mail rows, FTS, widget snapshots, outbox items, and secure tokens for that account.

---

## 6. Protocols & Authentication

### 6.1 Microsoft Graph

- Use Graph mail endpoints for list/sync/send (exact endpoint set TBD in design notes).
- Handle token refresh without dropping the user into repeated interactive login for normal expiry when a valid refresh token exists.
- Map Graph message/folder ids into the local schema with stable identity for incremental sync.
- Push (subscriptions / change notifications) is optional for v1; if not implemented, use poll-based incremental jobs with backoff (§6.4).

### 6.2 IMAP / SMTP

- Secure channels only (TLS).
- Support Google and arbitrary independent IMAP/SMTP providers that expose standard OAuth2 or app-password auth as implemented in v1.
- Incremental sync MUST track UID + UIDVALIDITY; tolerate flaky mobile networks with backoff/retry and durable jobs.
- IMAP IDLE MAY be used when available; otherwise poll. Capability flag `supportsPush` reflects effective watch ability.

### 6.3 OAuth2 Identity Manager

- Single abstraction over provider OAuth flows (system browser / loopback / platform patterns as appropriate per OS).
- Store tokens securely; expose refresh to sync Isolates without blocking the UI.
- Support account add/remove and token invalidation (force re-auth) with clear UI when sync cannot proceed.

### 6.4 Push vs poll (v1 policy)

| Path | v1 expectation |
| --- | --- |
| Graph | Prefer subscriptions if cost/complexity allows; otherwise incremental poll jobs |
| IMAP | IDLE when practical on desktop; bounded poll on Android for battery |
| Widgets | Refresh from local snapshot after sync commit — not via waking Flutter on a timer |

Document chosen intervals and backoff in a sync design note; expose conservative defaults and advanced settings if needed.

### 6.5 Account onboarding & provider detection

- Autoconfig for IMAP/SMTP where possible (e.g. Mozilla ISPDB / DNS SRV-style discovery).
- Microsoft: Graph OAuth via system browser (or platform-equivalent secure flow).
- Google: OAuth when scopes/policies allow; IMAP app-password (or documented alternative) fallback when OAuth is unavailable or blocked.
- Detect provider class early and select the correct `MailProvider` adapter + capability set.
- Clear error states for wrong password, blocked OAuth, missing app password, and unreachable endpoints.

---

## 7. UI / UX Requirements

### 7.1 Multi-tenant navigation

- Sidebar navigation MUST allow switching between:
  - **Unified Inbox** — aggregated view across accounts.
  - **Individual Account Views** — fully isolated per-account context (folders and messages scoped to that account).

### 7.2 Visual account anchors

- In the unified view, message list items MUST be subtly color-coded (or equivalently marked) so the source account is identifiable at a glance.
- Colors MUST be distinguishable; support automatic palette assignment with **user override** (per-account color control in settings).
- Default account accents SHOULD draw from the active theme’s jewel/accent ramp so they remain legible on that theme’s ground.

### 7.3 Unified inbox merge rules

| Topic | Requirement |
| --- | --- |
| Deduping | Prefer Message-ID–based dedupe across aliases/accounts when both copies are present; document behavior when only one side exists |
| Sort | Default date-desc; optional Focus-aware ordering MUST NOT hide Other mail outside the Focus filter |
| Reply routing | Reply/Reply-All MUST use the account that owns the selected message (or the user’s explicitly chosen From identity); color anchors alone are insufficient |

### 7.4 Adaptive layouts

| Mode | Layout |
| --- | --- |
| Portrait (mobile) | Single-pane list/detail with a swipe-dismissible drawer for folders; row density follows View settings (§7.8) |
| Landscape (mobile & desktop) | Fixed split-pane (list + reading pane) with a persistent sidebar toggle |

- Sidebar open/closed (and related layout prefs) MUST persist via local storage and restore on launch.

### 7.5 Visual Focus (layout)

- A gesture or toggle MUST collapse the sidebar and folder chrome to maximize reading/composing space while keeping the top app bar accessible.

### 7.6 Windows desktop power features (v1)

- Keyboard-first list/reading navigation (j/k or arrow paradigms, archive/delete/star shortcuts — exact keymap in UX spec).
- Multi-window message reading where the platform allows.
- Quick reply from reading pane.
- Local snooze (client-side resurfacing) in v1; server-side snooze if/when Graph (or provider) supports it cleanly.
- Templates / canned responses stored locally.

These are differentiators versus browser Gmail and are in scope for Windows v1; Android may implement a subset.

### 7.7 Themes & color settings

Appearance is user-configurable. The **Dark** theme matches the approved jewel-tone mockup direction (deep indigo ground; teal / amethyst / azure / emerald accents; amber and coral for status and urgency).

**Built-in themes (v1)**

| Theme id | Intent |
| --- | --- |
| `light` | Light surfaces; restrained jewel accents on pale grounds |
| `solarized_light` | Solarized Light palette |
| `dark` | **Default.** Dark jewel-tone shell from the visual mockups |
| `black` | Near-true black / OLED-leaning; accents retained but higher contrast |
| `solarized_dark` | Solarized Dark palette |

Requirements:

- Theme selection lives under Settings → Appearance (or equivalent).
- Theme choice is per-device/install and MUST persist.
- Widgets and system chrome SHOULD follow the active theme where the platform allows (Android widgets may use a simplified snapshot of theme tokens).
- Implementation SHOULD use a tokenized color system (background, panel, text, muted, accent ramp, semantic success/warn/danger) so new themes are data, not one-off widgets.
- Account color controls remain available in all themes (§7.2).

### 7.8 View density settings

Visual direction default is **Calm** (more whitespace, softer list treatment, reading-pane emphasis), as validated in mockups. Users MUST be able to switch to a more compact density for smaller devices (e.g. travel phones) without changing theme.

| Density | Intent |
| --- | --- |
| `calm` | **Default.** Larger type, more row padding, card-like list separation, reading pane emphasis |
| `compact` | Tighter rows, denser chrome, Outlook-like information density for constrained viewports |

Requirements:

- Density lives under Settings → View (or Appearance → Density).
- Density is independent of theme (any theme × calm/compact).
- Density preference is per-device/install (so a large home desktop can stay Calm while a travel phone uses Compact).
- Optional later: automatic density hints from window size / shortest side — not required for v1 if manual control is clear.

**Product note:** Primary household devices are expected to have large screen real estate (Calm default); Compact exists especially for smaller phones used while traveling.
## 8. Feature Requirements

### 8.1 Tiered search

**Local Blitz**

- Search bar input queries the local SQLite FTS5 index.
- Results SHOULD update as the user types (debounced as needed for performance).
- Query path MUST NOT require network access.

**Remote Bridge — UX contract**

- UI MUST expose a clear on-demand control (e.g. “Search older emails on the server”).
- Only show when the active account/provider advertises `supportsServerSearch`.
- MUST document and implement:
  - Which folders are searched (default: all mail / archive equivalent per provider).
  - How results merge into local DB + FTS (upsert by provider id / Message-ID).
  - Whether remotely fetched hits respect retention (default: yes) or receive a short “search pin” grace period.
  - Progress UX with partial results streaming into the list as pages arrive.
- Runs as a background `remote_search` job; failures surface non-blocking errors and diagnostics entries.

**Acceptance criteria (local search)**

- Given synced messages containing a distinctive token, typing that token returns matching results from SQLite without network.
- Search remains usable offline for indexed local content.

**Acceptance criteria (remote bridge)**

- Given older mail not present locally, invoking remote search eventually surfaces matches and persists them when the provider call succeeds.
- Partial results appear before the full remote query completes when the provider returns pages.

### 8.2 Variable retention dials & sync profiles

**Retention dials**

- Each device/install exposes a configurable local retention window.
- A background cleanup job enforces the window by removing or pruning locally cached message data older than the configured retention (provider mailbox is not deleted solely by local retention).
- Example profiles (guidance, not hard-coded products):
  - Large daily-driver device: on the order of 180–365 days local cache.
  - Smaller travel device: on the order of 14–30 days local cache.

**Sync profiles (beyond day counts)**

Device sync profiles MUST also configure:

| Knob | Examples |
| --- | --- |
| Folder scope | All folders vs Inbox+Sent (and user-selected folders) |
| Body policy | Headers+snippet only vs cache bodies on open vs proactive body cache |
| Attachment max size | Skip caching attachments above N MB |
| Pins | Pin thread, sender, or account to retain beyond the dial |

**Acceptance criteria**

- Changing retention/profile and allowing cleanup to run reduces local stored mail volume consistent with the new policy.
- Cleanup does not revoke provider account access or wipe account configuration.
- Pinned content survives cleanup until unpinned.

### 8.3 Dual-layer Focus Mode (optional)

Focused/Other is a **user option**, not a mandatory inbox mode. Some accounts benefit from it; others do not (e.g. purely transactional or newsletter-heavy mailboxes).

**Enablement model**

| Context | Setting | Behavior |
| --- | --- | --- |
| Individual account view | Per-account `focus_enabled` | When **on**, show Focused/Other filter and apply scoring + overrides for that account. When **off**, show a single unfiltered inbox chronologically (no Focused/Other chrome). |
| Unified Inbox | Separate Unified `focus_enabled` | Unified uses **only** the Unified setting. Per-account Focus on/off does **not** affect Unified. When Unified Focus is **on**, Focused/Other applies across the aggregated list; when **off**, Unified is a plain merged inbox. |

- Defaults: `focus_enabled = true` for Unified and for new accounts (user can disable). Exact defaults may be confirmed in UX.
- Changing enablement MUST persist per device/install (or sync later if settings sync exists; v1 local is fine).
- Overrides registry and scorer MAY still compute scores while disabled (for instant re-enable), but the UI MUST NOT require Focus interaction when the feature is off for the current context.

**Algorithmic filter (when enabled)**

- One-tap control filters the inbox between **Focused** (likely human / contact mail) and **Other** (automated mail, receipts, lists).
- v1 scorer MUST be rule/heuristic-based using signals such as: `List-Id`, `Precedence`, `Auto-Submitted`, noreply-style addresses, bulk headers, and contact / prior-correspondence signals.
- Implement Focus as a **pluggable scorer interface** so an on-device ML model can replace or augment heuristics later without rewriting UI, widget unread math, or override application.

**Manual override registry**

- Local rules allow flagging specific domains or senders as Always Focus or Always Other.
- Manual rules MUST override the algorithmic baseline for matching messages.
- Overrides SHOULD be scoped sensibly (per-account and/or apply-when-message-belongs-to-account) so disabling Focus on one account does not invent confusing cross-account behavior.

**Visual Focus (layout)**

- See §7.5 (layout collapse for reading/composing). Independent of Focused/Other enablement.

**Widgets**

- Split Focused/Other unread counts are available when the widget’s configured source has Focus enabled (Unified widget → Unified setting; single-account widget → that account’s setting). Otherwise show a single unread total.

**Acceptance criteria**

- Toggling Focused/Other (when enabled) changes the visible message set without leaving the current account/unified context.
- A domain set to Always Other never appears in Focused while that rule remains active and Focus is enabled.
- Disabling Focus for an account removes Focused/Other filtering/chrome in that account view only.
- Disabling Focus for Unified shows an unfiltered unified list even if individual accounts still have Focus enabled.
- Enabling Focus on Unified applies Focused/Other to the unified list even if some underlying accounts have Focus disabled.
- Counter widgets respect the enablement rule above.

### 8.4 Android home screen widgets

Managed via Kotlin + `home_widget`, reading local snapshot/DB storage **without** starting the Flutter UI engine for routine unread/list updates:

| Widget | Behavior |
| --- | --- |
| Dynamic List | Scrollable preview; configurable for Unified Inbox or a single account |
| Counter | Dense 1×1 (or compact) unread badges; aggregated and/or split Focused vs Other counts |
| Action Matrix | Quick actions: compose, global search, force background sync |

**Update model**

- Flutter/sync commits SHOULD update `widget_snapshots` (or equivalent) transactionally with mail writes.
- Widget process reads snapshots; MUST NOT poll-wake the Flutter engine solely to refresh badges.
- Action Matrix entry points MAY launch Flutter for compose/search UI or enqueue a sync job for force-refresh.

**Acceptance criteria**

- List and counter widgets update from local data after sync writes without requiring the Flutter activity to be foregrounded.
- Action Matrix compose/search/sync entry points launch the appropriate in-app destination or trigger background sync as specified.

### 8.5 Offline compose, outbox, and conflicts

**Outbox**

- Compose MUST work offline; attachments may be added while offline if stored locally.
- Send operations enqueue `outbox` rows; `send_outbox` jobs deliver when network and auth allow.
- UI shows clear states: queued, sending, sent, failed (actionable), needs re-auth.

**Conflict / race policy (v1)**

| Operation | Policy |
| --- | --- |
| Flags / read / star | Last-write-wins with server acknowledgement; surface sync error if server rejects |
| Move / delete | Optimistic local apply; reconcile to server; on conflict prefer server truth after re-fetch and notify user if local view changed |
| Send | At-least-once delivery attempt with idempotency keys where provider supports; prevent duplicate sends on retry via client-generated Message-ID |

**Acceptance criteria**

- User can compose and queue a send in airplane mode; on reconnect the message sends or fails with an actionable error.
- Kill/relaunch during queued send does not lose the outbox item.

---

## 9. Security & Privacy

- Tokens only in secure storage (§5.4).
- Optional desktop DB encryption at rest.
- Document TLS trust behavior for IMAP.
- Diagnostics export redacts secrets and default message bodies.
- Account wipe clears DB rows, FTS, snapshots, outbox, and tokens.
- OAuth scopes MUST follow least privilege for mail send/receive as required by each provider.

---

## 10. Dependencies (known)

| Dependency | Role |
| --- | --- |
| Flutter / Dart | App framework and language |
| SQLite + FTS5 | Local persistence and search |
| `flutter_secure_storage` | Secret/token storage |
| `home_widget` (+ Kotlin) | Android home screen widgets |
| Microsoft Graph API | Microsoft account mail |
| IMAP / SMTP libraries (TBD) | Non-Microsoft providers |
| Autoconfig sources (TBD) | ISPDB / DNS discovery for onboarding |
| Optional SQLCipher (or equiv.) | Desktop DB encryption at rest |

Concrete package versions and IMAP client library selection are left to implementation planning.

---

## 11. Open Questions & Assumptions

### 11.1 Assumptions baked into this draft

1. Windows + Android only for v1.
2. Microsoft mail goes through Graph, not IMAP; non-Graph on-prem Exchange is out of scope for v1.
3. Unified Inbox is a client-side aggregation, not a server-side mailbox.
4. Local retention prunes the device cache only; it does not imply server-side delete.
5. Focus v1 is heuristic/rule-based with a pluggable scorer seam for future on-device ML; Focused/Other is optional per account, with a separate Unified enablement that does not inherit account settings.
6. Absolute marketing claims from earlier drafts (e.g. “guaranteeing 60 fps”, “entirely eliminating” network errors) are restated as measurable UX/architecture requirements in §§3–4.
7. Architectural suggestions from design review (module boundaries, job queue, outbox, sync profiles, widget snapshots, desktop power features, observability) are normative for v1 unless demoted in a later revision.
8. Full contacts and calendar are planned for a future version; they remain non-goals for v1.
9. Default appearance is Dark jewel-tone theme + Calm density; Compact density and alternate themes (Light, Solarized Light/Dark, Black) are first-class settings.
10. Account accent colors are user-controllable in addition to automatic assignment.

### 11.2 Open questions for product / eng

1. **Auth coverage:** Which independent IMAP providers get first-class OAuth vs app-password only in v1?
2. **Google auth path:** Confirm OAuth scopes strategy vs app-password fallback priority for Google accounts.
3. **Graph push:** Ship Graph change notifications in v1 or poll-only?
4. **DB encryption default:** Opt-in vs default-on for Windows encrypted-at-rest?
5. **Snooze:** Local-only for v1 on all platforms, or Graph-backed where available?
6. **Focus heuristics:** Finalize the v1 signal list and how false positives are monitored/tuned.
7. **Sync cadence:** Default poll intervals, IDLE usage, and Android battery constraints — publish in a sync design note.
8. **Account color assignment:** Confirm UX for picker vs curated swatches only.
9. **Theme completeness:** Confirm widget theming depth on Android for all five themes in v1 vs Dark+Black first.
10. **Multi-account limits:** Soft/hard cap on concurrent accounts per install?
11. **Licensing / branding:** Public product name confirmed as “ByteMail”?

---

## 12. Future Work

### 12.1 Planned: contacts & calendar (post-v1)

Full contacts and calendar are planned for a future version after the mail client is solid. v1 MUST NOT implement these as product features, but architecture SHOULD avoid painting the corner:

- Prefer account/identity models that can later attach contact and calendar providers (Graph, CardDAV/CalDAV, or Google equivalents) without breaking mail schemas.
- Do not treat the local address book or calendar store as required for v1 send/receive (optional local recipient suggestions from recent mail headers remain acceptable).

| Future surface | Intent |
| --- | --- |
| Contacts | Full contact sync/edit; richer Focus/contact graph signals |
| Calendar | Full calendar sync, agenda views, and meeting-related mail affordances |

Exact protocol mix (Graph vs CardDAV/CalDAV vs Google APIs) is deferred to that version’s design.

### 12.2 Other future work

- POP3 local-only / download-and-delete on desktop, enabled by `storage_type`.
- Additional platforms (iOS, macOS, Linux) if product priority expands.
- Richer Exchange scenarios not covered by Graph; EAS only if explicitly required.
- On-device ML Focus scorer behind the pluggable interface.
- PGP / S/MIME if enterprise demand appears.
- Windows home-screen–style widgets if OS capabilities mature; until then tray/toast only.
- Server-side snooze / provider-native reminders where APIs allow.

---

## 13. Document History

| Version | Date | Notes |
| --- | --- | --- |
| 1.0 | 2026-07-13 | First structured tech spec from architecture blueprint draft; fluff removed; requirements normalized |
| 1.1 | 2026-07-14 | Incorporated architecture/feature review: module boundaries, MailProvider capabilities, job-queue sync, outbox/conflicts, body/attachment strategy, sync profiles, Focus pluggable scorer, unified merge/reply rules, remote search contract, widget snapshots, onboarding, Windows desktop surface, observability, expanded non-goals and metrics |
| 1.2 | 2026-07-14 | Clarified full contacts & calendar as planned post-v1 milestones; remain out of scope for v1 with light forward-compat guidance |
| 1.3 | 2026-07-14 | Appearance: Dark jewel-tone + Calm as defaults; themes (Light, Solarized Light/Dark, Black); account color controls; Compact density for smaller/travel devices |
| 1.4 | 2026-07-14 | Focused/Other optional per account; Unified has independent Focus enablement (does not follow account-level settings) |
