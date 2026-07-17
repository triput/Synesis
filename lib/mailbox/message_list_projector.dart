// ==============================================================================
// File: lib/mailbox/message_list_projector.dart
// Description: Pure projector for threaded / flat message list sections
// Component: Mailbox / Domain
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/settings/app_settings_state.dart';

/// How (or whether) list rows are bucketed by calendar date.
enum DateGroupingMode {
  /// Single untitled section; rows ordered newest-first.
  none,

  /// Outlook-style buckets: Today, Yesterday, This week, …
  outlookBuckets,
}

/// One dated (or untitled) block of projected list rows.
class MessageListSection {
  const MessageListSection({
    required this.title,
    required this.items,
  });

  /// Section header label (`Today`, `Yesterday`, …). Empty when grouping is off.
  final String title;
  final List<MessageListItem> items;
}

/// A single row in a projected message list.
sealed class MessageListItem {
  const MessageListItem();
}

/// One message rendered as its own row (flat mode, or an expanded thread child).
final class FlatMessageItem extends MessageListItem {
  const FlatMessageItem(this.message);

  final MailMessage message;
}

/// Conversation summary row. [members] are newest-first and always include
/// [latest]. When the thread is expanded, the projector emits [FlatMessageItem]
/// rows for **all** [members] (including [latest]) immediately after this row.
final class ThreadItem extends MessageListItem {
  const ThreadItem({
    required this.threadId,
    required this.latest,
    required this.members,
    required this.count,
    required this.anyUnread,
    required this.anyStarred,
    required this.anyPinned,
    required this.participantSummary,
  });

  /// Effective thread key within [latest.accountId]: `threadId ?? message.id`.
  final String threadId;

  /// Newest message in the thread (drives sort + date bucketing).
  final MailMessage latest;

  /// All thread members, newest-first (includes [latest]).
  final List<MailMessage> members;

  final int count;
  final bool anyUnread;
  final bool anyStarred;
  final bool anyPinned;

  /// Distinct participant display names (or addresses), comma-separated.
  final String participantSummary;

  /// Key stored in [MailboxState.expandedThreadIds] — account-scoped.
  String get expansionKey => expansionKeyFor(latest.accountId, threadId);

  static String expansionKeyFor(String accountId, String threadId) =>
      '$accountId::$threadId';
}

/// Pure function that turns a flat [MailMessage] list into dated sections with
/// optional conversation grouping. No Flutter / Material imports.
class MessageListProjector {
  const MessageListProjector._();

  /// Projects [messages] into dated sections.
  ///
  /// Threading rules:
  /// - Group key is `(accountId, threadId ?? message.id)` — never merges
  ///   across accounts even when remote thread ids collide.
  /// - Thread rows sort by [ThreadItem.latest.whenEpochMs] descending.
  /// - [ThreadItem.members] are newest-first.
  /// - When [expandedThreadIds] contains [ThreadItem.expansionKey], all
  ///   members are emitted as [FlatMessageItem]s under the thread header.
  ///
  /// Flat mode emits one [FlatMessageItem] per message; date grouping still
  /// applies when [dateGrouping] is [DateGroupingMode.outlookBuckets].
  static List<MessageListSection> project({
    required List<MailMessage> messages,
    required ThreadDisplayMode threadMode,
    required DateGroupingMode dateGrouping,
    required Set<String> expandedThreadIds,
    DateTime? now,
  }) {
    final DateTime clock = now ?? DateTime.now();
    final List<_ProjectedRow> rows = threadMode == ThreadDisplayMode.threaded
        ? _projectThreaded(messages, expandedThreadIds)
        : _projectFlat(messages);

    if (dateGrouping == DateGroupingMode.none) {
      return <MessageListSection>[
        MessageListSection(title: '', items: _itemsOf(rows)),
      ];
    }

    final Map<String, List<_ProjectedRow>> buckets =
        <String, List<_ProjectedRow>>{};
    for (final _ProjectedRow row in rows) {
      final String label = _outlookBucketLabel(row.sortEpochMs, clock);
      buckets.putIfAbsent(label, () => <_ProjectedRow>[]).add(row);
    }

    final List<MessageListSection> sections = <MessageListSection>[];
    for (final String label in _outlookBucketOrder) {
      final List<_ProjectedRow>? bucket = buckets[label];
      if (bucket == null || bucket.isEmpty) {
        continue;
      }
      sections.add(
        MessageListSection(title: label, items: _itemsOf(bucket)),
      );
    }
    return sections;
  }

  /// Flattened, deduped message ids in projected row order for reading-pane
  /// prev/next navigation (thread latests + flat rows).
  static List<String> navigationMessageIds(List<MessageListSection> sections) {
    final List<String> ids = <String>[];
    final Set<String> seen = <String>{};
    for (final MessageListSection section in sections) {
      for (final MessageListItem item in section.items) {
        final String id = switch (item) {
          ThreadItem(:final MailMessage latest) => latest.id,
          FlatMessageItem(:final MailMessage message) => message.id,
        };
        if (seen.add(id)) {
          ids.add(id);
        }
      }
    }
    return ids;
  }

