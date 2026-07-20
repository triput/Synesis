// ==============================================================================
// File: test/oauth_config_resolver_test.dart
// Description: Unit tests for OAuth client ID resolution priority.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:io';

import 'package:bytemail/auth/oauth_config_resolver.dart';
import 'package:bytemail/auth/oauth_public_clients.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bytemail_oauth_');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('prefers OS environment over local file', () {
    final File local = File('${tempDir.path}/oauth_local.json')
      ..writeAsStringSync(
        '{"BYTEMAIL_GRAPH_CLIENT_ID":"from-file",'
        '"BYTEMAIL_GOOGLE_CLIENT_ID":"google-from-file"}',
      );
    final OAuthConfigResolver resolver = OAuthConfigResolver(
      environment: <String, String>{
        'BYTEMAIL_GRAPH_CLIENT_ID': 'from-env',
        'BYTEMAIL_GOOGLE_CLIENT_ID': 'google-from-env',
      },
      localFiles: <File>[local],
    );
    expect(resolver.resolveGraph().clientId, 'from-env');
    expect(resolver.resolveGoogle().clientId, 'google-from-env');
  });

  test('falls back to oauth_local.json when env empty', () {
    final File local = File('${tempDir.path}/oauth_local.json')
      ..writeAsStringSync(
        '{"BYTEMAIL_GRAPH_CLIENT_ID":"file-graph",'
        '"BYTEMAIL_GRAPH_TENANT":"contoso",'
        '"BYTEMAIL_GOOGLE_CLIENT_ID":"file-google.apps.googleusercontent.com"}',
      );
    final OAuthConfigResolver resolver = OAuthConfigResolver(
      environment: const <String, String>{},
      localFiles: <File>[local],
    );
    expect(resolver.resolveGraph().isConfigured, isTrue);
    expect(resolver.resolveGraph().clientId, 'file-graph');
    expect(resolver.resolveGraph().tenant, 'contoso');
    expect(resolver.resolveGoogle().clientId, 'file-google.apps.googleusercontent.com');
  });

  test('falls back to shipped public clients when env and file empty', () {
    final OAuthConfigResolver resolver = OAuthConfigResolver(
      environment: const <String, String>{},
      localFiles: const <File>[],
    );
    // Placeholders may be empty until operator pastes product IDs; when set,
    // they must surface as configured without env/file.
    final bool graphShipped = OAuthPublicClients.graphClientId.trim().isNotEmpty;
    final bool googleShipped =
        OAuthPublicClients.googleClientId.trim().isNotEmpty;
    expect(resolver.resolveGraph().isConfigured, graphShipped);
    expect(resolver.resolveGoogle().isConfigured, googleShipped);
    if (graphShipped) {
      expect(
        resolver.resolveGraph().clientId,
        OAuthPublicClients.graphClientId,
      );
    }
    if (googleShipped) {
      expect(
        resolver.resolveGoogle().clientId,
        OAuthPublicClients.googleClientId,
      );
    }
  });

  test('local file overrides shipped public clients', () {
    final File local = File('${tempDir.path}/oauth_local.json')
      ..writeAsStringSync(
        '{"BYTEMAIL_GRAPH_CLIENT_ID":"override-graph",'
        '"BYTEMAIL_GOOGLE_CLIENT_ID":"override-google"}',
      );
    final OAuthConfigResolver resolver = OAuthConfigResolver(
      environment: const <String, String>{},
      localFiles: <File>[local],
    );
    expect(resolver.resolveGraph().clientId, 'override-graph');
    expect(resolver.resolveGoogle().clientId, 'override-google');
  });
}
