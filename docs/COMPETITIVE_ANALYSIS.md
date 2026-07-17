# ByteMail Competitive Analysis

| Field | Value |
| --- | --- |
| Status | Research snapshot |
| Compared clients | Outlook (new), Aqua Mail, Thunderbird, FairEmail / K-9, Spark |
| ByteMail baseline | SPEC v1.4 + ROADMAP (2026-07-16) + codebase audit |
| Last updated | 2026-07-16 |

This document maps **what ByteMail has today** against **what users expect** from mature email clients. It is input for backlog prioritization — not a commitment to parity with Outlook or Spark.

---

## 1. Competitor profiles

| Client | Primary platform | Positioning | Relevance to ByteMail |
| --- | --- | --- | --- |
| **Outlook (new)** | Windows, Web, Mobile | Microsoft 365 default; Copilot AI; deep Exchange/Graph integration; PST, shared mailboxes, calendar/contacts | **Primary desktop benchmark** for power users and Exchange shops |
| **Aqua Mail** | Android | Highly customizable IMAP/POP3/EWS client; 300+ settings; privacy (no cloud storage of mail); premium S/MIME, Exchange push | **Primary Android benchmark** for power-user IMAP customization |
| **Thunderbird** | Windows, macOS, Linux (+ mobile fork) | Open-source; extensible; native CalDAV/CardDAV; EWS email (2025+); filters; PGP via add-ons | **Open-source / local-control benchmark** |
| **FairEmail / K-9** | Android | Privacy-first; granular sync/filter control; OpenPGP (FairEmail, K-9+OpenKeychain); minimal vs maximal UX | **Privacy / technical-user Android benchmark** |
| **Spark** | Cross-platform | Unified inbox; Smart Inbox; snooze, schedule send, pin/set-aside; AI drafting; team collaboration | **Modern productivity / “inbox zero” benchmark** |

---

## 2. ByteMail today (honest inventory)

### 2.1 Landed strengths (differentiators or solid foundation)

| Area | ByteMail status |
| --- | --- |
| **Local-first architecture** | UI reads SQLite; sync in background — matches FairEmail/Thunderbird philosophy, stronger than cloud-centric Spark |
| **Dual protocol** | Graph + IMAP/SMTP via `MailProvider` adapters |
| **Offline read + FTS search** | FTS5 local search; cold start from DB |
| **Offline outbox** | Durable compose/send queue |
| **Multi-account** | Unified inbox + per-account views; account color anchors |
| **Optional Focus (Focused/Other)** | Rule-based scorer + overrides — similar intent to Outlook Focused / Spark Smart Inbox / Aqua Smart Folder |
| **Retention + sync profiles** | Device retention dial; job-based cleanup — uncommon in consumer clients |
| **Android widgets** | Snapshot-based list/counter/actions without waking Flutter |
| **Themes + density** | Five theme packs; Calm vs Compact |
| **Mark read/unread** | Individual + bulk; provider push (Graph PATCH, IMAP `\\Seen`) |
| **Folder tree** | Per-account collapsible sidebar; folder-scoped sync |
| **Header inspection** | Parsed + raw headers on demand |
| **Account lifecycle** | Add, edit, remove with typed wipe gate |
| **Diagnostics** | Redacted export for support |
| **Windows keyboard nav** | Ctrl+J/K/N/F, Ctrl+U (partial — see gaps) |

### 2.2 Partial / stub (marketed in SPEC or UI but incomplete)

| Area | Gap |
| --- | --- |
| **Reply / Archive / Delete** | Reading-pane buttons are UI stubs (`onPressed: () {}`) |
| **Quick reply** | Field present; not wired to outbox |
| **Compose** | Plain text only; no CC/BCC, rich text, reply/forward threading |
| **Attachments** | `hasAttachments` flag only — no fetch, view, or compose |
| **OAuth** | Manual token paste spike for Graph; no browser flow |
| **Push / IDLE** | Poll-first; `supportsPush` flag exists but not fully realized |
| **Windows desktop** | Tray/notification hooks exist; not full native parity |
| **Unread counts** | Provider counts partial; local recount polish open |
| **Read-row dimming** | Unread bold only; read messages not visually muted |

