# Synesis V2.0 Plan — PIM Headline

| Field | Value |
| --- | --- |
| Status | **In progress** — **Wave 4 / V2.0b complete** (2026-07-27, SHA `pending`, 556 tests); **Wave 5 / V2.0c next** (picker + Calendar UI). Wave 0 ✅; Wave H ✅; **Wave 1 / P0 ✅** (2026-07-27, `00ebdef`); **Wave 2 / P1 ✅** (2026-07-27, `b526e70`, 530 tests); **Wave 3 / P2 ✅** (2026-07-27, `7cbfdaa`, 551 tests, [V2_WAVE3_QA.md](V2_WAVE3_QA.md)). Wave 4 checklist: [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md); Renee QA: [V2_WAVE4_QA.md](V2_WAVE4_QA.md) (**GO**). **Re-consent:** `Contacts.Read` + **`Calendars.ReadWrite`** in Graph OAuth scopes; existing accounts re-sign-in via Edit account → re-auth |
| Headline | Contacts & calendar (TD-A) — not a new phone OS |
| Prerequisite | V1 exit signed off; **V1.5 complete** ([V1_5_PLAN.md](V1_5_PLAN.md)) |
| Watch | **P3 → V2.1** (not V2.0 critical path) |
| Enterprise crypto / shared mail / AI draft·summarize | **Maybe/Someday** — not V2.0 critical path unless demand appears |
| Owners | Steve (orchestrate) · Tesla (Graph PIM / sync) · Jules (CardDAV spike + UI modules) · Renee (QA) · Page (docs) |
| Last updated | 2026-07-27 |

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
| 13 | **Cross-account copy** (events + contacts) via drag-and-drop UX (desktop) with mobile fallback menu — **Wave 6**; local-first duplicate + push to target collection |

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

**Sequence:** Wave 0 → **Wave H ✅** → **Wave 1 (P0) ✅** → **Wave 2 (P1) ✅** → **Wave 3 (P2) ✅** → **Wave 4 (P3–P4) ✅** → **Wave 5 (P5–P6) ← next** → Waves 6–7.

| Batch | Scope | Notes |
| --- | --- | --- |
| **H1 — SDK pin verify** | Flutter/Dart SDK, `environment.sdk`, README/docs pins | ✅ `.flutter-version` 3.44.6 / `^3.12.2` |
| **H2 — Soft upgrades** | Patch/minor `pub get` resolution | ✅ `uuid` 4.6.0, `webview_flutter_windows` 1.1.1 |
| **H3 — Pub majors** | `pub outdated` major candidates | ✅ Landed or deferred with rationale |
| **H4 — Native / KGP / sqlite3mc** | Android Gradle/KGP, plugin native debt, `sqlite3mc` hook | ✅ Android debug + sqlite3mc; KGP escape hatches kept |
| **H5 — Verify exit** | Full test + build matrix | ✅ `flutter test` 510/510; Windows + Android debug PASS; analyze 0 errors |

**Exit (Wave H):** ✅ Cleared. Wave 1 / V2.0a P0 (expanded local PIM schema) **complete** (2026-07-27). Residuals (operator dogfood H5-M\*, Pri-3 AppLinks/fln tests, KGP hatches, deferred majors) tracked in the Wave H checklist — do not re-hold PIM.

## 5. Operator waves (working sequence)

**Status:** **Wave 1 complete** (2026-07-27, `00ebdef`); **Wave 2 complete** (2026-07-27, `b526e70`); **Wave 3 complete** (2026-07-27, 551 tests); **Wave 4 complete** (2026-07-27, SHA `pending`, 556 tests); **Wave 5 next** (picker + Calendar UI). V2.0a / V2.0b / V2.0c below remain **release buckets** for ship grouping; operator execution follows this table.

