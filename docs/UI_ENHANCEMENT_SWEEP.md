# UI Enhancement Sweep

| Field | Value |
| --- | --- |
| Status | Active backlog — open for additions |
| Purpose | Visual polish & mailbox interaction pass after foundation (M0–M12) |
| V1 delivery | **W2**, **W5**, **W7**, plus **W4** (outbound font, signature images) |
| Related | [ROADMAP.md](ROADMAP.md), [DEFECTS.md](DEFECTS.md), [TIER_B_PLAN.md §16](TIER_B_PLAN.md#16-tb-14--list-visual-polish) (TB-14) |
| Last updated | 2026-07-18 (UI-P21 notes: tabs / section nav vs endless scroll) |

The UI enhancement sweep is the **catch-all for polish and look-and-feel settings** that makes ByteMail feel like a finished client. Theme packs landed in M8; **built-in palette refresh + `content` token landed 2026-07-16** ([UI-L8](#3-landed-reference--do-not-re-implement)). **W2 list polish landed 2026-07-17** (UI-P1/P2/P7/P12 → UI-L9–L12). **Custom themes**, fonts, and export remain **W7** ([§6](#6-look--feel-extensions-user-backlog)).

**How to add items:** Append to [§7 Backlog](#7-backlog--add-here) or discuss with Steve — look-and-feel extensions live in [§6](#6-look--feel-extensions-user-backlog).

---

## 1. Sweep vs feature tiers

| Kind | Goes in… | Example |
| --- | --- | --- |
| Visual polish, contrast, spacing | **This sweep** | Read-row dimming |
| New capability | Tier A/B/C plans | Threading, filters |
| Bug / regression | [DEFECTS.md](DEFECTS.md) | DEF-001 shortcuts |
| Defect with UX impact | **Both** — defect + sweep row | DEF-007 read-state flicker |

---

## 2. V1 wave mapping

| Wave | Sweep focus | Rationale |
| --- | --- | --- |
| **W2** | Message list, mobile list gestures, read dimming, pull-to-refresh, date section headers styling | Same `message_list_pane` pass as TB-14 |
| **W5** | Keyboard/focus (DEF-001), layout chrome, selection affordances | `mail_workspace` touch once — **W5 landed**; UI-P3/DEF-001 closed; TC-9 desktop actions landed |
| **W7** | Theme token polish, **custom themes**, **settings export**, **UI fonts**, density, widget theming, empty states | Appearance settings surface |
| **W4** | **Outbound message font**, **signature images**, compose polish | Unified compose system |

```text
         ┌── W2: list & mobile polish
Sweep ───┼── W5: desktop focus & chrome
         ├── W7: themes, custom themes, fonts, export, density
         └── W4: outbound font, signature images
```

---

## 3. Landed (reference — do not re-implement)

| ID | Item | Notes |
| --- | --- | --- |
| UI-L1 | Mark read / unread — individual + bulk | Ctrl+U, bulk toolbar, provider push |
| UI-L2 | Per-account folder tree | Collapsible accounts, folder-scoped sync |
| UI-L3 | Account color anchors in list + reading pane | Jewel-tone chips |
| UI-L4 | Five theme selectors + Calm/Compact density | M8 — palette polish landed (UI-L8 / UI-P4) |
| UI-L5 | Focused/Other filter chips | When focus enabled |
| UI-L6 | Multi-select + bulk mark toolbar | Ctrl/Shift selection |
| UI-L7 | Header details sheet | Reading-pane Headers action |
| UI-L8 | Built-in palette refresh + `content` surface token | 2026-07-16 — five approved packs; reading pane + compose body; closes [DEF-019](DEFECTS.md) |
| UI-L9 | Read messages dimmer in list (UI-P2) | 2026-07-17 (W2) — mute from/subject/snippet on read rows |
| UI-L10 | Pull-to-refresh affordance (UI-P7) | 2026-07-17 (W2) — `RefreshIndicator` on message list |
| UI-L11 | Selection highlight vs account accent (UI-P12) | 2026-07-17 (W2) — azure wash distinct from account stripe |
| UI-L12 | Unread counts — local recount (UI-P1) | 2026-07-17 (W2) — `recountUnreadCounts()` from SQLite |

---

## 4. Open & partial (scheduled in V1)

| Pri | ID | Item | Status | V1 wave | Primary files | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| **Pri-2** | UI-P3 | **[DEF-001](DEFECTS.md)** — Ctrl shortcuts without Quick Reply focus | **Landed** (W5, 2026-07-17) | **W5** | `mail_workspace.dart`, `keyboard_intents.dart`, `mailbox_shortcuts.dart` | TC-9 keymap pass complete with W5 land |
| **Pri-2** | UI-P5 | **[DEF-007](DEFECTS.md)** — sync overwrites local read state | Open | W2/W3 | `sync_engine.dart`, `drift_mail_repository.dart` | UI flicker on refresh; merge policy |
| **Pri-3** | UI-P6 | **Density/spacing consistency** | **Landed** (W7) | **W7** | Shell panes, `density.dart` | Calm vs Compact metrics + empty-state sizes |
| **Pri-3** | UI-P8 | **Empty states** | **Landed** (W7) | **W7** | List, reading pane, search, no accounts | Shared `EmptyState` + CTAs |
| **Pri-3** | UI-P9 | **Loading / error skeletons** | Not started | W2/W7 | `reading_pane.dart`, list | Body fetch, sync-in-progress |
| **Pri-3** | UI-P10 | **Android widget theme tokens** | Not started | **W7** | `widget_snapshot_service`, Kotlin | SPEC open Q9 — all five themes vs Dark+Black |
| **Pri-3** | UI-P11 | **Sync status indicator polish** | Not started | W3/W7 | Title bar / sidebar | Clear syncing vs error vs idle |
| **Pri-3** | UI-P13 | **Search sheet UX** | Not started | W7 | `search_sheet.dart` | Remote search progress, empty results |
| **Pri-3** | UI-P14 | **Folder sidebar density** | Not started | W7 | `folder_sidebar.dart` | Unread badge alignment, collapse animation |
| **Pri-3** | UI-P15 | **Account nicknames in chrome** | Not started | W7 | `EditAccountSheet` label → sidebar | Outlook-style display name vs address |

---

## 5. Cross-references (sweep absorbs or touches)

| Source | Item | Sweep ID |
| --- | --- | --- |
| TB-14 | List visual polish | UI-P2, UI-P7, UI-P12 — **landed W2** (UI-L9–L11) |
| DEF-019 | Reading pane hardcoded navy | UI-L8 (closed 2026-07-16) |
| TB-9 / W5 | Visual Focus collapse | **Landed** (W5, 2026-07-17) — layout + collapse; [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) passed (operator) |
| TC-9 | Full keymap + help overlay | UI-P3 **landed** with W5; Ctrl+F, print/EML/detach landed |
| TC-11 | Widget theme variants | UI-P10, UI-P16 |
| UI enhancement ROADMAP (legacy) | All Pri-1–3 rows | Migrated to this doc |

---

## 6. Look & feel extensions (user backlog)

Not strictly “polish” — **appearance & settings product surface**. Crosses theme system, settings persistence, compose (W4), and optional export. Grouped here because it shapes look and feel end-to-end.

### 6.1 Items (2026-07-16)

| Pri | ID | Item | Status | V1 wave | Primary files | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| **Pri-2** | UI-P16 | **Custom themes (multiple)** | **Landed** (W7) | **W7** | `theme_tokens.dart`, `appearance_sheet.dart`, `custom_themes` table | Pick any **built-in theme as base** → adjust token colors → **Save as** named custom theme; **multiple** custom themes in picker alongside Light/Dark/… |
| **Pri-2** | UI-P17 | **Export / import settings** | **Landed** (W7) | **W7** | `app_settings_cubit.dart`, `settings_export_service.dart` | JSON export: themes, custom themes, density, fonts, focus prefs, layout prefs — **no credentials**; import merge or replace with validation |
| **Pri-2** | UI-P18 | **App-wide UI font** (family, size, color) | **Landed** (W7) | **W7** | `app_settings_state.dart`, `app_theme.dart` | User-selectable font for **all in-app screens**; size scale or pt; optional default text color override via theme tokens |
| **Pri-2** | UI-P19 | **Outbound message font** | **Partial** (W4) — default `kOutboundFontFamily` wrap on send; user family/size/color prefs not shipped | **W4** | `compose_sheet` / `ComposeDraft`, MIME builder | Font family, size, color for **sent mail** — distinct from UI font; per-account override optional; flows through HTML/plain MIME |
| **Pri-2** | UI-P20 | **Signature images** (logos, etc.) | **Landed (code)** with W4; checklist pending | **W4** | `account_signatures`, MIME send | **HTML signatures** (locked Tier A); embed images via CID→data-URI on send; local asset per signature; ties UI-P19/HTML compose |

### 6.2 Architecture notes

**Custom themes (UI-P16)**

```text
built_in_theme (Light | Dark | …)
  → user edits token slots (background, panel, content, accent, text, muted, …)
  → save as custom_themes row: { id, name, base_theme_id, token_overrides_json }
  → theme picker shows Built-in + My Themes sections
```

- SPEC five packs remain the **seed** set; custom themes are **forks**, not replacements.
- Widget snapshots / Android Kotlin may use simplified token subset for custom themes (UI-P10 dependency).

**Settings export (UI-P17)**

| Include | Exclude |
| --- | --- |
| `themeId`, custom themes, density, UI/outbound font prefs | OAuth tokens, passwords, `credentialsRef` |
| Focus enablement, retention days, reading-pane layout | Message bodies, attachment blobs |
| Signature **metadata** (not binary logos unless user opts in) | Raw SQLite |

**Fonts (UI-P18, UI-P19)**

| Scope | Settings keys (illustrative) |
| --- | --- |
| In-app UI | `ui_font_family`, `ui_font_size_scale`, `ui_text_color` nullable |
| Outbound mail | `outbound_font_family`, `outbound_font_size`, `outbound_font_color`; optional per-account in `account_settings_json` |

- UI fonts apply via `ThemeData.textTheme` / `google_fonts` or system font list.
- Outbound fonts apply in MIME HTML `font-family` / `color` and plain-text fallback.

**Signature images (UI-P20)**

- `account_signature_assets`: `id`, `signature_id`, `local_path`, `content_id`, `mime_type`
- Editor: insert image → stores sandbox file → HTML `<img src="cid:…">`
- Send path: `multipart/related` in W4 MIME isolate (same as inline compose images)

### 6.3 Schema additions (when scheduled)

| Table / column | Item |
| --- | --- |
| `custom_themes` | UI-P16 |
| `app_settings` / prefs keys for fonts | UI-P18, UI-P19 |
| `account_signature_assets` | UI-P20 |
| Export format version field | UI-P17 |

*Prefer bundling `custom_themes` + font pref keys in W0 schema v5 if promoted to V1 gate; otherwise migration at W7.*

### 6.4 Cross-tier links

| ID | Also see |
| --- | --- |
| UI-P19, UI-P20 | [TIER_A_PLAN.md](TIER_A_PLAN.md) TA-2 / W4 compose |
| UI-P17 | [TIER_D_PLAN.md](TIER_D_PLAN.md) D-G5 full DB backup — settings export is lighter subset |
| UI-P16 | Supersedes sweep non-goal “no themes beyond five” — **custom forks allowed** |

---

## 7. Backlog — add here

*Next ID: **UI-P31** …*

| Pri | ID | Item | Status | V1 wave | Primary files | Notes |
| --- | --- | --- | --- | --- | --- | --- |
| Pri-2 | UI-P21 | **Settings organized by functional area** | Backlog — **post-V1** | V1.1+ | `lib/ui/settings/`, `lib/settings/` | **Post-V1** — not a V1/Final-wave blocker. Replace the growing single long settings scroll with **tabs / section navigation** so functional vs visual settings are not one endless list. Sections: Accounts, Appearance (visual), Reading & message list, Compose, Sync & storage, Notifications, Privacy & security, Shortcuts & accessibility, and Advanced/About. **Navigation pattern:** desktop **tabs or adaptive navigation rail/list** (pick section → show that section’s controls only); mobile **section pages** (list of areas → drill-in). Searchable by setting label/keyword. Retain existing setting values and persistence. **W6 (2026-07-17):** dedicated **Notifications** sheet landed (`notifications_sheet.dart`); full functional-area reorg remains post-V1. **Operator (2026-07-18):** hate scrolling one long settings list — want tabs (or equivalent sectioned nav). Acceptance: a user can identify the owning section from its name, open a section via tab/rail/list (not endless scroll of unrelated controls), search by label/keyword, and reach any setting without scanning the whole surface. |
| Pri-2 | UI-P22 | **Search results show message datetime** | Backlog | **W7** / V1.1 | `lib/ui/search/search_sheet.dart`, list projectors | Local and especially **remote/server** search hits must show a clear datetime (`whenLabel` and/or absolute date for older mail) so near-duplicate subjects/senders are distinguishable. Acceptance: every search result row shows a readable sent/received time; older-than-today items use a date (not only “Yesterday”-style relative labels when that would collide). |
| Pri-2 | UI-P23 | **Folder context menu: mark all read/unread** | Backlog — post-V1 | V1.1+ | sidebar folder tree, `MailboxCubit`, provider `setUnread` bulk | Right-click (desktop) / long-press menu on a folder → Mark all as read / Mark all as unread for that folder’s messages (local optimistic + provider push where supported). Acceptance: action completes without opening the folder first; unread badge recounts. |
| Pri-2 | UI-P24 | **Ctrl+A select all messages** | Backlog | **W7** | `mail_workspace.dart`, `keyboard_intents.dart`, `MailboxCubit` | With list focus (and not while editing text), Ctrl+A selects all currently visible/projected messages for existing bulk actions (move, mark read, etc.). Respect text-field safety. Acceptance: Ctrl+A fills `selectedMessageIds`; Escape / click clears; works with threaded and flat modes. |
| Pri-3 | UI-P25 | **Discoverable per-message multi-select** | Backlog — post-V1 | V1.1+ | message list row, density | Ctrl/Shift multi-select already landed (UI-L6). Add clearer individual selection (e.g. always-available checkbox or hover affordance on desktop; keep mobile long-press). Acceptance: user can add/remove single rows from the bulk set without memorizing modifier keys. |
| Pri-1 | UI-P26 | **Honor remote read/unread from other clients on sync** | Backlog | **W7** (ties UI-P5 / [DEF-007](DEFECTS.md)) | `imap_smtp_mail_provider.dart`, `sync_engine.dart`, upsert merge | IMAP already FETCHes `FLAGS` / Graph `isRead`. Ensure sync applies server Seen/read for mail already read in another client, without undoing in-flight local mark-read/unread (coordinate merge with DEF-007). Acceptance: mark read in Thunderbird/Outlook → next ByteMail sync shows read; local mark then immediate sync does not flicker back incorrectly. |
| Pri-2 | UI-P27 | **Auto-mark as read after open dwell** | **Landed** (W7) — [DEF-034](DEFECTS.md) closed | **W7** (not W5 blocker) | `auto_mark_as_read.dart`, `reading_pane.dart` | After an unread message is open/selected in the reading pane for **5 continuous seconds** (default ON, fixed delay for V1), mark read via existing unread mutation + provider push. Cancel timer on selection change. |
| Pri-2 | UI-P28 | **Auto-mark settings (delay / off)** | Backlog — **post-V1** | V1.1+ | `AppSettings`, Appearance / Reading section | User-configurable auto-mark dwell seconds and ability to disable auto-marking. Default remains 5s / ON when unset. Ties UI-P21 Reading & message list section. Acceptance: setting persists; 0 or Off disables; custom delay used instead of hardcoded 5s. |
| Pri-2 | UI-P29 | **One-click clear active filters** | Backlog — **post-V1** | V1.1+ | filter bar / chip row, `MailboxCubit` | Dogfood gap after Final-wave Phase B: need a single obvious control (chip × / toolbar Clear) that resets ephemeral `userFilter` in one click without opening the filter sheet. Does **not** delete saved presets. Acceptance: with any active filter, one click restores the unfiltered list; control hidden or disabled when no filter is active. |
| Pri-1 | UI-P30 | **Hold / pause auto-mark for in-view message (Unread filter)** | Backlog — **post-V1** | V1.1+ | `auto_mark_as_read.dart`, reading pane, filter projection | **Dogfood (2026-07-18):** with **Unread** (or any filter that excludes read) active, the 5s auto-mark (UI-P27) marks the open message read → it drops out of the filtered list and the reading pane closes/advances — jarring while still reading. Need an option to **disable / pause auto-mark for the currently in-view email** (and/or keep selection pinned after auto-mark under restrictive filters). Ties UI-P28 global off/delay. Acceptance: user can keep reading an auto-marked message without the pane vanishing mid-read when Unread filter is on; default V1 behavior may remain until this ships. |
| | | *(additional items below)* | Planned | | | |

### Addition template (copy a row)

```markdown
| Pri-? | UI-P?? | **Short title** | Planned | W? | `file.dart` | One-line acceptance criteria |
```

---

## 8. Acceptance — sweep “done” for V1

Sweep is **complete for V1** when:

- [x] UI-P2 read dimming shipped (W2 — 2026-07-17, [UI-L9](UI_ENHANCEMENT_SWEEP.md))
- [x] UI-P3 DEF-001 fixed (W5 — 2026-07-17, [DEF-001](DEFECTS.md))
- [x] UI-P4 theme token pass complete for all five packs (landed 2026-07-16 — [UI-L8](UI_ENHANCEMENT_SWEEP.md))
- [x] UI-P7 pull-to-refresh shipped (W2 — 2026-07-17, [UI-L10](UI_ENHANCEMENT_SWEEP.md))
- [x] UI-P12 selection highlight shipped (W2 — 2026-07-17, [UI-L11](UI_ENHANCEMENT_SWEEP.md))
- [x] UI-P1 unread recount shipped (W2 — 2026-07-17, [UI-L12](UI_ENHANCEMENT_SWEEP.md))
- [x] UI-P6 density consistency pass (W7)
- [x] UI-P8 empty states for main panes (W7)
- [ ] UI-P5 DEF-007 read-merge fixed or documented workaround
- [x] UI-P27 / [DEF-034](DEFECTS.md) auto-mark 5s shipped (V1; not W5 blocker)
- [ ] All **Pri-1** rows in §4 and §6 resolved or explicitly deferred with reason
- [x] UI-P16–P18 shipped (W7); UI-P19/P20 tracked with W4 (partial / code landed)
- [ ] No open **Pri-2** sweep items blocking V1 exit checklist appearance gates

---

## 9. Non-goals (this sweep)

- Conversation threading UI (TB-1 / W2 feature, not polish)
- Rich compose toolbar (W4) — but outbound font (UI-P19) **is in scope**
- Arbitrary user CSS injection into HTML mail viewer
- Full mail-database backup (see Tier D D-G5) — settings-only export (UI-P17) **is in scope**

---

## 10. Document history

| Date | Change |
| --- | --- |
| 2026-07-16 | Initial sweep doc; migrated ROADMAP table; added wave mapping and backlog section |
| 2026-07-16 | §6 Look & feel extensions: custom themes, settings export, UI/outbound fonts, signature images (UI-P16–P20) |
| 2026-07-16 | UI-L8 / UI-P4 landed: five built-in palette refresh + `content` token ([DEF-019](DEFECTS.md)); custom themes (UI-P16) still **W7** |
| 2026-07-17 | W2 landed: UI-P1/P2/P7/P12 → UI-L9–L12; acceptance checkboxes updated |
| 2026-07-17 | **W5 landed** (2026-07-17): UI-P3/DEF-001 closed; TB-9 layout + Visual Focus; [W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md) passed (operator); **W6 unlocked** |
| 2026-07-17 | Added UI-P21 post-V1 settings information architecture: functional sections, adaptive navigation, and settings search |
| 2026-07-17 | Backlog UI-P22–P26: search result datetimes; folder mark-all read; Ctrl+A; discoverable multi-select; remote Seen sync (ties DEF-007) |
| 2026-07-17 | DEF-034 / UI-P27 V1 auto-mark 5s (default ON, fixed delay); UI-P28 post-V1 settings (delay / off) |
| 2026-07-18 | UI-P29 post-V1 one-click clear active filters (dogfood after Phase B) |
| 2026-07-18 | UI-P30 Pri-1 post-V1: pause/hold auto-mark for in-view message under Unread filter |
| 2026-07-18 | UI-P21 notes clarified: **tabs / section navigation** (desktop tabs or rail; mobile section pages; not one endless scroll); status confirmed **post-V1** (operator dogfood) |

---

*Add your items to §6 and ping Steve — we'll slot them into W2/W5/W7 without a separate release.*
