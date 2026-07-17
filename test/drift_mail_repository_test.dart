import 'package:bytemail/domain/models.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/database.dart' hide FocusRule;
import 'package:bytemail/repository/drift_mail_repository.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<DriftMailRepository> _openTestRepo() async {
  final ByteMailDatabase database = ByteMailDatabase(NativeDatabase.memory());
  final DriftMailRepository repo = DriftMailRepository(database);
  await repo.upsertAccount(
    const MailAccount(
      id: 'work',
      label: 'W',
      address: 'work@byte.io',
      accent: Color(0xFF2DD4BF),
    ),
    providerType: 'imap',
  );
  await repo.upsertFolders(const <MailFolder>[
    MailFolder(
      id: 'inbox-work',
      accountId: 'work',
      name: 'Inbox',
      remoteId: 'INBOX',
      role: 'inbox',
      unreadCount: 2,
    ),
  ]);
  await repo.upsertMessages(const <MailMessage>[
    MailMessage(
      id: 'msg-1',
      accountId: 'work',
      fromName: 'A',
      fromAddress: 'a@byte.io',
      subject: 'One',
      snippet: 's1',
      body: 'b1',
      whenLabel: '10:00',
      bucket: FocusBucket.focused,
      unread: true,
      folderId: 'inbox-work',
      providerId: '101',
    ),
    MailMessage(
      id: 'msg-2',
      accountId: 'work',
      fromName: 'B',
      fromAddress: 'b@byte.io',
      subject: 'Two',
      snippet: 's2',
      body: 'b2',
      whenLabel: '11:00',
      bucket: FocusBucket.focused,
      unread: true,
      folderId: 'inbox-work',
      providerId: '102',
    ),
    MailMessage(
      id: 'msg-3',
      accountId: 'work',
      fromName: 'C',
      fromAddress: 'c@byte.io',
      subject: 'Three',
      snippet: 's3',
      body: 'b3',
      whenLabel: '12:00',
      bucket: FocusBucket.focused,
      unread: false,
      folderId: 'inbox-work',
      providerId: '103',
    ),
  ], folderId: 'inbox-work');
  return repo;
}

Future<DriftMailRepository> _openWipeTestRepo() async {
  final ByteMailDatabase database = ByteMailDatabase(NativeDatabase.memory());
  final DriftMailRepository repo = DriftMailRepository(database);
  await repo.upsertAccount(
    const MailAccount(
      id: 'work',
      label: 'W',
      address: 'work@byte.io',
      accent: Color(0xFF2DD4BF),
      credentialsRef: 'imap:work',
    ),
    providerType: 'imap',
  );
  await repo.upsertFolders(const <MailFolder>[
    MailFolder(
      id: 'inbox-work',
      accountId: 'work',
      name: 'Inbox',
      remoteId: 'INBOX',
      role: 'inbox',
      unreadCount: 1,
    ),
  ]);
  await repo.upsertMessages(const <MailMessage>[
    MailMessage(
      id: 'msg-1',
      accountId: 'work',
      fromName: 'A',
      fromAddress: 'a@byte.io',
      subject: 'One',
      snippet: 's1',
      body: 'b1',
      whenLabel: '10:00',
      bucket: FocusBucket.focused,
      unread: true,
      folderId: 'inbox-work',
      providerId: '101',
    ),
  ], folderId: 'inbox-work');
  await repo.enqueueOutbox(
    accountId: 'work',
    to: 'b@byte.io',
    subject: 'Queued',
    body: 'Body',
  );
  await repo.enqueueSyncJob(accountId: 'work', type: 'bootstrap');
  await repo.upsertFocusRule(
    const FocusRule(
      id: 'rule-work',
      accountId: 'work',
      pattern: '@byte.io',
      matchType: FocusRuleMatchType.domain,
      bucket: FocusBucket.focused,
    ),
  );
  await repo.upsertWidgetSnapshot(
    'work-counter',
    'counter',
    '{"accountId":"work","unreadCount":1}',
  );
  await repo.upsertWidgetSnapshot(
    'mail_list',
    'list',
    '{"messages":[{"id":"msg-1","accountId":"work","subject":"One"}]}',
  );
  await repo.upsertWidgetSnapshot(
    'mail_counter',
    'counter',
    '{"unreadCount":1,"totalCount":1}',
  );
  return repo;
}

