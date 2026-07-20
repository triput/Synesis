import 'dart:async';

import 'package:bytemail/compose/account_signature.dart';
import 'package:bytemail/domain/address_match_scope.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/mailbox/message_action_service.dart';
import 'package:bytemail/mailbox/message_body_cache.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/theme/custom_theme.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _RecordingRepo implements MailRepository {
  _RecordingRepo({List<MailMessage>? messages, List<MailFolder>? folders})
    : _messages = List<MailMessage>.from(messages ?? <MailMessage>[message]),
      _folders = List<MailFolder>.from(
        folders ?? <MailFolder>[inbox, archive, trash, junk],
      );

  bool throwOnSetUnreadBulk = false;
  int setUnreadBulkCalls = 0;
  List<String>? lastUnreadBulkIds;
  bool? lastUnreadBulkValue;
  String? lastRawHeadersMessageId;
  String? lastRawHeadersValue;
  int setStarredCalls = 0;
  String? lastStarredMessageId;
  bool? lastStarredValue;
  int setPinnedBulkCalls = 0;
  List<String>? lastPinnedBulkIds;
  bool? lastPinnedBulkValue;
  int setSnoozedBulkCalls = 0;
  List<String>? lastSnoozedBulkIds;
  int? lastSnoozedBulkValue;
  int moveMessagesLocalCalls = 0;
  List<String>? lastMovedIds;
  String? lastMovedFolderId;
  int? lastMovedTrashedAt;
  bool lastMovedClearTrashedAt = false;
  final List<String> hardDeletedIds = <String>[];
  final List<Map<String, String?>> enqueuedJobs = <Map<String, String?>>[];
  final List<FocusRule> _focusRules = <FocusRule>[];
  FocusRule? lastUpsertedFocusRule;
  List<MailMessage> _messages;
  List<MailFolder> _folders;

  static const MailAccount account = MailAccount(
    id: 'work',
    label: 'W',
    address: 'work@byte.io',
    accent: Color(0xFF2DD4BF),
  );

  static const MailFolder inbox = MailFolder(
    id: 'inbox-work',
    accountId: 'work',
    name: 'Inbox',
    remoteId: 'INBOX',
    role: 'inbox',
    unreadCount: 1,
  );

  static const MailFolder archive = MailFolder(
    id: 'archive-work',
    accountId: 'work',
    name: 'Archive',
    remoteId: 'Archive',
    role: 'archive',
    unreadCount: 0,
  );

  static const MailFolder trash = MailFolder(
    id: 'trash-work',
    accountId: 'work',
    name: 'Trash',
    remoteId: 'Trash',
    role: 'trash',
    unreadCount: 0,
  );

  static const MailFolder junk = MailFolder(
    id: 'junk-work',
    accountId: 'work',
    name: 'Junk',
    remoteId: 'Junk',
    role: 'junk',
    unreadCount: 0,
  );

  static const MailMessage message = MailMessage(
    id: 'msg-1',
    accountId: 'work',
    fromName: 'Maya',
    fromAddress: 'maya@byte.io',
    subject: 'Hello',
    snippet: 'Snippet',
    body: 'Body',
    whenLabel: '10:14',
    bucket: FocusBucket.focused,
    unread: true,
    folderId: 'inbox-work',
    providerId: '101',
  );

  static const MailMessage messageTwo = MailMessage(
    id: 'msg-2',
    accountId: 'work',
    fromName: 'Jon',
    fromAddress: 'jon@byte.io',
    subject: 'Second',
    snippet: 'Snippet 2',
    body: 'Body 2',
    whenLabel: '10:15',
    bucket: FocusBucket.focused,
    unread: false,
    folderId: 'inbox-work',
    providerId: '102',
  );

  static const MailMessage messageThree = MailMessage(
    id: 'msg-3',
    accountId: 'work',
    fromName: 'Ada',
    fromAddress: 'ada@byte.io',
    subject: 'Third',
    snippet: 'Snippet 3',
    body: 'Body 3',
    whenLabel: '10:16',
    bucket: FocusBucket.focused,
    unread: false,
    folderId: 'inbox-work',
    providerId: '103',
  );

  @override
  Future<int> applyRetention({
    required int retentionDays,
    String? accountId,
  }) async => 0;

  @override
  Future<List<SyncProfile>> listSyncProfiles() async => const <SyncProfile>[];

  @override
  Future<SyncProfile?> getSyncProfile(String id) async => null;

  @override
  Future<SyncProfile?> getDefaultSyncProfile() async => null;

  @override
  Future<void> upsertSyncProfile(SyncProfile profile) async {}

  @override
  Future<ResolvedSyncPolicy> resolvePolicy(
    String accountId, {
    int fallbackRetentionDays = 180,
  }) async =>
      ResolvedSyncPolicy(
        accountId: accountId,
        profileId: 'default',
        retentionDays: fallbackRetentionDays,
        bodyPolicy: BodyFetchPolicy.onOpen,
        attachmentMaxMb: 25,
      );

  @override
  Future<List<SyncJob>> listSyncJobs({int limit = 50}) async =>
      const <SyncJob>[];

  @override
  Future<void> retrySyncJob(String id) async {}

  @override
  Future<void> cancelSyncJob(String id) async {}

  @override
  Future<List<AccountSyncHealth>> listAccountSyncHealth() async =>
      const <AccountSyncHealth>[];

  @override
  Future<List<SyncJob>> claimPendingJobs({int limit = 10}) async => const [];

  @override
  Future<int> reclaimRunningJobs() async => 0;

  @override
  Future<int> reclaimSendingOutbox() async => 0;

  @override
  Future<void> completeJob(
    String id, {
    required bool success,
    String? cursorJson,
    String? error,
  }) async {}

  @override
  Future<int> countQueuedOutbox() async => 0;

  @override
  Future<int> countFailedOutbox() async => 0;

  @override
  Future<int> reclassifyFocusBuckets(
    FocusBucket Function(MailMessage message) score,
  ) async {
    int changed = 0;
    for (int i = 0; i < _messages.length; i++) {
      final FocusBucket next = score(_messages[i]);
      if (next == _messages[i].bucket) {
        continue;
      }
      _messages[i] = _messages[i].copyWith(bucket: next);
      changed += 1;
    }
    return changed;
  }

  @override
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
  }) async => 'out-1';

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {
    enqueuedJobs.add(<String, String?>{
      'accountId': accountId,
      'type': type,
      'payloadJson': payloadJson,
    });
  }

  @override
  Future<bool> hasIncompleteJobOfType(String type) async =>
      enqueuedJobs.any((Map<String, String?> job) => job['type'] == type);

  @override
  Future<String> exportDiagnosticsRedacted() async => '{}';

  @override
  Future<String?> getCursor(
    String accountId,
    String folderId,
    String key,
  ) async => null;

  @override
  Future<MailMessage?> getMessage(String id) async {
    for (final MailMessage message in _messages) {
      if (message.id == id) {
        return message;
      }
    }
    return null;
  }

  @override
  Future<String?> getWidgetSnapshot(String id) async => null;

  @override
  Future<List<MailAccount>> listAccounts() async => const [account];

  @override
  Future<List<MailFolder>> listFolders({String? accountId}) async {
    if (accountId == null) {
      return List<MailFolder>.from(_folders);
    }
    return _folders
        .where((MailFolder folder) => folder.accountId == accountId)
        .toList(growable: false);
  }

  @override
  Future<MailFolder?> getFolder(String id) async {
    for (final MailFolder folder in _folders) {
      if (folder.id == id) {
        return folder;
      }
    }
    return null;
  }

  @override
  Future<void> upsertFolders(List<MailFolder> folders) async {
    for (final MailFolder folder in folders) {
      final int index = _folders.indexWhere(
        (MailFolder existing) => existing.id == folder.id,
      );
      if (index >= 0) {
        _folders[index] = folder;
      } else {
        _folders.add(folder);
      }
    }
  }

  MessageQuery? lastQuery;

  @override
  Future<List<MailMessage>> listMessages(MessageQuery query) async {
    lastQuery = query;
    return query.apply(_messages);
  }

  @override
  Future<List<OutboxItem>> listOutbox() async => const [];

  @override
  Future<List<MailMessage>> searchLocal(String query) async => const [];

  @override
  Future<void> seedDemoDataIfEmpty() async {}

  @override
  Future<void> setCursor(
    String accountId,
    String folderId,
    String key,
    String value,
  ) async {}

  @override
  Future<void> setPinned(String messageId, bool pinned) async {
    await setPinnedBulk(<String>[messageId], pinned);
  }

  @override
  Future<void> setPinnedBulk(List<String> ids, bool pinned) async {
    setPinnedBulkCalls++;
    lastPinnedBulkIds = ids;
    lastPinnedBulkValue = pinned;
    for (final String id in ids) {
      final int index = _messages.indexWhere(
        (MailMessage message) => message.id == id,
      );
      if (index >= 0) {
        _messages[index] = _messages[index].copyWith(pinned: pinned);
      }
    }
  }

  @override
  Future<void> setSnoozed(String messageId, int? snoozedUntil) async {
    await setSnoozedBulk(<String>[messageId], snoozedUntil);
  }

  @override
  Future<void> setSnoozedBulk(List<String> ids, int? snoozedUntil) async {
    setSnoozedBulkCalls++;
    lastSnoozedBulkIds = ids;
    lastSnoozedBulkValue = snoozedUntil;
    for (final String id in ids) {
      final int index = _messages.indexWhere(
        (MailMessage message) => message.id == id,
      );
      if (index < 0) {
        continue;
      }
      if (snoozedUntil == null) {
        _messages[index] = _messages[index].copyWith(clearSnoozedUntil: true);
      } else {
        _messages[index] = _messages[index].copyWith(
          snoozedUntil: snoozedUntil,
        );
      }
    }
  }

  @override
  Future<int?> nextSnoozeExpiryMs({int? nowMs}) async {
    final int now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    int? next;
    for (final MailMessage message in _messages) {
      final int? until = message.snoozedUntil;
      if (until == null || until <= now) {
        continue;
      }
      if (next == null || until < next) {
        next = until;
      }
    }
    return next;
  }

  @override
  Future<int> clearExpiredSnoozes({int? nowMs}) async {
    final int now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    int cleared = 0;
    for (int i = 0; i < _messages.length; i++) {
      final int? until = _messages[i].snoozedUntil;
      if (until != null && until <= now) {
        _messages[i] = _messages[i].copyWith(clearSnoozedUntil: true);
        cleared++;
      }
    }
    return cleared;
  }

  @override
  Future<void> setStarred(String messageId, bool starred) async {
    setStarredCalls++;
    lastStarredMessageId = messageId;
    lastStarredValue = starred;
    final int index = _messages.indexWhere(
      (MailMessage message) => message.id == messageId,
    );
    if (index >= 0) {
      _messages[index] = _messages[index].copyWith(starred: starred);
    }
  }

  @override
  Future<MailFolder?> resolveFolderByRole(String accountId, String role) async {
    final String normalized = role.trim().toLowerCase();
    String canonical = normalized;
    if (normalized == 'deleteditems' || normalized == 'deleted') {
      canonical = 'trash';
    } else if (normalized == 'junkemail' || normalized == 'spam') {
      canonical = 'junk';
    }
    for (final MailFolder folder in _folders) {
      if (folder.accountId == accountId && folder.role == canonical) {
        return folder;
      }
    }
    return null;
  }

  @override
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

  @override
  Future<void> moveMessagesLocal(
    List<String> messageIds,
    String folderId, {
    int? trashedAt,
    bool clearTrashedAt = false,
  }) async {
    moveMessagesLocalCalls++;
    lastMovedIds = List<String>.from(messageIds);
    lastMovedFolderId = folderId;
    lastMovedTrashedAt = trashedAt;
    lastMovedClearTrashedAt = clearTrashedAt;
    for (int i = 0; i < _messages.length; i++) {
      if (!messageIds.contains(_messages[i].id)) {
        continue;
      }
      _messages[i] = _messages[i].copyWith(
        folderId: folderId,
        trashedAt: trashedAt,
        clearTrashedAt: clearTrashedAt,
      );
    }
  }

  @override
  Future<void> hardDeleteLocal(String messageId) async {
    await hardDeleteLocalBulk(<String>[messageId]);
  }

  @override
  Future<void> hardDeleteLocalBulk(List<String> ids) async {
    hardDeletedIds.addAll(ids);
    _messages.removeWhere((MailMessage message) => ids.contains(message.id));
  }

  @override
  Future<List<MailMessage>> listTrashedPastRetention({
    required int retentionDays,
    DateTime? now,
  }) async => const <MailMessage>[];

  @override
  Future<void> setUnread(String messageId, bool unread) async {
    await setUnreadBulk(<String>[messageId], unread);
  }

  @override
  Future<void> setUnreadBulk(List<String> ids, bool unread) async {
    setUnreadBulkCalls++;
    lastUnreadBulkIds = List<String>.from(ids);
    lastUnreadBulkValue = unread;
    if (throwOnSetUnreadBulk) {
      throw StateError('database unavailable');
    }
    for (int i = 0; i < _messages.length; i++) {
      final MailMessage current = _messages[i];
      if (!ids.contains(current.id) || current.unread == unread) {
        continue;
      }
      _messages[i] = current.copyWith(unread: unread);
      final int delta = unread ? 1 : -1;
      final String? folderId = current.folderId;
      if (folderId == null) {
        continue;
      }
      final int folderIndex = _folders.indexWhere(
        (MailFolder folder) => folder.id == folderId,
      );
      if (folderIndex < 0) {
        continue;
      }
      final MailFolder folder = _folders[folderIndex];
      _folders[folderIndex] = MailFolder(
        id: folder.id,
        accountId: folder.accountId,
        name: folder.name,
        remoteId: folder.remoteId,
        role: folder.role,
        parentRemoteId: folder.parentRemoteId,
        unreadCount: ((folder.unreadCount ?? 0) + delta).clamp(0, 1 << 30),
        totalCount: folder.totalCount,
      );
    }
  }

  @override
  Future<void> recountUnreadCounts({String? accountId}) async {}

  @override
  Future<String> syncStatusLabel() async => 'Synced · test';

  @override
  Future<void> updateOutboxState(
    String id,
    String state, {
    String? error,
  }) async {}

  @override
  Future<void> deleteOutbox(String id) async {}

  @override
  Future<int> deleteOutboxInStates(Iterable<String> states) async => 0;

  @override
  Future<void> upsertAccount(
    MailAccount account, {
    required String providerType,
    bool focusEnabled = true,
  }) async {}

  @override
  Future<List<MailMessage>> upsertMessages(
    List<MailMessage> messages, {
    required String folderId,
  }) async =>
      const <MailMessage>[];

  @override
  Future<void> updateMessageBody(String messageId, String body) async {}

  @override
  Future<void> updateMessageRawHeaders(
    String messageId,
    String rawHeaders,
  ) async {
    lastRawHeadersMessageId = messageId;
    lastRawHeadersValue = rawHeaders;
    final int index = _messages.indexWhere(
      (MailMessage message) => message.id == messageId,
    );
    if (index >= 0) {
      _messages[index] = _messages[index].copyWith(rawHeaders: rawHeaders);
    }
  }

  @override
  Future<void> updateMessageFocusBucket(
    String messageId,
    FocusBucket bucket,
  ) async {
    final int index = _messages.indexWhere(
      (MailMessage message) => message.id == messageId,
    );
    if (index >= 0) {
      _messages[index] = _messages[index].copyWith(bucket: bucket);
    }
  }

  @override
  Future<void> upsertWidgetSnapshot(
    String id,
    String kind,
    String payloadJson,
  ) async {}

  @override
  Stream<void> watchChanges() => const Stream<void>.empty();

  @override
  Future<void> wipeAccount(String accountId) async {}

  @override
  Future<List<FocusRule>> listFocusRules({String? accountId}) async {
    if (accountId == null) {
      return List<FocusRule>.from(_focusRules);
    }
    return _focusRules
        .where(
          (FocusRule rule) =>
              rule.accountId == null || rule.accountId == accountId,
        )
        .toList(growable: false);
  }

  @override
  Future<void> upsertFocusRule(FocusRule rule) async {
    lastUpsertedFocusRule = rule;
    _focusRules.removeWhere((FocusRule existing) => existing.id == rule.id);
    _focusRules.add(rule);
  }

  @override
  Future<void> deleteFocusRule(String id) async {
    _focusRules.removeWhere((FocusRule existing) => existing.id == id);
  }

  @override
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

  // --- Compose assets (signatures / templates / outbound blobs) ---

  @override
  Future<List<MailSignature>> listSignatures(String accountId) async =>
      const <MailSignature>[];

  @override
  Future<MailSignature?> getSignature(String id) async => null;

  @override
  Future<String> upsertSignature(MailSignature signature) async =>
      signature.id;

  @override
  Future<void> deleteSignature(String id) async {}

  @override
  Future<List<MailSignatureAsset>> listSignatureAssets(
    String signatureId,
  ) async => const <MailSignatureAsset>[];

  @override
  Future<String> addSignatureAsset({
    required String signatureId,
    required String sourcePath,
    required String mimeType,
    String? contentId,
  }) async => '';

  @override
  Future<List<MailTemplate>> listTemplates({String? accountId}) async =>
      const <MailTemplate>[];

  @override
  Future<String> upsertTemplate(MailTemplate template) async => template.id;

  @override
  Future<void> deleteTemplate(String id) async {}

  @override
  Future<OutboundBlobRef> stageAttachmentBlob({
    required String accountId,
    required String sourcePath,
    String? fileName,
  }) {
    throw UnsupportedError('Attachment staging is not implemented.');
  }

  @override
  Future<OutboundBlobRef?> getAttachmentBlob(String id) async => null;

  @override
  Future<void> deleteAttachmentBlob(String id) async {}

  // --- Custom themes (UI-P16) ---

  @override
  Future<List<CustomTheme>> listCustomThemes() async =>
      const <CustomTheme>[];

  @override
  Future<CustomTheme?> getCustomTheme(String id) async => null;

  @override
  Future<String> upsertCustomTheme(CustomTheme theme) async => theme.id;

  @override
  Future<void> deleteCustomTheme(String id) async {}
}

