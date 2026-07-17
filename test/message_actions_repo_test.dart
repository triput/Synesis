// ==============================================================================
// File: test/message_actions_repo_test.dart
// Description: Repository helpers for trash/junk/archive moves and hard delete.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/database.dart' hide FocusRule;
import 'package:bytemail/repository/drift_mail_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<DriftMailRepository> _openActionsRepo() async {
  final ByteMailDatabase database = ByteMailDatabase(NativeDatabase.memory());
  final DriftMailRepository repo = DriftMailRepository(database);
  await repo.upsertAccount(
    const MailAccount(
      id: 'work',
      label: 'W',
      address: 'work@byte.io',
      accent: Color(0xFF2DD4BF),
    ),
    providerType: 'imap',
  );
  await repo.upsertFolders(const <MailFolder>[
    MailFolder(
      id: 'inbox-work',
      accountId: 'work',
      name: 'Inbox',
      remoteId: 'INBOX',
      role: 'inbox',
      unreadCount: 1,
    ),
    MailFolder(
      id: 'trash-work',
      accountId: 'work',
      name: 'Deleted Items',
      remoteId: 'DeletedItems',
      role: 'deleteditems',
      unreadCount: 0,
    ),
    MailFolder(
      id: 'junk-work',
      accountId: 'work',
      name: 'Junk Email',
      remoteId: 'JunkEmail',
      role: 'junkemail',
      unreadCount: 0,
    ),
    MailFolder(
      id: 'archive-work',
      accountId: 'work',
      name: 'Archive',
      remoteId: 'Archive',
      role: 'archive',
      unreadCount: 0,
    ),
  ]);
  await repo.upsertMessages(const <MailMessage>[
    MailMessage(
      id: 'msg-1',
      accountId: 'work',
      fromName: 'A',
      fromAddress: 'a@byte.io',
      subject: 'One',
      snippet: 's1',
      body: 'b1',
      whenLabel: '10:00',
      bucket: FocusBucket.focused,
      unread: true,
      folderId: 'inbox-work',
      providerId: '101',
      whenEpochMs: 1_000,
    ),
  ], folderId: 'inbox-work');
  return repo;
}

