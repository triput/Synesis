# Synesis V2.0 Plan — PIM Headline

| Field | Value |
| --- | --- |
| Status | **In progress** — **Waves 0–6b + G complete** (**729+ tests** after Operation Flat Zero 2026-08-25). **Wave 6c parked.** V2.0 feature spine done; exit = PIM docs/E2E + optional Wave 7 polish. **Next operator track:** **Wave WEB** (personal, not release-blocking). See [V2_WAVE_6B_CHECKLIST.md](V2_WAVE_6B_CHECKLIST.md) · [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md). |
| Headline | Contacts & calendar (TD-A) — not a new phone OS |
| Prerequisite | V1 exit signed off; **V1.5 complete** ([V1_5_PLAN.md](V1_5_PLAN.md)) |
| Watch | **P3 → V2.1** (not V2.0 critical path) |
| Enterprise crypto / shared mail / AI draft·summarize | **Maybe/Someday** — not V2.0 critical path unless demand appears |
| Owners | Steve (orchestrate) · Tesla (Graph + **Google PIM** / sync) · Jules (CardDAV spike + UI modules) · Renee (QA) · Page (docs) |
| Last updated | 2026-08-25 (Operation Flat Zero complete; **Wave WEB** next — personal operator track, not release-blocking) |
## 1. Locked product decisions (2026-07-22)

| # | Decision |
| --- | --- |
| 1 | V2 headline = **PIM** (contacts + calendar) |
| 2 | Shell = **Outlook-style modules** — Mail (home/default), **Calendar (deep)**, Contacts (useful / picker-led) |
| 3 | Calendar depth = daily-driver CRUD (add/edit/remove; month + week or agenda; basic recurrence + reminders). Cut rooms/shared ACLs/Teams deep links from V2.0 |
| 4 | **CardDAV + CalDAV in V2.0** — not deferred to V2.1 |
| 5 | Provider impl order = **A** (below) — Graph PIM first for speed; CardDAV/CalDAV still day-one of the *release* |
| 6 | CardDAV/CalDAV dogfood target = **Runbox** |
| 7 | **Parallel tracks OK** — Tesla Graph PIM ∥ Jules CardDAV discovery spike after local schema (P0) |
| 8 | **V2.0a** includes meeting-mail bridge (accept/decline/tentative + `.ics` → event draft) |
| 9 | Galaxy Watch = **P3 / V2.1** |
| 10 | Enterprise SKU (PGP/S/MIME, shared mailbox) + **AI draft/summarize** = **Maybe/Someday** until eval/paying need; if one is opted in later, treat the other as a paired companion |
| 11 | CardDAV/CalDAV dogfood host = **Runbox** (`https://dav.runbox.com/` — app password if 2FA) |
| 12 | **Multi-calendar + multi-contact-list** — first-class collections per account; select 1+ to display; Outlook-like overlay / side-by-side for calendars (P6 UI) |
| 13 | **Cross-account copy** (events + contacts) via drag-and-drop UX (desktop) with mobile fallback menu — **Wave 6** (after Wave G); local-first duplicate + push to target collection |
| 14 | **Google XOAUTH PIM** — People + Calendar API (not CardDAV/CalDAV); **Wave G** critical path before DnD; operator principal calendar is Google Workspace |

## 2. Account → PIM binding

| Mail account type | Default PIM source | Notes |
| --- | --- | --- |
| Microsoft Graph | Graph Contacts + Calendar | Optional extra CardDAV/CalDAV book later |
| Google (XOAUTH IMAP) | Google People + Calendar API preferred; CardDAV/CalDAV fallback | Avoid double-sync of same book |
| IMAP / Other (e.g. Runbox) | **CardDAV + CalDAV** | Base URL dogfood: `https://dav.runbox.com/` (trailing slash); full email as username; app password if 2FA |

Local store is provider-agnostic (`contacts` / `events` + sync cursors), same philosophy as mail.

## 3. Wave 0 — Account identity (A+B hybrid) [pre-PIM gate]

**Status:** **Complete** (2026-07-27). Gate cleared — proceed to Wave H, then V2.0a PIM P0.

| Item | Scope | Notes |
| --- | --- | --- |
| **Auto-seed display name (B)** | On add account | Derive friendly display name from email address when none supplied — **landed** |
| **User-editable display name (A)** | Edit account + rail | User can override seeded name; **accent color** picker unchanged — **landed** |
| **Rail truncation fix** | Account rail / sidebar | End forced single-letter truncation — show readable label (ellipsis only when space-constrained) — **landed** (includes rail overflow fix) |
| **Avatar / monogram hover cards (C)** | Deferred | **V-Next / late polish** — not Wave 0 critical path |

**Exit (Wave 0):** ✅ New accounts get a sensible default name; existing accounts editable; rail shows multi-character labels (no forced single-letter truncation; overflow layout fixed); no regression to accent colors or account cap.

## 4. Wave H — Dependency hygiene [pre-V2.0a gate]

**Status:** **Complete** (2026-07-27 Batch 4) — with known residuals in [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md). **Wave 1 / V2.0a PIM P0 complete** (2026-07-27).

Per-version hygiene after V1.5 freeze: toolchain + pub debt + native/plugin skew + docs SDK pins. Checklist: [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md).

**Sequence:** Wave 0 → **Wave H ✅** → **Waves 1–G ✅** → **Wave 6P ✅** → **Wave 6 ✅** → **Wave 6b ✅** → **Operation Flat Zero ✅** (2026-08-25) → **Wave 6c parked** → **Wave WEB** (personal, very soon) ∥ optional **Wave 7** ∥ **Wave MH** slices → **V2.0 freeze/tag** → **Wave H2** → **Wave R** → V2.1.

| Batch | Scope | Notes |
| --- | --- | --- |
| **H1 — SDK pin verify** | Flutter/Dart SDK, `environment.sdk`, README/docs pins | ✅ `.flutter-version` 3.44.6 / `^3.12.2` |
| **H2 — Soft upgrades** | Patch/minor `pub get` resolution | ✅ `uuid` 4.6.0, `webview_flutter_windows` 1.1.1 |
| **H3 — Pub majors** | `pub outdated` major candidates | ✅ Landed or deferred with rationale |
| **H4 — Native / KGP / sqlite3mc** | Android Gradle/KGP, plugin native debt, `sqlite3mc` hook | ✅ Android debug + sqlite3mc; KGP escape hatches kept |
| **H5 — Verify exit** | Full test + build matrix | ✅ `flutter test` 510/510; Windows + Android debug PASS; analyze 0 errors |

