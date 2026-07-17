// ==============================================================================
// File: lib/mime/eml_codec.dart
// Description: RFC 822 export and local EML preview parsing.
// Component: MIME
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:bytemail/domain/models.dart';
import 'package:enough_mail/enough_mail.dart';

/// Parsed, local-only representation of an opened `.eml` file.
class EmlPreview {
  const EmlPreview({
    required this.fromName,
    required this.fromAddress,
    required this.subject,
    required this.body,
    required this.isHtml,
    required this.rawHeaders,
    this.sentAt,
  });

  final String fromName;
  final String fromAddress;
  final String subject;
  final String body;
  final bool isHtml;
  final String rawHeaders;
  final DateTime? sentAt;
}

/// Serializes a cached message into a self-contained RFC 822 document.
///
/// Provider headers that describe the original envelope are retained, while
/// MIME content headers are rebuilt because ByteMail stores the decoded body.
String exportMessageToEml(MailMessage message) {
  final bool html = _looksLikeHtml(message.body);
  final StringBuffer output = StringBuffer();
  final Set<String> rebuilt = <String>{
    'from',
    'subject',
    'date',
    'message-id',
    'mime-version',
    'content-type',
    'content-transfer-encoding',
  };
  for (final _HeaderBlock block in _headerBlocks(message.rawHeaders ?? '')) {
    if (!rebuilt.contains(block.name.toLowerCase())) {
      output.writeln(block.text);
    }
  }
  output.writeln(
    'From: ${_encodePhrase(message.fromName)} '
    '<${_singleLine(message.fromAddress)}>',
  );
  output.writeln('Subject: ${_encodePhrase(message.subject)}');
  final int? epochMs = message.whenEpochMs;
  if (epochMs != null) {
    output.writeln(
      'Date: ${HttpDate.format(DateTime.fromMillisecondsSinceEpoch(epochMs).toUtc())}',
    );
  }
  final String? messageId = message.messageIdHeader?.trim();
  if (messageId != null && messageId.isNotEmpty) {
    output.writeln('Message-ID: ${_singleLine(messageId)}');
  }
  output.writeln('MIME-Version: 1.0');
  output.writeln(
    'Content-Type: ${html ? 'text/html' : 'text/plain'}; charset=utf-8',
  );
  output.writeln('Content-Transfer-Encoding: base64');
  output.writeln();
  output.writeln(_wrapBase64(base64.encode(utf8.encode(message.body))));
  return output.toString().replaceAll('\n', '\r\n');
}

/// Parses an RFC 822 document for a local preview without importing it.
EmlPreview parseEmlPreview(String source) {
  final MimeMessage message = MimeMessage.parseFromText(source);
  final List<MailAddress>? senders = message.from;
  final MailAddress? sender =
      senders == null || senders.isEmpty ? null : senders.first;
  final String? html = message.decodeTextHtmlPart();
  final String body = html ?? message.decodeTextPlainPart() ?? '';
  final String normalized = source.replaceAll('\r\n', '\n');
  final int headerEnd = normalized.indexOf('\n\n');
  return EmlPreview(
    fromName: sender?.personalName?.trim() ?? '',
    fromAddress: sender?.email.trim() ?? '',
    subject: message.decodeSubject()?.trim() ?? '',
    body: body,
    isHtml: html != null,
    rawHeaders: headerEnd < 0 ? normalized.trim() : normalized.substring(0, headerEnd),
    sentAt: message.decodeDate(),
  );
}

bool _looksLikeHtml(String body) {
  final String value = body.trimLeft().toLowerCase();
  return value.startsWith('<!doctype html') ||
      value.startsWith('<html') ||
      value.contains('<body');
}

String _singleLine(String value) =>
    value.replaceAll(RegExp(r'[\r\n]+'), ' ').trim();

String _encodePhrase(String value) {
  final String safe = _singleLine(value);
  if (safe.runes.every((int rune) => rune >= 32 && rune < 127)) {
    return safe;
  }
  return '=?UTF-8?B?${base64.encode(utf8.encode(safe))}?=';
}

String _wrapBase64(String value) {
  final StringBuffer output = StringBuffer();
  for (int offset = 0; offset < value.length; offset += 76) {
    final int end = (offset + 76).clamp(0, value.length);
    output.writeln(value.substring(offset, end));
  }
  return output.toString().trimRight();
}

List<_HeaderBlock> _headerBlocks(String source) {
  final List<_HeaderBlock> blocks = <_HeaderBlock>[];
  String? name;
  StringBuffer? text;
  void flush() {
    final String? currentName = name;
    final StringBuffer? currentText = text;
    if (currentName != null && currentText != null) {
      blocks.add(_HeaderBlock(currentName, currentText.toString()));
    }
    name = null;
    text = null;
  }

  for (final String line in source.replaceAll('\r\n', '\n').split('\n')) {
    if (line.isEmpty) {
      break;
    }
    if ((line.startsWith(' ') || line.startsWith('\t')) && text != null) {
      text!.write('\n$line');
      continue;
    }
    flush();
    final int colon = line.indexOf(':');
    if (colon <= 0) {
      continue;
    }
    name = line.substring(0, colon).trim();
    text = StringBuffer(line);
  }
  flush();
  return blocks;
}

class _HeaderBlock {
  const _HeaderBlock(this.name, this.text);

  final String name;
  final String text;
}
