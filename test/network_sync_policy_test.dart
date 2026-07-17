// ==============================================================================
// File: test/network_sync_policy_test.dart
// Description: Unit tests for poll/push gating under connectivity + settings.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/sync/network_sync_policy.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NetworkSyncPolicy allowPoll', () {
    const NetworkSyncPolicy policy = NetworkSyncPolicy();

    test('denies empty and none', () {
      expect(policy.allowPoll(const <ConnectivityResult>[]), isFalse);
      expect(
        policy.allowPoll(const <ConnectivityResult>[ConnectivityResult.none]),
        isFalse,
      );
    });

    test('allows wifi, mobile, ethernet', () {
      expect(
        policy.allowPoll(const <ConnectivityResult>[ConnectivityResult.wifi]),
        isTrue,
      );
      expect(
        policy.allowPoll(const <ConnectivityResult>[ConnectivityResult.mobile]),
        isTrue,
      );
      expect(
        policy.allowPoll(
          const <ConnectivityResult>[ConnectivityResult.ethernet],
        ),
        isTrue,
      );
    });
  });

  group('NetworkSyncPolicy allowPush mobile', () {
    const NetworkSyncPolicy mobile = NetworkSyncPolicy(isDesktop: false);

    test('allows wifi without cellular opt-in', () {
      expect(
        mobile.allowPush(
          const <ConnectivityResult>[ConnectivityResult.wifi],
          pushOnCellular: false,
        ),
        isTrue,
      );
    });

    test('denies cellular when pushOnCellular is false', () {
      expect(
        mobile.allowPush(
          const <ConnectivityResult>[ConnectivityResult.mobile],
          pushOnCellular: false,
        ),
        isFalse,
      );
    });

    test('allows cellular when pushOnCellular is true', () {
      expect(
        mobile.allowPush(
          const <ConnectivityResult>[ConnectivityResult.mobile],
          pushOnCellular: true,
        ),
        isTrue,
      );
    });

    test('denies when offline', () {
      expect(
        mobile.allowPush(
          const <ConnectivityResult>[ConnectivityResult.none],
          pushOnCellular: true,
        ),
        isFalse,
      );
    });
  });

  group('NetworkSyncPolicy allowPush desktop', () {
    const NetworkSyncPolicy desktop = NetworkSyncPolicy(isDesktop: true);

    test('allows any online interface regardless of cellular flag', () {
      expect(
        desktop.allowPush(
          const <ConnectivityResult>[ConnectivityResult.wifi],
          pushOnCellular: false,
        ),
        isTrue,
      );
      expect(
        desktop.allowPush(
          const <ConnectivityResult>[ConnectivityResult.mobile],
          pushOnCellular: false,
        ),
        isTrue,
      );
      expect(
        desktop.allowPush(
          const <ConnectivityResult>[ConnectivityResult.ethernet],
          pushOnCellular: false,
        ),
        isTrue,
      );
    });
  });
}
