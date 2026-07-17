// ==============================================================================
// File: lib/protocol/graph_mail_provider.dart
// Description: Microsoft Graph implementation of the remote mail contract.
// Component: Protocol / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bytemail/focus/focus_header_map.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:http/http.dart' as http;

/// Thrown when Graph rejects the bearer token and interactive re-auth is needed.
class GraphAuthException implements Exception {
  const GraphAuthException([
    this.message =
        'Microsoft Graph re-authentication required. Sign in again.',
  ]);

  final String message;

  @override
  String toString() => 'GraphAuthException: $message';
}

/// Invoked once after Graph returns HTTP 401 so callers can force-refresh tokens.
typedef GraphUnauthorizedHandler = Future<void> Function();

/// Result of a Microsoft Graph messages delta query (near-push).
class GraphDeltaResult {
  const GraphDeltaResult({
    required this.changed,
    required this.removedProviderIds,
    this.deltaLink,
  });

  /// Upsertable message headers from the delta page set.
  final List<RemoteMessageHeader> changed;

  /// Provider message ids marked `@removed` (hard-delete locally).
  final List<String> removedProviderIds;

  /// Opaque `@odata.deltaLink` to resume the next incremental poll.
  final String? deltaLink;
}

/// Polling Microsoft Graph adapter using bearer tokens supplied by auth.
class GraphMailProvider extends MailProvider {
  GraphMailProvider(
    this._accessToken, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 45),
    GraphUnauthorizedHandler? onUnauthorized,
  })  : _ownsClient = client == null,
        _client = _TimeoutClient(client ?? http.Client(), timeout),
        _onUnauthorized = onUnauthorized;

  static final Uri _graphBaseUri = Uri.parse('https://graph.microsoft.com/v1.0');

  final Future<String> Function() _accessToken;
  final http.Client _client;
  final bool _ownsClient;
  final GraphUnauthorizedHandler? _onUnauthorized;
  bool _disposed = false;

  @override
  MailCapabilities get capabilities => const MailCapabilities(
        supportsServerSearch: true,
        supportsPush: true,
        supportsPartialBody: true,
        supportsSend: true,
        supportsStar: true,
        supportsMove: true,
        supportsDelete: true,
        supportsAttachments: true,
      );

  static const String graphDeltaCursorKey = 'graph_delta';
  static const int _maxDeltaPages = 20;
  static const String _messageSelect =
      'id,subject,from,receivedDateTime,bodyPreview,internetMessageId,'
      'conversationId,isRead,hasAttachments,internetMessageHeaders';

  static const int _maxMailFolderPages = 20;

  @override
  Future<List<RemoteFolder>> listFolders() async {
    // wellKnownName is beta-only — selecting it on v1.0 400s and blocked bootstrap.
    final List<Map<String, Object?>> folderPages = await _listMailFolderPages();
    final Map<String, String> roleById = await _wellKnownFolderRoles();
    return folderPages
        .map(
          (Map<String, Object?> json) => _folderFromJson(
            json,
            role: roleById[json['id'] as String?],
          ),
        )
        .toList(growable: false);
  }

  /// Paginates `/me/mailFolders` following `@odata.nextLink` up to a page cap.
  Future<List<Map<String, Object?>>> _listMailFolderPages() async {
    final List<Map<String, Object?>> folders = <Map<String, Object?>>[];
    Map<String, Object?> document = await _getCollection(
      '/me/mailFolders',
      queryParameters: <String, String>{
        r'$select':
            'id,displayName,parentFolderId,unreadItemCount,totalItemCount',
        r'$top': '100',
      },
    );
    folders.addAll(_values(document));
    for (int page = 1; page < _maxMailFolderPages; page++) {
      final String? nextLink = document[r'@odata.nextLink'] as String?;
      if (nextLink == null || nextLink.trim().isEmpty) {
        break;
      }
      document = await _getAbsoluteUrl(nextLink);
      folders.addAll(_values(document));
    }
    return folders;
  }

  /// Resolve standard folder roles via well-known path names (valid on v1.0).
  Future<Map<String, String>> _wellKnownFolderRoles() async {
    const List<String> names = <String>[
      'inbox',
      'sentitems',
      'drafts',
      'deleteditems',
      'junkemail',
      'archive',
    ];
    final Map<String, String> roles = <String, String>{};
    for (final String name in names) {
      try {
        final Map<String, Object?> folder = await _getObject(
          '/me/mailFolders/$name',
          queryParameters: const <String, String>{r'$select': 'id'},
        );
        final String? id = folder['id'] as String?;
        if (id != null && id.isNotEmpty) {
          roles[id] = name;
        }
      } on Object {
        // Missing folder, timeout, or transient Graph error — keep listing.
      }
    }
    return roles;
  }

  @override
  Future<RemoteFolder> createFolder({
    required String displayName,
    String? role,
  }) async {
    final String trimmed = displayName.trim();
    if (trimmed.isEmpty) {
      throw const ProtocolException('A folder display name is required.');
    }
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.post(
        _uri('/me/mailFolders'),
        headers: headers,
        body: jsonEncode(<String, String>{'displayName': trimmed}),
      ),
      contentType: 'application/json',
    );
    _ensureSuccess(response);
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<Object?, Object?>) {
      throw const ProtocolException('Graph returned an invalid createFolder body.');
    }
    final Map<String, Object?> json = decoded.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
    return _folderFromJson(json, role: role);
  }

  @override
  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50}) {
    return listRecentInFolder('inbox', limit: limit);
  }

  @override
  Future<List<RemoteMessageHeader>> listRecentInFolder(
    String folderRemoteId, {
    int limit = 50,
  }) async {
    if (limit < 1) {
      return <RemoteMessageHeader>[];
    }
    final String folderSegment = Uri.encodeComponent(folderRemoteId);
    final Map<String, Object?> document = await _getCollection(
      '/me/mailFolders/$folderSegment/messages',
      queryParameters: <String, String>{
        r'$select': _messageSelect,
        r'$orderby': 'receivedDateTime desc',
        r'$top': limit.toString(),
      },
    );
    return _values(document).map(_messageFromJson).toList(growable: false);
  }

  /// Incremental folder sync via Graph delta.
  ///
  /// When [deltaLink] is null, starts a new delta for [folderRemoteId] and
  /// follows `@odata.nextLink` until `@odata.deltaLink` is returned.
  /// When [deltaLink] is set, resumes from that opaque URL.
  ///
  /// Throws [ProtocolException] with status 410 when the token is expired;
  /// callers should clear the cursor and fall back to [listRecentInFolder].
  Future<GraphDeltaResult> listDelta(
    String folderRemoteId, {
    String? deltaLink,
  }) async {
    final List<RemoteMessageHeader> changed = <RemoteMessageHeader>[];
    final List<String> removed = <String>[];
    String? nextDeltaLink;

    Map<String, Object?> document;
    if (deltaLink != null && deltaLink.trim().isNotEmpty) {
      document = await _getAbsoluteUrl(deltaLink.trim());
    } else {
      final String folderSegment = Uri.encodeComponent(folderRemoteId);
      document = await _getCollection(
        '/me/mailFolders/$folderSegment/messages/delta',
        queryParameters: <String, String>{
          r'$select': _messageSelect,
        },
      );
    }

    for (int page = 0; page < _maxDeltaPages; page++) {
      _mergeDeltaPage(document, changed: changed, removed: removed);
      final String? link = document[r'@odata.deltaLink'] as String?;
      if (link != null && link.trim().isNotEmpty) {
        nextDeltaLink = link.trim();
        break;
      }
      final String? next = document[r'@odata.nextLink'] as String?;
      if (next == null || next.trim().isEmpty) {
        break;
      }
      document = await _getAbsoluteUrl(next.trim());
    }

    return GraphDeltaResult(
      changed: List<RemoteMessageHeader>.unmodifiable(changed),
      removedProviderIds: List<String>.unmodifiable(removed),
      deltaLink: nextDeltaLink,
    );
  }

  void _mergeDeltaPage(
    Map<String, Object?> document, {
    required List<RemoteMessageHeader> changed,
    required List<String> removed,
  }) {
    for (final Map<String, Object?> item in _values(document)) {
      final Object? removedMeta = item[r'@removed'];
      final String? id = item['id'] as String?;
      if (removedMeta != null) {
        if (id != null && id.isNotEmpty) {
          removed.add(id);
        }
        continue;
      }
      try {
        changed.add(_messageFromJson(item));
      } on ProtocolException {
        // Skip incomplete delta rows that lack required fields.
      }
    }
  }

  @override
  Future<String?> fetchBody(
    String providerId, {
    String? folderRemoteId,
  }) async {
    final Map<String, Object?> document = await _getObject(
      '/me/messages/${Uri.encodeComponent(providerId)}',
      queryParameters: <String, String>{r'$select': 'body'},
    );
    final Object? body = document['body'];
    if (body is! Map<Object?, Object?>) {
      return null;
    }
    return body['content'] as String?;
  }

  @override
  Future<String?> fetchHeaders(
    String providerId, {
    String? folderRemoteId,
  }) async {
    final Map<String, Object?> document = await _getObject(
      '/me/messages/${Uri.encodeComponent(providerId)}',
      queryParameters: <String, String>{
        r'$select':
            'internetMessageHeaders,internetMessageId,subject,from,'
            'toRecipients,ccRecipients,receivedDateTime',
      },
    );
    return _formatGraphHeaders(document);
  }

  @override
  Future<void> send({
    required List<String> to,
    List<String> cc = const <String>[],
    List<String> bcc = const <String>[],
    required String subject,
    required String body,
  }) async {
    final List<String> toClean = _cleanAddresses(to);
    final List<String> ccClean = _cleanAddresses(cc);
    final List<String> bccClean = _cleanAddresses(bcc);
    if (toClean.isEmpty && ccClean.isEmpty && bccClean.isEmpty) {
      throw const ProtocolException('A recipient is required to send mail.');
    }
    final Map<String, Object> message = <String, Object>{
      'subject': subject,
      'body': <String, String>{
        'contentType': 'Text',
        'content': body,
      },
      'toRecipients': _graphRecipients(toClean),
    };
    if (ccClean.isNotEmpty) {
      message['ccRecipients'] = _graphRecipients(ccClean);
    }
    if (bccClean.isNotEmpty) {
      message['bccRecipients'] = _graphRecipients(bccClean);
    }
    final String payload = jsonEncode(<String, Object>{
      'message': message,
      'saveToSentItems': true,
    });
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.post(
        _uri('/me/sendMail'),
        headers: headers,
        body: payload,
      ),
      contentType: 'application/json',
    );
    _ensureSuccess(response);
  }

  static List<String> _cleanAddresses(List<String> addresses) {
    return addresses
        .map((String address) => address.trim())
        .where((String address) => address.isNotEmpty)
        .toList(growable: false);
  }

  static List<Map<String, Map<String, String>>> _graphRecipients(
    List<String> addresses,
  ) {
    return addresses
        .map(
          (String address) => <String, Map<String, String>>{
            'emailAddress': <String, String>{'address': address},
          },
        )
        .toList(growable: false);
  }

  @override
  Future<void> setRead(
    String providerId, {
    required bool isRead,
    String? folderRemoteId,
  }) async {
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.patch(
        _uri('/me/messages/${Uri.encodeComponent(providerId)}'),
        headers: headers,
        body: jsonEncode(<String, bool>{'isRead': isRead}),
      ),
      contentType: 'application/json',
    );
    _ensureSuccess(response);
  }

  @override
  Future<void> setStarred(String providerMessageId, bool starred) async {
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.patch(
        _uri('/me/messages/${Uri.encodeComponent(providerMessageId)}'),
        headers: headers,
        body: jsonEncode(<String, Object>{
          'flag': <String, String>{
            'flagStatus': starred ? 'flagged' : 'notFlagged',
          },
        }),
      ),
      contentType: 'application/json',
    );
    _ensureSuccess(response);
  }

  @override
  Future<void> moveMessage(
    String providerMessageId,
    String targetFolderRemoteId, {
    String? sourceFolderRemoteId,
  }) async {
    if (targetFolderRemoteId.trim().isEmpty) {
      throw const ProtocolException('A target folder id is required to move mail.');
    }
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.post(
        _uri('/me/messages/${Uri.encodeComponent(providerMessageId)}/move'),
        headers: headers,
        body: jsonEncode(<String, String>{
          'destinationId': targetFolderRemoteId,
        }),
      ),
      contentType: 'application/json',
    );
    _ensureSuccess(response);
  }

  @override
  Future<void> deleteMessage(
    String providerMessageId, {
    bool permanent = false,
    String? folderRemoteId,
  }) async {
    final String encodedId = Uri.encodeComponent(providerMessageId);
    if (permanent) {
      final http.Response permanentResponse = await _sendAuthorized(
        (Map<String, String> headers) => _client.post(
          _uri('/me/messages/$encodedId/permanentDelete'),
          headers: headers,
          body: '{}',
        ),
        contentType: 'application/json',
      );
      _ensureSuccess(permanentResponse);
      return;
    }
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.delete(
        _uri('/me/messages/$encodedId'),
        headers: headers,
      ),
    );
    _ensureSuccess(response);
  }

  @override
  Future<List<MailAttachmentMeta>> listAttachments(
    String providerMessageId,
  ) async {
    final Map<String, Object?> document = await _getCollection(
      '/me/messages/${Uri.encodeComponent(providerMessageId)}/attachments',
      queryParameters: <String, String>{
        r'$select': 'id,name,contentType,size,isInline,contentId',
        r'$top': '100',
      },
    );
    return _values(document).map(_attachmentFromJson).toList(growable: false);
  }

  @override
  Future<MailAttachmentBytes> fetchAttachment(
    String providerMessageId,
    String partId,
  ) async {
    final String messageSegment = Uri.encodeComponent(providerMessageId);
    final String partSegment = Uri.encodeComponent(partId);
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.get(
        _uri('/me/messages/$messageSegment/attachments/$partSegment/\$value'),
        headers: headers,
      ),
    );
    _ensureSuccess(response);
    final String contentType =
        response.headers['content-type'] ?? 'application/octet-stream';
    return MailAttachmentBytes(
      partId: partId,
      bytes: Uint8List.fromList(response.bodyBytes),
      contentType: contentType.split(';').first.trim(),
    );
  }

  MailAttachmentMeta _attachmentFromJson(Map<String, Object?> json) {
    final String? id = json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw const ProtocolException('Graph returned an attachment without an id.');
    }
    return MailAttachmentMeta(
      partId: id,
      name: json['name'] as String? ?? 'attachment',
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      sizeBytes: json['size'] as int?,
      isInline: json['isInline'] as bool? ?? false,
      contentId: json['contentId'] as String?,
    );
  }

  @override
  Future<List<RemoteMessageHeader>> searchRemote(String query) async {
    final String trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return <RemoteMessageHeader>[];
    }
    final Map<String, Object?> document = await _getCollection(
      '/me/messages',
      queryParameters: <String, String>{
        r'$search': '"${trimmedQuery.replaceAll('"', r'\"')}"',
        r'$select':
            'id,subject,from,receivedDateTime,bodyPreview,internetMessageId,'
            'conversationId,isRead,hasAttachments,internetMessageHeaders',
        r'$top': '50',
      },
      extraHeaders: const <String, String>{'ConsistencyLevel': 'eventual'},
    );
    return _values(document).map(_messageFromJson).toList(growable: false);
  }

  @override
  Future<void> dispose() async {
    if (!_disposed) {
      _disposed = true;
      if (_ownsClient) {
        _client.close();
      }
    }
  }

  Future<Map<String, Object?>> _getCollection(
    String path, {
    required Map<String, String> queryParameters,
    Map<String, String> extraHeaders = const <String, String>{},
  }) =>
      _getObject(
        path,
        queryParameters: queryParameters,
        extraHeaders: extraHeaders,
      );

  Future<Map<String, Object?>> _getObject(
    String path, {
    Map<String, String> queryParameters = const <String, String>{},
    Map<String, String> extraHeaders = const <String, String>{},
  }) async {
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.get(
        _uri(path, queryParameters: queryParameters),
        headers: headers,
      ),
      extraHeaders: extraHeaders,
    );
    return _decodeObjectResponse(response);
  }

  Future<Map<String, Object?>> _getAbsoluteUrl(String url) async {
    final Uri uri = Uri.parse(url);
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.get(uri, headers: headers),
    );
    return _decodeObjectResponse(response);
  }

  Map<String, Object?> _decodeObjectResponse(http.Response response) {
    _ensureSuccess(response);
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<Object?, Object?>) {
      throw const ProtocolException('Graph returned an invalid JSON object.');
    }
    return decoded.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
  }

  /// Sends an authorized Graph request; on 401, refreshes once and retries.
  Future<http.Response> _sendAuthorized(
    Future<http.Response> Function(Map<String, String> headers) send, {
    String? contentType,
    Map<String, String> extraHeaders = const <String, String>{},
  }) async {
    _ensureNotDisposed();
    Future<http.Response> once() async {
      final Map<String, String> headers = <String, String>{
        ...await _headers(contentType: contentType),
        ...extraHeaders,
      };
      return send(headers);
    }

    http.Response response = await once();
    final GraphUnauthorizedHandler? onUnauthorized = _onUnauthorized;
    if (response.statusCode == 401 && onUnauthorized != null) {
      await onUnauthorized();
      response = await once();
    }
    return response;
  }

  Uri _uri(String path, {Map<String, String> queryParameters = const <String, String>{}}) =>
      _graphBaseUri.replace(
        path: '${_graphBaseUri.path}$path',
        queryParameters: queryParameters,
      );

  Future<Map<String, String>> _headers({String? contentType}) async {
    final String token = await _accessToken();
    if (token.trim().isEmpty) {
      throw const ProtocolException('No Microsoft Graph access token is available.');
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (contentType != null) 'Content-Type': contentType,
    };
  }

  List<Map<String, Object?>> _values(Map<String, Object?> document) {
    final Object? values = document['value'];
    if (values is! List<Object?>) {
      throw const ProtocolException('Graph response did not contain a value collection.');
    }
    return values
        .whereType<Map<Object?, Object?>>()
        .map(
          (Map<Object?, Object?> item) => item.map(
            (Object? key, Object? value) => MapEntry(key.toString(), value),
          ),
        )
        .toList(growable: false);
  }

  RemoteFolder _folderFromJson(
    Map<String, Object?> json, {
    String? role,
  }) {
    final String? id = json['id'] as String?;
    final String? name = json['displayName'] as String?;
    if (id == null || name == null) {
      throw const ProtocolException('Graph returned a folder without an id or name.');
    }
    return RemoteFolder(
      providerId: id,
      name: name,
      parentProviderId: json['parentFolderId'] as String?,
      role: role,
      unreadCount: json['unreadItemCount'] as int?,
      totalCount: json['totalItemCount'] as int?,
    );
  }

  RemoteMessageHeader _messageFromJson(Map<String, Object?> json) {
    final String? id = json['id'] as String?;
    final String? receivedDateTime = json['receivedDateTime'] as String?;
    if (id == null || receivedDateTime == null) {
      throw const ProtocolException('Graph returned a message without an id or date.');
    }
    final Map<Object?, Object?>? from =
        json['from'] as Map<Object?, Object?>?;
    final Map<Object?, Object?>? emailAddress =
        from?['emailAddress'] as Map<Object?, Object?>?;
    return RemoteMessageHeader(
      providerId: id,
      subject: json['subject'] as String? ?? '',
      fromAddress: emailAddress?['address'] as String? ?? '',
      fromName: emailAddress?['name'] as String?,
      snippet: json['bodyPreview'] as String?,
      messageIdHeader: json['internetMessageId'] as String?,
      threadId: json['conversationId'] as String?,
      receivedAt: DateTime.parse(receivedDateTime).toLocal(),
      isRead: json['isRead'] as bool? ?? false,
      hasAttachments: json['hasAttachments'] as bool? ?? false,
      classificationHeaders: _classificationHeadersFromJson(json),
    );
  }

  Map<String, String> _classificationHeadersFromJson(Map<String, Object?> json) {
    final Map<String, String> headers = <String, String>{};
    final Object? headerList = json['internetMessageHeaders'];
    if (headerList is List<Object?>) {
      for (final Object? item in headerList) {
        if (item is! Map<Object?, Object?>) {
          continue;
        }
        final String? name = item['name'] as String?;
        final String? value = item['value'] as String?;
        if (name == null || value == null) {
          continue;
        }
        final String key = name.trim().toLowerCase();
        if (key == 'list-id' ||
            key == 'list-unsubscribe' ||
            key == 'list-unsubscribe-post' ||
            key == 'precedence' ||
            key == 'auto-submitted' ||
            key == 'x-campaign' ||
            key == 'feedback-id' ||
            key == 'x-mailer') {
          headers[key] = value.trim();
        }
      }
    }
    return focusHeadersFromFields(extra: headers);
  }

  String? _formatGraphHeaders(Map<String, Object?> document) {
    final StringBuffer buffer = StringBuffer();
    final Object? headerList = document['internetMessageHeaders'];
    if (headerList is List<Object?>) {
      for (final Object? item in headerList) {
        if (item is! Map<Object?, Object?>) {
          continue;
        }
        final String? name = item['name'] as String?;
        final String? value = item['value'] as String?;
        if (name == null || value == null) {
          continue;
        }
        buffer.writeln('$name: $value');
      }
    }
    if (buffer.isEmpty) {
      final String? messageId = document['internetMessageId'] as String?;
      final String? subject = document['subject'] as String?;
      final Map<Object?, Object?>? from =
          document['from'] as Map<Object?, Object?>?;
      final Map<Object?, Object?>? emailAddress =
          from?['emailAddress'] as Map<Object?, Object?>?;
      final String? fromLine = _graphAddressLine(
        emailAddress?['name'] as String?,
        emailAddress?['address'] as String?,
      );
      final String? toLine = _graphRecipientsLine(
        document['toRecipients'] as List<Object?>?,
      );
      final String? ccLine = _graphRecipientsLine(
        document['ccRecipients'] as List<Object?>?,
      );
      final String? received = document['receivedDateTime'] as String?;
      if (fromLine != null) {
        buffer.writeln('From: $fromLine');
      }
      if (toLine != null) {
        buffer.writeln('To: $toLine');
      }
      if (ccLine != null) {
        buffer.writeln('Cc: $ccLine');
      }
      if (subject != null && subject.isNotEmpty) {
        buffer.writeln('Subject: $subject');
      }
      if (received != null && received.isNotEmpty) {
        buffer.writeln('Date: $received');
      }
      if (messageId != null && messageId.isNotEmpty) {
        buffer.writeln('Message-ID: $messageId');
      }
    }
    final String text = buffer.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _graphRecipientsLine(List<Object?>? recipients) {
    if (recipients == null || recipients.isEmpty) {
      return null;
    }
    final List<String> parts = <String>[];
    for (final Object? recipient in recipients) {
      if (recipient is! Map<Object?, Object?>) {
        continue;
      }
      final Map<Object?, Object?>? emailAddress =
          recipient['emailAddress'] as Map<Object?, Object?>?;
      final String? line = _graphAddressLine(
        emailAddress?['name'] as String?,
        emailAddress?['address'] as String?,
      );
      if (line != null) {
        parts.add(line);
      }
    }
    return parts.isEmpty ? null : parts.join(', ');
  }

  String? _graphAddressLine(String? name, String? address) {
    final String? trimmedAddress = address?.trim();
    if (trimmedAddress == null || trimmedAddress.isEmpty) {
      return null;
    }
    final String? trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty) {
      return trimmedAddress;
    }
    return '$trimmedName <$trimmedAddress>';
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw const GraphAuthException();
      }
      String message = response.body;
      try {
        final Object? decoded = jsonDecode(response.body);
        if (decoded is Map<Object?, Object?>) {
          final Object? error = decoded['error'];
          if (error is Map<Object?, Object?>) {
            message = error['message'] as String? ?? message;
          }
        }
      } on FormatException {
        // HTTP status and the raw body are still useful to callers.
      }
      throw ProtocolException(message, statusCode: response.statusCode);
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const ProtocolException('This Graph provider has been disposed.');
    }
  }
}

class _TimeoutClient extends http.BaseClient {
  _TimeoutClient(this._inner, this._timeout);

  final http.Client _inner;
  final Duration _timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(
      _timeout,
      onTimeout: () {
        throw TimeoutException(
          'Microsoft Graph request timed out after ${_timeout.inSeconds}s',
          _timeout,
        );
      },
    );
  }

  @override
  void close() => _inner.close();
}
