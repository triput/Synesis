// ==============================================================================
// File: test/send_error_messages_test.dart
// Description: Unit tests for actionable SMTP/send error copy.
// Component: Test
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-24
// ==============================================================================

import 'package:synesis/outbox/send_error_messages.dart';
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

    // DEF-047: Gmail/Workspace "Sender address rejected: not owned by user"
    // carries a 553 code, which previously fell into the recipient bucket
    // and told the user to "check To/Cc" even though the To/Cc list was
    // fine and the real problem was the From address.
    test('maps sender-address rejection to a From-address message, not '
        'recipient guidance', () {
      final String message = actionableSendError(
        'ProtocolException: Unable to send SMTP mail. '
        'Cause: SmtpException: 553 5.7.1 <trish@trishputnam.com>... '
        'Sender address rejected: not owned by user',
        accountHint: 'trish@trishputnam.com',
      );
      expect(message, contains('rejected the From address'));
      expect(message, isNot(contains('recipient address')));
      expect(message, contains('Send mail as'));
    });

    test('maps DMARC/SPF sender-policy failures to From-address guidance',
        () {
      final String message = actionableSendError(
        '554 5.7.1 Unauthenticated email is not accepted due to '
        "domain's DMARC policy",
      );
      expect(message, contains('rejected the From address'));
      expect(message, isNot(contains('recipient address')));
    });

    test('maps a genuine recipient rejection and includes raw server detail',
        () {
      final String message = actionableSendError(
        'ProtocolException: Unable to send SMTP mail. '
        'Cause: SmtpException: 550 5.1.1 The email account that you '
        'tried to reach does not exist.',
      );
      expect(message, contains('the server rejected a recipient address'));
      expect(message, contains('Server said:'));
      expect(message, contains('does not exist'));
    });

    // DEF-048: enough_mail client guard must not look like a real RCPT fail.
    test('maps client-side 500 no recipients away from check-To/Cc copy', () {
      final String message = actionableSendError(
        'SmtpException: 500 no recipients',
      );
      expect(message, contains('no SMTP recipients after build'));
      expect(message, isNot(contains('Check To/Cc')));
      expect(message, contains('Server said:'));
    });
  });
}
