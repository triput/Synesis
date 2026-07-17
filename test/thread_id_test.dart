// ==============================================================================
// File: test/thread_id_test.dart
// Description: Unit tests for resolveThreadId preference order and normalization.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/protocol/thread_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('resolveThreadId', () {
    test('prefers conversationId over References and Message-ID', () {
      expect(
        resolveThreadId(
          conversationId: 'conv-abc',
          messageId: '<root@x>',
          inReplyTo: '<parent@x>',
          references: '<root@x> <parent@x>',
          fallbackProviderId: '99',
        ),
        'conv-abc',
      );
    });

    test('uses root of References chain when no conversationId', () {
      expect(
        resolveThreadId(
          references: '<root@mail> <mid@mail> <leaf@mail>',
          inReplyTo: '<mid@mail>',
          messageId: '<leaf@mail>',
          fallbackProviderId: '1',
        ),
        'root@mail',
      );
    });

    test('falls back to In-Reply-To then Message-ID then providerId', () {
      expect(
        resolveThreadId(
          inReplyTo: '<parent@byte.io>',
          messageId: '<child@byte.io>',
          fallbackProviderId: '42',
        ),
        'parent@byte.io',
      );
      expect(
        resolveThreadId(
          messageId: '<solo@byte.io>',
          fallbackProviderId: '42',
        ),
        'solo@byte.io',
      );
      expect(
        resolveThreadId(fallbackProviderId: '42'),
        '42',
      );
    });

    test('normalizes angle brackets and lowercases', () {
      expect(
        resolveThreadId(conversationId: '<Conv-ABC>'),
        'conv-abc',
      );
      expect(
        resolveThreadId(messageId: '  <Foo@Bar.IO>  '),
        'foo@bar.io',
      );
    });

    test('returns null when nothing usable is provided', () {
      expect(resolveThreadId(), isNull);
      expect(resolveThreadId(conversationId: '   '), isNull);
      expect(resolveThreadId(fallbackProviderId: ''), isNull);
    });

    test('parses bare tokens in References without angle brackets', () {
      expect(
        resolveThreadId(references: 'root@x mid@x'),
        'root@x',
      );
    });
  });
}
