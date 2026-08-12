# Sync recovery APIs (DEF-084)

Operator recovery hooks exposed on `SyncEngine` for Jules to wire from the Sync Status sheet. These clear **cursors and jobs only** — they do not wipe the local message store.

## Jules integration

| Action | Call | Notes |
| --- | --- | --- |
| Stop all sync | `syncEngine.stopAllSync()` | All accounts. Returns `(abortedRunning, cancelledPending)`. |
| Stop one account | `syncEngine.stopAllSync(accountId: id)` | Scoped stop. |
| Clear cursors | `syncEngine.clearSyncCursors(accountId: id)` | Per-account Graph/IMAP/PIM cursors. |
| Clear one folder | `syncEngine.clearSyncCursors(accountId: id, folderId: folderId)` | Includes PIM collection ids. |
| Force token refresh | `await syncEngine.forceRefreshAuthToken(accountId)` | Graph + Google XOAUTH only. |
| Sync now (after recovery) | `await syncEngine.enqueueIncremental(id); syncEngine.kickNonBlocking();` | Existing path. |

`MailRepository` also exposes `cancelPendingSyncJobs`, `abortRunningSyncJobs`, and `clearSyncCursors` for direct Drift access if needed.

## DEF-083 — expired Graph delta token

`_tryGraphDelta` treats **410** and **400** (*Sync token is expired*) as cursor invalid via `isGraphExpiredSyncToken()` in `lib/sync/graph_sync_recovery.dart`. Clears `graph_delta` cursor and falls back to `listRecent` + delta re-seed.

## Related

- [DEFECTS.md](../DEFECTS.md) — DEF-083, DEF-084
- `lib/sync/sync_engine.dart` — implementation