### 2.3 In SPEC or roadmap but not built

| Area | SPEC / ROADMAP reference |
| --- | --- |
| Snooze (local) | §7.6 |
| Templates / canned responses | §7.6 |
| Multi-window reading | §7.6 |
| `.eml` open/associate | §3.1 |
| Message filters (user-defined) | ROADMAP Pri-1 |
| Signatures (per-account) | ROADMAP Pri-2 |
| Reading-pane layout (right/top/bottom) | ROADMAP Pri-2 |
| Junk / spam actions | ROADMAP Pri-2 |
| Per-account retention | ROADMAP Pri-2 |
| DB encryption at rest | SPEC §5.4, opt-in |
| Browser Entra OAuth | ROADMAP risks |

### 2.4 Explicit non-goals (v1)

Contacts, calendar, POP3 runtime, PGP/S/MIME, cloud AI, iOS/macOS/Linux, EAS/MAPI — per SPEC §1.2 / §12.

---

## 3. Feature matrix

Legend: ✅ Landed · ◐ Partial / stub · ❌ Missing · 🚫 Out of scope (v1) · — N/A or weak in competitor

### 3.1 Core mail operations (table stakes)

| Feature | ByteMail | Outlook | Aqua Mail | Thunderbird | FairEmail/K-9 | Spark |
| --- | --- | --- | --- | --- | --- | --- |
| Read HTML email | ◐ WebView | ✅ | ✅ | ✅ | ✅ | ✅ |
| Read plain text | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Attachments — view** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Attachments — compose** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Reply / Reply-all** | ◐ stub | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Forward** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Delete** | ◐ stub | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Archive / move** | ◐ stub | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Mark read/unread** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Flag / star** | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Junk / spam** | ❌ | ✅ | ◐ rules prem. | ✅ filters | ✅ | ✅ |
| Drafts | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Sent folder sync | ◐ | ✅ | ✅ | ✅ | ✅ | ✅ |
| CC / BCC compose | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Rich text compose | ❌ | ✅ | ✅ | ✅ | ◐ | ✅ |
| **Signatures** | ❌ | ✅ | ✅ HTML | ✅ | ✅ | ✅ |
| Undo send | ❌ | ✅ offline | — | — | — | — |
| Schedule send | ❌ | — | — | — | — | ✅ |
| Print message | ❌ | ✅ | ◐ PDF | ✅ | ✅ K-9 | — |
| Save as .eml / .msg | ❌ | ✅ PST/MSG | ✅ EML | ✅ | ✅ | — |

**Table-stakes gap (highest priority):** attachments, wired reply/forward, delete/move/archive, star/flag, junk, drafts, rich compose basics, signatures.

### 3.2 Organization & discovery

| Feature | ByteMail | Outlook | Aqua Mail | Thunderbird | FairEmail/K-9 | Spark |
| --- | --- | --- | --- | --- | --- | --- |
| Unified inbox | ✅ | ✅ | ✅ Smart Folder | ✅ | ✅ | ✅ |
| Per-account isolation | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Folder tree | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Conversation threading** | ❌ | ✅ | ✅ | ✅ | ◐ | ✅ |
| **User filters / rules** | ❌ | ✅ | ◐ prem. | ✅ | ✅ advanced | ◐ Smart Folders |
| Search (local) | ✅ FTS5 | ✅ | ✅ | ✅ | ✅ | ✅ Smart Search |
| Search (server) | ◐ | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Date grouping (Today, etc.)** | ❌ | ✅ | — | — | — | ✅ |
| Categories / labels | ❌ | ✅ | — | ✅ | — | — |
| Pin / snooze | ❌ | ✅ flag/snooze | ✅ pin prem. | ✅ | — | ✅ pin/snooze/set-aside |
| Focused vs bulk mail | ✅ Focus | ✅ / Copilot | Smart Folder | — | — | ✅ Smart Inbox |

**Gap:** threading, client rules, date buckets, pin/snooze (SPEC snooze not built), categories.

