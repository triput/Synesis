// ==============================================================================
// File: test/message_query_test.dart
// Description: MessageQuery predicate stacking and Drift SQL filter coverage.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/database.dart' hide FocusRule;
import 'package:bytemail/repository/drift_mail_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MailMessage _msg({
  required String id,
  bool starred = false,
  bool pinned = false,
  bool unread = false,
  bool hasAttachments = false,
  int? snoozedUntil,
  int? trashedAt,
  bool isDraft = false,
  FocusBucket bucket = FocusBucket.focused,
  String folderId = 'inbox-work',
  String fromName = 'A',
  String fromAddress = 'a@byte.io',
  String subject = '',
  String snippet = 's',
  String body = 'b',
  String? threadId,
  String toRecipients = '',
  String ccRecipients = '',
  String? rawHeaders,
  int whenEpochMs = 1000,
}) {
  return MailMessage(
    id: id,
    accountId: 'work',
    fromName: fromName,
    fromAddress: fromAddress,
    subject: subject.isEmpty ? id : subject,
    snippet: snippet,
    body: body,
    whenLabel: '10:00',
    bucket: bucket,
    folderId: folderId,
    starred: starred,
    pinned: pinned,
    unread: unread,
    hasAttachments: hasAttachments,
    snoozedUntil: snoozedUntil,
    trashedAt: trashedAt,
    isDraft: isDraft,
    threadId: threadId,
    toRecipients: toRecipients,
    ccRecipients: ccRecipients,
    rawHeaders: rawHeaders,
    whenEpochMs: whenEpochMs,
  );
}