| Wave | Scope | Owner(s) | Maps to |
| --- | --- | --- | --- |
| **Wave 0** | Account identity (display names, rail labels) | Jules / Andi | Pre-PIM gate |
| **Wave H** | Dependency hygiene (SDK, pub, native/KGP) | Steve + team | Pre-V2.0a gate |
| **Wave 1** | **P0 — expanded schema foundations** (multi-list contacts, multi-calendar, FTS, sync job no-ops) | Jules + Tesla | **V2.0a P0** ✅ **Complete** (2026-07-27) |
| **Wave 2** | P1 — Graph contacts + calendars (multi-list/cal sync) | Tesla | **V2.0a P1** ✅ **Complete** (2026-07-27, `b526e70`) |
| **Wave 3** | P2 — meeting-mail bridge (ICS, RSVP, local `.ics` drafts) | Tesla + Jules | **V2.0a P2** ✅ **Complete** (2026-07-27, `7cbfdaa`, 551 tests) |
| **Wave 4** | P3–P4 — CardDAV/CalDAV (Runbox; multi address-book / calendar discovery) | Tesla + Jules | V2.0b ✅ **Complete** (2026-07-27, SHA `pending`, 556 tests) |
| **Wave 5** | P5–P6 — compose contact picker (FTS across selected lists) + Calendar module UI (multi-select overlay / side-by-side) | Jules | V2.0c ← **next** |
| **Wave 6** | Cross-account / cross-list **DnD copy** for events + contacts (local copy + push) | Jules + Tesla | Post-V2.0c polish |
| **Wave 7** | **Final polish / Trish extras** — UI niceties & enhancement backlog if time permits (resizable panes, list context menus, mobile nav polish, overflow sweeps, widget wishlist). **Not V2.0 critical path.** | Jules / Andi | Scope-creep parking lot |

Checklists: [V2_0A_P0_CHECKLIST.md](V2_0A_P0_CHECKLIST.md) (Wave 1 exit); [V2_WAVE2_CHECKLIST.md](V2_WAVE2_CHECKLIST.md) (Wave 2 exit ✅); [V2_WAVE3_CHECKLIST.md](V2_WAVE3_CHECKLIST.md) (Wave 3 exit ✅); [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md) (Wave 4 exit ✅, SHA `pending`, 556 tests). Wave 4 QA: [V2_WAVE4_QA.md](V2_WAVE4_QA.md) (**GO**).

### Wave 7 — Final polish / Trish extras (parking lot)

**Status:** **Planned** — last operator wave; honest scope-creep bucket. Ship only if Waves 1–6 exit cleanly and operator bandwidth allows. Does **not** block V2.0 release narrative.

| Item | Source | Notes |
| --- | --- | --- |
| Resizable Windows mail panes (drag splitters) | [DEF-054](DEFECTS.md) | Outlook-style rail / sidebar / list / reading widths |
| Right-click **Mark read** on list rows (solo vs thread) | [DEF-050](DEFECTS.md) | Pri-2.5 enhancement; context menu + thread disambiguation |
| Include Sent items in conversation threads | [DEF-055](DEFECTS.md) | Pri-2; operator reply context / “did I respond?” triage |
| Thread/list sort: oldest first vs newest first | [DEF-056](DEFECTS.md) | Pri-2; user-selectable list sort direction |
| Hamburger → folders-only sheet (swipe keeps full drawer) | [DEF-046](DEFECTS.md) | Android phone nav polish |
| Account dialog overflow sweep | [DEF-039](DEFECTS.md), [DEF-040](DEFECTS.md) | Remove / Edit Account yellow-black stripes on narrow widths |
| Configurable home-screen list widget | [DEF-044](DEFECTS.md) | Tap-through to message from widget rows |

Real Pri-1/2 defects and PIM gates stay on their owning waves — this bucket is **enhancement-shaped** backlog only.

### Multi-calendar product requirements (operator, 2026-07-27)

