// ==============================================================================
// File: lib/sync/sync_engine.dart
// Description: Sequential durable sync-job processor for local-first mail data.
// Component: Sync
// Version: 1.4 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-08-04
// ==============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:synesis/compose/outgoing_message_builder.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/domain/sync_profile.dart';
import 'package:synesis/focus/focus.dart';
import 'package:synesis/mime/outgoing_envelope.dart';
import 'package:synesis/protocol/graph_mail_provider.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/protocol/google_pim_provider.dart';
import 'package:synesis/protocol/dav_pim_provider.dart';
import 'package:synesis/protocol/mail_provider.dart';
import 'package:synesis/protocol/thread_id.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/outbox/send_error_messages.dart';
import 'package:synesis/sync/imap_idle_service.dart';
import 'package:synesis/sync/network_sync_policy.dart';
import 'package:synesis/sync/pim_sync_jobs.dart';
import 'package:synesis/sync/sync_activity.dart';
import 'package:synesis/widgets/widget_snapshot_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

typedef ProviderResolver = Future<MailProvider?> Function(String accountId);

/// Resolves a PIM adapter (Graph, Google, or DAV) for an account; null if none.
typedef GraphPimResolver = Future<GraphPimProvider?> Function(String accountId);

/// Invoked when newly inserted unread inbox messages arrive (non-bootstrap sync).
typedef NewUnreadMailHandler =
    Future<void> Function(List<MailMessage> messages);

/// Reads device trash auto-purge retention in days (default 30).
typedef TrashRetentionDaysReader = int Function();

/// Reads device-wide retention dial days (fallback when no profile).
typedef DeviceRetentionDaysReader = int Function();

/// Reads whether Android cellular push/IDLE is opted in.
typedef PushOnCellularReader = bool Function();

/// Injectable connectivity probe (defaults to [Connectivity.checkConnectivity]).
typedef ConnectivityReader = Future<List<ConnectivityResult>> Function();

class SyncEngine {
  SyncEngine({
    required MailRepository repository,
    required ProviderResolver resolveProvider,
    DriftPimStore? pimStore,
    GraphPimResolver? resolvePim,
    TrashRetentionDaysReader? trashRetentionDays,
    DeviceRetentionDaysReader? deviceRetentionDays,
    PushOnCellularReader? pushOnCellular,
    ConnectivityReader? readConnectivity,
    NetworkSyncPolicy? networkPolicy,
    Connectivity? connectivity,
    NewUnreadMailHandler? onNewUnread,
  }) : _repository = repository,
       _resolveProvider = resolveProvider,
       _pimStore = pimStore,
       _resolvePim = resolvePim,
       _trashRetentionDays = trashRetentionDays ?? (() => 30),
       _deviceRetentionDays = deviceRetentionDays ?? (() => 180),
       _pushOnCellular = pushOnCellular ?? (() => false),
       _readConnectivity =
           readConnectivity ??
           (() => (connectivity ?? Connectivity()).checkConnectivity()),
       _networkPolicy =
           networkPolicy ?? NetworkSyncPolicy(isDesktop: _detectDesktop()),
       _connectivity = connectivity,
       _onNewUnread = onNewUnread {
    _idleService = ImapIdleService(
      resolveProvider: resolveProvider,
      onMailboxChanged: _onIdleWake,
      allowPush: _mayPush,
    );
  }

  static const String trashPurgeJobType = 'trash_purge';
  static const String trashPurgeAccountId = 'system';
  static const String pushWakeJobType = 'push_wake';

  final MailRepository _repository;
  final ProviderResolver _resolveProvider;
  final DriftPimStore? _pimStore;
  final GraphPimResolver? _resolvePim;
  final TrashRetentionDaysReader _trashRetentionDays;
  final DeviceRetentionDaysReader _deviceRetentionDays;
  final PushOnCellularReader _pushOnCellular;
  final ConnectivityReader _readConnectivity;
  final NetworkSyncPolicy _networkPolicy;
  final Connectivity? _connectivity;
  final NewUnreadMailHandler? _onNewUnread;

  late final ImapIdleService _idleService;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  Future<void>? _activeKick;
  int _kickGeneration = 0;
  String? _folderListSoftError;
  FocusOverrideRegistry? _focusOverrides;
  bool _networkWatcherStarted = false;
  SyncActivity? _syncActivity;

  static bool _detectDesktop() {
    if (kIsWeb) {
      return false;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.fuchsia:
        return false;
    }
  }

  /// Resolves the live mail provider for [accountId] (attachments, etc.).
  Future<MailProvider?> resolveMailProvider(String accountId) {
    return _resolveProvider(accountId);
  }

  /// Binds Wave 6P [SyncActivity] for kick lifecycle notifications.
  void attachSyncActivity(SyncActivity activity) {
    _syncActivity = activity;
  }

  /// Whether a kick batch is currently executing on this engine instance.
  bool get isKickInFlight => _activeKick != null;

  /// Starts job processing without blocking the caller (Wave 6P UI contract).
  void kickNonBlocking() {
    unawaited(kick());
  }

  /// Reclaim + enqueue trash purge, then kick without blocking the caller.
  Future<void> kickFreshNonBlocking() async {
    _kickGeneration++;
    _activeKick = null;
    await _repository.reclaimRunningJobs();
    await _repository.reclaimSendingOutbox();
    await _enqueueTrashPurgeIfNeeded();
    kickNonBlocking();
  }

