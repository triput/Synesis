// ==============================================================================
// File: lib/sync/sync_activity.dart
// Description: Observable remote sync lifecycle (job counts + kick in-flight)
// Component: Sync
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'dart:async';

import 'package:synesis/repository/mail_repository.dart';

/// Point-in-time remote sync activity derived from the job store and
/// [SyncEngine] kick lifecycle (Wave 6P — honest sync UX).
class SyncActivitySnapshot {
  const SyncActivitySnapshot({
    required this.isRemoteSyncInFlight,
    required this.runningJobCount,
    required this.pendingJobCount,
  });

  const SyncActivitySnapshot.idle()
      : isRemoteSyncInFlight = false,
        runningJobCount = 0,
        pendingJobCount = 0;

  final bool isRemoteSyncInFlight;
  final int runningJobCount;
  final int pendingJobCount;

  int get activeJobCount => runningJobCount + pendingJobCount;

  @override
  bool operator ==(Object other) {
    return other is SyncActivitySnapshot &&
        other.isRemoteSyncInFlight == isRemoteSyncInFlight &&
        other.runningJobCount == runningJobCount &&
        other.pendingJobCount == pendingJobCount;
  }

  @override
  int get hashCode => Object.hash(
    isRemoteSyncInFlight,
    runningJobCount,
    pendingJobCount,
  );
}

/// Broadcasts [SyncActivitySnapshot] updates for title-bar / toolbar honesty.
///
/// Listens to [MailRepository.watchChanges] for job-store mutations and accepts
/// kick start/end signals from [SyncEngine.attachSyncActivity].
class SyncActivity {
  SyncActivity({required MailRepository repository}) : _repository = repository;

  final MailRepository _repository;
  final StreamController<SyncActivitySnapshot> _controller =
      StreamController<SyncActivitySnapshot>.broadcast();

  SyncActivitySnapshot _current = const SyncActivitySnapshot.idle();
  StreamSubscription<void>? _watchSub;
  bool _kickInFlight = false;

  Stream<SyncActivitySnapshot> get stream => _controller.stream;

  SyncActivitySnapshot get value => _current;

  /// Subscribes to repository changes and emits an initial snapshot.
  void start() {
    _watchSub?.cancel();
    _watchSub = _repository.watchChanges().listen((_) {
      unawaited(refresh());
    });
    unawaited(refresh());
  }

  /// Called by [SyncEngine] when a kick batch begins.
  void onKickStarted() {
    if (_kickInFlight) {
      return;
    }
    _kickInFlight = true;
    unawaited(refresh());
  }

  /// Called by [SyncEngine] when a kick batch completes.
  void onKickEnded() {
    if (!_kickInFlight) {
      return;
    }
    _kickInFlight = false;
    unawaited(refresh());
  }

  /// Re-reads job-store counts and publishes when changed.
  Future<void> refresh() async {
    final ({int running, int pending}) counts =
        await _repository.countSyncJobActivity();
    final SyncActivitySnapshot next = SyncActivitySnapshot(
      isRemoteSyncInFlight:
          _kickInFlight || counts.running > 0 || counts.pending > 0,
      runningJobCount: counts.running,
      pendingJobCount: counts.pending,
    );
    if (next == _current) {
      return;
    }
    _current = next;
    if (!_controller.isClosed) {
      _controller.add(next);
    }
  }

  Future<void> dispose() async {
    await _watchSub?.cancel();
    _watchSub = null;
    await _controller.close();
  }
}
