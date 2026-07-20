// ==============================================================================
// File: lib/query/message_query.dart
// Description: Composable local message list query predicates and user filters.
// Component: Query / Domain
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/focus/focus_header_map.dart';

/// User-facing list filters stacked on top of folder/focus scope.
///
/// All fields are optional; `null` / unset means "no constraint".
class MessageViewFilter {
  const MessageViewFilter({
    this.unread,
    this.starred,
    this.senderContains,
    this.recipientContains,
    this.receivedAfterEpochMs,
    this.receivedBeforeEpochMs,
    this.keyword,
    this.hasAttachments,
  });

  /// `null` = any; `true` = unread only; `false` = read only.
  final bool? unread;

  /// `null` = any; `true` = starred only; `false` = unstarred only.
  final bool? starred;

  /// Case-insensitive substring match against from name or address.
  final String? senderContains;

  /// Case-insensitive substring match against to/cc name or address fields.
  final String? recipientContains;

  /// Inclusive lower bound on [MailMessage.whenEpochMs].
  final int? receivedAfterEpochMs;

  /// Inclusive upper bound on [MailMessage.whenEpochMs].
  final int? receivedBeforeEpochMs;

  /// Free-text keyword (FTS in Drift; substring match in-memory).
  final String? keyword;

  /// `null` = any; `true` = has attachments; `false` = no attachments.
  final bool? hasAttachments;

  MessageViewFilter copyWith({
    bool? unread,
    bool? starred,
    String? senderContains,
    String? recipientContains,
    int? receivedAfterEpochMs,
    int? receivedBeforeEpochMs,
    String? keyword,
    bool? hasAttachments,
    bool clearUnread = false,
    bool clearStarred = false,
    bool clearSenderContains = false,
    bool clearRecipientContains = false,
    bool clearReceivedAfterEpochMs = false,
    bool clearReceivedBeforeEpochMs = false,
    bool clearKeyword = false,
    bool clearHasAttachments = false,
  }) {
    return MessageViewFilter(
      unread: clearUnread ? null : (unread ?? this.unread),
      starred: clearStarred ? null : (starred ?? this.starred),
      senderContains: clearSenderContains
          ? null
          : (senderContains ?? this.senderContains),
      recipientContains: clearRecipientContains
          ? null
          : (recipientContains ?? this.recipientContains),
      receivedAfterEpochMs: clearReceivedAfterEpochMs
          ? null
          : (receivedAfterEpochMs ?? this.receivedAfterEpochMs),
      receivedBeforeEpochMs: clearReceivedBeforeEpochMs
          ? null
          : (receivedBeforeEpochMs ?? this.receivedBeforeEpochMs),
      keyword: clearKeyword ? null : (keyword ?? this.keyword),
      hasAttachments: clearHasAttachments
          ? null
          : (hasAttachments ?? this.hasAttachments),
    );
  }

  /// In-memory evaluation of user-filter fields only.
  bool matches(MailMessage message) {
    final bool? unreadFilter = unread;
    if (unreadFilter != null && message.unread != unreadFilter) {
      return false;
    }
    final bool? starredFilter = starred;
    if (starredFilter != null && message.starred != starredFilter) {
      return false;
    }
    final String? sender = senderContains?.trim();
    if (sender != null && sender.isNotEmpty) {
      final String needle = sender.toLowerCase();
      final bool hit =
          message.fromAddress.toLowerCase().contains(needle) ||
          message.fromName.toLowerCase().contains(needle);
      if (!hit) {
        return false;
      }
    }
    final String? recipient = recipientContains?.trim();
    if (recipient != null && recipient.isNotEmpty) {
      if (!_matchesRecipient(message, recipient)) {
        return false;
      }
    }
    final int? after = receivedAfterEpochMs;
    if (after != null) {
      final int epoch = message.whenEpochMs ?? 0;
      if (epoch < after) {
        return false;
      }
    }
    final int? before = receivedBeforeEpochMs;
    if (before != null) {
      final int epoch = message.whenEpochMs ?? 0;
      if (epoch > before) {
        return false;
      }
    }
    final String? kw = keyword?.trim();
    if (kw != null && kw.isNotEmpty) {
      if (!_matchesKeyword(message, kw)) {
        return false;
      }
    }
    final bool? attachments = hasAttachments;
    if (attachments != null && message.hasAttachments != attachments) {
      return false;
    }
    return true;
  }

