# Tier B Implementation Plan

| Field | Value |
| --- | --- |
| Status | **W5 nearly complete / in progress** (2026-07-17) — TB-9 layout + Visual Focus landed; checklist open |
| Scope | Competitive parity polish ([COMPETITIVE_ANALYSIS.md](COMPETITIVE_ANALYSIS.md) §4, Tier B) |
| Prerequisite | [TIER_A_PLAN.md](TIER_A_PLAN.md) foundations (or merged V1 build — see [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md)) |
| Last updated | 2026-07-17 (W5 desktop UI wiring landed — TB-9 nearly complete) |

Tier B makes ByteMail feel **finished** — the behaviors users assume after basic send/receive works. **W2 (2026-07-17)** delivered threading, filters, date groups, local snooze/pin, mobile gestures, virtual starred/pinned/snoozed views, and list polish. **W3 (2026-07-17)** delivered push/near-push sync. Remaining Tier B work (drafts, layout, rich compose, templates) maps to W4–W5.

---

## 1. Tier B scope

| # | Capability | Today | Target |
| --- | --- | --- | --- |
| B1 | **Conversation threading** | Flat list by date | Group by `thread_id` / `Message-ID` + `References`; expandable threads |
| B2 | **User-defined message filters** | Focus only | Composable predicates on list (read, sender, date, keyword, starred) |
| B3 | **Date grouping** | Flat sort | Section headers: Today, Yesterday, This week, … |
| B4 | **Snooze** | SPEC §7.6, not built | Local `snoozed_until`; resurface to inbox |
| B5 | **Pin** | DB column exists, no UI | Pin/unpin; retention-exempt; sidebar/filter |
| B6 | **Drafts** | No draft sync | Save draft locally + sync Drafts folder |
| B7 | **Mobile swipe actions** | None | Configurable swipe → archive/delete/star/snooze |
| B8 | **Swipe between messages** | None | Horizontal nav in reading pane (mobile) |
| B9 | **Reading-pane layout** | Fixed right split | Right / top / bottom (desktop + landscape) |
| B10 | **Push sync** | **Landed (W3)** | IMAP IDLE + Graph delta/subscription (fallback poll) |
| B11 | **Starred / flagged views** | Star from Tier A | Folder filter + sidebar “Starred” virtual view |
| B12 | **Rich text compose** | Plain text | Bold, italic, links, lists; HTML outbox body |
| B13 | **Templates / canned responses** | SPEC §7.6 | Named full-body templates; insert in compose |
| B14 | **List visual polish** | Partial | Read-row dimming; pull-to-refresh on mobile |

**Tier B complete when:** inbox can be browsed by conversation or date groups, filtered by user rules, snoozed/pinned, composed with basic rich text and templates, operated via mobile swipes, laid out Outlook-style on desktop, and kept fresh via push where supported.

### Phase status (2026-07-17)

| Phase | Milestone | Status | Wave |
| --- | --- | --- | --- |
| TB-0 | MessageQuery foundations | **Landed** | W0 |
| TB-1 | Conversation threading | **Landed** | W2 |
| TB-2 | Filters + date grouping | **Landed** | W2 |
| TB-4 | Snooze (local) | **Landed** | W2 |
| TB-5 | Pin | **Landed** | W2 |
| TB-7 | Mobile gestures | **Landed** | W2 |
| TB-11 | Starred view | **Landed** | W2 |
| TB-14 | List polish | **Landed** | W2 |
| TB-6 | Drafts | Planned | W4 |
| TB-9 | Layout + Visual Focus | **Nearly complete** | W5 |
| TB-10 | Push sync | **Landed** | W3 |
| TB-12 | Rich text compose | Planned | W4 |
| TB-13 | Templates | Planned | W4 |

---

## 2. Shared architecture — `MessageQuery` layer

Tier B items B1, B2, B3, B4, B5, B11 all change **how lists are built**. Do not implement each as a separate `listMessages` fork.

### 2.1 `MessageQuery` value type

