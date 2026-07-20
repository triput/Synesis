// ==============================================================================
// File: lib/sync/sync_engine.dart
// Description: Sequential durable sync-job processor for local-first mail data.
// Component: Sync
// Version: 1.2 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:bytemail/compose/outgoing_message_builder.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/focus/focus.dart';
import 'package:bytemail/mime/outgoing_envelope.dart';
import 'package:bytemail/protocol/graph_mail_provider.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/protocol/thread_id.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/outbox/send_error_messages.dart';
import 'package:bytemail/sync/imap_idle_service.dart';
import 'package:bytemail/sync/network_sync_policy.dart';
import 'package:bytemail/widgets/widget_snapshot_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

typedef ProviderResolver = Future<MailProvider?> Function(String accountId);

/// Invoked when newly inserted unread inbox messages arrive (non-bootstrap sync).
typedef NewUnreadMailHandler = Future<void> Function(List<MailMessage> messages);

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
    TrashRetentionDaysReader? trashRetentionDays,
    DeviceRetentionDaysReader? deviceRetentionDays,
    PushOnCellularReader? pushOnCellular,
    ConnectivityReader? readConnectivity,
    NetworkSyncPolicy? networkPolicy,
    Connectivity? connectivity,
    NewUnreadMailHandler? onNewUnread,
  }) : _repository = repository,
       _resolveProvider = resolveProvider,
       _trashRetentionDays = trashRetentionDays ?? (() => 30),
       _deviceRetentionDays = deviceRetentionDays ?? (() => 180),
       _pushOnCellular = pushOnCellular ?? (() => false),
       _readConnectivity = readConnectivity ??
           (() => (connectivity ?? Connectivity()).checkConnectivity()),
       _networkPolicy = networkPolicy ??
           NetworkSyncPolicy(isDesktop: _detectDesktop()),
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

  /// Begins connectivity listening so reconnect kicks and IDLE policy refresh.
  void startNetworkWatcher() {
    if (_networkWatcherStarted) {
      return;
    }
    _networkWatcherStarted = true;
    final Connectivity connectivity = _connectivity ?? Connectivity();
    _connectivitySub = connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        unawaited(_onConnectivityChanged(results));
      },
    );
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
    return _networkPolicy.allowPush(
      results,
      pushOnCellular: _pushOnCellular(),
    );
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
    final Future<void> run = _processPendingJobs(generation);
    _activeKick = run;
    return run.whenComplete(() {
      if (identical(_activeKick, run)) {
        _activeKick = null;
      }
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
    await kick();
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
      default:
        throw ArgumentError.value(
          job.type,
          'job.type',
          'Unsupported sync job type.',
        );
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

  Future<String?> _syncInbox(
    SyncJob job, {
    required bool notifyNewMail,
  }) async {
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
    final String? deltaLink =
        (existing == null || existing.isEmpty) ? null : existing;
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
      await _repository.reclassifyFocusBuckets(
        (MailMessage message) {
          return _scoreFocus(
            accountId: message.accountId,
            fromAddress: message.fromAddress,
            subject: message.subject,
            headers: focusHeadersFromRaw(message.rawHeaders),
          );
        },
      );
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
