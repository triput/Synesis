// ==============================================================================
// File: lib/protocol/mail_provider.dart
// Description: Provider-neutral remote mail contract and value types.
// Component: Protocol
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:typed_data';

/// Feature set advertised by a [MailProvider].
class MailCapabilities {
  const MailCapabilities({
    required this.supportsServerSearch,
    required this.supportsPush,
    required this.supportsPartialBody,
    required this.supportsSend,
    this.supportsStar = false,
    this.supportsMove = false,
    this.supportsDelete = false,
    this.supportsAttachments = false,
  });

  final bool supportsServerSearch;
  final bool supportsPush;
  final bool supportsPartialBody;
  final bool supportsSend;
  final bool supportsStar;
  final bool supportsMove;
  final bool supportsDelete;
  final bool supportsAttachments;
}

/// Metadata for a remote attachment part.
class MailAttachmentMeta {
  const MailAttachmentMeta({
    required this.partId,
    required this.name,
    required this.contentType,
    this.sizeBytes,
    this.isInline = false,
    this.contentId,
  });

  final String partId;
  final String name;
  final String contentType;
  final int? sizeBytes;
  final bool isInline;
  final String? contentId;
}

/// Raw bytes for a fetched attachment part.
class MailAttachmentBytes {
  const MailAttachmentBytes({
    required this.partId,
    required this.bytes,
    required this.contentType,
    this.name,
  });

  final String partId;
  final Uint8List bytes;
  final String contentType;
  final String? name;
}

/// A remote folder without application-specific persistence identifiers.
class RemoteFolder {
  const RemoteFolder({
    required this.providerId,
    required this.name,
    this.parentProviderId,
    this.role,
    this.unreadCount,
    this.totalCount,
  });

  final String providerId;
  final String name;
  final String? parentProviderId;
  final String? role;
  final int? unreadCount;
  final int? totalCount;
}

/// Header data suitable for local persistence before a message body is fetched.
class RemoteMessageHeader {
  const RemoteMessageHeader({
    required this.providerId,
    required this.subject,
    required this.fromAddress,
    required this.receivedAt,
    this.fromName,
    this.snippet,
    this.messageIdHeader,
    this.threadId,
    this.inReplyTo,
    this.references,
    this.isRead = false,
    this.hasAttachments = false,
    this.classificationHeaders = const <String, String>{},
  });

  final String providerId;
  final String subject;
  final String fromAddress;
  final String? fromName;
  final String? snippet;
  final String? messageIdHeader;

  /// Unscoped thread / conversation key (Graph conversationId or IMAP-derived).
  /// SyncEngine account-scopes this before persistence.
  final String? threadId;

  /// RFC In-Reply-To header value when available (IMAP).
  final String? inReplyTo;

  /// RFC References header value when available (IMAP).
  final String? references;

  final DateTime receivedAt;
  final bool isRead;
  final bool hasAttachments;

  /// RFC headers used for Focus scoring (List-Id, List-Unsubscribe, etc.).
  final Map<String, String> classificationHeaders;
}

/// A recoverable failure while communicating with a mail provider.
class ProtocolException implements Exception {
  const ProtocolException(
    this.message, {
    this.statusCode,
    this.cause,
  });

  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() {
    final String base = statusCode == null
        ? 'ProtocolException: $message'
        : 'ProtocolException($statusCode): $message';
    if (cause == null) {
      return base;
    }
    return '$base Cause: $cause';
  }
}

/// Remote mail operations used by the sync engine.
abstract class MailProvider {
  const MailProvider();

  MailCapabilities get capabilities;

  Future<List<RemoteFolder>> listFolders();

  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50});

  /// Recent headers from an arbitrary folder ([folderRemoteId] is provider path/id).
  Future<List<RemoteMessageHeader>> listRecentInFolder(
    String folderRemoteId, {
    int limit = 50,
  });

  Future<String?> fetchBody(
    String providerId, {
    String? folderRemoteId,
  });

  /// Full RFC822-style header block for power-user inspection.
  Future<String?> fetchHeaders(
    String providerId, {
    String? folderRemoteId,
  });

  Future<void> send({
    required List<String> to,
    List<String> cc = const <String>[],
    List<String> bcc = const <String>[],
    required String subject,
    required String body,
  });

  Future<List<RemoteMessageHeader>> searchRemote(String query);

  /// Push read state to the remote mailbox ([providerId] is Graph id or IMAP UID).
  Future<void> setRead(
    String providerId, {
    required bool isRead,
    String? folderRemoteId,
  });

  /// Star / flag a remote message. Default throws [UnsupportedError].
  Future<void> setStarred(String providerMessageId, bool starred) {
    throw UnsupportedError('Star is not supported by this provider.');
  }

  /// Move a remote message into [targetFolderRemoteId]. Default throws.
  Future<void> moveMessage(
    String providerMessageId,
    String targetFolderRemoteId, {
    String? sourceFolderRemoteId,
  }) {
    throw UnsupportedError('Move is not supported by this provider.');
  }

  /// Delete a remote message. Default throws [UnsupportedError].
  Future<void> deleteMessage(
    String providerMessageId, {
    bool permanent = false,
    String? folderRemoteId,
  }) {
    throw UnsupportedError('Delete is not supported by this provider.');
  }

  /// List attachment metadata for a remote message. Default throws.
  Future<List<MailAttachmentMeta>> listAttachments(String providerMessageId) {
    throw UnsupportedError('Attachments are not supported by this provider.');
  }

  /// Fetch raw bytes for one attachment part. Default throws.
  Future<MailAttachmentBytes> fetchAttachment(
    String providerMessageId,
    String partId,
  ) {
    throw UnsupportedError('Attachments are not supported by this provider.');
  }

  /// Create a mailbox/folder on the remote server. Default throws.
  Future<RemoteFolder> createFolder({
    required String displayName,
    String? role,
  }) {
    throw UnsupportedError('Create folder is not supported by this provider.');
  }

  Future<void> dispose();
}