**Exit (Wave H):** ✅ Cleared. Wave 1 / V2.0a P0 (expanded local PIM schema) **complete** (2026-07-27). Residuals (operator dogfood H5-M\*, Pri-3 AppLinks/fln tests, KGP hatches, deferred majors) tracked in the Wave H checklist — do not re-hold PIM.

## 5. Operator waves (working sequence)

**Status:** **Wave 1 complete** (2026-07-27, `00ebdef`); **Wave 2 complete** (2026-07-27, `b526e70`); **Wave 3 complete** (2026-07-27, 551 tests); **Wave 4 complete** (2026-07-27, `f2bd29b`, 556 tests); **Wave 5 complete** (2026-07-27, `73c181d`, 585 tests); **Wave G complete** (2026-07-27, `f4c21b0`, **597 tests**); **Wave 6P complete** (2026-08-04, E1–E11 ✅, **645 tests**); **Wave 6 complete** (2026-08-04, E10+E11 **GO**, **659 tests**) — [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md). **Wave 6b complete** (2026-08-12, E8 **GO**, **668 tests**) — [V2_WAVE_6B_CHECKLIST.md](V2_WAVE_6B_CHECKLIST.md) · [V2_WAVE_6B_QA.md](V2_WAVE_6B_QA.md). **Wave 6c parked** — next = Android Pri-2 (DEF-085, DEF-082) / Wave 7 candidates. V2.0a / V2.0b / V2.0c / V2.0d below remain **release buckets** for ship grouping; operator execution follows this table.

| Wave | Scope | Owner(s) | Maps to |
| --- | --- | --- | --- |
| **Wave 0** | Account identity (display names, rail labels) | Jules / Andi | Pre-PIM gate |
| **Wave H** | Dependency hygiene (SDK, pub, native/KGP) | Steve + team | Pre-V2.0a gate |
| **Wave 1** | **P0 — expanded schema foundations** (multi-list contacts, multi-calendar, FTS, sync job no-ops) | Jules + Tesla | **V2.0a P0** ✅ **Complete** (2026-07-27) |
| **Wave 2** | P1 — Graph contacts + calendars (multi-list/cal sync) | Tesla | **V2.0a P1** ✅ **Complete** (2026-07-27, `b526e70`) |
| **Wave 3** | P2 — meeting-mail bridge (ICS, RSVP, local `.ics` drafts) | Tesla + Jules | **V2.0a P2** ✅ **Complete** (2026-07-27, `7cbfdaa`, 551 tests) |
| **Wave 4** | P3–P4 — CardDAV/CalDAV (Runbox; multi address-book / calendar discovery) | Tesla + Jules | V2.0b ✅ **Complete** (2026-07-27, `f2bd29b`, 556 tests) |
| **Wave 5** | P5–P6 — compose contact picker (FTS across selected lists) + Calendar module UI (multi-select overlay / side-by-side) | Jules + Tesla | V2.0c ✅ **Complete** (2026-07-27, `73c181d`, 585 tests) |
| **Wave G** | **Google People + Calendar API** for XOAUTH Google accounts (`GooglePimProvider` → `DriftPimStore`; no DAV) | Tesla | **V2.0d** ✅ **Complete** (2026-07-27, `f4c21b0`, **597 tests**) |
| **Wave 6P** | **Performance UX (Sync Honesty)** — decouple local refresh vs remote sync spinners; non-blocking kick; title-bar honesty; UI-P11 / UI-P9 partial / DEF-015 / DEF-007; P2 isolate if post-P0 jank | Jules + Andi + Tesla | **Complete** (2026-08-04) — E1–E11 ✅ (**645 tests**); E11 deferred — [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md) |
| **Wave 6** | Cross-account / cross-list **DnD copy** for events + contacts (local copy + push); **D1 locked:** Graph + Google remote push; DAV-as-target = local-only + honest label | Jules + Tesla | **Complete** (2026-08-04) — E10+E11 **GO** (**659 tests**) — [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md) · [V2_WAVE_6_QA.md](V2_WAVE_6_QA.md) |
| **Wave 6b** | CalDAV/CardDAV **create-only write** for copy targets (Runbox) | Tesla + Jules | **Complete** (2026-08-12) — E7 **GO** + E8 Trish **GO** (**668 tests**) — [V2_WAVE_6B_CHECKLIST.md](V2_WAVE_6B_CHECKLIST.md) · [V2_WAVE_6B_QA.md](V2_WAVE_6B_QA.md) |
| **Wave 6c** | **Calendar series / recurring event copy** semantics (this occurrence vs series vs new series) — not a Tasks module | Jules + Tesla | **Parked** — hard-stop after 6b; not planned-as-next |
| **Wave 7** | **Final polish / Trish extras** — UI niceties & enhancement backlog if time permits (resizable panes, list context menus, mobile nav polish, overflow sweeps, widget wishlist). **Not V2.0 critical path.** | Jules / Andi | Scope-creep parking lot — **last within V2.0** |
| **Wave H2** | **Dependency hygiene (post–V2.0)** — toolchain + `pub outdated` majors + native/plugin debt + docs SDK pins; revisit Wave H residuals | Steve + team | **TBD** — after **V2.0 freeze/tag**; before V2.1 features |
| **Wave R** | **Refactoring pass** — dead code, API tighten, AGENTS.md pattern debt; **no new product features** | Jules / Andi (+ Tesla if sync surfaces) | **TBD** — after Wave H2; before V2.1 features |
| **Wave MH** | **Mail hygiene digest** — desktop CLI probe (read-only multi-account digest + subscription Sheet). Spec locked. Phone out. Later public desktop report on the same library. | Tesla + Jules (plan next) | **Spec locked** — [design](superpowers/specs/2026-08-19-mail-hygiene-digest-design.md). Interleave OK; **not** freeze-blocking; **not** a substitute for Wave H2 |
| **Wave WEB** | **Personal web client** — local Flutter web + Cloudflare tunnel for Trish; not multi-tenant SaaS; keep APIs self-hostable later | Jules + Tesla | **Very soon** (2026-08-25) — **operator personal track**; design → MVP → tunnel; **not** V2.0 release-blocking |