void main() {
  group('DriftMailRepository.resolveFolderByRole', () {
    test('resolves trash aliases including deleteditems', () async {
      final DriftMailRepository repo = await _openActionsRepo();
      for (final String alias in <String>['trash', 'deleteditems', 'deleted']) {
        final MailFolder? folder = await repo.resolveFolderByRole(
          'work',
          alias,
        );
        expect(folder?.id, 'trash-work', reason: alias);
      }
    });

    test('resolves junk aliases including spam', () async {
      final DriftMailRepository repo = await _openActionsRepo();
      for (final String alias in <String>['junk', 'junkemail', 'spam']) {
        final MailFolder? folder = await repo.resolveFolderByRole(
          'work',
          alias,
        );
        expect(folder?.id, 'junk-work', reason: alias);
      }
    });

    test('resolves archive and inbox', () async {
      final DriftMailRepository repo = await _openActionsRepo();
      expect(
        (await repo.resolveFolderByRole('work', 'archive'))?.id,
        'archive-work',
      );
      expect(
        (await repo.resolveFolderByRole('work', 'inbox'))?.id,
        'inbox-work',
      );
    });

    test('falls back to folder name when role is empty', () async {
      final ByteMailDatabase database = ByteMailDatabase(
        NativeDatabase.memory(),
      );
      final DriftMailRepository repo = DriftMailRepository(database);
      await repo.upsertAccount(
        const MailAccount(
          id: 'personal',
          label: 'P',
          address: 'p@byte.io',
          accent: Color(0xFF2DD4BF),
        ),
        providerType: 'imap',
      );
      await repo.upsertFolders(const <MailFolder>[
        MailFolder(
          id: 'named-trash',
          accountId: 'personal',
          name: 'Trash',
          remoteId: 'Trash',
        ),
        MailFolder(
          id: 'named-spam',
          accountId: 'personal',
          name: 'Spam',
          remoteId: 'Spam',
        ),
      ]);
      expect(
        (await repo.resolveFolderByRole('personal', 'trash'))?.id,
        'named-trash',
      );
      expect(
        (await repo.resolveFolderByRole('personal', 'junk'))?.id,
        'named-spam',
      );
    });

    test('matches Outlook and Gmail display names when role is empty', () async {
      final ByteMailDatabase database = ByteMailDatabase(
        NativeDatabase.memory(),
      );
      final DriftMailRepository repo = DriftMailRepository(database);
      await repo.upsertAccount(
        const MailAccount(
          id: 'outlook',
          label: 'O',
          address: 'o@byte.io',
          accent: Color(0xFF2DD4BF),
        ),
        providerType: 'graph',
      );
      await repo.upsertFolders(const <MailFolder>[
        MailFolder(
          id: 'deleted-items',
          accountId: 'outlook',
          name: 'Deleted Items',
          remoteId: 'AAMkDeleted',
        ),
        MailFolder(
          id: 'junk-email',
          accountId: 'outlook',
          name: 'Junk Email',
          remoteId: 'AAMkJunk',
        ),
      ]);
      expect(
        (await repo.resolveFolderByRole('outlook', 'trash'))?.id,
        'deleted-items',
      );
      expect(
        (await repo.resolveFolderByRole('outlook', 'junk'))?.id,
        'junk-email',
      );

      await repo.upsertAccount(
        const MailAccount(
          id: 'gmail',
          label: 'G',
          address: 'g@byte.io',
          accent: Color(0xFF2DD4BF),
        ),
        providerType: 'imap',
      );
      await repo.upsertFolders(const <MailFolder>[
        MailFolder(
          id: 'gmail-trash',
          accountId: 'gmail',
          name: '[Gmail]/Trash',
          remoteId: '[Gmail]/Trash',
        ),
      ]);
      expect(
        (await repo.resolveFolderByRole('gmail', 'trash'))?.id,
        'gmail-trash',
      );
    });

    test('matches path suffixes like INBOX/Trash case-insensitively', () async {
      final ByteMailDatabase database = ByteMailDatabase(
        NativeDatabase.memory(),
      );
      final DriftMailRepository repo = DriftMailRepository(database);
      await repo.upsertAccount(
        const MailAccount(
          id: 'nested',
          label: 'N',
          address: 'n@byte.io',
          accent: Color(0xFF2DD4BF),
        ),
        providerType: 'imap',
      );
      await repo.upsertFolders(const <MailFolder>[
        MailFolder(
          id: 'path-trash',
          accountId: 'nested',
          name: 'Removed',
          remoteId: 'INBOX/Trash',
        ),
        MailFolder(
          id: 'path-junk',
          accountId: 'nested',
          name: 'Unwanted',
          remoteId: 'INBOX/Spam',
        ),
        MailFolder(
          id: 'path-archive',
          accountId: 'nested',
          name: 'Stored',
          remoteId: 'INBOX/Archive',
        ),
      ]);
      expect(
        (await repo.resolveFolderByRole('nested', 'trash'))?.id,
        'path-trash',
      );
      expect(
        (await repo.resolveFolderByRole('nested', 'junk'))?.id,
        'path-junk',
      );
      expect(
        (await repo.resolveFolderByRole('nested', 'archive'))?.id,
        'path-archive',
      );
    });
  });

  group('DriftMailRepository.moveMessageLocal', () {
    test('move to trash sets trashedAt; recover clears it', () async {
      final DriftMailRepository repo = await _openActionsRepo();
      const int trashedAt = 1_700_000_000_000;
      await repo.moveMessageLocal('msg-1', 'trash-work', trashedAt: trashedAt);
      MailMessage? message = await repo.getMessage('msg-1');
      expect(message?.folderId, 'trash-work');
      expect(message?.trashedAt, trashedAt);

      final MailFolder? inbox = await repo.getFolder('inbox-work');
      final MailFolder? trash = await repo.getFolder('trash-work');
      expect(inbox?.unreadCount, 0);
      // Trashed messages are excluded from unread badges.
      expect(trash?.unreadCount, 0);

      await repo.moveMessageLocal('msg-1', 'inbox-work', clearTrashedAt: true);
      message = await repo.getMessage('msg-1');
      expect(message?.folderId, 'inbox-work');
      expect(message?.trashedAt, isNull);
    });

    test(
      'upsertMessages preserves trashedAt after sync-shaped rewrite',
      () async {
        final DriftMailRepository repo = await _openActionsRepo();
        const int trashedAt = 42;
        await repo.moveMessageLocal(
          'msg-1',
          'trash-work',
          trashedAt: trashedAt,
        );
        await repo.upsertMessages(const <MailMessage>[
          MailMessage(
            id: 'msg-1',
            accountId: 'work',
            fromName: 'A',
            fromAddress: 'a@byte.io',
            subject: 'One sync',
            snippet: 's1',
            body: 's1',
            whenLabel: '10:00',
            bucket: FocusBucket.focused,
            unread: true,
            folderId: 'trash-work',
            providerId: '101',
            whenEpochMs: 2_000,
            trashedAt: null,
            starred: false,
          ),
        ], folderId: 'trash-work');
        final MailMessage? message = await repo.getMessage('msg-1');
        expect(message?.subject, 'One sync');
        expect(message?.trashedAt, trashedAt);
      },
    );
  });

  group('DriftMailRepository.hardDeleteLocal', () {
    test('removes message row', () async {
      final DriftMailRepository repo = await _openActionsRepo();
      await repo.hardDeleteLocal('msg-1');
      expect(await repo.getMessage('msg-1'), isNull);
      final MailFolder? inbox = await repo.getFolder('inbox-work');
      expect(inbox?.unreadCount, 0);
    });
  });

  group('DriftMailRepository.listTrashedPastRetention', () {
    test('includes boundary age and excludes fresher trash', () async {
      final DriftMailRepository repo = await _openActionsRepo();
      final DateTime now = DateTime.utc(2026, 7, 17, 12);
      final int exactlyThirtyDays = now
          .subtract(const Duration(days: 30))
          .millisecondsSinceEpoch;
      final int twentyNineDays = now
          .subtract(const Duration(days: 29))
          .millisecondsSinceEpoch;
      final int thirtyOneDays = now
          .subtract(const Duration(days: 31))
          .millisecondsSinceEpoch;

      await repo.upsertMessages(<MailMessage>[
        MailMessage(
          id: 'msg-boundary',
          accountId: 'work',
          fromName: 'B',
          fromAddress: 'b@byte.io',
          subject: 'Boundary',
          snippet: 's',
          body: 'b',
          whenLabel: '10:00',
          bucket: FocusBucket.focused,
          folderId: 'trash-work',
          providerId: '201',
          whenEpochMs: exactlyThirtyDays,
          trashedAt: exactlyThirtyDays,
        ),
        MailMessage(
          id: 'msg-fresh',
          accountId: 'work',
          fromName: 'C',
          fromAddress: 'c@byte.io',
          subject: 'Fresh',
          snippet: 's',
          body: 'b',
          whenLabel: '10:00',
          bucket: FocusBucket.focused,
          folderId: 'trash-work',
          providerId: '202',
          whenEpochMs: twentyNineDays,
          trashedAt: twentyNineDays,
        ),
        MailMessage(
          id: 'msg-old',
          accountId: 'work',
          fromName: 'D',
          fromAddress: 'd@byte.io',
          subject: 'Old',
          snippet: 's',
          body: 'b',
          whenLabel: '10:00',
          bucket: FocusBucket.focused,
          folderId: 'trash-work',
          providerId: '203',
          whenEpochMs: thirtyOneDays,
          trashedAt: thirtyOneDays,
        ),
      ], folderId: 'trash-work');

      final List<MailMessage> past = await repo.listTrashedPastRetention(
        retentionDays: 30,
        now: now,
      );
      final Set<String> ids = past
          .map((MailMessage message) => message.id)
          .toSet();
      expect(ids, containsAll(<String>['msg-boundary', 'msg-old']));
      expect(ids, isNot(contains('msg-fresh')));
      expect(ids, isNot(contains('msg-1')));
    });
  });

  group('DriftMailRepository pin and snooze', () {
    test('applyRetention skips pinned messages', () async {
      final DriftMailRepository repo = await _openActionsRepo();
      final int oldMs = DateTime.now()
          .subtract(const Duration(days: 40))
          .millisecondsSinceEpoch;
      await repo.upsertMessages(<MailMessage>[
        MailMessage(
          id: 'msg-old-pinned',
          accountId: 'work',
          fromName: 'P',
          fromAddress: 'p@byte.io',
          subject: 'Pinned old',
          snippet: 's',
          body: 'b',
          whenLabel: '10:00',
          bucket: FocusBucket.focused,
          folderId: 'inbox-work',
          providerId: 'pin-1',
          whenEpochMs: oldMs,
          pinned: true,
        ),
        MailMessage(
          id: 'msg-old-unpinned',
          accountId: 'work',
          fromName: 'U',
          fromAddress: 'u@byte.io',
          subject: 'Unpinned old',
          snippet: 's',
          body: 'b',
          whenLabel: '10:00',
          bucket: FocusBucket.focused,
          folderId: 'inbox-work',
          providerId: 'unpin-1',
          whenEpochMs: oldMs,
        ),
      ], folderId: 'inbox-work');

      final int removed = await repo.applyRetention(retentionDays: 30);
      expect(removed, greaterThanOrEqualTo(1));
      expect(await repo.getMessage('msg-old-pinned'), isNotNull);
      expect(await repo.getMessage('msg-old-unpinned'), isNull);
    });

    test('setSnoozed hides via excludeSnoozed and resurfaces after expiry', () async {
      final DriftMailRepository repo = await _openActionsRepo();
      final int future =
          DateTime.now().add(const Duration(hours: 3)).millisecondsSinceEpoch;

      await repo.setSnoozed('msg-1', future);
      final List<MailMessage> hidden = await repo.listMessages(
        MessageQuery.defaults.copyWith(excludeSnoozed: true),
      );
      expect(hidden.any((MailMessage m) => m.id == 'msg-1'), isFalse);

      final List<MailMessage> snoozedOnly = await repo.listMessages(
        MessageQuery.defaults.copyWith(snoozedOnly: true),
      );
      expect(snoozedOnly.map((MailMessage m) => m.id), <String>['msg-1']);

      expect(await repo.nextSnoozeExpiryMs(), future);

      await repo.setSnoozed('msg-1', 1);
      final int cleared = await repo.clearExpiredSnoozes();
      expect(cleared, greaterThanOrEqualTo(1));

      final List<MailMessage> visible = await repo.listMessages(
        MessageQuery.defaults.copyWith(excludeSnoozed: true),
      );
      expect(visible.any((MailMessage m) => m.id == 'msg-1'), isTrue);
      expect((await repo.getMessage('msg-1'))?.snoozedUntil, isNull);
    });

    test('upsert preserves snoozedUntil across restart-like rewrite', () async {
      final DriftMailRepository repo = await _openActionsRepo();
      final int until =
          DateTime.now().add(const Duration(days: 1)).millisecondsSinceEpoch;
      await repo.setSnoozed('msg-1', until);

      final MailMessage? existing = await repo.getMessage('msg-1');
      expect(existing, isNotNull);
      await repo.upsertMessages(<MailMessage>[
        existing!.copyWith(snippet: 'updated'),
      ], folderId: 'inbox-work');

      expect((await repo.getMessage('msg-1'))?.snoozedUntil, until);
    });
  });
}