### 3.3 Sync, offline & accounts

| Feature | ByteMail | Outlook | Aqua Mail | Thunderbird | FairEmail/K-9 | Spark |
| --- | --- | --- | --- | --- | --- | --- |
| Offline read | ✅ strong | ✅ 30d+ | ✅ preload | ✅ | ✅ configurable | ◐ |
| Offline compose/send | ✅ outbox | ✅ | ✅ | ✅ | ✅ | ✅ |
| **Push / IDLE** | ❌ poll | ✅ | ✅ IMAP IDLE / EWS prem. | ◐ | ✅ | ✅ |
| Graph / modern API | ✅ | ✅ | ◐ EWS | ◐ EWS 2025 | — | ✅ |
| IMAP / SMTP | ✅ | ◐ | ✅ | ✅ | ✅ | ✅ |
| POP3 | 🚫 | ✅ | ✅ | ✅ | ✅ | — |
| OAuth onboarding | ◐ manual | ✅ | ✅ | ✅ | ✅ | ✅ |
| Autoconfig | ◐ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Multi-account cap | ~10 soft | — | unlimited prem. | — | — | — |
| **Shared mailbox** | ❌ | ✅ | ◐ | — | — | ✅ teams |
| Move between accounts | ❌ | ✅ | ✅ prem. | — | — | — |
| Retention / cache control | ✅ unusual | ◐ offline days | ✅ WiFi vs mobile | — | ✅ granular | — |

**Gap:** real OAuth, push/IDLE, shared mailboxes; POP3 explicitly deferred.

### 3.4 Security & privacy

| Feature | ByteMail | Outlook | Aqua Mail | Thunderbird | FairEmail/K-9 | Spark |
| --- | --- | --- | --- | --- | --- | --- |
| TLS in transit | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Secure credential store | ✅ | ✅ | ✅ local | ✅ | ✅ | ◐ cloud sync |
| **DB encryption at rest** | ❌ backlog | — | — | — | — | — |
| **S/MIME** | 🚫 post-v1 | ✅ 2025 | ✅ prem. | ✅ add-on | — | — |
| **OpenPGP** | 🚫 post-v1 | — | — | ✅ add-on | ✅ | — |
| Tracker blocking | ❌ | — | — | — | ✅ | — |
| Local-only data | ✅ | ◐ M365 | ✅ | ✅ | ✅ | ◐ |
| Phishing / unsubscribe | ❌ | ◐ | ✅ prem. | — | — | ✅ Gatekeeper |

**Gap:** DB encryption (planned opt-in); message-level crypto deferred; no tracker blocking.

### 3.5 Notifications & widgets

| Feature | ByteMail | Outlook | Aqua Mail | Thunderbird | FairEmail/K-9 | Spark |
| --- | --- | --- | --- | --- | --- | --- |
| **New-mail notifications** | ◐ desktop hook | ✅ | ✅ per-account | ✅ | ✅ granular | ✅ |
| Per-account notification rules | ❌ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Android home widget | ✅ | — | ✅ | — | — | — |
| Wear / watch | ❌ | ◐ | ✅ | — | — | — |
| Badge / unread counts | ◐ | ✅ | ✅ | ✅ | ✅ | ✅ |

**Gap:** full notification pipeline (Android + Windows), per-account rules, quiet hours.

### 3.6 Desktop power UX

| Feature | ByteMail | Outlook | Aqua Mail | Thunderbird | Spark |
| --- | --- | --- | --- | --- | --- |
| Keyboard shortcuts | ◐ | ✅ | — | ✅ | ◐ |
| **Reading pane position** | ❌ fixed right | ✅ bottom/right | — | ✅ | ◐ |
| Multi-window | ❌ SPEC | ✅ | — | ✅ | — |
| Quick steps / macros | ❌ | ✅ | — | ✅ filters | — |
| System tray | ◐ | ✅ | — | ✅ | — |
| Ctrl+F in message | ❌ | ✅ 2025 | — | ✅ | — |
| Templates | ❌ SPEC | ✅ 2025 | — | ✅ | — |
| Snooze | ❌ SPEC | ✅ | — | — | ✅ |

