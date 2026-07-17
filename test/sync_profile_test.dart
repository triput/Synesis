// ==============================================================================
// File: test/sync_profile_test.dart
// Description: Sync profile resolve, retention scope, folder skip, body policy
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/mailbox/message_body_cache.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/database.dart' hide FocusRule, SyncProfile;
import 'package:bytemail/repository/drift_mail_repository.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/ui/mailbox/mailbox_state.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<DriftMailRepository> _openRepo() async {
  final ByteMailDatabase database = ByteMailDatabase(NativeDatabase.memory());
  return DriftMailRepository(database);
}

MailMessage _msg({
  required String id,
  required String accountId,
  required int whenEpochMs,
  String folderId = 'inbox-a',
  bool pinned = false,
  String? body,
  String? snippet,
  String? providerId,
}) {
  return MailMessage(
    id: id,
    accountId: accountId,
    fromName: 'S',
    fromAddress: 's@byte.io',
    subject: 'Subj $id',
    snippet: snippet ?? 'snippet',
    body: body ?? 'snippet',
    whenLabel: '10:00',
    bucket: FocusBucket.focused,
    folderId: folderId,
    providerId: providerId ?? id,
    whenEpochMs: whenEpochMs,
    pinned: pinned,
  );
}

class _RecordingBodyProvider extends MailProvider {
  int fetchBodyCalls = 0;

  @override
  MailCapabilities get capabilities => const MailCapabilities(
    supportsServerSearch: false,
    supportsPush: false,
    supportsPartialBody: false,
    supportsSend: false,
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
  }) async =>
      const <RemoteMessageHeader>[];

  @override
  Future<String?> fetchBody(
    String providerId, {
    String? folderRemoteId,
  }) async {
    fetchBodyCalls += 1;
    return '<p>full body</p>';
  }

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
  Future<void> deleteMessage(
    String providerId, {
    bool permanent = false,
    String? folderRemoteId,
  }) async {}

  @override
  Future<void> dispose() async {}
}

class _ScopeProvider extends MailProvider {
  final List<String> inboxFetches = <String>[];
  final List<String> folderFetches = <String>[];

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
    RemoteFolder(providerId: 'Sent', name: 'Sent', role: 'sent'),
  ];

  @override
  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50}) async {
    inboxFetches.add('inbox');
    return const <RemoteMessageHeader>[];
  }

  @override
  Future<List<RemoteMessageHeader>> listRecentInFolder(
    String folderRemoteId, {
    int limit = 50,
  }) async {
    folderFetches.add(folderRemoteId);
    return const <RemoteMessageHeader>[];
  }

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
  Future<void> deleteMessage(
    String providerId, {
    bool permanent = false,
    String? folderRemoteId,
  }) async {}

  @override
  Future<void> dispose() async {}
}

