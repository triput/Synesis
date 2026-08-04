// ==============================================================================
// File: lib/protocol/graph_mail_provider.dart
// Description: Microsoft Graph implementation of the remote mail contract.
// Component: Protocol / Integration
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-08-03
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:synesis/focus/focus_header_map.dart';
import 'package:synesis/mime/outgoing_envelope.dart';
import 'package:synesis/protocol/mail_provider.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

/// Attachments at or below this size are sent inline as base64 `contentBytes`
/// on a single `POST /me/sendMail` call. Above this per-file threshold,
/// [GraphMailProvider.sendEnvelope] switches to the draft + upload-session
/// path (D6-3) so large files don't hit inline Graph payload limits.
const int kGraphInlineAttachmentMaxBytes = 3 * 1024 * 1024;

/// Chunk size used for `PUT` calls against a Graph attachment upload
/// session. Microsoft recommends chunk sizes that are a multiple of 320 KiB;
/// this is 10 * 320 KiB (~3.125 MiB) to balance request count vs. memory use.
const int kGraphUploadChunkSizeBytes = 320 * 1024 * 10;

/// `$select` for [GraphMailProvider.listAttachments].
///
/// `contentId` lives on `microsoft.graph.fileAttachment`, not the polymorphic
/// base `attachment`. Unqualified `contentId` makes Graph return HTTP 400
/// (`Could not find a property named 'contentId'`) — DEF-073.
const String kGraphAttachmentListSelect =
    'id,name,contentType,size,isInline,microsoft.graph.fileAttachment/contentId';

/// MAPI `PR_IN_REPLY_TO_ID` — RFC `In-Reply-To` via Graph extended properties.
///
/// Graph `internetMessageHeaders` only accepts custom `x-`/`X-` names
/// (DEF-049); standard reply headers must use these MAPI tags instead.
const String kGraphInReplyToExtendedPropertyId = 'String 0x1042';

