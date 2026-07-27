// ==============================================================================
// File: test/graph_mail_provider_upload_session_test.dart
// Description: GraphMailProvider small-attachment sendMail vs. large-attachment
//              draft + upload-session send paths (D6-3).
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-07-23
// ==============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:synesis/mime/outgoing_envelope.dart';
import 'package:synesis/protocol/graph_mail_provider.dart';
import 'package:synesis/protocol/mail_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bm_graph_upload_');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<File> writeAttachment(String name, int sizeBytes) async {
    final File file = File('${tempDir.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(Uint8List(sizeBytes), flush: true);
    return file;
  }

  int endOfRange(String contentRange) {
    final RegExpMatch match =
        RegExp(r'bytes (\d+)-(\d+)/(\d+)').firstMatch(contentRange)!;
    return int.parse(match.group(2)!);
  }

  int totalOfRange(String contentRange) {
    final RegExpMatch match =
        RegExp(r'bytes (\d+)-(\d+)/(\d+)').firstMatch(contentRange)!;
    return int.parse(match.group(3)!);
  }

  test(
    'small attachment stays on POST /me/sendMail with inline contentBytes',
    () async {
      final List<String> requestedPaths = <String>[];
      final List<String> requestedMethods = <String>[];

      final File small = await writeAttachment('note.txt', 1024);

      final http.Client client = MockClient((http.Request request) async {
        requestedPaths.add(request.url.path);
        requestedMethods.add(request.method);
        expect(request.url.path, '/v1.0/me/sendMail');
        final Map<String, Object?> body =
            jsonDecode(request.body) as Map<String, Object?>;
        final Map<String, Object?> message =
            body['message'] as Map<String, Object?>;
        final List<Object?> attachments =
            message['attachments'] as List<Object?>;
        expect(attachments, hasLength(1));
        final Map<String, Object?> attachment =
            attachments.single as Map<String, Object?>;
        expect(attachment['@odata.type'], '#microsoft.graph.fileAttachment');
        expect(attachment['name'], 'note.txt');
        expect(attachment.containsKey('contentBytes'), isTrue);
        return http.Response('', 202);
      });

      final GraphMailProvider provider = GraphMailProvider(
        () async => 'token',
        client: client,
      );
      addTearDown(provider.dispose);

      await provider.sendEnvelope(
        OutgoingEnvelope(
          from: 'me@byte.io',
          to: const <String>['you@byte.io'],
          subject: 'Small attach',
          textBody: 'Body',
          attachmentPaths: <String>[small.path],
        ),
      );

      expect(requestedMethods, <String>['POST']);
      expect(requestedPaths, <String>['/v1.0/me/sendMail']);
    },
  );

  test(
    'large attachment creates a draft, uses an upload session, then sends',
    () async {
      final List<String> requestSequence = <String>[];
      const String draftId = 'draft-123';
      const String uploadUrl =
          'https://upload.example.com/attachmentSession/abc';
      final List<Map<String, String>> putHeadersSeen = <Map<String, String>>[];
      final List<int> putBodyLengths = <int>[];

      // One full chunk plus a short remainder chunk so the PUT loop runs
      // twice, exercising the Content-Range math across chunk boundaries.
      final int largeSize = kGraphUploadChunkSizeBytes + 100;
      final File large = await writeAttachment('big.bin', largeSize);

      final http.Client client = MockClient((http.Request request) async {
        final String path = request.url.path;
        requestSequence.add('${request.method} $path');

        if (path == '/v1.0/me/messages' && request.method == 'POST') {
          final Map<String, Object?> body =
              jsonDecode(request.body) as Map<String, Object?>;
          expect(body.containsKey('attachments'), isFalse);
          expect(body['subject'], 'Large attach');
          return http.Response(
            jsonEncode(<String, Object?>{'id': draftId}),
            201,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }

        if (path ==
                '/v1.0/me/messages/$draftId/attachments/createUploadSession' &&
            request.method == 'POST') {
          final Map<String, Object?> body =
              jsonDecode(request.body) as Map<String, Object?>;
          final Map<String, Object?> item =
              body['AttachmentItem'] as Map<String, Object?>;
          expect(item['attachmentType'], 'file');
          expect(item['name'], 'big.bin');
          expect(item['size'], largeSize);
          return http.Response(
            jsonEncode(<String, Object?>{
              'uploadUrl': uploadUrl,
              'expirationDateTime': '2026-07-24T00:00:00Z',
            }),
            201,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }

        if (request.url.toString() == uploadUrl && request.method == 'PUT') {
          putHeadersSeen.add(Map<String, String>.from(request.headers));
          putBodyLengths.add(request.bodyBytes.length);
          final String range = request.headers['Content-Range']!;
          final bool isFinalChunk =
              endOfRange(range) + 1 == totalOfRange(range);
          return http.Response('', isFinalChunk ? 201 : 202);
        }

        if (path == '/v1.0/me/messages/$draftId/send' &&
            request.method == 'POST') {
          return http.Response('', 202);
        }

        fail('Unexpected request: ${request.method} $path');
      });

      final GraphMailProvider provider = GraphMailProvider(
        () async => 'token',
        client: client,
      );
      addTearDown(provider.dispose);

      await provider.sendEnvelope(
        OutgoingEnvelope(
          from: 'me@byte.io',
          to: const <String>['you@byte.io'],
          subject: 'Large attach',
          textBody: 'Body',
          attachmentPaths: <String>[large.path],
        ),
      );

      expect(requestSequence.first, 'POST /v1.0/me/messages');
      expect(
        requestSequence[1],
        'POST /v1.0/me/messages/$draftId/attachments/createUploadSession',
      );
      expect(requestSequence.last, 'POST /v1.0/me/messages/$draftId/send');
      expect(putHeadersSeen.length, 2);
      for (final Map<String, String> headers in putHeadersSeen) {
        expect(headers['Content-Type'], 'application/octet-stream');
        expect(headers['Content-Range'], startsWith('bytes '));
        expect(headers.containsKey('Authorization'), isFalse);
      }
      expect(putBodyLengths, <int>[kGraphUploadChunkSizeBytes, 100]);
      final int totalUploaded =
          putBodyLengths.fold<int>(0, (int sum, int len) => sum + len);
      expect(totalUploaded, largeSize);
    },
  );

  test(
    'best-effort deletes the draft when the upload session fails',
    () async {
      final List<String> requestSequence = <String>[];
      const String draftId = 'draft-456';

      final int largeSize = kGraphInlineAttachmentMaxBytes + 1;
      final File large = await writeAttachment('fails.bin', largeSize);

      final http.Client client = MockClient((http.Request request) async {
        final String path = request.url.path;
        requestSequence.add('${request.method} $path');

        if (path == '/v1.0/me/messages' && request.method == 'POST') {
          return http.Response(
            jsonEncode(<String, Object?>{'id': draftId}),
            201,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }

        if (path ==
                '/v1.0/me/messages/$draftId/attachments/createUploadSession' &&
            request.method == 'POST') {
          return http.Response(
            jsonEncode(<String, Object?>{
              'error': <String, Object?>{'message': 'Quota exceeded'},
            }),
            507,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }

        if (path == '/v1.0/me/messages/$draftId' &&
            request.method == 'DELETE') {
          return http.Response('', 204);
        }

        fail('Unexpected request: ${request.method} $path');
      });

      final GraphMailProvider provider = GraphMailProvider(
        () async => 'token',
        client: client,
      );
      addTearDown(provider.dispose);

      await expectLater(
        provider.sendEnvelope(
          OutgoingEnvelope(
            from: 'me@byte.io',
            to: const <String>['you@byte.io'],
            subject: 'Large attach fails',
            textBody: 'Body',
            attachmentPaths: <String>[large.path],
          ),
        ),
        throwsA(isA<ProtocolException>()),
      );

      expect(
        requestSequence,
        containsAllInOrder(<String>[
          'POST /v1.0/me/messages',
          'POST /v1.0/me/messages/$draftId/attachments/createUploadSession',
          'DELETE /v1.0/me/messages/$draftId',
        ]),
      );
    },
  );
}