void main() {
  group('ResolvedSyncPolicy.allowsFolder', () {
    test('null scope allows all; roles and remote ids match', () {
      const ResolvedSyncPolicy all = ResolvedSyncPolicy(
        accountId: 'a',
        profileId: 'default',
        retentionDays: 180,
        bodyPolicy: BodyFetchPolicy.onOpen,
        attachmentMaxMb: 25,
      );
      expect(all.allowsFolder(role: 'inbox', remoteId: 'INBOX'), isTrue);

      const ResolvedSyncPolicy scoped = ResolvedSyncPolicy(
        accountId: 'a',
        profileId: 'travel',
        retentionDays: 14,
        folderScope: <String>['inbox', 'SentItems'],
        bodyPolicy: BodyFetchPolicy.headersOnly,
        attachmentMaxMb: 10,
      );
      expect(scoped.allowsFolder(role: 'inbox', remoteId: 'INBOX'), isTrue);
      expect(
        scoped.allowsFolder(role: 'sent', remoteId: 'SentItems'),
        isTrue,
      );
      expect(scoped.allowsFolder(role: 'archive', remoteId: 'Archive'), isFalse);
    });
  });

  group('SyncProfile.resolvePolicy', () {
    test('override > profile > device fallback', () async {
      final DriftMailRepository repo = await _openRepo();
      await repo.upsertSyncProfile(
        const SyncProfile(
          id: 'travel',
          name: 'Travel',
          retentionDays: 14,
          bodyPolicy: BodyFetchPolicy.headersOnly,
          attachmentMaxMb: 5,
          isDefault: false,
        ),
      );
      await repo.upsertAccount(
        const MailAccount(
          id: 'acct-override',
          label: 'A',
          address: 'a@byte.io',
          accent: Color(0xFF2563EB),
          syncProfileId: 'travel',
          retentionDaysOverride: 7,
        ),
        providerType: 'imap',
      );
      await repo.upsertAccount(
        const MailAccount(
          id: 'acct-profile',
          label: 'B',
          address: 'b@byte.io',
          accent: Color(0xFF0F766E),
          syncProfileId: 'travel',
        ),
        providerType: 'imap',
      );
      await repo.upsertAccount(
        const MailAccount(
          id: 'acct-fallback',
          label: 'C',
          address: 'c@byte.io',
          accent: Color(0xFFEA4335),
        ),
        providerType: 'imap',
      );

      final ResolvedSyncPolicy overridePolicy = await repo.resolvePolicy(
        'acct-override',
        fallbackRetentionDays: 99,
      );
      expect(overridePolicy.retentionDays, 7);
      expect(overridePolicy.profileId, 'travel');
      expect(overridePolicy.bodyPolicy, BodyFetchPolicy.headersOnly);
      expect(overridePolicy.attachmentMaxMb, 5);

      final ResolvedSyncPolicy profilePolicy = await repo.resolvePolicy(
        'acct-profile',
        fallbackRetentionDays: 99,
      );
      expect(profilePolicy.retentionDays, 14);

      final ResolvedSyncPolicy defaultPolicy = await repo.resolvePolicy(
        'acct-fallback',
        fallbackRetentionDays: 99,
      );
      expect(defaultPolicy.profileId, 'default');
      expect(defaultPolicy.retentionDays, 180);
    });

    test('attachment max persists on upsert', () async {
      final DriftMailRepository repo = await _openRepo();
      final SyncProfile? seeded = await repo.getDefaultSyncProfile();
      expect(seeded, isNotNull);
      expect(seeded!.attachmentMaxMb, 25);

      await repo.upsertSyncProfile(
        seeded.copyWith(attachmentMaxMb: 40),
      );
      final SyncProfile? updated = await repo.getDefaultSyncProfile();
      expect(updated!.attachmentMaxMb, 40);
      expect(updated.bodyPolicy, BodyFetchPolicy.onOpen);
    });
  });

  group('applyRetention account scope', () {
    test('accountId only deletes that account', () async {
      final DriftMailRepository repo = await _openRepo();
      await repo.upsertAccount(
        const MailAccount(
          id: 'a1',
          label: 'A',
          address: 'a@byte.io',
          accent: Color(0xFF2563EB),
        ),
        providerType: 'imap',
      );
      await repo.upsertAccount(
        const MailAccount(
          id: 'a2',
          label: 'B',
          address: 'b@byte.io',
          accent: Color(0xFF0F766E),
        ),
        providerType: 'imap',
      );
      await repo.upsertFolders(const <MailFolder>[
        MailFolder(
          id: 'inbox-a1',
          accountId: 'a1',
          name: 'Inbox',
          remoteId: 'INBOX',
          role: 'inbox',
        ),
        MailFolder(
          id: 'inbox-a2',
          accountId: 'a2',
          name: 'Inbox',
          remoteId: 'INBOX',
          role: 'inbox',
        ),
      ]);
      final int oldMs = DateTime.now()
          .subtract(const Duration(days: 40))
          .millisecondsSinceEpoch;
      await repo.upsertMessages(<MailMessage>[
        _msg(id: 'm1', accountId: 'a1', whenEpochMs: oldMs, folderId: 'inbox-a1'),
      ], folderId: 'inbox-a1');
      await repo.upsertMessages(<MailMessage>[
        _msg(id: 'm2', accountId: 'a2', whenEpochMs: oldMs, folderId: 'inbox-a2'),
      ], folderId: 'inbox-a2');

      final int removed = await repo.applyRetention(
        retentionDays: 30,
        accountId: 'a1',
      );
      expect(removed, 1);
      expect(await repo.getMessage('m1'), isNull);
      expect(await repo.getMessage('m2'), isNotNull);
    });
  });

  group('SyncEngine folder scope', () {
    test('skips inbox sync when scope excludes inbox', () async {
      final DriftMailRepository repo = await _openRepo();
      await repo.upsertSyncProfile(
        const SyncProfile(
          id: 'sent-only',
          name: 'Sent only',
          retentionDays: 30,
          folderScope: <String>['sent'],
          bodyPolicy: BodyFetchPolicy.onOpen,
          attachmentMaxMb: 25,
          isDefault: false,
        ),
      );
      await repo.upsertAccount(
        const MailAccount(
          id: 'acct',
          label: 'A',
          address: 'a@byte.io',
          accent: Color(0xFF2563EB),
          syncProfileId: 'sent-only',
        ),
        providerType: 'imap',
      );
      final _ScopeProvider provider = _ScopeProvider();
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (String id) async => provider,
      );
      await repo.enqueueSyncJob(accountId: 'acct', type: 'bootstrap');
      await engine.kick();
      expect(provider.inboxFetches, isEmpty);

      await repo.enqueueSyncJob(
        accountId: 'acct',
        type: 'full_folder',
        payloadJson: jsonEncode(<String, String>{
          'folderId': 'sent-acct',
          'remoteId': 'Sent',
        }),
      );
      await repo.upsertFolders(const <MailFolder>[
        MailFolder(
          id: 'sent-acct',
          accountId: 'acct',
          name: 'Sent',
          remoteId: 'Sent',
          role: 'sent',
        ),
      ]);
      await engine.kick();
      expect(provider.folderFetches, contains('Sent'));
    });
  });

  group('MessageBodyCache bodyPolicy', () {
    test('headersOnly blocks ensureBodyCached', () async {
      final DriftMailRepository repo = await _openRepo();
      await repo.upsertSyncProfile(
        const SyncProfile(
          id: 'headers',
          name: 'Headers',
          retentionDays: 30,
          bodyPolicy: BodyFetchPolicy.headersOnly,
          attachmentMaxMb: 25,
          isDefault: false,
        ),
      );
      await repo.upsertAccount(
        const MailAccount(
          id: 'acct',
          label: 'A',
          address: 'a@byte.io',
          accent: Color(0xFF2563EB),
          syncProfileId: 'headers',
        ),
        providerType: 'imap',
      );
      await repo.upsertFolders(const <MailFolder>[
        MailFolder(
          id: 'inbox-acct',
          accountId: 'acct',
          name: 'Inbox',
          remoteId: 'INBOX',
          role: 'inbox',
        ),
      ]);
      final MailMessage message = _msg(
        id: 'msg-1',
        accountId: 'acct',
        whenEpochMs: DateTime.now().millisecondsSinceEpoch,
        folderId: 'inbox-acct',
        body: 'snippet',
        snippet: 'snippet',
        providerId: 'p1',
      );
      await repo.upsertMessages(<MailMessage>[message], folderId: 'inbox-acct');

      final _RecordingBodyProvider provider = _RecordingBodyProvider();
      final MessageBodyCache cache = MessageBodyCache(
        repository: repo,
        resolveProvider: (String id) async => provider,
      );
      final MailboxState state = MailboxState(
        messages: <MailMessage>[message],
        selectedMessageId: message.id,
      );
      final result = await cache.ensureBodyCached(
        state,
        message.id,
        isClosed: () => false,
        currentState: () => state,
      );
      expect(result, isNull);
      expect(provider.fetchBodyCalls, 0);
    });
  });
}
