// ==============================================================================
// File: test/sync_engine_trash_purge_test.dart
// Description: Unit tests for SyncEngine trash_purge job and kickFresh enqueue.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePurgeProvider extends MailProvider {
  final List<String> deletedProviderIds = <String>[];
  final List<String?> deletedFolderRemoteIds = <String?>[];
  final List<String> starredProviderIds = <String>[];
  final List<String> movedProviderIds = <String>[];
  final List<String?> movedSourceFolderRemoteIds = <String?>[];
  bool failDelete = false;
  int disposeCalls = 0;

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
  Future<void> deleteMessage(
    String providerMessageId, {
    bool permanent = false,
    String? folderRemoteId,
  }) async {
    if (failDelete) {
      throw StateError('remote delete failed');
    }
    deletedProviderIds.add('$providerMessageId:$permanent');
    deletedFolderRemoteIds.add(folderRemoteId);
  }

  @override
  Future<void> setStarred(String providerMessageId, bool starred) async {
    starredProviderIds.add('$providerMessageId:$starred');
  }

  @override
  Future<void> moveMessage(
    String providerMessageId,
    String targetFolderRemoteId, {
    String? sourceFolderRemoteId,
  }) async {
    movedProviderIds.add('$providerMessageId:$targetFolderRemoteId');
    movedSourceFolderRemoteIds.add(sourceFolderRemoteId);
  }

  @override
  Future<void> dispose() async {
    disposeCalls += 1;
  }
}

class _TrashPurgeRepo implements MailRepository {
  _TrashPurgeRepo({
    this.expired = const <MailMessage>[],
    this.hasIncomplete = false,
  });

  List<MailMessage> expired;
  bool hasIncomplete;
  final List<SyncJob> pending = <SyncJob>[];
  final List<String> hardDeletedIds = <String>[];
  final List<Map<String, Object?>> completedJobs = <Map<String, Object?>>[];
  int enqueueTrashPurgeCount = 0;
  int nextJobId = 1;

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {
    if (type == SyncEngine.trashPurgeJobType) {
      enqueueTrashPurgeCount += 1;
      hasIncomplete = true;
    }
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
  Future<bool> hasIncompleteJobOfType(String type) async {
    if (type != SyncEngine.trashPurgeJobType) {
      return pending.any(
        (SyncJob job) =>
            job.type == type &&
            (job.status == 'pending' || job.status == 'running'),
      );
    }
    return hasIncomplete;
  }

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
    if (success) {
      hasIncomplete = pending.any(
        (SyncJob job) => job.type == SyncEngine.trashPurgeJobType,
      );
    }
  }

  @override
  Future<int> reclaimRunningJobs() async => 0;

  @override
  Future<int> reclaimSendingOutbox() async => 0;

  @override
  Future<List<MailMessage>> listTrashedPastRetention({
    required int retentionDays,
    DateTime? now,
  }) async => expired;

  @override
  Future<MailFolder?> getFolder(String id) async {
    return MailFolder(
      id: id,
      accountId: 'work',
      name: 'Trash',
      remoteId: 'Trash',
      role: 'trash',
    );
  }

  @override
  Future<void> hardDeleteLocal(String messageId) async {
    hardDeletedIds.add(messageId);
  }

