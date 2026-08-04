// ==============================================================================
// File: lib/sync/pim_copy_service.dart
// Description: Local-first event/contact copy + enqueue for Wave 6 sync push.
// Component: Sync
// Version: 1.0 (Gold Master)
// Created: 2026-08-04
// Last Update: 2026-08-04
// ==============================================================================

import 'dart:convert';

import 'package:synesis/domain/pim.dart';
import 'package:synesis/protocol/dav_pim_provider.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/pim_sync_jobs.dart';
import 'package:synesis/sync/sync_engine.dart';

/// Result of a local-first copy operation (Wave 6).
class PimCopyResult<T> {
  const PimCopyResult({
    required this.entity,
    required this.remotePushEnqueued,
  });

  /// Newly created Drift row under the target collection.
  final T entity;

  /// `true` when an `events_copy` / `contacts_copy` job was enqueued for
  /// Graph/Google. `false` for DAV targets (local-only until Wave 6b).
  final bool remotePushEnqueued;
}

/// Duplicates PIM rows locally, then enqueues remote create jobs when the
/// target account supports Graph/Google write-back.
///
/// Cubits / DnD (Jules P2–P3) should call this — never hit the network from
/// widgets. Kick [SyncEngine] separately (or rely on the existing kick loop).
class PimCopyService {
  PimCopyService({
    required DriftPimStore pimStore,
    required MailRepository repository,
    required GraphPimResolver resolvePim,
  }) : _pimStore = pimStore,
       _repository = repository,
       _resolvePim = resolvePim;

  final DriftPimStore _pimStore;
  final MailRepository _repository;
  final GraphPimResolver _resolvePim;

  /// Copies [sourceEventId] onto [targetCalendarId] under [targetAccountId].
  Future<PimCopyResult<CalendarEvent>> copyEventToCalendar({
    required String sourceEventId,
    required String targetAccountId,
    required String targetCalendarId,
  }) async {
    final CalendarEvent duplicated = await _pimStore.duplicateEventToCalendar(
      sourceEventId: sourceEventId,
      targetAccountId: targetAccountId,
      targetCalendarId: targetCalendarId,
    );
    final Calendar? targetCalendar = await _pimStore.getCalendar(
      targetCalendarId,
    );
    if (targetCalendar == null) {
      throw StateError(
        'copyEventToCalendar: target calendar "$targetCalendarId" missing '
        'after duplicate.',
      );
    }
    final bool enqueue = await _shouldEnqueueRemotePush(targetAccountId);
    if (!enqueue) {
      return PimCopyResult<CalendarEvent>(
        entity: duplicated,
        remotePushEnqueued: false,
      );
    }
    await _repository.enqueueSyncJob(
      accountId: targetAccountId,
      type: PimSyncJobs.eventsCopy,
      payloadJson: jsonEncode(<String, String>{
        'localEventId': duplicated.id,
        'targetCalendarId': targetCalendarId,
        'targetCalendarProviderId': targetCalendar.providerId,
        'sourceEventId': sourceEventId,
      }),
    );
    return PimCopyResult<CalendarEvent>(
      entity: duplicated,
      remotePushEnqueued: true,
    );
  }

  /// Copies [sourceContactId] onto [targetContactListId] under
  /// [targetAccountId].
  Future<PimCopyResult<Contact>> copyContactToList({
    required String sourceContactId,
    required String targetAccountId,
    required String targetContactListId,
  }) async {
    final Contact duplicated = await _pimStore.duplicateContactToList(
      sourceContactId: sourceContactId,
      targetAccountId: targetAccountId,
      targetContactListId: targetContactListId,
    );
    final ContactList? targetList = await _pimStore.getContactList(
      targetContactListId,
    );
    if (targetList == null) {
      throw StateError(
        'copyContactToList: target list "$targetContactListId" missing after '
        'duplicate.',
      );
    }
    final bool enqueue = await _shouldEnqueueRemotePush(targetAccountId);
    if (!enqueue) {
      return PimCopyResult<Contact>(
        entity: duplicated,
        remotePushEnqueued: false,
      );
    }
    await _repository.enqueueSyncJob(
      accountId: targetAccountId,
      type: PimSyncJobs.contactsCopy,
      payloadJson: jsonEncode(<String, String>{
        'localContactId': duplicated.id,
        'targetContactListId': targetContactListId,
        'targetContactListProviderId': targetList.providerId,
        'sourceContactId': sourceContactId,
      }),
    );
    return PimCopyResult<Contact>(
      entity: duplicated,
      remotePushEnqueued: true,
    );
  }

  Future<bool> _shouldEnqueueRemotePush(String accountId) async {
    final GraphPimProvider? provider = await _resolvePim(accountId);
    if (provider == null) {
      return false;
    }
    try {
      return provider is! DavPimProvider;
    } finally {
      await provider.dispose();
    }
  }
}