1. **All calendars usable** — many per account and across accounts; events always bound to a `calendarId`.
2. **Multi-select display** — pick 1+ calendars; each colored; **overlay** or **side-by-side** layout (Outlook-like). P0 stores display prefs (`isSelectedForDisplay`, color fields); P6 UI consumes them.
3. **Cross-account event copy** — desktop drag-and-drop (mobile: long-press → “Copy to calendar…”). **Not impossible** — local duplicate + push on target provider. Recurring instances, organizer meetings, and attachments need explicit UX later. **Wave 6**, not Wave 1.

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

**Status:** **Complete** (2026-07-27, SHA `pending`, 556 tests). Checklist: [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md). Renee QA: [V2_WAVE4_QA.md](V2_WAVE4_QA.md) (**GO**). Wave 4 establishes read-only CardDAV/CalDAV PIM sync for DAV-enabled IMAP accounts, using Runbox as the dogfood target; Graph PIM remains on `GraphPimProvider`.

| Item | Scope | Notes |
| --- | --- | --- |
| **Shared discovery** | `DavDiscovery` for CardDAV + CalDAV | Runbox hint, well-known/root candidates, Basic auth, redirect-aware PROPFIND principal → home-set → collections |
| **CardDAV contacts** | Address books + vCards | Contact lists, contacts, email/phone values, stable absolute-href provider identity |
| **CalDAV events** | Calendars + VEVENTs | Reuses `IcsCalendarParser`; event window is past 90 days / future 365 days; attendees mapped where present |
| **Account and engine wiring** | DAV-enabled IMAP accounts | Secure DAV base-url configuration, Runbox prefill, provider registry and sync-engine routing; no Calendar/People UI |
| **Regression coverage** | Fixtures + fake HTTP integration | Discovery, vCard, CalDAV, re-sync identity, display-pref preservation; full suite green at 556 tests |

**Residuals (accepted MVP):** full collection pulls with missing-resource soft-delete (no `sync-collection` REPORT / CTag skip); blank Edit field does not clear saved `dav.baseUrl`; sanitize DAV error bodies in a hardening follow-up. Not blockers for Wave 5.

**Exit (Wave 4):** ✅ CardDAV and CalDAV read sync land in the provider-agnostic local PIM schema; Graph PIM and mail remain unaffected; no live credentials are in the repository. **Wave 5 (compose picker + Calendar UI) is next.**

## 11. Release buckets (ship grouping)

Operator waves 1–7 map into these buckets for release narrative:

| Bucket | Phases | Operator waves |
| --- | --- | --- |
| **V2.0a** | P0–P2 — schema, Graph PIM sync, meeting-mail bridge | Waves **1–3** |
| **V2.0b** | P3–P4 — CardDAV/CalDAV (Runbox dogfood) | Wave **4** |
| **V2.0c** | P5–P6 — picker + Calendar module UI (deep CRUD, multi-select display) | Wave **5** |
| **V2.0 +** | Cross-account DnD copy polish | Wave **6** |
| **V2.0 ++** | Final polish / Trish extras (if time permits) | Wave **7** |
| **V2.1** | Watch companion (P3); CalDAV depth / free-busy; Contacts polish | Post-V2.0 |

| Gate | Scope | Status |
| --- | --- | --- |
| **Wave 0** | Account identity (A+B hybrid) — display names, rail labels | **Complete** (2026-07-27) |
| **Wave H** | Dependency hygiene — SDK pins, pub soft/majors, native/KGP/sqlite3mc | **Complete** (2026-07-27) |
| **Wave 1** | P0 — expanded local PIM schema + sync job no-ops | **Complete** (2026-07-27, `00ebdef`) |
| **Wave 2** | P1 — Graph contacts + calendars (multi-list/cal sync) | **Complete** (2026-07-27, `b526e70`) |
| **Wave 3** | P2 — meeting-mail bridge (ICS, RSVP, local `.ics` drafts) | **Complete** (2026-07-27, `7cbfdaa`, 551 tests) |
| **Wave 4** | P3–P4 — CardDAV/CalDAV (Runbox) | **Complete** (2026-07-27, SHA `pending`, 556 tests) · [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md) · [V2_WAVE4_QA.md](V2_WAVE4_QA.md) (**GO**) |

