// ==============================================================================
// File: lib/ui/compose/compose_draft.dart
// Description: Unified compose draft model for new / reply / forward / edit.
// Component: UI / Domain
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/ui/compose/compose_prefill.dart';

export 'package:bytemail/ui/compose/compose_prefill.dart' show ComposeMode;

/// Local file staged for outbound attach (paths resolve via attachment_blobs).
class LocalAttachmentRef {
  const LocalAttachmentRef({
    required this.blobId,
    required this.fileName,
    required this.sizeBytes,
    this.mimeType,
  });

  final String blobId;
  final String fileName;
  final int sizeBytes;
  final String? mimeType;

  Map<String, Object?> toJson() => <String, Object?>{
        'blobId': blobId,
        'fileName': fileName,
        'sizeBytes': sizeBytes,
        if (mimeType != null) 'mimeType': mimeType,
      };

  factory LocalAttachmentRef.fromJson(Map<String, Object?> json) {
    return LocalAttachmentRef(
      blobId: json['blobId']?.toString() ?? '',
      fileName: json['fileName']?.toString() ?? 'attachment',
      sizeBytes: (json['sizeBytes'] as num?)?.toInt() ?? 0,
      mimeType: json['mimeType']?.toString(),
    );
  }
}

/// Mode-aware compose envelope used by the single compose UI.
class ComposeDraft {
  const ComposeDraft({
    required this.mode,
    required this.accountId,
    this.to = const <String>[],
    this.cc = const <String>[],
    this.bcc = const <String>[],
    this.subject = '',
    this.bodyPlain = '',
    this.bodyHtml,
    this.inReplyTo,
    this.references = const <String>[],
    this.signatureId,
    this.attachments = const <LocalAttachmentRef>[],
    this.sourceMessage,
    this.outboxDraftId,
    this.sendAfterMs,
  });

  final ComposeMode mode;
  final String accountId;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String subject;
  final String bodyPlain;
  final String? bodyHtml;
  final String? inReplyTo;
  final List<String> references;
  final String? signatureId;
  final List<LocalAttachmentRef> attachments;
  final MailMessage? sourceMessage;
  final String? outboxDraftId;
  final int? sendAfterMs;

  String get composeModeValue {
    switch (mode) {
      case ComposeMode.newMessage:
        return 'new';
      case ComposeMode.reply:
        return 'reply';
      case ComposeMode.replyAll:
        return 'replyAll';
      case ComposeMode.forward:
        return 'forward';
    }
  }

  String? get referencesJson {
    if (references.isEmpty) {
      return null;
    }
    return jsonEncode(references);
  }

  String? get attachmentRefsJson {
    if (attachments.isEmpty) {
      return null;
    }
    return jsonEncode(
      attachments.map((LocalAttachmentRef a) => a.toJson()).toList(),
    );
  }

  /// Builds a draft from the thin [ComposePrefill] envelope.
  factory ComposeDraft.fromPrefill(ComposePrefill prefill) {
    List<String> refs = const <String>[];
    final String? rawRefs = prefill.referencesJson;
    if (rawRefs != null && rawRefs.trim().isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(rawRefs);
        if (decoded is List<Object?>) {
          refs = decoded
              .map((Object? e) => e?.toString().trim() ?? '')
              .where((String s) => s.isNotEmpty)
              .toList(growable: false);
        }
      } on FormatException {
        refs = <String>[rawRefs.trim()];
      }
    }
    return ComposeDraft(
      mode: prefill.mode,
      accountId: prefill.accountId,
      to: prefill.to,
      cc: prefill.cc,
      subject: prefill.subject,
      bodyPlain: prefill.body,
      bodyHtml: prefill.bodyHtml,
      inReplyTo: prefill.inReplyTo,
      references: refs,
    );
  }

  /// Empty new-message draft for [accountId].
  factory ComposeDraft.newMessage(String accountId) {
    return ComposeDraft(
      mode: ComposeMode.newMessage,
      accountId: accountId,
    );
  }

  ComposeDraft copyWith({
    ComposeMode? mode,
    String? accountId,
    List<String>? to,
    List<String>? cc,
    List<String>? bcc,
    String? subject,
    String? bodyPlain,
    String? bodyHtml,
    bool clearBodyHtml = false,
    String? inReplyTo,
    List<String>? references,
    String? signatureId,
    bool clearSignatureId = false,
    List<LocalAttachmentRef>? attachments,
    MailMessage? sourceMessage,
    String? outboxDraftId,
    int? sendAfterMs,
    bool clearSendAfter = false,
  }) {
    return ComposeDraft(
      mode: mode ?? this.mode,
      accountId: accountId ?? this.accountId,
      to: to ?? this.to,
      cc: cc ?? this.cc,
      bcc: bcc ?? this.bcc,
      subject: subject ?? this.subject,
      bodyPlain: bodyPlain ?? this.bodyPlain,
      bodyHtml: clearBodyHtml ? null : (bodyHtml ?? this.bodyHtml),
      inReplyTo: inReplyTo ?? this.inReplyTo,
      references: references ?? this.references,
      signatureId:
          clearSignatureId ? null : (signatureId ?? this.signatureId),
      attachments: attachments ?? this.attachments,
      sourceMessage: sourceMessage ?? this.sourceMessage,
      outboxDraftId: outboxDraftId ?? this.outboxDraftId,
      sendAfterMs:
          clearSendAfter ? null : (sendAfterMs ?? this.sendAfterMs),
    );
  }
}
