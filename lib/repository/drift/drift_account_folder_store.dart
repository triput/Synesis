// ==============================================================================
// File: lib/repository/drift/drift_account_folder_store.dart
// Description: Drift persistence for accounts, folders, and account wipe.
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/database.dart';
import 'package:bytemail/repository/drift/drift_account_mapper.dart';
import 'package:bytemail/repository/drift/drift_mappers.dart';
import 'package:drift/drift.dart';

class DriftAccountFolderStore {
  DriftAccountFolderStore(
    this._database, {
    required void Function() notify,
  }) : _notify = notify;

  final ByteMailDatabase _database;
  final void Function() _notify;


  Future<List<MailAccount>> listAccounts() async {
    final List<Account> rows =
        await (_database.select(_database.accounts)
              ..orderBy(<OrderingTerm Function(Accounts)>[
                (Accounts table) => OrderingTerm.asc(table.address),
              ]))
            .get();
    return rows.map(accountFromRow).toList(growable: false);
  }

  Future<List<MailFolder>> listFolders({String? accountId}) async {
    final query = _database.select(_database.folders);
    if (accountId != null) {
      query.where((Folders table) => table.accountId.equals(accountId));
    }
    query.orderBy(<OrderingTerm Function(Folders)>[
      (Folders table) => OrderingTerm.asc(table.name),
    ]);
    final List<Folder> rows = await query.get();
    return rows.map(folderFromRow).toList(growable: false);
  }

