# Wave 6P — Performance UX (Sync Honesty) Checklist

> **Status:** **P0 gate complete** (2026-08-03) — E1–E7 ✅; Renee **GO** on E6 (**626 tests**); Trish **GO** on E7 Android dogfood (`87ec66a`). P1/P2 open. Parent plan: [V2_PLAN.md](V2_PLAN.md). Prior: [V2_WAVE_G_QA.md](V2_WAVE_G_QA.md) **GO** (`f4c21b0`, **597 tests**). **Next after full 6P exit:** Wave 6 (cross-account DnD copy).

Wave 6P delivers **honest sync UX** — decouple local SQLite refresh from remote sync-in-flight indicators, stop blocking the UI on `await kick()` / `kickFresh()`, and land targeted polish (UI-P11, UI-P9 partial, DEF-015, DEF-007). **P2** (Tesla SyncEngine isolate work) is **committed** if post-P0 profiling confirms frame jank on operator hardware.

**Locked decisions (Trish, 2026-08-03):**

1. **Wave 6P before Wave 6** — full gate, not interleaved with DnD copy.
2. **Commit to P2** if still janky after P0 (profiling gate → isolate work if frames drop).
3. **Bundle DEF-007 + DEF-015** into Wave 6P.
4. Stub docs approved (this checklist + plan/roadmap stubs).

## Sequence

```text
Wave 0 ✅ → Wave H ✅ → Wave 1 (P0) ✅
                         → Wave 2: Graph PIM (P1) ✅
                         → Wave 3: meeting-mail bridge (P2) ✅
                         → Wave 4: CardDAV/CalDAV (P3–P4) ✅
                         → Wave 5: picker + Calendar UI (P5–P6) ✅
                         → Wave G: Google People + Calendar API ✅
                         → ★ Wave 6P: Performance UX (Sync Honesty) ← P0 gate complete; P1 open
                         → Wave 6: cross-account DnD copy
                         → Wave 7: Trish extras (last)
```

## Scope (locked for kickoff)

| Item | Slice | Scope | Notes |
| --- | --- | --- | --- |
| **Sync activity observable** | P0 | `isRemoteSyncInFlight`, running job count from job store / SyncEngine lifecycle | Tesla design → Jules wire; replaces conflated `mailbox.isLoading` for title bar |
| **Local vs remote refresh** | P0 | Decouple `MailboxCubit.refresh()` local recount from remote sync busy | `isRefreshingLocal` or restrict `isLoading` to initial attach only |
| **Title bar / toolbar honesty** | P0 | `syncing:` binds to SyncActivity only — **not** `\|\| mailbox.isLoading` | [DEF-006](DEFECTS.md) residue closure |
| **Non-blocking kick paths** | P0 | Manual sync, pull-to-refresh, add-account save — enqueue + kick without `await` | `mail_workspace.dart`, `mailbox_cubit.dart`, `add_account_sheet.dart` |
| **UI-P11 sync status polish** | P0/P1 | Idle / syncing (N jobs) / error consistent across title bar, sidebar, sync sheet | Primary absorption of UI-P11 |
| **UI-P9 partial — body skeletons** | P1 | Reading-pane body-fetch skeleton only (not full list/sync skeleton sweep) | Partial absorption of UI-P9 |
| **DEF-015 per-message headers** | P1 | Scope `isLoadingHeaders` / error by message id | Bundled per operator decision |
| **DEF-007 read/unread merge policy** | P1 | Local user intent wins until server confirms; stop sync header upsert flicker | Bundled per operator decision; coordinate with faster local refresh |
| **P2 isolate milestone** | P2 | Profile sync on operator Android; Tesla isolate spike for `_processPendingJobs` hot path if jank confirmed | **Committed** if profiling gate fails — not optional scope creep |
| **Docs alignment** | P2 | `DART_IN_SYNESIS.md` + sweep rows per Page pass | 6P-14 |

## Slices

| Slice | Goal | Owner(s) | Gate |
| --- | --- | --- | --- |
| **P0** | Fix malaise — honest spinners, non-blocking kick | Tesla (design) → Jules + Andi | **Required** — E1–E7 |
| **P1** | Polish — UI-P11, UI-P9 partial, DEF-015, DEF-007 | Jules + Andi | Required for full 6P exit — E8–E9 |
| **P2** | Isolate work if post-P0 jank confirmed | Tesla + Renee (profile) | E10–E11 — enter only if profiling gate fails |

## Work breakdown

| ID | Task | Slice | Owner | Primary files | Status |
| --- | --- | --- | --- | --- | --- |
| **6P-1** | Sync activity observable (`isRemoteSyncInFlight`, job count stream/notifier) | P0 | Tesla → Jules | `sync_engine.dart`, `drift_sync_job_store.dart`, DI | ✅ |
| **6P-2** | Decouple `MailboxCubit.refresh()` — stop using `isLoading` for local recount | P0 | Jules | `mailbox_cubit.dart`, `mailbox_state.dart` | ✅ |
| **6P-3** | Title bar / toolbar honesty — bind `syncing:` to SyncActivity only | P0 | Andi | `mail_workspace.dart` | ✅ |
| **6P-4** | Manual sync fire-and-forget — `_runManualSync` without await on kick | P0 | Jules | `mail_workspace.dart` | ✅ |
| **6P-5** | Pull-to-refresh non-blocking — local `refresh()` only in `RefreshIndicator` | P0 | Andi | `mailbox_cubit.dart` | ✅ |
| **6P-6** | Add-account unblocked — remove `await syncEngine.kick()` save paths | P0 | Andi | `add_account_sheet.dart` | ✅ |
| **6P-7** | Renee test delta — state separation, DEF-006 reclaim regression, double-tap manual sync | P0 | Renee | `test/` | ✅ **GO** (626 tests, E6) |
| **6P-8** | UI-P11 sync status polish — chip + sidebar + sheet consistency | P1 | Jules/Andi | Title bar, `sync_status_sheet.dart`, `folder_sidebar.dart` |
| **6P-9** | UI-P9 partial — body fetch skeleton in reading pane | P1 | Andi | `reading_pane.dart` |
| **6P-10** | DEF-015 per-message header loading / error scope | P1 | Jules | `mailbox_cubit.dart`, `message_headers_sheet.dart` |
| **6P-11** | Folder sidebar sync label accuracy | P1 | Andi | `folder_sidebar.dart` |
| **6P-12** | Profile sync on large mailbox (Android + Windows) | P2 | Renee + Tesla | DevTools timeline — only if post-P0 jank |
| **6P-13** | Isolate spike for `_processPendingJobs` hot path | P2 | Tesla | Design doc; incremental move if E10 fails |
| **6P-14** | SPEC / `DART_IN_SYNESIS.md` alignment pass | P2 | Page | Current vs target isolate posture |

