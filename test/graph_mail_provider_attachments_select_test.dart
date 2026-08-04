// ==============================================================================
// File: test/graph_mail_provider_attachments_select_test.dart
// Description: Graph listAttachments $select uses fileAttachment/contentId cast
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synesis/protocol/graph_mail_provider.dart';
import 'package:synesis/protocol/mail_provider.dart';

void main() {
  test(
    r'listAttachments $select casts contentId onto fileAttachment (DEF-073)',
    () async {
      Uri? seen;
      final http.Client client = MockClient((http.Request request) async {
        seen = request.url;
        final String? select = request.url.queryParameters[r'$select'];
        // Mimic Graph: bare contentId on base attachment → 400.
        if (select != null &&
            select.split(',').map((String s) => s.trim()).contains('contentId')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'error': <String, Object>{
                'code': 'BadRequest',
                'message':
                    'Parsing OData Select and Expand failed: Could not find a '
                    "property named 'contentId' on type "
                    "'microsoft.graph.attachment'.",
              },
            }),
            400,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        return http.Response(
          jsonEncode(<String, Object>{
            'value': <Map<String, Object?>>[
              <String, Object?>{
                '@odata.type': '#microsoft.graph.fileAttachment',
                'id': 'att-1',
                'name': 'photo.png',
                'contentType': 'image/png',
                'size': 12,
                'isInline': true,
                'contentId': 'cid-photo',
              },
            ],
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });

      final GraphMailProvider provider = GraphMailProvider(
        () async => 'token',
        client: client,
      );
      addTearDown(provider.dispose);

      final List<MailAttachmentMeta> items =
          await provider.listAttachments('msg-1');

      expect(seen, isNotNull);
      final String select = seen!.queryParameters[r'$select']!;
      expect(select, kGraphAttachmentListSelect);
      expect(select, contains('microsoft.graph.fileAttachment/contentId'));
      expect(
        select.split(',').map((String s) => s.trim()).contains('contentId'),
        isFalse,
      );
      expect(items, hasLength(1));
      expect(items.single.contentId, 'cid-photo');
      expect(items.single.isInline, isTrue);
    },
  );
}
