// ==============================================================================
// File: test/sync_engine_kick_lifecycle_test.dart
// Description: Wave 6P SyncEngine kickFresh reclaim + non-blocking kick lifecycle.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'dart:async';

import 'package:synesis/domain/models.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/sync_activity.dart';
import 'package:synesis/sync/sync_engine.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _KickLifecycleRepo implements MailRepository {
  Completer<void>? claimGate;
  int reclaimRunningCalls = 0;
  int reclaimSendingCalls = 0;
  int claimPendingCalls = 0;
  final List<SyncJob> pending = <SyncJob>[];
  int nextJobId = 1;

  void enqueuePending(String type, {String accountId = 'work'}) {
    pending.add(
      SyncJob(
        id: 'job-${nextJobId++}',
        accountId: accountId,
        type: type,
        status: 'pending',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {
    pending.add(
      SyncJob(
        id: 'job-${nextJobId++}',
        accountId: accountId,
        type: type,
        status: 'pending',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        payloadJson: payloadJson,
      ),
    );
  }

  @override
  Future<bool> hasIncompleteJobOfType(String type) async => pending.any(
    (SyncJob job) =>
        job.type == type &&
        (job.status == 'pending' || job.status == 'running'),
  );

  @override
  Future<List<SyncJob>> claimPendingJobs({int limit = 10}) async {
    claimPendingCalls += 1;
    final Completer<void>? gate = claimGate;
    if (gate != null) {
      await gate.future;
    }
    if (pending.isEmpty) {
      return const <SyncJob>[];
    }
    final List<SyncJob> claimed = pending.take(limit).toList(growable: false);
    pending.removeRange(0, claimed.length);
    return claimed
        .map(
          (SyncJob job) => SyncJob(
            id: job.id,
            accountId: job.accountId,
            type: job.type,
            status: 'running',
            updatedAt: job.updatedAt,
            payloadJson: job.payloadJson,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> completeJob(
    String id, {
    required bool success,
    String? cursorJson,
    String? error,
  }) async {}

  @override
  Future<int> reclaimRunningJobs() async {
    reclaimRunningCalls += 1;
    return 1;
  }

  @override
  Future<int> reclaimSendingOutbox() async {
    reclaimSendingCalls += 1;
    return 0;
  }

  @override
  Future<List<MailAccount>> listAccounts() async => const <MailAccount>[
    MailAccount(
      id: 'work',
      label: 'W',
      address: 'work@byte.io',
      accent: Color(0xFF2DD4BF),
    ),
  ];

  @override
  Future<({int running, int pending})> countSyncJobActivity() async =>
      (running: 0, pending: pending.length);

  @override
  Stream<void> watchChanges() => const Stream<void>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncEngine Wave 6P kick lifecycle (DEF-006 / E6)', () {
    test('kickFresh reclaims running jobs before processing', () async {
      final _KickLifecycleRepo repo = _KickLifecycleRepo();
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        trashRetentionDays: () => 30,
      );

      await engine.kickFresh();

      expect(repo.reclaimRunningCalls, greaterThan(0));
      expect(repo.reclaimSendingCalls, greaterThan(0));
      await engine.dispose();
    });

    test(
      'kickFresh abandons hung kick and reclaims (DEF-006 regression)',
      () async {
        final Completer<void> hungClaim = Completer<void>();
        final _KickLifecycleRepo repo = _KickLifecycleRepo()
          ..claimGate = hungClaim;
        final SyncEngine engine = SyncEngine(
          repository: repo,
          resolveProvider: (_) async => null,
          trashRetentionDays: () => 30,
        );

        engine.kickNonBlocking();
        await Future<void>.delayed(Duration.zero);
        expect(engine.isKickInFlight, isTrue);

        final int reclaimBeforeFresh = repo.reclaimRunningCalls;
        // Clear the hang gate for the fresh generation's claim loop.
        repo.claimGate = null;
        final Future<void> fresh = engine.kickFresh();

        // Hung first kick must not block kickFresh completion.
        await fresh.timeout(const Duration(seconds: 2));
        expect(repo.reclaimRunningCalls, greaterThan(reclaimBeforeFresh));
        expect(engine.isKickInFlight, isFalse);

        hungClaim.complete();
        await engine.dispose();
      },
    );

    test(
      'kickFreshNonBlocking reclaims then returns without awaiting kick',
      () async {
        final Completer<void> claimGate = Completer<void>();
        final _KickLifecycleRepo repo = _KickLifecycleRepo()
          ..claimGate = claimGate;
        final SyncEngine engine = SyncEngine(
          repository: repo,
          resolveProvider: (_) async => null,
          trashRetentionDays: () => 30,
        );

        final Stopwatch stopwatch = Stopwatch()..start();
        await engine.kickFreshNonBlocking();
        stopwatch.stop();

        expect(stopwatch.elapsedMilliseconds, lessThan(500));
        expect(repo.reclaimRunningCalls, greaterThan(0));
        expect(repo.reclaimSendingCalls, greaterThan(0));
        expect(engine.isKickInFlight, isTrue);

        claimGate.complete();
        await engine.kick();
        expect(engine.isKickInFlight, isFalse);
        await engine.dispose();
      },
    );

    test(
      'kickNonBlocking notifies SyncActivity start/end around in-flight kick',
      () async {
        final Completer<void> claimGate = Completer<void>();
        final _KickLifecycleRepo repo = _KickLifecycleRepo()
          ..claimGate = claimGate;
        final SyncActivity activity = SyncActivity(repository: repo);
        final SyncEngine engine = SyncEngine(
          repository: repo,
          resolveProvider: (_) async => null,
          trashRetentionDays: () => 30,
        );
        engine.attachSyncActivity(activity);

        final List<bool> inFlight = <bool>[];
        final StreamSubscription<SyncActivitySnapshot> sub = activity.stream
            .listen(
              (SyncActivitySnapshot snapshot) =>
                  inFlight.add(snapshot.isRemoteSyncInFlight),
            );
        addTearDown(sub.cancel);

        engine.kickNonBlocking();
        await Future<void>.delayed(Duration.zero);
        await activity.refresh();

        expect(engine.isKickInFlight, isTrue);
        expect(activity.value.isRemoteSyncInFlight, isTrue);

        claimGate.complete();
        await engine.kick();
        await Future<void>.delayed(Duration.zero);
        await activity.refresh();

        expect(engine.isKickInFlight, isFalse);
        expect(activity.value.isRemoteSyncInFlight, isFalse);
        expect(inFlight, contains(true));
        await activity.dispose();
        await engine.dispose();
      },
    );

    test('duplicate kickNonBlocking shares the in-flight kick future', () async {
      final Completer<void> claimGate = Completer<void>();
      final _KickLifecycleRepo repo = _KickLifecycleRepo()..claimGate = claimGate;
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        trashRetentionDays: () => 30,
      );

      engine.kickNonBlocking();
      for (int i = 0; i < 40 && repo.claimPendingCalls < 1; i++) {
        await Future<void>.delayed(Duration.zero);
      }
      expect(repo.claimPendingCalls, 1);
      expect(engine.isKickInFlight, isTrue);

      engine.kickNonBlocking();
      await Future<void>.delayed(Duration.zero);
      expect(repo.claimPendingCalls, 1);

      claimGate.complete();
      await engine.kick();
      expect(engine.isKickInFlight, isFalse);
      await engine.dispose();
    });
  });
}
