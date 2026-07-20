// ==============================================================================
// File: lib/repository/mail_repository.dart
// Description: Local-first mail persistence contract and queue domain types.
// Component: Repository
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/compose/account_signature.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/theme/custom_theme.dart';

class OutboxItem {
  const OutboxItem({
    required this.id,
    required this.accountId,
    required this.to,
    required this.subject,
    required this.body,
    required this.state,
    required this.attempts,
    required this.createdAt,
    this.lastError,
    this.cc,
    this.bcc,
    this.composeMode = 'new',
    this.inReplyTo,
    this.referencesJson,
    this.attachmentRefsJson,
    this.signatureId,
    this.sendAfter,
  });

  final String id;
  final String accountId;
  final String to;
  final String subject;
  final String body;
  final String state;
  final int attempts;
  final String? lastError;
  final int createdAt;
  final String? cc;
  final String? bcc;
  final String composeMode;
  final String? inReplyTo;
  final String? referencesJson;
  final String? attachmentRefsJson;
  final String? signatureId;
  final int? sendAfter;
}

class SyncJob {
  const SyncJob({
    required this.id,
    required this.accountId,
    required this.type,
    required this.status,
    required this.updatedAt,
    this.payloadJson,
    this.cursorJson,
  });

  final String id;
  final String accountId;
  final String type;
  final String status;
  final String? payloadJson;
  final String? cursorJson;
  final int updatedAt;

  /// Error text stored in [cursorJson] when [status] is `failed`.
  String? get errorSnippet {
    final String? raw = cursorJson;
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map<Object?, Object?>) {
        final String? error = decoded['error']?.toString();
        if (error != null && error.isNotEmpty) {
          return error;
        }
      }
    } on FormatException {
      return raw;
    }
    return null;
  }
}

/// Lightweight per-account sync health for the in-app job viewer.
class AccountSyncHealth {
  const AccountSyncHealth({
    required this.accountId,
    required this.pendingCount,
    required this.failedCount,
    required this.syncing,
    this.lastSuccessAt,
    this.lastError,
  });

  final String accountId;
  final DateTime? lastSuccessAt;
  final String? lastError;
  final int pendingCount;
  final int failedCount;
  final bool syncing;
}

abstract class MailRepository {
  Future<List<MailAccount>> listAccounts();
  Future<List<MailFolder>> listFolders({String? accountId});
  Future<MailFolder?> getFolder(String id);
  Future<void> upsertFolders(List<MailFolder> folders);
  Future<List<MailMessage>> listMessages(MessageQuery query);
  Future<MailMessage?> getMessage(String id);
  Future<List<FocusRule>> listFocusRules({String? accountId}) async {
    return const <FocusRule>[];
  }

  Future<void> upsertFocusRule(FocusRule rule) {
    throw UnsupportedError(
      'Focus rule persistence is not implemented by this repository.',
    );
  }

  /// Removes a single Focus override rule by id (TC-4).
  Future<void> deleteFocusRule(String id) {
    throw UnsupportedError(
      'Focus rule persistence is not implemented by this repository.',
    );
  }

  /// Counts outbox rows in `queued` or `sending` (pending send work).
  Future<int> countQueuedOutbox();

  /// Counts outbox rows in `failed`.
  Future<int> countFailedOutbox();
  Future<String> syncStatusLabel();
  Stream<void> watchChanges();
  Future<void> upsertAccount(
    MailAccount account, {
    required String providerType,
    bool focusEnabled,
  });
  /// Inserts or updates messages. Returns newly inserted unread messages
  /// (existing row was null and stored unread after DEF-007 merge).
  Future<List<MailMessage>> upsertMessages(
    List<MailMessage> messages, {
    required String folderId,
  });
  Future<void> updateMessageBody(String messageId, String body);
  Future<void> updateMessageRawHeaders(String messageId, String rawHeaders);
  Future<void> updateMessageFocusBucket(String messageId, FocusBucket bucket);

