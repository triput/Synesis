// ==============================================================================
// File: test/graph_mail_delta_test.dart
// Description: Graph listDelta merge, removed ids, and deltaLink persistence.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/protocol/graph_mail_provider.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('listDelta merges pages, removed ids, and returns deltaLink', () async {
    int page = 0;
    final http.Client client = MockClient((http.Request request) async {
      page += 1;
      if (page == 1) {
        expect(request.url.path.contains('/messages/delta'), isTrue);
        return http.Response(
          jsonEncode(<String, Object>{
            'value': <Map<String, Object>>[
              <String, Object>{
                'id': 'msg-1',
                'subject': 'Hello',
                'from': <String, Object>{
                  'emailAddress': <String, String>{
                    'address': 'a@example.com',
                    'name': 'A',
                  },
                },
                'receivedDateTime': '2026-07-17T12:00:00Z',
                'bodyPreview': 'hi',
                'isRead': false,
                'hasAttachments': false,
              },
              <String, Object>{
                'id': 'msg-gone',
                r'@removed': <String, String>{'reason': 'deleted'},
              },
            ],
            r'@odata.nextLink':
                'https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messages/delta?\$skiptoken=p2',
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      expect(request.url.queryParameters[r'$skiptoken'], 'p2');
      return http.Response(
        jsonEncode(<String, Object>{
          'value': <Map<String, Object>>[
            <String, Object>{
              'id': 'msg-2',
              'subject': 'World',
              'from': <String, Object>{
                'emailAddress': <String, String>{
                  'address': 'b@example.com',
                },
              },
              'receivedDateTime': '2026-07-17T13:00:00Z',
              'isRead': true,
              'hasAttachments': true,
            },
          ],
          r'@odata.deltaLink':
              'https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messages/delta?\$deltatokens=abc',
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

    final GraphDeltaResult result = await provider.listDelta('inbox');
    expect(result.changed.map((RemoteMessageHeader m) => m.providerId),
        <String>['msg-1', 'msg-2']);
    expect(result.removedProviderIds, <String>['msg-gone']);
    expect(result.deltaLink, contains('deltatokens=abc'));
  });

  test('listDelta resumes from absolute deltaLink URL', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(
        request.url.toString(),
        'https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messages/delta?\$deltatokens=resume',
      );
      return http.Response(
        jsonEncode(<String, Object>{
          'value': <Object>[],
          r'@odata.deltaLink':
              'https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messages/delta?\$deltatokens=next',
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

    final GraphDeltaResult result = await provider.listDelta(
      'inbox',
      deltaLink:
          'https://graph.microsoft.com/v1.0/me/mailFolders/inbox/messages/delta?\$deltatokens=resume',
    );
    expect(result.changed, isEmpty);
    expect(result.removedProviderIds, isEmpty);
    expect(result.deltaLink, contains('deltatokens=next'));
  });

  test('listDelta surfaces 410 for expired tokens', () async {
    final http.Client client = MockClient((http.Request request) async {
      return http.Response(
        jsonEncode(<String, Object>{
          'error': <String, String>{
            'code': 'syncStateNotFound',
            'message': 'Delta token expired',
          },
        }),
        410,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GraphMailProvider provider = GraphMailProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    expect(
      () => provider.listDelta(
        'inbox',
        deltaLink: 'https://graph.microsoft.com/v1.0/delta?token=old',
      ),
      throwsA(
        isA<ProtocolException>().having(
          (ProtocolException e) => e.statusCode,
          'statusCode',
          410,
        ),
      ),
    );
  });
}
