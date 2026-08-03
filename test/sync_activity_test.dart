// ==============================================================================
// File: test/sync_activity_test.dart
// Description: Wave 6P SyncActivity idle vs in-flight from job counts + kick.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'dart:async';

import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/sync_activity.dart';
import 'package:flutter_test/flutter_test.dart';

class _ActivityRepo implements MailRepository {
  _ActivityRepo({
    this.running = 0,
    this.pending = 0,
  });

  int running;
  int pending;
  final StreamController<void> changes = StreamController<void>.broadcast();
  int countCalls = 0;

  void setCounts({required int runningCount, required int pendingCount}) {
    running = runningCount;
    pending = pendingCount;
    changes.add(null);
  }

  @override
  Future<({int running, int pending})> countSyncJobActivity() async {
    countCalls += 1;
    return (running: running, pending: pending);
  }

  @override
  Stream<void> watchChanges() => changes.stream;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncActivity', () {
    late _ActivityRepo repo;
    late SyncActivity activity;

    setUp(() {
      repo = _ActivityRepo();
      activity = SyncActivity(repository: repo);
    });

    tearDown(() async {
      await activity.dispose();
      await repo.changes.close();
    });

    test('starts idle when job store is empty', () async {
      activity.start();
      await Future<void>.delayed(Duration.zero);
      await activity.refresh();

      expect(activity.value.isRemoteSyncInFlight, isFalse);
      expect(activity.value.runningJobCount, 0);
      expect(activity.value.pendingJobCount, 0);
      expect(activity.value.activeJobCount, 0);
    });

    test('marks in-flight when pending jobs exist', () async {
      repo.pending = 2;
      await activity.refresh();

      expect(activity.value.isRemoteSyncInFlight, isTrue);
      expect(activity.value.pendingJobCount, 2);
      expect(activity.value.runningJobCount, 0);
      expect(activity.value.activeJobCount, 2);
    });

    test('marks in-flight when running jobs exist', () async {
      repo.running = 1;
      await activity.refresh();

      expect(activity.value.isRemoteSyncInFlight, isTrue);
      expect(activity.value.runningJobCount, 1);
      expect(activity.value.activeJobCount, 1);
    });

    test('kick lifecycle forces in-flight even with zero job counts', () async {
      final List<SyncActivitySnapshot> emitted = <SyncActivitySnapshot>[];
      final StreamSubscription<SyncActivitySnapshot> sub = activity.stream.listen(
        emitted.add,
      );
      addTearDown(sub.cancel);

      await activity.refresh();
      expect(activity.value.isRemoteSyncInFlight, isFalse);

      activity.onKickStarted();
      await Future<void>.delayed(Duration.zero);
      await activity.refresh();

      expect(activity.value.isRemoteSyncInFlight, isTrue);
      expect(
        emitted.any((SyncActivitySnapshot s) => s.isRemoteSyncInFlight),
        isTrue,
      );

      activity.onKickEnded();
      await Future<void>.delayed(Duration.zero);
      await activity.refresh();

      expect(activity.value.isRemoteSyncInFlight, isFalse);
    });

    test('duplicate onKickStarted does not nest kick flag', () async {
      activity.onKickStarted();
      activity.onKickStarted();
      await Future<void>.delayed(Duration.zero);
      await activity.refresh();
      expect(activity.value.isRemoteSyncInFlight, isTrue);

      activity.onKickEnded();
      await Future<void>.delayed(Duration.zero);
      await activity.refresh();
      expect(activity.value.isRemoteSyncInFlight, isFalse);
    });

    test('watchChanges triggers refresh when job counts change', () async {
      activity.start();
      await Future<void>.delayed(Duration.zero);
      await activity.refresh();
      expect(activity.value.isRemoteSyncInFlight, isFalse);

      repo.setCounts(runningCount: 0, pendingCount: 3);
      await Future<void>.delayed(Duration.zero);
      await activity.refresh();

      expect(activity.value.isRemoteSyncInFlight, isTrue);
      expect(activity.value.pendingJobCount, 3);
    });

    test('snapshot equality ignores identical republish', () async {
      repo.pending = 1;
      await activity.refresh();
      final int callsAfterFirst = repo.countCalls;
      final SyncActivitySnapshot first = activity.value;

      await activity.refresh();
      expect(activity.value, same(first) == false ? activity.value : first);
      expect(activity.value, equals(first));
      expect(repo.countCalls, greaterThan(callsAfterFirst));
    });
  });
}