Checklists: [V2_0A_P0_CHECKLIST.md](V2_0A_P0_CHECKLIST.md) (Wave 1 exit); [V2_WAVE2_CHECKLIST.md](V2_WAVE2_CHECKLIST.md) (Wave 2 exit ✅); [V2_WAVE3_CHECKLIST.md](V2_WAVE3_CHECKLIST.md) (Wave 3 exit ✅); [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md) (Wave 4 exit ✅, `f2bd29b`, 556 tests); [V2_WAVE5_CHECKLIST.md](V2_WAVE5_CHECKLIST.md) (Wave 5 exit ✅, `73c181d`, 585 tests); [V2_WAVE_G_CHECKLIST.md](V2_WAVE_G_CHECKLIST.md) (Wave G exit ✅, `f4c21b0`, **597 tests**); [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md) (Wave 6P exit ✅, **645 tests**); [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md) (Wave 6 exit ✅, **659 tests**). Wave 4 QA: [V2_WAVE4_QA.md](V2_WAVE4_QA.md) (**GO**). Wave 5 QA: [V2_WAVE5_QA.md](V2_WAVE5_QA.md) (**GO**). Wave G QA: [V2_WAVE_G_QA.md](V2_WAVE_G_QA.md) (**GO**). Wave 6 QA: [V2_WAVE_6_QA.md](V2_WAVE_6_QA.md) (**GO**).

### Wave 6P — Performance UX (Sync Honesty)

**Status:** **P0 code + tests landed** (2026-08-03) — E1–E6 ✅; Renee **GO** on E6 (**626 tests**). E7 Android operator dogfood pending; P1/P2 open. Checklist: [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md).

| Slice | Scope |
| --- | --- |
| **P0** | Honest sync chrome — separate local refresh from remote sync-in-flight; non-blocking `kick()` / `kickFresh()` on pull-to-refresh, manual sync, add-account |
| **P1** | UI-P11 sync indicator polish; UI-P9 partial (body skeletons); DEF-015 per-message headers; DEF-007 read/unread merge policy |
| **P2** | Tesla SyncEngine isolate work **if** post-P0 profiling confirms frame jank (committed, not optional scope creep) |

**Out of MVP:** Wave 6 DnD copy; full SPEC isolate migration unless P2 gate fails; Wave 7 polish bucket.

### Wave 6 — Cross-account DnD copy (+ 6b / 6c)

**Status:** **Planning** — [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md). **D1 locked** (2026-08-04).

| Wave | Scope | Notes |
| --- | --- | --- |
| **6** | Graph ↔ Google event + contact copy (DnD desktop / long-press mobile); local duplicate → `events_copy` / `contacts_copy` | DAV targets: local-only + “not synced yet” until 6b |
| **6b** | CalDAV/CardDAV create-only write for copy targets | ~8–12 eng-days; after Wave 6 |
| **6c** | Calendar **series** / recurring event copy UX (RRULE, series-master vs instance) | Prefer separate wave — non-trivial cross-provider LOE; **not** a Tasks module |
| **Post–6** | Corporate Graph research (`microsoft.com` / Entra org tenants) | Incremental version — admin consent, CA, publisher verification; not 6/6b/6c |

### Operation Flat Zero — Android mail dogfood (2026-08-25)

**Status:** **Complete** — parallel burn before V2.0 tag; **729+ tests** on `v2.0`. Not a release bucket; operator dogfood closure.

| Wave | Item | Commit(s) | Notes |
| --- | --- | --- | --- |
| W0 | [DEF-078](DEFECTS.md) phone reading chrome + Show Quick Reply toggle | `be05245` | Settings toggle; ModuleShell expand |
| W1 | [DEF-086](DEFECTS.md) Android sync modes | `6ca4c3b` | Manual / Interval / Push |
| W2 | [DEF-087](DEFECTS.md) in-pane expanded HTML read | `bf196dc` | No compose jump |
| W2b | [DEF-087](DEFECTS.md) compose HTML quoted original | `ab14a77` | Reply/Forward quote parity |
| W3 | [DEF-085](DEFECTS.md) wide HTML horizontal pan (phone) | `f03f321` | HtmlWidget nested scroll |
| W4 | [DEF-056](DEFECTS.md) oldest/newest sort | `a4c397f` | Settings + projector |
| W5 | [DEF-055](DEFECTS.md) sent-in-threads | `843918b` | Settings toggle |
| W6 | [DEF-044](DEFECTS.md) list widget + deep links | `a44c7df`–`886a00d` | Widget + sticky body + portrait pager fixes |
| W7 | Wave MH digest slice 1 | `18697c2` | `lib/digest/` + `--demo` CLI |

### Wave WEB — Personal operator client (Trish-only)

**Status:** **Next** (2026-08-25) — **very soon**, **not V2.0 release-blocking**. Motivation: *“Because I want it”* — personal anywhere-access mail/PIM in a browser via Cloudflare tunnel, not a hosted product or LiveBytes marketing site.

| Principle | Choice |
| --- | --- |
| Audience | **Trish-only** first; APIs/layout kept clean for a hypothetical future self-hoster |
| Store | **Local-first** — same machine remains SQLite source of truth; web is a viewport |
| Stack | Flutter web **or** thin local HTTP + existing repository seam (TBD in design) |
| Access | **Cloudflare tunnel** to operator machine; no multi-tenant SaaS |
| Distinct from | LiveBytes public site ([POST_V1_WEB_AND_LEGAL.md](POST_V1_WEB_AND_LEGAL.md)); Wave MH digest CLI |
| Ship gate | **None** for V2.0 freeze/tag — dogfood / personal utility only |

**Phases (proposed):** (1) design doc + threat model (tunnel, auth, read-only MVP scope); (2) read-only mail list + reading pane in browser; (3) tunnel + operator runbook; (4) optional compose/sync parity if useful.

**Owners:** Jules (UI/web shell) + Tesla (local API / sync boundaries if split stack).

### Wave 7 — Final polish / Trish extras (parking lot)

**Status:** **Planned** — last **V2.0** operator wave; honest scope-creep bucket. Ship only if Waves 1–6 exit cleanly and operator bandwidth allows. Does **not** block V2.0 release narrative. Post–V2.0 gates (**Wave H2**, **Wave R**) are below — not Wave 7 scope.

**Flat Zero landed (2026-08-25)** — remove from active Wave 7 queue: [DEF-055](DEFECTS.md) sent-in-threads, [DEF-056](DEFECTS.md) sort direction, [DEF-044](DEFECTS.md) list widget, [DEF-078](DEFECTS.md)/[DEF-086](DEFECTS.md)/[DEF-087](DEFECTS.md)/[DEF-085](DEFECTS.md) Android mail dogfood.

