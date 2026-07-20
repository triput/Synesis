// ==============================================================================
// File: test/schema_v5_test.dart
// Description: Drift schema v5 migration, seed, wipe, and upsert preservation.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-16
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/database.dart' hide FocusRule;
import 'package:bytemail/repository/drift_mail_repository.dart';
import 'package:drift/drift.dart' show QueryRow, Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ByteMailDatabase> _openMemoryDb() async {
  final ByteMailDatabase database = ByteMailDatabase(NativeDatabase.memory());
  // Force migration / onCreate before assertions.
  await database.customSelect('SELECT 1').get();
  return database;
}

void main() {
  group('schema v5', () {
    test(
      'fresh database is schema version 6 with new tables and columns',
      () async {
        final ByteMailDatabase database = await _openMemoryDb();
        addTearDown(database.close);

        final int userVersion =
            (await database.customSelect('PRAGMA user_version').getSingle())
                .read<int>('user_version');
        expect(userVersion, 6);

        final List<String> tableNames =
            (await database
                    .customSelect(
                      "SELECT name FROM sqlite_master WHERE type = 'table' "
                      "ORDER BY name",
                    )
                    .get())
                .map((QueryRow row) => row.read<String>('name'))
                .toList(growable: false);

        expect(
          tableNames,
          containsAll(<String>[
            'sync_profiles',
            'attachments',
            'attachment_blobs',
            'account_signatures',
            'account_signature_assets',
            'message_templates',
            'custom_themes',
          ]),
        );

        final Set<String> messageColumns =
            (await database.customSelect('PRAGMA table_info(messages)').get())
                .map((QueryRow row) => row.read<String>('name'))
                .toSet();
        expect(
          messageColumns,
          containsAll(<String>[
            'starred',
            'thread_id',
            'snoozed_until',
            'trashed_at',
            'is_draft',
            'draft_sync_provider_id',
            'to_recipients',
            'cc_recipients',
          ]),
        );

        final Set<String> accountColumns =
            (await database.customSelect('PRAGMA table_info(accounts)').get())
                .map((QueryRow row) => row.read<String>('name'))
                .toSet();
        expect(
          accountColumns,
          containsAll(<String>['sync_profile_id', 'retention_days_override']),
        );

        final Set<String> outboxColumns =
            (await database.customSelect('PRAGMA table_info(outbox)').get())
                .map((QueryRow row) => row.read<String>('name'))
                .toSet();
        expect(
          outboxColumns,
          containsAll(<String>[
            'cc_json',
            'bcc_json',
            'compose_mode',
            'in_reply_to',
            'references_json',
            'attachment_refs_json',
            'signature_id',
            'send_after',
          ]),
        );
      },
    );

    test('seeds default sync profile on create', () async {
      final ByteMailDatabase database = await _openMemoryDb();
      addTearDown(database.close);

      final QueryRow row = await database
          .customSelect(
            "SELECT id, name, retention_days, body_policy, "
            'attachment_max_mb, is_default FROM sync_profiles '
            "WHERE id = 'default'",
          )
          .getSingle();
      expect(row.read<String>('id'), 'default');
      expect(row.read<String>('name'), 'Default');
      expect(row.read<int>('retention_days'), 180);
      expect(row.read<String>('body_policy'), 'on_open');
      expect(row.read<int>('attachment_max_mb'), 25);
      expect(row.read<int>('is_default'), 1);
    });

    test(
      'wipeAccount removes attachments and signatures for that account',
      () async {
        final ByteMailDatabase database = await _openMemoryDb();
        final DriftMailRepository repo = DriftMailRepository(database);
        addTearDown(repo.close);

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
            folderId: 'inbox-work',
            providerId: '101',
          ),
        ], folderId: 'inbox-work');

        await database
            .into(database.attachments)
            .insert(
              AttachmentsCompanion.insert(
                id: 'att-1',
                messageId: 'msg-1',
                accountId: 'work',
                filename: 'doc.pdf',
                mimeType: 'application/pdf',
                sizeBytes: 128,
              ),
            );
        await database
            .into(database.attachmentBlobs)
            .insert(
              AttachmentBlobsCompanion.insert(
                id: 'blob-1',
                accountId: 'work',
                path: '/tmp/blob-1',
                sizeBytes: 128,
                createdAt: 1,
              ),
            );
        await database
            .into(database.accountSignatures)
            .insert(
              AccountSignaturesCompanion.insert(
                id: 'sig-1',
                accountId: 'work',
                name: 'Work',
                bodyPlain: 'Thanks',
              ),
            );
        await database
            .into(database.accountSignatureAssets)
            .insert(
              AccountSignatureAssetsCompanion.insert(
                id: 'sig-asset-1',
                signatureId: 'sig-1',
                localPath: '/tmp/logo.png',
                contentId: 'logo',
                mimeType: 'image/png',
              ),
            );
        await database
            .into(database.messageTemplates)
            .insert(
              MessageTemplatesCompanion.insert(
                id: 'tpl-1',
                accountId: const Value<String?>('work'),
                name: 'Hello',
                subject: 'Hi',
                bodyHtml: '<p>Hi</p>',
              ),
            );
        await database
            .into(database.customThemes)
            .insert(
              CustomThemesCompanion.insert(
                id: 'theme-1',
                name: 'Custom',
                baseThemeId: 'dark',
                tokenOverridesJson: '{}',
              ),
            );

        await repo.wipeAccount('work');

        expect(
          await database
              .customSelect('SELECT COUNT(*) AS c FROM attachments')
              .map((QueryRow row) => row.read<int>('c'))
              .getSingle(),
          0,
        );
        expect(
          await database
              .customSelect('SELECT COUNT(*) AS c FROM attachment_blobs')
              .map((QueryRow row) => row.read<int>('c'))
              .getSingle(),
          0,
        );
        expect(
          await database
              .customSelect('SELECT COUNT(*) AS c FROM account_signatures')
              .map((QueryRow row) => row.read<int>('c'))
              .getSingle(),
          0,
        );
        expect(
          await database
              .customSelect(
                'SELECT COUNT(*) AS c FROM account_signature_assets',
              )
              .map((QueryRow row) => row.read<int>('c'))
              .getSingle(),
          0,
        );
        expect(
          await database
              .customSelect('SELECT COUNT(*) AS c FROM message_templates')
              .map((QueryRow row) => row.read<int>('c'))
              .getSingle(),
          0,
        );
        expect(
          await database
              .customSelect("SELECT COUNT(*) AS c FROM sync_profiles")
              .map((QueryRow row) => row.read<int>('c'))
              .getSingle(),
          1,
        );
        expect(
          await database
              .customSelect('SELECT COUNT(*) AS c FROM custom_themes')
              .map((QueryRow row) => row.read<int>('c'))
              .getSingle(),
          1,
        );
      },
    );

    test('upsert preserves starred and snoozedUntil on header sync', () async {
      final ByteMailDatabase database = await _openMemoryDb();
      final DriftMailRepository repo = DriftMailRepository(database);
      addTearDown(repo.close);

      await repo.upsertAccount(
        const MailAccount(
          id: 'work',
          label: 'W',
          address: 'work@byte.io',
          accent: Color(0xFF2DD4BF),
        ),
        providerType: 'imap',
      );
      await repo.upsertMessages(const <MailMessage>[
        MailMessage(
          id: 'msg-1',
          accountId: 'work',
          fromName: 'A',
          fromAddress: 'a@byte.io',
          subject: 'One',
          snippet: 's1',
          body: 'full body',
          whenLabel: '10:00',
          bucket: FocusBucket.focused,
          folderId: 'inbox-work',
          providerId: '101',
          whenEpochMs: 1000,
        ),
      ], folderId: 'inbox-work');

      const int snoozeEpoch = 9_999_999;
      await repo.setStarred('msg-1', true);
      await (database.update(
        database.messages,
      )..where((Messages table) => table.id.equals('msg-1'))).write(
        const MessagesCompanion(
          snoozedUntil: Value<int?>(snoozeEpoch),
          pinned: Value<bool>(true),
        ),
      );

      await repo.upsertMessages(const <MailMessage>[
        MailMessage(
          id: 'msg-1',
          accountId: 'work',
          fromName: 'A',
          fromAddress: 'a@byte.io',
          subject: 'One updated',
          snippet: 's1',
          body: 's1',
          whenLabel: '10:00',
          bucket: FocusBucket.focused,
          folderId: 'inbox-work',
          providerId: '101',
          whenEpochMs: 2000,
          starred: false,
          pinned: false,
          snoozedUntil: null,
        ),
      ], folderId: 'inbox-work');

      final MailMessage? message = await repo.getMessage('msg-1');
      expect(message?.subject, 'One updated');
      expect(message?.starred, isTrue);
      expect(message?.pinned, isTrue);
      expect(message?.snoozedUntil, snoozeEpoch);
      expect(message?.body, 'full body');
    });
  });
}
