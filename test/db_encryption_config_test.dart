// ==============================================================================
// File: test/db_encryption_config_test.dart
// Description: DbEncryptionConfig prefs/secret persistence and path helpers.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/repository/db_encryption_config.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the OS keystore so these tests never touch the
/// real `flutter_secure_storage` platform channel (mirrors the
/// `_MemoryCredentialStore` pattern used for `SecureCredentialStore`).
class _FakeDbEncryptionConfig extends DbEncryptionConfig {
  _FakeDbEncryptionConfig({required SharedPreferences prefs})
    : super(prefs: prefs);

  String? storedPassphrase;

  @override
  Future<void> setPassphrase(String passphrase) async {
    if (passphrase.trim().length < dbEncryptionMinPassphraseLength) {
      throw ArgumentError(
        'Passphrase must be at least $dbEncryptionMinPassphraseLength '
        'characters.',
      );
    }
    storedPassphrase = passphrase;
  }

  @override
  Future<String?> readPassphrase() async => storedPassphrase;

  @override
  Future<void> clearPassphrase() async => storedPassphrase = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DbEncryptionConfig prefs flag', () {
    test('defaults to disabled', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final _FakeDbEncryptionConfig config = _FakeDbEncryptionConfig(
        prefs: prefs,
      );
      expect(await config.isEnabled(), isFalse);
    });

    test('persists enabled flag across instances', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final _FakeDbEncryptionConfig config = _FakeDbEncryptionConfig(
        prefs: prefs,
      );

      await config.setEnabled(true);
      expect(await config.isEnabled(), isTrue);

      final _FakeDbEncryptionConfig reloaded = _FakeDbEncryptionConfig(
        prefs: prefs,
      );
      expect(await reloaded.isEnabled(), isTrue);
    });

    test('does not store the passphrase in SharedPreferences', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final _FakeDbEncryptionConfig config = _FakeDbEncryptionConfig(
        prefs: prefs,
      );

      await config.setEnabled(true);
      await config.setPassphrase('super-secret-passphrase');

      final Set<String> keys = prefs.getKeys();
      for (final String key in keys) {
        final Object? value = prefs.get(key);
        expect(
          value.toString(),
          isNot(contains('super-secret-passphrase')),
          reason: 'Passphrase leaked into plaintext SharedPreferences key '
              '"$key"',
        );
      }
    });
  });

  group('DbEncryptionConfig passphrase validation', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    test('refuses an empty passphrase', () async {
      final _FakeDbEncryptionConfig config = _FakeDbEncryptionConfig(
        prefs: prefs,
      );
      expect(
        () => config.setPassphrase(''),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refuses a whitespace-only passphrase', () async {
      final _FakeDbEncryptionConfig config = _FakeDbEncryptionConfig(
        prefs: prefs,
      );
      expect(
        () => config.setPassphrase('       '),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('refuses a passphrase shorter than the minimum length', () async {
      final _FakeDbEncryptionConfig config = _FakeDbEncryptionConfig(
        prefs: prefs,
      );
      expect(
        () => config.setPassphrase('short1'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts a passphrase at the minimum length', () async {
      final _FakeDbEncryptionConfig config = _FakeDbEncryptionConfig(
        prefs: prefs,
      );
      final String passphrase = 'a' * dbEncryptionMinPassphraseLength;
      await config.setPassphrase(passphrase);
      expect(await config.readPassphrase(), passphrase);
    });
  });

  group('DbEncryptionConfig.resolveActivePassphrase', () {
    late SharedPreferences prefs;

    setUp(() async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      prefs = await SharedPreferences.getInstance();
    });

    test('returns null when the flag is disabled', () async {
      final _FakeDbEncryptionConfig config = _FakeDbEncryptionConfig(
        prefs: prefs,
      )..storedPassphrase = 'irrelevant-because-disabled';
      expect(await config.resolveActivePassphrase(), isNull);
    });

    test('returns null when enabled but no passphrase is stored', () async {
      final _FakeDbEncryptionConfig config = _FakeDbEncryptionConfig(
        prefs: prefs,
      );
      await config.setEnabled(true);
      expect(await config.resolveActivePassphrase(), isNull);
    });

    test('returns the passphrase when enabled and present', () async {
      final _FakeDbEncryptionConfig config = _FakeDbEncryptionConfig(
        prefs: prefs,
      );
      await config.setEnabled(true);
      await config.setPassphrase('correct-horse-battery');
      expect(
        await config.resolveActivePassphrase(),
        'correct-horse-battery',
      );
    });

    test('degrades to unencrypted if the keystore entry is cleared '
        'externally while the flag stays on', () async {
      final _FakeDbEncryptionConfig config = _FakeDbEncryptionConfig(
        prefs: prefs,
      );
      await config.setEnabled(true);
      await config.setPassphrase('correct-horse-battery');
      await config.clearPassphrase();
      expect(await config.resolveActivePassphrase(), isNull);
    });
  });

  group('DbEncryptionPaths', () {
    test('databasePath joins the support directory and file name', () {
      expect(
        DbEncryptionPaths.databasePath(p.join('support', 'dir')),
        p.join('support', 'dir', 'bytemail.sqlite'),
      );
    });

    test('migrationTempPath is distinct from the source path', () {
      final String dbPath = p.join('support', 'dir', 'bytemail.sqlite');
      final String tempPath = DbEncryptionPaths.migrationTempPath(dbPath);
      expect(tempPath, isNot(dbPath));
      expect(tempPath, contains(dbPath));
      expect(tempPath, endsWith('.migrating.tmp'));
    });

    test('migrationBackupPath is distinct from the source and temp paths', () {
      final String dbPath = p.join('support', 'dir', 'bytemail.sqlite');
      final String backupPath = DbEncryptionPaths.migrationBackupPath(dbPath);
      final String tempPath = DbEncryptionPaths.migrationTempPath(dbPath);
      expect(backupPath, isNot(dbPath));
      expect(backupPath, isNot(tempPath));
      expect(backupPath, endsWith('.pre-migration.bak'));
    });
  });
}
