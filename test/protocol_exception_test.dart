// ==============================================================================
// File: test/protocol_exception_test.dart
// Description: Unit tests for ProtocolException cause-preserving toString.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/protocol/mail_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProtocolException.toString', () {
    test('includes message without cause', () {
      const ProtocolException error = ProtocolException(
        'Unable to list recent IMAP messages.',
      );
      expect(
        error.toString(),
        'ProtocolException: Unable to list recent IMAP messages.',
      );
    });

    test('includes cause when present', () {
      final ProtocolException error = ProtocolException(
        'Unable to list recent IMAP messages.',
        cause: Exception('BAD Invalid messageset'),
      );
      final String text = error.toString();
      expect(text, startsWith('ProtocolException: Unable to list recent IMAP messages.'));
      expect(text, contains('Cause:'));
      expect(text, contains('BAD Invalid messageset'));
    });

    test('includes statusCode and cause', () {
      final ProtocolException error = ProtocolException(
        'Graph request failed',
        statusCode: 401,
        cause: Exception('Unauthorized'),
      );
      expect(error.toString(), contains('ProtocolException(401): Graph request failed'));
      expect(error.toString(), contains('Cause: Exception: Unauthorized'));
    });
  });
}
