// ==============================================================================
// File: test/message_body_find_test.dart
// Description: Unit tests for in-message find match helpers
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/ui/shell/message_body_find.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findTextMatches', () {
    test('finds case-insensitive non-overlapping matches', () {
      final List<TextMatchRange> matches = findTextMatches(
        'Alpha beta ALPHA gamma',
        'alpha',
      );
      expect(matches.length, 2);
      expect(matches[0].start, 0);
      expect(matches[0].end, 5);
      expect(matches[1].start, 11);
      expect(matches[1].end, 16);
    });

    test('returns empty for blank needle', () {
      expect(findTextMatches('hello', '   '), isEmpty);
      expect(findTextMatches('hello', ''), isEmpty);
    });
  });

  group('stripHtmlToPlainText', () {
    test('strips tags and decodes entities for counting', () {
      expect(
        stripHtmlToPlainText('<p>Hello&nbsp;<b>world</b></p>'),
        'Hello world',
      );
    });
  });

  group('wrapFindIndex', () {
    test('wraps forward and backward', () {
      expect(wrapFindIndex(3, 3), 0);
      expect(wrapFindIndex(-1, 3), 2);
      expect(wrapFindIndex(1, 0), 0);
    });
  });
}
