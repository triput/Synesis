// ==============================================================================
// File: lib/compose/outgoing_message_builder.dart
// Description: Builds OutgoingEnvelope from outbox rows, signatures, and blobs.
// Component: Compose / Sync
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:bytemail/compose/account_signature.dart';
import 'package:bytemail/mime/outgoing_envelope.dart';
import 'package:bytemail/outbox/outbox_recipients.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/ui/compose/compose_draft.dart';

/// Default outbound HTML font stack (UI-P19).
const String kOutboundFontFamily =
    "'Segoe UI', system-ui, -apple-system, sans-serif";

/// Assembles a sendable [OutgoingEnvelope] from a queued [OutboxItem].
class OutgoingMessageBuilder {
  const OutgoingMessageBuilder({
    required this.resolveBlobPath,
    required this.loadSignature,
    required this.loadSignatureAssets,
  });

  final Future<String?> Function(String blobId) resolveBlobPath;
  final Future<MailSignature?> Function(String signatureId) loadSignature;
  final Future<List<MailSignatureAsset>> Function(String signatureId)
      loadSignatureAssets;

  Future<OutgoingEnvelope> build({
    required OutboxItem item,
    required String fromAddress,
  }) async {
    final List<String> to = splitOutboxRecipients(item.to);
    final List<String> cc = splitOutboxRecipients(item.cc);
    final List<String> bcc = splitOutboxRecipients(item.bcc);

    String textBody = item.body;
    String? htmlBody = _extractStoredHtml(item.body);
    if (htmlBody == null && _looksLikeHtml(item.body)) {
      htmlBody = item.body;
      textBody = _stripTags(item.body);
    }

    final List<String> attachmentPaths = <String>[];
    final String? refsJson = item.attachmentRefsJson;
    if (refsJson != null && refsJson.trim().isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(refsJson);
        if (decoded is List<Object?>) {
          for (final Object? entry in decoded) {
            if (entry is! Map) {
              continue;
            }
            final Map<String, Object?> map = Map<String, Object?>.from(entry);
            final LocalAttachmentRef ref = LocalAttachmentRef.fromJson(map);
            final String? path = await resolveBlobPath(ref.blobId);
            if (path != null && path.isNotEmpty) {
              attachmentPaths.add(path);
            }
          }
        }
      } on FormatException {
        // Ignore malformed attachment refs.
      }
    }

    final String? signatureId = item.signatureId?.trim();
    if (signatureId != null && signatureId.isNotEmpty) {
      final MailSignature? signature = await loadSignature(signatureId);
      if (signature != null) {
        final List<MailSignatureAsset> assets =
            await loadSignatureAssets(signatureId);
        final String plainSig = signature.bodyPlain.trim();
        if (plainSig.isNotEmpty) {
          textBody = '$textBody\n\n-- \n$plainSig';
        }
        String htmlSig = (signature.bodyHtml ?? '').trim();
        if (htmlSig.isEmpty && plainSig.isNotEmpty) {
          htmlSig = '<pre style="font-family:inherit;">'
              '${_escapeHtml(plainSig)}</pre>';
        }
        for (final MailSignatureAsset asset in assets) {
          final String dataUri = await _fileToDataUri(
            asset.localPath,
            asset.mimeType,
          );
          if (dataUri.isEmpty) {
            continue;
          }
          htmlSig = htmlSig.replaceAll('cid:${asset.contentId}', dataUri);
          if (!htmlSig.contains(dataUri) && !htmlSig.contains('<img')) {
            htmlSig = '$htmlSig<br><img src="$dataUri" alt="">';
          }
        }
        if (htmlSig.isNotEmpty) {
          htmlBody = '${htmlBody ?? _plainToHtml(item.body)}'
              '<br><div>--</div>$htmlSig';
        }
      }
    }

    if (htmlBody != null && htmlBody.isNotEmpty) {
      htmlBody = _wrapOutboundHtml(htmlBody);
    }

    String? references;
    final String? refsRaw = item.referencesJson?.trim();
    if (refsRaw != null && refsRaw.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(refsRaw);
        if (decoded is List<Object?>) {
          references = decoded
              .map((Object? e) => e?.toString().trim() ?? '')
              .where((String s) => s.isNotEmpty)
              .join(' ');
        } else {
          references = refsRaw;
        }
      } on FormatException {
        references = refsRaw;
      }
    }

    return OutgoingEnvelope(
      from: fromAddress,
      to: to,
      cc: cc,
      bcc: bcc,
      subject: item.subject,
      textBody: textBody,
      htmlBody: htmlBody,
      attachmentPaths: attachmentPaths,
      inReplyTo: item.inReplyTo,
      references: references,
    );
  }

  static String? _extractStoredHtml(String body) {
    const String marker = '\n---bytemail-html---\n';
    final int idx = body.indexOf(marker);
    if (idx < 0) {
      return null;
    }
    return body.substring(idx + marker.length);
  }

  /// Packs plain + optional HTML into a single outbox body string.
  static String packBody({required String plain, String? html}) {
    if (html == null || html.trim().isEmpty) {
      return plain;
    }
    return '$plain\n---bytemail-html---\n$html';
  }

  static String unpackPlain(String packed) {
    const String marker = '\n---bytemail-html---\n';
    final int idx = packed.indexOf(marker);
    if (idx < 0) {
      return packed;
    }
    return packed.substring(0, idx);
  }

  static bool _looksLikeHtml(String raw) {
    final String t = raw.trim();
    return t.startsWith('<') && t.contains('>');
  }

  static String _stripTags(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _plainToHtml(String plain) {
    return '<pre style="white-space:pre-wrap;font-family:inherit;">'
        '${_escapeHtml(plain)}</pre>';
  }

  static String _wrapOutboundHtml(String html) {
    if (html.contains('font-family') || html.contains('<html')) {
      return html;
    }
    return '<div style="font-family:$kOutboundFontFamily;font-size:14px;">'
        '$html</div>';
  }

  static String _escapeHtml(String raw) {
    return raw
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }

  static Future<String> _fileToDataUri(String path, String mimeType) async {
    try {
      final File file = File(path);
      if (!await file.exists()) {
        return '';
      }
      final List<int> bytes = await file.readAsBytes();
      final String b64 = base64Encode(bytes);
      return 'data:$mimeType;base64,$b64';
    } on FileSystemException {
      return '';
    }
  }
}