**DEF-007 merge policy** lands in P1 alongside 6P-2 / repository upsert paths — no separate work ID; tracked in exit E9 and related defects below.

## Out of Wave 6P MVP

- Cross-account DnD copy (**Wave 6**)
- Full SPEC §4.3 isolate architecture migration (unless P2 profiling gate fails)
- Profiler / Systrace campaign beyond operator DevTools spot-check
- Wave 7 enhancement backlog (resizable panes, DEF-050/054/055/056, widget theming)
- Sync policy changes (intervals, WiFi vs mobile, retention)
- PIM module perf (Calendar/People) unless same `isLoading` conflation is found
- UI-P9 full sweep (list skeletons, search sheet progress — defer remainder)

## Wave 6P exit criteria (gate)

### P0 gate (required)

- [x] **E1** — No title-bar spinner on mere local refresh (DB watch / mark-read recount does not flip global “syncing” chrome)
- [x] **E2** — Pull-to-refresh non-blocking (`RefreshIndicator` completes ≤500 ms local; remote kick continues in background)
- [x] **E3** — Manual sync non-blocking (toolbar enqueue + kick; UI immediately interactive; completion via snackbar / sync sheet)
- [x] **E4** — Add-account closes promptly (no `await kick()`; background sync visible in Sync Status sheet)
- [x] **E5** — Sync indicator reflects reality (idle \| syncing (N jobs) \| error from job store — **not** `mailbox.isLoading`)
- [x] **E6** — Automated tests for separated states; DEF-006 reclaim regression guard — Renee **GO**, **626 tests** (`sync_activity_test.dart`, `sync_engine_kick_lifecycle_test.dart`, `mailbox_cubit_test.dart` Wave 6P group, `sync_engine_trash_purge_test.dart` reclaim assert)
- [x] **E7** — Android operator dogfood script (below) — Trish **GO** (2026-08-03, `87ec66a`); no “stuck checking remote” perception

### P1 gate (required for full wave exit)

- [ ] **E8** — UI-P11: idle/syncing/error semantics consistent across title bar, sidebar label, sync sheet
- [ ] **E9** — UI-P9 partial: body-fetch skeleton in reading pane; DEF-015 per-message header spinner; DEF-007 merge policy (no read/unread flicker on sync refresh)

### P2 gate (committed if post-P0 jank confirmed)

- [ ] **E10** — Profile confirms >16 ms UI frames during sync on operator Android device (or document clean baseline)
- [ ] **E11** — If E10 fails: spike doc + incremental isolate move for heaviest sync path; if E10 passes: documented deferral with measured baseline

## Team routing

| Role | Wave 6P work |
| --- | --- |
| Steve | Orchestrate; lock scope; exit gate; sequencing before Wave 6 |
| Tesla | SyncActivity contract (P0); P2 isolate spike if profiling gate fails |
| Jules | P0 state model lead; P1 DEF-015 / DEF-007 merge; architecture |
| Andi | P0 mechanical wiring (pull-to-refresh, add-account, title bar); P1 skeletons |
| Renee | QA — dogfood matrix, test delta, GO/NO-GO; P2 profiling with Tesla |
| Page | Checklist / plan / roadmap / sweep absorption / headers |

## Android dogfood (operator — post-P0)

Run on operator Android device with linked Graph and/or IMAP account. Log issues without credentials or raw PII.

1. **Cold start** — inbox visible from local DB; no premature remote spinner.
2. **Pull-to-refresh** — list updates fast; sync continues without UI freeze.
3. **Manual sync** — tap twice rapidly; second tap handled gracefully; no false idle.
4. **Add account** — sheet closes after save; mail arrives via background sync.
5. **Mark read on 10 messages** — no list flicker (DEF-007); no global sync spinner during local recount.

## Related defects & sweep items

| ID | Relationship |
| --- | --- |
| [DEF-006](DEFECTS.md) (closed) | Residue — `isLoading` conflation; 6P closes the loop |
| [DEF-007](DEFECTS.md) (open, Pri-2) | **Bundled** — read/unread merge policy in P1 (E9) |
| [DEF-015](DEFECTS.md) (open, Pri-3) | **Bundled** — per-message header loading in P1 (6P-10, E9) |
| [UI-P9](UI_ENHANCEMENT_SWEEP.md) | P1 partial — body fetch skeletons only |
| [UI-P11](UI_ENHANCEMENT_SWEEP.md) | P0/P1 primary absorption — sync status indicator polish |
