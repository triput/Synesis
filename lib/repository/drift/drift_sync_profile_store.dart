// ==============================================================================
// File: lib/repository/drift/drift_sync_profile_store.dart
// Description: Drift persistence for sync profiles and account policy resolution
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart' as domain;
import 'package:bytemail/repository/database.dart' hide FocusRule;
import 'package:bytemail/repository/drift/drift_account_mapper.dart';
import 'package:drift/drift.dart';

class DriftSyncProfileStore {
  DriftSyncProfileStore(
    this._database, {
    required void Function() notify,
  }) : _notify = notify;

  final ByteMailDatabase _database;
  final void Function() _notify;

  Future<List<domain.SyncProfile>> listSyncProfiles() async {
    final List<SyncProfile> rows =
        await _database.select(_database.syncProfiles).get();
    return rows.map(_fromRow).toList(growable: false);
  }

  Future<domain.SyncProfile?> getSyncProfile(String id) async {
    final SyncProfile? row = await (_database.select(_database.syncProfiles)
          ..where((SyncProfiles table) => table.id.equals(id)))
        .getSingleOrNull();
    return row == null ? null : _fromRow(row);
  }

  Future<domain.SyncProfile?> getDefaultSyncProfile() async {
    final SyncProfile? row = await (_database.select(_database.syncProfiles)
          ..where((SyncProfiles table) => table.isDefault.equals(true))
          ..limit(1))
        .getSingleOrNull();
    if (row != null) {
      return _fromRow(row);
    }
    return getSyncProfile('default');
  }

  Future<void> upsertSyncProfile(domain.SyncProfile profile) async {
    if (profile.isDefault) {
      await (_database.update(_database.syncProfiles)).write(
        const SyncProfilesCompanion(isDefault: Value<bool>(false)),
      );
    }
    await _database
        .into(_database.syncProfiles)
        .insertOnConflictUpdate(
          SyncProfilesCompanion.insert(
            id: profile.id,
            name: profile.name,
            retentionDays: profile.retentionDays,
            folderScopeJson: Value<String?>(profile.encodeFolderScopeJson()),
            bodyPolicy: Value<String>(profile.bodyPolicy.dbValue),
            attachmentMaxMb: Value<int>(profile.attachmentMaxMb),
            isDefault: Value<bool>(profile.isDefault),
          ),
        );
    _notify();
  }

  /// Merges account override → profile retention → [fallbackRetentionDays].
  Future<domain.ResolvedSyncPolicy> resolvePolicy(
    String accountId, {
    int fallbackRetentionDays = 180,
  }) async {
    final Account? accountRow = await (_database.select(_database.accounts)
          ..where((Accounts table) => table.id.equals(accountId)))
        .getSingleOrNull();
    final MailAccount? account =
        accountRow == null ? null : accountFromRow(accountRow);

    domain.SyncProfile? profile;
    final String? profileId = account?.syncProfileId;
    if (profileId != null && profileId.isNotEmpty) {
      profile = await getSyncProfile(profileId);
    }
    profile ??= await getDefaultSyncProfile();
    profile ??= domain.SyncProfile(
      id: 'default',
      name: 'Default',
      retentionDays: fallbackRetentionDays,
      bodyPolicy: domain.BodyFetchPolicy.onOpen,
      attachmentMaxMb: 25,
      isDefault: true,
    );

    final int? overrideDays = account?.retentionDaysOverride;
    final int retentionDays = overrideDays ??
        (profile.retentionDays > 0
            ? profile.retentionDays
            : fallbackRetentionDays);

    return domain.ResolvedSyncPolicy(
      accountId: accountId,
      profileId: profile.id,
      retentionDays: retentionDays,
      folderScope: profile.folderScope,
      bodyPolicy: profile.bodyPolicy,
      attachmentMaxMb: profile.attachmentMaxMb,
    );
  }

  domain.SyncProfile _fromRow(SyncProfile row) {
    return domain.SyncProfile(
      id: row.id,
      name: row.name,
      retentionDays: row.retentionDays,
      folderScope: domain.SyncProfile.parseFolderScopeJson(row.folderScopeJson),
      bodyPolicy: domain.BodyFetchPolicyDb.fromDb(row.bodyPolicy),
      attachmentMaxMb: row.attachmentMaxMb,
      isDefault: row.isDefault,
    );
  }
}