  /// Re-scores persisted messages with [score] and updates changed focus buckets.
  ///
  /// Returns the number of rows whose bucket changed.
  Future<int> reclassifyFocusBuckets(
    FocusBucket Function(MailMessage message) score,
  );

  Future<List<MailMessage>> searchLocal(String query);
  Future<String> enqueueOutbox({
    required String accountId,
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
    String composeMode = 'new',
    String? inReplyTo,
    String? referencesJson,
    String? attachmentRefsJson,
    String? signatureId,
    int? sendAfter,
    String state = 'queued',
  });
  Future<List<OutboxItem>> listOutbox();
  Future<void> updateOutboxState(String id, String state, {String? error});

  /// Replaces draft/outbox content fields (used for autosave + schedule edits).
  Future<void> updateOutboxContent(
    String id, {
    String? to,
    String? subject,
    String? body,
    String? cc,
    String? bcc,
    String? composeMode,
    String? inReplyTo,
    String? referencesJson,
    String? attachmentRefsJson,
    String? signatureId,
    int? sendAfter,
    bool clearSendAfter = false,
  }) async {}

  /// Removes a single outbox row (discard queued/failed/sent).
  Future<void> deleteOutbox(String id);

  /// Deletes outbox rows whose [state] is in [states]. Returns rows removed.
  Future<int> deleteOutboxInStates(Iterable<String> states);

  // --- Compose assets (signatures / templates / outbound blobs) ---

  Future<List<MailSignature>> listSignatures(String accountId) async =>
      const <MailSignature>[];

  Future<MailSignature?> getSignature(String id) async => null;

  Future<String> upsertSignature(MailSignature signature) async =>
      signature.id;

  Future<void> deleteSignature(String id) async {}

  Future<List<MailSignatureAsset>> listSignatureAssets(
    String signatureId,
  ) async =>
      const <MailSignatureAsset>[];

  Future<String> addSignatureAsset({
    required String signatureId,
    required String sourcePath,
    required String mimeType,
    String? contentId,
  }) async =>
      '';

  Future<List<MailTemplate>> listTemplates({String? accountId}) async =>
      const <MailTemplate>[];

  Future<String> upsertTemplate(MailTemplate template) async => template.id;

  Future<void> deleteTemplate(String id) async {}

  // --- Custom themes (UI-P16) ---

  Future<List<CustomTheme>> listCustomThemes() async =>
      const <CustomTheme>[];

  Future<CustomTheme?> getCustomTheme(String id) async => null;

  Future<String> upsertCustomTheme(CustomTheme theme) async => theme.id;

  Future<void> deleteCustomTheme(String id) async {}

  Future<OutboundBlobRef> stageAttachmentBlob({
    required String accountId,
    required String sourcePath,
    String? fileName,
  }) {
    throw UnsupportedError('Attachment staging is not implemented.');
  }

  Future<OutboundBlobRef?> getAttachmentBlob(String id) async => null;