  @override
  Future<void> hardDeleteLocalBulk(List<String> ids) async {
    hardDeletedIds.addAll(ids);
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

MailMessage _trashed({
  required String id,
  required String providerId,
  String accountId = 'work',
}) {
  return MailMessage(
    id: id,
    accountId: accountId,
    fromName: 'Maya',
    fromAddress: 'maya@byte.io',
    subject: 'Old trash',
    snippet: 's',
    body: 'b',
    whenLabel: '10:00',
    bucket: FocusBucket.focused,
    folderId: 'trash-work',
    providerId: providerId,
    trashedAt: DateTime.utc(2026, 6, 1).millisecondsSinceEpoch,
  );
}

void main() {
  group('SyncEngine trash_purge', () {
    test('kickFresh enqueues trash_purge once when none pending', () async {
      final _TrashPurgeRepo repo = _TrashPurgeRepo();
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        trashRetentionDays: () => 30,
      );

      await engine.kickFresh();
      expect(repo.enqueueTrashPurgeCount, 1);
      expect(repo.completedJobs, isNotEmpty);
      expect(repo.completedJobs.first['success'], isTrue);

      repo.hasIncomplete = false;
      await engine.kickFresh();
      expect(repo.enqueueTrashPurgeCount, 2);
    });

    test(
      'kickFresh skips enqueue when trash_purge already incomplete',
      () async {
        final _TrashPurgeRepo repo = _TrashPurgeRepo(hasIncomplete: true);
        final SyncEngine engine = SyncEngine(
          repository: repo,
          resolveProvider: (_) async => null,
          trashRetentionDays: () => 30,
        );

        await engine.kickFresh();
        expect(repo.enqueueTrashPurgeCount, 0);
      },
    );

    test('purges remote then hard-deletes local for expired trash', () async {
      final _FakePurgeProvider provider = _FakePurgeProvider();
      final _TrashPurgeRepo repo = _TrashPurgeRepo(
        expired: <MailMessage>[
          _trashed(id: 'msg-a', providerId: 'p-a'),
          _trashed(id: 'msg-b', providerId: 'p-b'),
        ],
      );
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => provider,
        trashRetentionDays: () => 30,
      );

      await repo.enqueueSyncJob(
        accountId: SyncEngine.trashPurgeAccountId,
        type: SyncEngine.trashPurgeJobType,
      );
      await engine.kick();

      expect(provider.deletedProviderIds, <String>['p-a:true', 'p-b:true']);
      expect(repo.hardDeletedIds, <String>['msg-a', 'msg-b']);
      expect(repo.completedJobs.single['success'], isTrue);
      expect(provider.disposeCalls, greaterThanOrEqualTo(2));
    });

    test('retains local rows when remote permanent delete fails', () async {
      final _FakePurgeProvider provider = _FakePurgeProvider()
        ..failDelete = true;
      final _TrashPurgeRepo repo = _TrashPurgeRepo(
        expired: <MailMessage>[
          _trashed(id: 'msg-fail', providerId: 'p-fail'),
          _trashed(id: 'msg-ok', providerId: 'p-ok'),
        ],
      );
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => provider,
        trashRetentionDays: () => 14,
      );

      await repo.enqueueSyncJob(
        accountId: SyncEngine.trashPurgeAccountId,
        type: SyncEngine.trashPurgeJobType,
      );
      await engine.kick();

      expect(provider.deletedProviderIds, isEmpty);
      expect(repo.hardDeletedIds, isEmpty);
      expect(repo.completedJobs.single['success'], isTrue);
    });

    test('reads trashRetentionDays from injected reader', () async {
      final _RecordingDaysRepo daysRepo = _RecordingDaysRepo();
      final SyncEngine engine = SyncEngine(
        repository: daysRepo,
        resolveProvider: (_) async => null,
        trashRetentionDays: () => 42,
      );

      await daysRepo.enqueueSyncJob(
        accountId: SyncEngine.trashPurgeAccountId,
        type: SyncEngine.trashPurgeJobType,
      );
      await engine.kick();
      expect(daysRepo.lastRetentionDays, 42);
      expect(daysRepo.completedSuccess, isTrue);
    });
  });

  test(
    'push_message_action dispatches star, move, and permanent delete',
    () async {
      final _FakePurgeProvider provider = _FakePurgeProvider();
      final _TrashPurgeRepo repo = _TrashPurgeRepo();
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => provider,
      );

      await repo.enqueueSyncJob(
        accountId: 'work',
        type: 'push_message_action',
        payloadJson: '{"providerId":"p-star","action":"star","starred":true}',
      );
      await repo.enqueueSyncJob(
        accountId: 'work',
        type: 'push_message_action',
        payloadJson:
            '{"providerId":"p-move","action":"move","folderRemoteId":"Archive",'
            '"sourceFolderRemoteId":"Junk"}',
      );
      await repo.enqueueSyncJob(
        accountId: 'work',
        type: 'push_message_action',
        payloadJson:
            '{"providerId":"p-delete","action":"delete","permanent":true,'
            '"folderRemoteId":"Trash"}',
      );

      await engine.kick();

      expect(provider.starredProviderIds, <String>['p-star:true']);
      expect(provider.movedProviderIds, <String>['p-move:Archive']);
      expect(provider.movedSourceFolderRemoteIds, <String?>['Junk']);
      expect(provider.deletedProviderIds, <String>['p-delete:true']);
      expect(provider.deletedFolderRemoteIds, <String?>['Trash']);
      expect(repo.completedJobs, hasLength(3));
      expect(
        repo.completedJobs.every(
          (Map<String, Object?> job) => job['success'] == true,
        ),
        isTrue,
      );
    },
  );
}

/// Thin repo that records retention days asked by trash_purge.
class _RecordingDaysRepo implements MailRepository {
  int? lastRetentionDays;
  bool completedSuccess = false;
  final List<SyncJob> pending = <SyncJob>[];

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {
    pending.add(
      SyncJob(
        id: 'job-1',
        accountId: accountId,
        type: type,
        status: 'pending',
        updatedAt: 1,
        payloadJson: payloadJson,
      ),
    );
  }

  @override
  Future<bool> hasIncompleteJobOfType(String type) async => false;

  @override
  Future<List<SyncJob>> claimPendingJobs({int limit = 10}) async {
    if (pending.isEmpty) {
      return const <SyncJob>[];
    }
    final List<SyncJob> claimed = List<SyncJob>.from(pending);
    pending.clear();
    return claimed;
  }

  @override
  Future<void> completeJob(
    String id, {
    required bool success,
    String? cursorJson,
    String? error,
  }) async {
    completedSuccess = success;
  }

  @override
  Future<int> reclaimRunningJobs() async => 0;

  @override
  Future<int> reclaimSendingOutbox() async => 0;

  @override
  Future<List<MailMessage>> listTrashedPastRetention({
    required int retentionDays,
    DateTime? now,
  }) async {
    lastRetentionDays = retentionDays;
    return const <MailMessage>[];
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
