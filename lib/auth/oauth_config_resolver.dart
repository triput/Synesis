// ==============================================================================
// File: lib/auth/oauth_config_resolver.dart
// Description: Resolve Graph/Google OAuth client IDs from dart-define, OS env, or local file.
// Component: Auth / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:bytemail/auth/oauth_identity_manager.dart';
import 'package:bytemail/auth/oauth_public_clients.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Merges compile-time dart-defines, OS environment, optional local JSON, and
/// shipped [OAuthPublicClients] product defaults.
///
/// Priority (first non-empty wins per field):
/// 1. `--dart-define` / `String.fromEnvironment`
/// 2. Process environment (`Platform.environment`)
/// 3. Local `oauth_local.json` (cwd, next to exe, or app support)
/// 4. [OAuthPublicClients] (ByteMail-owned public client IDs)
class OAuthConfigResolver {
  OAuthConfigResolver({
    Map<String, String>? environment,
    List<File>? localFiles,
  }) : _environment = environment ?? Platform.environment,
       _localFiles = localFiles;

  final Map<String, String> _environment;
  final List<File>? _localFiles;

  static const String localFileName = 'oauth_local.json';

  /// Load Graph + Google configs for app startup.
  static Future<({GraphAuthConfig graph, GoogleAuthConfig google})>
  loadForStartup() async {
    final OAuthConfigResolver resolver = OAuthConfigResolver(
      localFiles: await _defaultLocalFiles(),
    );
    return (graph: resolver.resolveGraph(), google: resolver.resolveGoogle());
  }

  GraphAuthConfig resolveGraph() {
    final Map<String, String> local = _readLocalMap();
    return GraphAuthConfig(
      clientId: _firstNonEmpty(<String?>[
        const String.fromEnvironment('BYTEMAIL_GRAPH_CLIENT_ID'),
        _environment['BYTEMAIL_GRAPH_CLIENT_ID'],
        local['BYTEMAIL_GRAPH_CLIENT_ID'],
        OAuthPublicClients.graphClientId,
      ]),
      tenant: _firstNonEmpty(<String?>[
        const String.fromEnvironment(
          'BYTEMAIL_GRAPH_TENANT',
          defaultValue: '',
        ),
        _environment['BYTEMAIL_GRAPH_TENANT'],
        local['BYTEMAIL_GRAPH_TENANT'],
        OAuthPublicClients.graphTenant,
        'common',
      ], fallback: 'common'),
    );
  }

  GoogleAuthConfig resolveGoogle() {
    final Map<String, String> local = _readLocalMap();
    return GoogleAuthConfig(
      clientId: _firstNonEmpty(<String?>[
        const String.fromEnvironment('BYTEMAIL_GOOGLE_CLIENT_ID'),
        _environment['BYTEMAIL_GOOGLE_CLIENT_ID'],
        local['BYTEMAIL_GOOGLE_CLIENT_ID'],
        OAuthPublicClients.googleClientId,
      ]),
      clientSecret: _firstNonEmpty(<String?>[
        const String.fromEnvironment('BYTEMAIL_GOOGLE_CLIENT_SECRET'),
        _environment['BYTEMAIL_GOOGLE_CLIENT_SECRET'],
        local['BYTEMAIL_GOOGLE_CLIENT_SECRET'],
        OAuthPublicClients.googleClientSecret,
      ]),
    );
  }

  Map<String, String> _readLocalMap() {
    final List<File> files = _localFiles ?? const <File>[];
    for (final File file in files) {
      if (!file.existsSync()) {
        continue;
      }
      try {
        final Object? decoded = jsonDecode(file.readAsStringSync());
        if (decoded is! Map<String, dynamic>) {
          continue;
        }
        final Map<String, String> out = <String, String>{};
        for (final MapEntry<String, dynamic> entry in decoded.entries) {
          final Object? value = entry.value;
          if (value is String && value.trim().isNotEmpty) {
            out[entry.key] = value.trim();
          }
        }
        if (out.isNotEmpty) {
          return out;
        }
      } on Object {
        // Skip unreadable / invalid files; try the next candidate.
      }
    }
    return const <String, String>{};
  }

  static Future<List<File>> _defaultLocalFiles() async {
    final List<File> files = <File>[
      File(p.join(Directory.current.path, localFileName)),
    ];
    try {
      final File exe = File(Platform.resolvedExecutable);
      files.add(File(p.join(exe.parent.path, localFileName)));
    } on Object {
      // Ignore — some hosts omit a useful executable path.
    }
    try {
      final Directory support = await getApplicationSupportDirectory();
      files.add(File(p.join(support.path, localFileName)));
    } on Object {
      // path_provider can fail in tests / early bootstrap.
    }
    return files;
  }

  static String _firstNonEmpty(
    List<String?> candidates, {
    String fallback = '',
  }) {
    for (final String? value in candidates) {
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return fallback;
  }
}
