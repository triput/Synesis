// ==============================================================================
// File: test/schema_migration_v6_to_v7_test.dart
// Description: Real file-backed SQLite migration from schema v6 to v7 (PIM).
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'dart:io';

import 'package:drift/drift.dart' show QueryRow;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart';
import 'package:synesis/repository/database.dart';

/// Minimal schema version 6 database (mail tables only, no PIM).
void _writeSchemaV6Database(String filePath) {
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
  credentials_ref TEXT,
  sync_profile_id TEXT,
  retention_days_override INTEGER
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
  raw_headers TEXT,
  to_recipients TEXT NOT NULL DEFAULT '',
  cc_recipients TEXT NOT NULL DEFAULT '',
  starred INTEGER NOT NULL DEFAULT 0,
  thread_id TEXT,
  snoozed_until INTEGER,
  trashed_at INTEGER,
  is_draft INTEGER NOT NULL DEFAULT 0,
  draft_sync_provider_id TEXT
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
CREATE TABLE outbox (
  id TEXT NOT NULL PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts (id),
  to_json TEXT NOT NULL,
  subject TEXT NOT NULL,
  body TEXT NOT NULL,
  state TEXT NOT NULL CHECK (state IN ('queued', 'sending', 'sent', 'failed')),
  attempts INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  created_at INTEGER NOT NULL,
  cc_json TEXT,
  bcc_json TEXT,
  compose_mode TEXT NOT NULL DEFAULT 'new',
  in_reply_to TEXT,
  references_json TEXT,
  attachment_refs_json TEXT,
  signature_id TEXT,
  send_after INTEGER
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
    db.execute('''
CREATE TABLE sync_profiles (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  retention_days INTEGER NOT NULL,
  folder_scope_json TEXT,
  body_policy TEXT NOT NULL DEFAULT 'on_open',
  attachment_max_mb INTEGER NOT NULL DEFAULT 25,
  is_default INTEGER NOT NULL DEFAULT 0
);
''');
    db.execute('''
CREATE TABLE attachments (
  id TEXT NOT NULL PRIMARY KEY,
  message_id TEXT NOT NULL REFERENCES messages (id),
  account_id TEXT NOT NULL REFERENCES accounts (id),
  provider_part_id TEXT,
  filename TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  local_path TEXT,
  fetched_at INTEGER
);
''');
    db.execute('''
CREATE TABLE attachment_blobs (
  id TEXT NOT NULL PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts (id),
  path TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  created_at INTEGER NOT NULL
);
''');
    db.execute('''
CREATE TABLE account_signatures (
  id TEXT NOT NULL PRIMARY KEY,
  account_id TEXT NOT NULL REFERENCES accounts (id),
  name TEXT NOT NULL,
  body_plain TEXT NOT NULL,
  body_html TEXT,
  is_default INTEGER NOT NULL DEFAULT 0,
  sort_order INTEGER NOT NULL DEFAULT 0
);
''');
    db.execute('''
CREATE TABLE account_signature_assets (
  id TEXT NOT NULL PRIMARY KEY,
  signature_id TEXT NOT NULL REFERENCES account_signatures (id),
  local_path TEXT NOT NULL,
  content_id TEXT NOT NULL,
  mime_type TEXT NOT NULL
);
''');
    db.execute('''
CREATE TABLE message_templates (
  id TEXT NOT NULL PRIMARY KEY,
  account_id TEXT REFERENCES accounts (id),
  name TEXT NOT NULL,
  subject TEXT NOT NULL,
  body_html TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0
);
''');
    db.execute('''
CREATE TABLE custom_themes (
  id TEXT NOT NULL PRIMARY KEY,
  name TEXT NOT NULL,
  base_theme_id TEXT NOT NULL,
  token_overrides_json TEXT NOT NULL
);
''');
    db.execute(
      'CREATE VIRTUAL TABLE message_fts USING fts5('
      'message_id UNINDEXED, subject, sender, body)',
    );

    db.execute(
      "INSERT INTO accounts ("
      "id, label, address, accent_argb, provider_type, storage_type, "
      "focus_enabled, credentials_ref, sync_profile_id, retention_days_override"
      ") VALUES ("
      "'work', 'Work', 'work@byte.io', 4278228919, 'imap', 'local', 1, NULL, "
      "'default', NULL"
      ')',
    );
    db.execute(
      "INSERT INTO sync_profiles ("
      "id, name, retention_days, folder_scope_json, body_policy, "
      "attachment_max_mb, is_default"
      ") VALUES ("
      "'default', 'Default', 180, NULL, 'on_open', 25, 1"
      ')',
    );
    db.execute('PRAGMA user_version = 6');
  } finally {
    db.dispose();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('opens v6 file database and migrates to schema v7 with PIM tables',
      () async {
    final Directory tempDir = await Directory.systemTemp.createTemp(
      'synesis_v6_mig_',
    );
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final String dbPath = path.join(tempDir.path, 'synesis_v6.sqlite');
    _writeSchemaV6Database(dbPath);

    final SynesisDatabase database = SynesisDatabase(
      NativeDatabase(File(dbPath)),
    );
    addTearDown(database.close);

    await database.customSelect('SELECT 1').get();

    final int userVersion =
        (await database.customSelect('PRAGMA user_version').getSingle())
            .read<int>('user_version');
    expect(userVersion, 7);

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
        'contact_lists',
        'contacts',
        'contact_emails',
        'contact_phones',
        'calendars',
        'events',
        'event_attendees',
      ]),
    );

    final List<String> ftsNames =
        (await database
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'table' "
                  "AND name = 'contact_fts'",
                )
                .get())
            .map((QueryRow row) => row.read<String>('name'))
            .toList(growable: false);
    expect(ftsNames, <String>['contact_fts']);

    final Set<String> calendarColumns =
        (await database.customSelect('PRAGMA table_info(calendars)').get())
            .map((QueryRow row) => row.read<String>('name'))
            .toSet();
    expect(
      calendarColumns,
      containsAll(<String>[
        'account_id',
        'provider_id',
        'name',
        'color_argb',
        'color_override_argb',
        'is_default',
        'is_selected_for_display',
        'sort_index',
      ]),
    );

    final Set<String> contactListColumns =
        (await database.customSelect('PRAGMA table_info(contact_lists)').get())
            .map((QueryRow row) => row.read<String>('name'))
            .toSet();
    expect(
      contactListColumns,
      containsAll(<String>[
        'account_id',
        'provider_id',
        'is_selected_for_display',
        'sort_index',
      ]),
    );

    final Set<String> contactColumns =
        (await database.customSelect('PRAGMA table_info(contacts)').get())
            .map((QueryRow row) => row.read<String>('name'))
            .toSet();
    expect(contactColumns, contains('contact_list_id'));

    final Set<String> eventColumns =
        (await database.customSelect('PRAGMA table_info(events)').get())
            .map((QueryRow row) => row.read<String>('name'))
            .toSet();
    expect(eventColumns, contains('calendar_id'));

    // Pre-existing account row survives migration.
    final QueryRow account = await database
        .customSelect("SELECT id, address FROM accounts WHERE id = 'work'")
        .getSingle();
    expect(account.read<String>('address'), 'work@byte.io');
  });
}
