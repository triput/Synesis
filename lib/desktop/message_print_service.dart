// ==============================================================================
// File: lib/desktop/message_print_service.dart
// Description: Builds and submits printable message documents.
// Component: Platform Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:typed_data';

import 'package:bytemail/domain/models.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Soft cap so a single body widget cannot exceed one printable page height.
const int _maxBodyChunkChars = 3000;

Future<Uint8List> buildMessagePdf(
  MailMessage message,
  PdfPageFormat pageFormat,
) async {
  final pw.ThemeData theme = await _messagePdfTheme();
  final pw.Document document = pw.Document(
    title: message.subject,
    author: message.fromAddress,
    theme: theme,
  );
  document.addPage(
    pw.MultiPage(
      pageFormat: pageFormat,
      margin: const pw.EdgeInsets.all(42),
      build: (pw.Context context) => <pw.Widget>[
        pw.Text(
          message.subject,
          style: pw.TextStyle(
            fontSize: 20,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text('From: ${message.fromName} <${message.fromAddress}>'),
        if (message.whenLabel.trim().isNotEmpty)
          pw.Text('Date: ${message.whenLabel}'),
        pw.SizedBox(height: 12),
        pw.Divider(),
        pw.SizedBox(height: 12),
        ..._printableBodyWidgets(message.body),
      ],
    ),
  );
  return document.save();
}

Future<bool> printMessage(MailMessage message) async {
  final Uint8List bytes = await buildMessagePdf(
    message,
    PdfPageFormat.letter,
  );
  return Printing.layoutPdf(
    name: '${_safeFileName(message.subject)}.pdf',
    onLayout: (PdfPageFormat format) async => bytes,
  );
}

/// Saves/shares the message PDF when the system print dialog is unavailable.
Future<bool> shareMessagePdf(MailMessage message) async {
  final Uint8List bytes = await buildMessagePdf(
    message,
    PdfPageFormat.letter,
  );
  await Printing.sharePdf(
    bytes: bytes,
    filename: '${_safeFileName(message.subject)}.pdf',
  );
  return true;
}

/// Unicode-capable theme — Helvetica cannot draw em dashes / smart quotes.
Future<pw.ThemeData> _messagePdfTheme() async {
  final ByteData regular = await rootBundle.load(
    'assets/fonts/OpenSans-Regular.ttf',
  );
  final ByteData bold = await rootBundle.load(
    'assets/fonts/OpenSans-Bold.ttf',
  );
  final pw.Font base = pw.Font.ttf(regular);
  final pw.Font boldFont = pw.Font.ttf(bold);
  return pw.ThemeData.withFont(
    base: base,
    bold: boldFont,
    fontFallback: <pw.Font>[base],
  );
}

/// Converts [body] into MultiPage-safe widgets that can span across pages.
List<pw.Widget> _printableBodyWidgets(String body) {
  final String text = _printableBody(body);
  if (text.isEmpty) {
    return const <pw.Widget>[];
  }

  final List<pw.Widget> widgets = <pw.Widget>[];
  for (final String line in text.split('\n')) {
    if (line.trim().isEmpty) {
      widgets.add(pw.SizedBox(height: 8));
      continue;
    }
    for (final String chunk in _chunkBodyText(line)) {
      widgets.add(
        pw.Paragraph(
          text: chunk,
          textAlign: pw.TextAlign.left,
          margin: const pw.EdgeInsets.only(bottom: 4),
        ),
      );
    }
  }
  return widgets;
}

/// Splits a long paragraph so each chunk stays within a safe page height.
List<String> _chunkBodyText(String text) {
  if (text.length <= _maxBodyChunkChars) {
    return <String>[text];
  }

  final List<String> chunks = <String>[];
  int offset = 0;
  while (offset < text.length) {
    final int remaining = text.length - offset;
    if (remaining <= _maxBodyChunkChars) {
      chunks.add(text.substring(offset));
      break;
    }

    int end = offset + _maxBodyChunkChars;
    final int space = text.lastIndexOf(' ', end);
    if (space > offset) {
      end = space;
    }
    chunks.add(text.substring(offset, end));
    offset = end;
    while (offset < text.length && text.codeUnitAt(offset) == 0x20) {
      offset++;
    }
  }
  return chunks;
}

String _printableBody(String body) {
  if (!RegExp(r'<[a-z!/][^>]*>', caseSensitive: false).hasMatch(body)) {
    return body;
  }
  return body
      .replaceAll(RegExp(r'<(br|hr)\s*/?>', caseSensitive: false), '\n')
      .replaceAll(
        RegExp(r'</(p|div|li|tr|h[1-6])>', caseSensitive: false),
        '\n',
      )
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

String _safeFileName(String value) {
  final String sanitized = value
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .trim();
  return sanitized.isEmpty ? 'ByteMail message' : sanitized;
}