class _ThrowingHeaderProvider extends MailProvider {
  _ThrowingHeaderProvider(this.message);

  final String message;

  @override
  MailCapabilities get capabilities => const MailCapabilities(
    supportsServerSearch: false,
    supportsPush: false,
    supportsPartialBody: true,
    supportsSend: false,
  );

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> fetchBody(
    String providerId, {
    String? folderRemoteId,
  }) async => null;

  @override
  Future<String?> fetchHeaders(
    String providerId, {
    String? folderRemoteId,
  }) async {
    throw Exception(message);
  }

  @override
  Future<List<RemoteFolder>> listFolders() async => const [];

  @override
  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50}) async =>
      const [];

  @override
  Future<List<RemoteMessageHeader>> listRecentInFolder(
    String folderRemoteId, {
    int limit = 50,
  }) async => const [];

  @override
  Future<List<RemoteMessageHeader>> searchRemote(String query) async =>
      const [];

  @override
  Future<void> send({
    required List<String> to,
    List<String> cc = const <String>[],
    List<String> bcc = const <String>[],
    required String subject,
    required String body,
  }) async {}

  @override
  Future<void> setRead(
    String providerId, {
    required bool isRead,
    String? folderRemoteId,
  }) async {}
}

class _CreateFolderProvider extends MailProvider {
  int createCalls = 0;
  String? lastDisplayName;
  String? lastRole;