  Future<void> deleteAttachmentBlob(String id) async {}

  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  });

  /// Recent sync jobs newest-first (pending/running/done/failed).
  Future<List<SyncJob>> listSyncJobs({int limit = 50}) async {
    return const <SyncJob>[];
  }

  /// Re-queues a failed job as `pending`, or re-enqueues the same type if done.
  Future<void> retrySyncJob(String id) async {}

  /// Cancels a `pending` job (deletes the row). No-op for other statuses.
  Future<void> cancelSyncJob(String id) async {}

  /// Per-account pending/failed/running counts plus last success/error.
  Future<List<AccountSyncHealth>> listAccountSyncHealth() async {
    return const <AccountSyncHealth>[];
  }

  /// True when a job of [type] is already `pending` or `running`.
  Future<bool> hasIncompleteJobOfType(String type);

  /// Reset orphaned `running` jobs so a new kick can claim them again.
  Future<int> reclaimRunningJobs();

  /// Reset stuck outbox rows left in `sending` back to `queued`.
  Future<int> reclaimSendingOutbox();

  Future<List<SyncJob>> claimPendingJobs({int limit});
  Future<void> completeJob(
    String id, {
    required bool success,
    String? cursorJson,
    String? error,
  });
  Future<void> setCursor(
    String accountId,
    String folderId,
    String key,
    String value,
  );
  Future<String?> getCursor(String accountId, String folderId, String key);
  Future<int> applyRetention({
    required int retentionDays,
    String? accountId,
  });

  Future<List<SyncProfile>> listSyncProfiles();
  Future<SyncProfile?> getSyncProfile(String id);
  Future<SyncProfile?> getDefaultSyncProfile();
  Future<void> upsertSyncProfile(SyncProfile profile);

  /// Resolves retention/folder/body/attachment policy for [accountId].
  ///
  /// Retention precedence: account override → profile → [fallbackRetentionDays].
  Future<ResolvedSyncPolicy> resolvePolicy(
    String accountId, {
    int fallbackRetentionDays = 180,
  });

  Future<void> setPinned(String messageId, bool pinned);
  Future<void> setPinnedBulk(List<String> ids, bool pinned);

  /// Sets or clears local-only snooze. Pass `null` to clear.
  Future<void> setSnoozed(String messageId, int? snoozedUntil);
  Future<void> setSnoozedBulk(List<String> ids, int? snoozedUntil);

  /// Earliest future [MailMessage.snoozedUntil] across all messages, or null.
  Future<int?> nextSnoozeExpiryMs({int? nowMs});

  /// Clears [MailMessage.snoozedUntil] when it is ≤ now. Returns rows updated.
  Future<int> clearExpiredSnoozes({int? nowMs});

  Future<void> setStarred(String messageId, bool starred);
  Future<void> setUnread(String messageId, bool unread);
  Future<void> setUnreadBulk(List<String> ids, bool unread);

  /// Recomputes folder unread badges from local messages.
  ///
  /// Counts unread, non-draft, non-trashed messages that are not actively
  /// snoozed. Optional [accountId] scopes the recount.
  Future<void> recountUnreadCounts({String? accountId}) async {}

  /// Resolves a well-known folder for [accountId] by role alias.
  ///
  /// Canonical roles: `trash`, `junk`, `archive`, `inbox`.
  /// Accepts aliases such as `deleteditems`/`deleted` → trash and
  /// `junkemail`/`spam` → junk. Falls back to folder-name heuristics when
  /// [MailFolder.role] is empty.
  Future<MailFolder?> resolveFolderByRole(String accountId, String role);

  /// Moves a single message locally; see [moveMessagesLocal].
  Future<void> moveMessageLocal(
    String messageId,
    String folderId, {
    int? trashedAt,
    bool clearTrashedAt = false,
  });

  /// Moves messages to [folderId], optionally setting or clearing [trashedAt].
  /// Recomputes folder unread badges from local messages afterward.
  Future<void> moveMessagesLocal(
    List<String> messageIds,
    String folderId, {
    int? trashedAt,
    bool clearTrashedAt = false,
  });

  /// Permanently deletes a local message row (attachments + FTS via triggers).
  Future<void> hardDeleteLocal(String messageId);

  /// Permanently deletes local message rows in bulk.
  Future<void> hardDeleteLocalBulk(List<String> ids);

  /// Messages with [MailMessage.trashedAt] set whose age is ≥ [retentionDays].
  Future<List<MailMessage>> listTrashedPastRetention({
    required int retentionDays,
    DateTime? now,
  });

  Future<void> upsertWidgetSnapshot(String id, String kind, String payloadJson);
  Future<String?> getWidgetSnapshot(String id);
  Future<void> wipeAccount(String accountId);
  Future<String> exportDiagnosticsRedacted();
  Future<void> seedDemoDataIfEmpty();
}