```dart
class MessageQuery {
  final String? accountId;
  final String? folderId;
  final FocusBucket? focusFilter;
  final MessageViewFilter? userFilter;      // B2
  final bool starredOnly;                   // B11
  final bool excludeSnoozed;              // B4
  final ThreadDisplayMode threadMode;     // flat | threaded
  final DateGroupingMode dateGrouping;    // none | outlookBuckets
}
```

| Component | Role |
| --- | --- |
| `MailRepository.listMessages(MessageQuery)` | Single SQL builder with composable `WHERE` |
| `MailboxCubit` | Holds active `MessageQuery`; emits flat or grouped state |
| `MessageListPane` | Renders rows OR section headers + thread expanders |

**Integration note:** Define this in **TB-0** alongside Tier A schema work — see [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md).

### 2.2 Schema additions (migration v9+)

| Column / table | Phase | Purpose |
| --- | --- | --- |
| `messages.thread_id` | TB-1 | Stable thread key (root Message-ID or provider conversation id) |
| `messages.snoozed_until` | TB-4 | Epoch ms; null = not snoozed |
| `messages.is_draft` | TB-6 | Local draft flag |
| `messages.draft_sync_provider_id` | TB-6 | Remote draft id when synced |
| `message_templates` | TB-13 | `id`, `account_id` nullable, `name`, `subject`, `body_html`, `sort_order` |
| `saved_filters` | TB-2 | Optional: named filter presets |

`messages.pinned` already exists — wire in TB-5.

---

## 3. Phase overview

```text
TB-0 MessageQuery + schema v9 ─────────────────────────────┐
                                                             │
TB-1 Threading ◄───┬── TB-2 Filters + date groups            │
                   │                                         │
TB-4 Snooze + TB-5 Pin ◄── use MessageQuery exclusions      │
                                                             │
TB-6 Drafts ◄── compose + outbox from Tier A                 │
                                                             │
TB-7 Mobile gestures ◄── Tier A archive/delete/star          │
                                                             │
TB-9 Layout refactor ◄── mail_workspace (do once)          │
                                                             │
TB-10 Push ◄── sync_engine (parallel)                        │
                                                             │
TB-11 Starred view ◄── TB-0 query + Tier A star              │
                                                             │
TB-12 Rich compose ◄── Tier A compose + mime                 │
TB-13 Templates ◄── Tier A compose extension slot            │
                                                             │
TB-14 List polish ◄── message_list_pane (UI sweep)           │
```

---

## 4. TB-0 — MessageQuery foundations

**Status:** **Landed** (W0, 2026-07-16)

**Goal:** One list pipeline for all Tier B filtering/grouping.

### Work

- Introduce `MessageQuery`, `MessageViewFilter`, `MessageListSection` types in `lib/query/`
- Refactor `MailRepository.listMessages` → `listMessages(MessageQuery)`
- Refactor `MailboxCubit.refresh` to use query object
- Migration v9: `thread_id`, `snoozed_until` (nullable; default null)
- Unit tests: predicate composition (focus + starred + snooze exclusion)

### Exit criteria

- [ ] Existing inbox behavior unchanged with default `MessageQuery`
- [ ] Cubit can swap query without repository duplication
- [ ] Tests cover SQL predicate stacking

**Estimate:** 3–4 days  
**Touch once:** `drift_mail_repository.dart`, `mailbox_cubit.dart`, `mailbox_state.dart`, `database.dart`

---

## 5. TB-1 — Conversation threading

**Status:** **Landed** (W2, 2026-07-17)

**Goal:** Default threaded view with flat-list toggle in settings.

### Thread key assignment (on sync / upsert)

| Source | `thread_id` |
| --- | --- |
| Graph | `conversationId` when present |
| IMAP | Root of `References` / `In-Reply-To` chain → normalized root `Message-ID` |
| Fallback | Own `Message-ID` or provider id |

### UI

- Thread row: subject, participant summary, count badge, latest snippet/date
- Expand/collapse thread → load members via `thread_id` query
- Reading pane: show full thread header strip (optional)

### Provider

