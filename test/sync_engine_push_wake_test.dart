// ==============================================================================
// File: test/sync_engine_push_wake_test.dart
// Description: push_wake job and offline kick gating for SyncEngine.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/network_sync_policy.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';

class _WakeProvider extends MailProvider {
  int inboxCalls = 0;
  int disposeCalls = 0;

  @override
  MailCapabilities get capabilities => const MailCapabilities(
        supportsServerSearch: false,
        supportsPush: true,
        supportsPartialBody: false,
        supportsSend: false,
      );

  @override
  Future<List<RemoteFolder>> listFolders() async => const <RemoteFolder>[];

  @override
  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50}) async {
    inboxCalls += 1;
    return const <RemoteMessageHeader>[];
  }

  @override
  Future<List<RemoteMessageHeader>> listRecentInFolder(
    String folderRemoteId, {
    int limit = 50,
  }) async =>
      const <RemoteMessageHeader>[];

  @override
  Future<String?> fetchBody(
    String providerId, {
    String? folderRemoteId,
  }) async =>
      null;

  @override
  Future<String?> fetchHeaders(
    String providerId, {
    String? folderRemoteId,
  }) async =>
      null;

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
  Future<List<RemoteMessageHeader>> searchRemote(String query) async =>
      const <RemoteMessageHeader>[];

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

class _WakeRepo implements MailRepository {
  final List<SyncJob> pending = <SyncJob>[];
  final List<Map<String, Object?>> completed = <Map<String, Object?>>[];
  final Map<String, String> cursors = <String, String>{};
  int nextId = 1;

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {
    pending.add(
      SyncJob(
        id: 'job-${nextId++}',
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
    final List<SyncJob> batch = pending.take(limit).toList(growable: false);
    pending.removeWhere(batch.contains);
    return batch;
  }

  @override
  Future<void> completeJob(
    String id, {
    required bool success,
    String? cursorJson,
    String? error,
  }) async {
    completed.add(<String, Object?>{
      'id': id,
      'success': success,
      'error': error,
    });
  }

  @override
  Future<bool> hasIncompleteJobOfType(String type) async => false;

  @override
  Future<int> reclaimRunningJobs() async => 0;

  @override
  Future<int> reclaimSendingOutbox() async => 0;

  @override
  Future<void> setCursor(
    String accountId,
    String folderId,
    String key,
    String value,
  ) async {
    cursors['$accountId|$folderId|$key'] = value;
  }

  @override
  Future<String?> getCursor(
    String accountId,
    String folderId,
    String key,
  ) async =>
      cursors['$accountId|$folderId|$key'];

  @override
  Future<List<MailMessage>> upsertMessages(
    List<MailMessage> messages, {
    required String folderId,
  }) async =>
      const <MailMessage>[];

  @override
  Future<void> upsertFolders(List<MailFolder> folders) async {}

  @override
  Future<List<FocusRule>> listFocusRules({String? accountId}) async =>
      const <FocusRule>[];

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
  Future<List<MailAccount>> listAccounts() async => const <MailAccount>[];

  // --- unused stubs ---
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('push_wake enqueues incremental which syncs inbox', () async {
    final _WakeProvider provider = _WakeProvider();
    final _WakeRepo repo = _WakeRepo();
    final SyncEngine engine = SyncEngine(
      repository: repo,
      resolveProvider: (_) async => provider,
      readConnectivity: () async =>
          const <ConnectivityResult>[ConnectivityResult.wifi],
      networkPolicy: const NetworkSyncPolicy(isDesktop: true),
    );
    addTearDown(engine.dispose);

    await engine.enqueuePushWake('work');
    await engine.kick();

    expect(
      repo.completed.any(
        (Map<String, Object?> j) => j['success'] == true,
      ),
      isTrue,
    );
    expect(provider.inboxCalls, 1);
  });

  test('kick no-ops when offline', () async {
    final _WakeProvider provider = _WakeProvider();
    final _WakeRepo repo = _WakeRepo();
    final SyncEngine engine = SyncEngine(
      repository: repo,
      resolveProvider: (_) async => provider,
      readConnectivity: () async =>
          const <ConnectivityResult>[ConnectivityResult.none],
      networkPolicy: const NetworkSyncPolicy(isDesktop: true),
    );
    addTearDown(engine.dispose);

    await engine.enqueueIncremental('work');
    await engine.kick();

    expect(repo.completed, isEmpty);
    expect(provider.inboxCalls, 0);
  });
}
