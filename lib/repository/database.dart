// ==============================================================================
// File: lib/repository/database.dart
// Description: Drift schema and application-support SQLite connection.
// Component: Data
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:bytemail/repository/db_encryption_config.dart';

part 'database.g.dart';

class Accounts extends Table {
  @override
  String get tableName => 'accounts';

  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get address => text()();
  IntColumn get accentArgb => integer()();
  TextColumn get providerType => text().customConstraint(
    "NOT NULL CHECK (provider_type IN ('graph', 'imap'))",
  )();
  TextColumn get storageType => text()();
  BoolColumn get focusEnabled => boolean().withDefault(const Constant(true))();
  TextColumn get credentialsRef => text().nullable()();
  TextColumn get syncProfileId => text().nullable()();
  IntColumn get retentionDaysOverride => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Folders extends Table {
  @override
  String get tableName => 'folders';

  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get name => text()();
  TextColumn get role => text().withDefault(const Constant(''))();
  TextColumn get remoteId => text()();
  TextColumn get parentRemoteId => text().nullable()();
  IntColumn get unreadCount => integer().nullable()();
  IntColumn get totalCount => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Messages extends Table {
  @override
  String get tableName => 'messages';

  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get folderId => text()();
  TextColumn get providerId => text()();
  TextColumn get messageIdHeader => text()();
  TextColumn get fromName => text()();
  TextColumn get fromAddress => text()();
  TextColumn get subject => text()();
  TextColumn get snippet => text()();
  TextColumn get body => text().nullable()();
  IntColumn get whenEpochMs => integer()();
  TextColumn get focusBucket => text().customConstraint(
    "NOT NULL CHECK (focus_bucket IN ('focused', 'other'))",
  )();
  BoolColumn get unread => boolean().withDefault(const Constant(false))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get hasAttachments =>
      boolean().withDefault(const Constant(false))();
  TextColumn get rawHeaders => text().nullable()();
  TextColumn get toRecipients =>
      text().named('to_recipients').withDefault(const Constant(''))();
  TextColumn get ccRecipients =>
      text().named('cc_recipients').withDefault(const Constant(''))();
  BoolColumn get starred => boolean().withDefault(const Constant(false))();
  TextColumn get threadId => text().nullable()();
  IntColumn get snoozedUntil => integer().nullable()();
  IntColumn get trashedAt => integer().nullable()();
  BoolColumn get isDraft => boolean().withDefault(const Constant(false))();
  TextColumn get draftSyncProviderId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class FocusRules extends Table {
  @override
  String get tableName => 'focus_rules';

  TextColumn get id => text()();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  TextColumn get pattern => text()();
  TextColumn get matchType => text().customConstraint(
    "NOT NULL CHECK (match_type IN ('sender', 'domain'))",
  )();
  TextColumn get bucket => text().customConstraint(
    "NOT NULL CHECK (bucket IN ('focused', 'other'))",
  )();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Outbox extends Table {
  @override
  String get tableName => 'outbox';

  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get recipientsJson => text().named('to_json')();
  TextColumn get subject => text()();
  TextColumn get body => text()();
  TextColumn get state => text().customConstraint(
    "NOT NULL CHECK (state IN ('queued', 'sending', 'sent', 'failed'))",
  )();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();
  IntColumn get createdAt => integer()();
  TextColumn get ccJson => text().nullable()();
  TextColumn get bccJson => text().nullable()();
  TextColumn get composeMode => text().withDefault(const Constant('new'))();
  TextColumn get inReplyTo => text().nullable()();
  TextColumn get referencesJson => text().nullable()();
  TextColumn get attachmentRefsJson => text().nullable()();
  TextColumn get signatureId => text().nullable()();
  IntColumn get sendAfter => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Jobs extends Table {
  @override
  String get tableName => 'sync_jobs';

  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get type => text()();
  TextColumn get status => text().customConstraint(
    "NOT NULL CHECK (status IN ('pending', 'running', 'done', 'failed'))",
  )();
  TextColumn get payloadJson => text().nullable()();
  TextColumn get cursorJson => text().nullable()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class SyncCursors extends Table {
  @override
  String get tableName => 'sync_cursors';

  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get folderId => text()();
  TextColumn get cursorKey => text()();
  TextColumn get cursorValue => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{
    accountId,
    folderId,
    cursorKey,
  };
}

class WidgetSnapshots extends Table {
  @override
  String get tableName => 'widget_snapshots';

  TextColumn get id => text()();
  TextColumn get kind => text()();
  TextColumn get payloadJson => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class SyncProfiles extends Table {
  @override
  String get tableName => 'sync_profiles';

  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get retentionDays => integer()();
  TextColumn get folderScopeJson => text().nullable()();
  TextColumn get bodyPolicy => text().withDefault(const Constant('on_open'))();
  IntColumn get attachmentMaxMb => integer().withDefault(const Constant(25))();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class Attachments extends Table {
  @override
  String get tableName => 'attachments';

  TextColumn get id => text()();
  TextColumn get messageId => text().references(Messages, #id)();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get providerPartId => text().nullable()();
  TextColumn get filename => text()();
  TextColumn get mimeType => text()();
  IntColumn get sizeBytes => integer()();
  TextColumn get localPath => text().nullable()();
  IntColumn get fetchedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class AttachmentBlobs extends Table {
  @override
  String get tableName => 'attachment_blobs';

  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get path => text()();
  IntColumn get sizeBytes => integer()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class AccountSignatures extends Table {
  @override
  String get tableName => 'account_signatures';

  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get name => text()();
  TextColumn get bodyPlain => text()();
  TextColumn get bodyHtml => text().nullable()();
  BoolColumn get isDefault => boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class AccountSignatureAssets extends Table {
  @override
  String get tableName => 'account_signature_assets';

  TextColumn get id => text()();
  TextColumn get signatureId => text().references(AccountSignatures, #id)();
  TextColumn get localPath => text()();
  TextColumn get contentId => text()();
  TextColumn get mimeType => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class MessageTemplates extends Table {
  @override
  String get tableName => 'message_templates';

  TextColumn get id => text()();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  TextColumn get name => text()();
  TextColumn get subject => text()();
  TextColumn get bodyHtml => text()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

class CustomThemes extends Table {
  @override
  String get tableName => 'custom_themes';

  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get baseThemeId => text()();
  TextColumn get tokenOverridesJson => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}

@DriftDatabase(
  tables: <Type>[
    Accounts,
    Folders,
    Messages,
    FocusRules,
    Outbox,
    Jobs,
    SyncCursors,
    WidgetSnapshots,
    SyncProfiles,
    Attachments,
    AttachmentBlobs,
    AccountSignatures,
    AccountSignatureAssets,
    MessageTemplates,
    CustomThemes,
  ],
)
class ByteMailDatabase extends _$ByteMailDatabase {
  ByteMailDatabase(super.e);

  factory ByteMailDatabase.open() => ByteMailDatabase(_openConnection());

  @override
  int get schemaVersion => 6;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator migrator) async {
      await migrator.createAll();
      await customStatement(
        'CREATE VIRTUAL TABLE message_fts USING fts5('
        'message_id UNINDEXED, subject, sender, body)',
      );
      await customStatement(
        "CREATE TRIGGER messages_fts_insert AFTER INSERT ON messages BEGIN "
        "INSERT INTO message_fts(message_id, subject, sender, body) VALUES "
        "(new.id, new.subject, new.from_name || ' ' || new.from_address, "
        "COALESCE(new.body, new.snippet)); END",
      );
      await customStatement(
        'CREATE TRIGGER messages_fts_delete AFTER DELETE ON messages BEGIN '
        'DELETE FROM message_fts WHERE message_id = old.id; END',
      );
      await customStatement(
        "CREATE TRIGGER messages_fts_update AFTER UPDATE ON messages BEGIN "
        "DELETE FROM message_fts WHERE message_id = old.id; "
        "INSERT INTO message_fts(message_id, subject, sender, body) VALUES "
        "(new.id, new.subject, new.from_name || ' ' || new.from_address, "
        "COALESCE(new.body, new.snippet)); END",
      );
      await customStatement(
        'CREATE INDEX messages_account_when ON messages(account_id, when_epoch_ms DESC)',
      );
      await customStatement(
        'CREATE INDEX messages_folder_when ON messages(folder_id, when_epoch_ms DESC)',
      );
      await customStatement(
        'CREATE INDEX sync_jobs_status_updated ON sync_jobs(status, updated_at)',
      );
      await customStatement(
        'CREATE INDEX folders_account ON folders(account_id)',
      );
      await customStatement(
        'CREATE INDEX messages_account_folder_when ON messages('
        'account_id, folder_id, when_epoch_ms DESC)',
      );
      await customStatement(
        'CREATE INDEX messages_account_starred ON messages(account_id, starred)',
      );
      await customStatement(
        "INSERT INTO sync_profiles ("
        "id, name, retention_days, folder_scope_json, body_policy, "
        "attachment_max_mb, is_default"
        ") VALUES ("
        "'default', 'Default', 180, NULL, 'on_open', 25, 1"
        ')',
      );
    },
    onUpgrade: (Migrator migrator, int from, int to) async {
      if (from < 2) {
        // Invalidate plain-text bodies cached before HTML-preferring fetch so
        // linked accounts re-download rich HTML on the next open.
        await customStatement(
          'UPDATE messages SET body = NULL WHERE account_id IN '
          '(SELECT id FROM accounts WHERE credentials_ref IS NOT NULL)',
        );
      }
      if (from < 3) {
        await migrator.addColumn(folders, folders.parentRemoteId);
        await migrator.addColumn(folders, folders.unreadCount);
        await migrator.addColumn(folders, folders.totalCount);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS folders_account ON folders(account_id)',
        );
      }
      if (from < 4) {
        await migrator.addColumn(messages, messages.rawHeaders);
      }
      if (from < 5) {
        await migrator.addColumn(accounts, accounts.syncProfileId);
        await migrator.addColumn(accounts, accounts.retentionDaysOverride);
        await migrator.addColumn(messages, messages.starred);
        await migrator.addColumn(messages, messages.threadId);
        await migrator.addColumn(messages, messages.snoozedUntil);
        await migrator.addColumn(messages, messages.trashedAt);
        await migrator.addColumn(messages, messages.isDraft);
        await migrator.addColumn(messages, messages.draftSyncProviderId);
        await migrator.addColumn(outbox, outbox.ccJson);
        await migrator.addColumn(outbox, outbox.bccJson);
        await migrator.addColumn(outbox, outbox.composeMode);
        await migrator.addColumn(outbox, outbox.inReplyTo);
        await migrator.addColumn(outbox, outbox.referencesJson);
        await migrator.addColumn(outbox, outbox.attachmentRefsJson);
        await migrator.addColumn(outbox, outbox.signatureId);
        await migrator.addColumn(outbox, outbox.sendAfter);
        await migrator.createTable(syncProfiles);
        await migrator.createTable(attachments);
        await migrator.createTable(attachmentBlobs);
        await migrator.createTable(accountSignatures);
        await migrator.createTable(accountSignatureAssets);
        await migrator.createTable(messageTemplates);
        await migrator.createTable(customThemes);
        await customStatement(
          'CREATE INDEX IF NOT EXISTS messages_account_folder_when ON '
          'messages(account_id, folder_id, when_epoch_ms DESC)',
        );
        await customStatement(
          'CREATE INDEX IF NOT EXISTS messages_account_starred ON '
          'messages(account_id, starred)',
        );
        await customStatement(
          "INSERT OR IGNORE INTO sync_profiles ("
          "id, name, retention_days, folder_scope_json, body_policy, "
          "attachment_max_mb, is_default"
          ") VALUES ("
          "'default', 'Default', 180, NULL, 'on_open', 25, 1"
          ')',
        );
      }
      if (from < 6) {
        await migrator.addColumn(messages, messages.toRecipients);
        await migrator.addColumn(messages, messages.ccRecipients);
      }
    },
  );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory directory = await getApplicationSupportDirectory();
    final File file = File(
      DbEncryptionPaths.databasePath(directory.path),
    );
    // Opt-in, disabled by default: resolveActivePassphrase() only returns
    // non-null when the user has explicitly enabled encryption AND a
    // passphrase is present in the OS keystore. Any other state (disabled,
    // or a corrupted/missing keystore entry) falls back to a plain,
    // unencrypted open so a preference glitch never locks a user out.
    final String? passphrase = await DbEncryptionConfig()
        .resolveActivePassphrase();
    return NativeDatabase.createInBackground(
      file,
      setup: passphrase == null
          ? null
          : (Database rawDb) {
              rawDb.execute(
                "PRAGMA key = '${passphrase.replaceAll("'", "''")}';",
              );
            },
    );
  });
}