  Future<MailFolder?> getFolder(String id) async {
    final Folder? row = await (_database.select(
      _database.folders,
    )..where((Folders table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : folderFromRow(row);
  }

  Future<void> upsertFolders(List<MailFolder> folders) async {
    if (folders.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final MailFolder folder in folders) {
        await _database
            .into(_database.folders)
            .insertOnConflictUpdate(
              FoldersCompanion.insert(
                id: folder.id,
                accountId: folder.accountId,
                name: folder.name,
                role: Value<String>(folder.role ?? ''),
                remoteId: folder.remoteId,
                parentRemoteId: Value<String?>(folder.parentRemoteId),
                unreadCount: Value<int?>(folder.unreadCount),
                totalCount: Value<int?>(folder.totalCount),
              ),
            );
      }
    });
    _notify();
  }

  Future<void> upsertAccount(
    MailAccount account, {
    required String providerType,
    bool focusEnabled = true,
  }) async {
    _validateProviderType(providerType);
    await _database
        .into(_database.accounts)
        .insertOnConflictUpdate(
          AccountsCompanion.insert(
            id: account.id,
            label: account.label,
            address: account.address,
            accentArgb: accentArgbFromAccount(account),
            providerType: providerType,
            storageType: account.storageType,
            focusEnabled: Value<bool>(focusEnabled),
            credentialsRef: Value<String?>(account.credentialsRef),
            syncProfileId: Value<String?>(account.syncProfileId),
            retentionDaysOverride: Value<int?>(account.retentionDaysOverride),
          ),
        );
    _notify();
  }

  Future<MailFolder?> resolveFolderByRole(String accountId, String role) async {
    final String? canonical = canonicalFolderRole(role);
    if (canonical == null) {
      return null;
    }
    final List<MailFolder> folders = await listFolders(accountId: accountId);
    for (final MailFolder folder in folders) {
      final String? folderCanonical = canonicalFolderRole(folder.role);
      if (folderCanonical == canonical) {
        return folder;
      }
    }
    for (final MailFolder folder in folders) {
      final String existingRole = folder.role?.trim() ?? '';
      if (existingRole.isNotEmpty) {
        continue;
      }
      if (_folderMatchesRoleHeuristic(folder, canonical)) {
        return folder;
      }
    }
    return null;
  }

  Future<void> wipeAccount(String accountId) async {
    await _database.transaction(() async {
      await (_database.delete(
        _database.attachments,
      )..where((Attachments table) => table.accountId.equals(accountId))).go();
      await (_database.delete(_database.attachmentBlobs)..where(
            (AttachmentBlobs table) => table.accountId.equals(accountId),
          ))
          .go();
      await _database.customStatement(
        'DELETE FROM account_signature_assets WHERE signature_id IN '
        '(SELECT id FROM account_signatures WHERE account_id = ?)',
        <Object>[accountId],
      );
      await (_database.delete(_database.accountSignatures)..where(
            (AccountSignatures table) => table.accountId.equals(accountId),
          ))
          .go();
      await (_database.delete(_database.messageTemplates)..where(
            (MessageTemplates table) => table.accountId.equals(accountId),
          ))
          .go();
      await (_database.delete(
        _database.messages,
      )..where((Messages table) => table.accountId.equals(accountId))).go();
      await (_database.delete(
        _database.folders,
      )..where((Folders table) => table.accountId.equals(accountId))).go();
      await (_database.delete(
        _database.outbox,
      )..where((Outbox table) => table.accountId.equals(accountId))).go();
      await (_database.delete(
        _database.jobs,
      )..where((Jobs table) => table.accountId.equals(accountId))).go();
      await (_database.delete(
        _database.syncCursors,
      )..where((SyncCursors table) => table.accountId.equals(accountId))).go();
      await (_database.delete(
        _database.focusRules,
      )..where((FocusRules table) => table.accountId.equals(accountId))).go();
      // Prefer payload accountId match; also catch id-prefixed snapshot rows.
      await _database.customStatement(
        'DELETE FROM widget_snapshots WHERE '
        "payload_json LIKE ? OR payload_json LIKE ? OR id LIKE ?",
        <Object>['%"accountId":"$accountId"%', '%$accountId%', '$accountId%'],
      );
      await (_database.delete(
        _database.accounts,
      )..where((Accounts table) => table.id.equals(accountId))).go();
    });
    _notify();
  }

  /// Ensures a folder row exists (insert-or-ignore). Used by message moves/upserts.
  Future<void> ensureFolder(String accountId, String folderId) async {
    final bool isInbox = folderId == MailFolder.inboxId(accountId);
    await _database
        .into(_database.folders)
        .insert(
          FoldersCompanion.insert(
            id: folderId,
            accountId: accountId,
            name: isInbox ? 'Inbox' : folderId,
            role: Value<String>(isInbox ? 'inbox' : ''),
            remoteId: isInbox ? 'INBOX' : folderId,
          ),
          mode: InsertMode.insertOrIgnore,
        );
  }

  /// Applies unread-count deltas to folder rows (clamped ≥ 0).
  Future<void> applyFolderUnreadDeltas(Map<String, int> folderDelta) async {
    for (final MapEntry<String, int> entry in folderDelta.entries) {
      if (entry.value == 0) {
        continue;
      }
      final Folder? folder =
          await (_database.select(_database.folders)
                ..where((Folders table) => table.id.equals(entry.key)))
              .getSingleOrNull();
      if (folder == null) {
        continue;
      }
      final int current = folder.unreadCount ?? 0;
      final int next = (current + entry.value).clamp(0, 1 << 30);
      await (_database.update(_database.folders)
            ..where((Folders table) => table.id.equals(entry.key)))
          .write(FoldersCompanion(unreadCount: Value<int?>(next)));
    }
  }

  /// Recomputes [Folders.unreadCount] from local messages.
  ///
  /// Counts messages where unread, not draft, not trashed, and not actively
  /// snoozed (`snoozedUntil` is null or ≤ [nowMs]).
  Future<void> recountUnreadFromMessages({
    String? accountId,
    int? nowMs,
  }) async {
    final int now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final StringBuffer sql = StringBuffer(
      'SELECT folder_id AS folder_id, COUNT(*) AS unread_count '
      'FROM messages '
      'WHERE unread = 1 '
      'AND is_draft = 0 '
      'AND trashed_at IS NULL '
      'AND (snoozed_until IS NULL OR snoozed_until <= ?) ',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[
      Variable<int>(now),
    ];
    if (accountId != null) {
      sql.write('AND account_id = ? ');
      variables.add(Variable<String>(accountId));
    }
    sql.write('GROUP BY folder_id');

    final List<QueryRow> rows = await _database
        .customSelect(sql.toString(), variables: variables)
        .get();
    final Map<String, int> countsByFolder = <String, int>{
      for (final QueryRow row in rows)
        row.read<String>('folder_id'): row.read<int>('unread_count'),
    };

    final SimpleSelectStatement<Folders, Folder> folderQuery =
        _database.select(_database.folders);
    if (accountId != null) {
      folderQuery.where((Folders table) => table.accountId.equals(accountId));
    }
    final List<Folder> folders = await folderQuery.get();
    for (final Folder folder in folders) {
      final int next = countsByFolder[folder.id] ?? 0;
      if (folder.unreadCount == next) {
        continue;
      }
      await (_database.update(_database.folders)
            ..where((Folders table) => table.id.equals(folder.id)))
          .write(FoldersCompanion(unreadCount: Value<int?>(next)));
    }
  }

  /// Maps role aliases to canonical roles: trash, junk, archive, inbox.
  static String? canonicalFolderRole(String? role) {
    if (role == null) {
      return null;
    }
    final String normalized = role.trim().toLowerCase();
    if (normalized.isEmpty) {
      return null;
    }
    switch (normalized) {
      case 'trash':
      case 'deleteditems':
      case 'deleted':
        return 'trash';
      case 'junk':
      case 'junkemail':
      case 'spam':
        return 'junk';
      case 'archive':
        return 'archive';
      case 'inbox':
        return 'inbox';
      case 'sentitems':
      case 'sent':
        return 'sentitems';
      case 'drafts':
      case 'draft':
        return 'drafts';
      default:
        return null;
    }
  }

  bool _folderMatchesRoleHeuristic(MailFolder folder, String canonical) {
    if (_folderNameMatchesRole(folder.name, canonical)) {
      return true;
    }
    if (_folderNameMatchesRole(folder.remoteId, canonical)) {
      return true;
    }
    if (_folderPathSuffixMatchesRole(folder.remoteId, canonical)) {
      return true;
    }
    if (_folderPathSuffixMatchesRole(folder.name, canonical)) {
      return true;
    }
    return false;
  }

  bool _folderNameMatchesRole(String name, String canonical) {
    final String normalized = name.trim().toLowerCase();
    switch (canonical) {
      case 'trash':
        return normalized == 'trash' ||
            normalized == 'deleted items' ||
            normalized == 'deleted' ||
            normalized == 'bin' ||
            normalized == '[gmail]/trash';
      case 'junk':
        return normalized == 'junk' ||
            normalized == 'spam' ||
            normalized == 'junk email' ||
            normalized == 'junk e-mail' ||
            normalized == '[gmail]/spam';
      case 'archive':
        // Prefer exact Archive; Gmail All Mail only when role is empty (caller).
        return normalized == 'archive' || normalized == '[gmail]/all mail';
      case 'inbox':
        return normalized == 'inbox';
      default:
        return false;
    }
  }

  bool _folderPathSuffixMatchesRole(String path, String canonical) {
    final String normalized =
        path.trim().toLowerCase().replaceAll('\\', '/');
    if (normalized.isEmpty) {
      return false;
    }
    final List<String> suffixes;
    switch (canonical) {
      case 'trash':
        suffixes = const <String>[
          '/trash',
          '/deleted items',
          '/deleted',
          '/bin',
          '/[gmail]/trash',
        ];
      case 'junk':
        suffixes = const <String>[
          '/junk',
          '/spam',
          '/junk email',
          '/junk e-mail',
          '/[gmail]/spam',
        ];
      case 'archive':
        suffixes = const <String>[
          '/archive',
          '/[gmail]/all mail',
        ];
      case 'inbox':
        suffixes = const <String>['/inbox'];
      default:
        return false;
    }
    for (final String suffix in suffixes) {
      if (normalized.endsWith(suffix)) {
        return true;
      }
    }
    return false;
  }

  void _validateProviderType(String providerType) {
    if (providerType != 'graph' && providerType != 'imap') {
      throw ArgumentError.value(
        providerType,
        'providerType',
        'Must be graph or imap.',
      );
    }
  }
}
