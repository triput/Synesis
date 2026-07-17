// ==============================================================================
// File: test/send_error_messages_test.dart
// Description: Unit tests for actionable SMTP/send error copy.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/outbox/send_error_messages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('actionableSendError', () {
    test('maps auth failures to credential guidance', () {
      final String message = actionableSendError(
        'ProtocolException: Authentication failed 535',
        accountHint: 'you@example.com',
      );
      expect(message, contains('could not sign in to SMTP'));
      expect(message, contains('you@example.com'));
      expect(message, contains('password'));
    });

    test('maps ProtocolException with nested auth cause', () {
      final String message = actionableSendError(
        'ProtocolException: Unable to send SMTP mail. '
        'Cause: SmtpException: Authentication failed 535',
        accountHint: 'you@example.com',
      );
      expect(message, contains('could not sign in to SMTP'));
      expect(message, contains('you@example.com'));
    });

    test('maps socket failures to host/port guidance', () {
      final String message = actionableSendError(
        'SocketException: Connection refused',
      );
      expect(message, contains('could not reach the SMTP server'));
      expect(message, contains('SMTP host and port'));
    });

    test('does not double-wrap already actionable text', () {
      const String prior =
          'Send failed: could not sign in to SMTP for a@b.com. Update the password.';
      expect(actionableSendError(prior), prior);
    });

    test('empty input still returns guidance', () {
      expect(actionableSendError(null), contains('Check your account settings'));
    });
  });
}
