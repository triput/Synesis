// ==============================================================================
// File: lib/domain/models.dart
// Description: Domain models used by the mailbox and persistence layers.
// Component: Domain
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/material.dart';

class MailAccount {
  const MailAccount({
    required this.id,
    required this.label,
    required this.address,
    required this.accent,
    this.providerType = 'imap',
    this.storageType = 'synced',
    this.focusEnabled = true,
    this.credentialsRef,
    this.syncProfileId,
    this.retentionDaysOverride,
  });

  final String id;
  final String label;
  final String address;
  final Color accent;
  final String providerType;
  final String storageType;
  final bool focusEnabled;
  final String? credentialsRef;
  final String? syncProfileId;
  final int? retentionDaysOverride;
}

enum FocusBucket { focused, other }

enum FocusRuleMatchType { sender, domain }

class FocusRule {
  const FocusRule({
    required this.id,
    required this.pattern,
    required this.matchType,
    required this.bucket,
    this.accountId,
  });

  final String id;
  final String? accountId;
  final String pattern;
  final FocusRuleMatchType matchType;
  final FocusBucket bucket;
}

class MailFolder {
  const MailFolder({
    required this.id,
    required this.accountId,
    required this.name,
    required this.remoteId,
    this.role,
    this.parentRemoteId,
    this.unreadCount,
    this.totalCount,
  });

  final String id;
  final String accountId;
  final String name;
  final String remoteId;
  final String? role;
  final String? parentRemoteId;
  final int? unreadCount;
  final int? totalCount;

  bool get isInbox => role == 'inbox';

  /// Stable local id for the account inbox (compatible with existing sync).
  static String inboxId(String accountId) => 'inbox-$accountId';

  static String localId({
    required String accountId,
    required String remoteId,
    String? role,
  }) {
    if (role == 'inbox') {
      return inboxId(accountId);
    }
    return '$accountId::${Uri.encodeComponent(remoteId)}';
  }
}

class MailMessage {
  const MailMessage({
    required this.id,
    required this.accountId,
    required this.fromName,
    required this.fromAddress,
    required this.subject,
    required this.snippet,
    required this.body,
    required this.whenLabel,
    required this.bucket,
    this.unread = false,
    this.pinned = false,
    this.folderId,
    this.providerId,
    this.messageIdHeader,
    this.hasAttachments = false,
    this.whenEpochMs,
    this.rawHeaders,
    this.starred = false,
    this.threadId,
    this.snoozedUntil,
    this.trashedAt,
    this.isDraft = false,
    this.draftSyncProviderId,
  });

  final String id;
  final String accountId;
  final String fromName;
  final String fromAddress;
  final String subject;
  final String snippet;
  final String body;
  final String whenLabel;
  final FocusBucket bucket;
  final bool unread;
  final bool pinned;
  final String? folderId;
  final String? providerId;
  final String? messageIdHeader;
  final bool hasAttachments;
  final int? whenEpochMs;
  final String? rawHeaders;
  final bool starred;
  final String? threadId;
  final int? snoozedUntil;
  final int? trashedAt;
  final bool isDraft;
  final String? draftSyncProviderId;

  MailMessage copyWith({
    String? id,
    String? accountId,
    String? fromName,
    String? fromAddress,
    String? subject,
    String? snippet,
    String? body,
    String? whenLabel,
    FocusBucket? bucket,
    bool? unread,
    bool? pinned,
    String? folderId,
    String? providerId,
    String? messageIdHeader,
    bool? hasAttachments,
    int? whenEpochMs,
    String? rawHeaders,
    bool? starred,
    String? threadId,
    int? snoozedUntil,
    bool clearSnoozedUntil = false,
    int? trashedAt,
    bool clearTrashedAt = false,
    bool? isDraft,
    String? draftSyncProviderId,
  }) {
    return MailMessage(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      fromName: fromName ?? this.fromName,
      fromAddress: fromAddress ?? this.fromAddress,
      subject: subject ?? this.subject,
      snippet: snippet ?? this.snippet,
      body: body ?? this.body,
      whenLabel: whenLabel ?? this.whenLabel,
      bucket: bucket ?? this.bucket,
      unread: unread ?? this.unread,
      pinned: pinned ?? this.pinned,
      folderId: folderId ?? this.folderId,
      providerId: providerId ?? this.providerId,
      messageIdHeader: messageIdHeader ?? this.messageIdHeader,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      whenEpochMs: whenEpochMs ?? this.whenEpochMs,
      rawHeaders: rawHeaders ?? this.rawHeaders,
      starred: starred ?? this.starred,
      threadId: threadId ?? this.threadId,
      snoozedUntil: clearSnoozedUntil
          ? null
          : (snoozedUntil ?? this.snoozedUntil),
      trashedAt: clearTrashedAt ? null : (trashedAt ?? this.trashedAt),
      isDraft: isDraft ?? this.isDraft,
      draftSyncProviderId: draftSyncProviderId ?? this.draftSyncProviderId,
    );
  }
}
