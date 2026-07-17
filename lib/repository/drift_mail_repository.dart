// ==============================================================================
// File: lib/repository/drift_mail_repository.dart
// Description: Thin Drift-backed MailRepository façade over store modules.
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/database.dart' hide FocusRule, SyncProfile;
import 'package:bytemail/repository/drift/drift_account_folder_store.dart';
import 'package:bytemail/repository/drift/drift_focus_store.dart';
import 'package:bytemail/repository/drift/drift_message_store.dart';
import 'package:bytemail/repository/drift/drift_outbox_store.dart';
import 'package:bytemail/repository/drift/drift_sync_job_store.dart';
import 'package:bytemail/repository/drift/drift_sync_profile_store.dart';
import 'package:bytemail/repository/drift/drift_widget_diagnostics_store.dart';
import 'package:bytemail/repository/mail_repository.dart';

class DriftMailRepository implements MailRepository {
  DriftMailRepository(this._database)
      : _changes = StreamController<void>.broadcast() {
    final void Function() notify = _notifyChanged;
    _accounts = DriftAccountFolderStore(_database, notify: notify);
    _messages = DriftMessageStore(
      _database,
      notify: notify,
      folders: _accounts,
    );
    _outbox = DriftOutboxStore(_database, notify: notify);
    _jobs = DriftSyncJobStore(
      _database,
      notify: notify,
      countQueuedOutbox: () => _outbox.countQueuedOutbox(),
    );
    _focus = DriftFocusStore(_database, notify: notify);
    _syncProfiles = DriftSyncProfileStore(_database, notify: notify);
    _widgetDiagnostics = DriftWidgetDiagnosticsStore(
      _database,
      notify: notify,
      accounts: _accounts,
      messages: _messages,
    );
  }

  final ByteMailDatabase _database;
  final StreamController<void> _changes;

  late final DriftAccountFolderStore _accounts;
  late final DriftMessageStore _messages;
  late final DriftOutboxStore _outbox;
  late final DriftSyncJobStore _jobs;
  late final DriftFocusStore _focus;
  late final DriftSyncProfileStore _syncProfiles;
  late final DriftWidgetDiagnosticsStore _widgetDiagnostics;

  @override
  Stream<void> watchChanges() => _changes.stream;

  Future<void> close() async {
    await _changes.close();
    await _database.close();
  }

  @override
  Future<List<MailAccount>> listAccounts() => _accounts.listAccounts();

  @override
  Future<List<MailFolder>> listFolders({String? accountId}) =>
      _accounts.listFolders(accountId: accountId);

  @override
  Future<MailFolder?> getFolder(String id) => _accounts.getFolder(id);

  @override
  Future<void> upsertFolders(List<MailFolder> folders) =>
      _accounts.upsertFolders(folders);

  @override
  Future<List<MailMessage>> listMessages(MessageQuery query) =>
      _messages.listMessages(query);

  @override
  Future<MailMessage?> getMessage(String id) => _messages.getMessage(id);

  @override
  Future<List<FocusRule>> listFocusRules({String? accountId}) =>
      _focus.listFocusRules(accountId: accountId);

  @override
  Future<void> upsertFocusRule(FocusRule rule) => _focus.upsertFocusRule(rule);

  @override
  Future<int> countQueuedOutbox() => _outbox.countQueuedOutbox();

  @override
  Future<int> countFailedOutbox() => _outbox.countFailedOutbox();

  @override
  Future<String> syncStatusLabel() => _jobs.syncStatusLabel();

  @override
  Future<void> upsertAccount(
    MailAccount account, {
    required String providerType,
    bool focusEnabled = true,
  }) =>
      _accounts.upsertAccount(
        account,
        providerType: providerType,
        focusEnabled: focusEnabled,
      );

  @override
  Future<void> upsertMessages(
    List<MailMessage> messages, {
    required String folderId,
  }) =>
      _messages.upsertMessages(messages, folderId: folderId);

