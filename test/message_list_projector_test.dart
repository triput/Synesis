// ==============================================================================
// File: test/message_list_projector_test.dart
// Description: Unit tests for MessageListProjector threading and date sections
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-08-25
// ==============================================================================

import 'package:synesis/domain/models.dart';
import 'package:synesis/mailbox/message_list_projector.dart';
import 'package:synesis/mailbox/thread_sent_enrichment.dart';
import 'package:synesis/settings/app_settings_state.dart';
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
  String folderId = 'work-inbox',
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
    folderId: folderId,
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

  group('MessageListProjector sort direction', () {
    test('flat oldestFirst reverses row order', () {
      final List<MailMessage> messages = <MailMessage>[
        _msg(id: 'a', accountId: 'work', whenEpochMs: 3000),
        _msg(id: 'b', accountId: 'work', whenEpochMs: 2000),
        _msg(id: 'c', accountId: 'work', whenEpochMs: 1000),
      ];

      final List<MessageListSection> sections = MessageListProjector.project(
        messages: messages,
        threadMode: ThreadDisplayMode.flat,
        sortDirection: MessageListSortDirection.oldestFirst,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: const <String>{},
        now: now,
      );

      expect(
        sections.single.items.map((MessageListItem item) {
          return (item as FlatMessageItem).message.id;
        }).toList(),
        <String>['c', 'b', 'a'],
      );
    });

    test('expanded thread oldestFirst lists members oldest to newest', () {
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
        sortDirection: MessageListSortDirection.oldestFirst,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: <String>{key},
        now: now,
      );

      expect(
        (sections.single.items[1] as FlatMessageItem).message.id,
        'root',
      );
      expect(
        (sections.single.items[2] as FlatMessageItem).message.id,
        'reply',
      );
      final ThreadItem header = sections.single.items[0] as ThreadItem;
      expect(header.latest.id, 'reply');
    });

    test('outlookBuckets oldestFirst reverses section order', () {
      final List<MailMessage> messages = <MailMessage>[
        _msg(
          id: 'today',
          accountId: 'work',
          whenEpochMs: epoch(DateTime(2026, 7, 17, 9)),
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
        sortDirection: MessageListSortDirection.oldestFirst,
        dateGrouping: DateGroupingMode.outlookBuckets,
        expandedThreadIds: const <String>{},
        now: now,
      );

      expect(
        sections.map((MessageListSection s) => s.title).toList(),
        <String>['Older', 'Today'],
      );
    });
  });

  group('MessageListProjector DEF-055 sent in threads', () {
    test('merged sent reply increases thread count and expansion', () {
      final List<MailMessage> inboxOnly = <MailMessage>[
        _msg(
          id: 'inbox-root',
          accountId: 'work',
          threadId: 't1',
          whenEpochMs: 1000,
          fromName: 'Alice',
        ),
      ];
      final MailMessage sentReply = _msg(
        id: 'sent-reply',
        accountId: 'work',
        threadId: 't1',
        whenEpochMs: 2000,
        fromName: 'Me',
        fromAddress: 'me@byte.io',
        folderId: 'work-sent',
      );
      final List<MailMessage> enriched =
          ThreadSentEnrichment.mergeSentThreadMembers(
        primary: inboxOnly,
        sentMembers: <MailMessage>[sentReply],
      );

      final List<MessageListSection> sections = MessageListProjector.project(
        messages: enriched,
        threadMode: ThreadDisplayMode.threaded,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: const <String>{},
        now: now,
      );

      final ThreadItem thread = sections.single.items.single as ThreadItem;
      expect(thread.count, 2);
      expect(thread.latest.id, 'sent-reply');
      expect(
        thread.members.map((MailMessage m) => m.id).toList(),
        <String>['sent-reply', 'inbox-root'],
      );

      final String key = ThreadItem.expansionKeyFor('work', 't1');
      final List<MessageListSection> expanded = MessageListProjector.project(
        messages: enriched,
        threadMode: ThreadDisplayMode.threaded,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: <String>{key},
        now: now,
      );
      expect(expanded.single.items, hasLength(3));
      expect(
        (expanded.single.items[1] as FlatMessageItem).message.id,
        'sent-reply',
      );
      expect(
        (expanded.single.items[2] as FlatMessageItem).message.id,
        'inbox-root',
      );
    });

    test('solo sent without inbox anchor is not merged into folder view', () {
      final List<MailMessage> inboxView = <MailMessage>[
        _msg(
          id: 'other',
          accountId: 'work',
          threadId: 'other-thread',
          whenEpochMs: 500,
        ),
      ];
      final Map<String, Set<String>> threadKeys =
          ThreadSentEnrichment.collectThreadKeysByAccount(inboxView);
      final Set<String> existingIds =
          inboxView.map((MailMessage m) => m.id).toSet();
      final List<MailMessage> sentMembers =
          ThreadSentEnrichment.filterSentThreadMembers(
        sentCandidates: <MailMessage>[
          _msg(
            id: 'sent-only',
            accountId: 'work',
            threadId: 'sent-only-thread',
            whenEpochMs: 900,
            folderId: 'work-sent',
          ),
        ],
        threadIds: threadKeys['work'] ?? const <String>{},
        existingMessageIds: existingIds,
      );
      final List<MailMessage> enriched =
          ThreadSentEnrichment.mergeSentThreadMembers(
        primary: inboxView,
        sentMembers: sentMembers,
      );

      final List<MessageListSection> sections = MessageListProjector.project(
        messages: enriched,
        threadMode: ThreadDisplayMode.threaded,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: const <String>{},
        now: now,
      );

      expect(sections.single.items, hasLength(1));
      final ThreadItem thread = sections.single.items.single as ThreadItem;
      expect(thread.threadId, 'other-thread');
      expect(thread.count, 1);
    });

    test('does not merge identical threadIds across accounts after enrichment', () {
      final List<MailMessage> primary = <MailMessage>[
        _msg(
          id: 'w-in',
          accountId: 'work',
          threadId: 'shared',
          whenEpochMs: 2000,
        ),
        _msg(
          id: 'p-in',
          accountId: 'personal',
          threadId: 'shared',
          whenEpochMs: 1500,
        ),
      ];
      final List<MailMessage> enriched =
          ThreadSentEnrichment.mergeSentThreadMembers(
        primary: primary,
        sentMembers: <MailMessage>[
          _msg(
            id: 'w-out',
            accountId: 'work',
            threadId: 'shared',
            whenEpochMs: 2500,
            folderId: 'work-sent',
          ),
          _msg(
            id: 'p-out',
            accountId: 'personal',
            threadId: 'shared',
            whenEpochMs: 1800,
            folderId: 'personal-sent',
          ),
        ],
      );

      final List<MessageListSection> sections = MessageListProjector.project(
        messages: enriched,
        threadMode: ThreadDisplayMode.threaded,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: const <String>{},
        now: now,
      );

      expect(sections.single.items, hasLength(2));
      final List<ThreadItem> threads = sections.single.items
          .whereType<ThreadItem>()
          .toList(growable: false);
      expect(threads.every((ThreadItem t) => t.count == 2), isTrue);
      expect(
        threads.map((ThreadItem t) => t.expansionKey).toSet(),
        <String>{'work::shared', 'personal::shared'},
      );
    });

    test('oldestFirst expanded thread includes sent reply in chronological order', () {
      final List<MailMessage> enriched =
          ThreadSentEnrichment.mergeSentThreadMembers(
        primary: <MailMessage>[
          _msg(
            id: 'inbox-root',
            accountId: 'work',
            threadId: 't1',
            whenEpochMs: 1000,
          ),
        ],
        sentMembers: <MailMessage>[
          _msg(
            id: 'sent-reply',
            accountId: 'work',
            threadId: 't1',
            whenEpochMs: 2000,
            folderId: 'work-sent',
          ),
        ],
      );
      final String key = ThreadItem.expansionKeyFor('work', 't1');

      final List<MessageListSection> sections = MessageListProjector.project(
        messages: enriched,
        threadMode: ThreadDisplayMode.threaded,
        sortDirection: MessageListSortDirection.oldestFirst,
        dateGrouping: DateGroupingMode.none,
        expandedThreadIds: <String>{key},
        now: now,
      );

      expect(
        (sections.single.items[1] as FlatMessageItem).message.id,
        'inbox-root',
      );
      expect(
        (sections.single.items[2] as FlatMessageItem).message.id,
        'sent-reply',
      );
    });
  });
}