| Item | Source | Notes |
| --- | --- | --- |
| Resizable Windows mail panes (drag splitters) | [DEF-054](DEFECTS.md) | Outlook-style rail / sidebar / list / reading widths |
| Right-click **Mark read** on list rows (solo vs thread) | [DEF-050](DEFECTS.md) | Pri-2.5 enhancement; context menu + thread disambiguation |
| ~~Include Sent items in conversation threads~~ | [DEF-055](DEFECTS.md) | ✅ **Fixed** Flat Zero W5 (`843918b`) |
| ~~Thread/list sort: oldest first vs newest first~~ | [DEF-056](DEFECTS.md) | ✅ **Fixed** Flat Zero W4 (`a4c397f`) |
| Hamburger → folders-only sheet (swipe keeps full drawer) | [DEF-046](DEFECTS.md) | Android phone nav polish |
| Account dialog overflow sweep | [DEF-039](DEFECTS.md), [DEF-040](DEFECTS.md), [DEF-063](DEFECTS.md) | Remove / Edit / Manage Account yellow-black stripes on narrow widths |
| Preserve accounts/data across reinstall | [DEF-067](DEFECTS.md) | Backup/restore or clear-data-safe reinstall so dogfood doesn’t force full re-auth |
| ~~Configurable home-screen list widget~~ | [DEF-044](DEFECTS.md) | ✅ **Fixed** Flat Zero W6 (`a44c7df` + widget deep-link polish) |
| Calendar defaults to **Today** (Agenda / day-first) | [DEF-071](DEFECTS.md) | Prefer **V-Soon / V-Next**; pull into Wave 7 only if bandwidth |
| **Trish:** Calendar **Week** + **Weekdays** views | [DEF-075](DEFECTS.md) | Pri-3; beyond Month/Agenda |
| **Trish:** Day-of-year + week-of-year in chrome | [DEF-076](DEFECTS.md) | Pri-3; operator uses these numbers |
| **Trish:** Reading-pane zoom for HTML / embedded images | [DEF-088](DEFECTS.md) | Pri-3; pinch (phone) + step zoom (desktop); non-urgent |

Real Pri-1/2 defects and PIM gates stay on their owning waves — this bucket is **enhancement-shaped** backlog only.

### Post–V2.0 gates (scheduled placeholders — 2026-08-12)

Per-version rule: after prior freeze/tag and **before** next-version feature waves, run Dependency Hygiene (unless Trish overrides). Refactor wave is now an explicit sibling gate.

```text
V2.0 exit (Wave 7 optional) → V2.0 freeze/tag
  → Wave H2 (Dependency Hygiene) → Wave R (Refactor)
  → V2.1 feature waves (Watch P3, PIM polish, V-Next pulls)
```

| Wave | Scope | Status |
| --- | --- | --- |
| **Wave H2** | Toolchain + pub soft/majors + native/KGP/plugin debt + docs SDK pins; reopen Wave H deferred majors (`xml`/`pdf`/`printing`/`file_picker` 12 / `drift_dev`) and residuals | **Quick scan** (2026-08-12) — [WAVE_H2_DEPENDENCY_HYGIENE.md](WAVE_H2_DEPENDENCY_HYGIENE.md); full H2 **TBD**; **no upgrades until Trish unlocks** |
| **Wave R** | Structural cleanup after V2.0 feature landings — rename/dead code, tighten public APIs, align patterns with AGENTS.md; fix debt found in pass only | **TBD** — plan stub only; **no refactor implementation until Trish unlocks** |
| **Wave MH** | Mail hygiene digest (desktop CLI + Sheet) | **Spec locked** 2026-08-19 — [design](superpowers/specs/2026-08-19-mail-hygiene-digest-design.md); implementation plan next session |
| **Wave WEB** | Personal web client (local + Cloudflare tunnel) | **Very soon** (2026-08-25) — operator personal; design → MVP; **not** release-blocking |

**H2 quick-scan done** (2026-08-12, Trish **(b)**): preview checklist landed; **no upgrades**. Full H2 batches + Wave R checklist still wait for V2.0 freeze/tag (or unlock).

| Item | Source | Notes |
| --- | --- | --- |
| Resizable Windows mail panes (drag splitters) | [DEF-054](DEFECTS.md) | Outlook-style rail / sidebar / list / reading widths |
| Right-click **Mark read** on list rows (solo vs thread) | [DEF-050](DEFECTS.md) | Pri-2.5 enhancement; context menu + thread disambiguation |
| ~~Include Sent items in conversation threads~~ | [DEF-055](DEFECTS.md) | ✅ Flat Zero W5 |
| ~~Thread/list sort: oldest first vs newest first~~ | [DEF-056](DEFECTS.md) | ✅ Flat Zero W4 |
| Hamburger → folders-only sheet (swipe keeps full drawer) | [DEF-046](DEFECTS.md) | Android phone nav polish |
| Account dialog overflow sweep | [DEF-039](DEFECTS.md), [DEF-040](DEFECTS.md), [DEF-063](DEFECTS.md) | Remove / Edit / Manage Account yellow-black stripes on narrow widths |
| Preserve accounts/data across reinstall | [DEF-067](DEFECTS.md) | Backup/restore or clear-data-safe reinstall so dogfood doesn’t force full re-auth |
| ~~Configurable home-screen list widget~~ | [DEF-044](DEFECTS.md) | ✅ Flat Zero W6 |
| Calendar defaults to **Today** (Agenda / day-first) | [DEF-071](DEFECTS.md) | Prefer **V-Soon / V-Next**; pull into Wave 7 only if bandwidth |
| **Trish:** Calendar **Week** + **Weekdays** views | [DEF-075](DEFECTS.md) | Pri-3; beyond Month/Agenda |
| **Trish:** Day-of-year + week-of-year in chrome | [DEF-076](DEFECTS.md) | Pri-3; operator uses these numbers |
| **Trish:** Reading-pane zoom for HTML / embedded images | [DEF-088](DEFECTS.md) | Pri-3; pinch (phone) + step zoom (desktop); non-urgent |

Real Pri-1/2 defects and PIM gates stay on their owning waves — this bucket is **enhancement-shaped** backlog only.

### Multi-calendar product requirements (operator, 2026-07-27)

1. **All calendars usable** — many per account and across accounts; events always bound to a `calendarId`.
2. **Multi-select display** — pick 1+ calendars; each colored; **overlay** or **side-by-side** layout (Outlook-like). P0 stores display prefs (`isSelectedForDisplay`, color fields); P6 UI consumes them.
3. **Cross-account event copy** — desktop drag-and-drop (mobile: long-press → “Copy to calendar…”). Local duplicate + push on target provider. **Wave 6** (Graph+Google). Recurring **calendar series** copy → **Wave 6c**. Organizer meetings / attachments later.

