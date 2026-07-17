// ==============================================================================
// File: lib/sync/network_sync_policy.dart
// Description: Connectivity-aware poll and push gating for SyncEngine / IDLE.
// Component: Sync
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:connectivity_plus/connectivity_plus.dart';

/// Decides whether poll sync and push/IDLE are allowed for the current network.
///
/// Product rules:
/// - Poll when any non-none connectivity is present.
/// - Desktop push/IDLE whenever online.
/// - Mobile push/IDLE on Wi‑Fi/ethernet/VPN, or on cellular when
///   [pushOnCellular] is opted in (default off).
class NetworkSyncPolicy {
  const NetworkSyncPolicy({this.isDesktop = false});

  /// True on Windows / macOS / Linux — IDLE is always allowed when online.
  final bool isDesktop;

  /// True when at least one interface reports connectivity.
  bool allowPoll(List<ConnectivityResult> results) {
    if (results.isEmpty) {
      return false;
    }
    return results.any(
      (ConnectivityResult result) => result != ConnectivityResult.none,
    );
  }

  /// True when near-push / IMAP IDLE may run.
  bool allowPush(
    List<ConnectivityResult> results, {
    required bool pushOnCellular,
  }) {
    if (!allowPoll(results)) {
      return false;
    }
    if (isDesktop) {
      return true;
    }
    if (_hasUnmeteredLike(results)) {
      return true;
    }
    if (results.contains(ConnectivityResult.mobile)) {
      return pushOnCellular;
    }
    // Bluetooth / other: treat as metered — require cellular opt-in.
    return pushOnCellular;
  }

  bool _hasUnmeteredLike(List<ConnectivityResult> results) {
    return results.any(
      (ConnectivityResult result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet ||
          result == ConnectivityResult.vpn,
    );
  }
}