  /// Begins connectivity listening so reconnect kicks and IDLE policy refresh.
  void startNetworkWatcher() {
    if (_networkWatcherStarted) {
      return;
    }
    _networkWatcherStarted = true;
    final Connectivity connectivity = _connectivity ?? Connectivity();
    _connectivitySub = connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      unawaited(_onConnectivityChanged(results));
    });
    unawaited(_bootstrapIdleWatches());
  }

  Future<void> _onConnectivityChanged(List<ConnectivityResult> results) async {
    await _idleService.refreshPolicy();
    if (_networkPolicy.allowPoll(results)) {
      await kick();
      if (await _mayPush()) {
        await _bootstrapIdleWatches();
      }
    } else {
      await _idleService.stopAll();
    }
  }

  Future<void> _bootstrapIdleWatches() async {
    if (!await _mayPush()) {
      return;
    }
    final List<MailAccount> accounts = await _repository.listAccounts();
    for (final MailAccount account in accounts) {
      if (account.providerType == 'imap') {
        await _idleService.ensureWatching(account.id);
      }
    }
  }

  Future<void> _onIdleWake(String accountId) async {
    await enqueuePushWake(accountId);
    await kick();
  }

  Future<bool> _mayPoll() async {
    final List<ConnectivityResult> results = await _safeConnectivity();
    return _networkPolicy.allowPoll(results);
  }

  Future<bool> _mayPush() async {
    final List<ConnectivityResult> results = await _safeConnectivity();
    return _networkPolicy.allowPush(results, pushOnCellular: _pushOnCellular());
  }

  /// Connectivity plugins can throw in unit tests / unsupported hosts.
  Future<List<ConnectivityResult>> _safeConnectivity() async {
    try {
      return await _readConnectivity();
    } on Object {
      return const <ConnectivityResult>[ConnectivityResult.wifi];
    }
  }

  Future<void> kick() {
    final Future<void>? activeKick = _activeKick;
    if (activeKick != null) {
      return activeKick;
    }
    final int generation = _kickGeneration;
    _syncActivity?.onKickStarted();
    final Future<void> run = _processPendingJobs(generation);
    _activeKick = run;
    return run.whenComplete(() {
      if (identical(_activeKick, run)) {
        _activeKick = null;
      }
      _syncActivity?.onKickEnded();
    });
  }

  /// Abandon a hung kick, reclaim stuck jobs/outbox, enqueue trash purge, and process.
  Future<void> kickFresh() async {
    _kickGeneration++;
    _activeKick = null;
    await _repository.reclaimRunningJobs();
    await _repository.reclaimSendingOutbox();
    await _enqueueTrashPurgeIfNeeded();
    await kick();
  }

  Future<void> enqueueIncremental(String accountId) async {
    await _repository.enqueueSyncJob(accountId: accountId, type: 'incremental');
    await enqueuePimIncremental(accountId);
  }

  /// Enqueues PIM collection incremental jobs for Graph, Google, or DAV accounts.
  Future<void> enqueuePimIncremental(String accountId) async {
    if (!await _isPimAccount(accountId)) {
      return;
    }
    await _repository.enqueueSyncJob(
      accountId: accountId,
      type: PimSyncJobs.contactListsIncremental,
    );
    await _repository.enqueueSyncJob(
      accountId: accountId,
      type: PimSyncJobs.calendarsIncremental,
    );
  }

  /// Enqueues PIM bootstrap jobs after account add / credential refresh.
  Future<void> enqueuePimBootstrap(String accountId) async {
    if (!await _isPimAccount(accountId)) {
      return;
    }
    await _repository.enqueueSyncJob(
      accountId: accountId,
      type: PimSyncJobs.contactListsBootstrap,
    );
    await _repository.enqueueSyncJob(
      accountId: accountId,
      type: PimSyncJobs.calendarsBootstrap,
    );
  }

  /// Near-push wake: enqueues an incremental sync for [accountId].
  Future<void> enqueuePushWake(String accountId) async {
    await _repository.enqueueSyncJob(
      accountId: accountId,
      type: pushWakeJobType,
    );
  }

  Future<void> enqueueFolderSync(
    String accountId, {
    required String folderId,
    required String remoteId,
  }) async {
    await _repository.enqueueSyncJob(
      accountId: accountId,
      type: 'full_folder',
      payloadJson: jsonEncode(<String, String>{
        'folderId': folderId,
        'remoteId': remoteId,
      }),
    );
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
    await _idleService.dispose();
  }

  Future<void> _enqueueTrashPurgeIfNeeded() async {
    final bool alreadyQueued = await _repository.hasIncompleteJobOfType(
      trashPurgeJobType,
    );
    if (alreadyQueued) {
      return;
    }
    await _repository.enqueueSyncJob(
      accountId: trashPurgeAccountId,
      type: trashPurgeJobType,
    );
  }

  Future<void> _processPendingJobs(int generation) async {
    if (!await _mayPoll()) {
      return;
    }
    await _repository.reclaimRunningJobs();
    await _repository.reclaimSendingOutbox();
    _focusOverrides = null;
    await _loadFocusOverrides();
    await _reclassifyLocalFocus();
    while (generation == _kickGeneration) {
      final List<SyncJob> jobs = await _repository.claimPendingJobs();
      if (jobs.isEmpty) {
        return;
      }
      for (final SyncJob job in jobs) {
        if (generation != _kickGeneration) {
          return;
        }
        await _processJobSafely(job);
      }
    }
  }

  Future<void> _processJobSafely(SyncJob job) async {
    try {
      final String? cursorJson = await _processJob(job);
      await _repository.completeJob(
        job.id,
        success: true,
        cursorJson: cursorJson,
      );
    } on FormatException catch (error) {
      await _completeFailure(job.id, error.message);
    } on ArgumentError catch (error) {
      await _completeFailure(
        job.id,
        error.message?.toString() ?? error.toString(),
      );
    } on Object catch (error) {
      await _completeFailure(job.id, error.toString());
    }
  }

  Future<void> _completeFailure(String jobId, String error) async {
    try {
      await _repository.completeJob(jobId, success: false, error: error);
    } on Object {
      // The job is already durable and will remain visible as running if storage fails.
    }
  }

  Future<String?> _processJob(SyncJob job) async {
    switch (job.type) {
      case 'bootstrap':
        await _syncFolderListBestEffort(job);
        return _syncInbox(job, notifyNewMail: false);
      case 'incremental':
        await _syncFolderListBestEffort(job);
        return _syncInbox(job, notifyNewMail: true);
      case pushWakeJobType:
        await enqueueIncremental(job.accountId);
        return null;
      case 'full_folder':
        await _syncFolderListBestEffort(job);
        return _syncFolderMessages(job, notifyNewMail: true);
      case 'send_outbox':
        await _sendOutbox(job);
        return null;
      case 'remote_search':
        await _remoteSearch(job);
        return null;
      case 'retention_cleanup':
        await _runRetentionCleanup(job);
        return null;
      case 'push_message_action':
        await _pushMessageAction(job);
        return null;
      case trashPurgeJobType:
        await _runTrashPurge();
        return null;
      case PimSyncJobs.contactListsBootstrap:
        await _syncContactLists(job, bootstrap: true);
        return null;
      case PimSyncJobs.contactListsIncremental:
        await _syncContactLists(job, bootstrap: false);
        return null;
      case PimSyncJobs.contactsBootstrap:
        await _syncContacts(job, bootstrap: true);
        return null;
      case PimSyncJobs.contactsIncremental:
        await _syncContacts(job, bootstrap: false);
        return null;
      case PimSyncJobs.calendarsBootstrap:
        await _syncCalendars(job, bootstrap: true);
        return null;
      case PimSyncJobs.calendarsIncremental:
        await _syncCalendars(job, bootstrap: false);
        return null;
      case PimSyncJobs.eventsBootstrap:
        await _syncEvents(job, bootstrap: true);
        return null;
      case PimSyncJobs.eventsIncremental:
        await _syncEvents(job, bootstrap: false);
        return null;
      case PimSyncJobs.contactsPush:
      case PimSyncJobs.eventsPush:
        // Reserved until ordinary local CRUD write-back.
        return null;
      case PimSyncJobs.contactsCopy:
        await _copyContact(job);
        return null;
      case PimSyncJobs.eventsCopy:
        await _copyEvent(job);
        return null;
      default:
        throw ArgumentError.value(
          job.type,
          'job.type',
          'Unsupported sync job type.',
        );
    }
  }

  Future<bool> _isGraphAccount(String accountId) async {
    try {
      for (final MailAccount account in await _repository.listAccounts()) {
        if (account.id == accountId) {
          return account.providerType == 'graph' ||
              account.providerType == 'microsoft';
        }
      }
    } on Object {
      // Test doubles / transient store errors — treat as non-Graph.
      return false;
    }
    return false;
  }

  Future<bool> _isPimAccount(String accountId) async {
    if (await _isGraphAccount(accountId)) {
      return true;
    }
    return await _pimProvider(accountId) != null;
  }

  Future<GraphPimProvider?> _pimProvider(String accountId) async {
    final GraphPimResolver? resolve = _resolvePim;
    if (resolve == null) {
      return null;
    }
    return resolve(accountId);
  }

  Future<void> _syncContactLists(SyncJob job, {required bool bootstrap}) async {
    final DriftPimStore? store = _pimStore;
    final GraphPimProvider? provider = await _pimProvider(job.accountId);
    if (store == null || provider == null) {
      return;
    }
    try {
      final List<GraphContactFolder> folders = await provider
          .listContactFolders();
      final List<ContactList> lists = provider.mapContactFolders(
        folders,
        accountId: job.accountId,
      );
      await store.upsertContactLists(lists);

      // Re-read so contactListId matches store identity (provider-id lookup).
      final List<ContactList> stored = await store.listContactLists(
        accountId: job.accountId,
      );

      // Metadata cursor: timestamp marker (folders lack a stable delta API).
      final String metaKey = PimSyncJobs.contactListCursorKey(job.accountId);
      await _repository.setCursor(
        job.accountId,
        job.accountId,
        metaKey,
        DateTime.now().toUtc().toIso8601String(),
      );

      for (final ContactList list in stored) {
        await _repository.enqueueSyncJob(
          accountId: job.accountId,
          type: bootstrap
              ? PimSyncJobs.contactsBootstrap
              : PimSyncJobs.contactsIncremental,
          payloadJson: jsonEncode(<String, String>{
            'contactListId': list.id,
            'providerId': list.providerId,
          }),
        );
      }
    } finally {
      await provider.dispose();
    }
  }

  Future<void> _syncContacts(SyncJob job, {required bool bootstrap}) async {
    final DriftPimStore? store = _pimStore;
    final GraphPimProvider? provider = await _pimProvider(job.accountId);
    if (store == null || provider == null) {
      return;
    }
    final Map<String, Object?> payload = _decodePayload(job.payloadJson);
    final String? contactListId = payload['contactListId'] as String?;
    final String? providerId = payload['providerId'] as String?;
    if (contactListId == null ||
        contactListId.isEmpty ||
        providerId == null ||
        providerId.isEmpty) {
      return;
    }
    try {
      final String cursorKey = PimSyncJobs.contactsCursorKey(contactListId);
      final String? existing = bootstrap
          ? null
          : await _repository.getCursor(
              job.accountId,
              contactListId,
              cursorKey,
            );
      final String? deltaLink = (existing == null || existing.isEmpty)
          ? null
          : existing;

      GraphPimDeltaResult<GraphContactBundle> result;
      try {
        result = await provider.syncContacts(
          accountId: job.accountId,
          contactListId: contactListId,
          folderProviderId: providerId,
          deltaLink: deltaLink,
        );
      } on ProtocolException catch (error) {
        if (error.statusCode == 410) {
          await _repository.setCursor(
            job.accountId,
            contactListId,
            cursorKey,
            '',
          );
          result = await provider.syncContacts(
            accountId: job.accountId,
            contactListId: contactListId,
            folderProviderId: providerId,
          );
        } else {
          rethrow;
        }
      }

      if (result.changed.isNotEmpty) {
        await store.upsertContacts(
          result.changed
              .map((GraphContactBundle bundle) => bundle.contact)
              .toList(growable: false),
        );
        final List<ContactEmail> emails = <ContactEmail>[];
        final List<ContactPhone> phones = <ContactPhone>[];
        for (final GraphContactBundle bundle in result.changed) {
          emails.addAll(bundle.emails);
          phones.addAll(bundle.phones);
        }
        await store.upsertContactEmails(emails);
        await store.upsertContactPhones(phones);
      }

      // DAV always returns a full snapshot. Google full pulls (no syncToken
      // cursor) do the same; incremental Google People syncToken pages use
      // removedProviderIds instead and must not soft-delete the rest.
      final bool fullSnapshotSoftDelete =
          provider is DavPimProvider ||
          (provider is GooglePimProvider &&
              (deltaLink == null || deltaLink.isEmpty));
      if (fullSnapshotSoftDelete) {
        final Set<String> remoteIds = result.changed
            .map((GraphContactBundle bundle) => bundle.contact.providerId)
            .toSet();
        final int now = DateTime.now().millisecondsSinceEpoch;
        final List<Contact> missing =
            (await store.listContacts(
                  accountId: job.accountId,
                  contactListId: contactListId,
                ))
                .where(
                  (Contact contact) =>
                      !PimIds.isLocalProviderId(contact.providerId) &&
                      !remoteIds.contains(contact.providerId),
                )
                .map(
                  (Contact contact) => Contact(
                    id: contact.id,
                    accountId: contact.accountId,
                    contactListId: contact.contactListId,
                    providerId: contact.providerId,
                    displayName: contact.displayName,
                    givenName: contact.givenName,
                    familyName: contact.familyName,
                    company: contact.company,
                    notes: contact.notes,
                    etag: contact.etag,
                    updatedAt: now,
                    deletedAt: now,
                  ),
                )
                .toList(growable: false);
        await store.upsertContacts(missing);
      }

      if (result.removedProviderIds.isNotEmpty) {
        final int now = DateTime.now().millisecondsSinceEpoch;
        final List<Contact> softDeleted = <Contact>[];
        for (final String removedId in result.removedProviderIds) {
          final Contact? existingContact = await store.findContactByProviderId(
            accountId: job.accountId,
            providerId: removedId,
          );
          if (existingContact == null) {
            softDeleted.add(
              Contact(
                id: PimIds.stableLocalId(job.accountId, removedId),
                accountId: job.accountId,
                contactListId: contactListId,
                providerId: removedId,
                displayName: '',
                updatedAt: now,
                deletedAt: now,
              ),
            );
          } else {
            softDeleted.add(
              Contact(
                id: existingContact.id,
                accountId: existingContact.accountId,
                contactListId: existingContact.contactListId,
                providerId: existingContact.providerId,
                displayName: existingContact.displayName,
                givenName: existingContact.givenName,
                familyName: existingContact.familyName,
                company: existingContact.company,
                notes: existingContact.notes,
                etag: existingContact.etag,
                updatedAt: now,
                deletedAt: now,
              ),
            );
          }
        }
        await store.upsertContacts(softDeleted);
      }

      final String? link = result.deltaLink;
      if (link != null && link.isNotEmpty) {
        await _repository.setCursor(
          job.accountId,
          contactListId,
          cursorKey,
          link,
        );
      }
    } finally {
      await provider.dispose();
    }
  }

  Future<void> _syncCalendars(SyncJob job, {required bool bootstrap}) async {
    final DriftPimStore? store = _pimStore;
    final GraphPimProvider? provider = await _pimProvider(job.accountId);
    if (store == null || provider == null) {
      return;
    }
    try {
      final List<GraphCalendarInfo> remote = await provider.listCalendars();
      final List<Calendar> calendars = provider.mapCalendars(
        remote,
        accountId: job.accountId,
      );
      await store.upsertCalendars(calendars);

      final List<Calendar> stored = await store.listCalendars(
        accountId: job.accountId,
      );

      final String metaKey = PimSyncJobs.calendarCursorKey(job.accountId);
      await _repository.setCursor(
        job.accountId,
        job.accountId,
        metaKey,
        DateTime.now().toUtc().toIso8601String(),
      );

      for (final Calendar calendar in stored) {
        await _repository.enqueueSyncJob(
          accountId: job.accountId,
          type: bootstrap
              ? PimSyncJobs.eventsBootstrap
              : PimSyncJobs.eventsIncremental,
          payloadJson: jsonEncode(<String, String>{
            'calendarId': calendar.id,
            'providerId': calendar.providerId,
          }),
        );
      }
    } finally {
      await provider.dispose();
    }
  }

  Future<void> _syncEvents(SyncJob job, {required bool bootstrap}) async {
    final DriftPimStore? store = _pimStore;
    final GraphPimProvider? provider = await _pimProvider(job.accountId);
    if (store == null || provider == null) {
      return;
    }
    final Map<String, Object?> payload = _decodePayload(job.payloadJson);
    final String? calendarId = payload['calendarId'] as String?;
    final String? providerId = payload['providerId'] as String?;
    if (calendarId == null ||
        calendarId.isEmpty ||
        providerId == null ||
        providerId.isEmpty) {
      return;
    }
    try {
      final String cursorKey = PimSyncJobs.eventsCursorKey(calendarId);
      final String? existing = bootstrap
          ? null
          : await _repository.getCursor(job.accountId, calendarId, cursorKey);
      final String? deltaLink = (existing == null || existing.isEmpty)
          ? null
          : existing;

      GraphPimDeltaResult<GraphEventBundle> result;
      try {
        result = await provider.syncEvents(
          accountId: job.accountId,
          calendarId: calendarId,
          calendarProviderId: providerId,
          deltaLink: deltaLink,
        );
      } on ProtocolException catch (error) {
        if (error.statusCode == 410) {
          await _repository.setCursor(job.accountId, calendarId, cursorKey, '');
          result = await provider.syncEvents(
            accountId: job.accountId,
            calendarId: calendarId,
            calendarProviderId: providerId,
          );
        } else {
          rethrow;
        }
      }

      if (result.changed.isNotEmpty) {
        await store.upsertEvents(
          result.changed
              .map((GraphEventBundle bundle) => bundle.event)
              .toList(growable: false),
        );
        final List<EventAttendee> attendees = <EventAttendee>[];
        for (final GraphEventBundle bundle in result.changed) {
          attendees.addAll(bundle.attendees);
        }
        await store.upsertEventAttendees(attendees);
      }

      // DAV and Google windowed event pulls are full snapshots within the
      // sync horizon; soft-delete locals missing from the remote set.
      final bool fullSnapshotSoftDelete =
          provider is DavPimProvider ||
          (provider is GooglePimProvider &&
              (deltaLink == null || deltaLink.isEmpty));
      if (fullSnapshotSoftDelete) {
        final Set<String> remoteIds = result.changed
            .map((GraphEventBundle bundle) => bundle.event.providerId)
            .toSet();
        final int now = DateTime.now().millisecondsSinceEpoch;
        final List<CalendarEvent> missing =
            (await store.listEvents(
                  accountId: job.accountId,
                  calendarId: calendarId,
                ))
                .where(
                  (CalendarEvent event) =>
                      !PimIds.isLocalProviderId(event.providerId) &&
                      !remoteIds.contains(event.providerId),
                )
                .map(
                  (CalendarEvent event) => CalendarEvent(
                    id: event.id,
                    accountId: event.accountId,
                    calendarId: event.calendarId,
                    providerId: event.providerId,
                    title: event.title,
                    body: event.body,
                    startEpochMs: event.startEpochMs,
                    endEpochMs: event.endEpochMs,
                    allDay: event.allDay,
                    location: event.location,
                    rrule: event.rrule,
                    reminderMinutes: event.reminderMinutes,
                    etag: event.etag,
                    updatedAt: now,
                    deletedAt: now,
                  ),
                )
                .toList(growable: false);
        await store.upsertEvents(missing);
      }

      if (result.removedProviderIds.isNotEmpty) {
        final int now = DateTime.now().millisecondsSinceEpoch;
        final List<CalendarEvent> softDeleted = <CalendarEvent>[];
        for (final String removedId in result.removedProviderIds) {
          final CalendarEvent? existingEvent = await store
              .findEventByProviderId(
                accountId: job.accountId,
                providerId: removedId,
              );
          if (existingEvent == null) {
            softDeleted.add(
              CalendarEvent(
                id: PimIds.stableLocalId(job.accountId, removedId),
                accountId: job.accountId,
                calendarId: calendarId,
                providerId: removedId,
                title: '',
                startEpochMs: now,
                endEpochMs: now,
                updatedAt: now,
                deletedAt: now,
              ),
            );
          } else {
            softDeleted.add(
              CalendarEvent(
                id: existingEvent.id,
                accountId: existingEvent.accountId,
                calendarId: existingEvent.calendarId,
                providerId: existingEvent.providerId,
                title: existingEvent.title,
                body: existingEvent.body,
                startEpochMs: existingEvent.startEpochMs,
                endEpochMs: existingEvent.endEpochMs,
                allDay: existingEvent.allDay,
                location: existingEvent.location,
                rrule: existingEvent.rrule,
                reminderMinutes: existingEvent.reminderMinutes,
                etag: existingEvent.etag,
                updatedAt: now,
                deletedAt: now,
              ),
            );
          }
        }
        await store.upsertEvents(softDeleted);
      }

      final String? link = result.deltaLink;
      if (link != null && link.isNotEmpty) {
        await _repository.setCursor(job.accountId, calendarId, cursorKey, link);
      }
    } finally {
      await provider.dispose();
    }
  }

  /// Pushes a locally duplicated event to Graph/Google (Wave 6).
  ///
  /// Payload: `localEventId`, `targetCalendarId`, `targetCalendarProviderId`.
  /// DAV targets should not enqueue this job (see [PimCopyService]).
  Future<void> _copyEvent(SyncJob job) async {
    final DriftPimStore? store = _pimStore;
    final GraphPimProvider? provider = await _pimProvider(job.accountId);
    if (store == null || provider == null) {
      return;
    }
    try {
      if (provider is DavPimProvider) {
        // Local duplicate is already done; Wave 6b owns DAV write-back.
        return;
      }
      final Map<String, Object?> payload = _decodePayload(job.payloadJson);
      final String? localEventId = payload['localEventId'] as String?;
      final String? targetCalendarProviderId =
          payload['targetCalendarProviderId'] as String?;
      if (localEventId == null ||
          localEventId.isEmpty ||
          targetCalendarProviderId == null ||
          targetCalendarProviderId.isEmpty) {
        // Soft no-op when payload absent (registered-job smoke / mis-enqueue).
        return;
      }
      final CalendarEvent? event = await store.getEvent(localEventId);
      if (event == null) {
        throw StateError(
          'events_copy: local event "$localEventId" not found.',
        );
      }
      if (event.deletedAt != null) {
        // Undo / local soft-delete before push — do not create remote.
        return;
      }
      if (!PimIds.isLocalProviderId(event.providerId)) {
        // Prior attempt already rewrote the remote id — retry-safe no-op.
        return;
      }
      final PimRemoteCreateResult created = await provider.createEvent(
        calendarProviderId: targetCalendarProviderId,
        event: event,
      );
      await store.rewriteEventProviderId(
        eventId: localEventId,
        providerId: created.providerId,
        etag: created.etag,
      );
    } finally {
      await provider.dispose();
    }
  }

  /// Pushes a locally duplicated contact to Graph/Google (Wave 6).
  ///
  /// Payload: `localContactId`, `targetContactListId`,
  /// `targetContactListProviderId`.
  Future<void> _copyContact(SyncJob job) async {
    final DriftPimStore? store = _pimStore;
    final GraphPimProvider? provider = await _pimProvider(job.accountId);
    if (store == null || provider == null) {
      return;
    }
    try {
      if (provider is DavPimProvider) {
        return;
      }
      final Map<String, Object?> payload = _decodePayload(job.payloadJson);
      final String? localContactId = payload['localContactId'] as String?;
      final String? targetContactListProviderId =
          payload['targetContactListProviderId'] as String?;
      if (localContactId == null ||
          localContactId.isEmpty ||
          targetContactListProviderId == null ||
          targetContactListProviderId.isEmpty) {
        return;
      }
      final Contact? contact = await store.getContact(localContactId);
      if (contact == null) {
        throw StateError(
          'contacts_copy: local contact "$localContactId" not found.',
        );
      }
      if (contact.deletedAt != null) {
        // Local soft-delete before push — do not create remote.
        return;
      }
      if (!PimIds.isLocalProviderId(contact.providerId)) {
        return;
      }
      final List<ContactEmail> emails = await store.listContactEmails(
        localContactId,
      );
      final List<ContactPhone> phones = await store.listContactPhones(
        localContactId,
      );
      final PimRemoteCreateResult created = await provider.createContact(
        folderProviderId: targetContactListProviderId,
        contact: contact,
        emails: emails,
        phones: phones,
      );
      await store.rewriteContactProviderId(
        contactId: localContactId,
        providerId: created.providerId,
        etag: created.etag,
      );
    } finally {
      await provider.dispose();
    }
  }

  Future<void> _runTrashPurge() async {
    final int days = _trashRetentionDays();
    if (days < 0) {
      return;
    }
    final List<MailMessage> expired = await _repository
        .listTrashedPastRetention(retentionDays: days);
    for (final MailMessage message in expired) {
      try {
        final String? providerId = message.providerId;
        if (providerId != null && providerId.isNotEmpty) {
          try {
            String? folderRemoteId;
            final String? folderId = message.folderId;
            if (folderId != null && folderId.isNotEmpty) {
              try {
                folderRemoteId = (await _repository.getFolder(
                  folderId,
                ))?.remoteId;
              } on Object {
                folderRemoteId = null;
              }
            }
            await _withProvider(message.accountId, (
              MailProvider provider,
            ) async {
              await provider.deleteMessage(
                providerId,
                permanent: true,
                folderRemoteId: folderRemoteId,
              );
            });
          } on Object {
            // Keep the local row so the next purge can retry remote deletion.
            continue;
          }
        }
        await _repository.hardDeleteLocal(message.id);
      } on Object {
        // Soft-fail per message; continue purging others.
      }
    }
  }

  Future<void> _pushMessageAction(SyncJob job) async {
    final Map<String, Object?> payload = _decodePayload(job.payloadJson);
    final String? providerId = payload['providerId'] as String?;
    final String? action = payload['action'] as String?;
    if (providerId == null ||
        providerId.isEmpty ||
        action == null ||
        action.isEmpty) {
      throw const FormatException(
        'push_message_action requires providerId and action.',
      );
    }
    await _withProvider(job.accountId, (MailProvider provider) async {
      switch (action) {
        case 'star':
          final Object? starredRaw = payload['starred'];
          final bool starred = starredRaw == true || starredRaw == 'true';
          await provider.setStarred(providerId, starred);
        case 'read':
          final Object? isReadRaw = payload['isRead'];
          final bool isRead = isReadRaw == true || isReadRaw == 'true';
          await provider.setRead(
            providerId,
            isRead: isRead,
            folderRemoteId: payload['folderRemoteId'] as String?,
          );
        case 'move':
        case 'delete':
          final bool permanent =
              payload['permanent'] == true || payload['permanent'] == 'true';
          if (action == 'delete' && permanent) {
            await provider.deleteMessage(
              providerId,
              permanent: true,
              folderRemoteId: payload['folderRemoteId'] as String?,
            );
          } else {
            final String? folderRemoteId = payload['folderRemoteId'] as String?;
            if (folderRemoteId == null || folderRemoteId.isEmpty) {
              throw const FormatException(
                'push_message_action move/delete requires folderRemoteId.',
              );
            }
            await provider.moveMessage(
              providerId,
              folderRemoteId,
              sourceFolderRemoteId: payload['sourceFolderRemoteId'] as String?,
            );
          }
        default:
          throw ArgumentError.value(
            action,
            'action',
            'Unsupported push_message_action.',
          );
      }
    });
  }

  Future<void> _syncFolderListBestEffort(SyncJob job) async {
    try {
      await _syncFolderList(job);
      _folderListSoftError = null;
    } on Object catch (error) {
      // Inbox sync must still run if folder enumeration fails.
      _folderListSoftError = error.toString();
    }
  }

  Future<void> _syncFolderList(SyncJob job) async {
    await _withProvider(job.accountId, (MailProvider provider) async {
      final List<RemoteFolder> remote = await provider.listFolders();
      final List<MailFolder> folders = remote
          .map(
            (RemoteFolder folder) => MailFolder(
              id: MailFolder.localId(
                accountId: job.accountId,
                remoteId: folder.providerId,
                role: _normalizeRole(folder.role),
              ),
              accountId: job.accountId,
              name: folder.name,
              remoteId: folder.providerId,
              role: _normalizeRole(folder.role),
              parentRemoteId: folder.parentProviderId,
              unreadCount: folder.unreadCount,
              totalCount: folder.totalCount,
            ),
          )
          .toList(growable: false);
      await _repository.upsertFolders(folders);
      // Server folder unread counts lag local mark-read; recount from SQLite.
      await _repository.recountUnreadCounts(accountId: job.accountId);
    });
  }

  Future<String?> _syncInbox(SyncJob job, {required bool notifyNewMail}) async {
    final ResolvedSyncPolicy policy = await _resolvePolicy(job.accountId);
    final String folderId = MailFolder.inboxId(job.accountId);
    if (!policy.allowsFolder(
      role: 'inbox',
      remoteId: 'INBOX',
      folderId: folderId,
    )) {
      return null;
    }
    await _withProvider(job.accountId, (MailProvider provider) async {
      await _syncFolderMessagesViaProvider(
        job: job,
        provider: provider,
        folderId: folderId,
        remoteId: provider is GraphMailProvider ? 'inbox' : 'INBOX',
        isInbox: true,
        notifyNewMail: notifyNewMail,
      );
    });
    await WidgetSnapshotService(_repository).refreshAll();
    if (await _mayPush()) {
      await _idleService.ensureWatching(job.accountId);
    }
    final String syncedAt = DateTime.now().toUtc().toIso8601String();
    await _repository.setCursor(job.accountId, folderId, 'inbox', syncedAt);
    final Map<String, String> cursor = <String, String>{'inbox': syncedAt};
    final String? folderListError = _folderListSoftError;
    if (folderListError != null && folderListError.isNotEmpty) {
      cursor['folderListError'] = folderListError;
      _folderListSoftError = null;
    }
    return jsonEncode(cursor);
  }

  Future<String?> _syncFolderMessages(
    SyncJob job, {
    required bool notifyNewMail,
  }) async {
    final Map<String, Object?> payload = _decodePayload(job.payloadJson);
    final String? folderId = payload['folderId'] as String?;
    final String? remoteId = payload['remoteId'] as String?;
    if (folderId == null ||
        folderId.isEmpty ||
        remoteId == null ||
        remoteId.isEmpty) {
      // Legacy full_folder with no payload: keep inbox behavior.
      return _syncInbox(job, notifyNewMail: notifyNewMail);
    }

    final ResolvedSyncPolicy policy = await _resolvePolicy(job.accountId);
    final MailFolder? folder = await _repository.getFolder(folderId);
    if (!policy.allowsFolder(
      role: folder?.role,
      remoteId: remoteId,
      folderId: folderId,
    )) {
      return null;
    }

    final bool isInbox = folderId == MailFolder.inboxId(job.accountId);
    await _withProvider(job.accountId, (MailProvider provider) async {
      await _syncFolderMessagesViaProvider(
        job: job,
        provider: provider,
        folderId: folderId,
        remoteId: remoteId,
        isInbox: isInbox,
        notifyNewMail: notifyNewMail,
      );
    });
    await WidgetSnapshotService(_repository).refreshAll();
    final String syncedAt = DateTime.now().toUtc().toIso8601String();
    await _repository.setCursor(job.accountId, folderId, 'folder', syncedAt);
    return jsonEncode(<String, String>{folderId: syncedAt});
  }

  /// Graph delta when available; otherwise listRecent (+ seed deltaLink).
  Future<void> _syncFolderMessagesViaProvider({
    required SyncJob job,
    required MailProvider provider,
    required String folderId,
    required String remoteId,
    required bool isInbox,
    required bool notifyNewMail,
  }) async {
    if (provider is GraphMailProvider) {
      final bool usedDelta = await _tryGraphDelta(
        job: job,
        provider: provider,
        folderId: folderId,
        remoteId: remoteId,
        isInbox: isInbox,
        notifyNewMail: notifyNewMail,
      );
      if (usedDelta) {
        return;
      }
    }

    final List<RemoteMessageHeader> messages = isInbox
        ? await provider.listRecentInbox()
        : await provider.listRecentInFolder(remoteId);
    final List<MailMessage> newlyUnread = await _repository.upsertMessages(
      messages
          .map(
            (RemoteMessageHeader header) => _toMailMessage(
              job.accountId,
              header,
              folderKey: isInbox ? null : folderId,
            ),
          )
          .toList(growable: false),
      folderId: folderId,
    );
    await _maybeNotifyNewUnread(
      isInbox: isInbox,
      notifyNewMail: notifyNewMail,
      messages: newlyUnread,
    );

    if (provider is GraphMailProvider) {
      await _seedGraphDeltaCursor(
        provider: provider,
        accountId: job.accountId,
        folderId: folderId,
        remoteId: remoteId,
      );
    }
  }

  /// Runs Graph delta (resume or initial). Returns false to fall back to poll.
  Future<bool> _tryGraphDelta({
    required SyncJob job,
    required GraphMailProvider provider,
    required String folderId,
    required String remoteId,
    required bool isInbox,
    required bool notifyNewMail,
  }) async {
    final String? existing = await _repository.getCursor(
      job.accountId,
      folderId,
      GraphMailProvider.graphDeltaCursorKey,
    );
    final String? deltaLink = (existing == null || existing.isEmpty)
        ? null
        : existing;
    try {
      final GraphDeltaResult delta = await provider.listDelta(
        remoteId,
        deltaLink: deltaLink,
      );
      await _applyGraphDelta(
        job: job,
        folderId: folderId,
        isInbox: isInbox,
        notifyNewMail: notifyNewMail,
        delta: delta,
      );
      return true;
    } on ProtocolException catch (error) {
      if (error.statusCode == 410) {
        await _repository.setCursor(
          job.accountId,
          folderId,
          GraphMailProvider.graphDeltaCursorKey,
          '',
        );
        return false;
      }
      // Initial delta can fail on some tenants — preserve listRecent fallback.
      if (deltaLink == null) {
        return false;
      }
      rethrow;
    } on Object {
      if (deltaLink == null) {
        return false;
      }
      rethrow;
    }
  }

  Future<void> _seedGraphDeltaCursor({
    required GraphMailProvider provider,
    required String accountId,
    required String folderId,
    required String remoteId,
  }) async {
    try {
      final GraphDeltaResult seed = await provider.listDelta(remoteId);
      final String? link = seed.deltaLink;
      if (link != null && link.isNotEmpty) {
        await _repository.setCursor(
          accountId,
          folderId,
          GraphMailProvider.graphDeltaCursorKey,
          link,
        );
      }
    } on Object {
      // Poll path already succeeded; seeding delta is best-effort.
    }
  }

  Future<void> _applyGraphDelta({
    required SyncJob job,
    required String folderId,
    required bool isInbox,
    required bool notifyNewMail,
    required GraphDeltaResult delta,
  }) async {
    if (delta.changed.isNotEmpty) {
      final List<MailMessage> newlyUnread = await _repository.upsertMessages(
        delta.changed
            .map(
              (RemoteMessageHeader header) => _toMailMessage(
                job.accountId,
                header,
                folderKey: isInbox ? null : folderId,
              ),
            )
            .toList(growable: false),
        folderId: folderId,
      );
      await _maybeNotifyNewUnread(
        isInbox: isInbox,
        notifyNewMail: notifyNewMail,
        messages: newlyUnread,
      );
    }
    for (final String providerId in delta.removedProviderIds) {
      final String idKey = isInbox ? providerId : '$folderId\u0000$providerId';
      await _repository.hardDeleteLocal(_localId(job.accountId, idKey));
    }
    final String? link = delta.deltaLink;
    if (link != null && link.isNotEmpty) {
      await _repository.setCursor(
        job.accountId,
        folderId,
        GraphMailProvider.graphDeltaCursorKey,
        link,
      );
    }
  }

  Future<void> _maybeNotifyNewUnread({
    required bool isInbox,
    required bool notifyNewMail,
    required List<MailMessage> messages,
  }) async {
    if (!notifyNewMail || !isInbox || messages.isEmpty) {
      return;
    }
    final NewUnreadMailHandler? handler = _onNewUnread;
    if (handler == null) {
      return;
    }
    await handler(messages);
  }

  Future<void> _sendOutbox(SyncJob job) async {
    int failureCount = 0;
    String? firstError;
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final List<MailAccount> accounts = await _repository.listAccounts();
    String fromAddress = job.accountId;
    for (final MailAccount account in accounts) {
      if (account.id == job.accountId) {
        fromAddress = account.address;
        break;
      }
    }
    final OutgoingMessageBuilder builder = OutgoingMessageBuilder(
      resolveBlobPath: (String blobId) async {
        return (await _repository.getAttachmentBlob(blobId))?.path;
      },
      loadSignature: _repository.getSignature,
      loadSignatureAssets: _repository.listSignatureAssets,
    );
    await _withProvider(job.accountId, (MailProvider provider) async {
      final List<OutboxItem> queued = (await _repository.listOutbox())
          .where(
            (OutboxItem item) =>
                item.accountId == job.accountId && item.state == 'queued',
          )
          .toList(growable: false);
      for (final OutboxItem item in queued) {
        final int? sendAfter = item.sendAfter;
        if (sendAfter != null && sendAfter > nowMs) {
          continue;
        }
        await _repository.updateOutboxState(item.id, 'sending');
        try {
          final OutgoingEnvelope envelope = await builder.build(
            item: item,
            fromAddress: fromAddress,
          );
          if (envelope.to.isEmpty &&
              envelope.cc.isEmpty &&
              envelope.bcc.isEmpty) {
            throw const ProtocolException(
              'A recipient is required to send mail.',
            );
          }
          await provider.sendEnvelope(envelope);
          await _repository.updateOutboxState(item.id, 'sent');
        } on Object catch (error) {
          failureCount += 1;
          final String message = actionableSendError(error);
          firstError ??= message;
          await _repository.updateOutboxState(
            item.id,
            'failed',
            error: message,
          );
        }
      }
    });
    if (failureCount > 0) {
      throw StateError(
        failureCount == 1
            ? 'Outbox send failed: ${firstError ?? 'unknown error'}'
            : 'Outbox send failed for $failureCount messages: '
                  '${firstError ?? 'unknown error'}',
      );
    }
  }

  Future<void> _remoteSearch(SyncJob job) async {
    final Map<String, Object?> payload = _decodePayload(job.payloadJson);
    final String query = payload['query'] as String? ?? '';
    if (query.trim().isEmpty) {
      throw const FormatException('remote_search requires a non-empty query.');
    }
    await _withProvider(job.accountId, (MailProvider provider) async {
      final List<RemoteMessageHeader> messages = await provider.searchRemote(
        query,
      );
      await _repository.upsertMessages(
        messages
            .map(
              (RemoteMessageHeader header) =>
                  _toMailMessage(job.accountId, header),
            )
            .toList(growable: false),
        folderId: MailFolder.inboxId(job.accountId),
      );
    });
    await WidgetSnapshotService(_repository).refreshAll();
  }

  Future<void> _runRetentionCleanup(SyncJob job) async {
    final Map<String, Object?> payload = _decodePayload(job.payloadJson);
    final Object? days = payload['days'] ?? payload['retentionDays'];
    final int retentionDays;
    if (days is num) {
      retentionDays = days.toInt();
    } else {
      final ResolvedSyncPolicy policy = await _resolvePolicy(job.accountId);
      retentionDays = policy.retentionDays;
    }
    final String? accountId =
        job.accountId.isEmpty || job.accountId == trashPurgeAccountId
        ? null
        : job.accountId;
    await _repository.applyRetention(
      retentionDays: retentionDays,
      accountId: accountId,
    );
  }

  Future<ResolvedSyncPolicy> _resolvePolicy(String accountId) {
    return _repository.resolvePolicy(
      accountId,
      fallbackRetentionDays: _deviceRetentionDays(),
    );
  }

  /// Resolves a short-lived provider, runs [action], then disposes it.
  Future<T> _withProvider<T>(
    String accountId,
    Future<T> Function(MailProvider provider) action,
  ) async {
    final MailProvider? provider = await _resolveProvider(accountId);
    if (provider == null) {
      throw StateError('No configured mail provider for account $accountId.');
    }
    try {
      return await action(provider);
    } finally {
      await provider.dispose();
    }
  }

  MailMessage _toMailMessage(
    String accountId,
    RemoteMessageHeader header, {
    String? folderKey,
  }) {
    final int whenEpochMs = header.receivedAt.millisecondsSinceEpoch;
    final String idKey =
        folderKey == null || folderKey == MailFolder.inboxId(accountId)
        ? header.providerId
        : '$folderKey\u0000${header.providerId}';
    final FocusBucket bucket = _scoreFocus(
      accountId: accountId,
      fromAddress: header.fromAddress,
      subject: header.subject,
      headers: header.classificationHeaders,
    );
    final String? threadRoot = resolveThreadId(
      conversationId: header.threadId,
      messageId: header.messageIdHeader,
      inReplyTo: header.inReplyTo,
      references: header.references,
      fallbackProviderId: header.providerId,
    );
    return MailMessage(
      id: _localId(accountId, idKey),
      accountId: accountId,
      fromName: header.fromName ?? header.fromAddress,
      fromAddress: header.fromAddress,
      subject: header.subject,
      snippet: header.snippet ?? '',
      body: header.snippet ?? '',
      whenLabel: _whenLabel(header.receivedAt),
      bucket: bucket,
      unread: !header.isRead,
      providerId: header.providerId,
      messageIdHeader: header.messageIdHeader,
      hasAttachments: header.hasAttachments,
      whenEpochMs: whenEpochMs,
      threadId: threadRoot == null ? null : '$accountId:$threadRoot',
      rawHeaders: header.rawHeaders,
      toRecipients: header.toRecipients,
      ccRecipients: header.ccRecipients,
    );
  }

  Future<void> _loadFocusOverrides() async {
    if (_focusOverrides != null) {
      return;
    }
    try {
      final List<FocusRule> rules = await _repository.listFocusRules();
      _focusOverrides = FocusOverrideRegistry(rules: rules);
    } on Object {
      _focusOverrides = FocusOverrideRegistry();
    }
  }

  FocusBucket _scoreFocus({
    required String accountId,
    required String fromAddress,
    required String subject,
    Map<String, String> headers = const <String, String>{},
  }) {
    final RuleBasedFocusScorer scorer = RuleBasedFocusScorer(
      overrides: _focusOverrides,
      accountId: accountId,
    );
    return scorer.score(
      MailMessageDraft(
        fromAddress: fromAddress,
        subject: subject,
        headers: headers,
      ),
    );
  }

  /// Re-scores locally stored messages using from/subject/raw headers.
  ///
  /// Fixes mail that was ingested before Focus scoring was wired, without
  /// waiting for a full remote re-fetch of classification headers.
  Future<void> _reclassifyLocalFocus() async {
    try {
      await _loadFocusOverrides();
      await _repository.reclassifyFocusBuckets((MailMessage message) {
        return _scoreFocus(
          accountId: message.accountId,
          fromAddress: message.fromAddress,
          subject: message.subject,
          headers: focusHeadersFromRaw(message.rawHeaders),
        );
      });
    } on Object {
      // Best-effort; sync jobs still proceed.
    }
  }

  String? _normalizeRole(String? role) {
    if (role == null || role.isEmpty) {
      return null;
    }
    final String normalized = role.trim().toLowerCase();
    switch (normalized) {
      case 'inbox':
        return 'inbox';
      case 'trash':
      case 'deleteditems':
      case 'deleted':
        return 'trash';
      case 'junk':
      case 'junkemail':
      case 'spam':
        return 'junk';
      case 'archive':
        return 'archive';
      case 'sentitems':
      case 'sent':
        return 'sentitems';
      case 'drafts':
      case 'draft':
        return 'drafts';
      default:
        return normalized;
    }
  }

  Map<String, Object?> _decodePayload(String? payloadJson) {
    if (payloadJson == null || payloadJson.trim().isEmpty) {
      return const <String, Object?>{};
    }
    final Object? decoded = jsonDecode(payloadJson);
    if (decoded is! Map<Object?, Object?>) {
      throw const FormatException('Sync job payload must be a JSON object.');
    }
    return Map<String, Object?>.from(decoded);
  }

  String _localId(String accountId, String providerId) => base64Url
      .encode(utf8.encode('$accountId\u0000$providerId'))
      .replaceAll('=', '');

  String _whenLabel(DateTime timestamp) {
    final DateTime local = timestamp.toLocal();
    final DateTime now = DateTime.now();
    if (_isSameDay(local, now)) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    if (_isSameDay(local, now.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return '${local.month}/${local.day}/${local.year}';
  }

  bool _isSameDay(DateTime left, DateTime right) =>
      left.year == right.year &&
      left.month == right.month &&
      left.day == right.day;
}
