// ==============================================================================
// File: test/db_encryption_migrator_test.dart
// Description: Native SQLite3MultipleCiphers encrypt/decrypt round-trip tests.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================
//
// These tests exercise the real native SQLite build (enabled via
// `pubspec.yaml`'s `hooks.user_defines.sqlite3.source: sqlite3mc`). If the
// encrypted cipher build is unavailable on a given CI/native toolchain,
// tests skip themselves via [_cipherAvailable] rather than failing the
// whole suite — see docs/W7_SQLCIPHER_SPIKE.md.

import 'dart:io';

import 'package:bytemail/repository/db_encryption_config.dart';
import 'package:bytemail/repository/db_encryption_migrator.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

Future<bool> _cipherAvailable() async {
  final Directory dir = await Directory.systemTemp.createTemp(
    'cipher_probe',
  );
  try {
    final Database db = sqlite3.open(p.join(dir.path, 'probe.sqlite'));
    try {
      final ResultSet rows = db.select('PRAGMA cipher;');
      return rows.isNotEmpty;
    } finally {
      db.close();
    }
  } catch (_) {
    return false;
  } finally {
    await dir.delete(recursive: true);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DbEncryptionMigrator', () {
    late bool cipherAvailable;
    late Directory tempDir;
    late String dbPath;

    setUpAll(() async {
      cipherAvailable = await _cipherAvailable();
    });

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('db_migrator_test');
      dbPath = DbEncryptionPaths.databasePath(tempDir.path);
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('encryptInPlace refuses a short passphrase before touching disk', () {
      expect(
        () => const DbEncryptionMigrator().encryptInPlace(
          databasePath: dbPath,
          passphrase: 'short',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('encryptInPlace no-ops when the database file does not exist', () async {
      await const DbEncryptionMigrator().encryptInPlace(
        databasePath: dbPath,
        passphrase: 'a-long-enough-passphrase',
      );
      expect(await File(dbPath).exists(), isFalse);
    });

    test(
      'encrypts an existing plaintext database in place; wrong key fails, '
      'right key reads the original rows',
      () async {
        if (!cipherAvailable) {
          markTestSkipped('sqlite3mc cipher build unavailable on this host');
          return;
        }
        final Database plain = sqlite3.open(dbPath);
        plain.execute('CREATE TABLE t (a TEXT);');
        plain.execute("INSERT INTO t VALUES ('hello-plain');");
        plain.close();

        await const DbEncryptionMigrator().encryptInPlace(
          databasePath: dbPath,
          passphrase: 'correct-horse-battery-staple',
        );

        // No leftover temp/backup artifacts after a clean run.
        expect(
          await File(DbEncryptionPaths.migrationTempPath(dbPath)).exists(),
          isFalse,
        );
        expect(
          await File(DbEncryptionPaths.migrationBackupPath(dbPath)).exists(),
          isFalse,
        );

        final Database wrongKey = sqlite3.open(dbPath);
        wrongKey.execute("PRAGMA key = 'wrong-passphrase';");
        expect(
          () => wrongKey.select('SELECT a FROM t'),
          throwsA(isA<SqliteException>()),
        );
        wrongKey.close();

        final Database rightKey = sqlite3.open(dbPath);
        rightKey.execute("PRAGMA key = 'correct-horse-battery-staple';");
        final ResultSet rows = rightKey.select('SELECT a FROM t');
        expect(rows.single['a'], 'hello-plain');
        rightKey.close();
      },
    );

    test(
      'encrypt then decrypt round-trips back to a plainly readable database',
      () async {
        if (!cipherAvailable) {
          markTestSkipped('sqlite3mc cipher build unavailable on this host');
          return;
        }
        final Database plain = sqlite3.open(dbPath);
        plain.execute('CREATE TABLE t (a TEXT);');
        plain.execute("INSERT INTO t VALUES ('round-trip');");
        plain.close();

        const String passphrase = 'round-trip-passphrase';
        await const DbEncryptionMigrator().encryptInPlace(
          databasePath: dbPath,
          passphrase: passphrase,
        );
        await const DbEncryptionMigrator().decryptInPlace(
          databasePath: dbPath,
          passphrase: passphrase,
        );

        final Database reopened = sqlite3.open(dbPath);
        final ResultSet rows = reopened.select('SELECT a FROM t');
        expect(rows.single['a'], 'round-trip');
        reopened.close();
      },
    );
  });
}