- Graph: request `conversationId` in `$select` on list endpoints
- IMAP: parse `Message-ID` / `References` from header fetch (already partial in sync)

### Exit criteria

- [ ] Unified + per-account inbox group correctly for reply chains
- [ ] Flat / threaded toggle persists per device
- [ ] Unified dedupe (SPEC §7.3) respected when both sides of thread exist

**Estimate:** 5–7 days  
**Depends on:** TB-0

---

## 6. TB-2 — User filters + date grouping

**Status:** **Landed** (W2, 2026-07-17)

**Goal:** ROADMAP “cross-cutting message filter system” + Outlook date buckets.

### User filters (B2)

Predicates (AND composable):

| Predicate | SQL |
| --- | --- |
| Read / unread | `unread = ?` |
| Starred | `starred = 1` |
| Sender contains | `from_address LIKE` or FTS |
| Date range | `when_epoch_ms BETWEEN` |
| Keyword | FTS5 subquery |
| Has attachment | `has_attachments = 1` |

UI: filter chip bar above message list; “Clear filters”; optional save preset.

### Date grouping (B3)

- **Not** a SQL filter — Cubit groups sorted results into `MessageListSection` buckets
- Buckets: Today, Yesterday, This week, Last week, This month, Last month, Older
- Compatible with threaded mode: group top-level thread rows by latest message date

### Exit criteria

- [ ] Filter + Focus + search compose without conflict (document order: folder scope → focus → user filter)
- [ ] Date headers render in flat and threaded modes
- [ ] Drift tests for each predicate

**Estimate:** 5–6 days  
**Depends on:** TB-0  
**Note:** Merge with ROADMAP Pri-1 message filter — single delivery.

---

## 7. TB-4 — Snooze (local)

**Status:** **Landed** (W2, 2026-07-17) — **local-only** v1; no server folder move.

**Goal:** SPEC §7.6 local snooze — client-side resurfacing.

### Model

- `messages.snoozed_until` epoch ms
- Snooze action: set timestamp; hide from default query (`excludeSnoozed: true`)
- Background: on app open + periodic timer, clear snooze when `now >= snoozed_until`, bump `unread` optional
- **No server folder move** in v1 (unlike Spark); document difference

### UI

- Reading pane + swipe + keyboard `B` (boomerang/snooze)
- Presets: later today, tomorrow, next week, custom datetime picker
- Snoozed virtual folder or filter chip “Snoozed”

### Exit criteria

- [ ] Snoozed mail hidden from inbox; reappears at time
- [ ] Survives restart
- [ ] Widget unread counts exclude snoozed (or setting)

**Estimate:** 3–4 days  
**Depends on:** TB-0 query exclusion  
**Schema:** `snoozed_until` in v9

---

## 8. TB-5 — Pin

**Status:** **Landed** (W2, 2026-07-17)

**Goal:** Retention-exempt pins (SPEC §8.2); UI for existing column.

### Work

- Toggle pin on reading pane + list context menu
- `RetentionService`: skip pinned messages (verify M7 behavior)
- Sidebar “Pinned” filter or section
- Widget: optional pinned count (low pri)

### Exit criteria

- [ ] Pinned messages survive retention cleanup in tests
- [ ] Pin state syncs locally only (no provider flag required v1)

**Estimate:** 2 days  
**Depends on:** TB-0 (pinned filter view)

---

## 9. TB-6 — Drafts

**Goal:** Save draft + sync provider Drafts folder.

### Local draft

- Compose autosave every N seconds → `is_draft = 1` row or separate `drafts` table
- Opening draft restores `ComposeDraft`

### Remote draft (phase B)

- Sync `drafts` folder role on bootstrap
- Graph: list/create/update draft messages
- IMAP: `\Draft` flag on Drafts mailbox
- Conflict: local wins until send or explicit discard

### Outbox relationship

- Draft is **not** outbox; converting draft → send deletes draft row, enqueues outbox

### Exit criteria

- [ ] Autosave recovers after kill/relaunch
- [ ] Drafts folder visible in sidebar when provider has it
- [ ] Send from draft works

