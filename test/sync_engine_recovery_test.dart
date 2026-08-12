// ==============================================================================
// File: test/sync_engine_recovery_test.dart
// Description: DEF-083/084 Graph delta recovery and operator sync recovery APIs.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-12
// Last Update: 2026-08-12
// ==============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/sync_profile.dart';
import 'package:synesis/protocol/graph_mail_provider.dart';
import 'package:synesis/protocol/mail_provider.dart';
import 'package:synesis/query/message_query.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/graph_sync_recovery.dart';
import 'package:synesis/sync/sync_engine.dart';

void main() {
  group('isGraphExpiredSyncToken', () {
    test('matches 410 Gone', () {
      expect(
        isGraphExpiredSyncToken(
          const ProtocolException('gone', statusCode: 410),
        ),
        isTrue,
      );
    });

    test('matches 400 with expired sync token message', () {
      expect(
        isGraphExpiredSyncToken(
          const ProtocolException(
            'Sync token is expired. Clear local cache and retry call without the sync token.',
            statusCode: 400,
          ),
        ),
        isTrue,
      );
    });

    test('ignores unrelated 400 errors', () {
      expect(
        isGraphExpiredSyncToken(
          const ProtocolException('Bad Request', statusCode: 400),
        ),
        isFalse,
      );
    });
  });

  group('SyncEngine Graph delta recovery (DEF-083)', () {
    test('400 expired token clears graph_delta cursor and uses listRecent', () async {
      final _RecoveryRepo repo = _RecoveryRepo();
      await repo.upsertAccount(
        const MailAccount(
          id: 'graph-acct',
          label: 'G',
          address: 'user@contoso.com',
          accent: Color(0xFF2563EB),
        ),
        providerType: 'graph',
      );
      await repo.upsertFolders(const <MailFolder>[
        MailFolder(
          id: 'inbox-graph-acct',
          accountId: 'graph-acct',
          name: 'Inbox',
          remoteId: 'inbox',
          role: 'inbox',
        ),
      ]);
      await repo.setCursor(
        'graph-acct',
        'inbox-graph-acct',
        GraphMailProvider.graphDeltaCursorKey,
        'https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messages/delta?\$deltatokens=bad',
      );

      final http.Client client = MockClient((http.Request request) async {
        if (request.url.toString().contains('deltatokens=bad')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'error': <String, String>{
                'code': 'InvalidRequest',
                'message':
                    'Sync token is expired. Clear local cache and retry call without the sync token.',
              },
            }),
            400,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/messages/delta')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'value': <Object>[],
              r'@odata.deltaLink':
                  'https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messages/delta?\$deltatokens=fresh',
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }
        if (request.url.path.endsWith('/messages')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'value': <Map<String, Object>>[
                <String, Object>{
                  'id': 'msg-1',
                  'subject': 'Hello',
                  'from': <String, Object>{
                    'emailAddress': <String, String>{
                      'address': 'a@example.com',
                    },
                  },
                  'receivedDateTime': '2026-08-12T12:00:00Z',
                  'isRead': false,
                  'hasAttachments': false,
                },
              ],
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }
        return http.Response('{}', 404);
      });

      final GraphMailProvider provider = GraphMailProvider(
        () async => 'token',
        client: client,
      );
      addTearDown(provider.dispose);

      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => provider,
        trashRetentionDays: () => 30,
      );
      await repo.enqueueSyncJob(accountId: 'graph-acct', type: 'incremental');
      await engine.kick();

      expect(repo.cursorClears, contains('graph_delta'));
      expect(
        await repo.getCursor(
          'graph-acct',
          'inbox-graph-acct',
          GraphMailProvider.graphDeltaCursorKey,
        ),
        contains('deltatokens=fresh'),
      );
      await engine.dispose();
    });
  });

  group('SyncEngine operator recovery (DEF-084)', () {
    test('stopAllSync aborts running and cancels pending', () async {
      final _RecoveryRepo repo = _RecoveryRepo()
        ..pendingJobs.addAll(<SyncJob>[
          SyncJob(
            id: 'p1',
            accountId: 'a',
            type: 'incremental',
            status: 'pending',
            updatedAt: 1,
          ),
          SyncJob(
            id: 'p2',
            accountId: 'b',
            type: 'incremental',
            status: 'pending',
            updatedAt: 2,
          ),
        ])
        ..runningJobs.add(
          SyncJob(
            id: 'r1',
            accountId: 'a',
            type: 'incremental',
            status: 'running',
            updatedAt: 3,
          ),
        );
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        trashRetentionDays: () => 30,
      );

      final ({int abortedRunning, int cancelledPending}) result =
          await engine.stopAllSync(accountId: 'a');

      expect(result.abortedRunning, 1);
      expect(result.cancelledPending, 1);
      expect(repo.abortedRunning, 1);
      expect(repo.cancelledPending, 1);
      await engine.dispose();
    });

    test('clearSyncCursors delegates to repository', () async {
      final _RecoveryRepo repo = _RecoveryRepo();
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        trashRetentionDays: () => 30,
      );

      final int cleared = await engine.clearSyncCursors(accountId: 'acct');
      expect(cleared, 2);
      expect(repo.clearCursorCalls, 1);
      await engine.dispose();
    });

    test('forceRefreshAuthToken invokes wired callback', () async {
      final List<String> refreshed = <String>[];
      final SyncEngine engine = SyncEngine(
        repository: _RecoveryRepo(),
        resolveProvider: (_) async => null,
        trashRetentionDays: () => 30,
        refreshAuthToken: (String accountId) async {
          refreshed.add(accountId);
        },
      );

      await engine.forceRefreshAuthToken('graph-acct');
      expect(refreshed, <String>['graph-acct']);
      await engine.dispose();
    });

    test('stopAllSync bumps kick generation to interrupt in-flight kick', () async {
      final Completer<void> claimGate = Completer<void>();
      final _RecoveryRepo repo = _RecoveryRepo()..claimGate = claimGate;
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        trashRetentionDays: () => 30,
      );

      engine.kickNonBlocking();
      await Future<void>.delayed(Duration.zero);
      expect(engine.isKickInFlight, isTrue);

      await engine.stopAllSync();
      expect(engine.isKickInFlight, isFalse);

      claimGate.complete();
      await engine.dispose();
    });
  });
}

