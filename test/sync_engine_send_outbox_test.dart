// ==============================================================================
// File: test/sync_engine_send_outbox_test.dart
// Description: SyncEngine send_outbox failure surfacing and multi-recipient send.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/mime/outgoing_envelope.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/outbox/outbox_recipients.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingSendProvider extends MailProvider {
  final List<Map<String, Object?>> sends = <Map<String, Object?>>[];
  Object? throwOnSend;
  int disposeCalls = 0;

  @override
  MailCapabilities get capabilities => const MailCapabilities(
    supportsServerSearch: false,
    supportsPush: false,
    supportsPartialBody: false,
    supportsSend: true,
  );

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
  }) async {
    if (throwOnSend != null) {
      throw throwOnSend!;
    }
    sends.add(<String, Object?>{
      'to': List<String>.from(to),
      'cc': List<String>.from(cc),
      'bcc': List<String>.from(bcc),
      'subject': subject,
      'body': body,
    });
  }

  @override
  Future<void> sendEnvelope(OutgoingEnvelope envelope) async {
    if (throwOnSend != null) {
      throw throwOnSend!;
    }
    envelopes.add(envelope);
    await send(
      to: envelope.to,
      cc: envelope.cc,
      bcc: envelope.bcc,
      subject: envelope.subject,
      body: envelope.textBody,
    );
  }

  final List<OutgoingEnvelope> envelopes = <OutgoingEnvelope>[];

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

class _SendOutboxRepo implements MailRepository {
  _SendOutboxRepo({List<OutboxItem>? outbox})
    : outbox = List<OutboxItem>.from(outbox ?? const <OutboxItem>[]);

  final List<OutboxItem> outbox;
  final List<SyncJob> pending = <SyncJob>[];
  final List<Map<String, Object?>> completedJobs = <Map<String, Object?>>[];
  final List<Map<String, Object?>> stateUpdates = <Map<String, Object?>>[];
  int reclaimSendingCalls = 0;
  int nextJobId = 1;