**Estimate:** 5–7 days  
**Depends on:** Tier A TA-2 compose model

---

## 10. TB-7 — Mobile gestures

**Status:** **Landed** (W2, 2026-07-17) — AVD checklist: [W2_AVD_CHECKLIST.md](W2_AVD_CHECKLIST.md)

**Goal:** Aqua/Spark-level list interaction on Android.

### Swipe actions (B7)

- `Dismissible` or custom slidable on `message_list_pane` (platform split)
- Default: swipe right → archive; swipe left → delete (configurable in settings)
- Long swipe variants: star, snooze (if TB-4 done)

### Swipe between messages (B8)

- `PageView` or horizontal drag in reading pane (portrait)
- Only when message selected

### Pull to refresh (B14 overlap)

- `RefreshIndicator` → `MailboxCubit.syncCurrentFolder()` + `SyncEngine.kick()`

### Exit criteria

- [ ] Swipes call Tier A `archiveSelected` / `deleteSelected` / `toggleStar`
- [ ] No conflict with multi-select mode
- [ ] AVD manual pass documented

**Estimate:** 4–5 days  
**Depends on:** Tier A TA-1 actions

---

## 11. TB-9 — Reading-pane layout + Visual Focus

**Status:** **Nearly complete / in progress** (W5, 2026-07-17) — layout positions + Visual Focus landed; [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) manual pass + TB-9.1 divider deferred

**Goal:** ROADMAP reading-pane position + SPEC §7.5 layout collapse.

### Layout positions (B9)

| Value | Layout |
| --- | --- |
| `right` | Current `Row`: sidebar \| list \| reading |
| `bottom` | List top, reading bottom (`Column`) |
| `top` | Reading top, list bottom |

- Persist `readingPanePosition` in `AppSettings`
- `mail_workspace.dart` single layout builder — **touch once**
- Optional: draggable split divider (TB-9.1 — can defer)

### Visual Focus (§7.5)

- Toggle collapses `FolderSidebar` + list chrome; reading/compose maximized
- Distinct from Focused/Other mail filter

### Exit criteria

- [x] Three positions work on Windows wide window (`MailSplitLayout`, `test/mail_split_layout_test.dart`)
- [ ] Android landscape supports bottom split (Windows-first; not verified)
- [x] Visual Focus toggle persists (`visualFocusEnabled` in AppSettings)
- [ ] [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) manual pass complete

**Estimate:** 3–4 days (partial — 2026-07-17)  
**Integration:** Combine with Tier C multi-window prep in layout refactor — see integration doc.

---

## 12. TB-10 — Push sync

**Status:** **Landed** (W3, 2026-07-17)

**Goal:** Reduce poll latency; honor `supportsPush` capability.

### IMAP IDLE

- Dedicated isolate or long-lived connection per account (desktop always; Android when push enabled)
- **Push on Android cellular:** **supported** — user setting per account (not WiFi-only default)
- On `EXISTS` / `RECENT` → enqueue `incremental` job
- Fallback: existing poll interval when IDLE unsupported or battery saver

### Graph

- Delta query (`/me/mailFolders/{id}/messages/delta`) — already cursor-friendly
- Optional: webhook subscription (complex; **delta poll with short interval** may suffice for v1)

### Sync engine

- New job trigger source: `push_wake` vs `poll_timer`
- `AppSettings`: push enabled per account

### Exit criteria

- [x] New mail appears within ~60s on IDLE-capable IMAP without manual sync
- [x] Android: push on cellular works when user enables setting (`pushOnCellular` default **false**)
- [x] Graph incremental uses delta link when available; `supportsPush: true` when delta path exists

**Estimate:** 7–10 days (actual: W3)  
**Touch:** `sync_engine.dart`, `imap_smtp_mail_provider.dart`, `graph_mail_provider.dart`, `imap_idle_service.dart`, `network_sync_policy.dart`

---

## 13. TB-11 — Starred view

**Status:** **Landed** (W2, 2026-07-17)

**Goal:** Virtual “Starred” entry in sidebar + filter chip.

