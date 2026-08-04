# Wave 6P P2 — Android Profiling Gate (E10 / E11)

> **Status:** **In progress** (2026-08-03) — operator dogfood + DevTools spot-check on Galaxy-class hardware. Parent: [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md). Spike (if needed): [V2_WAVE_6P_P2_ISOLATE_SPIKE.md](V2_WAVE_6P_P2_ISOLATE_SPIKE.md).

Wave 6P **P2** decides whether post-P0/P1 sync still drops UI frames on operator Android. **Pass (E10 clean)** → document baseline and defer isolate migration. **Fail (E10 jank)** → land incremental isolate spike per [V2_WAVE_6P_P2_ISOLATE_SPIKE.md](V2_WAVE_6P_P2_ISOLATE_SPIKE.md) (E11).

## Exit criteria mapping

| ID | Gate | Pass condition |
| --- | --- | --- |
| **E10** | DevTools timeline during active sync | No sustained **>16 ms** UI frames while scrolling inbox during manual sync on a large mailbox |
| **E11** | Follow-up | **If E10 fails:** spike doc + first incremental isolate move. **If E10 passes:** documented deferral with measured baseline in this file |

## Build under test

Install the latest **debug dogfood APK** built from `v2.0` with `oauth_local.json` dart-defines (Wave 6P P1 `@ db6d316` or later). Path after build:

`build/app/outputs/flutter-apk/app-debug.apk`

## E10 — Operator profiling script (~10 min)

**Account:** Real Graph and/or IMAP account with **≥500 inbox messages** (or your daily-driver volume).

**Tools:** USB debugging, Flutter DevTools Performance tab (attach to running debug APK) **or** Android Studio Profiler → CPU / Frame timeline.

### Steps

1. **Cold start** — launch Synesis; wait until inbox list is visible from local DB (no interaction for 5 s).
2. **Baseline scroll** — scroll inbox up/down for 15 s **without** syncing. Note worst frame time (target: mostly ≤16 ms).
3. **Manual sync + scroll** — tap toolbar **Sync**; immediately scroll inbox continuously for 30 s.
4. **Pull-to-refresh + scroll** — pull-to-refresh once; scroll 15 s while `Syncing (N jobs)` shows in title bar.
5. **Mark-read burst** — with sync still running or just finished, mark **10 messages read** rapidly; scroll list during local recount (Wave 6P DEF-007 / honest spinner check).

### Record (no credentials / PII)

| Step | Worst frame (ms) | Sustained jank? (Y/N) | Notes |
| --- | --- | --- | --- |
| 2 Baseline scroll | | | |
| 3 Sync + scroll | | | |
| 4 Pull + scroll | | | |
| 5 Mark-read burst | | | |

**E10 PASS:** Steps 3–4 show no **sustained** >16 ms frames (occasional single spikes OK). Step 5 must not show global sync spinner (P0) or list flicker (DEF-007).

**E10 FAIL:** Visible stutter or DevTools shows repeated >16 ms frames during steps 3–4 → open E11 isolate spike.

## E11 — Decision log

| Date | Operator | E10 result | Action |
| --- | --- | --- | --- |
| 2026-08-03 | Trish | *pending* | Profiling gate opened; dogfood APK + P1 (`db6d316`) |

### If E10 passes (expected after P0 non-blocking kick)

- Checklist E10/E11 ✅ with baseline table above filled in.
- Update [DART_IN_SYNESIS.md](DART_IN_SYNESIS.md) § Isolates — **current posture: defer** full `_processPendingJobs` isolate until a future wave unless operator revisits.
- Proceed to **Wave 6** (cross-account DnD copy) after full 6P sign-off.

### If E10 fails

- Execute [V2_WAVE_6P_P2_ISOLATE_SPIKE.md](V2_WAVE_6P_P2_ISOLATE_SPIKE.md) Phase 1 (job batch + inbox upsert off UI isolate).
- Re-run E10 on next dogfood APK before Wave 6.

## Related

- [V2_WAVE_6P_CHECKLIST.md](V2_WAVE_6P_CHECKLIST.md) — E10/E11 gates
- [DART_IN_SYNESIS.md](DART_IN_SYNESIS.md) — isolate posture (6P-14)
- Wave 6P P0/P1: `SyncActivity`, non-blocking kick, UI-P11/P9, DEF-007/015