  @override
  MailCapabilities get capabilities => const MailCapabilities(
    supportsServerSearch: false,
    supportsPush: false,
    supportsPartialBody: false,
    supportsSend: false,
    supportsMove: true,
  );

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> fetchBody(
    String providerId, {
    String? folderRemoteId,
  }) async => null;

  @override
  Future<String?> fetchHeaders(
    String providerId, {
    String? folderRemoteId,
  }) async => null;

  @override
  Future<List<RemoteFolder>> listFolders() async => const <RemoteFolder>[];

  @override
  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50}) async =>
      const <RemoteMessageHeader>[];

  @override
  Future<List<RemoteMessageHeader>> listRecentInFolder(
    String folderRemoteId, {
    int limit = 50,
  }) async => const <RemoteMessageHeader>[];

  @override
  Future<List<RemoteMessageHeader>> searchRemote(String query) async =>
      const <RemoteMessageHeader>[];

  @override
  Future<void> send({
    required List<String> to,
    List<String> cc = const <String>[],
    List<String> bcc = const <String>[],
    required String subject,
    required String body,
  }) async {}

  @override
  Future<void> setRead(
    String providerId, {
    required bool isRead,
    String? folderRemoteId,
  }) async {}

  @override
  Future<RemoteFolder> createFolder({
    required String displayName,
    String? role,
  }) async {
    createCalls += 1;
    lastDisplayName = displayName;
    lastRole = role;
    return RemoteFolder(
      providerId: displayName,
      name: displayName,
      role: role,
    );
  }

  @override
  Future<void> moveMessage(
    String providerMessageId,
    String targetFolderRemoteId, {
    String? sourceFolderRemoteId,
  }) async {}
}

