# Synesis V1 Exit Checklist

Use this checklist to verify the SPEC milestone exits before the v1 release.

**Status:** **Signed off 2026-07-22** (operator). ~~W0–W7~~ landed; Final wave Phases A–G complete — see [FINAL_WAVE_PLAN.md](FINAL_WAVE_PLAN.md). FW-5 matrix: [V1_MANUAL_E2E_MATRIX.csv](V1_MANUAL_E2E_MATRIX.csv) finalized Pass.

## M0 — Planning + BLoC foundation
- [x] Application shell uses BLoC/Cubit state only.
- [x] Settings persist across restart.
- [x] `flutter analyze` and tests pass.

## M1 — Local data plane
- [x] Cold start renders mailbox data from SQLite.
- [x] Mailbox state restores offline after restart.

## M2 — Dual protocol thin spike
- [x] Graph account imports message headers into SQLite.
- [x] IMAP account imports message headers into SQLite.

## M3 — Sync engine deepen
- [x] Sync jobs and cursors survive restart.
- [x] Incremental catch-up works for both providers.

## M4 — Compose / outbox / send
- [x] Offline compose is durable.
- [x] Reconnect sends queued messages or reports actionable failure.

## M5 — Search
- [x] FTS search works offline.
- [x] Remote search results are ingested under the documented contract.

## M6 — Optional Focus
- [x] Focused/Other behavior meets SPEC §8.3.
- [x] Focus rules and overrides have automated tests.

## M7 — Retention & sync profiles
- [x] Retention job uses `retention_cleanup` and a configured day count.
- [x] Cleanup removes only cached, unpinned messages.
- [x] Pins survive all supported retention windows.

## M8 — Appearance completeness
- [x] All five theme selectors are usable.
- [x] Account color selection is available.

## M9 — Android widgets
- [x] List, unread counter, and actions have fresh JSON snapshots.
- [x] Kotlin widget renders the shared snapshot without starting Flutter.
- [x] Widget refresh is validated after a successful sync commit.

## M10 — Windows desktop polish
- [x] Minimize-to-tray preference is persisted and wired to a Windows adapter.
- [x] New-mail toast provider is wired and exercised on Windows.
- [x] Ctrl+J/K/N/F keyboard shortcuts work when enabled; letter keys type normally in compose/search fields.

## M11 — Hardening & v1 gate
- [x] Diagnostics exports contain no credentials, cursors, recipients, or message content.
- [x] Account wipe requires account-specific confirmation.
- [x] Performance targets are measured against representative mailboxes.
- [x] Full SPEC acceptance review is complete.

## Sign-off

| Field | Value |
| --- | --- |
| Operator | Confirmed complete (chat 2026-07-22) |
| Date | 2026-07-22 |
| FW-5 | [V1_MANUAL_E2E_MATRIX.csv](V1_MANUAL_E2E_MATRIX.csv) — all rows Pass |
| Post-V1 | Formal perf suite, Android focus track, UI-P29/P30 — see [ROADMAP.md](ROADMAP.md) Planned backlog |