  static bool _matchesRecipient(MailMessage message, String needle) {
    final String lowerNeedle = needle.toLowerCase();
    String toLine = message.toRecipients;
    String ccLine = message.ccRecipients;
    if (toLine.isEmpty && ccLine.isEmpty) {
      final Map<String, String> headers = focusHeadersFromRaw(message.rawHeaders);
      toLine = headers['to'] ?? '';
      ccLine = headers['cc'] ?? '';
    }
    return toLine.toLowerCase().contains(lowerNeedle) ||
        ccLine.toLowerCase().contains(lowerNeedle);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        if (unread != null) 'unread': unread,
        if (starred != null) 'starred': starred,
        if (senderContains != null) 'senderContains': senderContains,
        if (recipientContains != null) 'recipientContains': recipientContains,
        if (receivedAfterEpochMs != null)
          'receivedAfterEpochMs': receivedAfterEpochMs,
        if (receivedBeforeEpochMs != null)
          'receivedBeforeEpochMs': receivedBeforeEpochMs,
        if (keyword != null) 'keyword': keyword,
        if (hasAttachments != null) 'hasAttachments': hasAttachments,
      };

  static MessageViewFilter fromJson(Map<String, dynamic> json) {
    return MessageViewFilter(
      unread: json['unread'] as bool?,
      starred: json['starred'] as bool?,
      senderContains: json['senderContains'] as String?,
      recipientContains: json['recipientContains'] as String?,
      receivedAfterEpochMs: json['receivedAfterEpochMs'] as int?,
      receivedBeforeEpochMs: json['receivedBeforeEpochMs'] as int?,
      keyword: json['keyword'] as String?,
      hasAttachments: json['hasAttachments'] as bool?,
    );
  }

  static bool _matchesKeyword(MailMessage message, String keyword) {
    final String needle = keyword.toLowerCase();
    return message.subject.toLowerCase().contains(needle) ||
        message.snippet.toLowerCase().contains(needle) ||
        message.body.toLowerCase().contains(needle) ||
        message.fromName.toLowerCase().contains(needle) ||
        message.fromAddress.toLowerCase().contains(needle);
  }

  @override
  bool operator ==(Object other) {
    return other is MessageViewFilter &&
        other.unread == unread &&
        other.starred == starred &&
        other.senderContains == senderContains &&
        other.recipientContains == recipientContains &&
        other.receivedAfterEpochMs == receivedAfterEpochMs &&
        other.receivedBeforeEpochMs == receivedBeforeEpochMs &&
        other.keyword == keyword &&
        other.hasAttachments == hasAttachments;
  }

  @override
  int get hashCode => Object.hash(
        unread,
        starred,
        senderContains,
        recipientContains,
        receivedAfterEpochMs,
        receivedBeforeEpochMs,
        keyword,
        hasAttachments,
      );
}

/// Composable filters for [MailRepository.listMessages].
///
/// Predicate order in [matches] / Drift SQL:
/// 1. folder scope (`accountId`, `folderId`)
/// 2. focus (`focusFilter`)
/// 3. user filter ([MessageViewFilter])
/// 4. view flags (`starredOnly`, `pinnedOnly`, `snoozedOnly` / `excludeSnoozed`)
/// 5. draft / trash inclusion (`includeDrafts`, `includeTrashed`)
class MessageQuery {
  const MessageQuery({
    this.accountId,
    this.folderId,
    this.focusFilter,
    this.userFilter,
    this.starredOnly = false,
    this.pinnedOnly = false,
    this.snoozedOnly = false,
    this.excludeSnoozed = true,
    this.includeDrafts = false,
    this.includeTrashed = false,
    this.limit,
  });

  /// Default inbox-style query matching pre-W0 listMessages behavior for
  /// ordinary (non-snoozed, non-draft, non-trashed) messages.
  static const MessageQuery defaults = MessageQuery();

  final String? accountId;
  final String? folderId;
  final FocusBucket? focusFilter;
  final MessageViewFilter? userFilter;
  final bool starredOnly;
  final bool pinnedOnly;

  /// When true, show only messages with a future [MailMessage.snoozedUntil].
  /// Callers should typically set [excludeSnoozed] to false when enabling this.
  final bool snoozedOnly;

  /// When true, exclude messages with [MailMessage.snoozedUntil] in the future.
  final bool excludeSnoozed;

  /// When false, exclude messages with [MailMessage.isDraft] == true.
  final bool includeDrafts;