**Gap:** layout options (backlog), snooze, templates, multi-window, find-in-message.

### 3.7 Mobile UX

| Feature | ByteMail | Outlook | Aqua Mail | FairEmail/K-9 | Spark |
| --- | --- | --- | --- | --- | --- |
| Swipe actions (archive/delete) | ❌ | ✅ | ✅ | ✅ | ✅ |
| Pull to refresh | ◐ manual sync | ✅ | ✅ | ✅ | ✅ |
| Single-pane list/detail | ◐ | ✅ | ✅ | ✅ | ✅ |
| **Swipe between messages** | ❌ | ✅ | ✅ | — | ✅ |
| Back gesture | Flutter default | ✅ | ✅ | ✅ | ✅ |

### 3.8 Integrations & ecosystem (mostly post-v1 for ByteMail)

| Feature | ByteMail | Outlook | Aqua Mail | Thunderbird | Spark |
| --- | --- | --- | --- | --- | --- |
| Calendar | 🚫 | ✅ native | ✅ Exchange | ✅ CalDAV | ✅ built-in |
| Contacts | 🚫 | ✅ | ✅ Exchange | ✅ CardDAV | ◐ |
| Teams / Slack / tasks | 🚫 | ✅ | — | add-ons | ✅ |
| Copilot / AI draft | 🚫 | ✅ | — | — | ✅ |
| PST / OST files | 🚫 | ✅ read 2025 | — | — | — |

---

## 4. Gap tiers (recommended product framing)

### Tier A — Table stakes (users will notice immediately)

Without these, ByteMail does not feel like a complete mail client:

1. **Attachments** — view, download, compose (already Pri-1 backlog)
2. **Reply, Reply-all, Forward** — wire reading pane + message context
3. **Delete, Archive, Move to folder** — optimistic local + provider sync
4. **Flag / star** — SPEC conflict policy already assumes flag LWW
5. **CC / BCC + quoted reply** in compose
6. **Signatures** — per-account default + picker (backlog)
7. **Junk / not junk** — folder + actions (backlog)
8. **Real OAuth** — browser Entra + Google (risk item)
9. **New-mail notifications** — Android + Windows

### Tier B — Expected polish (competitive parity)

10. Conversation threading (or explicit “flat list” product choice)
11. User-defined filters / rules (backlog Pri-1)
12. Snooze + pin (SPEC §7.6)
13. Drafts folder sync + save draft
14. Date grouping in message list (Today / Yesterday / …)
15. Swipe actions (mobile)
16. Reading-pane layout options (backlog)
17. IMAP IDLE / Graph webhook push
18. Starred / flagged filter views
19. Rich text compose (minimum: bold, links, inline reply quote)
20. Templates / canned responses (SPEC §7.6)

### Tier C — Power-user & differentiation (ByteMail can win here)

Already aligned or extend:

| ByteMail angle | vs competitors |
| --- | --- |
| **Local-first + retention dials** | Stronger than Spark/Outlook cloud cache story |
| **Transparent sync jobs + diagnostics** | FairEmail-level trust, better UX |
| **Focus without cloud ML** | Privacy-friendly vs Copilot/Spark AI |
| **Widget snapshots without Flutter wake** | Unique on Android |
| **Keyboard-first Windows** | Extend to full Outlook keymap |
| **Sync profiles** (folder scope, body policy, attachment caps) | Aqua/FairEmail granularity, cleaner UI |
| **Per-account wipe** | Strong privacy story |

### Tier D — Defer (explicit non-goals or low ROI for v1)

- Calendar, contacts, CardDAV/CalDAV
- PGP / S/MIME message encryption
- Cloud AI (Copilot, Spark+)
- POP3 runtime
- PST / MSG import
- Shared mailboxes / delegation
- Team collaboration (co-editing, comments, read receipts)
- iOS / macOS / Linux
- Newsletter builder, mail merge
- Wear OS

---

## 5. Competitive positioning summary

