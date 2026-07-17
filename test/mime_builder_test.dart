// ==============================================================================
// File: test/mime_builder_test.dart
// Description: Multipart MIME builder coverage for plain, HTML, and attachments.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-16
// ==============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bytemail/mime/mime.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildMultipartMessage', () {
    test('builds plain-text multipart message', () {
      final Uint8List bytes = buildMultipartMessage(
        const OutgoingEnvelope(
          from: 'me@byte.io',
          to: <String>['you@byte.io'],
          subject: 'Hello',
          textBody: 'Plain body',
        ),
      );
      final String mime = utf8.decode(bytes);
      expect(mime, contains('From: me@byte.io'));
      expect(mime, contains('To: you@byte.io'));
      expect(mime, contains('Subject: Hello'));
      expect(mime, contains('Content-Type: text/plain; charset=utf-8'));
      expect(mime, contains('Plain body'));
      expect(mime, contains('multipart/mixed'));
      expect(mime, isNot(contains('text/html')));
    });

    test('builds alternative part when htmlBody is present', () {
      final Uint8List bytes = buildMultipartMessage(
        const OutgoingEnvelope(
          from: 'me@byte.io',
          to: <String>['you@byte.io'],
          subject: 'Html',
          textBody: 'Plain',
          htmlBody: '<p>Html</p>',
        ),
      );
      final String mime = utf8.decode(bytes);
      expect(mime, contains('multipart/alternative'));
      expect(mime, contains('Content-Type: text/plain; charset=utf-8'));
      expect(mime, contains('Content-Type: text/html; charset=utf-8'));
      expect(mime, contains('<p>Html</p>'));
    });

    test('embeds a simple attachment as base64', () async {
      final Directory temp = await Directory.systemTemp.createTemp('bm_mime_');
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final File attachment = File(
        '${temp.path}${Platform.pathSeparator}note.txt',
      );
      await attachment.writeAsString('attach-bytes');

      final Uint8List bytes = await buildMultipartMessageInIsolate(
        OutgoingEnvelope(
          from: 'me@byte.io',
          to: const <String>['you@byte.io'],
          subject: 'With file',
          textBody: 'Body',
          attachmentPaths: <String>[attachment.path],
        ),
      );
      final String mime = utf8.decode(bytes);
      expect(
        mime,
        contains('Content-Disposition: attachment; filename="note.txt"'),
      );
      expect(mime, contains('Content-Transfer-Encoding: base64'));
      expect(mime, contains(base64.encode(utf8.encode('attach-bytes'))));
    });
  });
}
