// ==============================================================================
// File: lib/repository/drift/drift_message_store.dart
// Description: Drift persistence for messages, flags, moves, and trash queries.
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/database.dart';
import 'package:bytemail/repository/drift/drift_account_folder_store.dart';
import 'package:bytemail/repository/drift/drift_mappers.dart';
import 'package:drift/drift.dart';

class DriftMessageStore {
  DriftMessageStore(
    this._database, {
    required void Function() notify,
    required DriftAccountFolderStore folders,
  }) : _notify = notify,
       _folders = folders;

  final ByteMailDatabase _database;
  final void Function() _notify;
  final DriftAccountFolderStore _folders;

  Future<List<MailMessage>> listMessages(MessageQuery query) async {
    final SimpleSelectStatement<Messages, Message> select = _database.select(
      _database.messages,
    );
    // 1. Folder scope
    final String? accountId = query.accountId;
    if (accountId != null) {
      select.where((Messages table) => table.accountId.equals(accountId));
    }
    final String? folderId = query.folderId;
    if (folderId != null) {
      select.where((Messages table) => table.folderId.equals(folderId));
    }
    // 2. Focus
    final FocusBucket? focusFilter = query.focusFilter;
    if (focusFilter != null) {
      select.where(
        (Messages table) => table.focusBucket.equals(focusFilter.name),
      );
    }
    // 3. User filter (MessageViewFilter)
    final MessageViewFilter? userFilter = query.userFilter;
    if (userFilter != null) {
      final bool? unread = userFilter.unread;
      if (unread != null) {
        select.where((Messages table) => table.unread.equals(unread));
      }
      final bool? starred = userFilter.starred;
      if (starred != null) {
        select.where((Messages table) => table.starred.equals(starred));
      }
      final String? sender = userFilter.senderContains?.trim();
      if (sender != null && sender.isNotEmpty) {
        final String pattern = '%${_escapeLike(sender)}%';
        select.where(
          (Messages table) =>
              table.fromAddress.like(pattern, escapeChar: r'\') |
              table.fromName.like(pattern, escapeChar: r'\'),
        );
      }
      final String? recipient = userFilter.recipientContains?.trim();
      if (recipient != null && recipient.isNotEmpty) {
        final String pattern = '%${_escapeLike(recipient)}%';
        select.where(
          (Messages table) =>
              table.toRecipients.like(pattern, escapeChar: r'\') |
              table.ccRecipients.like(pattern, escapeChar: r'\'),
        );
      }
      final int? after = userFilter.receivedAfterEpochMs;
      if (after != null) {
        select.where(
          (Messages table) => table.whenEpochMs.isBiggerOrEqualValue(after),
        );
      }
      final int? before = userFilter.receivedBeforeEpochMs;
      if (before != null) {
        select.where(
          (Messages table) => table.whenEpochMs.isSmallerOrEqualValue(before),
        );
      }
      final bool? hasAttachments = userFilter.hasAttachments;
      if (hasAttachments != null) {
        select.where(
          (Messages table) => table.hasAttachments.equals(hasAttachments),
        );
      }
      final String? keyword = userFilter.keyword?.trim();
      if (keyword != null && keyword.isNotEmpty) {
        final List<String> ftsIds = await _ftsMessageIds(keyword);
        if (ftsIds.isEmpty) {
          return const <MailMessage>[];
        }
        select.where((Messages table) => table.id.isIn(ftsIds));
      }
    }
    // 4. View flags
    if (query.starredOnly) {
      select.where((Messages table) => table.starred.equals(true));
    }
    if (query.pinnedOnly) {
      select.where((Messages table) => table.pinned.equals(true));
    }
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    if (query.snoozedOnly) {
      select.where(
        (Messages table) =>
            table.snoozedUntil.isNotNull() &
            table.snoozedUntil.isBiggerThanValue(nowMs),
      );
    } else if (query.excludeSnoozed) {
      select.where(
        (Messages table) =>
            table.snoozedUntil.isNull() |
            table.snoozedUntil.isSmallerOrEqualValue(nowMs),
      );
    }
    // 5. Draft / trash inclusion
    if (!query.includeDrafts) {
      select.where((Messages table) => table.isDraft.equals(false));
    }
    if (!query.includeTrashed) {
      select.where((Messages table) => table.trashedAt.isNull());
    }
    select.orderBy(<OrderingTerm Function(Messages)>[
      (Messages table) => OrderingTerm.desc(table.whenEpochMs),
    ]);
    final int? limit = query.limit;
    if (limit != null && limit > 0) {
      select.limit(limit);
    }
    final List<Message> rows = await select.get();
    return rows.map(messageFromRow).toList(growable: false);
  }

  Future<MailMessage?> getMessage(String id) async {
    final Message? row = await (_database.select(
      _database.messages,
    )..where((Messages table) => table.id.equals(id))).getSingleOrNull();
    return row == null ? null : messageFromRow(row);
  }

  /// Upserts messages and returns newly inserted unread rows (W6 detection).
  Future<List<MailMessage>> upsertMessages(
    List<MailMessage> messages, {
    required String folderId,
  }) async {
    if (messages.isEmpty) {
      return const <MailMessage>[];
    }
    final List<MailMessage> newlyInsertedUnread = <MailMessage>[];
    await _database.transaction(() async {
      for (final MailMessage message in messages) {
        await _folders.ensureFolder(message.accountId, folderId);
        final Message? existing =
            await (_database.select(_database.messages)
                  ..where((Messages table) => table.id.equals(message.id)))
                .getSingleOrNull();
        final String? bodyToStore = bodyForUpsert(
          incomingBody: message.body,
          incomingSnippet: message.snippet,
          existingBody: existing?.body,
        );
        final String? rawHeadersToStore = rawHeadersForUpsert(
          incomingRawHeaders: message.rawHeaders,
          existingRawHeaders: existing?.rawHeaders,
        );
        final ({String toRecipients, String ccRecipients}) recipients =
            recipientsForUpsert(
              incomingToRecipients: message.toRecipients,
              incomingCcRecipients: message.ccRecipients,
              rawHeaders: rawHeadersToStore,
              existingToRecipients: existing?.toRecipients,
              existingCcRecipients: existing?.ccRecipients,
            );
        // DEF-007 partial: keep local read when sync would flicker back to unread.
        final bool unreadToStore =
            existing != null && !existing.unread && message.unread
            ? existing.unread
            : message.unread;
        final String? threadIdToStore =
            message.threadId ?? existing?.threadId;
        await _database
            .into(_database.messages)
            .insertOnConflictUpdate(
              MessagesCompanion.insert(
                id: message.id,
                accountId: message.accountId,
                folderId: folderId,
                providerId: message.providerId ?? message.id,
                messageIdHeader: message.messageIdHeader ?? message.id,
                fromName: message.fromName,
                fromAddress: message.fromAddress,
                subject: message.subject,
                snippet: message.snippet,
                body: Value<String?>(bodyToStore),
                whenEpochMs:
                    message.whenEpochMs ??
                    DateTime.now().millisecondsSinceEpoch,
                focusBucket: message.bucket.name,
                unread: Value<bool>(unreadToStore),
                pinned: Value<bool>(
                  existing != null ? existing.pinned : message.pinned,
                ),
                hasAttachments: Value<bool>(message.hasAttachments),
                rawHeaders: Value<String?>(rawHeadersToStore),
                toRecipients: Value<String>(recipients.toRecipients),
                ccRecipients: Value<String>(recipients.ccRecipients),
                starred: Value<bool>(
                  existing != null ? existing.starred : message.starred,
                ),
                threadId: Value<String?>(threadIdToStore),
                snoozedUntil: Value<int?>(
                  existing != null
                      ? existing.snoozedUntil
                      : message.snoozedUntil,
                ),
                trashedAt: Value<int?>(
                  existing != null ? existing.trashedAt : message.trashedAt,
                ),
                isDraft: Value<bool>(
                  existing != null ? existing.isDraft : message.isDraft,
                ),
                draftSyncProviderId: Value<String?>(
                  existing != null
                      ? existing.draftSyncProviderId
                      : message.draftSyncProviderId,
                ),
              ),
            );
        if (existing == null && unreadToStore) {
          newlyInsertedUnread.add(
            message.copyWith(unread: unreadToStore, folderId: folderId),
          );
        }
      }
      await _folders.recountUnreadFromMessages();
    });
    _notify();
    return newlyInsertedUnread;
  }

  Future<void> updateMessageBody(String messageId, String body) async {
    await (_database.update(_database.messages)
          ..where((Messages table) => table.id.equals(messageId)))
        .write(MessagesCompanion(body: Value<String?>(body)));
    // Intentionally no notify: callers update in-memory state.
    // Avoids a full mailbox refresh/loading flicker on every open-body fetch.
  }

  Future<void> updateMessageRawHeaders(
    String messageId,
    String rawHeaders,
  ) async {
    final MailMessage? existing = await getMessage(messageId);
    final ({String toRecipients, String ccRecipients}) recipients =
        recipientsForUpsert(
          incomingToRecipients: '',
          incomingCcRecipients: '',
          rawHeaders: rawHeaders,
          existingToRecipients: existing?.toRecipients,
          existingCcRecipients: existing?.ccRecipients,
        );
    await (_database.update(_database.messages)
          ..where((Messages table) => table.id.equals(messageId)))
        .write(
          MessagesCompanion(
            rawHeaders: Value<String?>(rawHeaders),
            toRecipients: Value<String>(recipients.toRecipients),
            ccRecipients: Value<String>(recipients.ccRecipients),
          ),
        );
  }

  Future<void> updateMessageFocusBucket(
    String messageId,
    FocusBucket bucket,
  ) async {
    await (_database.update(_database.messages)
          ..where((Messages table) => table.id.equals(messageId)))
        .write(MessagesCompanion(focusBucket: Value<String>(bucket.name)));
    _notify();
  }

  Future<List<MailMessage>> searchLocal(String query) async {
    final List<String> ids = await _ftsMessageIds(query);
    if (ids.isEmpty) {
      return <MailMessage>[];
    }
    final List<MailMessage> results = <MailMessage>[];
    for (final String id in ids) {
      final MailMessage? message = await getMessage(id);
      if (message != null) {
        results.add(message);
      }
    }
    return results;
  }

  Future<List<String>> _ftsMessageIds(String query) async {
    final String matchQuery = toFtsQuery(query);
    if (matchQuery.isEmpty) {
      return const <String>[];
    }
    final List<QueryRow> hits = await _database
        .customSelect(
          'SELECT message_id FROM message_fts WHERE message_fts MATCH ? '
          'ORDER BY bm25(message_fts)',
          variables: <Variable<Object>>[Variable<String>(matchQuery)],
        )
        .get();
    return hits
        .map((QueryRow row) => row.read<String>('message_id'))
        .toList(growable: false);
  }

  static String _escapeLike(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');
  }

  Future<int> applyRetention({
    required int retentionDays,
    String? accountId,
  }) async {
    if (retentionDays < 0) {
      throw ArgumentError.value(
        retentionDays,
        'retentionDays',
        'Must be non-negative.',
      );
    }
    final int cutoff = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    final int removed = await (_database.delete(_database.messages)
          ..where((Messages table) {
            Expression<bool> predicate =
                table.whenEpochMs.isSmallerThanValue(cutoff) &
                table.pinned.equals(false);
            if (accountId != null && accountId.isNotEmpty) {
              predicate = predicate & table.accountId.equals(accountId);
            }
            return predicate;
          }))
        .go();
    if (removed > 0) {
      _notify();
    }
    return removed;
  }

  Future<void> setPinned(String messageId, bool pinned) async {
    await setPinnedBulk(<String>[messageId], pinned);
  }

  Future<void> setPinnedBulk(List<String> ids, bool pinned) async {
    if (ids.isEmpty) {
      return;
    }
    await (_database.update(_database.messages)
          ..where((Messages table) => table.id.isIn(ids)))
        .write(MessagesCompanion(pinned: Value<bool>(pinned)));
    _notify();
  }

  Future<void> setSnoozed(String messageId, int? snoozedUntil) async {
    await setSnoozedBulk(<String>[messageId], snoozedUntil);
  }

  Future<void> setSnoozedBulk(List<String> ids, int? snoozedUntil) async {
    if (ids.isEmpty) {
      return;
    }
    await (_database.update(_database.messages)
          ..where((Messages table) => table.id.isIn(ids)))
        .write(
          MessagesCompanion(snoozedUntil: Value<int?>(snoozedUntil)),
        );
    await _folders.recountUnreadFromMessages();
    _notify();
  }

  Future<int?> nextSnoozeExpiryMs({int? nowMs}) async {
    final int now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final Expression<int> minCol = _database.messages.snoozedUntil.min();
    final TypedResult row =
        await (_database.selectOnly(_database.messages)
              ..addColumns(<Expression<Object>>[minCol])
              ..where(
                _database.messages.snoozedUntil.isNotNull() &
                    _database.messages.snoozedUntil.isBiggerThanValue(now),
              ))
            .getSingle();
    return row.read(minCol);
  }

  Future<int> clearExpiredSnoozes({int? nowMs}) async {
    final int now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final int updated =
        await (_database.update(_database.messages)..where(
              (Messages table) =>
                  table.snoozedUntil.isNotNull() &
                  table.snoozedUntil.isSmallerOrEqualValue(now),
            ))
            .write(
              const MessagesCompanion(snoozedUntil: Value<int?>(null)),
            );
    if (updated > 0) {
      _notify();
    }
    return updated;
  }

  Future<void> setStarred(String messageId, bool starred) async {
    await (_database.update(_database.messages)
          ..where((Messages table) => table.id.equals(messageId)))
        .write(MessagesCompanion(starred: Value<bool>(starred)));
    _notify();
  }

  Future<void> moveMessageLocal(
    String messageId,
    String folderId, {
    int? trashedAt,
    bool clearTrashedAt = false,
  }) async {
    await moveMessagesLocal(
      <String>[messageId],
      folderId,
      trashedAt: trashedAt,
      clearTrashedAt: clearTrashedAt,
    );
  }

  Future<void> moveMessagesLocal(
    List<String> messageIds,
    String folderId, {
    int? trashedAt,
    bool clearTrashedAt = false,
  }) async {
    if (messageIds.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final String messageId in messageIds) {
        final Message? row =
            await (_database.select(_database.messages)
                  ..where((Messages table) => table.id.equals(messageId)))
                .getSingleOrNull();
        if (row == null) {
          continue;
        }
        await _folders.ensureFolder(row.accountId, folderId);
        final Value<int?> trashedAtValue;
        if (clearTrashedAt) {
          trashedAtValue = const Value<int?>(null);
        } else if (trashedAt != null) {
          trashedAtValue = Value<int?>(trashedAt);
        } else {
          trashedAtValue = const Value.absent();
        }
        await (_database.update(
          _database.messages,
        )..where((Messages table) => table.id.equals(messageId))).write(
          MessagesCompanion(
            folderId: Value<String>(folderId),
            trashedAt: trashedAtValue,
          ),
        );
      }
      await _folders.recountUnreadFromMessages();
    });
    _notify();
  }

  Future<void> hardDeleteLocal(String messageId) async {
    await hardDeleteLocalBulk(<String>[messageId]);
  }

  Future<void> hardDeleteLocalBulk(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final String messageId in ids) {
        final Message? row =
            await (_database.select(_database.messages)
                  ..where((Messages table) => table.id.equals(messageId)))
                .getSingleOrNull();
        if (row == null) {
          continue;
        }
        await (_database.delete(_database.attachments)
              ..where((Attachments table) => table.messageId.equals(messageId)))
            .go();
        await (_database.delete(
          _database.messages,
        )..where((Messages table) => table.id.equals(messageId))).go();
      }
      await _folders.recountUnreadFromMessages();
    });
    _notify();
  }

  Future<List<MailMessage>> listTrashedPastRetention({
    required int retentionDays,
    DateTime? now,
  }) async {
    if (retentionDays < 0) {
      throw ArgumentError.value(
        retentionDays,
        'retentionDays',
        'Must be non-negative.',
      );
    }
    final DateTime effectiveNow = now ?? DateTime.now();
    final int cutoff = effectiveNow
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;
    final List<Message> rows =
        await (_database.select(_database.messages)
              ..where(
                (Messages table) =>
                    table.trashedAt.isNotNull() &
                    table.trashedAt.isSmallerOrEqualValue(cutoff),
              )
              ..orderBy(<OrderingTerm Function(Messages)>[
                (Messages table) => OrderingTerm.asc(table.trashedAt),
              ]))
            .get();
    return rows.map(messageFromRow).toList(growable: false);
  }

  Future<void> setUnread(String messageId, bool unread) async {
    await setUnreadBulk(<String>[messageId], unread);
  }

  Future<void> setUnreadBulk(List<String> ids, bool unread) async {
    if (ids.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final String id in ids) {
        final Message? row = await (_database.select(
          _database.messages,
        )..where((Messages table) => table.id.equals(id))).getSingleOrNull();
        if (row == null || row.unread == unread) {
          continue;
        }
        await (_database.update(_database.messages)
              ..where((Messages table) => table.id.equals(id)))
            .write(MessagesCompanion(unread: Value<bool>(unread)));
      }
      await _folders.recountUnreadFromMessages();
    });
    _notify();
  }
}
