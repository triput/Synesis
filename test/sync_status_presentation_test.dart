// ==============================================================================
// File: test/sync_status_presentation_test.dart
// Description: Wave 6P UI-P11 unified sync status label composition.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/sync/sync_activity.dart';
import 'package:synesis/ui/sync/sync_status_presentation.dart';

void main() {
  group('SyncStatusPresentation', () {
    test('composeLabel uses syncing with job count when in flight', () {
      const SyncActivitySnapshot activity = SyncActivitySnapshot(
        isRemoteSyncInFlight: true,
        runningJobCount: 1,
        pendingJobCount: 2,
      );
      expect(
        SyncStatusPresentation.composeLabel(
          activity: activity,
          repositoryLabel: 'Up to date',
        ),
        'Syncing (3 jobs)',
      );
    });

    test('composeLabel falls back to repository label when idle', () {
      expect(
        SyncStatusPresentation.composeLabel(
          activity: const SyncActivitySnapshot.idle(),
          repositoryLabel: 'Outbox send failed',
        ),
        'Outbox send failed',
      );
    });

    test('needsAttention detects failed and outbox labels', () {
      expect(SyncStatusPresentation.needsAttention('Sync failed: timeout'), isTrue);
      expect(SyncStatusPresentation.needsAttention('2 waiting to send'), isTrue);
      expect(SyncStatusPresentation.needsAttention('Up to date'), isFalse);
    });
  });
}