### Multi-contact-list product requirements (operator, 2026-07-27)

Same pattern as calendars:

1. **All contact lists / address books usable** — many per account and across accounts; contacts FK to `contactListId`, not a flat per-account blob.
2. **Multi-select for picker + People views** — select 1+ lists; optional color per list (nice-to-have). P0 stores `isSelectedForDisplay` (and optional color); P5 picker + People UI consume them.
3. **Cross-account / cross-list contact copy** — same DnD / menu UX as events; local duplicate + push to target list. **Wave 6**.

**Wave 1 delivers schema + job hooks only** — no Calendar/People chrome, no Graph/CardDAV adapters, no DnD copy UI.

## 6. Implementation order (accepted — option A)

```text
P0  Local PIM schema + sync job types
P1  Graph contacts + Graph events          ← Tesla (reuse Graph OAuth)
P2  Meeting-mail bridge (V2.0a)            ← ICS + accept/decline
P3  CardDAV contacts adapter               ← Jules; dogfood Runbox
P4  CalDAV calendar adapter                ← Jules; dogfood Runbox
P5  Compose contact picker (FTS, all sources)
P6  Calendar module UI (month/week, CRUD) wired to local store
```

**Parallelism:** After P0, Tesla continues P1/P2 while Jules runs CardDAV **discovery spike** (well-known / Runbox) so P3 is not fake “day-one.” Spike doc: [CARDDAV_DISCOVERY_SPIKE.md](CARDDAV_DISCOVERY_SPIKE.md).

**Why Graph before CardDAV:** Fastest dual-surface dogfood on existing tokens; CardDAV then proves the registry isn’t Graph-shaped.

**Why CardDAV before CalDAV:** Compose picker + people graph; meeting bridge can use `.ics` + Graph before CalDAV is perfect.

## 7. Wave 1 — V2.0a P0 (expanded schema foundations)

**Status:** **Complete** (2026-07-27, `00ebdef`, 516 tests). Checklist: [V2_0A_P0_CHECKLIST.md](V2_0A_P0_CHECKLIST.md). **Renee QA:** [V2_0A_P0_QA.md](V2_0A_P0_QA.md) — **GO** exit + Wave 2 handoff (preserve display prefs; stable provider identity). **Handoff:** Wave 2 — Tesla (Graph contacts + calendars); Jules CardDAV discovery spike may run in parallel.

| Item | Scope | Notes |
| --- | --- | --- |
| **Schema v7** | Drift migration 6→7 | `contact_lists`, `contacts` (+ FK), `contact_emails`, `contact_phones`, `calendars`, `events` (+ FK), `event_attendees`, `contact_fts` |
| **Multi-collection prefs** | Display columns on lists/calendars | `isSelectedForDisplay`, `colorArgb` / `colorOverrideArgb`, `sortIndex`; `calendarViewMode` in app settings |
| **Sync job types** | No-op handlers in SyncEngine | Bootstrap/incremental per collection; reserved `contacts_push`, `contacts_copy`, `events_push`, `events_copy` |
| **Cursor keys** | Per-list / per-calendar | e.g. `pim:contact_list:{id}`, `pim:calendar:{id}` |
| **Thin stores** | Read paths + “selected” helpers | No Calendar/People UI |

**Exit (Wave 1):** ✅ See [V2_0A_P0_CHECKLIST.md](V2_0A_P0_CHECKLIST.md). **Wave 2 (Graph PIM) and CardDAV discovery spike unblocked.**

## 8. Wave 2 — V2.0a P1 (Graph contacts + calendars)

**Status:** **Complete** (2026-07-27, `b526e70` + `eac846c` foundation, 530 tests). Checklist: [V2_WAVE2_CHECKLIST.md](V2_WAVE2_CHECKLIST.md). Renee QA: [V2_WAVE2_QA.md](V2_WAVE2_QA.md) (**GO**). **Constraints met:** display prefs preserved; stable provider identity. **Parallel:** Jules CardDAV discovery spike landed (`9d5f750` — [CARDDAV_DISCOVERY_SPIKE.md](CARDDAV_DISCOVERY_SPIKE.md)).

| Item | Scope | Notes |
| --- | --- | --- |
| **OAuth scopes** | `Contacts.Read`, `Calendars.Read` | **Landed** in `GraphAuthConfig.scopes` (`eac846c`); re-sign-in path documented for existing accounts |
| **Contact lists bootstrap/incremental** | Graph `/me/contactFolders` → `contact_lists` | `GraphPimProvider` + SyncEngine handlers; per-list cursor keys |
| **Contacts bootstrap/incremental** | Graph contacts per folder → `contacts` + emails/phones + FTS | FTS via Drift triggers; display prefs preserved on upsert |
| **Calendars bootstrap/incremental** | Graph `/me/calendars` → `calendars` | Multi-calendar; per-calendar cursor keys |
| **Events bootstrap/incremental** | Graph events per calendar → `events` (+ attendees stub) | **Sync window:** past **90d** / future **365d** (`kGraphEventHorizonPast` / `kGraphEventHorizonFuture` in `graph_pim_provider.dart`) |
| **Stable provider identity** | Deterministic local ids / providerId mapping | `PimIds.stableLocalId`; no duplicate rows on re-sync (tested) |
| **Account-add enqueue** | Bootstrap jobs on Graph account add / re-auth | `_enqueueGraphPimBootstrap` in `AccountService`; incremental on sync cycle |
| **Mail regression** | Graph mail sync unchanged | 530/530 tests green; no Calendar/People UI |

**Exit (Wave 2):** ✅ See [V2_WAVE2_CHECKLIST.md](V2_WAVE2_CHECKLIST.md). **Wave 3 (meeting-mail bridge) unblocked.**

## 9. Wave 3 — V2.0a P2 (meeting-mail bridge)

**Status:** **Complete** (2026-07-27, `7cbfdaa`, 551 tests). Checklist: [V2_WAVE3_CHECKLIST.md](V2_WAVE3_CHECKLIST.md). Renee QA: [V2_WAVE3_QA.md](V2_WAVE3_QA.md) (**GO**). Wave 3 makes meeting email actionable without Calendar chrome: ICS parser + `MeetingInviteResolver`; reading-pane Graph **accept** / **decline** / **tentative**; standalone `.ics` → local draft `providerId` `ics:{uid}`.