- `MessageQuery(starredOnly: true)` across account or unified
- No new provider API — local `starred` flag from Tier A

**Estimate:** 1–2 days  
**Depends on:** TB-0, Tier A star

---

## 14. TB-12 — Rich text compose

**Goal:** Minimum rich compose — not a full Word editor.

### Scope

| In scope | Out of scope v1 |
| --- | --- |
| Bold, italic, underline | Tables |
| Links | Embedded images in body |
| Bulleted/numbered lists | Full HTML paste from web |
| HTML body in outbox | Collaborative editing |

### Implementation

- `flutter_quill` or lightweight custom `TextSpan` toolbar — evaluate package weight
- Store `body_html` + `body_plain` fallback on outbox
- Graph: `contentType: HTML`; IMAP: `text/html` MIME part
- Reading pane already WebView — compose preview optional

### Exit criteria

- [ ] Bold/link survive send and display in received test mail
- [ ] Plain-text fallback for text-only recipients

**Estimate:** 5–7 days  
**Depends on:** Tier A TA-2, TA-3 MIME  
**Integration:** Consider building in same compose refactor as TA-2 — see integration doc.

---

## 15. TB-13 — Templates / canned responses

**Goal:** SPEC §7.6 — full message bodies, distinct from signatures.

### Model

`message_templates` table; account-scoped or global per device.

### UI

- Compose → “Insert template” dropdown
- Settings → Templates manager (CRUD)
- Variables deferred (`{{name}}` = Tier C or post-v1)

### Exit criteria

- [ ] Insert overwrites or appends per user choice
- [ ] Templates work with rich compose (TB-12)

**Estimate:** 3–4 days  
**Depends on:** TA-2 compose extension points

---

## 16. TB-14 — List visual polish

**Status:** **Landed** (W2, 2026-07-17)

Absorbs UI enhancement sweep items — full list [UI_ENHANCEMENT_SWEEP.md](UI_ENHANCEMENT_SWEEP.md):

| Item | Work |
| --- | --- |
| Read-row dimming | Mute `message_list_pane` text when `!unread` |
| Pull to refresh | TB-7 |
| DEF-001 shortcuts | Fix workspace focus — may move to Tier C keyboard pass |
| Density consistency | After theme tokens |

**Estimate:** 2–3 days

---

## 17. Testing matrix

| Phase | Unit | Manual |
| --- | --- | --- |
| TB-0 | MessageQuery SQL | — |
| TB-1 | thread_id assignment | reply chain display |
| TB-2 | filter predicates, date buckets | combined filters |
| TB-4 | snooze resurfacing | timezone edge |
| TB-6 | draft autosave | Drafts folder sync |
| TB-7 | — | AVD swipes |
| TB-9 | layout setting persist | 3 desktop layouts |
| TB-10 | delta cursor | IDLE receive |
| TB-12 | HTML MIME round-trip | send/receive formatting |

---

## 18. Schedule sketch (after Tier A)

| Week | Focus |
| --- | --- |
| 1 | TB-0 + TB-1 threading |
| 2 | TB-2 filters + TB-4 snooze + TB-5 pin |
| 3 | TB-6 drafts + TB-11 starred |
| 4 | TB-7 mobile + TB-9 layout |
| 5 | TB-10 push (stretch) + TB-12 rich compose |
| 6 | TB-13 templates + TB-14 polish |

**Parallel:** TB-10 can run alongside TB-7–9 if second dev/stream available.

---

## 19. Locked decisions (2026-07-16)

| # | Question | Locked choice |
| --- | --- | --- |
| 1 | Default inbox | **Threaded** with flat toggle |
| 2 | Snooze | **Local only** v1 |
| 3 | Rich editor | Spike **`flutter_quill`** |
| 4 | Push on Android cellular | **Supported** — per-account **settings option** |
| 5 | Date groups + threads | **Yes** — group by latest message in thread |

*Full list: [V1_TIER_INTEGRATION.md §12](V1_TIER_INTEGRATION.md#12-locked-decisions-2026-07-16).*

---

*See [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md) for cross-tier consolidation before implementation.*
