// ==============================================================================
// File: test/graph_mail_folder_list_test.dart
// Description: Graph listFolders pagination and resilient well-known lookups.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:bytemail/protocol/graph_mail_provider.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('listFolders follows @odata.nextLink and keeps folders when roles fail',
      () async {
    int pageRequests = 0;
    final http.Client client = MockClient((http.Request request) async {
      final String path = request.url.path;
      if (path.endsWith('/me/mailFolders/inbox') ||
          path.contains('/me/mailFolders/deleteditems') ||
          path.contains('/me/mailFolders/junkemail') ||
          path.contains('/me/mailFolders/archive') ||
          path.contains('/me/mailFolders/sentitems') ||
          path.contains('/me/mailFolders/drafts')) {
        // Simulate timeouts / missing well-known folders.
        throw TimeoutException('probe timeout');
      }
      if (path.endsWith('/me/mailFolders') &&
          !request.url.queryParameters.containsKey(r'$skiptoken')) {
        pageRequests += 1;
        return http.Response(
          jsonEncode(<String, Object>{
            'value': <Map<String, Object>>[
              <String, Object>{
                'id': 'folder-1',
                'displayName': 'Inbox',
                'parentFolderId': '',
                'unreadItemCount': 1,
                'totalItemCount': 2,
              },
            ],
            r'@odata.nextLink':
                'https://graph.microsoft.com/v1.0/me/mailFolders?\$skiptoken=page2',
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.url.queryParameters[r'$skiptoken'] == 'page2') {
        pageRequests += 1;
        return http.Response(
          jsonEncode(<String, Object>{
            'value': <Map<String, Object>>[
              <String, Object>{
                'id': 'folder-2',
                'displayName': 'Projects',
                'parentFolderId': 'folder-1',
                'unreadItemCount': 0,
                'totalItemCount': 4,
              },
            ],
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      return http.Response('unexpected ${request.url}', 500);
    });

    final GraphMailProvider provider = GraphMailProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    final List<RemoteFolder> folders = await provider.listFolders();
    expect(pageRequests, 2);
    expect(folders.length, 2);
    expect(folders.map((RemoteFolder f) => f.name), containsAll(<String>['Inbox', 'Projects']));
  });

  test('createFolder posts displayName and returns RemoteFolder', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(request.method, 'POST');
      expect(request.url.path.endsWith('/me/mailFolders'), isTrue);
      final Object? body = jsonDecode(request.body);
      expect(body, isA<Map<Object?, Object?>>());
      expect((body as Map<Object?, Object?>)['displayName'], 'Trash');
      return http.Response(
        jsonEncode(<String, Object>{
          'id': 'new-trash',
          'displayName': 'Trash',
          'parentFolderId': 'root',
          'unreadItemCount': 0,
          'totalItemCount': 0,
        }),
        201,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GraphMailProvider provider = GraphMailProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    final RemoteFolder folder = await provider.createFolder(
      displayName: 'Trash',
      role: 'trash',
    );
    expect(folder.providerId, 'new-trash');
    expect(folder.name, 'Trash');
    expect(folder.role, 'trash');
  });
}
