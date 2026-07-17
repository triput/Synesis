// ==============================================================================
// File: lib/repository/drift/drift_sync_job_store.dart
// Description: Drift persistence for sync jobs, cursors, and status labels.
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/repository/database.dart';
import 'package:bytemail/repository/drift/drift_mappers.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class DriftSyncJobStore {
  DriftSyncJobStore(
    this._database, {
    required void Function() notify,
    required Future<int> Function() countQueuedOutbox,
  }) : _notify = notify,
       _countQueuedOutbox = countQueuedOutbox;

  final ByteMailDatabase _database;
  final void Function() _notify;
  final Future<int> Function() _countQueuedOutbox;
  final Uuid _uuid = const Uuid();

  Future<String> syncStatusLabel() async {
    final Expression<int> runningCount = _database.jobs.id.count();
    final TypedResult running =
        await (_database.selectOnly(_database.jobs)
              ..addColumns(<Expression<Object>>[runningCount])
              ..where(_database.jobs.status.equals('running')))
            .getSingle();
    if ((running.read(runningCount) ?? 0) > 0) {
      return 'Syncing';
    }
    final Expression<int> failedOutboxCount = _database.outbox.id.count();
    final TypedResult failedOutbox =
        await (_database.selectOnly(_database.outbox)
              ..addColumns(<Expression<Object>>[failedOutboxCount])
              ..where(_database.outbox.state.equals('failed')))
            .getSingle();
    final int failedSends = failedOutbox.read(failedOutboxCount) ?? 0;
    final Job? latest =
        await (_database.select(_database.jobs)
              ..orderBy(<OrderingTerm Function(Jobs)>[
                (Jobs table) => OrderingTerm.desc(table.updatedAt),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (latest != null && latest.status == 'failed') {
      final String detail = _jobErrorDetail(latest.cursorJson);
      if (detail.isNotEmpty) {
        final String short = detail.length > 80
            ? '${detail.substring(0, 80)}…'
            : detail;
        if (failedSends > 0) {
          return 'Sync failed: $short · outbox $failedSends failed';
        }
        return 'Sync failed: $short';
      }
      if (failedSends > 0) {
        return 'Sync needs attention · outbox $failedSends failed';
      }
      return 'Sync needs attention';
    }
    if (failedSends > 0) {
      return failedSends == 1
          ? 'Outbox send failed'
          : 'Outbox: $failedSends failed';
    }
    final int pendingSends = await _countQueuedOutbox();
    if (latest != null &&
        latest.status == 'done' &&
        _folderListErrorDetail(latest.cursorJson).isNotEmpty) {
      if (pendingSends > 0) {
        return 'Folder list incomplete · $pendingSends queued';
      }
      return 'Up to date · folder list incomplete';
    }
    if (pendingSends > 0) {
      return pendingSends == 1
          ? '1 waiting to send'
          : '$pendingSends waiting to send';
    }
    return 'Up to date';
  }

  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {
    await _database
        .into(_database.jobs)
        .insert(
          JobsCompanion.insert(
            id: _uuid.v4(),
            accountId: accountId,
            type: type,
            status: 'pending',
            payloadJson: Value<String?>(payloadJson),
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    _notify();
  }

  Future<bool> hasIncompleteJobOfType(String type) async {
    final Job? row =
        await (_database.select(_database.jobs)
              ..where(
                (Jobs table) =>
                    table.type.equals(type) &
                    (table.status.equals('pending') |
                        table.status.equals('running')),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  Future<int> reclaimRunningJobs() async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    final int changed =
        await (_database.update(
          _database.jobs,
        )..where((Jobs table) => table.status.equals('running'))).write(
          JobsCompanion(
            status: const Value<String>('pending'),
            updatedAt: Value<int>(now),
          ),
        );
    if (changed > 0) {
      _notify();
    }
    return changed;
  }

  Future<List<SyncJob>> claimPendingJobs({int limit = 10}) async {
    if (limit < 1) {
      return <SyncJob>[];
    }
    final List<SyncJob> claimed = await _database.transaction(() async {
      final List<Job> rows =
          await (_database.select(_database.jobs)
                ..where((Jobs table) => table.status.equals('pending'))
                ..orderBy(<OrderingTerm Function(Jobs)>[
                  (Jobs table) => OrderingTerm.asc(table.updatedAt),
                ])
                ..limit(limit))
              .get();
      final int now = DateTime.now().millisecondsSinceEpoch;
      for (final Job row in rows) {
        await (_database.update(
          _database.jobs,
        )..where((Jobs table) => table.id.equals(row.id))).write(
          JobsCompanion(
            status: const Value<String>('running'),
            updatedAt: Value<int>(now),
          ),
        );
      }
      return rows
          .map(
            (Job row) => syncJobFromRow(
              row.copyWith(status: 'running', updatedAt: now),
            ),
          )
          .toList(growable: false);
    });
    if (claimed.isNotEmpty) {
      _notify();
    }
    return claimed;
  }

  Future<void> completeJob(
    String id, {
    required bool success,
    String? cursorJson,
    String? error,
  }) async {
    final String? resultJson = error == null
        ? cursorJson
        : jsonEncode(<String, String>{'error': error});
    await (_database.update(
      _database.jobs,
    )..where((Jobs table) => table.id.equals(id))).write(
      JobsCompanion(
        status: Value<String>(success ? 'done' : 'failed'),
        cursorJson: Value<String?>(resultJson),
        updatedAt: Value<int>(DateTime.now().millisecondsSinceEpoch),
      ),
    );
    _notify();
  }

  Future<List<SyncJob>> listSyncJobs({int limit = 50}) async {
    final int capped = limit < 1 ? 1 : (limit > 500 ? 500 : limit);
    final List<Job> rows =
        await (_database.select(_database.jobs)
              ..orderBy(<OrderingTerm Function(Jobs)>[
                (Jobs table) => OrderingTerm.desc(table.updatedAt),
              ])
              ..limit(capped))
            .get();
    return rows.map(syncJobFromRow).toList(growable: false);
  }

  Future<void> retrySyncJob(String id) async {
    final Job? row =
        await (_database.select(_database.jobs)
              ..where((Jobs table) => table.id.equals(id)))
            .getSingleOrNull();
    if (row == null) {
      return;
    }
    if (row.status == 'failed') {
      final int now = DateTime.now().millisecondsSinceEpoch;
      await (_database.update(
        _database.jobs,
      )..where((Jobs table) => table.id.equals(id))).write(
        JobsCompanion(
          status: const Value<String>('pending'),
          cursorJson: const Value<String?>(null),
          updatedAt: Value<int>(now),
        ),
      );
      _notify();
      return;
    }
    if (row.status == 'done') {
      await enqueueSyncJob(
        accountId: row.accountId,
        type: row.type,
        payloadJson: row.payloadJson,
      );
    }
  }

  Future<void> cancelSyncJob(String id) async {
    final Job? row =
        await (_database.select(_database.jobs)
              ..where((Jobs table) => table.id.equals(id)))
            .getSingleOrNull();
    if (row == null || row.status != 'pending') {
      return;
    }
    await (_database.delete(
      _database.jobs,
    )..where((Jobs table) => table.id.equals(id))).go();
    _notify();
  }

  Future<List<AccountSyncHealth>> listAccountSyncHealth() async {
    final List<Account> accounts =
        await _database.select(_database.accounts).get();
    if (accounts.isEmpty) {
      return const <AccountSyncHealth>[];
    }
    final List<Job> jobs = await _database.select(_database.jobs).get();
    final List<SyncCursor> cursors =
        await _database.select(_database.syncCursors).get();

    final Map<String, List<Job>> jobsByAccount = <String, List<Job>>{};
    for (final Job job in jobs) {
      jobsByAccount.putIfAbsent(job.accountId, () => <Job>[]).add(job);
    }
    final Map<String, List<SyncCursor>> cursorsByAccount =
        <String, List<SyncCursor>>{};
    for (final SyncCursor cursor in cursors) {
      cursorsByAccount
          .putIfAbsent(cursor.accountId, () => <SyncCursor>[])
          .add(cursor);
    }

    return accounts.map((Account account) {
      final List<Job> accountJobs =
          jobsByAccount[account.id] ?? const <Job>[];
      int pendingCount = 0;
      int failedCount = 0;
      bool syncing = false;
      Job? latestFailed;
      Job? latestDone;
      for (final Job job in accountJobs) {
        switch (job.status) {
          case 'pending':
            pendingCount += 1;
          case 'running':
            syncing = true;
          case 'failed':
            failedCount += 1;
            if (latestFailed == null ||
                job.updatedAt > latestFailed.updatedAt) {
              latestFailed = job;
            }
          case 'done':
            if (latestDone == null || job.updatedAt > latestDone.updatedAt) {
              latestDone = job;
            }
        }
      }

      DateTime? lastSuccessAt;
      if (latestDone != null) {
        lastSuccessAt = DateTime.fromMillisecondsSinceEpoch(
          latestDone.updatedAt,
          isUtc: true,
        ).toLocal();
      }
      final List<SyncCursor> accountCursors =
          cursorsByAccount[account.id] ?? const <SyncCursor>[];
      for (final SyncCursor cursor in accountCursors) {
        final DateTime? parsed = DateTime.tryParse(cursor.cursorValue);
        if (parsed == null) {
          continue;
        }
        final DateTime local = parsed.toLocal();
        if (lastSuccessAt == null || local.isAfter(lastSuccessAt)) {
          lastSuccessAt = local;
        }
      }

      return AccountSyncHealth(
        accountId: account.id,
        lastSuccessAt: lastSuccessAt,
        lastError: latestFailed == null
            ? null
            : syncJobFromRow(latestFailed).errorSnippet,
        pendingCount: pendingCount,
        failedCount: failedCount,
        syncing: syncing,
      );
    }).toList(growable: false);
  }

  Future<void> setCursor(
    String accountId,
    String folderId,
    String key,
    String value,
  ) async {
    await _database
        .into(_database.syncCursors)
        .insertOnConflictUpdate(
          SyncCursorsCompanion.insert(
            accountId: accountId,
            folderId: folderId,
            cursorKey: key,
            cursorValue: value,
          ),
        );
    _notify();
  }

  Future<String?> getCursor(
    String accountId,
    String folderId,
    String key,
  ) async {
    final SyncCursor? row =
        await (_database.select(_database.syncCursors)..where(
              (SyncCursors table) =>
                  table.accountId.equals(accountId) &
                  table.folderId.equals(folderId) &
                  table.cursorKey.equals(key),
            ))
            .getSingleOrNull();
    return row?.cursorValue;
  }

  String _jobErrorDetail(String? cursorJson) {
    if (cursorJson == null || cursorJson.trim().isEmpty) {
      return '';
    }
    try {
      final Object? decoded = jsonDecode(cursorJson);
      if (decoded is Map<Object?, Object?>) {
        return decoded['error']?.toString() ?? '';
      }
    } on FormatException {
      return cursorJson;
    }
    return '';
  }

  String _folderListErrorDetail(String? cursorJson) {
    if (cursorJson == null || cursorJson.trim().isEmpty) {
      return '';
    }
    try {
      final Object? decoded = jsonDecode(cursorJson);
      if (decoded is Map<Object?, Object?>) {
        return decoded['folderListError']?.toString() ?? '';
      }
    } on FormatException {
      return '';
    }
    return '';
  }
}
