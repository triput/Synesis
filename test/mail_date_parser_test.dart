// ==============================================================================
// File: test/mail_date_parser_test.dart
// Description: Unit tests for tolerant mail Date header parsing.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/protocol/mail_date_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseMailDate', () {
    test('parses asctime UTC forms that enough_mail rejects', () {
      final DateTime? parsed = parseMailDate(
        'Tue Aug 20 15:10:06 UTC 2019',
      );
      expect(parsed, isNotNull);
      expect(parsed!.isUtc, isTrue);
      expect(parsed.year, 2019);
      expect(parsed.month, 8);
      expect(parsed.day, 20);
      expect(parsed.hour, 15);
      expect(parsed.minute, 10);
      expect(parsed.second, 6);
    });

    test('parses RFC 5322 with numeric zone', () {
      final DateTime? parsed = parseMailDate(
        'Tue, 20 Aug 2019 15:10:06 +0000',
      );
      expect(parsed, DateTime.utc(2019, 8, 20, 15, 10, 6));
    });

    test('parses ISO-8601', () {
      expect(
        parseMailDate('2019-08-20T15:10:06Z'),
        DateTime.utc(2019, 8, 20, 15, 10, 6),
      );
    });

    test('returns null for empty input', () {
      expect(parseMailDate(null), isNull);
      expect(parseMailDate(''), isNull);
      expect(parseMailDate('   '), isNull);
    });
  });
}
