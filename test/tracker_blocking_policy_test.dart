// ==============================================================================
// File: test/tracker_blocking_policy_test.dart
// Description: Pure-function tests for D6-7 ESP/analytics tracker stripping
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-07-23
// ==============================================================================

import 'package:synesis/ui/shell/tracker_blocking_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isTrackerUrl', () {
    test('detects known ESP denylist hosts', () {
      expect(
        isTrackerUrl('https://track.hubspot.com/open.gif?id=1'),
        isTrue,
      );
      expect(
        isTrackerUrl('https://x.list-manage.com/track/click'),
        isTrue,
      );
    });

    test('detects common open-track path patterns regardless of host', () {
      expect(
        isTrackerUrl('https://mail.example.com/wf/open?upn=abc'),
        isTrue,
      );
      expect(
        isTrackerUrl('https://mail.example.com/api/track/foo'),
        isTrue,
      );
    });

    test('does not flag ordinary content images', () {
      expect(isTrackerUrl('https://cdn.example.com/logo.png'), isFalse);
    });

    test('never flags inline cid/data resources', () {
      expect(isTrackerUrl('cid:logo'), isFalse);
      expect(isTrackerUrl('data:image/gif;base64,abc'), isFalse);
    });
  });

  group('applyTrackerBlockingPolicy', () {
    test('passes through unchanged when blockTrackers is false', () {
      const String html =
          '<img src="https://track.hubspot.com/open.gif">';
      final TrackerBlockingPolicyResult result = applyTrackerBlockingPolicy(
        html,
        blockTrackers: false,
      );
      expect(result.html, html);
      expect(result.blockedTrackers, isFalse);
    });

    test('strips known tracker img src to placeholder', () {
      const String html =
          '<p><img src="https://track.hubspot.com/open.gif" alt=""></p>';
      final TrackerBlockingPolicyResult result = applyTrackerBlockingPolicy(
        html,
        blockTrackers: true,
      );
      expect(result.blockedTrackers, isTrue);
      expect(result.html, isNot(contains('track.hubspot.com')));
    });

    test('leaves ordinary remote content images untouched', () {
      const String html = '<img src="https://cdn.example.com/photo.jpg">';
      final TrackerBlockingPolicyResult result = applyTrackerBlockingPolicy(
        html,
        blockTrackers: true,
      );
      expect(result.blockedTrackers, isFalse);
      expect(result.html, html);
    });

    test('strips tracker from css url()', () {
      const String html =
          '<div style="background:url(https://track.hubspot.com/open.gif)">'
          '</div>';
      final TrackerBlockingPolicyResult result = applyTrackerBlockingPolicy(
        html,
        blockTrackers: true,
      );
      expect(result.blockedTrackers, isTrue);
      expect(result.html, contains('none'));
      expect(result.html, isNot(contains('track.hubspot.com')));
    });

    test('strips tracker candidates from srcset', () {
      const String html =
          '<img src="https://cdn.example.com/x.png" '
          'srcset="https://track.hubspot.com/open.gif 1x">';
      final TrackerBlockingPolicyResult result = applyTrackerBlockingPolicy(
        html,
        blockTrackers: true,
      );
      expect(result.blockedTrackers, isTrue);
      expect(result.html, isNot(contains('track.hubspot.com')));
      expect(result.html, contains('https://cdn.example.com/x.png'));
    });

    test('D6-2 allowlisted host skips tracker strip', () {
      const String html =
          '<img src="https://track.hubspot.com/open.gif">';
      final TrackerBlockingPolicyResult result = applyTrackerBlockingPolicy(
        html,
        blockTrackers: true,
        allowlistDomains: <String>['hubspot.com'],
      );
      expect(result.blockedTrackers, isFalse);
      expect(result.html, html);
    });
  });

  group('htmlHasTrackers', () {
    test('true when a known tracker resource is present', () {
      expect(
        htmlHasTrackers('<img src="https://track.hubspot.com/open.gif">'),
        isTrue,
      );
    });

    test('false for ordinary content images', () {
      expect(
        htmlHasTrackers('<img src="https://cdn.example.com/photo.jpg">'),
        isFalse,
      );
    });
  });
}
