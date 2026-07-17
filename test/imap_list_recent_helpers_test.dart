// ==============================================================================
// File: test/imap_list_recent_helpers_test.dart
// Description: Unit tests for IMAP empty-folder and reconnect classification.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/protocol/imap_smtp_mail_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('imapShouldSkipRecentFetch', () {
    test('skips when mailbox is empty', () {
      expect(imapShouldSkipRecentFetch(0), isTrue);
    });

    test('does not skip when messages exist', () {
      expect(imapShouldSkipRecentFetch(1), isFalse);
      expect(imapShouldSkipRecentFetch(50), isFalse);
    });
  });

  group('imapIsInvalidMessagesetError', () {
    test('detects enough_mail empty FETCH failure', () {
      expect(
        imapIsInvalidMessagesetError(
          Exception('BAD Error in IMAP command FETCH: Invalid messageset'),
        ),
        isTrue,
      );
    });

    test('ignores unrelated errors', () {
      expect(
        imapIsInvalidMessagesetError(Exception('Connection refused')),
        isFalse,
      );
    });
  });

  group('imapIsConnectionLostError', () {
    test('detects socket and timeout failures', () {
      expect(
        imapIsConnectionLostError(Exception('SocketException: Connection reset')),
        isTrue,
      );
      expect(
        imapIsConnectionLostError(Exception('ImapException: timed out')),
        isTrue,
      );
      expect(
        imapIsConnectionLostError(Exception('connection lost')),
        isTrue,
      );
    });

    test('does not treat auth failures as connection lost', () {
      expect(
        imapIsConnectionLostError(Exception('Authentication failed')),
        isFalse,
      );
      expect(
        imapIsAuthFailure(Exception('login failed')),
        isTrue,
      );
    });
  });
}
