// ==============================================================================
// File: lib/auth/secure_credential_store.dart
// Description: Secure credential persistence keyed by account credential refs.
// Component: Auth / Security
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Stores provider secrets outside the SQLite mailbox database.
class SecureCredentialStore {
  SecureCredentialStore({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  Future<void> writeSecret({
    required String credentialsRef,
    required String name,
    required String value,
  }) =>
      _storage.write(
        key: _key(credentialsRef, name),
        value: value,
      );

  Future<String?> readSecret({
    required String credentialsRef,
    required String name,
  }) =>
      _storage.read(key: _key(credentialsRef, name));

  Future<void> deleteSecret({
    required String credentialsRef,
    required String name,
  }) =>
      _storage.delete(key: _key(credentialsRef, name));

  Future<void> deleteCredentials(String credentialsRef) async {
    final Map<String, String> values = await _storage.readAll();
    final String prefix = 'bytemail:$credentialsRef:';
    await Future.wait(
      values.keys
          .where((String key) => key.startsWith(prefix))
          .map((String key) => _storage.delete(key: key)),
    );
  }

  String _key(String credentialsRef, String name) {
    if (credentialsRef.trim().isEmpty || name.trim().isEmpty) {
      throw ArgumentError('Credential references and names must not be empty.');
    }
    return 'bytemail:$credentialsRef:$name';
  }
}
