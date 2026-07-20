<p align="center">
  <img src="branding/branding_logo_lockup_google.png" alt="bytemail" width="360" />
</p>

# Final Wave Plan — V1 Exit / Release Readiness

| Field | Value |
| --- | --- |
| Status | **In progress** — Phases A–F landed (branding, filters, FW-1 polish, FW-2 measure, docs/FW-6, W4/W7 checklist payback); Phase G FW-5 finalize + V1 exit **open** |
| Spec | [SPEC.md](SPEC.md) v1.4 |
| Exit checklist | [V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md) |
| Roadmap anchor | [ROADMAP.md § Final wave](ROADMAP.md#final-wave-v1-exit--release-readiness) |
| Tier integration | [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md) |
| Branding lock | [branding/README.md](branding/README.md) |
| Owners | Steve (orchestrate) · Jules (code) · Renee (QA) · Page (docs) · Tesla (sync/DB when touched) |
| Last updated | 2026-07-18 |

This document is the **execution plan** for a **broadened Final wave**: classic FW-1…FW-6 release readiness **plus** Pri-1 cross-cutting message filters **plus** locked branding wire-up. **Phases A–F landed 2026-07-18** (Phase F: W4/W7 operator validation complete; checklist checkbox tick-off pending). Phase G (FW-5 finalize) and V1 exit remain open (operator-owned).

---

## 1. Status & prerequisites

### Current product posture (2026-07-18)

| Area | Status |
| --- | --- |
| W0–W3, W5–W6 | **Landed** |
| W4 Compose | **Landed** (2026-07-18) — code + operator validation; [W4_COMPOSE_CHECKLIST.md](W4_COMPOSE_CHECKLIST.md) checkbox tick-off pending |
| W7 Hardening | **Landed** (2026-07-18) — TC-3 encryption shipped; operator validation complete; [W7_HARDENING_CHECKLIST.md](W7_HARDENING_CHECKLIST.md) checkbox tick-off pending |
| Pri-1 message filter system | **Landed** (Phase B, 2026-07-18) — recipient predicate + saved named presets on `MessageViewFilter` / `MessageQuery` |
| Branding assets | **Landed / wired** (Phase A, 2026-07-18) — Data Envelope v2 + wordmark B + minimal Android splash; see [branding/README.md](branding/README.md) |
| Final wave FW-1…FW-6 | **In progress** — FW-1 polish + FW-2 measure + FW-3a/b/c + FW-4 + FW-6 **landed**; FW-5 living draft only |
| W4 / W7 checklists | **Operator validation complete** (2026-07-18); Phase F **landed** — formal checkbox tick-off in checklist files pending |

### Operator debt (remaining — Phase F gate satisfied)

W4 and W7 **operator inspection/validation complete (2026-07-18)** — Phase F checklist payback **landed**. Status docs treat W4 and W7 as **landed**; individual checkbox tick-off in [W4_COMPOSE_CHECKLIST.md](W4_COMPOSE_CHECKLIST.md) and [W7_HARDENING_CHECKLIST.md](W7_HARDENING_CHECKLIST.md) remains operator-owned.

**Still operator-owned (Phase G / exit):**

- FW-5 `V1_MANUAL_E2E_MATRIX.csv` **finalize** (living draft exists; live Graph/IMAP E2E rows)
- Live OAuth dogfood (Entra registration)
- [V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md) sign-off

See [§6 Phase F — Checklist payback weekend](#6-phase-f--checklist-payback-weekend) (complete) and [§ Phase G — FW-5 Manual E2E matrix](#phase-g--fw-5-manual-e2e-matrix).

### Prerequisites to open Final-wave implementation

| Gate | Requirement |
| --- | --- |
| W7 code | Prefer W7 feature code **landed or explicitly deferred** before FW-1 deep refactor (branding + filter phases may start earlier) |
| W4 code | Already landed; checklist may remain open |
| Spec note | Add/refresh SPEC language for saved filters when Phase B lands (Page) |
| Human confirm | Steve presents this plan; operator confirms phase order before Jules starts |

---

## 2. Locked decisions (do not re-debate)

### Branding (from [branding/README.md](branding/README.md))

| Decision | Lock |
| --- | --- |
| Wordmark | **Option B — stealth lowercase** continuous `bytemail` (gradient `#7B2CBF` → `#3A7BD5` → `#00B4D8`) |
| Icon | **Data Envelope v2** — [`branding_icon_data_envelope_v2.png`](branding/branding_icon_data_envelope_v2.png) |
| Android splash | **Minimal only** — obsidian/jewel + centered icon v2; dismiss on **first Flutter frame**; **no** artificial delay |
| Windows splash | **Skip** — rely on `.ico` + wordmark |
| Wire-up timing | **Final wave Phase A** (early packaging) |

### Filter system (locked in this plan — see [§4](#4-locked-design--cross-cutting-message-filter-system))

| Decision | Lock |
| --- | --- |
| Architecture | **Extend** existing `MessageViewFilter` + `MessageQuery` stack — **no** parallel filter type |
| Date buckets | **UI section headers only** via `MessageListProjector` / `DateGroupingMode.outlookBuckets` — **not** mutually exclusive “date bucket filters” |
| Saved filters | Named presets that **hydrate** `MessageViewFilter` into `MailboxState.userFilter`; device-local persistence |
| Focus | Remains independent; always composes **before** user filter in `MessageQuery` |
| Search | Ephemeral FTS search UI stays separate; keyword leg on `MessageViewFilter` may reuse FTS IDs in Drift |
| Out of V1 | Server rules, IMAP Sieve import, auto-actions on match, cloud sync of filter definitions |

### Final-wave scope philosophy

- FW-1 remains **no new product features** *except* debt found in the refactor pass.
- **Filter system** and **branding wire-up** are **explicit Final-wave product/packaging phases** absorbed from ROADMAP backlog — they are **not** “sneak features inside FW-1.”
- V1 exit still signs off via [V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md).

---

## 3. Phased execution (recommended order)

```text
Phase A  Branding packaging          (early; no live mail)
    │
Phase B  Cross-cutting filter system (dedicated; mostly offline-testable)
    │
Phase C  FW-1 Last refactor          (after W7 code stable + A/B landed)
    │
Phase D  FW-2 Coverage               (measure → raise critical-path floor)
    │
Phase E  Docs cluster                (FW-3a ∥ FW-3b ∥ FW-3c ∥ FW-4)
    │         then FW-6 after FW-4
    │
Phase F  Checklist payback weekend   (W4 + W7 — **landed 2026-07-18**) ✓
    │
Phase G  FW-5 Manual E2E matrix      (finalize; living draft may start earlier)
    │
         → V1_EXIT_CHECKLIST sign-off
```

**Default start:** Phase A and Phase B may run **in parallel** once W7 code is far enough not to thrash list/query APIs. Phase F **landed 2026-07-18** (operator validation complete; checkbox tick-off pending in checklist files).

---

### Phase A — Branding packaging (early)

**Goal:** Stop shipping Flutter default icons; wire locked brand assets.

| Work | Detail |
| --- | --- |
| Windows `.ico` | Multi-size from Data Envelope v2 → runner / installer / taskbar |
| Android adaptive | Launcher foreground/background from v2 |
| Android notification mono | Monochrome small icon for notification channel |
| Android splash | `flutter_native_splash` and/or Android 12 SplashScreen API — obsidian/jewel + centered v2; first-frame dismiss |
| Wordmark | Optional in-app / title-bar Option B (per branding README) |
| Windows splash | **Do not add** |

**Exit:** Packaged Windows + Android builds show ByteMail icon (not Flutter logo); Android cold start shows minimal splash then app; Windows has no dedicated splash.

**Key files (expected):** `windows/runner/resources/`, `android/app/src/main/res/`, `pubspec.yaml` (splash config if used), shell title-bar widgets, [branding/README.md](branding/README.md).

---

### Phase B — Cross-cutting message filter system

**Goal:** Productize Pri-1 filters on top of the W2 `MessageViewFilter` pipeline. Full design lock: [§4](#4-locked-design--cross-cutting-message-filter-system).

**Exit (summary):** Recipient predicate + saved named filters + clear UI; date buckets unchanged as headers; Focus still composes; automated tests + FW-5 rows planned.

---

### Phase C — FW-1 Last refactoring pass

Polish after feature + filter + branding landings: dead code, API alignment with AGENTS.md, Gold Master headers. **No new product features** beyond debt found in the pass.

**Exit:** `flutter analyze` clean on touched packages; no orphaned dual paths for list query / branding assets.

---

### Phase D — FW-2 Verify test coverage

1. Measure: `flutter test --coverage` → lcov / IDE report.
2. Map gaps on **critical paths:** SyncEngine, accounts/onboarding, `MailboxCubit`, Graph + IMAP providers, filter/`MessageQuery` SQL.
3. Raise floor; block release on critical-path regressions.
4. Refresh [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) via wave-close ritual ([TEST_INVENTORY.md](TEST_INVENTORY.md)).

**Exit:** Coverage report archived or linked; critical-path gaps closed or explicitly deferred with reason in DEFECTS / exit notes.


#### FW-2 measurement notes (2026-07-18)

**Measured:** Full `flutter test --coverage` (~39s). Report: [`coverage/lcov.info`](../coverage/lcov.info) (also `coverage/lcov_full_suite.info`). Inventory regenerated: **395** cases / **57** files (**8** tagged `Final`).

**Focused filter suite (all pass):** `message_query_test`, `message_filter_bar_test`, `saved_message_filter_test`, `app_settings_cubit_test` — **58/58**.

**Rough line coverage (full-suite lcov):**

| Critical path | Approx. line % |
|---|---|
| Overall (instrumented) | 41.6% (8162/19601) |
| Filter / `MessageQuery` (+ bar, projector, saved filter) | 89.6% |
| SyncEngine | 75.3% |
| App settings (saved-filter persistence) | 89.2% |
| MailboxCubit | 52.7% |
| Accounts / OAuth | 69.3% |
| Graph provider | 43.1% |
| IMAP/SMTP provider | 10.5% |

**Gaps closed (filter critical path):** Recipient predicate + saved named filters covered by unit/widget/integration tests; inventory rows under wave `Final`.

**Explicitly deferred (not blocking Phase D measurement):**

- Full suite green: 2 unrelated failures remain (`schema_migration_v4_to_v5_test`, `widget_test` shell branding text) — track outside FW-2 filter work; coverage still emitted.
- Raising IMAP/SMTP (~11%) and Graph (~43%) provider floors — live-mail / integration dogfood when account restored (checklist payback).
- Raising `MailboxCubit` floor (~53%) — candidate for FW-1 / later gap-fill; not claimed closed here.
- Phase D **exit checkbox** and Final-wave complete remain **open** until critical-path floors are accepted or further deferred in DEFECTS / V1 exit notes.

---

### Phase E — Documentation cluster (FW-3a ∥ FW-3b ∥ FW-3c ∥ FW-4 → FW-6)

| ID | Artifact | Notes |
| --- | --- | --- |
| **FW-3a** | Comprehensive end-user guide | Accounts, folders, compose, search, Focus, **filters**, settings, wipe, Win vs Android |
| **FW-3b** | Quick start | Short path; cross-link FW-3a |
| **FW-3c** | [`DART_IN_BYTEMAIL.md`](DART_IN_BYTEMAIL.md) | May land early; Page + Steve review |
| **FW-4** | Doc reality sweep | SPEC, ROADMAP, ARCHITECTURE, README, DEFECTS, V1_EXIT_CHECKLIST match ship |
| **FW-6** | [`MULTI_AGENT_SYSTEM_PROMPT.md`](MULTI_AGENT_SYSTEM_PROMPT.md) | **After FW-4**; portable playbook; parallel with FW-5 OK |

---

### Phase F — Checklist payback weekend

**Status: Landed (2026-07-18).** Operator inspection/validation complete for deferred W4/W7 checklists. W4 and W7 marked **landed** in status docs/plans. Formal checkbox tick-off in checklist files remains operator-owned.

| Checklist | Result |
| --- | --- |
| [W4_COMPOSE_CHECKLIST.md](W4_COMPOSE_CHECKLIST.md) | Operator validation **complete** — W4 **landed**; checkbox detail pending |
| [W7_HARDENING_CHECKLIST.md](W7_HARDENING_CHECKLIST.md) | Operator validation **complete** — W7 **landed**; checkbox detail pending |

---

### Phase G — FW-5 Manual E2E matrix

- Artifact: `docs/V1_MANUAL_E2E_MATRIX.csv` (versionable; importable to Sheets).
- Keep separate from automated inventory.
- Include **filter** scenarios (saved + ephemeral), branding smoke (icon/splash), and live-mail rows after Phase F where applicable.
- May start as a **living draft** during W7 / Phase B; **finalize** here as formal gate.

**Then:** [V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md) sign-off.

---

## 4. Locked design — cross-cutting message filter system

### 4.1 Problem statement

ROADMAP Pri-1 asks for **user-defined view filters** on the current folder / unified list — distinct from optional Focused/Other ([SPEC §8.3](SPEC.md#83-dual-layer-focus-mode-optional)) and from ephemeral FTS search ([SPEC §8.1](SPEC.md#81-tiered-search)).

W2 already shipped a strong foundation:

- `MessageViewFilter` — unread / starred / sender / date range / keyword / attachments
- `MessageQuery` — composable stack consumed by `DriftMessageStore.listMessages`
- `MessageFilterBar` + advanced sheet
- `MessageListProjector` — Outlook **date section headers**
- Focus chips independent of the filter bar

What is **missing** for Pri-1: **recipient (to/cc)** predicate, **named saved filters**, and an explicit lock that date buckets are **headers**, not a second filter mode.

### 4.2 Architecture (locked)

```text
UI (MessageFilterBar / SavedFiltersSheet)
        │
        ▼
MailboxCubit  ── builds ──► MessageQuery
        │                      │
        │                      ├─ accountId / folderId
        │                      ├─ focusFilter          (Focus — independent)
        │                      ├─ userFilter           (MessageViewFilter)
        │                      └─ virtual flags        (starredOnly / pin / snooze / trash)
        ▼
MailRepository.listMessages  →  Drift SQL WHERE (+ FTS id set for keyword)
        ▼
MessageListProjector  →  date section headers (outlookBuckets)  →  list UI
```

**Single stack rule** (already in code comments): folder → focus → user filter → view flags → draft/trash. Do not invent a second query path.

### 4.3 Model (locked)

#### A. Ephemeral filter = `MessageViewFilter` (extend in place)

Keep the type name. Add:

| Field | Semantics |
| --- | --- |
| `recipientContains` | Case-insensitive substring against **to** and **cc** address/name fields available on `MailMessage` / Drift columns (same LIKE pattern as `senderContains`) |

Existing fields remain: `unread`, `starred`, `senderContains`, `receivedAfterEpochMs`, `receivedBeforeEpochMs`, `keyword`, `hasAttachments`.

**Keyword:** Drift path continues to resolve FTS message IDs then `id IN (…)`; in-memory `matches` keeps substring fallback for tests.

**Read/unread filter** remains separate from mark-read/unread **actions**.

#### B. Saved filters = named presets (new small domain type)

```text
SavedMessageFilter {
  id: String
  name: String
  filter: MessageViewFilter   // serialized snapshot of predicates
  createdAt / updatedAt
}
```

- Persistence: **device-local** via `AppSettingsCubit` / SharedPreferences JSON (same pattern as other prefs) — **not** SQLite mail tables, **not** synced to providers in V1.
- Apply = set `MailboxState.userFilter` from `SavedMessageFilter.filter` (replace, not merge — simpler UX).
- Save current = snapshot `userFilter` under a user-chosen name.
- Delete / rename in a small management sheet.
- Soft cap: ~20 named filters (enough for power users; avoid unbounded prefs bloat).

#### C. Date buckets (locked — UI grouping only)

| Mode | Role |
| --- | --- |
| `DateGroupingMode.outlookBuckets` | Section headers: Today, Yesterday, This week, Last week, This month, Last month, Older |
| Custom date range on `MessageViewFilter` | **Predicate** that narrows the SQL result set |

**Do not** implement date buckets as mutually exclusive filter chips that replace the projector. Optional UX: “This week” quick action that **sets** `receivedAfterEpochMs` / `receivedBeforeEpochMs` to calendar bounds — that is still a **predicate**, and headers continue to group whatever remains.

#### D. Relation to Focus & search

| Concern | Relation |
| --- | --- |
| Focus Focused/Other | Independent chips; `focusFilter` applied **before** `userFilter` |
| Virtual views (Starred / Pinned / Snoozed) | `MessageQuery` flags; user filter still applies on top |
| FTS search UI | Separate entry point; filter keyword is list-scoped, not the global search sheet |

### 4.4 UI (locked defaults)

1. Keep chip bar: Unread / Starred / Has attachment / Advanced.
2. Advanced sheet: add **Recipient** field beside Sender; keep date pickers + keyword.
3. Add **Saved** affordance: apply / save current / manage list.
4. Clear filters clears ephemeral `userFilter` only (does not delete saved definitions).
5. Focus chips stay outside the filter bar (existing pattern).

### 4.5 Tests (Renee)

- Unit: `MessageViewFilter.matches` + recipient; `MessageQuery` composition with Focus.
- Drift: SQL LIKE for recipient; FTS keyword still returns empty-safe.
- Cubit/widget: apply saved filter; clear; rename/delete; chip bar recipient chip when active.
- Inventory: new rows under Final wave / filter wave tag in CSV after land.

### 4.6 SPEC / docs

When Phase B lands, Page adds a short SPEC subsection (or ROADMAP→SPEC pointer) describing saved local filters vs Focus vs search — **done:** [SPEC §8.6](SPEC.md#86-message-list-filters-view-predicates).

---

## 5. Key files (blast radius)

| Area | Paths |
| --- | --- |
| Query | `lib/query/message_query.dart` |
| Drift list | `lib/repository/drift/drift_message_store.dart` |
| Cubit / state | `lib/ui/mailbox/mailbox_cubit.dart`, `mailbox_state.dart` |
| Filter UI | `lib/ui/mailbox/message_filter_bar.dart` (+ new saved-filter sheet) |
| Projector | `lib/mailbox/message_list_projector.dart` |
| Settings | `lib/settings/` (`AppSettingsCubit` for saved filter JSON) |
| Branding | `docs/branding/*`, `windows/runner/resources/`, `android/app/src/main/res/` |
| Tests | `test/message_query_test.dart`, `test/message_filter_bar_test.dart`, new saved-filter tests |
| Docs | This plan, ROADMAP, SPEC (filter section), FW-3/4/5/6 artifacts |

---

## 6. Exit criteria (Final wave complete)

- [x] Phase A branding wired; no Flutter default launcher/taskbar icon in release builds
- [x] Phase B filter system landed per [§4](#4-locked-design--cross-cutting-message-filter-system) with tests + inventory update
- [x] FW-1 refactor complete; analyze clean on critical packages *(lib warnings cleared on Final-wave paths; ~65 project-wide info lints deferred)*
- [x] FW-2 coverage measured; critical-path gaps addressed or deferred with reason *(see Phase D notes; filter path ~90%; provider floors deferred to live mail)*
- [x] FW-3a, FW-3b present; FW-3c current; FW-4 docs match ship
- [x] FW-6 `MULTI_AGENT_SYSTEM_PROMPT.md` written
- [ ] FW-5 `V1_MANUAL_E2E_MATRIX.csv` **finalized** (living draft exists; includes filters + branding smoke; live-mail rows operator-owned)
- [x] W4 + W7 operator validation complete (**Phase F landed 2026-07-18**); checkbox tick-off in checklist files pending
- [ ] [V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md) signed off — **operator owns**

**Remaining (operator):** Phase G FW-5 finalize · V1 exit sign-off · live-mail E2E rows · checklist checkbox tick-off.

---

## 7. Out of scope / Post-V1

**Out of this Final wave (do not absorb):**

- Server-side / IMAP / Graph inbox rules and Sieve import
- Syncing saved filters across devices
- Auto-file / auto-delete / auto-forward on filter match
- Windows native splash screen
- Replacing Focus with user filters (or vice versa)
- Replacing Outlook date **headers** with date-only filter mode
- PIM, multi-window+, enterprise crypto (Tier D / post-V1)
- Editing `.cursor/plans/*` (operator policy — leave alone)
- Implementing filters, icons, splash, or FW code in the same change set as this plan

**Explicit Post-V1 backlog** (not Final-wave work — see [ROADMAP Planned backlog](ROADMAP.md#planned-backlog-post-foundation)):

- **Hold / pause auto-mark for in-view message** (Pri-1 / [UI-P30](UI_ENHANCEMENT_SWEEP.md)) — Unread filter + 5s auto-mark removes open mail mid-read; pause/hold for current message
- **One-click clear active filters** (Pri-2 / [UI-P29](UI_ENHANCEMENT_SWEEP.md)) — chip × / toolbar Clear for ephemeral `userFilter`; does not delete saved presets
- **Performance test suite** (Pri-2) — spreadsheet catalog (`perf_id`, budgets, harness); fixture-DB microbench first; friend-and-family traces later; mirror [TEST_INVENTORY.md](TEST_INVENTORY.md)
- **Android focus track** (Pri-2) — battery (sync/IDLE/push/wakelocks/Doze), UX density vs Windows, widget/deep-link polish; device + AVD matrix spreadsheet-backed
- **Project health dashboard** (Pri-3 / **adjacent tooling**) — reusable meta dashboard (waves, test inventory, future perf); not a ByteMail product feature — [POST_V1_HEALTH_DASHBOARD.md](POST_V1_HEALTH_DASHBOARD.md)

---

## 8. Agent routing (Steve)

| Phase | Primary | Support |
| --- | --- | --- |
| A Branding | Jules | Page (asset captions / README) |
| B Filters | Jules | Tesla if Drift/FTS edges; Renee tests |
| C FW-1 | Jules | Renee spot-check |
| D FW-2 | Renee | Jules fill gaps |
| E Docs / FW-6 | Page | Steve review; Renee inventory ritual language |
| F Checklists | Operator + Renee | Jules only if fails need code |
| G FW-5 | Renee + Operator | Page CSV hygiene |

---

## 9. Related links

- [ROADMAP.md](ROADMAP.md) — Final wave + Planned backlog
- [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md) — W0–W7 + Final unlock
- [V1_EXIT_CHECKLIST.md](V1_EXIT_CHECKLIST.md)
- [branding/README.md](branding/README.md)
- [W4_COMPOSE_CHECKLIST.md](W4_COMPOSE_CHECKLIST.md) · [W7_HARDENING_CHECKLIST.md](W7_HARDENING_CHECKLIST.md)
- [TEST_INVENTORY.md](TEST_INVENTORY.md) · [AGENTS.md](../AGENTS.md)
