// ==============================================================================
// File: test/pim_sync_jobs_noop_test.dart
// Description: PIM sync job types dispatch successfully in SyncEngine (push no-op; copy soft no-op without payload; bootstrap/incremental no-op without PIM wiring).
// Component: Test
// Version: 1.2 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-08-04
// ==============================================================================

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/sync_profile.dart';
import 'package:synesis/protocol/mail_provider.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/network_sync_policy.dart';
import 'package:synesis/sync/pim_sync_jobs.dart';
import 'package:synesis/sync/sync_engine.dart';

class _NoopRepo implements MailRepository {
  final List<SyncJob> pending = <SyncJob>[];
  final List<Map<String, Object?>> completed = <Map<String, Object?>>[];
  int nextId = 1;

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {
    pending.add(
      SyncJob(
        id: 'job-${nextId++}',
        accountId: accountId,
        type: type,
        status: 'pending',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        payloadJson: payloadJson,
      ),
    );
  }

  @override
  Future<List<SyncJob>> claimPendingJobs({int limit = 8}) async {
    final List<SyncJob> batch = pending.take(limit).toList(growable: false);
    pending.removeWhere(batch.contains);
    return batch;
  }

  @override
  Future<void> completeJob(
    String id, {
    required bool success,
    String? cursorJson,
    String? error,
  }) async {
    completed.add(<String, Object?>{
      'id': id,
      'success': success,
      'error': error,
      'cursorJson': cursorJson,
    });
  }

  @override
  Future<bool> hasIncompleteJobOfType(String type) async => false;

  @override
  Future<int> reclaimRunningJobs() async => 0;

  @override
  Future<int> reclaimSendingOutbox() async => 0;

  @override
  Future<List<MailAccount>> listAccounts() async => const <MailAccount>[];

  @override
  Future<ResolvedSyncPolicy> resolvePolicy(
    String accountId, {
    int fallbackRetentionDays = 180,
  }) async =>
      ResolvedSyncPolicy(
        accountId: accountId,
        profileId: 'default',
        retentionDays: fallbackRetentionDays,
        bodyPolicy: BodyFetchPolicy.onOpen,
        attachmentMaxMb: 25,
      );

  @override
  Future<List<FocusRule>> listFocusRules({String? accountId}) async =>
      const <FocusRule>[];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('PimSyncJobs cursor key helpers follow documented convention', () {
    expect(
      PimSyncJobs.contactListCursorKey('list-1'),
      'pim:contact_list:list-1',
    );
    expect(PimSyncJobs.contactsCursorKey('list-1'), 'pim:contacts:list-1');
    expect(PimSyncJobs.calendarCursorKey('cal-1'), 'pim:calendar:cal-1');
    expect(PimSyncJobs.eventsCursorKey('cal-1'), 'pim:events:cal-1');
  });

  test('all registered PIM job types complete successfully without PIM wiring',
      () async {
    final _NoopRepo repo = _NoopRepo();
    final SyncEngine engine = SyncEngine(
      repository: repo,
      resolveProvider: (_) async => null,
      readConnectivity: () async =>
          const <ConnectivityResult>[ConnectivityResult.wifi],
      networkPolicy: const NetworkSyncPolicy(isDesktop: true),
    );

    for (final String type in PimSyncJobs.allRegistered) {
      await repo.enqueueSyncJob(accountId: 'work', type: type);
    }

    await engine.kick();

    expect(repo.pending, isEmpty);
    expect(repo.completed, hasLength(PimSyncJobs.allRegistered.length));
    for (final Map<String, Object?> row in repo.completed) {
      expect(row['success'], isTrue, reason: 'job ${row['id']}');
      expect(row['error'], isNull);
    }
  });

  test('unknown job type still fails', () async {
    final _NoopRepo repo = _NoopRepo();
    final SyncEngine engine = SyncEngine(
      repository: repo,
      resolveProvider: (_) async => null,
      readConnectivity: () async =>
          const <ConnectivityResult>[ConnectivityResult.wifi],
      networkPolicy: const NetworkSyncPolicy(isDesktop: true),
    );

    await repo.enqueueSyncJob(accountId: 'work', type: 'not_a_real_job');
    await engine.kick();

    expect(repo.completed, hasLength(1));
    expect(repo.completed.single['success'], isFalse);
  });
}
