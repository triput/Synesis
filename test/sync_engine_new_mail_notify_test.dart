// ==============================================================================
// File: test/sync_engine_new_mail_notify_test.dart
// Description: SyncEngine new-unread callback routing by sync job type.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/network_sync_policy.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class _NotifyProvider extends MailProvider {
  int inboxCalls = 0;
  int searchCalls = 0;

  @override
  MailCapabilities get capabilities => const MailCapabilities(
    supportsServerSearch: true,
    supportsPush: false,
    supportsPartialBody: false,
    supportsSend: false,
  );

  @override
  Future<List<RemoteFolder>> listFolders() async => const <RemoteFolder>[];

  @override
  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50}) async {
    inboxCalls += 1;
    return <RemoteMessageHeader>[_header('inbox-message')];
  }

  @override
  Future<List<RemoteMessageHeader>> searchRemote(String query) async {
    searchCalls += 1;
    return <RemoteMessageHeader>[_header('search-message')];
  }

  RemoteMessageHeader _header(String id) {
    return RemoteMessageHeader(
      providerId: id,
      subject: 'New mail',
      fromAddress: 'sender@example.com',
      receivedAt: DateTime.utc(2026, 7, 17, 12),
    );
  }

  @override
  Future<List<RemoteMessageHeader>> listRecentInFolder(
    String folderRemoteId, {
    int limit = 50,
  }) async => const <RemoteMessageHeader>[];

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
  Future<void> dispose() async {}
}

class _NotifyRepo implements MailRepository {
  _NotifyRepo({required this.newlyInsertedUnread});

  final MailMessage newlyInsertedUnread;
  final List<SyncJob> pending = <SyncJob>[];
  int nextJobId = 1;

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {
    pending.add(
      SyncJob(
        id: 'job-${nextJobId++}',
        accountId: accountId,
        type: type,
        status: 'pending',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        payloadJson: payloadJson,
      ),
    );
  }

  @override
  Future<List<SyncJob>> claimPendingJobs({int limit = 8}) async {
    final List<SyncJob> claimed = pending.take(limit).toList(growable: false);
    pending.removeRange(0, claimed.length);
    return claimed;
  }

  @override
  Future<List<MailMessage>> upsertMessages(
    List<MailMessage> messages, {
    required String folderId,
  }) async => <MailMessage>[newlyInsertedUnread];

  @override
  Future<ResolvedSyncPolicy> resolvePolicy(
    String accountId, {
    int fallbackRetentionDays = 180,
  }) async {
    return ResolvedSyncPolicy(
      accountId: accountId,
      profileId: 'default',
      retentionDays: fallbackRetentionDays,
      bodyPolicy: BodyFetchPolicy.onOpen,
      attachmentMaxMb: 25,
    );
  }

  @override
  Future<List<FocusRule>> listFocusRules({String? accountId}) async =>
      const <FocusRule>[];

  @override
  Future<int> reclassifyFocusBuckets(
    FocusBucket Function(MailMessage message) score,
  ) async => 0;

  @override
  Future<List<MailMessage>> listMessages(MessageQuery query) async =>
      const <MailMessage>[];

  @override
  Future<void> upsertFolders(List<MailFolder> folders) async {}

  @override
  Future<void> upsertWidgetSnapshot(
    String id,
    String kind,
    String payloadJson,
  ) async {}

  @override
  Future<void> setCursor(
    String accountId,
    String folderId,
    String key,
    String value,
  ) async {}

  @override
  Future<void> completeJob(
    String id, {
    required bool success,
    String? cursorJson,
    String? error,
  }) async {}

  @override
  Future<bool> hasIncompleteJobOfType(String type) async => false;

  @override
  Future<int> reclaimRunningJobs() async => 0;

  @override
  Future<int> reclaimSendingOutbox() async => 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

MailMessage _newUnread() {
  return const MailMessage(
    id: 'new-unread',
    accountId: 'work',
    fromName: 'Sender',
    fromAddress: 'sender@example.com',
    subject: 'New mail',
    snippet: 'New mail',
    body: '',
    whenLabel: 'now',
    bucket: FocusBucket.focused,
    unread: true,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'incremental inbox notifies new unread but remote_search does not',
    () async {
      final _NotifyProvider provider = _NotifyProvider();
      final MailMessage newlyUnread = _newUnread();
      final _NotifyRepo repository = _NotifyRepo(
        newlyInsertedUnread: newlyUnread,
      );
      final List<List<MailMessage>> callbacks = <List<MailMessage>>[];
      final SyncEngine engine = SyncEngine(
        repository: repository,
        resolveProvider: (_) async => provider,
        readConnectivity: () async =>
            const <ConnectivityResult>[ConnectivityResult.wifi],
        networkPolicy: const NetworkSyncPolicy(isDesktop: false),
        onNewUnread: (List<MailMessage> messages) async {
          callbacks.add(List<MailMessage>.from(messages));
        },
      );
      addTearDown(engine.dispose);

      await engine.enqueueIncremental('work');
      await engine.kick();

      expect(provider.inboxCalls, 1);
      expect(callbacks, <List<MailMessage>>[
        <MailMessage>[newlyUnread],
      ]);

      await repository.enqueueSyncJob(
        accountId: 'work',
        type: 'remote_search',
        payloadJson: jsonEncode(<String, String>{'query': 'invoice'}),
      );
      await engine.kick();

      expect(provider.searchCalls, 1);
      expect(callbacks, hasLength(1));
    },
  );
}
