// ==============================================================================
// File: test/graph_mail_provider_auth_retry_test.dart
// Description: GraphMailProvider retries once after HTTP 401 with token refresh.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-16
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/protocol/graph_mail_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('retries once after 401 when onUnauthorized is provided', () async {
    int requestCount = 0;
    int unauthorizedCalls = 0;
    String token = 'stale';

    final http.Client client = MockClient((http.Request request) async {
      requestCount += 1;
      final String? auth = request.headers['Authorization'];
      if (auth == 'Bearer stale') {
        return http.Response('{"error":{"message":"Unauthorized"}}', 401);
      }
      return http.Response(
        jsonEncode(<String, Object>{
          'value': <Map<String, Object>>[
            <String, Object>{
              'id': 'folder-1',
              'displayName': 'Inbox',
              'parentFolderId': '',
              'unreadItemCount': 0,
              'totalItemCount': 0,
            },
          ],
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GraphMailProvider provider = GraphMailProvider(
      () async => token,
      client: client,
      onUnauthorized: () async {
        unauthorizedCalls += 1;
        token = 'fresh';
      },
    );
    addTearDown(provider.dispose);

    final folders = await provider.listFolders();
    expect(folders, isNotEmpty);
    expect(unauthorizedCalls, 1);
    // mailFolders + well-known folder probes may add GETs; first call must 401.
    expect(requestCount, greaterThanOrEqualTo(2));
  });

  test('throws GraphAuthException on 401 without onUnauthorized', () async {
    final http.Client client = MockClient(
      (http.Request request) async => http.Response('Unauthorized', 401),
    );
    final GraphMailProvider provider = GraphMailProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    await expectLater(
      provider.listFolders(),
      throwsA(isA<GraphAuthException>()),
    );
  });
}
