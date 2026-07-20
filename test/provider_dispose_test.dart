// ==============================================================================
// File: test/provider_dispose_test.dart
// Description: Verifies MailProvider dispose is idempotent and SyncEngine cleans up.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-16
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/protocol/graph_mail_provider.dart';
import 'package:bytemail/protocol/imap_smtp_mail_provider.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _CountingDisposeProvider extends MailProvider {
  int disposeCalls = 0;

  @override
  MailCapabilities get capabilities => const MailCapabilities(
    supportsServerSearch: false,
    supportsPush: false,
    supportsPartialBody: false,
    supportsSend: false,
  );

  @override
  Future<List<RemoteFolder>> listFolders() async => const <RemoteFolder>[
    RemoteFolder(providerId: 'INBOX', name: 'Inbox', role: 'inbox'),
  ];

  @override
  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50}) async =>
      const <RemoteMessageHeader>[];

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
  Future<List<RemoteMessageHeader>> searchRemote(String query) async =>
      const <RemoteMessageHeader>[];

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

class _ClaimOnceRepo implements MailRepository {
  bool _claimed = false;

  @override
  Future<List<SyncJob>> claimPendingJobs({int limit = 1}) async {
    if (_claimed) {
      return const <SyncJob>[];
    }
    _claimed = true;
    return <SyncJob>[
      SyncJob(
        id: 'job-1',
        accountId: 'work',
        type: 'incremental',
        status: 'running',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    ];
  }

  @override
  Future<void> completeJob(
    String id, {
    required bool success,
    String? cursorJson,
    String? error,
  }) async {}

  @override
  Future<int> reclaimRunningJobs() async => 0;

  @override
  Future<int> reclaimSendingOutbox() async => 0;

  @override
  Future<void> upsertFolders(List<MailFolder> folders) async {}

  @override
  Future<List<MailMessage>> upsertMessages(
    List<MailMessage> messages, {
    required String folderId,
  }) async =>
      const <MailMessage>[];

  @override
  Future<void> setCursor(
    String accountId,
    String folderId,
    String key,
    String value,
  ) async {}

  @override
  Future<void> upsertWidgetSnapshot(
    String id,
    String kind,
    String payloadJson,
  ) async {}

  @override
  Future<String?> getWidgetSnapshot(String id) async => null;

  @override
  Future<List<MailMessage>> listMessages(MessageQuery query) async =>
      const <MailMessage>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('provider dispose', () {
    test(
      'GraphMailProvider.dispose is idempotent and skips shared client',
      () async {
        final http.Client shared = MockClient(
          (http.Request request) async => http.Response('{}', 200),
        );
        final GraphMailProvider provider = GraphMailProvider(
          () async => 'token',
          client: shared,
        );
        await expectLater(provider.dispose(), completes);
        await expectLater(provider.dispose(), completes);
        final http.Response probe = await shared.get(
          Uri.parse('https://example.com'),
        );
        expect(probe.statusCode, 200);
        shared.close();
      },
    );

    test(
      'ImapSmtpMailProvider.dispose does not throw when never connected',
      () async {
        final ImapSmtpMailProvider provider = ImapSmtpMailProvider(
          host: 'localhost',
          port: 993,
          user: 'u',
          password: 'p',
          smtpHost: 'localhost',
          smtpPort: 465,
        );
        await expectLater(provider.dispose(), completes);
        await expectLater(provider.dispose(), completes);
      },
    );

    test('SyncEngine disposes resolved provider after job work', () async {
      final _CountingDisposeProvider provider = _CountingDisposeProvider();
      final SyncEngine engine = SyncEngine(
        repository: _ClaimOnceRepo(),
        resolveProvider: (String accountId) async => provider,
      );
      await engine.kick();
      // incremental runs folder-list + inbox, each with its own resolve/dispose.
      expect(provider.disposeCalls, greaterThanOrEqualTo(1));
    });
  });
}
