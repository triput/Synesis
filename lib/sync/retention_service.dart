// ==============================================================================
// File: lib/sync/retention_service.dart
// Description: Retention cleanup execution and durable job enqueueing.
// Component: Sync
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/repository/mail_repository.dart';

class RetentionService {
  RetentionService(this._repository);

  static const String cleanupJobType = 'retention_cleanup';

  final MailRepository _repository;

  Future<int> run({required int days, String? accountId}) {
    if (days < 0) {
      throw ArgumentError.value(days, 'days', 'Must be non-negative.');
    }
    return _repository.applyRetention(
      retentionDays: days,
      accountId: accountId,
    );
  }

  /// Runs retention for [accountId] using the resolved sync policy.
  Future<int> runForAccount(
    String accountId, {
    int fallbackRetentionDays = 180,
  }) async {
    final ResolvedSyncPolicy policy = await _repository.resolvePolicy(
      accountId,
      fallbackRetentionDays: fallbackRetentionDays,
    );
    return run(days: policy.retentionDays, accountId: accountId);
  }

  Future<void> enqueue({required String accountId, required int days}) {
    if (days < 0) {
      throw ArgumentError.value(days, 'days', 'Must be non-negative.');
    }
    return _repository.enqueueSyncJob(
      accountId: accountId,
      type: cleanupJobType,
      payloadJson: jsonEncode(<String, int>{'days': days}),
    );
  }

  /// Updates the default sync profile retention to match the device dial and
  /// enqueues per-account cleanup jobs with each account's resolved days.
  Future<void> applyDeviceRetentionDial({
    required int days,
  }) async {
    if (days < 0) {
      throw ArgumentError.value(days, 'days', 'Must be non-negative.');
    }
    final SyncProfile? defaultProfile =
        await _repository.getDefaultSyncProfile();
    if (defaultProfile != null) {
      await _repository.upsertSyncProfile(
        defaultProfile.copyWith(retentionDays: days),
      );
    } else {
      await _repository.upsertSyncProfile(
        SyncProfile(
          id: 'default',
          name: 'Default',
          retentionDays: days,
          bodyPolicy: BodyFetchPolicy.onOpen,
          attachmentMaxMb: 25,
          isDefault: true,
        ),
      );
    }

    final List<MailAccount> accounts = await _repository.listAccounts();
    for (final MailAccount account in accounts) {
      final ResolvedSyncPolicy policy = await _repository.resolvePolicy(
        account.id,
        fallbackRetentionDays: days,
      );
      await enqueue(accountId: account.id, days: policy.retentionDays);
    }
  }
}