  static List<_ProjectedRow> _projectFlat(List<MailMessage> messages) {
    final List<MailMessage> sorted = List<MailMessage>.from(messages)
      ..sort(_compareNewestFirst);
    return <_ProjectedRow>[
      for (final MailMessage message in sorted)
        _ProjectedRow(
          sortEpochMs: message.whenEpochMs ?? 0,
          items: <MessageListItem>[FlatMessageItem(message)],
        ),
    ];
  }

  static List<_ProjectedRow> _projectThreaded(
    List<MailMessage> messages,
    Set<String> expandedThreadIds,
  ) {
    final Map<String, List<MailMessage>> groups =
        <String, List<MailMessage>>{};
    for (final MailMessage message in messages) {
      final String effectiveThreadId = message.threadId ?? message.id;
      final String groupKey =
          ThreadItem.expansionKeyFor(message.accountId, effectiveThreadId);
      groups.putIfAbsent(groupKey, () => <MailMessage>[]).add(message);
    }

    final List<_ProjectedRow> rows = <_ProjectedRow>[];
    for (final MapEntry<String, List<MailMessage>> entry in groups.entries) {
      final List<MailMessage> members = List<MailMessage>.from(entry.value)
        ..sort(_compareNewestFirst);
      final MailMessage latest = members.first;
      final String effectiveThreadId = latest.threadId ?? latest.id;
      final ThreadItem thread = ThreadItem(
        threadId: effectiveThreadId,
        latest: latest,
        members: List<MailMessage>.unmodifiable(members),
        count: members.length,
        anyUnread: members.any((MailMessage m) => m.unread),
        anyStarred: members.any((MailMessage m) => m.starred),
        anyPinned: members.any((MailMessage m) => m.pinned),
        participantSummary: _participantSummary(members),
      );
      final List<MessageListItem> items = <MessageListItem>[thread];
      if (expandedThreadIds.contains(thread.expansionKey)) {
        for (final MailMessage member in members) {
          items.add(FlatMessageItem(member));
        }
      }
      rows.add(
        _ProjectedRow(
          sortEpochMs: latest.whenEpochMs ?? 0,
          items: items,
        ),
      );
    }
    rows.sort(
      (_ProjectedRow a, _ProjectedRow b) =>
          b.sortEpochMs.compareTo(a.sortEpochMs),
    );
    return rows;
  }

  static List<MessageListItem> _itemsOf(List<_ProjectedRow> rows) {
    return <MessageListItem>[
      for (final _ProjectedRow row in rows) ...row.items,
    ];
  }

  static int _compareNewestFirst(MailMessage a, MailMessage b) {
    final int aEpoch = a.whenEpochMs ?? 0;
    final int bEpoch = b.whenEpochMs ?? 0;
    final int byEpoch = bEpoch.compareTo(aEpoch);
    if (byEpoch != 0) {
      return byEpoch;
    }
    return b.id.compareTo(a.id);
  }

  static String _participantSummary(List<MailMessage> members) {
    final Set<String> seen = <String>{};
    final List<String> labels = <String>[];
    for (final MailMessage message in members) {
      final String label = message.fromName.trim().isNotEmpty
          ? message.fromName.trim()
          : message.fromAddress.trim();
      if (label.isEmpty) {
        continue;
      }
      final String key = label.toLowerCase();
      if (seen.add(key)) {
        labels.add(label);
      }
    }
    return labels.join(', ');
  }

  static const List<String> _outlookBucketOrder = <String>[
    'Today',
    'Yesterday',
    'This week',
    'Last week',
    'This month',
    'Last month',
    'Older',
  ];

  /// Maps an epoch-ms timestamp to an Outlook-style section title.
  ///
  /// Week boundaries use Monday as the first day of the week (ISO-8601).
  static String _outlookBucketLabel(int epochMs, DateTime now) {
    if (epochMs <= 0) {
      return 'Older';
    }
    final DateTime local = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime messageDay = DateTime(local.year, local.month, local.day);

    if (messageDay == today) {
      return 'Today';
    }
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    if (messageDay == yesterday) {
      return 'Yesterday';
    }

    final DateTime thisWeekStart = _mondayOf(today);
    final DateTime nextWeekStart = thisWeekStart.add(const Duration(days: 7));
    if (!messageDay.isBefore(thisWeekStart) &&
        messageDay.isBefore(nextWeekStart)) {
      return 'This week';
    }

    final DateTime lastWeekStart =
        thisWeekStart.subtract(const Duration(days: 7));
    if (!messageDay.isBefore(lastWeekStart) &&
        messageDay.isBefore(thisWeekStart)) {
      return 'Last week';
    }

    if (messageDay.year == today.year && messageDay.month == today.month) {
      return 'This month';
    }

    final DateTime lastMonthAnchor = DateTime(today.year, today.month - 1, 1);
    if (messageDay.year == lastMonthAnchor.year &&
        messageDay.month == lastMonthAnchor.month) {
      return 'Last month';
    }

    return 'Older';
  }

  static DateTime _mondayOf(DateTime day) {
    final DateTime dateOnly = DateTime(day.year, day.month, day.day);
    return dateOnly.subtract(Duration(days: dateOnly.weekday - DateTime.monday));
  }
}

class _ProjectedRow {
  const _ProjectedRow({
    required this.sortEpochMs,
    required this.items,
  });

  final int sortEpochMs;
  final List<MessageListItem> items;
}