  @override
  Future<void> updateMessageBody(String messageId, String body) =>
      _messages.updateMessageBody(messageId, body);

  @override
  Future<void> updateMessageRawHeaders(
    String messageId,
    String rawHeaders,
  ) =>
      _messages.updateMessageRawHeaders(messageId, rawHeaders);

  @override
  Future<void> updateMessageFocusBucket(
    String messageId,
    FocusBucket bucket,
  ) =>
      _messages.updateMessageFocusBucket(messageId, bucket);

  @override
  Future<int> reclassifyFocusBuckets(
    FocusBucket Function(MailMessage message) score,
  ) =>
      _focus.reclassifyFocusBuckets(score);

  @override
  Future<List<MailMessage>> searchLocal(String query) =>
      _messages.searchLocal(query);

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
  }) =>
      _outbox.enqueueOutbox(
        accountId: accountId,
        to: to,
        subject: subject,
        body: body,
        cc: cc,
        bcc: bcc,
        composeMode: composeMode,
        inReplyTo: inReplyTo,
        referencesJson: referencesJson,
        attachmentRefsJson: attachmentRefsJson,
        signatureId: signatureId,
        sendAfter: sendAfter,
      );

  @override
  Future<List<OutboxItem>> listOutbox() => _outbox.listOutbox();

  @override
  Future<void> updateOutboxState(
    String id,
    String state, {
    String? error,
  }) =>
      _outbox.updateOutboxState(id, state, error: error);

  @override
  Future<void> deleteOutbox(String id) => _outbox.deleteOutbox(id);

  @override
  Future<int> deleteOutboxInStates(Iterable<String> states) =>
      _outbox.deleteOutboxInStates(states);

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) =>
      _jobs.enqueueSyncJob(
        accountId: accountId,
        type: type,
        payloadJson: payloadJson,
      );

  @override
  Future<List<SyncJob>> listSyncJobs({int limit = 50}) =>
      _jobs.listSyncJobs(limit: limit);

  @override
  Future<void> retrySyncJob(String id) => _jobs.retrySyncJob(id);

  @override
  Future<void> cancelSyncJob(String id) => _jobs.cancelSyncJob(id);

  @override
  Future<List<AccountSyncHealth>> listAccountSyncHealth() =>
      _jobs.listAccountSyncHealth();

  @override
  Future<bool> hasIncompleteJobOfType(String type) =>
      _jobs.hasIncompleteJobOfType(type);

  @override
  Future<int> reclaimRunningJobs() => _jobs.reclaimRunningJobs();

  @override
  Future<int> reclaimSendingOutbox() => _outbox.reclaimSendingOutbox();

  @override
  Future<List<SyncJob>> claimPendingJobs({int limit = 10}) =>
      _jobs.claimPendingJobs(limit: limit);

  @override
  Future<void> completeJob(
    String id, {
    required bool success,
    String? cursorJson,
    String? error,
  }) =>
      _jobs.completeJob(
        id,
        success: success,
        cursorJson: cursorJson,
        error: error,
      );

  @override
  Future<void> setCursor(
    String accountId,
    String folderId,
    String key,
    String value,
  ) =>
      _jobs.setCursor(accountId, folderId, key, value);

  @override
  Future<String?> getCursor(
    String accountId,
    String folderId,
    String key,
  ) =>
      _jobs.getCursor(accountId, folderId, key);

  @override
  Future<int> applyRetention({
    required int retentionDays,
    String? accountId,
  }) =>
      _messages.applyRetention(
        retentionDays: retentionDays,
        accountId: accountId,
      );

  @override
  Future<List<SyncProfile>> listSyncProfiles() =>
      _syncProfiles.listSyncProfiles();

  @override
  Future<SyncProfile?> getSyncProfile(String id) =>
      _syncProfiles.getSyncProfile(id);

  @override
  Future<SyncProfile?> getDefaultSyncProfile() =>
      _syncProfiles.getDefaultSyncProfile();

  @override
  Future<void> upsertSyncProfile(SyncProfile profile) =>
      _syncProfiles.upsertSyncProfile(profile);

  @override
  Future<ResolvedSyncPolicy> resolvePolicy(
    String accountId, {
    int fallbackRetentionDays = 180,
  }) =>
      _syncProfiles.resolvePolicy(
        accountId,
        fallbackRetentionDays: fallbackRetentionDays,
      );

  @override
  Future<void> setPinned(String messageId, bool pinned) =>
      _messages.setPinned(messageId, pinned);

  @override
  Future<void> setPinnedBulk(List<String> ids, bool pinned) =>
      _messages.setPinnedBulk(ids, pinned);

  @override
  Future<void> setSnoozed(String messageId, int? snoozedUntil) =>
      _messages.setSnoozed(messageId, snoozedUntil);

  @override
  Future<void> setSnoozedBulk(List<String> ids, int? snoozedUntil) =>
      _messages.setSnoozedBulk(ids, snoozedUntil);

  @override
  Future<int?> nextSnoozeExpiryMs({int? nowMs}) =>
      _messages.nextSnoozeExpiryMs(nowMs: nowMs);

  @override
  Future<int> clearExpiredSnoozes({int? nowMs}) =>
      _messages.clearExpiredSnoozes(nowMs: nowMs);

  @override
  Future<void> setStarred(String messageId, bool starred) =>
      _messages.setStarred(messageId, starred);

  @override
  Future<void> setUnread(String messageId, bool unread) =>
      _messages.setUnread(messageId, unread);

  @override
  Future<void> setUnreadBulk(List<String> ids, bool unread) =>
      _messages.setUnreadBulk(ids, unread);

  @override
  Future<void> recountUnreadCounts({String? accountId}) async {
    // Silent recompute: mutation paths already notify; refresh callers
    // re-read folders immediately after this returns.
    await _accounts.recountUnreadFromMessages(accountId: accountId);
  }

  @override
  Future<MailFolder?> resolveFolderByRole(String accountId, String role) =>
      _accounts.resolveFolderByRole(accountId, role);

  @override
  Future<void> moveMessageLocal(
    String messageId,
    String folderId, {
    int? trashedAt,
    bool clearTrashedAt = false,
  }) =>
      _messages.moveMessageLocal(
        messageId,
        folderId,
        trashedAt: trashedAt,
        clearTrashedAt: clearTrashedAt,
      );

  @override
  Future<void> moveMessagesLocal(
    List<String> messageIds,
    String folderId, {
    int? trashedAt,
    bool clearTrashedAt = false,
  }) =>
      _messages.moveMessagesLocal(
        messageIds,
        folderId,
        trashedAt: trashedAt,
        clearTrashedAt: clearTrashedAt,
      );

  @override
  Future<void> hardDeleteLocal(String messageId) =>
      _messages.hardDeleteLocal(messageId);

  @override
  Future<void> hardDeleteLocalBulk(List<String> ids) =>
      _messages.hardDeleteLocalBulk(ids);

  @override
  Future<List<MailMessage>> listTrashedPastRetention({
    required int retentionDays,
    DateTime? now,
  }) =>
      _messages.listTrashedPastRetention(
        retentionDays: retentionDays,
        now: now,
      );

  @override
  Future<void> upsertWidgetSnapshot(
    String id,
    String kind,
    String payloadJson,
  ) =>
      _widgetDiagnostics.upsertWidgetSnapshot(id, kind, payloadJson);

  @override
  Future<String?> getWidgetSnapshot(String id) =>
      _widgetDiagnostics.getWidgetSnapshot(id);

  @override
  Future<void> wipeAccount(String accountId) =>
      _accounts.wipeAccount(accountId);

  @override
  Future<String> exportDiagnosticsRedacted() =>
      _widgetDiagnostics.exportDiagnosticsRedacted();

  @override
  Future<void> seedDemoDataIfEmpty() =>
      _widgetDiagnostics.seedDemoDataIfEmpty();

  void _notifyChanged() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}
