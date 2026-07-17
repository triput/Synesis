# Tier D Implementation Plan

| Field | Value |
| --- | --- |
| Status | Planning — post-V1 / deferred scope |
| Scope | Explicit non-goals, low-ROI, and horizon features ([COMPETITIVE_ANALYSIS.md](COMPETITIVE_ANALYSIS.md) §4, Tier D) |
| Prerequisite | V1 waves W0–W7 complete (or consciously promoted into V1.x) |
| Last updated | 2026-07-17 (added editable keyboard shortcuts, D7-9) |

Tier D is the **horizon backlog**: work we deliberately excluded from V1 to ship a cohesive mail client first. Items here are fully planned (not vague wishes) so product can **promote** them into V1.1, V2, or enterprise tracks without rediscovery.

**Not in Tier D:** anything already locked for V1 (see [V1_TIER_INTEGRATION.md §12](V1_TIER_INTEGRATION.md#12-locked-decisions-2026-07-16)).

---

## 1. Tier D scope (recap)

| # | Theme | Examples | Default disposition |
| --- | --- | --- | --- |
| D1 | **Productivity suite** | Contacts, calendar, meeting mail | Post-V1 **V2** |
| D2 | **Message-level crypto** | OpenPGP, S/MIME | Post-V1 **enterprise** |
| D3 | **Legacy & migration** | PST/MSG, POP3 runtime, on-prem EAS | Post-V1 **selective** |
| D4 | **Collaboration & AI** | Copilot-style AI, team inboxes, read receipts | Post-V1 **low priority** |
| D5 | **Platform expansion** | iOS, macOS, Linux, Wear OS | Post-V1 **platform** |
| D6 | **V1 adjacency** | Multi-window+, image whitelist, Graph upload session | **V1.1 candidates** |
| D7 | **Power-user depth** | Server rules sync, JMAP, advanced trackers, optional MFA, editable shortcuts | Post-V1 **optional** |

---

## 2. Promotion framework

Before pulling Tier D into a release, score the item:

| Gate | Question |
| --- | --- |
| **P1 Dogfood** | Do we need it to use ByteMail daily for mail-only workflows? |
| **P2 Architecture** | Does V1 leave a clean extension point (documented in plan)? |
| **P3 Cost** | Estimate ≤ 2 weeks = V1.1 candidate; > 4 weeks = major version |
| **P4 Competition** | Are we losing evals without it? |
| **P5 Philosophy** | Does it violate local-first / no-cloud-AI positioning? |

```text
                    High promotion pressure
                            ▲
                            │
         D6 V1.1 candidates │  D1 Contacts (if evals demand)
                            │
    ────────────────────────┼────────────────────────► Effort
                            │
         D4 AI / teams      │  D2 PGP / D3 PST
                            │
                            ▼
                    Low priority / niche
```

---

## 3. V1 adjacency — promotion candidates (D6)

Items **already deferred from locked V1** with known hooks. First place to look after W7.

| ID | Feature | V1 hook | Promotion target | Estimate |
| --- | --- | --- | --- | --- |
| D6-1 | **Unlimited multi-window desktop** | W5 detached window + layout extension points | **V1.1** | 1–2 weeks |
| D6-2 | **Per-account image block + domain whitelist** | TC-6 phase 1 global toggle; `account_settings_json` | **V1.1** | 1 week |
| D6-3 | **Graph large attachment upload session** | W4 compose + sync profile cap | **V1.1** | 1–2 weeks |
| D6-4 | **Template variables** (`{{name}}`, etc.) | TB-13 templates table | V1.2 | 3–5 days |
| D6-5 | **Server-side snooze** | TB-4 local snooze | V1.2 | 1–2 weeks |
| D6-6 | **Save as PDF** (in addition to EML) | TC-9 print path | V1.1 | 3–5 days |
| D6-7 | **Advanced tracker blocking** | TC-6 HTML sanitize | V1.2 | 1 week |
| D6-8 | **Windows toast actions** (archive/delete from notification) | W6 notifications | V1.2 | 1 week |

**Recommendation:** After V1 ship, run a **V1.1 triage** — default bundle D6-1, D6-2, D6-3 if dogfood demands.

---

## 4. TD-A — Contacts & calendar (D1)

**Goal:** SPEC §12.1 — full PIM surface without breaking mail architecture.

### 4.1 Contacts

| Piece | Approach |
| --- | --- |
| Graph | `/me/contacts` sync; people picker in compose |
| CardDAV | Thunderbird-style native sync for Nextcloud/iCloud |
| Local store | `contacts` + `contact_emails` tables; FTS for picker |
| Focus integration | `FocusScorer` uses contact graph (“prior correspondence”) |
| v1 compat | Recipient suggestions from recent mail headers until TD-A ships |

### 4.2 Calendar

| Piece | Approach |
| --- | --- |
| Graph | `/me/events`; meeting request parse in reading pane |
| CalDAV | Per-account calendar sync |
| UI | Agenda sidebar or tab — **product choice:** integrated shell vs separate view |
| Notifications | TC-7 extension for meeting reminders |

### 4.3 Meeting mail affordances

- Accept/decline/tentative ICS from reading pane
- .ics attachment open → calendar event draft
- Free/busy for compose scheduling (ties to TC-10 schedule send)

### TD-A exit criteria

- [ ] Contact picker in compose with Graph + one CardDAV provider
- [ ] Calendar month view with one Graph account
- [ ] Meeting invite actionable from mail body

**Estimate:** 6–10 weeks (major version)  
**Depends on:** V1 compose, OAuth, sync job framework  
**Disposition:** **V2 flagship** — do not slip into V1.1 without explicit promotion

---

## 5. TD-B — Message encryption (D2)

**Goal:** Enterprise and privacy-power-user demand (Aqua premium S/MIME, FairEmail OpenPGP).

### 5.1 OpenPGP

| Piece | Detail |
| --- | --- |
| Key management | OpenKeychain integration (Android) or embedded keyring (desktop) |
| Compose | Sign/encrypt toggles; key picker |
| Read | Decrypt inline; signature verification status |
| Provider | MIME PGP/MIME parts in IMAP |

### 5.2 S/MIME

| Piece | Detail |
| --- | --- |
| Certs | OS store + import .pfx |
| Graph | Send signed/encrypted via Graph MIME APIs |
| Outlook interop | Critical for enterprise evals |

### 5.3 TLS pinning (optional sub-item)

- Per-account cert pin for paranoid IMAP — document recovery path

### TD-B exit criteria

- [ ] Send/receive signed mail with one method (PGP *or* S/MIME) on Windows + Android
- [ ] Key import/export documented

**Estimate:** 8–12 weeks  
**Disposition:** **Enterprise track** — separate from consumer V1.x  
**V1 note:** DB encryption (TC-3) is **not** TD-B — stays V1 optional

---

## 6. TD-C — Legacy mail & migration (D3)

**Goal:** Outlook refugees and POP-only providers.

### 6.1 PST / MSG import

| Piece | Detail |
| --- | --- |
| Read PST | Port or wrap `libpst` / read-only parser — **spike required** |
| Import flow | File picker → extract messages → SQLite upsert |
| Scope | Mail items first (Outlook 2025 new Outlook still maturing PST support) |
| Export MSG | Optional — lower priority than import |

**Estimate:** 4–8 weeks (parser risk)  
**Promotion:** When migration stories block adoption

### 6.2 POP3 runtime (`storage_type = local_only`)

| Piece | Detail |
| --- | --- |
| Schema | `accounts.storage_type` already reserved (SPEC §5.2) |
| Semantics | Download-and-delete or keep local copy; no server sync after fetch |
| Provider | New `Pop3MailProvider` |
| UI | Distinct account badge “Local only” |

**Estimate:** 3–5 weeks  
**Promotion:** Niche users; Aqua/Thunderbird have it

### 6.3 Exchange without Graph (EAS / on-prem)

| Piece | Detail |
| --- | --- |
| Problem | SPEC excludes non-Graph on-prem for v1 |
| Options | EAS library, or Thunderbird-style EWS (deprecated path) |
| Recommendation | **Prefer Graph hybrid modern auth**; EAS only if paying customer requires |

**Estimate:** 10+ weeks — **avoid unless contractual**

### 6.4 Shared mailboxes & delegation

- Graph: `/users/{id}/messages` shared mailbox access
- Send-as / send-on-behalf in compose From picker
- Aqua “move between accounts” premium feature

**Estimate:** 2–4 weeks (Graph-only subset)  
**Promotion:** Enterprise / workplace evals

### TD-C exit criteria (minimal)

- [ ] Import 10k messages from sample PST into local DB
- [ ] POP3 account receives and optionally deletes from server

---

## 7. TD-D — Collaboration & cloud AI (D4)

**Goal:** Document what ByteMail **chooses not to chase** by default vs optional future.

| ID | Feature | Competitor | ByteMail stance |
| --- | --- | --- | --- |
| D4-1 | Copilot / cloud AI draft | Outlook, Spark | **Non-goal** — conflicts with privacy positioning; on-device ML only via Focus seam |
| D4-2 | On-device ML Focus | Gmail | **Optional** — replace `RuleBasedFocusScorer` behind interface |
| D4-3 | Team shared inboxes | Spark | Post-V1; needs backend or Graph shared mailbox first |
| D4-4 | Co-edit drafts / comments | Spark | Post-V1 low priority |
| D4-5 | Read receipts | Spark | Post-V1; privacy controversial — default off |
| D4-6 | Newsletter builder | Outlook 2025 | **Non-goal** — use dedicated tools |
| D4-7 | Mail merge | Outlook | **Non-goal** for consumer; **enterprise** maybe |

### TD-D1 — On-device ML Focus (only promoted AI item)

| Piece | Detail |
| --- | --- |
| Interface | Existing `FocusScorer` pluggable seam |
| Model | TFLite / ONNX small classifier; train on local labels from overrides |
| Privacy | No cloud training upload |

**Estimate:** 4–6 weeks after sufficient override data  
**Disposition:** V2+ enhancement, not launch blocker

### TD-D exit criteria (ML only)

- [ ] ML scorer drop-in replaces rules without UI rewrite
- [ ] Inference off UI isolate

---

## 8. TD-E — Platform expansion (D5)

| Platform | Work | Estimate | Notes |
| --- | --- | --- | --- |
| **iOS** | Flutter iOS build; secure storage; push (APNs); App Store OAuth redirects | 4–6 weeks *after* Android parity | Large market |
| **macOS** | Menu bar, sandbox, keychain | 3–4 weeks | Shares Windows desktop patterns |
| **Linux** | GTK/tray, Secret Service API | 3–4 weeks | Thunderbird overlap — niche |
| **Wear OS / Galaxy Watch** | Lightweight triage companion (unread glance, star/archive, optional voice reply) | 2–3 weeks | **V2** — after Android phone parity; Galaxy Watch target |

### Galaxy Watch — lightweight V2 companion (locked)

Not a full mail client on the wrist. Target **Samsung Galaxy Watch** (Wear OS) after Android phone app is stable.

| In scope (V2) | Out of scope |
| --- | --- |
| Unread count / Focused badge | Full compose with attachments |
| Last 3–5 subject lines per account | HTML rendering |
| Star / archive / mark read | OAuth flow on watch |
| Open on phone (handoff to selected message) | Calendar PIM (use phone) |
| Optional voice reply (stretch) | IDLE / background sync on watch |

**Data path:** Phone app remains source of truth; watch reads widget-style snapshot or Wear Data Layer sync — same philosophy as Android home widgets (no full Flutter engine on watch for routine updates).

### Architecture prep in V1 (no extra scope)

- Keep platform seams (`DesktopController`, `NotificationService`) interface-based
- Avoid `dart:io` assumptions in domain layer
- OAuth redirect schemes per platform documented in W0
- Widget snapshot pipeline reusable for watch glance data (TC-11 / W7)

---

### TD-E exit criteria

- [ ] TestFlight build reads Graph mail with parity to Android core (when iOS ships post-PIM)
- [ ] Galaxy Watch companion shows unread + triage actions via phone snapshot sync

**Disposition:** **V2 platform** — **PIM (TD-A) is the V2 headline**; iOS/macOS/Linux and Galaxy Watch follow based on demand after PIM lands.

---

## 9. TD-F — Protocol & power-user depth (D7)

| ID | Feature | Detail | Estimate |
| --- | --- | --- | --- |
| D7-1 | **JMAP** | Fastmail-style protocol; K-9 has experimental code | 4–6 weeks |
| D7-2 | **IMAP server filter import** | Sync Sieve/Outlook rules as client hints | 2–3 weeks |
| D7-3 | **Unsubscribe helper** | List-Unsubscribe one-tap (Aqua premium) | 3–5 days |
| D7-4 | **Phishing heuristics** | Link warning, spoofed From detection | 1–2 weeks |
| D7-5 | **Categories / labels** | Outlook categories sync | 2–3 weeks |
| D7-6 | **Quick Steps** | Outlook macros — multi-action shortcuts | 1–2 weeks |
| D7-7 | **Graph webhook push** | True push vs delta poll | 2–3 weeks |
| D7-8 | **Optional client MFA** | 100% opt-in second factor + server MFA pass-through | 3–5 weeks |
| D7-9 | **Editable keyboard shortcuts** | User-remappable chords; conflict detection; reset to defaults | 1–2 weeks |

**Disposition:** Cherry-pick into V1.x based on dogfood; none are V1 blockers

### D7-8 — Optional multi-factor authentication (post-V1/V2)

**Goal:** Offer an additional security layer to users who want it, without ever forcing it. MFA is **100% optional** — the client must never mandate a second factor on its own.

| Principle | Implication |
| --- | --- |
| **Opt-in only** | No forced client MFA; default off. User explicitly enables per install or per account. |
| **Server pass-through** | When a provider/server already requires MFA (e.g. Entra Conditional Access, IMAP app-password + OTP), honor and surface that challenge cleanly — do not suppress or duplicate it. |
| **Local gate, not crypto** | Client MFA guards app/account access on-device; distinct from DB encryption (TC-3) and message crypto (TD-B). |
| **Recovery** | Document lockout/recovery path before shipping; a lost factor must not orphan a local mailbox. |

**Factor options (user chooses any subset):**

| Factor | Detail |
| --- | --- |
| **Biometrics** | Platform biometric unlock (Windows Hello, Android BiometricPrompt) as app/account gate |
| **Email** | One-time code delivered to a verified address |
| **Text message (SMS)** | OTP via SMS to a verified number (requires a delivery path — likely provider/gateway dependency) |
| **Authenticator app** | TOTP (RFC 6238) enrollment via QR; offline code generation |

**Scope notes:**
- Enrollment + verification UI in account/security settings; per-account or app-wide gate (product to pick granularity at promotion).
- SMS/email delivery may need a backend or third-party service — evaluate against the no-cloud-dependency principle at promotion; TOTP and biometrics are fully local and are the preferred first factors.
- Pass-through handling reuses existing OAuth/Graph interactive flows and IMAP auth error surfacing.

**Estimate:** 3–5 weeks (TOTP + biometrics first; email/SMS gated on delivery path)  
**Disposition:** Post-V1/V2 optional; promote if security-conscious evals ask for it.

### D7-9 — Editable keyboard shortcuts (post-V1)

**Goal:** Let power users remap workspace chords after V1 ships a fixed keymap (W5 DEF-001 / TC-9 help overlay). V1 documents and honors the built-in set; customization is explicitly deferred.

| Principle | Implication |
| --- | --- |
| **Defaults first** | Ship with the W5 binding table; remapping is opt-in preference, not required for keyboard-first use. |
| **Conflict detection** | Reject or warn on duplicates and reserved system chords (copy/paste, OS shortcuts). |
| **Reset path** | One-tap restore to factory bindings; persist overrides in `AppSettings` (or a dedicated keymap prefs blob). |
| **Text-field safety** | Keep the existing “skip while editing text” rule; remaps must not break compose/search typing. |

**Scope notes:**
- Settings UI: list intents → activator editor (key capture) → save; surface from Appearance or a dedicated Shortcuts sheet.
- Runtime: load overrides into the hardware-key handler / intent map used by `mailbox_shortcuts.dart` and `keyboard_intents.dart`.
- Out of scope for this item: per-account keymaps, chord sequences (multi-key Vim-style), macOS Command remaps until D5 platforms ship.

**V1 hook:** W5 keymap help overlay + `ByteMailKeyboardShortcuts` / `handleMailboxHardwareKey`.  
**Estimate:** 1–2 weeks  
**Disposition:** Post-V1 optional; promote if dogfood asks to rebind after the fixed set lands.

---

## 10. TD-G — Windows & Android ecosystem extras

| ID | Feature | Detail |
| --- | --- | --- |
| D-G1 | Windows shell widgets | If OS APIs mature (SPEC §12.2) |
| D-G2 | Wear / Galaxy Watch | Lightweight V2 companion — see TD-E; not phone parity |
| D-G3 | Share target | “Share to ByteMail” compose from other apps |
| D-G4 | Default mail handler | OS registration as default client |
| D-G5 | Backup/restore mail DB | User-initiated encrypted backup file |

---

## 11. Master disposition table

| Item | Tier D ID | Default release | Promote if… |
| --- | --- | --- | --- |
| Unlimited multi-window | D6-1 | **V1.1** | Desktop power users want it (likely yes) |
| Image whitelist per account | D6-2 | **V1.1** | Privacy inbox pattern (likely yes) |
| Graph large attachments | D6-3 | **V1.1** | Hit attachment cap in dogfood |
| Contacts & calendar (PIM) | TD-A | **V2 headline** | **Locked** — V2 flagship |
| Enterprise SKU | TD-B + TD-C subset | **Separate product** | **Locked** — crypto + shared mail + S/MIME |
| OpenPGP / S/MIME | TD-B | **Enterprise** | Paying org requirement |
| PST import | TD-C | **After V1.1** | **Locked** — unless migration is acquisition channel |
| POP3 | TD-C | **V2** | User demand |
| Shared mailboxes | TD-C | **Enterprise / V1.2** | Workplace Graph accounts |
| Galaxy Watch (lightweight) | TD-E | **V2** | After Android stable |
| iOS / macOS / Linux | TD-E | **V2+** | After PIM |
| On-device ML Focus | TD-D1 | **V2+** | Override data + quality bar |
| JMAP | TD-F | **Optional** | Fastmail users |
| Optional MFA (opt-in + pass-through) | TD-F D7-8 | **Post-V1/V2 optional** | Security-conscious users / evals request it |
| Editable keyboard shortcuts | TD-F D7-9 | **Post-V1 optional** | Dogfood asks to rebind after W5 fixed keymap |
| Maybe/Someday | §17 | **Unplanned** | On radar only — see below |

---

## 12. Phase overview (if executing Tier D as program)

```text
V1.1  (post-W7, ~2–4 weeks) ── D6 adjacency bundle only (locked)
V1.2  (~4–6 weeks)          ── D7 cherry-picks; PST import if needed
V2.0  (major)               ── TD-A PIM headline + Galaxy Watch lightweight (TD-E)
Enterprise SKU              ── TD-B crypto + TD-C shared mail + S/MIME (locked)
Ongoing                     ── TD-D ML Focus, TD-F protocol depth, iOS/macOS/Linux
```

**Locked:** V1.1 does **not** include shared mailbox — mail-focused patch only.  
**Locked:** V2 headline is **contacts & calendar (PIM)**, not a new phone OS.

---

## 13. V1 forward-compatibility checklist

Ensure V1 does not block Tier D (verify during W7):

| Area | V1 requirement |
| --- | --- |
| `accounts.storage_type` | Present; only `synced` used |
| `FocusScorer` interface | Swappable implementation |
| `MailProvider` registry | New provider types = new adapter |
| Compose `ComposeDraft` | Extension fields for encrypt/sign |
| `account_settings_json` | Extensible for image whitelist, push prefs |
| `MailWorkspace` | Window manager hook for multi-window |
| OAuth | Scopes documented; room for Calendars.Read |
| Schema | No mail tables that assume contacts FK required |

---

## 14. Testing strategy (Tier D)

| Track | Approach |
| --- | --- |
| D6 V1.1 | Regression on V1 exit checklist + new feature tests |
| TD-A | CardDAV test server; Graph sandbox calendar |
| TD-B | GPG test vectors; S/MIME round-trip with Outlook |
| TD-C | Sample PST corpus; POP3 test server |
| TD-E | Platform-specific CI (Codemagic iOS, etc.) |

---

## 15. Locked decisions (2026-07-16)

| # | Question | Locked choice |
| --- | --- | --- |
| 1 | First post-V1 bundle | **V1.1 = D6 only** — no shared mailbox in V1.1 |
| 2 | V2 headline | **PIM** (contacts & calendar) — not iOS-first |
| 3 | Enterprise SKU | **Yes** — separate track for crypto + shared mail + S/MIME |
| 4 | PST import | **After V1.1** unless migration becomes acquisition channel |
| 5 | On-device ML Focus | After TC-4 override UI + ~90 days dogfood data |
| 6 | Galaxy Watch | **V2 lightweight companion** — unread/triage/star/archive; not full client |
| 7 | Former non-goals | **Maybe/Someday backlog** (§16) — on radar, unplanned |

*Cross-tier locked V1 decisions: [V1_TIER_INTEGRATION.md §12](V1_TIER_INTEGRATION.md#12-locked-decisions-2026-07-16).*

---

## 16. Maybe / Someday (unplanned backlog)

Items we have **explicitly considered and declined for V1/V2 planning** for now. Kept so we do not re-litigate them every quarter. **No estimates, no phases** — promotion requires a new RFC and conscious strategy change.

| ID | Item | Why deferred | Revisit if… |
| --- | --- | --- | --- |
| MS-1 | **Cloud AI drafting** (Copilot, Spark+) | Conflicts with local-first / privacy positioning | On-device-only AI proves insufficient |
| MS-2 | **Newsletter builder** | Different product category (Outlook marketing tools) | Never (default) |
| MS-3 | **Consumer mail merge** | Enterprise-only niche; high complexity | Paying enterprise asks |
| MS-4 | **Team collaboration** (co-edit drafts, inline comments, read receipts) | Spark territory; needs shared infra | Workplace SKU expands beyond shared mailbox |
| MS-5 | **Exchange ActiveSync / on-prem without Graph** | Graph is v1 Microsoft path; EAS is legacy burden | Contract requires it |
| MS-6 | **ByteMail-operated mail hosting** | SPEC non-goal — we are a client | Never (default) |
| MS-7 | **Replace provider web UIs** (files, productivity) | Out of scope — mail client only | Never (default) |
| MS-8 | **Server-side ranking / cloud Focus** | Focus stays on-device via scorer seam | Strategy reversal |
| MS-9 | **Windows shell widgets** (full) | OS APIs immature; tray/toast sufficient v1 | Windows platform adds mail widget API |
| MS-10 | **iOS as V2 headline** (before PIM) | **Locked:** PIM first | PIM shipped + market demands iOS |

**Not Maybe/Someday:** Galaxy Watch (V2 planned, §8), PIM (V2 headline), Enterprise SKU (locked), D6 V1.1 items (scheduled).

---

## 17. Relationship to other docs

| Doc | Role |
| --- | --- |
| [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md) | What ships in V1 |
| [TIER_A/B/C_PLAN.md](TIER_A_PLAN.md) | V1 scope detail |
| [SPEC.md §12](SPEC.md#12-future-work) | Normative future work |
| [ROADMAP.md Post-v1](ROADMAP.md) | Living index — sync from this plan |

---

*When promoting a Tier D item, open a short **promotion RFC**: user story, wave fit, schema delta, and which subsystem gets touched.*