  void enqueueSendJob(String accountId) {
    pending.add(
      SyncJob(
        id: 'job-${nextJobId++}',
        accountId: accountId,
        type: 'send_outbox',
        status: 'pending',
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

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
  Future<bool> hasIncompleteJobOfType(String type) async => pending.any(
    (SyncJob job) =>
        job.type == type &&
        (job.status == 'pending' || job.status == 'running'),
  );

  @override
  Future<List<SyncJob>> claimPendingJobs({int limit = 10}) async {
    if (pending.isEmpty) {
      return const <SyncJob>[];
    }
    final List<SyncJob> claimed = pending.take(limit).toList(growable: false);
    pending.removeRange(0, claimed.length);
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
  }) async {
    completedJobs.add(<String, Object?>{
      'id': id,
      'success': success,
      'error': error,
    });
  }

  @override
  Future<int> reclaimRunningJobs() async => 0;

  @override
  Future<int> reclaimSendingOutbox() async {
    reclaimSendingCalls += 1;
    int changed = 0;
    for (int i = 0; i < outbox.length; i++) {
      final OutboxItem item = outbox[i];
      if (item.state != 'sending') {
        continue;
      }
      outbox[i] = OutboxItem(
        id: item.id,
        accountId: item.accountId,
        to: item.to,
        subject: item.subject,
        body: item.body,
        state: 'queued',
        attempts: item.attempts,
        createdAt: item.createdAt,
        lastError: item.lastError,
        cc: item.cc,
        bcc: item.bcc,
        composeMode: item.composeMode,
        inReplyTo: item.inReplyTo,
        referencesJson: item.referencesJson,
        attachmentRefsJson: item.attachmentRefsJson,
        signatureId: item.signatureId,
        sendAfter: item.sendAfter,
      );
      changed += 1;
    }
    return changed;
  }

  @override
  Future<List<OutboxItem>> listOutbox() async =>
      List<OutboxItem>.from(outbox);

  @override
  Future<List<MailAccount>> listAccounts() async => <MailAccount>[
        MailAccount(
          id: 'work',
          label: 'Work',
          address: 'me@byte.io',
          accent: const Color(0xFF3366FF),
        ),
      ];

  @override
  Future<void> updateOutboxState(
    String id,
    String state, {
    String? error,
  }) async {
    stateUpdates.add(<String, Object?>{
      'id': id,
      'state': state,
      'error': error,
    });
    for (int i = 0; i < outbox.length; i++) {
      final OutboxItem item = outbox[i];
      if (item.id != id) {
        continue;
      }
      outbox[i] = OutboxItem(
        id: item.id,
        accountId: item.accountId,
        to: item.to,
        subject: item.subject,
        body: item.body,
        state: state,
        attempts: item.attempts + (state == 'sending' ? 1 : 0),
        createdAt: item.createdAt,
        lastError: error,
        cc: item.cc,
        bcc: item.bcc,
        composeMode: item.composeMode,
        inReplyTo: item.inReplyTo,
        referencesJson: item.referencesJson,
        attachmentRefsJson: item.attachmentRefsJson,
        signatureId: item.signatureId,
        sendAfter: item.sendAfter,
      );
      return;
    }
  }

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
  Future<String?> getWidgetSnapshot(String id) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

OutboxItem _queued({
  required String id,
  required String to,
  String? cc,
  String subject = 'Hi',
  String body = 'Body',
  String accountId = 'work',
  String state = 'queued',
}) {
  return OutboxItem(
    id: id,
    accountId: accountId,
    to: to,
    subject: subject,
    body: body,
    state: state,
    attempts: 0,
    createdAt: 1,
    cc: cc,
  );
}

void main() {
  group('splitOutboxRecipients', () {
    test('splits comma and semicolon lists', () {
      expect(
        splitOutboxRecipients('a@byte.io, b@byte.io; c@byte.io'),
        <String>['a@byte.io', 'b@byte.io', 'c@byte.io'],
      );
    });

    test('decodes JSON address arrays', () {
      expect(
        splitOutboxRecipients('["a@byte.io","b@byte.io"]'),
        <String>['a@byte.io', 'b@byte.io'],
      );
    });
  });

  group('SyncEngine send_outbox', () {
    test('provider throw marks failed and job is not silent success', () async {
      final _RecordingSendProvider provider = _RecordingSendProvider()
        ..throwOnSend = StateError('SMTP down');
      final _SendOutboxRepo repo = _SendOutboxRepo(
        outbox: <OutboxItem>[_queued(id: 'out-1', to: 'a@byte.io')],
      )..enqueueSendJob('work');
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => provider,
      );

      await engine.kick();

      expect(repo.outbox.single.state, 'failed');
      expect(repo.outbox.single.lastError, contains('SMTP down'));
      expect(repo.completedJobs, hasLength(1));
      expect(repo.completedJobs.single['success'], isFalse);
      expect(repo.completedJobs.single['error'], contains('Outbox send failed'));
      expect(provider.sends, isEmpty);
      expect(provider.disposeCalls, 1);
    });

    test('passes multi to and cc lists to provider', () async {
      final _RecordingSendProvider provider = _RecordingSendProvider();
      final _SendOutboxRepo repo = _SendOutboxRepo(
        outbox: <OutboxItem>[
          _queued(
            id: 'out-2',
            to: 'a@byte.io, b@byte.io',
            cc: 'c@byte.io; d@byte.io',
          ),
        ],
      )..enqueueSendJob('work');
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => provider,
      );

      await engine.kick();

      expect(repo.outbox.single.state, 'sent');
      expect(repo.completedJobs.single['success'], isTrue);
      expect(provider.sends, hasLength(1));
      expect(
        provider.sends.single['to'],
        <String>['a@byte.io', 'b@byte.io'],
      );
      expect(
        provider.sends.single['cc'],
        <String>['c@byte.io', 'd@byte.io'],
      );
    });

    test('kick reclaimSendingOutbox resets stuck sending rows', () async {
      final _RecordingSendProvider provider = _RecordingSendProvider();
      final _SendOutboxRepo repo = _SendOutboxRepo(
        outbox: <OutboxItem>[
          _queued(id: 'out-3', to: 'a@byte.io', state: 'sending'),
        ],
      )..enqueueSendJob('work');
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => provider,
      );

      await engine.kick();

      expect(repo.reclaimSendingCalls, greaterThan(0));
      expect(repo.outbox.single.state, 'sent');
      expect(provider.sends, hasLength(1));
    });

    test('skips queued items with future send_after', () async {
      final _RecordingSendProvider provider = _RecordingSendProvider();
      final int future =
          DateTime.now().millisecondsSinceEpoch + 60 * 60 * 1000;
      final _SendOutboxRepo repo = _SendOutboxRepo(
        outbox: <OutboxItem>[
          OutboxItem(
            id: 'out-sched',
            accountId: 'work',
            to: 'a@byte.io',
            subject: 'Later',
            body: 'Body',
            state: 'queued',
            attempts: 0,
            createdAt: 1,
            sendAfter: future,
          ),
        ],
      )..enqueueSendJob('work');
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => provider,
      );

      await engine.kick();

      expect(repo.outbox.single.state, 'queued');
      expect(provider.sends, isEmpty);
      expect(provider.envelopes, isEmpty);
      expect(repo.completedJobs.single['success'], isTrue);
    });
  });
}
