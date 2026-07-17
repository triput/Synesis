// ==============================================================================
// File: test/imap_folder_role_mapping_test.dart
// Description: Unit tests for IMAP mailbox special-use role mapping.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/protocol/imap_smtp_mail_provider.dart';
import 'package:enough_mail/enough_mail.dart';
import 'package:flutter_test/flutter_test.dart';

Mailbox _mailbox({
  required String name,
  required List<MailboxFlag> flags,
  String? path,
  String pathSeparator = '/',
}) {
  final String resolvedPath = path ?? name;
  return Mailbox(
    encodedName: name,
    encodedPath: resolvedPath,
    flags: flags,
    pathSeparator: pathSeparator,
  );
}

void main() {
  group('imapMailboxRole', () {
    test('maps special-use flags to canonical roles', () {
      expect(
        imapMailboxRole(_mailbox(name: 'INBOX', flags: <MailboxFlag>[MailboxFlag.inbox])),
        'inbox',
      );
      expect(
        imapMailboxRole(_mailbox(name: 'Trash', flags: <MailboxFlag>[MailboxFlag.trash])),
        'trash',
      );
      expect(
        imapMailboxRole(_mailbox(name: 'Junk', flags: <MailboxFlag>[MailboxFlag.junk])),
        'junk',
      );
      expect(
        imapMailboxRole(
          _mailbox(name: 'Archive', flags: <MailboxFlag>[MailboxFlag.archive]),
        ),
        'archive',
      );
      expect(
        imapMailboxRole(_mailbox(name: 'Sent', flags: <MailboxFlag>[MailboxFlag.sent])),
        'sentitems',
      );
      expect(
        imapMailboxRole(
          _mailbox(name: 'Drafts', flags: <MailboxFlag>[MailboxFlag.drafts]),
        ),
        'drafts',
      );
      expect(
        imapMailboxRole(_mailbox(name: 'Projects', flags: <MailboxFlag>[])),
        isNull,
      );
    });
  });

  group('imapMailboxParentProviderId', () {
    test('returns parent path for nested mailboxes', () {
      expect(
        imapMailboxParentProviderId(
          _mailbox(
            name: 'Trash',
            path: 'INBOX/Trash',
            flags: <MailboxFlag>[MailboxFlag.trash],
          ),
        ),
        'INBOX',
      );
      expect(
        imapMailboxParentProviderId(
          _mailbox(name: 'INBOX', flags: <MailboxFlag>[MailboxFlag.inbox]),
        ),
        isNull,
      );
    });
  });
}
