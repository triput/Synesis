# Synesis V2.0 Plan — PIM Headline

| Field | Value |
| --- | --- |
| Status | **In progress** — **Wave 0 complete**; **Wave H complete** (2026-07-27); **V2.0a PIM P0 unblocked** |
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

**Status:** **Complete** (2026-07-27 Batch 4) — with known residuals in [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md). **Wave 1 / V2.0a PIM P0 unblocked.**

Per-version hygiene after V1.5 freeze: toolchain + pub debt + native/plugin skew + docs SDK pins. Checklist: [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md).

**Sequence:** Wave 0 → **Wave H ✅** → V2.0a (P0–P2) **← open**.

| Batch | Scope | Notes |
| --- | --- | --- |
| **H1 — SDK pin verify** | Flutter/Dart SDK, `environment.sdk`, README/docs pins | ✅ `.flutter-version` 3.44.6 / `^3.12.2` |
| **H2 — Soft upgrades** | Patch/minor `pub get` resolution | ✅ `uuid` 4.6.0, `webview_flutter_windows` 1.1.1 |
| **H3 — Pub majors** | `pub outdated` major candidates | ✅ Landed or deferred with rationale |
| **H4 — Native / KGP / sqlite3mc** | Android Gradle/KGP, plugin native debt, `sqlite3mc` hook | ✅ Android debug + sqlite3mc; KGP escape hatches kept |
| **H5 — Verify exit** | Full test + build matrix | ✅ `flutter test` 510/510; Windows + Android debug PASS; analyze 0 errors |

**Exit (Wave H):** ✅ Cleared. Open V2.0a P0 (local PIM schema). Residuals (operator dogfood H5-M\*, Pri-3 AppLinks/fln tests, KGP hatches, deferred majors) tracked in the Wave H checklist — do not re-hold PIM.

## 5. Implementation order (accepted — option A)

```text
P0  Local PIM schema + sync job types
P1  Graph contacts + Graph events          ← Tesla (reuse Graph OAuth)
P2  Meeting-mail bridge (V2.0a)            ← ICS + accept/decline
P3  CardDAV contacts adapter               ← Jules; dogfood Runbox
P4  CalDAV calendar adapter                ← Jules; dogfood Runbox
P5  Compose contact picker (FTS, all sources)
P6  Calendar module UI (month/week, CRUD) wired to local store
```

**Parallelism:** After P0, Tesla continues P1/P2 while Jules runs CardDAV **discovery spike** (well-known / Runbox) so P3 is not fake “day-one.”

**Why Graph before CardDAV:** Fastest dual-surface dogfood on existing tokens; CardDAV then proves the registry isn’t Graph-shaped.

**Why CardDAV before CalDAV:** Compose picker + people graph; meeting bridge can use `.ics` + Graph before CalDAV is perfect.

## 6. Wave sketch (product)

| Wave | Scope |
| --- | --- |
| **Wave 0** | Account identity (A+B hybrid) — display names, rail labels — **complete** |
| **Wave H** | Dependency hygiene — SDK pins, pub soft/majors, native/KGP/sqlite3mc — **complete** (2026-07-27) |
| **V2.0a** | P0–P2 — schema, Graph PIM sync, meeting-mail bridge — **unblocked / next** |
| **V2.0b** | P3–P4 — CardDAV/CalDAV (Runbox dogfood) |
| **V2.0c** | P5–P6 — picker + Calendar module UI (deep CRUD) |
| **V2.1** | Watch companion (P3); CalDAV depth / free-busy; Contacts polish |

## 7. Exit criteria (V2.0)

- [ ] Contact picker in compose fed by local FTS (Graph and/or CardDAV sources)
- [ ] CardDAV sync works against **Runbox** dogfood account
- [ ] CalDAV sync works against **Runbox** dogfood account
- [ ] Calendar module: month + week (or agenda); create / edit / delete events
- [ ] Meeting invite actionable from mail body; `.ics` → event draft
- [ ] Graph account: contacts + events sync without breaking mail
- [ ] Mail remains default launch surface; Calendar/People reachable via module switcher
- [ ] Docs + E2E matrix rows for PIM; regression on V1/V1.5 mail paths

## 8. Explicitly out of V2.0

| Item | Disposition |
| --- | --- |
| Galaxy Watch companion | **V2.1** (P3) |
| iOS / macOS / Linux | V2+ / demand |
| OpenPGP / S/MIME / shared mailboxes | Maybe/Someday (enterprise) |
| AI draft / summarize | Maybe/Someday — paired companion to enterprise crypto if either is opted in |
| PST import | After V1.5; not V2 headline |
| Rooms/resources, shared calendar ACLs, Teams deep links | Later calendar depth |
| Avatar / monogram hover cards (Option C) | V-Next / late polish |

## 9. Forward-compat (from V1 / during V1.5)

Do not expand V1.5 scope — only avoid painting corners:

- OAuth scope room for Contacts + Calendars (Graph)
- Provider registry seam for CardDAV/CalDAV adapters
- Compose recipients swappable from “recent headers” → contact FTS
- Widget snapshot path reusable later for Watch (V2.1)

## 10. Relationship to other docs

| Doc | Role |
| --- | --- |
| [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md) | Wave H checklist (batches H1–H5, exit gate) |
| [TIER_D_PLAN.md](TIER_D_PLAN.md) §4 TD-A | Horizon detail; dispositions updated to point here |
| [V1_5_PLAN.md](V1_5_PLAN.md) | Immediate post-V1 ship before this plan executes |
| [ROADMAP.md](ROADMAP.md) | Living index |
| [SPEC.md](SPEC.md) §12.1 | Normative “planned contacts & calendar” |

---

*Wave 0 complete 2026-07-27 (account identity + rail overflow fix). Wave H (dependency hygiene) complete 2026-07-27 — V2.0a PIM P0 unblocked.*