  /// When false, exclude messages with [MailMessage.trashedAt] != null.
  final bool includeTrashed;

  final int? limit;

  MessageQuery copyWith({
    String? accountId,
    String? folderId,
    FocusBucket? focusFilter,
    MessageViewFilter? userFilter,
    bool? starredOnly,
    bool? pinnedOnly,
    bool? snoozedOnly,
    bool? excludeSnoozed,
    bool? includeDrafts,
    bool? includeTrashed,
    int? limit,
    bool clearAccountId = false,
    bool clearFolderId = false,
    bool clearFocusFilter = false,
    bool clearUserFilter = false,
    bool clearLimit = false,
  }) {
    return MessageQuery(
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
      focusFilter: clearFocusFilter ? null : (focusFilter ?? this.focusFilter),
      userFilter: clearUserFilter ? null : (userFilter ?? this.userFilter),
      starredOnly: starredOnly ?? this.starredOnly,
      pinnedOnly: pinnedOnly ?? this.pinnedOnly,
      snoozedOnly: snoozedOnly ?? this.snoozedOnly,
      excludeSnoozed: excludeSnoozed ?? this.excludeSnoozed,
      includeDrafts: includeDrafts ?? this.includeDrafts,
      includeTrashed: includeTrashed ?? this.includeTrashed,
      limit: clearLimit ? null : (limit ?? this.limit),
    );
  }

  /// In-memory predicate used by unit tests and optional client-side filters.
  ///
  /// Evaluation order: folder scope → focus → user filter →
  /// starred/pinned/snoozed flags → draft/trash inclusion.
  bool matches(MailMessage message, {DateTime? now}) {
    if (accountId != null && message.accountId != accountId) {
      return false;
    }
    if (folderId != null && message.folderId != folderId) {
      return false;
    }
    if (focusFilter != null && message.bucket != focusFilter) {
      return false;
    }
    final MessageViewFilter? filter = userFilter;
    if (filter != null && !filter.matches(message)) {
      return false;
    }
    if (starredOnly && !message.starred) {
      return false;
    }
    if (pinnedOnly && !message.pinned) {
      return false;
    }
    final int epoch = (now ?? DateTime.now()).millisecondsSinceEpoch;
    if (snoozedOnly) {
      final int? snoozedUntil = message.snoozedUntil;
      if (snoozedUntil == null || snoozedUntil <= epoch) {
        return false;
      }
    } else if (excludeSnoozed) {
      final int? snoozedUntil = message.snoozedUntil;
      if (snoozedUntil != null && snoozedUntil > epoch) {
        return false;
      }
    }
    if (!includeDrafts && message.isDraft) {
      return false;
    }
    if (!includeTrashed && message.trashedAt != null) {
      return false;
    }
    return true;
  }

  /// Applies [matches] then sorts newest-first and optionally applies [limit].
  List<MailMessage> apply(
    Iterable<MailMessage> messages, {
    DateTime? now,
  }) {
    final List<MailMessage> filtered = messages
        .where((MailMessage message) => matches(message, now: now))
        .toList(growable: true);
    filtered.sort((MailMessage a, MailMessage b) {
      final int aEpoch = a.whenEpochMs ?? 0;
      final int bEpoch = b.whenEpochMs ?? 0;
      return bEpoch.compareTo(aEpoch);
    });
    final int? max = limit;
    if (max == null || max <= 0 || max >= filtered.length) {
      return List<MailMessage>.unmodifiable(filtered);
    }
    return List<MailMessage>.unmodifiable(filtered.take(max));
  }

  @override
  bool operator ==(Object other) {
    return other is MessageQuery &&
        other.accountId == accountId &&
        other.folderId == folderId &&
        other.focusFilter == focusFilter &&
        other.userFilter == userFilter &&
        other.starredOnly == starredOnly &&
        other.pinnedOnly == pinnedOnly &&
        other.snoozedOnly == snoozedOnly &&
        other.excludeSnoozed == excludeSnoozed &&
        other.includeDrafts == includeDrafts &&
        other.includeTrashed == includeTrashed &&
        other.limit == limit;
  }

  @override
  int get hashCode => Object.hash(
        accountId,
        folderId,
        focusFilter,
        userFilter,
        starredOnly,
        pinnedOnly,
        snoozedOnly,
        excludeSnoozed,
        includeDrafts,
        includeTrashed,
        limit,
      );
}
