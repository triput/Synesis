// ==============================================================================
// File: test/sync_auto_sync_policy_test.dart
// Description: DEF-086 auto-sync gating unit tests
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'package:synesis/sync/android_sync_mode.dart';
import 'package:synesis/sync/sync_auto_sync_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SyncAutoSyncPolicy', () {
    test('desktop always uses push-like mode', () {
      expect(
        SyncAutoSyncPolicy.effectiveMode(
          configured: AndroidSyncMode.manual,
          isMobile: false,
        ),
        AndroidSyncMode.push,
      );
    });

    test('mobile respects configured mode', () {
      expect(
        SyncAutoSyncPolicy.effectiveMode(
          configured: AndroidSyncMode.interval,
          isMobile: true,
        ),
        AndroidSyncMode.interval,
      );
    });

    test('manual skips connectivity and resume kicks', () {
      expect(
        SyncAutoSyncPolicy.shouldKickOnConnectivity(AndroidSyncMode.manual),
        isFalse,
      );
      expect(
        SyncAutoSyncPolicy.shouldKickOnForegroundResume(AndroidSyncMode.manual),
        isFalse,
      );
    });

    test('interval runs timer only in foreground', () {
      expect(
        SyncAutoSyncPolicy.shouldRunIntervalTimer(
          mode: AndroidSyncMode.interval,
          isForeground: true,
        ),
        isTrue,
      );
      expect(
        SyncAutoSyncPolicy.shouldRunIntervalTimer(
          mode: AndroidSyncMode.interval,
          isForeground: false,
        ),
        isFalse,
      );
      expect(
        SyncAutoSyncPolicy.shouldRunIdle(AndroidSyncMode.interval),
        isFalse,
      );
    });

    test('push enables IDLE not interval timer', () {
      expect(SyncAutoSyncPolicy.shouldRunIdle(AndroidSyncMode.push), isTrue);
      expect(
        SyncAutoSyncPolicy.shouldRunIntervalTimer(
          mode: AndroidSyncMode.push,
          isForeground: true,
        ),
        isFalse,
      );
    });

    test('clamps interval minutes', () {
      expect(SyncAutoSyncPolicy.clampIntervalMinutes(1), kSyncIntervalMinutesMin);
      expect(SyncAutoSyncPolicy.clampIntervalMinutes(999), kSyncIntervalMinutesMax);
    });
  });
}