/// MAPI `PR_INTERNET_REFERENCES` — RFC `References` via Graph extended properties.
const String kGraphReferencesExtendedPropertyId = 'String 0x1039';

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
    Duration uploadTimeout = const Duration(minutes: 10),
    GraphUnauthorizedHandler? onUnauthorized,
  })  : _ownsClient = client == null,
        _innerClient = client ?? http.Client(),
        _onUnauthorized = onUnauthorized {
    _client = _TimeoutClient(_innerClient, timeout);
    // Large-attachment upload sessions can legitimately take minutes per
    // chunk on slow links, so this leg uses a much longer timeout than the
    // JSON-centric Graph calls above.
    _uploadClient = _TimeoutClient(_innerClient, uploadTimeout);
  }

  static final Uri _graphBaseUri = Uri.parse('https://graph.microsoft.com/v1.0');

  final Future<String> Function() _accessToken;
  final http.Client _innerClient;
  late final http.Client _client;
  late final http.Client _uploadClient;
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
        supportsServerSnooze: true,
      );

  static const String graphDeltaCursorKey = 'graph_delta';
  static const int _maxDeltaPages = 20;
  static const String _messageSelect =
      'id,subject,from,toRecipients,ccRecipients,receivedDateTime,bodyPreview,'
      'internetMessageId,conversationId,isRead,hasAttachments,internetMessageHeaders';

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

  @override
  Future<void> sendEnvelope(OutgoingEnvelope envelope) async {
    final List<String> toClean = _cleanAddresses(envelope.to);
    final List<String> ccClean = _cleanAddresses(envelope.cc);
    final List<String> bccClean = _cleanAddresses(envelope.bcc);
    if (toClean.isEmpty && ccClean.isEmpty && bccClean.isEmpty) {
      throw const ProtocolException('A recipient is required to send mail.');
    }
    final Map<String, Object> message = _buildOutgoingMessage(
      envelope,
      toClean: toClean,
      ccClean: ccClean,
      bccClean: bccClean,
    );

    if (envelope.attachmentPaths.isEmpty) {
      await _sendMailDirect(message);
      return;
    }

    final List<_OutgoingAttachmentFile> files =
        await _resolveAttachmentFiles(envelope.attachmentPaths);
    final bool anyLarge = files.any(
      (_OutgoingAttachmentFile file) =>
          file.sizeBytes > kGraphInlineAttachmentMaxBytes,
    );

    if (!anyLarge) {
      // Small path: every attachment fits under the inline threshold, so
      // keep the single-request `sendMail` call with base64 contentBytes.
      message['attachments'] = await _buildInlineAttachments(files);
      await _sendMailDirect(message);
      return;
    }

    // Large path: at least one attachment exceeds the inline threshold.
    // Once we're on this path every attachment uses an upload session so
    // there is a single, well-tested code path for large sends (D6-3).
    await _sendViaUploadSessions(message, files);
  }

  /// Builds the Graph `message` JSON object (subject, body, recipients,
  /// reply threading via MAPI extended properties) shared by both the inline
  /// and upload-session send paths. Attachments are attached separately by
  /// each path.
  Map<String, Object> _buildOutgoingMessage(
    OutgoingEnvelope envelope, {
    required List<String> toClean,
    required List<String> ccClean,
    required List<String> bccClean,
  }) {
    final bool useHtml =
        envelope.htmlBody != null && envelope.htmlBody!.trim().isNotEmpty;
    final Map<String, Object> message = <String, Object>{
      'subject': envelope.subject,
      'body': <String, String>{
        'contentType': useHtml ? 'HTML' : 'Text',
        'content': useHtml ? envelope.htmlBody!.trim() : envelope.textBody,
      },
      'toRecipients': _graphRecipients(
        toClean.isNotEmpty ? toClean : <String>[envelope.from],
      ),
    };
    if (ccClean.isNotEmpty) {
      message['ccRecipients'] = _graphRecipients(ccClean);
    }
    if (bccClean.isNotEmpty) {
      message['bccRecipients'] = _graphRecipients(bccClean);
    }
    // DEF-049: Graph rejects standard RFC headers on internetMessageHeaders
    // ("…should start with 'x-' or 'X-'"). Map In-Reply-To / References to
    // the documented MAPI extended properties instead.
    final List<Map<String, Object>> extended = <Map<String, Object>>[];
    final String? inReplyTo = envelope.inReplyTo?.trim();
    if (inReplyTo != null && inReplyTo.isNotEmpty) {
      extended.add(<String, Object>{
        'id': kGraphInReplyToExtendedPropertyId,
        'value': inReplyTo,
      });
    }
    final String? references = envelope.references?.trim();
    if (references != null && references.isNotEmpty) {
      extended.add(<String, Object>{
        'id': kGraphReferencesExtendedPropertyId,
        'value': references,
      });
    }
    if (extended.isNotEmpty) {
      message['singleValueExtendedProperties'] = extended;
    }
    return message;
  }

  /// Validates attachment paths exist and captures size/name/content-type
  /// metadata without reading full file bytes (needed before deciding
  /// between the inline and upload-session send paths).
  Future<List<_OutgoingAttachmentFile>> _resolveAttachmentFiles(
    List<String> paths,
  ) async {
    final List<_OutgoingAttachmentFile> files = <_OutgoingAttachmentFile>[];
    for (final String path in paths) {
      final File file = File(path);
      if (!await file.exists()) {
        throw ProtocolException('Attachment missing: $path');
      }
      final int sizeBytes = await file.length();
      files.add(
        _OutgoingAttachmentFile(
          path: path,
          name: p.basename(path),
          sizeBytes: sizeBytes,
          contentType: 'application/octet-stream',
        ),
      );
    }
    return List<_OutgoingAttachmentFile>.unmodifiable(files);
  }

  /// Reads each file fully and base64-encodes it as an inline
  /// `#microsoft.graph.fileAttachment` for the small/`sendMail` path.
  Future<List<Map<String, Object>>> _buildInlineAttachments(
    List<_OutgoingAttachmentFile> files,
  ) async {
    final List<Map<String, Object>> attachments = <Map<String, Object>>[];
    for (final _OutgoingAttachmentFile file in files) {
      final Uint8List bytes = await File(file.path).readAsBytes();
      attachments.add(<String, Object>{
        '@odata.type': '#microsoft.graph.fileAttachment',
        'name': file.name,
        'contentType': file.contentType,
        'contentBytes': base64Encode(bytes),
      });
    }
    return attachments;
  }

  /// Sends [message] with any attachments already inlined via a single
  /// `POST /me/sendMail`.
  Future<void> _sendMailDirect(Map<String, Object> message) async {
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

  /// Large-attachment send path (D6-3): creates a draft message, uploads
  /// every attachment through a Graph upload session, then sends the
  /// draft. If anything fails after the draft is created, best-effort
  /// deletes the draft so it doesn't leak into Sent/Drafts.
  Future<void> _sendViaUploadSessions(
    Map<String, Object> message,
    List<_OutgoingAttachmentFile> files,
  ) async {
    final http.Response draftResponse = await _sendAuthorized(
      (Map<String, String> headers) => _client.post(
        _uri('/me/messages'),
        headers: headers,
        body: jsonEncode(message),
      ),
      contentType: 'application/json',
    );
    final Map<String, Object?> draft = _decodeObjectResponse(draftResponse);
    final String? draftId = draft['id'] as String?;
    if (draftId == null || draftId.isEmpty) {
      throw const ProtocolException(
        'Microsoft Graph did not return a draft id for the large-attachment '
        'send path.',
      );
    }

    try {
      for (final _OutgoingAttachmentFile file in files) {
        await _uploadAttachmentSession(draftId, file);
      }
      final http.Response sendResponse = await _sendAuthorized(
        (Map<String, String> headers) => _client.post(
          _uri('/me/messages/${Uri.encodeComponent(draftId)}/send'),
          headers: headers,
          body: '{}',
        ),
        contentType: 'application/json',
      );
      _ensureSuccess(sendResponse);
    } on Object {
      await _bestEffortDeleteDraft(draftId);
      rethrow;
    }
  }

  /// Creates an attachment upload session for [file] on draft [draftId],
  /// then streams the file to the returned `uploadUrl` in fixed-size chunks.
  Future<void> _uploadAttachmentSession(
    String draftId,
    _OutgoingAttachmentFile file,
  ) async {
    final Map<String, Object> sessionRequest = <String, Object>{
      'AttachmentItem': <String, Object>{
        'attachmentType': 'file',
        'name': file.name,
        'size': file.sizeBytes,
        'contentType': file.contentType,
      },
    };
    final http.Response sessionResponse = await _sendAuthorized(
      (Map<String, String> headers) => _client.post(
        _uri(
          '/me/messages/${Uri.encodeComponent(draftId)}/attachments/createUploadSession',
        ),
        headers: headers,
        body: jsonEncode(sessionRequest),
      ),
      contentType: 'application/json',
    );
    final Map<String, Object?> session = _decodeObjectResponse(sessionResponse);
    final String? uploadUrl = session['uploadUrl'] as String?;
    if (uploadUrl == null || uploadUrl.isEmpty) {
      throw ProtocolException(
        'Microsoft Graph did not return an upload URL for attachment '
        '${file.name}.',
      );
    }
    await _uploadFileInChunks(uploadUrl, file);
  }

  /// Streams [file] to the pre-authorized upload-session [uploadUrl] using
  /// `PUT` requests with `Content-Range` chunk headers. `uploadUrl` may be
  /// on a different host than `graph.microsoft.com`, so it is used verbatim
  /// rather than resolved against the Graph base URI.
  Future<void> _uploadFileInChunks(
    String uploadUrl,
    _OutgoingAttachmentFile file,
  ) async {
    _ensureNotDisposed();
    final Uri uri = Uri.parse(uploadUrl);
    final int total = file.sizeBytes;
    if (total == 0) {
      // Degenerate but valid input — upload an empty final chunk so the
      // session still completes instead of hanging with zero PUTs.
      await _putUploadChunk(uri, Uint8List(0), start: 0, end: 0, total: 0);
      return;
    }
    final RandomAccessFile handle = await File(file.path).open();
    try {
      int start = 0;
      while (start < total) {
        final int end = math.min(start + kGraphUploadChunkSizeBytes, total) - 1;
        final int length = end - start + 1;
        await handle.setPosition(start);
        final Uint8List chunk = await handle.read(length);
        final http.Response response = await _putUploadChunk(
          uri,
          chunk,
          start: start,
          end: end,
          total: total,
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw ProtocolException(
            'Microsoft Graph rejected an upload-session chunk for '
            '${file.name}.',
            statusCode: response.statusCode,
          );
        }
        start = end + 1;
      }
    } finally {
      await handle.close();
    }
  }

  /// Issues one chunked `PUT` against an upload-session `uploadUrl`.
  ///
  /// `uploadUrl` is pre-authorized by Graph, so no `Authorization` header is
  /// sent here — this deliberately does not go through [_sendAuthorized]
  /// since a 401 refresh/retry is not meaningful against a session token.
  Future<http.Response> _putUploadChunk(
    Uri uri,
    Uint8List bytes, {
    required int start,
    required int end,
    required int total,
  }) async {
    final http.Request request = http.Request('PUT', uri)
      ..headers['Content-Range'] = 'bytes $start-$end/$total'
      ..headers['Content-Type'] = 'application/octet-stream'
      ..bodyBytes = bytes;
    final http.StreamedResponse streamed = await _uploadClient.send(request);
    return http.Response.fromStream(streamed);
  }

  /// Best-effort cleanup for a draft created during the upload-session path
  /// when a later step (attachment upload or `/send`) fails. Swallows its
  /// own errors so the original failure is what surfaces to the caller.
  Future<void> _bestEffortDeleteDraft(String draftId) async {
    try {
      final http.Response response = await _sendAuthorized(
        (Map<String, String> headers) => _client.delete(
          _uri('/me/messages/${Uri.encodeComponent(draftId)}'),
          headers: headers,
        ),
      );
      _ensureSuccess(response);
    } on Object {
      // Draft cleanup is best-effort; the original send failure is what
      // matters to the caller and has already propagated via rethrow.
    }
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
        r'$select': kGraphAttachmentListSelect,
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
        _innerClient.close();
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
    final String toRecipients =
        _graphRecipientsLine(json['toRecipients'] as List<Object?>?) ?? '';
    final String ccRecipients =
        _graphRecipientsLine(json['ccRecipients'] as List<Object?>?) ?? '';
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
      toRecipients: toRecipients,
      ccRecipients: ccRecipients,
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

/// Local attachment file staged for an outbound Graph send, resolved once
/// up front (path/name/size/content-type) so [GraphMailProvider.sendEnvelope]
/// can pick the inline vs. upload-session path without re-reading files.
class _OutgoingAttachmentFile {
  const _OutgoingAttachmentFile({
    required this.path,
    required this.name,
    required this.sizeBytes,
    required this.contentType,
  });

  final String path;
  final String name;
  final int sizeBytes;
  final String contentType;
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