## 12. Exit criteria (V2.0)

- [ ] Contact picker in compose fed by local FTS (Graph and/or CardDAV sources)
- [ ] CardDAV sync works against **Runbox** dogfood account
- [ ] CalDAV sync works against **Runbox** dogfood account
- [ ] Calendar module: month + week (or agenda); create / edit / delete events
- [x] Meeting invite actionable from mail body; `.ics` → event draft
- [ ] Graph account: contacts + events sync without breaking mail
- [ ] Mail remains default launch surface; Calendar/People reachable via module switcher
- [ ] Multi-calendar display: select 1+ calendars; overlay or side-by-side; colored lanes
- [ ] Multi-contact-list: select 1+ lists for picker and People views
- [ ] Cross-account event + contact copy (DnD desktop / menu mobile) — Wave 6
- [ ] Docs + E2E matrix rows for PIM; regression on V1/V1.5 mail paths

## 13. Explicitly out of V2.0

| Item | Disposition |
| --- | --- |
| Galaxy Watch companion | **V2.1** (P3) |
| iOS / macOS / Linux | V2+ / demand |
| OpenPGP / S/MIME / shared mailboxes | Maybe/Someday (enterprise) |
| AI draft / summarize | Maybe/Someday — paired companion to enterprise crypto if either is opted in |
| PST import | After V1.5; not V2 headline |
| Rooms/resources, shared calendar ACLs, Teams deep links | Later calendar depth |
| Avatar / monogram hover cards (Option C) | V-Next / late polish |
| Cross-account DnD copy (events + contacts) | **Wave 6** — after provider sync + Calendar/People UI |
| UI niceties / operator enhancement backlog | **Wave 7 / Trish extras** — not V2.0 critical path |

## 14. Forward-compat (from V1 / during V1.5)

Do not expand V1.5 scope — only avoid painting corners:

- OAuth scope room for Contacts + Calendars (Graph) — **Wave 2 adds `Contacts.Read` + `Calendars.Read`; Wave 3 upgrades calendar access to `Calendars.ReadWrite`; re-consent required**
- Provider registry seam for CardDAV/CalDAV adapters
- Compose recipients swappable from “recent headers” → contact FTS
- Widget snapshot path reusable later for Watch (V2.1)

## 15. Relationship to other docs

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
| [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md) | Wave H checklist (batches H1–H5, exit gate) |
| [TIER_D_PLAN.md](TIER_D_PLAN.md) §4 TD-A | Horizon detail; dispositions updated to point here |
| [V1_5_PLAN.md](V1_5_PLAN.md) | Immediate post-V1 ship before this plan executes |
| [ROADMAP.md](ROADMAP.md) | Living index |
| [CARDDAV_DISCOVERY_SPIKE.md](CARDDAV_DISCOVERY_SPIKE.md) | Wave 2 parallel — RFC 6764 + Runbox (`https://dav.runbox.com/`) discovery design |
| [SPEC.md](SPEC.md) §12.1 | Normative “planned contacts & calendar” |

---

*Wave 0 complete 2026-07-27. Wave H complete 2026-07-27. **Wave 1 / V2.0a P0 complete** 2026-07-27 (`00ebdef`). **Wave 2 / V2.0a P1 complete** 2026-07-27 (`b526e70`, 530 tests). **Wave 3 / V2.0a P2 complete** 2026-07-27 (`7cbfdaa`, 551 tests) — Renee GO [V2_WAVE3_QA.md](V2_WAVE3_QA.md); `Calendars.ReadWrite` re-consent; meeting-mail bridge. **Wave 4 / V2.0b complete** 2026-07-27 (SHA `pending`, 556 tests; [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md); Renee GO [V2_WAVE4_QA.md](V2_WAVE4_QA.md)). **Wave 5 (picker + Calendar UI) next.** **Wave 7 / Trish extras** parked for final polish if time permits.*