| Item | Scope | Notes |
| --- | --- | --- |
| **OAuth / re-consent** | `Calendars.ReadWrite` | Replaces Wave 2 `Calendars.Read`; Edit account → re-auth |
| **Invite resolution** | ICS parser + `MeetingInviteResolver` | Body / attachment / Graph meeting heuristics |
| **Graph RSVP** | Accept / decline / tentative | Local draft first; remote POST; attendee status after success |
| **Local ICS draft** | `providerId` `ics:{uid}` | Idempotent upsert on default calendar |
| **Reading-pane actions** | RSVP + Add to calendar | Mail-first; non-Graph → local + “server reply not sent” |

**Out of MVP:** Calendar chrome, CalDAV push, SMTP iTIP, free/busy, Teams, Wave 7 polish.

**Exit (Wave 3):** ✅ See [V2_WAVE3_CHECKLIST.md](V2_WAVE3_CHECKLIST.md). **Wave 4 (CardDAV/CalDAV) unblocked.**

## 10. Wave 4 — V2.0b P3–P4 (CardDAV / CalDAV)

**Status:** **Complete** (2026-07-27, `f2bd29b`, 556 tests). Checklist: [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md). Renee QA: [V2_WAVE4_QA.md](V2_WAVE4_QA.md) (**GO**). Wave 4 establishes read-only CardDAV/CalDAV PIM sync for DAV-enabled IMAP accounts, using Runbox as the dogfood target; Graph PIM remains on `GraphPimProvider`.

| Item | Scope | Notes |
| --- | --- | --- |
| **Shared discovery** | `DavDiscovery` for CardDAV + CalDAV | Runbox hint, well-known/root candidates, Basic auth, redirect-aware PROPFIND principal → home-set → collections |
| **CardDAV contacts** | Address books + vCards | Contact lists, contacts, email/phone values, stable absolute-href provider identity |
| **CalDAV events** | Calendars + VEVENTs | Reuses `IcsCalendarParser`; event window is past 90 days / future 365 days; attendees mapped where present |
| **Account and engine wiring** | DAV-enabled IMAP accounts | Secure DAV base-url configuration, Runbox prefill, provider registry and sync-engine routing; no Calendar/People UI |
| **Regression coverage** | Fixtures + fake HTTP integration | Discovery, vCard, CalDAV, re-sync identity, display-pref preservation; full suite green at 556 tests |

**Residuals (accepted MVP):** full collection pulls with missing-resource soft-delete (no `sync-collection` REPORT / CTag skip); blank Edit field does not clear saved `dav.baseUrl`; sanitize DAV error bodies in a hardening follow-up. Not blockers for Wave 5.

**Exit (Wave 4):** ✅ CardDAV and CalDAV read sync land in the provider-agnostic local PIM schema; Graph PIM and mail remain unaffected; no live credentials are in the repository. **Wave 5 (compose picker + Calendar UI) complete.**

## 11. Wave 5 — V2.0c P5–P6 (compose picker + Calendar / People UI)

**Status:** **Complete** (2026-07-27, `73c181d`, **585 tests**). Checklist: [V2_WAVE5_CHECKLIST.md](V2_WAVE5_CHECKLIST.md). Renee QA: [V2_WAVE5_QA.md](V2_WAVE5_QA.md) (**GO**). Prior: [V2_WAVE4_QA.md](V2_WAVE4_QA.md) (**GO**). Wave 5 lands Outlook-style module shell, local-FTS compose contact picker, Calendar workspace (month + week/agenda, local CRUD), and People workspace — all UI reads/writes through local Drift; no widget-level network; `events_push` remains no-op.

| Item | Scope | Notes |
| --- | --- | --- |
| **Store APIs** | `searchContacts`, `listEventsInRange`, display-pref writers | Jules + Tesla; DI for `DriftPimStore` in UI — **landed** |
| **Module shell** | Mail (default) · Calendar · People | Module switcher; no mail regression — **landed** |
| **Compose picker (P5)** | Local `contact_fts` across selected lists | No HTTP from widgets — **landed** |
| **Calendar UI (P6)** | Month + week/agenda; local create/edit/delete | Multi-calendar `isSelectedForDisplay` + colors; `calendarViewMode` overlay vs side-by-side — **landed** |
| **People workspace** | Contacts from selected lists | Read-only for remote-sourced rows in Wave 5 — **landed** |
| **Settings** | `calendarViewMode` UI if missing | Existing `AppSettingsCubit` enum — **landed** |

**Out of MVP:** Wave 6 DnD copy; CalDAV/CardDAV write-back; Galaxy Watch; remote push on local CRUD.

**Residuals (accepted MVP):** Calendar create/edit/delete persist in Drift only; `events_push` / `contacts_push` remain no-op. Event editor may target a deselected calendar (event hidden from grid until re-selected) — polish backlog. Resume/deep-link module restore not implemented; Mail cold-start default verified.

**Exit (Wave 5):** ✅ See [V2_WAVE5_CHECKLIST.md](V2_WAVE5_CHECKLIST.md). **Wave G (Google People + Calendar API) unblocked.**

## 12. Wave G — Google People + Calendar API (Google PIM)

**Status:** **Complete** (2026-07-27, `f4c21b0`, **597 tests**). Checklist: [V2_WAVE_G_CHECKLIST.md](V2_WAVE_G_CHECKLIST.md). Renee QA: [V2_WAVE_G_QA.md](V2_WAVE_G_QA.md) (**GO**). Prior: [V2_WAVE5_QA.md](V2_WAVE5_QA.md) (**GO**). Wave 4 explicitly deferred Google PIM ([V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md) out-of-scope; [V2_WAVE4_QA.md](V2_WAVE4_QA.md) W4-3: no DAV for `google:` / `xoauth2` IMAP). Per §2 binding matrix, Google XOAUTH accounts use **People + Calendar API** — not CardDAV/CalDAV — to avoid double-sync.

**Scheduling:** Operator principal work calendar is **Google Workspace**; Wave G cleared the critical path before Wave 6 DnD.

