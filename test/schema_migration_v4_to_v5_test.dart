// ==============================================================================
// File: test/schema_migration_v4_to_v5_test.dart
// Description: Real file-backed SQLite migration from schema v4 to v5.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-16
// ==============================================================================

import 'dart:io';

import 'package:bytemail/repository/database.dart';
import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';

/// Creates a minimal pre-v5 (schema version 4) ByteMail database on disk.
void _writeSchemaV4Database(String filePath) {
  final Database db = sqlite3.open(filePath);
  try {
    db.execute('''
CREATE TABLE accounts (
  id TEXT NOT NULL PRIMARY KEY,
  label TEXT NOT NULL,
  address TEXT NOT NULL,
  accent_argb INTEGER NOT NULL,
  provider_type TEXT NOT NULL CHECK (provider_type IN ('graph', 'imap')),
  storage_type TEXT NOT NULL,
  focus_enabled INTEGER NOT NULL DEFAULT 1,
  credentials_ref TEXT
);
''');
    db.execute('''
CREATE TABLE folders (
  id TEXT NOT NULL PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts (id),
  name TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT '',
  remote_id TEXT NOT NULL,
  parent_remote_id TEXT,
  unread_count INTEGER,
  total_count INTEGER
);
''');
    db.execute('''
CREATE TABLE messages (
  id TEXT NOT NULL PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts (id),
  folder_id TEXT NOT NULL,
  provider_id TEXT NOT NULL,
  message_id_header TEXT NOT NULL,
  from_name TEXT NOT NULL,
  from_address TEXT NOT NULL,
  subject TEXT NOT NULL,
  snippet TEXT NOT NULL,
  body TEXT,
  when_epoch_ms INTEGER NOT NULL,
  focus_bucket TEXT NOT NULL CHECK (focus_bucket IN ('focused', 'other')),
  unread INTEGER NOT NULL DEFAULT 0,
  pinned INTEGER NOT NULL DEFAULT 0,
  has_attachments INTEGER NOT NULL DEFAULT 0,
  raw_headers TEXT
);
''');
    db.execute('''
CREATE TABLE outbox (
  id TEXT NOT NULL PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts (id),
  to_json TEXT NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('queued', 'sending', 'sent', 'failed')),
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  created_at INTEGER NOT NULL
);
''');
    db.execute('''
CREATE TABLE focus_rules (
  id TEXT NOT NULL PRIMARY KEY,
  account_id TEXT REFERENCES accounts (id),
  pattern TEXT NOT NULL,
  match_type TEXT NOT NULL CHECK (match_type IN ('sender', 'domain')),
  bucket TEXT NOT NULL CHECK (bucket IN ('focused', 'other'))
);
''');
    db.execute('''
CREATE TABLE sync_jobs (
  id TEXT NOT NULL PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts (id),
  type TEXT NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'running', 'done', 'failed')),
  payload_json TEXT,
  cursor_json TEXT,
  updated_at INTEGER NOT NULL
);
''');
    db.execute('''
CREATE TABLE sync_cursors (
  account_id TEXT NOT NULL REFERENCES accounts (id),
  folder_id TEXT NOT NULL,
  cursor_key TEXT NOT NULL,
  cursor_value TEXT NOT NULL,
  PRIMARY KEY (account_id, folder_id, cursor_key)
);
''');
    db.execute('''
CREATE TABLE widget_snapshots (
  id TEXT NOT NULL PRIMARY KEY,
  kind TEXT NOT NULL,
  payload_json TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
''');

    db.execute(
      "INSERT INTO accounts ("
      "id, label, address, accent_argb, provider_type, storage_type, "
      "focus_enabled, credentials_ref"
      ") VALUES ("
      "'work', 'Work', 'work@byte.io', 4278228919, 'imap', 'local', 1, NULL"
      ')',
    );
    db.execute(
      "INSERT INTO folders ("
      "id, account_id, name, role, remote_id, parent_remote_id, "
      "unread_count, total_count"
      ") VALUES ("
      "'inbox-work', 'work', 'Inbox', 'inbox', 'INBOX', NULL, 1, 1"
      ')',
    );
    db.execute(
      "INSERT INTO messages ("
      "id, account_id, folder_id, provider_id, message_id_header, "
      "from_name, from_address, subject, snippet, body, when_epoch_ms, "
      "focus_bucket, unread, pinned, has_attachments, raw_headers"
      ") VALUES ("
      "'msg-legacy', 'work', 'inbox-work', '101', '<legacy@byte.io>', "
      "'Alice', 'alice@byte.io', 'Pre-migration', 'snippet', 'body text', "
      "1700000000000, 'focused', 1, 0, 0, 'From: alice@byte.io'"
      ')',
    );
    db.execute('PRAGMA user_version = 4');
  } finally {
    db.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('opens v4 file database and migrates to schema v5', () async {
    final Directory tempDir = await Directory.systemTemp.createTemp(
      'bytemail_v4_mig_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final String dbPath = path.join(tempDir.path, 'bytemail_v4.sqlite');
    _writeSchemaV4Database(dbPath);

    final ByteMailDatabase database = ByteMailDatabase(
      NativeDatabase(File(dbPath)),
    );
    addTearDown(database.close);

    // Force Drift to open the connection and run onUpgrade.
    await database.customSelect('SELECT 1').get();

    final int userVersion =
        (await database.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version');
    expect(userVersion, 5);

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
        'raw_headers',
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

    final QueryRow profile = await database
        .customSelect(
          "SELECT id, name, retention_days, is_default FROM sync_profiles "
          "WHERE id = 'default'",
        )
        .getSingle();
    expect(profile.read<String>('id'), 'default');
    expect(profile.read<String>('name'), 'Default');
    expect(profile.read<int>('retention_days'), 180);
    expect(profile.read<int>('is_default'), 1);

    final QueryRow legacy = await database
        .customSelect(
          'SELECT id, subject, starred, thread_id, is_draft, raw_headers '
          "FROM messages WHERE id = 'msg-legacy'",
        )
        .getSingle();
    expect(legacy.read<String>('id'), 'msg-legacy');
    expect(legacy.read<String>('subject'), 'Pre-migration');
    expect(legacy.read<int>('starred'), 0);
    expect(legacy.read<String?>('thread_id'), isNull);
    expect(legacy.read<int>('is_draft'), 0);
    expect(legacy.read<String>('raw_headers'), 'From: alice@byte.io');
  });
}