class _HeaderStubProvider extends MailProvider {
  _HeaderStubProvider(this.headers);

  final String headers;

  @override
  MailCapabilities get capabilities => const MailCapabilities(
    supportsServerSearch: false,
    supportsPush: false,
    supportsPartialBody: true,
    supportsSend: false,
  );

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> fetchBody(
    String providerId, {
    String? folderRemoteId,
  }) async => null;

  @override
  Future<String?> fetchHeaders(
    String providerId, {
    String? folderRemoteId,
  }) async => headers;

  @override
  Future<List<RemoteFolder>> listFolders() async => const [];

  @override
  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50}) async =>
      const [];

  @override
  Future<List<RemoteMessageHeader>> listRecentInFolder(
    String folderRemoteId, {
    int limit = 50,
  }) async => const [];

  @override
  Future<List<RemoteMessageHeader>> searchRemote(String query) async =>
      const [];

  @override
  Future<void> send({
    required List<String> to,
    List<String> cc = const <String>[],
    List<String> bcc = const <String>[],
    required String subject,
    required String body,
  }) async {}

  @override
  Future<void> setRead(
    String providerId, {
    required bool isRead,
    String? folderRemoteId,
  }) async {}
}

Future<MailboxCubit> _buildCubit({
  required _RecordingRepo repo,
  required SharedPreferences prefs,
  ProviderResolver? resolveProvider,
  SystemFolderConfirm? onConfirmCreateSystemFolder,
}) async {
  final ProviderResolver resolver = resolveProvider ?? (_) async => null;
  final MessageActionService actions = MessageActionService(
    repository: repo,
    resolveProvider: resolver,
    onConfirmCreateSystemFolder: onConfirmCreateSystemFolder,
  );
  final MessageBodyCache bodyCache = MessageBodyCache(
    repository: repo,
    resolveProvider: resolver,
  );
  final MailboxCubit cubit = MailboxCubit(
    repository: repo,
    settingsCubit: AppSettingsCubit(prefs),
    actions: actions,
    bodyCache: bodyCache,
    onConfirmCreateSystemFolder: onConfirmCreateSystemFolder,
  );
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return cubit;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MailboxCubit mark read/unread', () {
    late _RecordingRepo repo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = _RecordingRepo();
    });

    test('refresh builds MessageQuery with default exclusions', () async {
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      expect(repo.lastQuery, isNotNull);
      expect(repo.lastQuery!.excludeSnoozed, isTrue);
      expect(repo.lastQuery!.includeDrafts, isFalse);
      expect(repo.lastQuery!.includeTrashed, isFalse);
      expect(repo.lastQuery!.starredOnly, isFalse);
      await cubit.close();
    });

    test(
      'setUnreadBulk optimistically marks messages read and updates folder count',
      () async {
        final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
        await cubit.setUnreadBulk(const <String>['msg-1'], false);
        expect(cubit.state.messages.first.unread, isFalse);
        expect(cubit.state.folders.first.unreadCount, 0);
        expect(repo.setUnreadBulkCalls, 1);
        expect(repo.lastUnreadBulkIds, const <String>['msg-1']);
        expect(repo.lastUnreadBulkValue, isFalse);
        await cubit.close();
      },
    );

    test('rolls back optimistic state when repository write fails', () async {
      repo.throwOnSetUnreadBulk = true;
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      await cubit.setUnreadBulk(const <String>['msg-1'], false);
      expect(cubit.state.messages.first.unread, isTrue);
      expect(cubit.state.errorMessage, contains('Could not save read state'));
      await cubit.close();
    });

    test('toggleSelectedUnread flips selected message unread state', () async {
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          selectedMessageId: 'msg-1',
          messages: const <MailMessage>[_RecordingRepo.message],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );
      await cubit.toggleSelectedUnread();
      expect(cubit.state.messages.first.unread, isFalse);
      await cubit.close();
    });

    test('toggleSelectedUnread marks mixed bulk selection all read', () async {
      const MailMessage second = MailMessage(
        id: 'msg-2',
        accountId: 'work',
        fromName: 'Bob',
        fromAddress: 'bob@example.com',
        subject: 'Second',
        snippet: 'Hi',
        body: 'Hi',
        whenLabel: 'Today',
        bucket: FocusBucket.focused,
        unread: false,
        folderId: 'folder-inbox',
      );
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          selectedMessageId: 'msg-1',
          selectedMessageIds: const <String>{'msg-1', 'msg-2'},
          messages: const <MailMessage>[_RecordingRepo.message, second],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );
      await cubit.toggleSelectedUnread();
      expect(
        cubit.state.messages.map((MailMessage m) => m.unread),
        everyElement(isFalse),
      );
      expect(repo.setUnreadBulkCalls, 1);
      expect(repo.lastUnreadBulkIds, <String>['msg-1', 'msg-2']);
      expect(repo.lastUnreadBulkValue, isFalse);
      await cubit.close();
    });

    test('toggleSelectedUnread marks all-read bulk selection unread', () async {
      const MailMessage first = MailMessage(
        id: 'msg-1',
        accountId: 'work',
        fromName: 'Ada',
        fromAddress: 'ada@example.com',
        subject: 'Hello',
        snippet: 'Hi',
        body: 'Hi',
        whenLabel: 'Today',
        bucket: FocusBucket.focused,
        unread: false,
        folderId: 'folder-inbox',
      );
      const MailMessage second = MailMessage(
        id: 'msg-2',
        accountId: 'work',
        fromName: 'Bob',
        fromAddress: 'bob@example.com',
        subject: 'Second',
        snippet: 'Hi',
        body: 'Hi',
        whenLabel: 'Today',
        bucket: FocusBucket.focused,
        unread: false,
        folderId: 'folder-inbox',
      );
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          selectedMessageId: 'msg-1',
          selectedMessageIds: const <String>{'msg-1', 'msg-2'},
          messages: const <MailMessage>[first, second],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );
      await cubit.toggleSelectedUnread();
      expect(
        cubit.state.messages.map((MailMessage m) => m.unread),
        everyElement(isTrue),
      );
      expect(repo.lastUnreadBulkValue, isTrue);
      await cubit.close();
    });

    test('empty bulk selection is a no-op', () async {
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      await cubit.setUnreadBulk(const <String>[], false);
      expect(repo.setUnreadBulkCalls, 0);
      await cubit.close();
    });

    test(
      'onAccountRemoved clears selection when deleted account was active',
      () async {
        final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
        cubit.emit(
          cubit.state.copyWith(
            unified: false,
            accountId: 'work',
            folderId: 'inbox-work',
            selectedMessageId: 'msg-1',
            expandedAccountIds: const <String>{'work'},
          ),
        );
        await cubit.onAccountRemoved('work');
        expect(cubit.state.unified, isTrue);
        expect(cubit.state.accountId, isNull);
        expect(cubit.state.folderId, isNull);
        expect(cubit.state.selectedMessageId, isNull);
        expect(cubit.state.expandedAccountIds, isEmpty);
        await cubit.close();
      },
    );

    test(
      'onAccountRemoved clears unified selection for removed account messages',
      () async {
        const MailMessage personalMessage = MailMessage(
          id: 'msg-2',
          accountId: 'personal',
          fromName: 'Jon',
          fromAddress: 'jon@home.dev',
          subject: 'Hi',
          snippet: 'Snippet',
          body: 'Body',
          whenLabel: 'Yesterday',
          bucket: FocusBucket.focused,
        );
        final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
        cubit.emit(
          cubit.state.copyWith(
            unified: true,
            selectedMessageId: 'msg-1',
            messages: const <MailMessage>[
              _RecordingRepo.message,
              personalMessage,
            ],
          ),
        );
        await cubit.onAccountRemoved('work');
        expect(cubit.state.unified, isTrue);
        expect(cubit.state.selectedMessageId, isNull);
        await cubit.close();
      },
    );
  });

  group('MailboxCubit ensureHeadersCached', () {
    late _RecordingRepo repo;
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = _RecordingRepo();
    });

    test('fetches and caches raw headers from provider', () async {
      const String headers = 'From: a@byte.io\nTo: b@byte.io';
      final MailboxCubit cubit = await _buildCubit(
        repo: repo,
        prefs: prefs,
        resolveProvider: (_) async => _HeaderStubProvider(headers),
      );
      cubit.emit(
        cubit.state.copyWith(
          messages: const <MailMessage>[_RecordingRepo.message],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );
      await cubit.ensureHeadersCached('msg-1');
      expect(cubit.state.isLoadingHeaders, isFalse);
      expect(cubit.state.messages.first.rawHeaders, headers);
      expect(repo.lastRawHeadersMessageId, 'msg-1');
      expect(repo.lastRawHeadersValue, headers);
      await cubit.close();
    });

    test('skips provider fetch when headers already cached locally', () async {
      final MailboxCubit cubit = await _buildCubit(
        repo: repo,
        prefs: prefs,
        resolveProvider: (_) async => _HeaderStubProvider('should-not-run'),
      );
      const MailMessage cached = MailMessage(
        id: 'msg-1',
        accountId: 'work',
        fromName: 'Maya',
        fromAddress: 'maya@byte.io',
        subject: 'Hello',
        snippet: 'Snippet',
        body: 'Body',
        whenLabel: '10:14',
        bucket: FocusBucket.focused,
        unread: true,
        folderId: 'inbox-work',
        providerId: '101',
        rawHeaders: 'From: cached@byte.io',
      );
      cubit.emit(
        cubit.state.copyWith(
          messages: const <MailMessage>[cached],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );
      await cubit.ensureHeadersCached('msg-1');
      expect(cubit.state.isLoadingHeaders, isFalse);
      expect(repo.lastRawHeadersMessageId, isNull);
      await cubit.close();
    });

    test('unknown message id is a no-op', () async {
      final MailboxCubit cubit = await _buildCubit(
        repo: repo,
        prefs: prefs,
        resolveProvider: (_) async => _HeaderStubProvider('unused'),
      );
      await cubit.ensureHeadersCached('missing-id');
      expect(cubit.state.isLoadingHeaders, isFalse);
      expect(cubit.state.headersErrorMessage, isNull);
      await cubit.close();
    });

    test('fetch failure surfaces error without mutating messages', () async {
      final MailboxCubit cubit = await _buildCubit(
        repo: repo,
        prefs: prefs,
        resolveProvider: (_) async =>
            _ThrowingHeaderProvider('header fetch failed'),
      );
      cubit.emit(
        cubit.state.copyWith(
          messages: const <MailMessage>[_RecordingRepo.message],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );
      await cubit.ensureHeadersCached('msg-1');
      expect(cubit.state.isLoadingHeaders, isFalse);
      expect(cubit.state.headersErrorMessage, contains('header fetch failed'));
      expect(cubit.state.messages.first.rawHeaders, isNull);
      expect(repo.lastRawHeadersMessageId, isNull);
      await cubit.close();
    });

    test('empty server response is not retried in-session', () async {
      final MailboxCubit cubit = await _buildCubit(
        repo: repo,
        prefs: prefs,
        resolveProvider: (_) async => _HeaderStubProvider(''),
      );
      cubit.emit(
        cubit.state.copyWith(
          messages: const <MailMessage>[_RecordingRepo.message],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );
      await cubit.ensureHeadersCached('msg-1');
      expect(
        cubit.state.headersErrorMessage,
        'No raw headers were returned by the server.',
      );
      await cubit.ensureHeadersCached('msg-1');
      expect(repo.lastRawHeadersMessageId, isNull);
      await cubit.close();
    });
  });

  group('MailboxCubit ensureSystemFolder', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test('creates folder when confirm returns true', () async {
      final _RecordingRepo repo = _RecordingRepo(
        folders: const <MailFolder>[_RecordingRepo.inbox],
      );
      final _CreateFolderProvider provider = _CreateFolderProvider();
      final MailboxCubit cubit = await _buildCubit(
        repo: repo,
        prefs: prefs,
        resolveProvider: (_) async => provider,
        onConfirmCreateSystemFolder: (String accountId, String roleDisplayName) async {
          expect(accountId, 'work');
          expect(roleDisplayName, 'Trash');
          return true;
        },
      );

      final MailFolder? created = await cubit.ensureSystemFolder(
        accountId: 'work',
        role: 'trash',
      );

      expect(created, isNotNull);
      expect(created!.name, 'Trash');
      expect(created.role, 'trash');
      expect(provider.createCalls, 1);
      expect(provider.lastDisplayName, 'Trash');
      expect(provider.lastRole, 'trash');
      expect(
        cubit.state.folders.any((MailFolder folder) => folder.role == 'trash'),
        isTrue,
      );
      await cubit.close();
    });

    test('skips create when confirm is null', () async {
      final _RecordingRepo repo = _RecordingRepo(
        folders: const <MailFolder>[_RecordingRepo.inbox],
      );
      final _CreateFolderProvider provider = _CreateFolderProvider();
      final MailboxCubit cubit = await _buildCubit(
        repo: repo,
        prefs: prefs,
        resolveProvider: (_) async => provider,
      );

      final MailFolder? created = await cubit.ensureSystemFolder(
        accountId: 'work',
        role: 'trash',
      );

      expect(created, isNull);
      expect(provider.createCalls, 0);
      await cubit.close();
    });

    test('deleteSelected creates missing trash then moves', () async {
      final _RecordingRepo repo = _RecordingRepo(
        folders: const <MailFolder>[_RecordingRepo.inbox],
      );
      final _CreateFolderProvider provider = _CreateFolderProvider();
      final MailboxCubit cubit = await _buildCubit(
        repo: repo,
        prefs: prefs,
        resolveProvider: (_) async => provider,
        onConfirmCreateSystemFolder: (_, __) async => true,
      );
      cubit.emit(
        cubit.state.copyWith(
          selectedMessageId: 'msg-1',
          messages: const <MailMessage>[_RecordingRepo.message],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );

      await cubit.deleteSelected();

      expect(provider.createCalls, 1);
      expect(repo.moveMessagesLocalCalls, 1);
      expect(repo.lastMovedFolderId, isNotNull);
      await cubit.close();
    });
  });

  group('MailboxCubit message actions', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    test(
      'toggleStarSelected optimistically stars and persists via repo',
      () async {
        final _RecordingRepo repo = _RecordingRepo();
        final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
        cubit.emit(
          cubit.state.copyWith(
            selectedMessageId: 'msg-1',
            messages: const <MailMessage>[_RecordingRepo.message],
            folders: const <MailFolder>[_RecordingRepo.inbox],
          ),
        );
        await cubit.toggleStarSelected();
        expect(cubit.state.messages.first.starred, isTrue);
        expect(repo.setStarredCalls, 1);
        expect(repo.lastStarredMessageId, 'msg-1');
        expect(repo.lastStarredValue, isTrue);
        await cubit.close();
      },
    );

    test('togglePinSelected pins locally without sync jobs', () async {
      final _RecordingRepo repo = _RecordingRepo();
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          selectedMessageId: 'msg-1',
          messages: const <MailMessage>[_RecordingRepo.message],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );
      await cubit.togglePinSelected();
      expect(cubit.state.messages.first.pinned, isTrue);
      expect(repo.setPinnedBulkCalls, 1);
      expect(repo.lastPinnedBulkIds, <String>['msg-1']);
      expect(repo.lastPinnedBulkValue, isTrue);
      expect(repo.enqueuedJobs, isEmpty);
      await cubit.close();
    });

    test('snoozeSelected hides message until expiry then refresh shows it', () async {
      final int futureUntil =
          DateTime.now().add(const Duration(hours: 2)).millisecondsSinceEpoch;
      final _RecordingRepo repo = _RecordingRepo();
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          selectedMessageId: 'msg-1',
          messages: const <MailMessage>[_RecordingRepo.message],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );

      await cubit.snoozeSelected(snoozedUntil: futureUntil);

      expect(cubit.state.messages, isEmpty);
      expect(repo.setSnoozedBulkCalls, 1);
      expect(repo.lastSnoozedBulkIds, <String>['msg-1']);
      expect(repo.lastSnoozedBulkValue, futureUntil);
      expect(repo.enqueuedJobs, isEmpty);

      // Expire snooze locally and refresh — excludeSnoozed lets it resurface.
      await repo.setSnoozed('msg-1', 1);
      await cubit.refresh();
      expect(
        cubit.state.messages.any((MailMessage m) => m.id == 'msg-1'),
        isTrue,
      );
      await cubit.close();
    });

    test('deleteSelected moves out of list and advances selection', () async {
      final _RecordingRepo repo = _RecordingRepo(
        messages: const <MailMessage>[
          _RecordingRepo.message,
          _RecordingRepo.messageTwo,
          _RecordingRepo.messageThree,
        ],
      );
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          unified: false,
          accountId: 'work',
          folderId: 'inbox-work',
          selectedMessageId: 'msg-1',
          messages: const <MailMessage>[
            _RecordingRepo.message,
            _RecordingRepo.messageTwo,
            _RecordingRepo.messageThree,
          ],
          folders: const <MailFolder>[
            _RecordingRepo.inbox,
            _RecordingRepo.archive,
            _RecordingRepo.trash,
            _RecordingRepo.junk,
          ],
        ),
      );
      await cubit.deleteSelected();
      expect(cubit.state.messages.map((MailMessage m) => m.id), <String>[
        'msg-2',
        'msg-3',
      ]);
      expect(cubit.state.selectedMessageId, 'msg-2');
      expect(repo.moveMessagesLocalCalls, 1);
      expect(repo.lastMovedFolderId, 'trash-work');
      expect(repo.lastMovedTrashedAt, isNotNull);
      await cubit.close();
    });

    test('deleteSelected in trash permanently deletes locally', () async {
      final _RecordingRepo repo = _RecordingRepo(
        messages: const <MailMessage>[
          _RecordingRepo.message,
          _RecordingRepo.messageTwo,
        ],
      );
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          unified: false,
          accountId: 'work',
          folderId: 'trash-work',
          selectedMessageId: 'msg-1',
          messages: const <MailMessage>[
            _RecordingRepo.message,
            _RecordingRepo.messageTwo,
          ],
          folders: const <MailFolder>[
            _RecordingRepo.inbox,
            _RecordingRepo.trash,
          ],
        ),
      );

      await cubit.deleteSelected();

      expect(repo.hardDeletedIds, const <String>['msg-1']);
      expect(repo.moveMessagesLocalCalls, 0);
      expect(cubit.state.selectedMessageId, 'msg-2');
      await cubit.close();
    });

    test('bulk removal preserves an unremoved primary selection', () async {
      final _RecordingRepo repo = _RecordingRepo(
        messages: const <MailMessage>[
          _RecordingRepo.message,
          _RecordingRepo.messageTwo,
          _RecordingRepo.messageThree,
        ],
      );
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          unified: false,
          accountId: 'work',
          folderId: 'inbox-work',
          selectedMessageId: 'msg-1',
          selectedMessageIds: const <String>{'msg-2'},
          messages: const <MailMessage>[
            _RecordingRepo.message,
            _RecordingRepo.messageTwo,
            _RecordingRepo.messageThree,
          ],
          folders: const <MailFolder>[
            _RecordingRepo.inbox,
            _RecordingRepo.archive,
          ],
        ),
      );

      await cubit.archiveSelected();

      expect(cubit.state.selectedMessageId, 'msg-1');
      expect(
        cubit.state.messages.map((MailMessage message) => message.id),
        const <String>['msg-1', 'msg-3'],
      );
      await cubit.close();
    });

    test('reportJunk moves selected message to junk folder', () async {
      final _RecordingRepo repo = _RecordingRepo(
        messages: const <MailMessage>[
          _RecordingRepo.message,
          _RecordingRepo.messageTwo,
        ],
      );
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          unified: false,
          accountId: 'work',
          folderId: 'inbox-work',
          selectedMessageId: 'msg-1',
          messages: const <MailMessage>[
            _RecordingRepo.message,
            _RecordingRepo.messageTwo,
          ],
          folders: const <MailFolder>[
            _RecordingRepo.inbox,
            _RecordingRepo.archive,
            _RecordingRepo.trash,
            _RecordingRepo.junk,
          ],
        ),
      );
      await cubit.reportJunk();
      expect(cubit.state.messages.map((MailMessage m) => m.id), <String>[
        'msg-2',
      ]);
      expect(cubit.state.selectedMessageId, 'msg-2');
      expect(repo.lastMovedFolderId, 'junk-work');
      expect(repo.lastMovedIds, const <String>['msg-1']);
      await cubit.close();
    });

    test('notJunk moves selected message to inbox', () async {
      final MailMessage junked = _RecordingRepo.message.copyWith(
        folderId: 'junk-work',
      );
      final _RecordingRepo repo = _RecordingRepo(
        messages: <MailMessage>[junked],
        folders: const <MailFolder>[
          _RecordingRepo.inbox,
          _RecordingRepo.junk,
        ],
      );
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          unified: false,
          accountId: 'work',
          folderId: 'junk-work',
          selectedMessageId: 'msg-1',
          messages: <MailMessage>[junked],
          folders: const <MailFolder>[
            _RecordingRepo.inbox,
            _RecordingRepo.junk,
          ],
        ),
      );
      expect(cubit.isViewingJunk, isTrue);
      await cubit.notJunk();
      expect(repo.lastMovedFolderId, 'inbox-work');
      expect(repo.lastMovedIds, const <String>['msg-1']);
      await cubit.close();
    });

    test('markFocusBucket upserts sender rule and updates message', () async {
      final _RecordingRepo repo = _RecordingRepo(
        messages: const <MailMessage>[
          _RecordingRepo.message,
          _RecordingRepo.messageTwo,
        ],
      );
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          unified: false,
          accountId: 'work',
          folderId: 'inbox-work',
          selectedMessageId: 'msg-1',
          focusFilter: FocusBucket.focused,
          messages: const <MailMessage>[
            _RecordingRepo.message,
            _RecordingRepo.messageTwo,
          ],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );
      await cubit.markFocusBucket(FocusBucket.other);
      expect(repo.lastUpsertedFocusRule?.bucket, FocusBucket.other);
      expect(repo.lastUpsertedFocusRule?.matchType, FocusRuleMatchType.sender);
      expect(repo.lastUpsertedFocusRule?.pattern, 'maya@byte.io');
      final List<MailMessage> listed = await repo.listMessages(
        const MessageQuery(accountId: 'work', folderId: 'inbox-work'),
      );
      expect(
        listed.firstWhere((MailMessage m) => m.id == 'msg-1').bucket,
        FocusBucket.other,
      );
      await cubit.close();
    });

    test('markFocusBucket domain scope upserts domain rule', () async {
      final MailMessage news = _RecordingRepo.message.copyWith(
        id: 'msg-news',
        fromAddress: 'news@brand.com',
        fromName: 'Brand News',
      );
      final MailMessage promo = _RecordingRepo.message.copyWith(
        id: 'msg-promo',
        fromAddress: 'promo@brand.com',
        fromName: 'Brand Promo',
        subject: 'Sale',
      );
      final _RecordingRepo repo = _RecordingRepo(
        messages: <MailMessage>[news, promo],
      );
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          unified: false,
          accountId: 'work',
          folderId: 'inbox-work',
          selectedMessageId: 'msg-news',
          messages: <MailMessage>[news, promo],
          folders: const <MailFolder>[_RecordingRepo.inbox],
        ),
      );
      await cubit.markFocusBucket(
        FocusBucket.other,
        scope: AddressMatchScope.domain,
      );
      expect(repo.lastUpsertedFocusRule?.matchType, FocusRuleMatchType.domain);
      expect(repo.lastUpsertedFocusRule?.pattern, 'brand.com');
      final List<MailMessage> listed = await repo.listMessages(
        const MessageQuery(accountId: 'work'),
      );
      expect(
        listed.firstWhere((MailMessage m) => m.id == 'msg-promo').bucket,
        FocusBucket.other,
      );
      await cubit.close();
    });

    test('reportJunk domain scope moves all matching local mail', () async {
      final MailMessage news = _RecordingRepo.message.copyWith(
        id: 'msg-news',
        fromAddress: 'news@brand.com',
      );
      final MailMessage promo = _RecordingRepo.message.copyWith(
        id: 'msg-promo',
        fromAddress: 'promo@brand.com',
      );
      final _RecordingRepo repo = _RecordingRepo(
        messages: <MailMessage>[
          news,
          promo,
          _RecordingRepo.messageTwo,
        ],
        folders: const <MailFolder>[
          _RecordingRepo.inbox,
          _RecordingRepo.junk,
        ],
      );
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          unified: false,
          accountId: 'work',
          folderId: 'inbox-work',
          selectedMessageId: 'msg-news',
          messages: <MailMessage>[news, promo, _RecordingRepo.messageTwo],
          folders: const <MailFolder>[
            _RecordingRepo.inbox,
            _RecordingRepo.junk,
          ],
        ),
      );
      await cubit.reportJunk(scope: AddressMatchScope.domain);
      expect(repo.lastMovedFolderId, 'junk-work');
      expect(repo.lastMovedIds, containsAll(<String>['msg-news', 'msg-promo']));
      expect(repo.lastMovedIds, isNot(contains('msg-2')));
      await cubit.close();
    });

    test(
      'refresh includes trashed messages when viewing trash folder',
      () async {
        final _RecordingRepo repo = _RecordingRepo();
        final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
        cubit.emit(
          cubit.state.copyWith(
            unified: false,
            accountId: 'work',
            folderId: 'trash-work',
            folders: const <MailFolder>[
              _RecordingRepo.inbox,
              _RecordingRepo.archive,
              _RecordingRepo.trash,
              _RecordingRepo.junk,
            ],
          ),
        );
        await cubit.refresh();
        expect(repo.lastQuery, isNotNull);
        expect(repo.lastQuery!.includeTrashed, isTrue);
        expect(repo.lastQuery!.folderId, 'trash-work');
        await cubit.close();
      },
    );

    test('refresh recognizes a role-less folder named Trash', () async {
      const MailFolder namedTrash = MailFolder(
        id: 'named-trash-work',
        accountId: 'work',
        name: 'Trash',
        remoteId: 'Trash',
      );
      final _RecordingRepo repo = _RecordingRepo(
        folders: const <MailFolder>[_RecordingRepo.inbox, namedTrash],
      );
      final MailboxCubit cubit = await _buildCubit(repo: repo, prefs: prefs);
      cubit.emit(
        cubit.state.copyWith(
          unified: false,
          accountId: 'work',
          folderId: namedTrash.id,
          folders: const <MailFolder>[_RecordingRepo.inbox, namedTrash],
        ),
      );

      await cubit.refresh();

      expect(repo.lastQuery!.includeTrashed, isTrue);
      await cubit.close();
    });
  });
}