| Item | Scope | Notes |
| --- | --- | --- |
| **OAuth scopes** | Extend `GoogleAuthConfig.scopes` | **Landed:** `contacts.readonly` + `calendar` (+ mail/openid/email/profile). **Re-consent:** Edit account → re-auth for existing Google XOAUTH accounts |
| **`GooglePimProvider`** | People API + Calendar API → `DriftPimStore` | **Landed** — contact lists, contacts, calendars, events; stable provider identity; 90d/365d event window; display prefs preserved on upsert |
| **Provider registry** | Route `google:` / `xoauth2` refs to `GooglePimProvider` | **Landed** — no DAV PIM for Google XOAUTH. Graph + password-auth IMAP+DAV unchanged |
| **SyncEngine** | Bootstrap + incremental handlers | **Landed** — per-list / per-calendar cursor keys; account-add enqueue; mail regression guard |
| **Tests** | Fixtures + registry regression | **Landed** — `google_pim_provider_test`, `google_pim_sync_engine_test`, registry + re-consent coverage; **597/597** suite green |
| **Dogfood** | Google Workspace | Operator script in checklist — post-land; not a code Pri-1 |

**Out of MVP:** DnD copy (**Wave 6**); Google write-back on local CRUD unless explicitly scoped; CardDAV/CalDAV fallback; Wave 7 polish.

**Residuals (accepted MVP):** Calendar window pulls use full snapshot + missing soft-delete (no persisted Calendar `syncToken` with `singleEvents`); large contact groups capped at 1000 members per group pull; no automatic missing-scope UI detector (403 fails job — re-auth required).

**Exit (Wave G):** ✅ See [V2_WAVE_G_CHECKLIST.md](V2_WAVE_G_CHECKLIST.md). **Wave 6P (Performance UX / Sync Honesty) unblocked.**

## 13. Release buckets (ship grouping)

Operator waves 1–7 + **G** map into these buckets for release narrative:

| Bucket | Phases | Operator waves |
| --- | --- | --- |
| **V2.0a** | P0–P2 — schema, Graph PIM sync, meeting-mail bridge | Waves **1–3** |
| **V2.0b** | P3–P4 — CardDAV/CalDAV (Runbox dogfood) | Wave **4** |
| **V2.0c** | P5–P6 — picker + Calendar module UI (deep CRUD, multi-select display) | Wave **5** |
| **V2.0d** | Google People + Calendar API (XOAUTH Google PIM) | Wave **G** |
| **V2.0 +** | Cross-account DnD copy polish | Wave **6** |
| **V2.0 ++** | Final polish / Trish extras (if time permits) | Wave **7** |
| **Post–V2.0 gates** | Dependency hygiene + refactor (before V2.1 features) | **Wave H2** → **Wave R** (**TBD**) |
| **V2.1** | Watch companion (P3); CalDAV depth / free-busy; Contacts polish | After Wave H2 + Wave R |

| Gate | Scope | Status |
| --- | --- | --- |
| **Wave 0** | Account identity (A+B hybrid) — display names, rail labels | **Complete** (2026-07-27) |
| **Wave H** | Dependency hygiene — SDK pins, pub soft/majors, native/KGP/sqlite3mc | **Complete** (2026-07-27) |
| **Wave 1** | P0 — expanded local PIM schema + sync job no-ops | **Complete** (2026-07-27, `00ebdef`) |
| **Wave 2** | P1 — Graph contacts + calendars (multi-list/cal sync) | **Complete** (2026-07-27, `b526e70`) |
| **Wave 3** | P2 — meeting-mail bridge (ICS, RSVP, local `.ics` drafts) | **Complete** (2026-07-27, `7cbfdaa`, 551 tests) |
| **Wave 4** | P3–P4 — CardDAV/CalDAV (Runbox) | **Complete** (2026-07-27, `f2bd29b`, 556 tests) · [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md) · [V2_WAVE4_QA.md](V2_WAVE4_QA.md) (**GO**) |
| **Wave 5** | P5–P6 — picker + Calendar/People UI | **Complete** (2026-07-27, `73c181d`, 585 tests) · [V2_WAVE5_CHECKLIST.md](V2_WAVE5_CHECKLIST.md) · [V2_WAVE5_QA.md](V2_WAVE5_QA.md) (**GO**) |
| **Wave G** | Google People + Calendar API (XOAUTH Google PIM) | **Complete** (2026-07-27, `f4c21b0`, **597 tests**) · [V2_WAVE_G_CHECKLIST.md](V2_WAVE_G_CHECKLIST.md) · [V2_WAVE_G_QA.md](V2_WAVE_G_QA.md) (**GO**) |
| **Wave 6P** | Performance UX (Sync Honesty) | **Complete** (2026-08-04) — E1–E11 ✅ (**645 tests**) · [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md) |
| **Wave 6** | Cross-account DnD copy (events + contacts; Graph + Google) | **Complete** (2026-08-04) — E10+E11 **GO** (**659 tests**) · [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md) · [V2_WAVE_6_QA.md](V2_WAVE_6_QA.md) |
| **Wave 6b** | CalDAV/CardDAV write (copy targets) | **Complete** (2026-08-12) — E8 **GO** (**668 tests**) — [V2_WAVE_6B_CHECKLIST.md](V2_WAVE_6B_CHECKLIST.md) · [V2_WAVE_6B_QA.md](V2_WAVE_6B_QA.md) |
| **Wave 6c** | Calendar series / recurring event copy semantics | **Parked** — not next; Android Pri-2 / Wave 7 candidates |
| **Wave 7** | Final polish / Trish extras | **Planned** — last within V2.0 |
| **Wave H2** | Dependency hygiene (post–V2.0 freeze/tag) | **TBD** — before V2.1 features |
| **Wave R** | Refactoring pass (no new product features) | **TBD** — after H2; before V2.1 features |

## 14. Exit criteria (V2.0)

- [x] Contact picker in compose fed by local FTS (Graph and/or CardDAV sources)
- [x] CardDAV sync works against **Runbox** dogfood account
- [x] CalDAV sync works against **Runbox** dogfood account
- [x] Calendar module: month + week (or agenda); create / edit / delete events *(local Drift only; `events_push` no-op)*
- [x] Meeting invite actionable from mail body; `.ics` → event draft
- [x] Graph account: contacts + events sync without breaking mail
- [x] **Google XOAUTH account:** contacts + events sync via People + Calendar API (**Wave G**)
- [x] Mail remains default launch surface; Calendar/People reachable via module switcher
- [x] Multi-calendar display: select 1+ calendars; overlay or side-by-side; colored lanes
- [x] Multi-contact-list: select 1+ lists for picker and People views
- [x] Cross-account event + contact copy (DnD desktop / menu mobile) — Wave 6
- [ ] Docs + E2E matrix rows for PIM; regression on V1/V1.5 mail paths

## 15. Explicitly out of V2.0

