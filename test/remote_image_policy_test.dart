// ==============================================================================
// File: test/remote_image_policy_test.dart
// Description: Pure-function tests for remote HTML image blocking/rewriting
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/ui/shell/remote_image_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isRemoteImageUrl', () {
    test('treats http https and protocol-relative as remote', () {
      expect(isRemoteImageUrl('https://cdn.example/a.png'), isTrue);
      expect(isRemoteImageUrl('http://cdn.example/a.png'), isTrue);
      expect(isRemoteImageUrl('//cdn.example/a.png'), isTrue);
    });

    test('allows cid and data inline', () {
      expect(isRemoteImageUrl('cid:part1'), isFalse);
      expect(
        isRemoteImageUrl('data:image/png;base64,abc'),
        isFalse,
      );
    });

    test('ignores empty and relative paths', () {
      expect(isRemoteImageUrl(''), isFalse);
      expect(isRemoteImageUrl('/local/icon.png'), isFalse);
      expect(isRemoteImageUrl('images/foo.png'), isFalse);
    });
  });

  group('htmlHasRemoteImages', () {
    test('detects remote img src', () {
      expect(
        htmlHasRemoteImages('<img src="https://x.test/a.png">'),
        isTrue,
      );
    });

    test('detects remote css url', () {
      expect(
        htmlHasRemoteImages(
          '<div style="background:url(https://x.test/b.png)"></div>',
        ),
        isTrue,
      );
    });

    test('ignores cid and data', () {
      expect(
        htmlHasRemoteImages(
          '<img src="cid:img1"><img src="data:image/gif;base64,xx">',
        ),
        isFalse,
      );
    });
  });

  group('applyRemoteImagePolicy', () {
    test('passes through when not blocking', () {
      const String html = '<img src="https://x.test/a.png">';
      final RemoteImagePolicyResult result = applyRemoteImagePolicy(
        html,
        blockRemoteImages: false,
      );
      expect(result.html, html);
      expect(result.blockedRemoteImages, isFalse);
    });

    test('rewrites remote img src to placeholder', () {
      const String html =
          '<p><img src="https://track.example/pixel.gif" alt="x"></p>';
      final RemoteImagePolicyResult result = applyRemoteImagePolicy(
        html,
        blockRemoteImages: true,
      );
      expect(result.blockedRemoteImages, isTrue);
      expect(result.html, contains(kBlockedRemoteImagePlaceholder));
      expect(result.html, isNot(contains('https://track.example')));
    });

    test('preserves cid and data img src while blocking remote', () {
      const String html =
          '<img src="cid:logo"><img src="https://evil.test/x.png">'
          '<img src="data:image/png;base64,abc">';
      final RemoteImagePolicyResult result = applyRemoteImagePolicy(
        html,
        blockRemoteImages: true,
      );
      expect(result.blockedRemoteImages, isTrue);
      expect(result.html, contains('cid:logo'));
      expect(result.html, contains('data:image/png;base64,abc'));
      expect(result.html, isNot(contains('https://evil.test')));
    });

    test('rewrites remote css url to none', () {
      const String html =
          '<div style="background-image: url(\'https://x.test/bg.png\')"></div>';
      final RemoteImagePolicyResult result = applyRemoteImagePolicy(
        html,
        blockRemoteImages: true,
      );
      expect(result.blockedRemoteImages, isTrue);
      expect(result.html, contains('none'));
      expect(result.html, isNot(contains('https://x.test')));
    });

    test('handles single-quoted and unquoted img src', () {
      const String html =
          "<img src='http://a.test/1.png'><img src=https://b.test/2.png>";
      final RemoteImagePolicyResult result = applyRemoteImagePolicy(
        html,
        blockRemoteImages: true,
      );
      expect(result.blockedRemoteImages, isTrue);
      expect(result.html, isNot(contains('http://a.test')));
      expect(result.html, isNot(contains('https://b.test')));
      expect(
        'https://'.allMatches(result.html).length,
        0,
      );
    });

    test('returns blockedRemoteImages false when no remotes present', () {
      const String html = '<p>Hello <img src="cid:inline"></p>';
      final RemoteImagePolicyResult result = applyRemoteImagePolicy(
        html,
        blockRemoteImages: true,
      );
      expect(result.blockedRemoteImages, isFalse);
      expect(result.html, html);
    });
  });
}
