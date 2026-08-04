# Wave 6P P2 — SyncEngine Isolate Spike (E11)

> **Status:** **Draft — not entered** (E10 pass 2026-08-04; isolate work deferred). Owner: **Tesla**. Parent: [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md).

Design for moving the hottest **mail sync** path off the UI isolate without a full SPEC §4.3 migration. Scope is **incremental** — one vertical slice, measurable on E10 re-run.

## Problem

`SyncEngine._processPendingJobs` runs on the **main isolate** today (`lib/sync/sync_engine.dart`). Each kick:

1. Reclaims jobs / outbox
2. Reloads focus overrides + reclassifies local focus
3. Claims pending jobs in a loop
4. For each job: network I/O + SQLite upserts + repository `notify()` → Drift streams → Cubit `refresh()`

Wave 6P P0 decoupled **spinners** from local refresh; P1 reduced header/body UI bleed. If E10 still shows frame drops during sync+scroll, the remaining cost is likely **main-isolate SQLite + JSON parsing** in the job loop, not honest UX chrome.

## Non-goals (this spike)

- Full isolate architecture for all PIM jobs
- MIME parse isolate expansion (already in `multipart_builder.dart`)
- Changing sync semantics, job store schema, or Wave 6 DnD

## Proposed Phase 1 — Inbox incremental batch isolate

Move **one job type** end-to-end:

| Job | Rationale |
| --- | --- |
| `incremental` → `_syncInbox` fetch + header map | Highest frequency during dogfood; mixes network + parse + bulk upsert |

### Contract

```text
UI isolate                          Worker isolate
──────────                          ──────────────
claimPendingJobs (UI)    ──send──►  fetch headers / bodies (network)
                                    parse to MailMessage drafts (CPU)
                         ◄─reply─  serialized upsert batch (bytes or DTO list)
Drift upsert + notify (UI)          (no Drift in worker — Drift is main-isolate today)
SyncActivity refresh (unchanged)
```

**Rule:** Worker isolate **must not** touch `SynesisDatabase` or `MailRepository` instances created on UI isolate. Worker returns **immutable DTOs** (List of upsert payloads); UI isolate applies in one transaction.

### Implementation slices

| Slice | Work | Files |
| --- | --- | --- |
| **P2-1a** | `SyncJobWorkerMessage` / `SyncJobWorkerResult` types + `Isolate.run` wrapper for inbox header fetch only | `lib/sync/sync_job_worker.dart` (new) |
| **P2-1b** | Feature flag `kSyncWorkerInboxIncremental` (default off until E10 fail) | `lib/sync/sync_engine.dart` |
| **P2-1c** | Wire `_syncInbox` hot path behind flag; fallback to inline on worker error | `sync_engine.dart`, `graph_mail_provider.dart` |
| **P2-1d** | Renee: regression tests with fake provider; no isolate in unit tests (inject `runWorker`) | `test/sync_job_worker_test.dart` |

### Rollback

Flag off → current sequential loop. Worker crash → log + inline retry once + job failure surface in Sync Status sheet.

## Phase 2 (only if Phase 1 insufficient)

- `full_folder` message page fetch
- PIM incremental jobs (separate worker entry — do not block Wave 6 on this)

## Success metric

Re-run [E10 profiling script](V2_WAVE_6P_P2_PROFILING.md) — step 3 **Sync + scroll** worst frame ≤16 ms sustained, or operator GO that jank is gone.

## Current posture (pre-E10)

**Defer implementation** until Trish E10 result. MIME isolate remains the only production isolate ([DART_IN_SYNESIS.md](DART_IN_SYNESIS.md) § Isolates).