| Item | Disposition |
| --- | --- |
| Galaxy Watch companion | **V2.1** (P3) |
| iOS / macOS / Linux | V2+ / demand |
| OpenPGP / S/MIME / shared mailboxes | Maybe/Someday (enterprise) |
| AI draft / summarize | Maybe/Someday — paired companion to enterprise crypto if either is opted in |
| PST import | After V1.5; not V2 headline |
| Rooms/resources, shared calendar ACLs, Teams deep links | Later calendar depth |
| Avatar / monogram hover cards (Option C) | V-Next / late polish |
| Calendar module defaults to **Today** | **V-Soon / V-Next** — [DEF-071](DEFECTS.md); Wave 7 only if pulled forward |
| ~~**Trish:** Phone Quick Reply density + collapsible chrome~~ | ✅ Flat Zero — [DEF-078](DEFECTS.md) |
| ~~**Trish:** Phone read vs full Reply same document~~ | ✅ Flat Zero — [DEF-087](DEFECTS.md) |
| ~~**Trish:** Android sync modes (manual / timer / push)~~ | ✅ Flat Zero — [DEF-086](DEFECTS.md) |
| **Trish:** Personal web client (Cloudflare tunnel) | **Very soon** — **Wave WEB**; Trish-only; **not** V2.0 release item |
| ~~**Trish:** Per-account home-screen list widgets (AquaMail bar)~~ | ✅ Flat Zero — [DEF-044](DEFECTS.md) |
| ~~Cross-account DnD copy (events + contacts)~~ | ✅ Wave **6** / **6b**; calendar series copy → **6c** (parked) |
| Corporate Graph / Entra org work accounts | **Post–Wave 6** research → incremental version |
| Synesis **Tasks** (basic to-do + agenda with calendar items) | **Maybe/Someday / V-Next** — grocery-list class only; not V2.0. Full productivity / planning stays **Phronesis** |
| **Voice / assistant capture** (add·modify to-dos or calendar-adjacent items) | **V-SometimeSoonish / V-Next** — in-car voice; phone assistants (**Gemini**, **Siri**, etc.). Not V2.0; pairs with basic Tasks if that lands |
| Contact postal addresses + open in Maps / Waze / other map apps | **Pri-3 / V-Next** — [DEF-079](DEFECTS.md); when providers supply ADR; not Wave 6 |
| Calendar pills: tap to temporarily show/hide in current view (reset on leave) | **Pri-3 / V-Next** — [DEF-081](DEFECTS.md); settings still gate which pills appear |
| UI niceties / operator enhancement backlog | **Wave 7 / Trish extras** — not V2.0 critical path |

## 16. Forward-compat (from V1 / during V1.5)

Do not expand V1.5 scope — only avoid painting corners:

- OAuth scope room for Contacts + Calendars (Graph) — **Wave 2 adds `Contacts.Read` + `Calendars.Read`; Wave 3 upgrades calendar access to `Calendars.ReadWrite`; re-consent required**
- OAuth scope room for Google People + Calendar — **Wave G extends `GoogleAuthConfig.scopes`; re-consent via Edit account → re-auth**
- Provider registry seam for CardDAV/CalDAV adapters
- Compose recipients swappable from “recent headers” → contact FTS
- Widget snapshot path reusable later for Watch (V2.1)

## 17. Relationship to other docs

| Doc | Role |
| --- | --- |
| [V2_0A_P0_CHECKLIST.md](V2_0A_P0_CHECKLIST.md) | Wave 1 / V2.0a P0 exit criteria |
| [V2_0A_P0_QA.md](V2_0A_P0_QA.md) | Wave 1 Renee QA — GO + Wave 2 handoff constraints |
| [V2_WAVE2_CHECKLIST.md](V2_WAVE2_CHECKLIST.md) | Wave 2 / V2.0a P1 exit criteria ✅ |
| [V2_WAVE2_QA.md](V2_WAVE2_QA.md) | Wave 2 Renee QA — GO + Wave 3 handoff |
| [V2_WAVE3_CHECKLIST.md](V2_WAVE3_CHECKLIST.md) | Wave 3 / V2.0a P2 exit criteria ✅ |
| [V2_WAVE3_QA.md](V2_WAVE3_QA.md) | Wave 3 Renee QA — GO + Wave 4 handoff |
| [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md) | Wave 4 / V2.0b P3–P4 exit criteria ✅ |
| [V2_WAVE4_QA.md](V2_WAVE4_QA.md) | Wave 4 Renee QA — GO + Wave 5 handoff |
| [V2_WAVE5_CHECKLIST.md](V2_WAVE5_CHECKLIST.md) | Wave 5 / V2.0c P5–P6 exit criteria ✅ |
| [V2_WAVE5_QA.md](V2_WAVE5_QA.md) | Wave 5 Renee QA — GO + Wave G handoff |
| [V2_WAVE_G_CHECKLIST.md](V2_WAVE_G_CHECKLIST.md) | Wave G / Google PIM exit criteria ✅ |
| [V2_WAVE_G_QA.md](V2_WAVE_G_QA.md) | Wave G Renee QA — GO + Wave 6P handoff |
| [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md) | Wave 6P / Performance UX (Sync Honesty) exit criteria |
| [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md) | Wave 6 / cross-account DnD copy — complete (E10+E11 GO) |
| [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md) | Wave H checklist (batches H1–H5, exit gate) — **complete**; residuals → Wave H2 |
| [WAVE_H2_DEPENDENCY_HYGIENE.md](WAVE_H2_DEPENDENCY_HYGIENE.md) | Wave H2 quick-scan preview (2026-08-12) — **no upgrades this pass**; full H2 not opened |
| *(pending)* Wave R checklist | Open after full Wave H2 |
| [TIER_D_PLAN.md](TIER_D_PLAN.md) §4 TD-A | Horizon detail; dispositions updated to point here |
| [V1_5_PLAN.md](V1_5_PLAN.md) | Immediate post-V1 ship before this plan executes |
| [ROADMAP.md](ROADMAP.md) | Living index |
| [CARDDAV_DISCOVERY_SPIKE.md](CARDDAV_DISCOVERY_SPIKE.md) | Wave 2 parallel — RFC 6764 + Runbox (`https://dav.runbox.com/`) discovery design |
| [SPEC.md](SPEC.md) §12.1 | Normative “planned contacts & calendar” |

---

*Wave 0–6b + G complete. **Operation Flat Zero complete** 2026-08-25 (**729+ tests**). **Wave 6c parked.** **Next operator track: Wave WEB** (personal, not release-blocking). **Wave 7** optional polish. V2.0 exit = PIM docs/E2E. **Post–V2.0:** Wave H2 → Wave R before V2.1.*
