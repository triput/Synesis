// ==============================================================================
// File: lib/sync/sync_auto_sync_policy.dart
// Description: Pure auto-sync gating for Android sync modes (DEF-086)
// Component: Sync
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'package:synesis/sync/android_sync_mode.dart';

/// Connectivity / lifecycle decisions for [SyncEngine] auto-sync (testable).
abstract final class SyncAutoSyncPolicy {
  /// Desktop keeps legacy near-push behavior regardless of the mobile dial.
  static AndroidSyncMode effectiveMode({
    required AndroidSyncMode configured,
    required bool isMobile,
  }) {
    if (!isMobile) {
      return AndroidSyncMode.push;
    }
    return configured;
  }

  static bool shouldKickOnConnectivity(AndroidSyncMode mode) {
    return mode != AndroidSyncMode.manual;
  }

  static bool shouldKickOnForegroundResume(AndroidSyncMode mode) {
    return mode != AndroidSyncMode.manual;
  }

  static bool shouldRunIdle(AndroidSyncMode mode) {
    return mode == AndroidSyncMode.push;
  }

  static bool shouldRunIntervalTimer({
    required AndroidSyncMode mode,
    required bool isForeground,
  }) {
    return mode == AndroidSyncMode.interval && isForeground;
  }

  static int clampIntervalMinutes(int minutes) {
    return minutes.clamp(kSyncIntervalMinutesMin, kSyncIntervalMinutesMax);
  }
}
