// ==============================================================================
// File: lib/repository/db_encryption_migrator.dart
// Description: Plaintext <-> SQLite3MultipleCiphers in-place DB migration.
// Component: Data / Security / Sync
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:io';
import 'dart:isolate';

import 'package:sqlite3/sqlite3.dart';

import 'package:bytemail/repository/db_encryption_config.dart';

/// Raised when a migration cannot proceed safely, e.g. the encrypted copy
/// fails an integrity check or a wrong source passphrase was supplied.
///
/// ByteMail never leaves the mailbox in a half-migrated state: on failure
/// the original file is restored from its backup before this is thrown.
class DbEncryptionMigrationException implements Exception {
  DbEncryptionMigrationException(this.message);

  final String message;

  @override
  String toString() => 'DbEncryptionMigrationException: $message';
}

/// Migrates the local mailbox database between plaintext and
/// SQLite3MultipleCiphers-encrypted storage using SQLite's own
/// `VACUUM INTO` + `PRAGMA rekey` recipe (as recommended by Drift's
/// encryption docs).
///
/// The actual file copy/rekey work runs on a background isolate via
/// [Isolate.run] so a large mailbox does not block the UI thread; only
/// plain, isolate-safe [String] values cross the isolate boundary.
class DbEncryptionMigrator {
  const DbEncryptionMigrator();

  /// Encrypts the database at [databasePath] in place using [passphrase].
  ///
  /// No-ops if the file does not exist yet — fresh installs that enable
  /// encryption before their first sync open encrypted from the very first
  /// write via `ByteMailDatabase`'s connection factory, so there is nothing
  /// to migrate.
  Future<void> encryptInPlace({
    required String databasePath,
    required String passphrase,
  }) async {
    _requireValidPassphrase(passphrase);
    if (!await File(databasePath).exists()) {
      return;
    }
    await Isolate.run(
      () => _rekeyOnBackgroundIsolate(
        databasePath: databasePath,
        fromPassphrase: null,
        toPassphrase: passphrase,
      ),
    );
  }

  /// Decrypts the database at [databasePath] in place back to plaintext,
  /// given the currently active [passphrase].
  ///
  /// Kept for symmetry and as a defensive recovery path if a user turns
  /// encryption back off; not currently wired to a UI action beyond the
  /// settings sheet's disable flow.
  Future<void> decryptInPlace({
    required String databasePath,
    required String passphrase,
  }) async {
    if (!await File(databasePath).exists()) {
      return;
    }
    await Isolate.run(
      () => _rekeyOnBackgroundIsolate(
        databasePath: databasePath,
        fromPassphrase: passphrase,
        toPassphrase: null,
      ),
    );
  }

  void _requireValidPassphrase(String passphrase) {
    if (passphrase.trim().length < dbEncryptionMinPassphraseLength) {
      throw ArgumentError(
        'Passphrase must be at least $dbEncryptionMinPassphraseLength '
        'characters.',
      );
    }
  }
}

/// Runs entirely inside a background isolate spawned by [Isolate.run].
///
/// All native SQLite handles are opened, used, and disposed within this
/// single synchronous function — none of them ever cross the isolate
/// boundary.
void _rekeyOnBackgroundIsolate({
  required String databasePath,
  required String? fromPassphrase,
  required String? toPassphrase,
}) {
  final String tempPath = DbEncryptionPaths.migrationTempPath(databasePath);
  final String backupPath = DbEncryptionPaths.migrationBackupPath(
    databasePath,
  );
  final File original = File(databasePath);
  final File temp = File(tempPath);
  final File backup = File(backupPath);

  if (temp.existsSync()) {
    temp.deleteSync();
  }
  if (backup.existsSync()) {
    backup.deleteSync();
  }

  final Database source = sqlite3.open(databasePath);
  try {
    if (fromPassphrase != null) {
      source.execute('PRAGMA key = ${_sqlString(fromPassphrase)};');
    }
    try {
      // Fail fast on a wrong/missing source key rather than vacuuming
      // garbage into the temp file.
      source.select('SELECT count(*) FROM sqlite_master;');
    } on SqliteException catch (error) {
      throw DbEncryptionMigrationException(
        'Could not read source database with the supplied passphrase: '
        '$error',
      );
    }
    source.execute('VACUUM INTO ${_sqlString(tempPath)};');
  } finally {
    source.close();
  }

  try {
    final Database target = sqlite3.open(tempPath);
    try {
      if (fromPassphrase != null) {
        // `VACUUM INTO` run from an already-keyed connection writes the
        // temp copy using that same active cipher, so the fresh connection
        // above must be unlocked with the source key before it can be
        // rekeyed (either to a new passphrase or back to plaintext).
        target.execute('PRAGMA key = ${_sqlString(fromPassphrase)};');
      }
      if (toPassphrase != null) {
        target.execute('PRAGMA rekey = ${_sqlString(toPassphrase)};');
      } else if (fromPassphrase != null) {
        // Decrypting to plaintext: rekeying to an empty string removes the
        // cipher while keeping the file readable as plain SQLite.
        target.execute("PRAGMA rekey = '';");
      }
      final ResultSet check = target.select('PRAGMA integrity_check;');
      final String verdict = check.isEmpty
          ? 'no result'
          : check.first.values.first.toString();
      if (verdict.toLowerCase() != 'ok') {
        throw DbEncryptionMigrationException(
          'Post-migration integrity check failed: $verdict',
        );
      }
    } finally {
      target.close();
    }
  } catch (error) {
    if (temp.existsSync()) {
      temp.deleteSync();
    }
    rethrow;
  }

  original.renameSync(backupPath);
  try {
    temp.renameSync(databasePath);
  } catch (_) {
    // Roll back: restore the original file so the app can still open it.
    backup.renameSync(databasePath);
    rethrow;
  }
  backup.deleteSync();
}

String _sqlString(String value) => "'${value.replaceAll("'", "''")}'";