void main() {
  group('MessageQuery.matches predicate stacking', () {
    final DateTime now = DateTime.fromMillisecondsSinceEpoch(1_000_000);

    test('defaults exclude future snooze, drafts, and trash', () {
      const MessageQuery query = MessageQuery.defaults;
      expect(query.matches(_msg(id: 'ok'), now: now), isTrue);
      expect(
        query.matches(
          _msg(id: 'snoozed', snoozedUntil: now.millisecondsSinceEpoch + 1),
          now: now,
        ),
        isFalse,
      );
      expect(
        query.matches(
          _msg(id: 'expired', snoozedUntil: now.millisecondsSinceEpoch - 1),
          now: now,
        ),
        isTrue,
      );
      expect(
        query.matches(_msg(id: 'draft', isDraft: true), now: now),
        isFalse,
      );
      expect(query.matches(_msg(id: 'trash', trashedAt: 1), now: now), isFalse);
    });

    test('starredOnly stacks with trash exclusion', () {
      final MessageQuery query = MessageQuery.defaults.copyWith(
        starredOnly: true,
      );
      expect(query.matches(_msg(id: 'star', starred: true), now: now), isTrue);
      expect(
        query.matches(_msg(id: 'plain', starred: false), now: now),
        isFalse,
      );
      expect(
        query.matches(
          _msg(id: 'star-trash', starred: true, trashedAt: 9),
          now: now,
        ),
        isFalse,
      );
    });

    test('pinnedOnly and snoozedOnly filters', () {
      expect(
        MessageQuery.defaults
            .copyWith(pinnedOnly: true)
            .matches(_msg(id: 'pin', pinned: true), now: now),
        isTrue,
      );
      expect(
        MessageQuery.defaults
            .copyWith(pinnedOnly: true)
            .matches(_msg(id: 'plain'), now: now),
        isFalse,
      );

      final MessageQuery snoozedView = MessageQuery.defaults.copyWith(
        snoozedOnly: true,
        excludeSnoozed: false,
      );
      expect(
        snoozedView.matches(
          _msg(id: 'future', snoozedUntil: now.millisecondsSinceEpoch + 10),
          now: now,
        ),
        isTrue,
      );
      expect(
        snoozedView.matches(_msg(id: 'none'), now: now),
        isFalse,
      );
      expect(
        snoozedView.matches(
          _msg(id: 'past', snoozedUntil: now.millisecondsSinceEpoch - 10),
          now: now,
        ),
        isFalse,
      );
    });

    test('userFilter unread, sender, date, keyword, attachments', () {
      final MessageQuery unreadQuery = MessageQuery.defaults.copyWith(
        userFilter: const MessageViewFilter(unread: true),
      );
      expect(
        unreadQuery.matches(_msg(id: 'u', unread: true), now: now),
        isTrue,
      );
      expect(
        unreadQuery.matches(_msg(id: 'r', unread: false), now: now),
        isFalse,
      );

      final MessageQuery senderQuery = MessageQuery.defaults.copyWith(
        userFilter: const MessageViewFilter(senderContains: 'Byte'),
      );
      expect(
        senderQuery.matches(
          _msg(id: 'hit', fromAddress: 'ops@byte.io'),
          now: now,
        ),
        isTrue,
      );
      expect(
        senderQuery.matches(
          _msg(id: 'miss', fromAddress: 'other@x.io', fromName: 'Other'),
          now: now,
        ),
        isFalse,
      );

      final MessageQuery dateQuery = MessageQuery.defaults.copyWith(
        userFilter: const MessageViewFilter(
          receivedAfterEpochMs: 500,
          receivedBeforeEpochMs: 1500,
        ),
      );
      expect(
        dateQuery.matches(_msg(id: 'in', whenEpochMs: 1000), now: now),
        isTrue,
      );
      expect(
        dateQuery.matches(_msg(id: 'early', whenEpochMs: 100), now: now),
        isFalse,
      );
      expect(
        dateQuery.matches(_msg(id: 'late', whenEpochMs: 2000), now: now),
        isFalse,
      );

      final MessageQuery keywordQuery = MessageQuery.defaults.copyWith(
        userFilter: const MessageViewFilter(keyword: 'invoice'),
      );
      expect(
        keywordQuery.matches(
          _msg(id: 'k', subject: 'Your Invoice'),
          now: now,
        ),
        isTrue,
      );
      expect(
        keywordQuery.matches(_msg(id: 'no', subject: 'Hello'), now: now),
        isFalse,
      );

      final MessageQuery attachQuery = MessageQuery.defaults.copyWith(
        userFilter: const MessageViewFilter(hasAttachments: true),
      );
      expect(
        attachQuery.matches(
          _msg(id: 'a', hasAttachments: true),
          now: now,
        ),
        isTrue,
      );
      expect(
        attachQuery.matches(_msg(id: 'plain'), now: now),
        isFalse,
      );

      final MessageQuery recipientQuery = MessageQuery.defaults.copyWith(
        userFilter: const MessageViewFilter(recipientContains: 'carol'),
      );
      expect(
        recipientQuery.matches(
          _msg(
            id: 'to-hit',
            toRecipients: 'Bob <bob@example.com>, Carol <carol@example.com>',
          ),
          now: now,
        ),
        isTrue,
      );
      expect(
        recipientQuery.matches(
          _msg(
            id: 'cc-hit',
            ccRecipients: 'Carol <carol@example.com>',
          ),
          now: now,
        ),
        isTrue,
      );
      expect(
        recipientQuery.matches(
          _msg(id: 'miss', toRecipients: 'bob@example.com'),
          now: now,
        ),
        isFalse,
      );

      final MessageQuery rawRecipientQuery = MessageQuery.defaults.copyWith(
        userFilter: const MessageViewFilter(recipientContains: 'eve@'),
      );
      expect(
        rawRecipientQuery.matches(
          _msg(
            id: 'raw-hit',
            rawHeaders: 'To: Bob <bob@example.com>\nCc: Eve <eve@example.com>\n',
          ),
          now: now,
        ),
        isTrue,
      );
    });

    test('include flags relax draft and trash exclusions', () {
      final MessageQuery query = MessageQuery.defaults.copyWith(
        includeDrafts: true,
        includeTrashed: true,
        excludeSnoozed: false,
      );
      expect(query.matches(_msg(id: 'draft', isDraft: true), now: now), isTrue);
      expect(query.matches(_msg(id: 'trash', trashedAt: 1), now: now), isTrue);
      expect(
        query.matches(
          _msg(id: 'snoozed', snoozedUntil: now.millisecondsSinceEpoch + 50),
          now: now,
        ),
        isTrue,
      );
    });

    test('apply sorts newest first and respects limit', () {
      final List<MailMessage> result = MessageQuery.defaults
          .copyWith(limit: 2)
          .apply(<MailMessage>[
            _msg(id: 'a', whenEpochMs: 10),
            _msg(id: 'b', whenEpochMs: 30),
            _msg(id: 'c', whenEpochMs: 20),
          ], now: now);
      expect(result.map((MailMessage m) => m.id), <String>['b', 'c']);
    });

    test('non-positive limit matches Drift no-limit behavior', () {
      final List<MailMessage> messages = <MailMessage>[
        _msg(id: 'a', whenEpochMs: 10),
        _msg(id: 'b', whenEpochMs: 20),
      ];

      expect(
        MessageQuery.defaults.copyWith(limit: 0).apply(messages, now: now),
        hasLength(2),
      );
      expect(
        MessageQuery.defaults.copyWith(limit: -1).apply(messages, now: now),
        hasLength(2),
      );
    });

    test('equality includes new filter fields', () {
      const MessageQuery a = MessageQuery(
        pinnedOnly: true,
        snoozedOnly: true,
        excludeSnoozed: false,
        userFilter: MessageViewFilter(unread: true, keyword: 'x'),
      );
      const MessageQuery b = MessageQuery(
        pinnedOnly: true,
        snoozedOnly: true,
        excludeSnoozed: false,
        userFilter: MessageViewFilter(unread: true, keyword: 'x'),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(
        a,
        isNot(
          equals(
            a.copyWith(userFilter: const MessageViewFilter(unread: false)),
          ),
        ),
      );
    });
  });

  group('DriftMailRepository MessageQuery SQL', () {
    late DriftMailRepository repo;
    late int nowMs;

    setUp(() async {
      final ByteMailDatabase database = ByteMailDatabase(
        NativeDatabase.memory(),
      );
      repo = DriftMailRepository(database);
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
        ),
      ]);
      nowMs = DateTime.now().millisecondsSinceEpoch;
      await repo.upsertMessages(<MailMessage>[
        _msg(id: 'normal', whenEpochMs: nowMs),
        _msg(id: 'starred', starred: true, whenEpochMs: nowMs - 1),
        _msg(id: 'pinned', pinned: true, whenEpochMs: nowMs - 2),
        _msg(
          id: 'unread',
          unread: true,
          fromAddress: 'boss@byte.io',
          fromName: 'Boss',
          subject: 'Quarterly invoice review',
          body: 'Please review the invoice attachment',
          hasAttachments: true,
          toRecipients: 'Me <me@byte.io>, Carol <carol@example.com>',
          ccRecipients: 'Ops <ops@byte.io>',
          whenEpochMs: nowMs - 3,
        ),
        _msg(
          id: 'snoozed',
          snoozedUntil: nowMs + Duration(days: 1).inMilliseconds,
          whenEpochMs: nowMs - 4,
        ),
        _msg(id: 'draft', isDraft: true, whenEpochMs: nowMs - 5),
        _msg(id: 'trash', trashedAt: nowMs, whenEpochMs: nowMs - 6),
      ], folderId: 'inbox-work');
    });

    tearDown(() async {
      await repo.close();
    });

    test('defaults hide snoozed, draft, and trashed rows', () async {
      final List<MailMessage> rows = await repo.listMessages(
        MessageQuery.defaults,
      );
      final Set<String> ids = rows.map((MailMessage m) => m.id).toSet();
      expect(
        ids,
        containsAll(<String>['normal', 'starred', 'pinned', 'unread']),
      );
      expect(ids.contains('snoozed'), isFalse);
      expect(ids.contains('draft'), isFalse);
      expect(ids.contains('trash'), isFalse);
    });

    test('starredOnly returns only starred non-excluded rows', () async {
      final List<MailMessage> rows = await repo.listMessages(
        MessageQuery.defaults.copyWith(starredOnly: true),
      );
      expect(rows.map((MailMessage m) => m.id), <String>['starred']);
    });

    test('pinnedOnly and snoozedOnly SQL filters', () async {
      final List<MailMessage> pinned = await repo.listMessages(
        MessageQuery.defaults.copyWith(pinnedOnly: true),
      );
      expect(pinned.map((MailMessage m) => m.id), <String>['pinned']);

      final List<MailMessage> snoozed = await repo.listMessages(
        const MessageQuery(snoozedOnly: true, excludeSnoozed: false),
      );
      expect(snoozed.map((MailMessage m) => m.id), <String>['snoozed']);
    });

    test('userFilter unread, sender, date, attachments, keyword via FTS',
        () async {
      final List<MailMessage> unread = await repo.listMessages(
        MessageQuery.defaults.copyWith(
          userFilter: const MessageViewFilter(unread: true),
        ),
      );
      expect(unread.map((MailMessage m) => m.id), <String>['unread']);

      final List<MailMessage> sender = await repo.listMessages(
        MessageQuery.defaults.copyWith(
          userFilter: const MessageViewFilter(senderContains: 'boss'),
        ),
      );
      expect(sender.map((MailMessage m) => m.id), <String>['unread']);

      final List<MailMessage> dated = await repo.listMessages(
        MessageQuery.defaults.copyWith(
          userFilter: MessageViewFilter(
            receivedAfterEpochMs: nowMs - 3,
            receivedBeforeEpochMs: nowMs - 3,
          ),
        ),
      );
      expect(dated.map((MailMessage m) => m.id), <String>['unread']);

      final List<MailMessage> attached = await repo.listMessages(
        MessageQuery.defaults.copyWith(
          userFilter: const MessageViewFilter(hasAttachments: true),
        ),
      );
      expect(attached.map((MailMessage m) => m.id), <String>['unread']);

      final List<MailMessage> keyword = await repo.listMessages(
        MessageQuery.defaults.copyWith(
          userFilter: const MessageViewFilter(keyword: 'invoice'),
        ),
      );
      expect(keyword.map((MailMessage m) => m.id), <String>['unread']);

      final List<MailMessage> recipient = await repo.listMessages(
        MessageQuery.defaults.copyWith(
          userFilter: const MessageViewFilter(recipientContains: 'carol'),
        ),
      );
      expect(recipient.map((MailMessage m) => m.id), <String>['unread']);

      final List<MailMessage> ccRecipient = await repo.listMessages(
        MessageQuery.defaults.copyWith(
          userFilter: const MessageViewFilter(recipientContains: 'ops@'),
        ),
      );
      expect(ccRecipient.map((MailMessage m) => m.id), <String>['unread']);
    });

    test('includeDrafts and includeTrashed surface excluded rows', () async {
      final List<MailMessage> rows = await repo.listMessages(
        const MessageQuery(
          includeDrafts: true,
          includeTrashed: true,
          excludeSnoozed: false,
        ),
      );
      final Set<String> ids = rows.map((MailMessage m) => m.id).toSet();
      expect(
        ids,
        containsAll(<String>[
          'normal',
          'starred',
          'pinned',
          'unread',
          'snoozed',
          'draft',
          'trash',
        ]),
      );
    });
  });

  group('upsertMessages merge policy', () {
    late DriftMailRepository repo;

    setUp(() async {
      final ByteMailDatabase database = ByteMailDatabase(
        NativeDatabase.memory(),
      );
      repo = DriftMailRepository(database);
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
        ),
      ]);
    });

    tearDown(() async {
      await repo.close();
    });

    test('preserves existing threadId when incoming threadId is null', () async {
      await repo.upsertMessages(<MailMessage>[
        _msg(id: 't1', threadId: 'work:root@x', unread: true),
      ], folderId: 'inbox-work');

      await repo.upsertMessages(<MailMessage>[
        _msg(id: 't1', threadId: null, unread: true, subject: 'Updated'),
      ], folderId: 'inbox-work');

      final MailMessage? row = await repo.getMessage('t1');
      expect(row?.threadId, 'work:root@x');
      expect(row?.subject, 'Updated');
    });

    test('DEF-007: keeps local read when sync would re-unread', () async {
      await repo.upsertMessages(<MailMessage>[
        _msg(id: 'r1', unread: true),
      ], folderId: 'inbox-work');
      await repo.setUnread('r1', false);

      await repo.upsertMessages(<MailMessage>[
        _msg(id: 'r1', unread: true),
      ], folderId: 'inbox-work');

      final MailMessage? row = await repo.getMessage('r1');
      expect(row?.unread, isFalse);
    });

    test('allows remote mark-read when local is still unread', () async {
      await repo.upsertMessages(<MailMessage>[
        _msg(id: 'r2', unread: true),
      ], folderId: 'inbox-work');

      await repo.upsertMessages(<MailMessage>[
        _msg(id: 'r2', unread: false),
      ], folderId: 'inbox-work');

      final MailMessage? row = await repo.getMessage('r2');
      expect(row?.unread, isFalse);
    });

    test('parses To/Cc from rawHeaders when recipient columns empty', () async {
      await repo.upsertMessages(<MailMessage>[
        _msg(
          id: 'hdr',
          rawHeaders:
              'To: Bob <bob@example.com>\nCc: Carol <carol@example.com>\n',
        ),
      ], folderId: 'inbox-work');

      final MailMessage? row = await repo.getMessage('hdr');
      expect(row?.toRecipients, contains('bob@example.com'));
      expect(row?.ccRecipients, contains('carol@example.com'));
    });
  });
}
