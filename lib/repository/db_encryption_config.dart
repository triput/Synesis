// ==============================================================================
// File: lib/repository/db_encryption_config.dart
// Description: Opt-in local database encryption preferences and secret storage.
// Component: Data / Security
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';

/// Minimum passphrase length enforced when enabling database encryption.
const int dbEncryptionMinPassphraseLength = 8;

/// Reads and writes the opt-in "encrypt local database" preference.
///
/// The boolean toggle lives in [SharedPreferences] (safe to store in
/// plaintext); the passphrase itself never touches prefs and is written only
/// to [FlutterSecureStorage], which is backed by the OS keystore (Windows
/// DPAPI, Android Keystore, macOS/iOS Keychain).
class DbEncryptionConfig {
  DbEncryptionConfig({SharedPreferences? prefs, FlutterSecureStorage? secureStorage})
    : _prefs = prefs,
      _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String _enabledPrefsKey = 'bytemail.db_encryption.enabled_v1';
  static const String _passphraseSecureKey =
      'bytemail:db_encryption:passphrase';

  final SharedPreferences? _prefs;
  final FlutterSecureStorage _secureStorage;

  Future<SharedPreferences> _resolvePrefs() async {
    return _prefs ?? await SharedPreferences.getInstance();
  }

  /// Whether the user has opted into local database encryption.
  ///
  /// This flag alone does not guarantee an active passphrase exists;
  /// callers that need to actually open the database should use
  /// [resolveActivePassphrase], which cross-checks both signals.
  Future<bool> isEnabled() async {
    final SharedPreferences prefs = await _resolvePrefs();
    return prefs.getBool(_enabledPrefsKey) ?? false;
  }

  /// Persists the opt-in flag.
  ///
  /// Disabling does not delete the stored passphrase by itself; callers
  /// that fully turn off encryption after a successful decrypt-to-plaintext
  /// migration must call [clearPassphrase] explicitly once the plaintext
  /// file is confirmed safe to read.
  Future<void> setEnabled(bool enabled) async {
    final SharedPreferences prefs = await _resolvePrefs();
    await prefs.setBool(_enabledPrefsKey, enabled);
  }

  /// Stores [passphrase] in the OS keystore.
  ///
  /// Throws an [ArgumentError] for a passphrase shorter than
  /// [dbEncryptionMinPassphraseLength] (after trimming) so callers cannot
  /// silently persist an unusable key.
  Future<void> setPassphrase(String passphrase) async {
    if (passphrase.trim().length < dbEncryptionMinPassphraseLength) {
      throw ArgumentError(
        'Passphrase must be at least $dbEncryptionMinPassphraseLength '
        'characters.',
      );
    }
    await _secureStorage.write(key: _passphraseSecureKey, value: passphrase);
  }

  /// Reads the raw passphrase from secure storage, or `null` if none is set.
  Future<String?> readPassphrase() =>
      _secureStorage.read(key: _passphraseSecureKey);

  /// Removes the stored passphrase.
  ///
  /// Callers must have already re-encrypted (or decrypted) the database
  /// file before calling this, or the database will become unreadable on
  /// next open.
  Future<void> clearPassphrase() =>
      _secureStorage.delete(key: _passphraseSecureKey);

  /// Returns the passphrase that should be applied when opening the local
  /// database, or `null` when encryption is disabled or misconfigured (for
  /// example the flag is set but the keystore entry was cleared
  /// externally).
  ///
  /// This method never throws: a corrupted preference state degrades to
  /// "open unencrypted" rather than locking the user out of their mailbox.
  Future<String?> resolveActivePassphrase() async {
    if (!await isEnabled()) {
      return null;
    }
    final String? passphrase = await readPassphrase();
    if (passphrase == null || passphrase.trim().isEmpty) {
      return null;
    }
    return passphrase;
  }
}

/// Pure filesystem path helpers for the local database file and the
/// temporary artifacts used while migrating between encrypted and
/// unencrypted storage.
///
/// Kept dependency-free (no Flutter, no SQLite) so they can be unit tested
/// without touching native SQLite or platform plugins.
class DbEncryptionPaths {
  const DbEncryptionPaths._();

  /// File name of the primary application database.
  static const String databaseFileName = 'bytemail.sqlite';

  /// Full path to the primary database file inside [supportDirectoryPath].
  static String databasePath(String supportDirectoryPath) =>
      p.join(supportDirectoryPath, databaseFileName);

  /// Temporary file that receives the `VACUUM INTO` copy while encrypting
  /// or decrypting [databasePath]. Never left behind after a successful
  /// migration.
  static String migrationTempPath(String databasePath) =>
      '$databasePath.migrating.tmp';

  /// Backup of the pre-migration file, kept until the migrated copy passes
  /// an integrity check.
  static String migrationBackupPath(String databasePath) =>
      '$databasePath.pre-migration.bak';
}
