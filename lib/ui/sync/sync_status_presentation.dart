// ==============================================================================
// File: lib/ui/sync/sync_status_presentation.dart
// Description: Unified idle/syncing/error labels for Wave 6P UI-P11 polish
// Component: UI / Sync
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'package:synesis/sync/sync_activity.dart';

/// Composes human-readable sync chrome from [SyncActivitySnapshot] and the
/// repository-derived health label (Wave 6P — UI-P11).
class SyncStatusPresentation {
  const SyncStatusPresentation._();

  /// Title bar / sidebar pill when remote sync is active.
  static String syncingLabel(SyncActivitySnapshot activity) {
    final int jobs = activity.activeJobCount;
    if (jobs <= 0) {
      return 'Syncing';
    }
    if (jobs == 1) {
      return 'Syncing (1 job)';
    }
    return 'Syncing ($jobs jobs)';
  }

  /// Primary status label: remote activity overrides idle repository text.
  static String composeLabel({
    required SyncActivitySnapshot activity,
    required String repositoryLabel,
  }) {
    if (activity.isRemoteSyncInFlight) {
      return syncingLabel(activity);
    }
    return repositoryLabel;
  }

  /// Coral / warning styling for pills and compact chrome.
  static bool needsAttention(String label) {
    final String lower = label.toLowerCase();
    return lower.contains('failed') ||
        lower.contains('needs attention') ||
        lower.contains('waiting to send') ||
        lower.contains('incomplete');
  }

  /// Short subtitle for drawer folder tile while sync is active.
  static String? activeSyncSubtitle({
    required SyncActivitySnapshot activity,
    required String repositoryLabel,
  }) {
    if (!activity.isRemoteSyncInFlight) {
      return null;
    }
    if (repositoryLabel.toLowerCase().contains('folder list')) {
      return 'Folder list incomplete — open Sync status';
    }
    return syncingLabel(activity);
  }

  /// One-line summary for the sync status sheet header.
  static String sheetSummary({
    required SyncActivitySnapshot activity,
    required String repositoryLabel,
  }) {
    if (activity.isRemoteSyncInFlight) {
      return syncingLabel(activity);
    }
    return repositoryLabel;
  }
}
