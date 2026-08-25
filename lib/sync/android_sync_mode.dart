// ==============================================================================
// File: lib/sync/android_sync_mode.dart
// Description: Operator-visible mail sync modes for Android (DEF-086)
// Component: Sync
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

/// How Synesis fetches new mail while the app can run (Android-first; desktop
/// keeps near-push / IDLE regardless — see [SyncEngine] auto-sync policy).
enum AndroidSyncMode {
  /// Sync only when the operator pulls, opens sync, or similar explicit kick.
  manual,

  /// Periodic poll while the app is in the foreground.
  interval,

  /// IMAP IDLE / reconnect kicks while online (Graph still delta-on-kick).
  push,
}

extension AndroidSyncModeX on AndroidSyncMode {
  String get label => switch (this) {
        AndroidSyncMode.manual => 'Manual',
        AndroidSyncMode.interval => 'Interval',
        AndroidSyncMode.push => 'Push',
      };

  String get settingsSubtitle => switch (this) {
        AndroidSyncMode.manual =>
          'Sync when you pull to refresh or tap Sync.',
        AndroidSyncMode.interval =>
          'Poll on a timer while Synesis is open.',
        AndroidSyncMode.push =>
          'IMAP IDLE on Wi‑Fi (and cellular when allowed). '
          'Microsoft/Google accounts sync on reconnect and wake.',
      };
}

/// Default interval when [AndroidSyncMode.interval] is selected.
const int kSyncIntervalMinutesDefault = 15;

/// Minimum interval slider step (DEF-086 battery guard).
const int kSyncIntervalMinutesMin = 5;

/// Maximum interval slider step.
const int kSyncIntervalMinutesMax = 120;