void main() {
  group('DriftMailRepository.wipeAccount', () {
    test('removes all account-scoped rows', () async {
      final DriftMailRepository repo = await _openWipeTestRepo();
      await repo.wipeAccount('work');

      expect(await repo.listAccounts(), isEmpty);
      expect(await repo.listFolders(accountId: 'work'), isEmpty);
      expect(
        await repo.listMessages(const MessageQuery(accountId: 'work')),
        isEmpty,
      );
      expect(await repo.listOutbox(), isEmpty);
      expect(await repo.claimPendingJobs(limit: 10), isEmpty);
      expect(await repo.listFocusRules(accountId: 'work'), isEmpty);
      expect(await repo.getWidgetSnapshot('work-counter'), isNull);
      expect(await repo.getWidgetSnapshot('mail_list'), isNull);
      // Aggregate counter has no accountId — wipe leaves it for refresh rebuild.
      expect(await repo.getWidgetSnapshot('mail_counter'), isNotNull);
    });
  });

  group('DriftMailRepository.setUnreadBulk', () {
    test('empty ids is a no-op', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.setUnreadBulk(const <String>[], false);
      final MailFolder? folder = await repo.getFolder('inbox-work');
      expect(folder?.unreadCount, 2);
    });

    test('mark read decrements folder unreadCount', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.setUnreadBulk(const <String>['msg-1'], false);
      final MailMessage? message = await repo.getMessage('msg-1');
      final MailFolder? folder = await repo.getFolder('inbox-work');
      expect(message?.unread, isFalse);
      expect(folder?.unreadCount, 1);
    });

    test('bulk mark read applies net delta once per folder', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.setUnreadBulk(const <String>['msg-1', 'msg-2'], false);
      final MailFolder? folder = await repo.getFolder('inbox-work');
      expect(folder?.unreadCount, 0);
    });

    test('skips messages already in target state', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.setUnreadBulk(const <String>['msg-3'], false);
      final MailFolder? folder = await repo.getFolder('inbox-work');
      expect(folder?.unreadCount, 2);
    });

    test('mark unread increments folder unreadCount', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.setUnreadBulk(const <String>['msg-3'], true);
      final MailMessage? message = await repo.getMessage('msg-3');
      final MailFolder? folder = await repo.getFolder('inbox-work');
      expect(message?.unread, isTrue);
      expect(folder?.unreadCount, 3);
    });

    test('recount corrects stale folder unreadCount after mark read', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.upsertFolders(const <MailFolder>[
        MailFolder(
          id: 'inbox-work',
          accountId: 'work',
          name: 'Inbox',
          remoteId: 'INBOX',
          role: 'inbox',
          unreadCount: 99,
        ),
      ]);
      await repo.setUnreadBulk(const <String>['msg-1'], false);
      final MailFolder? folder = await repo.getFolder('inbox-work');
      expect(folder?.unreadCount, 1);
    });
  });

  group('DriftMailRepository.recountUnreadCounts', () {
    test('excludes drafts, trashed, and actively snoozed unread', () async {
      final DriftMailRepository repo = await _openTestRepo();
      final int now = DateTime.now().millisecondsSinceEpoch;
      await repo.upsertFolders(const <MailFolder>[
        MailFolder(
          id: 'inbox-work',
          accountId: 'work',
          name: 'Inbox',
          remoteId: 'INBOX',
          role: 'inbox',
          unreadCount: 99,
        ),
      ]);
      await repo.upsertMessages(<MailMessage>[
        MailMessage(
          id: 'msg-draft',
          accountId: 'work',
          fromName: 'D',
          fromAddress: 'd@byte.io',
          subject: 'Draft',
          snippet: 'd',
          body: 'd',
          whenLabel: '13:00',
          bucket: FocusBucket.focused,
          unread: true,
          isDraft: true,
          folderId: 'inbox-work',
          providerId: '104',
        ),
        MailMessage(
          id: 'msg-trash',
          accountId: 'work',
          fromName: 'T',
          fromAddress: 't@byte.io',
          subject: 'Trash',
          snippet: 't',
          body: 't',
          whenLabel: '14:00',
          bucket: FocusBucket.focused,
          unread: true,
          trashedAt: now,
          folderId: 'inbox-work',
          providerId: '105',
        ),
        MailMessage(
          id: 'msg-snooze',
          accountId: 'work',
          fromName: 'S',
          fromAddress: 's@byte.io',
          subject: 'Snooze',
          snippet: 's',
          body: 's',
          whenLabel: '15:00',
          bucket: FocusBucket.focused,
          unread: true,
          snoozedUntil: now + 60_000,
          folderId: 'inbox-work',
          providerId: '106',
        ),
        MailMessage(
          id: 'msg-expired-snooze',
          accountId: 'work',
          fromName: 'E',
          fromAddress: 'e@byte.io',
          subject: 'Expired',
          snippet: 'e',
          body: 'e',
          whenLabel: '16:00',
          bucket: FocusBucket.focused,
          unread: true,
          snoozedUntil: now - 1,
          folderId: 'inbox-work',
          providerId: '107',
        ),
      ], folderId: 'inbox-work');

      // upsertMessages already recounts; force a stale badge then recount.
      await repo.upsertFolders(const <MailFolder>[
        MailFolder(
          id: 'inbox-work',
          accountId: 'work',
          name: 'Inbox',
          remoteId: 'INBOX',
          role: 'inbox',
          unreadCount: 99,
        ),
      ]);
      await repo.recountUnreadCounts();
      final MailFolder? folder = await repo.getFolder('inbox-work');
      // msg-1, msg-2, msg-expired-snooze (draft/trash/active-snooze excluded).
      expect(folder?.unreadCount, 3);
    });

    test('updates after mark read', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.recountUnreadCounts();
      expect((await repo.getFolder('inbox-work'))?.unreadCount, 2);
      await repo.setUnreadBulk(const <String>['msg-1', 'msg-2'], false);
      expect((await repo.getFolder('inbox-work'))?.unreadCount, 0);
    });
  });

  group('DriftMailRepository.updateMessageRawHeaders', () {
    test('persists and round-trips raw header text', () async {
      final DriftMailRepository repo = await _openTestRepo();
      const String headers =
          'From: a@byte.io\nTo: b@byte.io\nSubject: One\nMessage-ID: <abc>';
      await repo.updateMessageRawHeaders('msg-1', headers);
      final MailMessage? message = await repo.getMessage('msg-1');
      expect(message?.rawHeaders, headers);
    });

    test('header sync upsert preserves cached raw headers', () async {
      final DriftMailRepository repo = await _openTestRepo();
      const String headers = 'From: a@byte.io\nTo: b@byte.io';
      await repo.updateMessageRawHeaders('msg-1', headers);
      await repo.upsertMessages(const <MailMessage>[
        MailMessage(
          id: 'msg-1',
          accountId: 'work',
          fromName: 'A',
          fromAddress: 'a@byte.io',
          subject: 'One updated',
          snippet: 's1',
          body: 'b1',
          whenLabel: '10:00',
          bucket: FocusBucket.focused,
          unread: false,
          folderId: 'inbox-work',
          providerId: '101',
        ),
      ], folderId: 'inbox-work');
      final MailMessage? message = await repo.getMessage('msg-1');
      expect(message?.rawHeaders, headers);
      expect(message?.subject, 'One updated');
    });
  });

  group('DriftMailRepository outbox recipients', () {
    test('enqueue splits multi to/cc into JSON arrays', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.enqueueOutbox(
        accountId: 'work',
        to: 'a@byte.io, b@byte.io',
        subject: 'Multi',
        body: 'Body',
        cc: 'c@byte.io; d@byte.io',
      );
      final List<OutboxItem> items = await repo.listOutbox();
      expect(items, hasLength(1));
      expect(items.single.to, 'a@byte.io, b@byte.io');
      expect(items.single.cc, 'c@byte.io, d@byte.io');
    });

    test('reclaimSendingOutbox resets sending to queued', () async {
      final DriftMailRepository repo = await _openTestRepo();
      final String id = await repo.enqueueOutbox(
        accountId: 'work',
        to: 'a@byte.io',
        subject: 'Stuck',
        body: 'Body',
      );
      await repo.updateOutboxState(id, 'sending');
      expect((await repo.listOutbox()).single.state, 'sending');
      expect(await repo.reclaimSendingOutbox(), 1);
      expect((await repo.listOutbox()).single.state, 'queued');
    });

    test('syncStatusLabel mentions failed outbox', () async {
      final DriftMailRepository repo = await _openTestRepo();
      final String id = await repo.enqueueOutbox(
        accountId: 'work',
        to: 'a@byte.io',
        subject: 'Fail',
        body: 'Body',
      );
      await repo.updateOutboxState(id, 'failed', error: 'SMTP down');
      expect(await repo.syncStatusLabel(), 'Outbox send failed');
      expect(await repo.countFailedOutbox(), 1);
      expect(await repo.countQueuedOutbox(), 0);
    });

    test('deleteOutbox and deleteOutboxInStates clear rows', () async {
      final DriftMailRepository repo = await _openTestRepo();
      final String queuedId = await repo.enqueueOutbox(
        accountId: 'work',
        to: 'a@byte.io',
        subject: 'Queued',
        body: 'Body',
      );
      final String failedId = await repo.enqueueOutbox(
        accountId: 'work',
        to: 'b@byte.io',
        subject: 'Failed',
        body: 'Body',
      );
      await repo.updateOutboxState(failedId, 'failed', error: 'nope');
      await repo.deleteOutbox(queuedId);
      expect(await repo.listOutbox(), hasLength(1));
      expect(await repo.deleteOutboxInStates(<String>['failed']), 1);
      expect(await repo.listOutbox(), isEmpty);
    });

    test('syncStatusLabel mentions pending queued outbox', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.enqueueOutbox(
        accountId: 'work',
        to: 'a@byte.io',
        subject: 'Pending',
        body: 'Body',
      );
      expect(await repo.countQueuedOutbox(), 1);
      expect(await repo.syncStatusLabel(), '1 waiting to send');
    });
  });

  group('DriftMailRepository sync job viewer', () {
    test('listSyncJobs returns newest first', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.enqueueSyncJob(accountId: 'work', type: 'incremental');
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repo.enqueueSyncJob(accountId: 'work', type: 'full_folder');
      final List<SyncJob> jobs = await repo.listSyncJobs(limit: 10);
      expect(jobs.length, greaterThanOrEqualTo(2));
      expect(jobs.first.type, 'full_folder');
      expect(jobs.first.status, 'pending');
    });

    test('retrySyncJob resets failed to pending and clears error', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.enqueueSyncJob(accountId: 'work', type: 'incremental');
      final List<SyncJob> claimed = await repo.claimPendingJobs(limit: 10);
      final SyncJob job = claimed.firstWhere(
        (SyncJob j) => j.type == 'incremental',
      );
      await repo.completeJob(job.id, success: false, error: 'boom');
      final SyncJob failed = (await repo.listSyncJobs())
          .firstWhere((SyncJob j) => j.id == job.id);
      expect(failed.status, 'failed');
      expect(failed.errorSnippet, 'boom');

      await repo.retrySyncJob(job.id);
      final SyncJob retried = (await repo.listSyncJobs())
          .firstWhere((SyncJob j) => j.id == job.id);
      expect(retried.status, 'pending');
      expect(retried.errorSnippet, isNull);
    });

    test('retrySyncJob re-enqueues done jobs of same type', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.enqueueSyncJob(accountId: 'work', type: 'bootstrap');
      final List<SyncJob> claimed = await repo.claimPendingJobs(limit: 10);
      final SyncJob job = claimed.firstWhere(
        (SyncJob j) => j.type == 'bootstrap',
      );
      await repo.completeJob(job.id, success: true);
      final int before = (await repo.listSyncJobs()).length;
      await repo.retrySyncJob(job.id);
      final List<SyncJob> after = await repo.listSyncJobs();
      expect(after.length, before + 1);
      expect(
        after.where(
          (SyncJob j) => j.type == 'bootstrap' && j.status == 'pending',
        ),
        isNotEmpty,
      );
    });

    test('cancelSyncJob deletes pending only', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.enqueueSyncJob(accountId: 'work', type: 'incremental');
      final SyncJob pending = (await repo.listSyncJobs())
          .firstWhere((SyncJob j) => j.type == 'incremental');
      await repo.cancelSyncJob(pending.id);
      expect(
        (await repo.listSyncJobs()).where((SyncJob j) => j.id == pending.id),
        isEmpty,
      );

      await repo.enqueueSyncJob(accountId: 'work', type: 'full_folder');
      final List<SyncJob> claimed = await repo.claimPendingJobs(limit: 10);
      final SyncJob running = claimed.firstWhere(
        (SyncJob j) => j.type == 'full_folder',
      );
      await repo.completeJob(running.id, success: false, error: 'x');
      await repo.cancelSyncJob(running.id);
      expect(
        (await repo.listSyncJobs()).where((SyncJob j) => j.id == running.id),
        isNotEmpty,
      );
    });

    test('listAccountSyncHealth aggregates counts and last error', () async {
      final DriftMailRepository repo = await _openTestRepo();
      await repo.enqueueSyncJob(accountId: 'work', type: 'incremental');
      await repo.enqueueSyncJob(accountId: 'work', type: 'full_folder');
      final List<SyncJob> claimed = await repo.claimPendingJobs(limit: 1);
      await repo.completeJob(claimed.single.id, success: false, error: 'net');
      await repo.setCursor(
        'work',
        'inbox-work',
        'inbox',
        '2026-07-17T18:00:00.000Z',
      );

      final List<AccountSyncHealth> health = await repo.listAccountSyncHealth();
      expect(health, hasLength(1));
      expect(health.single.accountId, 'work');
      expect(health.single.failedCount, 1);
      expect(health.single.pendingCount, greaterThanOrEqualTo(1));
      expect(health.single.lastError, 'net');
      expect(health.single.lastSuccessAt, isNotNull);
    });
  });
}
