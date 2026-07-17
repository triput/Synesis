// ==============================================================================
// File: lib/repository/drift/drift_mappers.dart
// Description: Row-to-domain mappers shared by Drift store modules (no Flutter).
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/database.dart';
import 'package:bytemail/repository/mail_repository.dart';

MailFolder folderFromRow(Folder row) => MailFolder(
  id: row.id,
  accountId: row.accountId,
  name: row.name,
  remoteId: row.remoteId,
  role: row.role.isEmpty ? null : row.role,
  parentRemoteId: row.parentRemoteId,
  unreadCount: row.unreadCount,
  totalCount: row.totalCount,
);

MailMessage messageFromRow(Message row) => MailMessage(
  id: row.id,
  accountId: row.accountId,
  fromName: row.fromName,
  fromAddress: row.fromAddress,
  subject: row.subject,
  snippet: row.snippet,
  body: row.body ?? row.snippet,
  whenLabel: formatWhen(row.whenEpochMs),
  bucket: FocusBucket.values.byName(row.focusBucket),
  unread: row.unread,
  pinned: row.pinned,
  folderId: row.folderId,
  providerId: row.providerId,
  messageIdHeader: row.messageIdHeader,
  hasAttachments: row.hasAttachments,
  whenEpochMs: row.whenEpochMs,
  rawHeaders: row.rawHeaders,
  starred: row.starred,
  threadId: row.threadId,
  snoozedUntil: row.snoozedUntil,
  trashedAt: row.trashedAt,
  isDraft: row.isDraft,
  draftSyncProviderId: row.draftSyncProviderId,
);

OutboxItem outboxFromRow(OutboxData row) {
  return OutboxItem(
    id: row.id,
    accountId: row.accountId,
    to: joinRecipientJson(row.recipientsJson),
    subject: row.subject,
    body: row.body,
    state: row.state,
    attempts: row.attempts,
    lastError: row.lastError,
    createdAt: row.createdAt,
    cc: optionalJoinedRecipients(row.ccJson),
    bcc: optionalJoinedRecipients(row.bccJson),
    composeMode: row.composeMode,
    inReplyTo: row.inReplyTo,
    referencesJson: row.referencesJson,
    attachmentRefsJson: row.attachmentRefsJson,
    signatureId: row.signatureId,
    sendAfter: row.sendAfter,
  );
}

SyncJob syncJobFromRow(Job row) => SyncJob(
  id: row.id,
  accountId: row.accountId,
  type: row.type,
  status: row.status,
  payloadJson: row.payloadJson,
  cursorJson: row.cursorJson,
  updatedAt: row.updatedAt,
);

String formatWhen(int epochMs) {
  final DateTime time = DateTime.fromMillisecondsSinceEpoch(epochMs);
  final DateTime now = DateTime.now();
  if (time.year == now.year &&
      time.month == now.month &&
      time.day == now.day) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
  final DateTime yesterday = now.subtract(const Duration(days: 1));
  if (time.year == yesterday.year &&
      time.month == yesterday.month &&
      time.day == yesterday.day) {
    return 'Yesterday';
  }
  return '${time.month}/${time.day}/${time.year}';
}

String joinRecipientJson(String recipientsJson) {
  try {
    final Object? decoded = jsonDecode(recipientsJson);
    if (decoded is List) {
      return decoded
          .map((Object? entry) => entry?.toString().trim() ?? '')
          .where((String entry) => entry.isNotEmpty)
          .join(', ');
    }
  } on FormatException {
    // Fall through.
  }
  return recipientsJson.trim();
}

String? optionalJoinedRecipients(String? raw) {
  if (raw == null || raw.trim().isEmpty) {
    return null;
  }
  final String joined = joinRecipientJson(raw);
  return joined.isEmpty ? null : joined;
}

/// Header sync must not wipe a previously fetched full body.
String? bodyForUpsert({
  required String incomingBody,
  required String incomingSnippet,
  required String? existingBody,
}) {
  final String? cached = existingBody?.trim().isNotEmpty == true
      ? existingBody
      : null;
  if (cached == null) {
    return incomingBody;
  }
  final String incoming = incomingBody.trim();
  if (incoming.isEmpty || incoming == incomingSnippet.trim()) {
    return cached;
  }
  return incomingBody;
}

/// Header sync must not clear previously cached raw headers.
String? rawHeadersForUpsert({
  required String? incomingRawHeaders,
  required String? existingRawHeaders,
}) {
  final String? cached = existingRawHeaders?.trim().isNotEmpty == true
      ? existingRawHeaders
      : null;
  if (cached == null) {
    return incomingRawHeaders;
  }
  final String? incoming = incomingRawHeaders?.trim();
  if (incoming == null || incoming.isEmpty) {
    return cached;
  }
  return incomingRawHeaders;
}

String toFtsQuery(String query) => query
    .trim()
    .split(RegExp(r'\s+'))
    .where((String term) => term.isNotEmpty)
    .map((String term) => '"${term.replaceAll('"', '""')}"*')
    .join(' AND ');