```text
                    Power / customization
                            ▲
                            │
              FairEmail ●   │   ● Aqua Mail
                            │
         Thunderbird ●      │      ● Outlook (new)
                            │
              ByteMail ◆    │         ● Spark
              (target)      │
                            │
    Local / privacy ◄───────┼───────► Cloud / AI / teams
                            │
                            ▼
                    Simplicity / defaults
```

**ByteMail's viable niche:** Local-first, privacy-respecting, cross-platform (Windows + Android) mail for people who want **Aqua/FairEmail-level control** without Android-only lock-in, and **Outlook-level desktop ergonomics** without M365 lock-in — *once Tier A/B gaps close*.

**Where not to compete in v1:** Copilot, calendar hub, team inboxes, PST legacy — different products.

---

## 6. Tier planning

| Tier | Document | Status |
| --- | --- | --- |
| A — Table stakes | [TIER_A_PLAN.md](TIER_A_PLAN.md) | Complete |
| B — Competitive parity | [TIER_B_PLAN.md](TIER_B_PLAN.md) | Complete |
| C — Differentiation | [TIER_C_PLAN.md](TIER_C_PLAN.md) | Complete |
| D — Horizon / post-V1 | [TIER_D_PLAN.md](TIER_D_PLAN.md) | Complete (locked) |
| UI sweep | [UI_ENHANCEMENT_SWEEP.md](UI_ENHANCEMENT_SWEEP.md) | Active — add in §6 |
| **V1 integration** | [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md) | **Use for implementation order** |

## 7. Suggested backlog additions (from this analysis)

Items **not yet** in ROADMAP that competitors commonly ship:

| Pri | Item | Rationale |
| --- | --- | --- |
| **Pri-1** | Reply / Reply-all / Forward (wired) | Table stakes; stubs exist |
| **Pri-1** | Delete / Archive / Move message | Table stakes; stubs exist |
| **Pri-1** | Flag / star messages | SPEC §8.5 assumes it; Outlook/Aqua/K-9 all have it |
| **Pri-1** | New-mail notifications (Android + Windows) | Expected on both target platforms |
| **Pri-1** | Browser OAuth (Entra + Google) | Onboarding friction vs all competitors |
| **Pri-2** | Conversation threading | Default in Outlook, Aqua, Thunderbird, Spark |
| **Pri-2** | Snooze (local) | SPEC §7.6; Spark/Outlook differentiator |
| **Pri-2** | Drafts sync + save draft | Basic compose completeness |
| **Pri-2** | Mobile swipe actions | Standard Android UX |
| **Pri-2** | CC / BCC + quoted reply in compose | Basic compose completeness |
| **Pri-2** | Templates / canned responses | SPEC §7.6; Outlook 2025 shipped |
| **Pri-3** | Schedule send | Spark; nice desktop power feature |
| **Pri-3** | Print / save as PDF or EML | Aqua, Thunderbird |
| **Pri-3** | Find in message (Ctrl+F) | Outlook 2025 |
| **Pri-3** | Tracker / remote image controls | FairEmail differentiator for privacy crowd |

---

## 8. Sources

- [Aqua Mail core functions](https://aquamail.freshdesk.com/support/solutions/articles/77000519534-aqua-mail-s-core-functions)
- [Aqua Mail product site](https://www.aqua-mail.com/)
- [What's new in new Outlook for Windows](https://support.microsoft.com/en-us/office/what-s-new-in-new-outlook-for-windows-c4c33813-1e9a-4304-8499-90fe7f164bd1)
- [Thunderbird Exchange support (blog)](https://blog.thunderbird.net/2025/11/thunderbird-adds-native-microsoft-exchange-email-support/)
- [K-9 Mail on Google Play](https://play.google.com/store/apps/details?id=com.fsck.k9)
- [Spark vs Gmail (2026)](https://sparkmailapp.com/blog/spark-vs-gmail)
- ByteMail: [SPEC.md](SPEC.md), [ROADMAP.md](ROADMAP.md), codebase audit 2026-07-16

---

*Next review: after Tier A items are scheduled or when a major competitor ships a relevant feature (e.g. Thunderbird Graph calendar).*
