// ==============================================================================
// File: lib/mime/multipart_builder.dart
// Description: RFC-ish multipart MIME builder for outgoing envelopes.
// Component: MIME
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-16
// ==============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:bytemail/mime/outgoing_envelope.dart';
import 'package:path/path.dart' as p;

/// Builds a multipart MIME message synchronously on the calling isolate.
Uint8List buildMultipartMessage(OutgoingEnvelope envelope) {
  if (envelope.to.isEmpty) {
    throw ArgumentError.value(envelope.to, 'to', 'At least one recipient is required.');
  }
  final String mixedBoundary = _boundary('mixed');
  final StringBuffer buffer = StringBuffer();
  buffer.writeln('MIME-Version: 1.0');
  buffer.writeln('From: ${envelope.from}');
  buffer.writeln('To: ${envelope.to.join(', ')}');
  if (envelope.cc.isNotEmpty) {
    buffer.writeln('Cc: ${envelope.cc.join(', ')}');
  }
  if (envelope.bcc.isNotEmpty) {
    buffer.writeln('Bcc: ${envelope.bcc.join(', ')}');
  }
  buffer.writeln('Subject: ${_encodeHeader(envelope.subject)}');
  final String? inReplyTo = envelope.inReplyTo?.trim();
  if (inReplyTo != null && inReplyTo.isNotEmpty) {
    buffer.writeln('In-Reply-To: $inReplyTo');
  }
  final String? references = envelope.references?.trim();
  if (references != null && references.isNotEmpty) {
    buffer.writeln('References: $references');
  }
  buffer.writeln('Date: ${HttpDate.format(DateTime.now().toUtc())}');
  buffer.writeln(
    'Content-Type: multipart/mixed; boundary="$mixedBoundary"',
  );
  buffer.writeln();
  buffer.writeln('--$mixedBoundary');
  buffer.write(_buildBodyPart(envelope));
  for (final String path in envelope.attachmentPaths) {
    buffer.writeln('--$mixedBoundary');
    buffer.write(_buildAttachmentPart(path));
  }
  buffer.writeln('--$mixedBoundary--');
  buffer.writeln();
  return Uint8List.fromList(utf8.encode(buffer.toString()));
}

/// Builds a multipart MIME message on a background isolate.
Future<Uint8List> buildMultipartMessageInIsolate(
  OutgoingEnvelope envelope,
) {
  return Isolate.run(() => buildMultipartMessage(envelope));
}

String _buildBodyPart(OutgoingEnvelope envelope) {
  final String? htmlBody = envelope.htmlBody;
  if (htmlBody == null || htmlBody.isEmpty) {
    final StringBuffer part = StringBuffer();
    part.writeln('Content-Type: text/plain; charset=utf-8');
    part.writeln('Content-Transfer-Encoding: 8bit');
    part.writeln();
    part.writeln(envelope.textBody);
    return part.toString();
  }
  final String altBoundary = _boundary('alt');
  final StringBuffer part = StringBuffer();
  part.writeln(
    'Content-Type: multipart/alternative; boundary="$altBoundary"',
  );
  part.writeln();
  part.writeln('--$altBoundary');
  part.writeln('Content-Type: text/plain; charset=utf-8');
  part.writeln('Content-Transfer-Encoding: 8bit');
  part.writeln();
  part.writeln(envelope.textBody);
  part.writeln('--$altBoundary');
  part.writeln('Content-Type: text/html; charset=utf-8');
  part.writeln('Content-Transfer-Encoding: 8bit');
  part.writeln();
  part.writeln(htmlBody);
  part.writeln('--$altBoundary--');
  part.writeln();
  return part.toString();
}

String _buildAttachmentPart(String path) {
  final File file = File(path);
  if (!file.existsSync()) {
    throw ArgumentError.value(path, 'attachmentPaths', 'Attachment file not found.');
  }
  final String fileName = p.basename(path);
  final List<int> bytes = file.readAsBytesSync();
  final String encoded = base64.encode(bytes);
  final StringBuffer part = StringBuffer();
  part.writeln(
    'Content-Type: application/octet-stream; name="${_escapeParam(fileName)}"',
  );
  part.writeln(
    'Content-Disposition: attachment; filename="${_escapeParam(fileName)}"',
  );
  part.writeln('Content-Transfer-Encoding: base64');
  part.writeln();
  for (int i = 0; i < encoded.length; i += 76) {
    final int end = (i + 76 < encoded.length) ? i + 76 : encoded.length;
    part.writeln(encoded.substring(i, end));
  }
  return part.toString();
}

String _boundary(String label) {
  final int stamp = DateTime.now().microsecondsSinceEpoch;
  return 'bytemail_${label}_$stamp';
}

String _encodeHeader(String value) {
  if (value.runes.every((int rune) => rune >= 32 && rune < 127)) {
    return value;
  }
  final String encoded = base64.encode(utf8.encode(value));
  return '=?UTF-8?B?$encoded?=';
}

String _escapeParam(String value) => value.replaceAll('"', r'\"');
