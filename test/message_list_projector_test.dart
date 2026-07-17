// ==============================================================================
// File: test/message_list_projector_test.dart
// Description: Unit tests for MessageListProjector threading and date sections
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/mailbox/message_list_projector.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

MailMessage _msg({
  required String id,
  required String accountId,
  String? threadId,
  int? whenEpochMs,
  String fromName = 'Alice',
  String fromAddress = 'alice@byte.io',
  bool unread = false,
  bool starred = false,
  bool pinned = false,
}) {
  return MailMessage(
    id: id,
    accountId: accountId,
    fromName: fromName,
    fromAddress: fromAddress,
    subject: id,
    snippet: 's',
    body: 'b',
    whenLabel: '10:00',
    bucket: FocusBucket.focused,
    folderId: '$accountId-inbox',
    threadId: threadId,
    whenEpochMs: whenEpochMs,
    unread: unread,
    starred: starred,
    pinned: pinned,
  );
}

void main() {
  // Friday 2026-07-17 local noon — mid-week for Outlook bucket tests.
  final DateTime now = DateTime(2026, 7, 17, 12, 0);

  int epoch(DateTime dt) => dt.millisecondsSinceEpoch;

  group('MessageListProjector flat vs threaded', () {
    test('flat mode emits one FlatMessageItem per message', () {
      final List<MailMessage> messages = <MailMessage>[
        _msg(id: 'a', accountId: 'work', whenEpochMs: 3000),
        _msg(id: 'b', accountId: 'work', whenEpochMs: 2000),
        _msg(id: 'c', accountId: 'work', whenEpochMs: 1000),
      ];

      final List<MessageListSection> sections = MessageListProjector.project(
        messages: messages,
        threadMode: ThreadDisplayMode.flat,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: const <String>{},
        now: now,
      );

      expect(sections, hasLength(1));
      expect(sections.single.title, isEmpty);
      expect(sections.single.items, hasLength(3));
      expect(sections.single.items, everyElement(isA<FlatMessageItem>()));
      expect(
        (sections.single.items[0] as FlatMessageItem).message.id,
        'a',
      );
    });

    test('threaded mode groups reply chain by threadId', () {
      final List<MailMessage> messages = <MailMessage>[
        _msg(
          id: 'root',
          accountId: 'work',
          threadId: 't1',
          whenEpochMs: 1000,
          fromName: 'Alice',
        ),
        _msg(
          id: 'reply',
          accountId: 'work',
          threadId: 't1',
          whenEpochMs: 2000,
          fromName: 'Bob',
          fromAddress: 'bob@byte.io',
          unread: true,
        ),
        _msg(
          id: 'solo',
          accountId: 'work',
          whenEpochMs: 1500,
          fromName: 'Carol',
          fromAddress: 'carol@byte.io',
        ),
      ];

      final List<MessageListSection> sections = MessageListProjector.project(
        messages: messages,
        threadMode: ThreadDisplayMode.threaded,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: const <String>{},
        now: now,
      );

      expect(sections.single.items, hasLength(2));
      final ThreadItem first = sections.single.items[0] as ThreadItem;
      final ThreadItem second = sections.single.items[1] as ThreadItem;

      // Newest thread first (reply at 2000 beats solo at 1500).
      expect(first.threadId, 't1');
      expect(first.latest.id, 'reply');
      expect(first.count, 2);
      expect(first.anyUnread, isTrue);
      expect(first.members.map((MailMessage m) => m.id).toList(),
          <String>['reply', 'root']);
      expect(first.participantSummary, 'Bob, Alice');

      expect(second.threadId, 'solo');
      expect(second.count, 1);
    });

    test('does not merge identical threadIds across accounts', () {
      final List<MailMessage> messages = <MailMessage>[
        _msg(
          id: 'w1',
          accountId: 'work',
          threadId: 'shared',
          whenEpochMs: 2000,
        ),
        _msg(
          id: 'p1',
          accountId: 'personal',
          threadId: 'shared',
          whenEpochMs: 1000,
        ),
      ];

      final List<MessageListSection> sections = MessageListProjector.project(
        messages: messages,
        threadMode: ThreadDisplayMode.threaded,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: const <String>{},
        now: now,
      );

      expect(sections.single.items, hasLength(2));
      final List<ThreadItem> threads = sections.single.items
          .whereType<ThreadItem>()
          .toList(growable: false);
      expect(threads.map((ThreadItem t) => t.latest.accountId).toSet(),
          <String>{'work', 'personal'});
      expect(threads.every((ThreadItem t) => t.threadId == 'shared'), isTrue);
      expect(
        threads.map((ThreadItem t) => t.expansionKey).toSet(),
        <String>{'work::shared', 'personal::shared'},
      );
    });
  });

  group('MessageListProjector expansion', () {
    test('expanded thread emits FlatMessageItems for all members', () {
      final List<MailMessage> messages = <MailMessage>[
        _msg(
          id: 'root',
          accountId: 'work',
          threadId: 't1',
          whenEpochMs: 1000,
        ),
        _msg(
          id: 'reply',
          accountId: 'work',
          threadId: 't1',
          whenEpochMs: 2000,
        ),
      ];
      final String key = ThreadItem.expansionKeyFor('work', 't1');

      final List<MessageListSection> sections = MessageListProjector.project(
        messages: messages,
        threadMode: ThreadDisplayMode.threaded,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: <String>{key},
        now: now,
      );

      expect(sections.single.items, hasLength(3));
      expect(sections.single.items[0], isA<ThreadItem>());
      expect(
        (sections.single.items[1] as FlatMessageItem).message.id,
        'reply',
      );
      expect(
        (sections.single.items[2] as FlatMessageItem).message.id,
        'root',
      );
    });
  });

  group('MessageListProjector date sections', () {
    test('outlookBuckets places messages into Today…Older', () {
      final List<MailMessage> messages = <MailMessage>[
        _msg(
          id: 'today',
          accountId: 'work',
          whenEpochMs: epoch(DateTime(2026, 7, 17, 9)),
        ),
        _msg(
          id: 'yesterday',
          accountId: 'work',
          whenEpochMs: epoch(DateTime(2026, 7, 16, 18)),
        ),
        // Wednesday this week (Mon=13 … Fri=17)
        _msg(
          id: 'this-week',
          accountId: 'work',
          whenEpochMs: epoch(DateTime(2026, 7, 15, 10)),
        ),
        // Previous week Monday
        _msg(
          id: 'last-week',
          accountId: 'work',
          whenEpochMs: epoch(DateTime(2026, 7, 6, 10)),
        ),
        // Earlier in July (before last week)
        _msg(
          id: 'this-month',
          accountId: 'work',
          whenEpochMs: epoch(DateTime(2026, 7, 1, 10)),
        ),
        _msg(
          id: 'last-month',
          accountId: 'work',
          whenEpochMs: epoch(DateTime(2026, 6, 20, 10)),
        ),
        _msg(
          id: 'older',
          accountId: 'work',
          whenEpochMs: epoch(DateTime(2026, 3, 1, 10)),
        ),
      ];

      final List<MessageListSection> sections = MessageListProjector.project(
        messages: messages,
        threadMode: ThreadDisplayMode.flat,
        dateGrouping: DateGroupingMode.outlookBuckets,
        expandedThreadIds: const <String>{},
        now: now,
      );

      expect(
        sections.map((MessageListSection s) => s.title).toList(),
        <String>[
          'Today',
          'Yesterday',
          'This week',
          'Last week',
          'This month',
          'Last month',
          'Older',
        ],
      );
      expect(
        (sections[0].items.single as FlatMessageItem).message.id,
        'today',
      );
      expect(
        (sections[1].items.single as FlatMessageItem).message.id,
        'yesterday',
      );
      expect(
        (sections[2].items.single as FlatMessageItem).message.id,
        'this-week',
      );
      expect(
        (sections[3].items.single as FlatMessageItem).message.id,
        'last-week',
      );
      expect(
        (sections[4].items.single as FlatMessageItem).message.id,
        'this-month',
      );
      expect(
        (sections[5].items.single as FlatMessageItem).message.id,
        'last-month',
      );
      expect(
        (sections[6].items.single as FlatMessageItem).message.id,
        'older',
      );
    });

    test('threaded mode date-groups by latest member', () {
      final List<MailMessage> messages = <MailMessage>[
        _msg(
          id: 'old',
          accountId: 'work',
          threadId: 't1',
          whenEpochMs: epoch(DateTime(2026, 3, 1)),
        ),
        _msg(
          id: 'new',
          accountId: 'work',
          threadId: 't1',
          whenEpochMs: epoch(DateTime(2026, 7, 17, 8)),
        ),
      ];

      final List<MessageListSection> sections = MessageListProjector.project(
        messages: messages,
        threadMode: ThreadDisplayMode.threaded,
        dateGrouping: DateGroupingMode.outlookBuckets,
        expandedThreadIds: const <String>{},
        now: now,
      );

      expect(sections, hasLength(1));
      expect(sections.single.title, 'Today');
      expect(sections.single.items.single, isA<ThreadItem>());
    });
  });

  group('navigationMessageIds', () {
    test('dedupes expanded thread latest and flats', () {
      final List<MailMessage> messages = <MailMessage>[
        _msg(
          id: 'a',
          accountId: 'work',
          threadId: 't1',
          whenEpochMs: epoch(DateTime(2026, 7, 17, 10)),
        ),
        _msg(
          id: 'b',
          accountId: 'work',
          threadId: 't1',
          whenEpochMs: epoch(DateTime(2026, 7, 17, 9)),
        ),
        _msg(
          id: 'c',
          accountId: 'work',
          whenEpochMs: epoch(DateTime(2026, 7, 17, 8)),
        ),
      ];
      final String expansionKey = ThreadItem.expansionKeyFor('work', 't1');
      final List<MessageListSection> sections = MessageListProjector.project(
        messages: messages,
        threadMode: ThreadDisplayMode.threaded,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: <String>{expansionKey},
        now: now,
      );
      final List<String> ids =
          MessageListProjector.navigationMessageIds(sections);
      expect(ids, <String>['a', 'b', 'c']);
    });
  });
}