class _RecoveryRepo implements MailRepository {
  Completer<void>? claimGate;
  final List<SyncJob> pendingJobs = <SyncJob>[];
  final List<SyncJob> runningJobs = <SyncJob>[];
  final List<String> cursorClears = <String>[];
  int abortedRunning = 0;
  int cancelledPending = 0;
  int clearCursorCalls = 0;

  final Map<String, String> _cursors = <String, String>{};

  String _cursorKey(String accountId, String folderId, String key) =>
      '$accountId|$folderId|$key';

  @override
  Future<void> setCursor(
    String accountId,
    String folderId,
    String key,
    String value,
  ) async {
    if (value.isEmpty) {
      cursorClears.add(key);
    }
    _cursors[_cursorKey(accountId, folderId, key)] = value;
  }

  @override
  Future<String?> getCursor(
    String accountId,
    String folderId,
    String key,
  ) async =>
      _cursors[_cursorKey(accountId, folderId, key)];

  @override
  Future<int> abortRunningSyncJobs({String? accountId}) async {
    abortedRunning += 1;
    runningJobs.removeWhere(
      (SyncJob job) => accountId == null || job.accountId == accountId,
    );
    return 1;
  }

  @override
  Future<int> cancelPendingSyncJobs({String? accountId}) async {
    cancelledPending += 1;
    pendingJobs.removeWhere(
      (SyncJob job) => accountId == null || job.accountId == accountId,
    );
    return 1;
  }

  @override
  Future<int> clearSyncCursors({String? accountId, String? folderId}) async {
    clearCursorCalls += 1;
    return 2;
  }

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {
    pendingJobs.add(
      SyncJob(
        id: 'job-${pendingJobs.length}',
        accountId: accountId,
        type: type,
        status: 'pending',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        payloadJson: payloadJson,
      ),
    );
  }

  @override
  Future<List<SyncJob>> claimPendingJobs({int limit = 10}) async {
    final Completer<void>? gate = claimGate;
    if (gate != null) {
      await gate.future;
    }
    if (pendingJobs.isEmpty) {
      return const <SyncJob>[];
    }
    final List<SyncJob> claimed = pendingJobs.take(limit).toList(growable: false);
    pendingJobs.removeRange(0, claimed.length);
    return claimed
        .map(
          (SyncJob job) => SyncJob(
            id: job.id,
            accountId: job.accountId,
            type: job.type,
            status: 'running',
            updatedAt: job.updatedAt,
            payloadJson: job.payloadJson,
          ),
        )
        .toList(growable: false);
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
  Future<bool> hasIncompleteJobOfType(String type) async => false;

  @override
  Future<List<MailAccount>> listAccounts() async => const <MailAccount>[
    MailAccount(
      id: 'graph-acct',
      label: 'G',
      address: 'user@contoso.com',
      accent: Color(0xFF2563EB),
    ),
  ];

  @override
  Future<List<MailFolder>> listFolders({String? accountId}) async =>
      const <MailFolder>[
        MailFolder(
          id: 'inbox-graph-acct',
          accountId: 'graph-acct',
          name: 'Inbox',
          remoteId: 'inbox',
          role: 'inbox',
        ),
      ];

  @override
  Future<MailFolder?> getFolder(String id) async => (await listFolders())
      .cast<MailFolder?>()
      .firstWhere(
        (MailFolder? folder) => folder?.id == id,
        orElse: () => null,
      );

  @override
  Future<List<MailMessage>> upsertMessages(
    List<MailMessage> messages, {
    required String folderId,
  }) async =>
      messages;

  @override
  Future<void> upsertAccount(
    MailAccount account, {
    required String providerType,
    bool focusEnabled = false,
  }) async {}

  @override
  Future<void> upsertFolders(List<MailFolder> folders) async {}

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
  Future<List<MailMessage>> listMessages(MessageQuery query) async =>
      const <MailMessage>[];

  @override
  Future<void> upsertWidgetSnapshot(
    String id,
    String kind,
    String payloadJson,
  ) async {}

  @override
  Future<int> reclassifyFocusBuckets(
    FocusBucket Function(MailMessage message) score,
  ) async =>
      0;

  @override
  Future<({int running, int pending})> countSyncJobActivity() async =>
      (running: runningJobs.length, pending: pendingJobs.length);

  @override
  Stream<void> watchChanges() => const Stream<void>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
