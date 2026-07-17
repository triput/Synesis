// ==============================================================================
// File: lib/mailbox/message_action_service.dart
// Description: Optimistic mailbox mutations with enqueue-only remote sync
// Component: Data / Sync
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:bytemail/domain/address_match_scope.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/focus/focus.dart';
import 'package:bytemail/mailbox/mailbox_mutation_result.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/ui/mailbox/mailbox_state.dart';

/// Confirms creating a missing system folder (Trash / Junk / Archive).
///
/// [roleDisplayName] is a user-facing label such as `Trash`.
typedef SystemFolderConfirm = Future<bool> Function(
  String accountId,
  String roleDisplayName,
);

/// Applies a [MailboxMutationResult] patch (typically cubit emit / refresh).
typedef MailboxMutationApply = FutureOr<void> Function(
  MailboxMutationResult result,
);

/// Local-first message actions; remote side effects are always outbox jobs.
class MessageActionService {
  MessageActionService({
    required MailRepository repository,
    required ProviderResolver resolveProvider,
    SyncEngine? syncEngine,
    this.onConfirmCreateSystemFolder,
  }) : _repository = repository,
       _resolveProvider = resolveProvider,
       _syncEngine = syncEngine;

  final MailRepository _repository;
  final ProviderResolver _resolveProvider;
  final SyncEngine? _syncEngine;

  /// When set (typically by the workspace UI), missing trash/junk/archive
  /// folders can be created after user confirmation.
  SystemFolderConfirm? onConfirmCreateSystemFolder;

  Future<void> setUnread(
    MailboxState state,
    String messageId,
    bool unread, {
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    await setUnreadBulk(
      state,
      <String>[messageId],
      unread,
      apply: apply,
      currentState: currentState,
    );
  }

  Future<void> setUnreadBulk(
    MailboxState state,
    List<String> messageIds,
    bool unread, {
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    if (messageIds.isEmpty) {
      return;
    }
    final Set<String> idSet = messageIds.toSet();
    final List<MailMessage> targets = state.messages
        .where((MailMessage m) => idSet.contains(m.id))
        .toList(growable: false);
    if (targets.isEmpty) {
      return;
    }

    final List<MailMessage> previousMessages = state.messages;
    final List<MailFolder> previousFolders = state.folders;
    final List<MailMessage> patchedMessages = state.messages
        .map(
          (MailMessage m) => idSet.contains(m.id) && m.unread != unread
              ? m.copyWith(unread: unread)
              : m,
        )
        .toList(growable: false);
    final List<MailFolder> patchedFolders = _foldersWithUnreadDelta(
      state,
      targets,
      unread: unread,
    );
    apply(
      MailboxMutationResult(
        messages: patchedMessages,
        folders: patchedFolders,
        clearError: true,
      ),
    );

    try {
      await _repository.setUnreadBulk(messageIds, unread);
    } catch (error) {
      apply(
        MailboxMutationResult(
          messages: previousMessages,
          folders: previousFolders,
          errorMessage: 'Could not save read state: $error',
        ),
      );
      return;
    }

    // Re-load folder badges from DB after recount — optimistic delta can miss
    // messages with a null folderId, and sync may have raced.
    try {
      final List<MailFolder> folders = await _repository.listFolders();
      apply(MailboxMutationResult(folders: folders));
    } on Object {
      // Keep optimistic folders if reload fails.
    }

    final List<String> softErrors = await _enqueueReadState(
      targets,
      isRead: !unread,
      folders: currentState().folders,
    );
    if (softErrors.isNotEmpty) {
      apply(MailboxMutationResult(errorMessage: softErrors.first));
    }
  }

  Future<void> toggleSelectedUnread(
    MailboxState state, {
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    final List<MailMessage> targets = _actionTargets(state);
    if (targets.isEmpty) {
      return;
    }
    // Uniform bulk policy: if any target is unread, mark all read; else unread.
    final bool markUnread = !targets.any((MailMessage message) => message.unread);
    await setUnreadBulk(
      state,
      targets.map((MailMessage message) => message.id).toList(growable: false),
      markUnread,
      apply: apply,
      currentState: currentState,
    );
  }

  Future<void> toggleStarSelected(
    MailboxState state, {
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    final List<MailMessage> targets = _actionTargets(state);
    if (targets.isEmpty) {
      return;
    }
    final bool starred = !targets.first.starred;
    await setStarredBulk(
      state,
      targets.map((MailMessage message) => message.id).toList(growable: false),
      starred,
      apply: apply,
      currentState: currentState,
    );
  }

  Future<void> setStarredBulk(
    MailboxState state,
    List<String> ids,
    bool starred, {
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    if (ids.isEmpty) {
      return;
    }
    final Set<String> idSet = ids.toSet();
    final List<MailMessage> targets = state.messages
        .where((MailMessage message) => idSet.contains(message.id))
        .toList(growable: false);
    if (targets.isEmpty) {
      return;
    }

    final List<MailMessage> previousMessages = state.messages;
    final List<MailMessage> patchedMessages = state.messages
        .map(
          (MailMessage message) => idSet.contains(message.id)
              ? message.copyWith(starred: starred)
              : message,
        )
        .toList(growable: false);
    apply(
      MailboxMutationResult(messages: patchedMessages, clearError: true),
    );

    try {
      for (final String id in ids) {
        await _repository.setStarred(id, starred);
      }
    } catch (error) {
      apply(
        MailboxMutationResult(
          messages: previousMessages,
          errorMessage: 'Could not save starred state: $error',
        ),
      );
      return;
    }

    final List<String> softErrors = await _enqueueStarred(
      targets,
      starred: starred,
    );
    if (softErrors.isNotEmpty) {
      apply(MailboxMutationResult(errorMessage: softErrors.first));
    }
  }

  /// Local-only pin; does not enqueue remote sync jobs.
  Future<void> setPinned(
    MailboxState state,
    String messageId,
    bool pinned, {
    required MailboxMutationApply apply,
  }) async {
    await setPinnedBulk(
      state,
      <String>[messageId],
      pinned,
      apply: apply,
    );
  }

  Future<void> togglePinSelected(
    MailboxState state, {
    required MailboxMutationApply apply,
  }) async {
    final List<MailMessage> targets = _actionTargets(state);
    if (targets.isEmpty) {
      return;
    }
    final bool pinned = !targets.first.pinned;
    await setPinnedBulk(
      state,
      targets.map((MailMessage message) => message.id).toList(growable: false),
      pinned,
      apply: apply,
    );
  }

  Future<void> setPinnedBulk(
    MailboxState state,
    List<String> ids,
    bool pinned, {
    required MailboxMutationApply apply,
  }) async {
    if (ids.isEmpty) {
      return;
    }
    final Set<String> idSet = ids.toSet();
    final List<MailMessage> targets = state.messages
        .where((MailMessage message) => idSet.contains(message.id))
        .toList(growable: false);
    if (targets.isEmpty) {
      return;
    }

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final List<MailMessage> previousMessages = state.messages;
    final List<MailMessage> patched = state.messages
        .map(
          (MailMessage message) => idSet.contains(message.id)
              ? message.copyWith(pinned: pinned)
              : message,
        )
        .toList(growable: false);

    final bool leaveView =
        state.virtualView == MailboxVirtualView.pinned && !pinned;
    if (leaveView) {
      _applyOptimisticRemoval(
        state,
        targets,
        apply: apply,
        currentState: () => state,
      );
    } else {
      apply(
        MailboxMutationResult(
          messages: _filterVisible(state, patched, nowMs: nowMs),
          clearError: true,
        ),
      );
    }

    try {
      await _repository.setPinnedBulk(ids, pinned);
    } catch (error) {
      apply(
        MailboxMutationResult(
          messages: previousMessages,
          errorMessage: 'Could not save pinned state: $error',
        ),
      );
    }
  }

  /// Local-only snooze for the current selection. Does not enqueue sync jobs.
  Future<void> snoozeSelected(
    MailboxState state, {
    required int snoozedUntil,
    required MailboxMutationApply apply,
  }) async {
    final List<MailMessage> targets = _actionTargets(state);
    if (targets.isEmpty) {
      return;
    }
    await _setSnoozedBulk(
      state,
      targets.map((MailMessage message) => message.id).toList(growable: false),
      snoozedUntil,
      apply: apply,
    );
  }

  Future<void> clearSnoozeSelected(
    MailboxState state, {
    required MailboxMutationApply apply,
  }) async {
    final List<MailMessage> targets = _actionTargets(state);
    if (targets.isEmpty) {
      return;
    }
    await _setSnoozedBulk(
      state,
      targets.map((MailMessage message) => message.id).toList(growable: false),
      null,
      apply: apply,
    );
  }

  Future<void> _setSnoozedBulk(
    MailboxState state,
    List<String> ids,
    int? snoozedUntil, {
    required MailboxMutationApply apply,
  }) async {
    if (ids.isEmpty) {
      return;
    }
    final Set<String> idSet = ids.toSet();
    final List<MailMessage> targets = state.messages
        .where((MailMessage message) => idSet.contains(message.id))
        .toList(growable: false);
    if (targets.isEmpty) {
      return;
    }

    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final List<MailMessage> previousMessages = state.messages;
    final List<MailMessage> patched = state.messages
        .map((MailMessage message) {
          if (!idSet.contains(message.id)) {
            return message;
          }
          if (snoozedUntil == null) {
            return message.copyWith(clearSnoozedUntil: true);
          }
          return message.copyWith(snoozedUntil: snoozedUntil);
        })
        .toList(growable: false);

    final bool activeSnooze = snoozedUntil != null && snoozedUntil > nowMs;
    final bool leaveView = activeSnooze
        ? state.virtualView != MailboxVirtualView.snoozed
        : state.virtualView == MailboxVirtualView.snoozed;

    if (leaveView) {
      _applyOptimisticRemoval(
        state,
        targets,
        apply: apply,
        currentState: () => state,
      );
    } else {
      apply(
        MailboxMutationResult(
          messages: _filterVisible(state, patched, nowMs: nowMs),
          clearError: true,
        ),
      );
    }

    try {
      await _repository.setSnoozedBulk(ids, snoozedUntil);
    } catch (error) {
      apply(
        MailboxMutationResult(
          messages: previousMessages,
          errorMessage: 'Could not save snooze state: $error',
        ),
      );
    }
  }

  List<MailMessage> _filterVisible(
    MailboxState state,
    List<MailMessage> messages, {
    required int nowMs,
  }) {
    return messages
        .where(
          (MailMessage message) =>
              _isVisibleInCurrentView(state, message, nowMs),
        )
        .toList(growable: false);
  }

  bool _isVisibleInCurrentView(
    MailboxState state,
    MailMessage message,
    int nowMs,
  ) {
    final MailboxVirtualView view = state.virtualView;
    if (view == MailboxVirtualView.starred && !message.starred) {
      return false;
    }
    if (view == MailboxVirtualView.pinned && !message.pinned) {
      return false;
    }
    if (view == MailboxVirtualView.snoozed) {
      final int? until = message.snoozedUntil;
      return until != null && until > nowMs;
    }
    final int? until = message.snoozedUntil;
    if (until != null && until > nowMs) {
      return false;
    }
    return true;
  }

  Future<void> archiveSelected(
    MailboxState state, {
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    final List<MailMessage> targets = _actionTargets(state);
    if (targets.isEmpty) {
      return;
    }
    await _moveTargetsByRole(
      state,
      targets,
      role: 'archive',
      action: 'move',
      leaveCurrentView: true,
      apply: apply,
      currentState: currentState,
    );
  }

  Future<void> deleteSelected(
    MailboxState state, {
    required bool permanent,
    required bool viewingTrash,
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    final List<MailMessage> targets = _actionTargets(state);
    if (targets.isEmpty) {
      return;
    }
    if (permanent || viewingTrash) {
      await _hardDeleteTargets(
        state,
        targets,
        apply: apply,
        currentState: currentState,
      );
      return;
    }
    await _moveTargetsByRole(
      state,
      targets,
      role: 'trash',
      action: 'delete',
      leaveCurrentView: true,
      trashedAt: DateTime.now().millisecondsSinceEpoch,
      apply: apply,
      currentState: currentState,
    );
  }

  Future<void> recoverSelected(
    MailboxState state, {
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    final List<MailMessage> targets = _actionTargets(state);
    if (targets.isEmpty) {
      return;
    }
    await _moveTargetsByRole(
      state,
      targets,
      role: 'inbox',
      action: 'move',
      leaveCurrentView: true,
      clearTrashedAt: true,
      apply: apply,
      currentState: currentState,
    );
  }

  Future<void> moveSelectedToFolder(
    MailboxState state,
    String folderId, {
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    final List<MailMessage> targets = _actionTargets(state);
    if (targets.isEmpty) {
      return;
    }
    final MailFolder? destination =
        await _repository.getFolder(folderId) ?? _folderById(state, folderId);
    if (destination == null) {
      apply(
        const MailboxMutationResult(
          errorMessage: 'Destination folder was not found.',
        ),
      );
      return;
    }

    final List<MailMessage> eligible = targets
        .where(
          (MailMessage message) => message.accountId == destination.accountId,
        )
        .toList(growable: false);
    final int skipped = targets.length - eligible.length;
    if (eligible.isEmpty) {
      apply(
        const MailboxMutationResult(
          errorMessage:
              'No selected messages belong to the destination folder account.',
        ),
      );
      return;
    }

    final bool leavingView = _messageLeavesCurrentView(
      state,
      destinationFolderId: destination.id,
      trashedAt: null,
      clearTrashedAt: false,
      hardDelete: false,
    );
    final List<MailMessage> previousMessages = state.messages;
    final List<MailFolder> previousFolders = state.folders;
    _applyOptimisticMove(
      state,
      eligible,
      destinationFolderId: destination.id,
      leaveCurrentView: leavingView,
      clearTrashedAt: false,
      apply: apply,
      currentState: currentState,
    );

    try {
      await _repository.moveMessagesLocal(
        eligible
            .map((MailMessage message) => message.id)
            .toList(growable: false),
        destination.id,
      );
    } catch (error) {
      apply(
        MailboxMutationResult(
          messages: previousMessages,
          folders: previousFolders,
          errorMessage: 'Could not move messages: $error',
        ),
      );
      return;
    }

    final List<String> enqueueErrors = await _enqueueMove(
      eligible,
      targetFolder: destination,
      action: 'move',
      folders: currentState().folders,
    );
    final List<String> softErrors = <String>[
      if (skipped > 0) 'Skipped $skipped message(s) from other accounts.',
      ...enqueueErrors,
    ];
    if (softErrors.isNotEmpty) {
      apply(MailboxMutationResult(errorMessage: softErrors.first));
    }
  }

  Future<void> reportJunk(
    MailboxState state, {
    AddressMatchScope scope = AddressMatchScope.sender,
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    final List<MailMessage> selected = _actionTargets(state);
    if (selected.isEmpty) {
      return;
    }
    final List<MailMessage> targets = await _expandAddressScope(
      state,
      selected,
      scope: scope,
    );
    await _moveTargetsByRole(
      state,
      targets,
      role: 'junk',
      action: 'move',
      leaveCurrentView: true,
      apply: apply,
      currentState: currentState,
    );
  }

  Future<void> notJunk(
    MailboxState state, {
    AddressMatchScope scope = AddressMatchScope.sender,
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    final List<MailMessage> selected = _actionTargets(state);
    if (selected.isEmpty) {
      return;
    }
    final List<MailMessage> targets = await _expandAddressScope(
      state,
      selected,
      scope: scope,
      onlyFolderRole: 'junk',
    );
    await _moveTargetsByRole(
      state,
      targets,
      role: 'inbox',
      action: 'move',
      leaveCurrentView: true,
      clearTrashedAt: true,
      apply: apply,
      currentState: currentState,
    );
  }

  /// Pins selected senders or domains to [bucket] and updates matching mail.
  Future<void> markFocusBucket(
    MailboxState state,
    FocusBucket bucket, {
    AddressMatchScope scope = AddressMatchScope.sender,
    required MailboxMutationApply apply,
  }) async {
    final List<MailMessage> targets = _actionTargets(state);
    if (targets.isEmpty) {
      return;
    }

    final Set<String> touchedKeys = <String>{};
    for (final MailMessage message in targets) {
      final String sender = normalizeFocusSender(message.fromAddress);
      if (sender.isEmpty) {
        continue;
      }
      if (scope == AddressMatchScope.domain) {
        final String? domain = domainFromFocusSender(sender);
        if (domain == null || domain.isEmpty) {
          continue;
        }
        touchedKeys.add(_touchKey(message.accountId, scope, domain));
        await _repository.upsertFocusRule(
          FocusRule(
            id: focusDomainRuleId(
              accountId: message.accountId,
              domain: domain,
            ),
            accountId: message.accountId,
            pattern: domain,
            matchType: FocusRuleMatchType.domain,
            bucket: bucket,
          ),
        );
      } else {
        touchedKeys.add(_touchKey(message.accountId, scope, sender));
        await _repository.upsertFocusRule(
          FocusRule(
            id: focusSenderRuleId(
              accountId: message.accountId,
              sender: sender,
            ),
            accountId: message.accountId,
            pattern: sender,
            matchType: FocusRuleMatchType.sender,
            bucket: bucket,
          ),
        );
      }
      await _repository.updateMessageFocusBucket(message.id, bucket);
    }

    if (touchedKeys.isEmpty) {
      return;
    }

    final FocusOverrideRegistry overrides = FocusOverrideRegistry(
      rules: await _repository.listFocusRules(),
    );
    await _repository.reclassifyFocusBuckets((MailMessage message) {
      final String sender = normalizeFocusSender(message.fromAddress);
      final String? domain = domainFromFocusSender(sender);
      final bool touched =
          touchedKeys.contains(
            _touchKey(message.accountId, AddressMatchScope.sender, sender),
          ) ||
          (domain != null &&
              touchedKeys.contains(
                _touchKey(message.accountId, AddressMatchScope.domain, domain),
              ));
      if (!touched) {
        return message.bucket;
      }
      return RuleBasedFocusScorer(
        overrides: overrides,
        accountId: message.accountId,
      ).score(
        MailMessageDraft(
          fromAddress: message.fromAddress,
          subject: message.subject,
          headers: focusHeadersFromRaw(message.rawHeaders),
        ),
      );
    });

    await apply(const MailboxMutationResult(shouldRefresh: true));
  }

  /// Resolves a system folder by role, optionally creating it after confirmation.
  Future<MailFolder?> ensureSystemFolder({
    required MailboxState state,
    required String accountId,
    required String role,
    SystemFolderConfirm? confirmCreate,
    required MailboxMutationApply apply,
  }) async {
    final MailFolder? existing = await _repository.resolveFolderByRole(
      accountId,
      role,
    );
    if (existing != null) {
      return existing;
    }

    final SystemFolderConfirm? confirm =
        confirmCreate ?? onConfirmCreateSystemFolder;
    if (confirm == null) {
      return null;
    }

    final String displayName = systemFolderDisplayName(role);
    final bool approved = await confirm(accountId, displayName);
    if (!approved) {
      return null;
    }

    final MailProvider? provider = await _resolveProvider(accountId);
    if (provider == null) {
      apply(
        MailboxMutationResult(
          errorMessage: 'No mail provider configured for account $accountId.',
        ),
      );
      return null;
    }

    try {
      final String? canonicalRole = _canonicalSystemRole(role);
      final RemoteFolder remote = await provider.createFolder(
        displayName: displayName,
        role: canonicalRole,
      );
      final MailFolder folder = MailFolder(
        id: MailFolder.localId(
          accountId: accountId,
          remoteId: remote.providerId,
          role: remote.role ?? canonicalRole,
        ),
        accountId: accountId,
        name: remote.name.isNotEmpty ? remote.name : displayName,
        remoteId: remote.providerId,
        role: remote.role ?? canonicalRole,
        parentRemoteId: remote.parentProviderId,
        unreadCount: remote.unreadCount,
        totalCount: remote.totalCount,
      );
      await _repository.upsertFolders(<MailFolder>[folder]);
      final List<MailFolder> folders = await _repository.listFolders();
      apply(MailboxMutationResult(folders: folders));
      return folder;
    } catch (error) {
      apply(
        MailboxMutationResult(
          errorMessage: 'Could not create $displayName folder: $error',
        ),
      );
      return null;
    } finally {
      await provider.dispose();
    }
  }

  static String systemFolderDisplayName(String role) {
    switch (role.trim().toLowerCase()) {
      case 'trash':
      case 'deleteditems':
      case 'deleted':
        return 'Trash';
      case 'junk':
      case 'junkemail':
      case 'spam':
        return 'Junk';
      case 'archive':
        return 'Archive';
      default:
        final String trimmed = role.trim();
        if (trimmed.isEmpty) {
          return 'Folder';
        }
        return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
    }
  }

  List<MailMessage> _actionTargets(MailboxState state) {
    if (state.selectedMessageIds.isNotEmpty) {
      final Set<String> ids = state.selectedMessageIds;
      return state.messages
          .where((MailMessage message) => ids.contains(message.id))
          .toList(growable: false);
    }
    final MailMessage? selected = state.selectedMessage;
    if (selected == null) {
      return const <MailMessage>[];
    }
    return <MailMessage>[selected];
  }

  String _touchKey(String accountId, AddressMatchScope scope, String pattern) {
    return '$accountId\u0000${scope.name}\u0000$pattern';
  }

  Future<List<MailMessage>> _expandAddressScope(
    MailboxState state,
    List<MailMessage> selected, {
    required AddressMatchScope scope,
    String? onlyFolderRole,
  }) async {
    if (selected.isEmpty || scope == AddressMatchScope.sender) {
      return selected;
    }

    final Set<String> accountDomains = <String>{};
    for (final MailMessage message in selected) {
      final String? domain = domainFromFocusSender(message.fromAddress);
      if (domain == null || domain.isEmpty) {
        continue;
      }
      accountDomains.add('${message.accountId}\u0000$domain');
    }
    if (accountDomains.isEmpty) {
      return selected;
    }

    final Set<String> seen = <String>{};
    final List<MailMessage> expanded = <MailMessage>[];
    for (final String key in accountDomains) {
      final int sep = key.indexOf('\u0000');
      final String accountId = key.substring(0, sep);
      final String domain = key.substring(sep + 1);
      final List<MailMessage> candidates = await _repository.listMessages(
        MessageQuery(accountId: accountId, includeTrashed: true),
      );
      for (final MailMessage message in candidates) {
        if (domainFromFocusSender(message.fromAddress) != domain) {
          continue;
        }
        if (onlyFolderRole != null &&
            !_messageFolderHasRole(state, message, onlyFolderRole)) {
          continue;
        }
        if (seen.add(message.id)) {
          expanded.add(message);
        }
      }
    }
    return expanded.isEmpty ? selected : expanded;
  }

  bool _messageFolderHasRole(
    MailboxState state,
    MailMessage message,
    String role,
  ) {
    final String? folderId = message.folderId;
    if (folderId == null) {
      return false;
    }
    for (final MailFolder folder in state.folders) {
      if (folder.id != folderId) {
        continue;
      }
      final String normalized = (folder.role ?? '').trim().toLowerCase();
      final String want = role.trim().toLowerCase();
      if (want == 'junk') {
        return normalized == 'junk' ||
            normalized == 'junkemail' ||
            normalized == 'spam' ||
            _isJunkFolderName(folder.name);
      }
      return normalized == want;
    }
    return false;
  }

  Future<void> _moveTargetsByRole(
    MailboxState state,
    List<MailMessage> targets, {
    required String role,
    required String action,
    required bool leaveCurrentView,
    int? trashedAt,
    bool clearTrashedAt = false,
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    final Map<String, List<MailMessage>> byAccount =
        <String, List<MailMessage>>{};
    for (final MailMessage message in targets) {
      byAccount
          .putIfAbsent(message.accountId, () => <MailMessage>[])
          .add(message);
    }

    final List<MailMessage> previousMessages = state.messages;
    final List<MailFolder> previousFolders = state.folders;
    final List<String> softErrors = <String>[];
    final List<MailMessage> moved = <MailMessage>[];
    final Map<String, MailFolder> destinationByAccount = <String, MailFolder>{};

    for (final MapEntry<String, List<MailMessage>> entry in byAccount.entries) {
      MailFolder? destination = await _repository.resolveFolderByRole(
        entry.key,
        role,
      );
      if (destination == null && _isCreatableSystemRole(role)) {
        destination = await ensureSystemFolder(
          state: currentState(),
          accountId: entry.key,
          role: role,
          apply: apply,
        );
      }
      if (destination == null) {
        softErrors.add('No $role folder for account ${entry.key}.');
        continue;
      }
      destinationByAccount[entry.key] = destination;
      moved.addAll(entry.value);
    }

    if (moved.isEmpty) {
      apply(
        MailboxMutationResult(
          errorMessage: softErrors.isEmpty
              ? 'Could not resolve destination folder.'
              : softErrors.first,
        ),
      );
      return;
    }

    final MailboxState latestBeforeOptimistic = currentState();
    final String? primaryDestinationId =
        destinationByAccount[moved.first.accountId]?.id;
    _applyOptimisticMove(
      latestBeforeOptimistic,
      moved,
      destinationFolderId: primaryDestinationId ?? moved.first.folderId ?? '',
      leaveCurrentView: leaveCurrentView,
      trashedAt: trashedAt,
      clearTrashedAt: clearTrashedAt,
      perMessageDestination: <String, String>{
        for (final MailMessage message in moved)
          message.id: destinationByAccount[message.accountId]!.id,
      },
      apply: apply,
      currentState: currentState,
    );

    try {
      for (final MapEntry<String, List<MailMessage>> entry
          in byAccount.entries) {
        final MailFolder? destination = destinationByAccount[entry.key];
        if (destination == null) {
          continue;
        }
        await _repository.moveMessagesLocal(
          entry.value
              .map((MailMessage message) => message.id)
              .toList(growable: false),
          destination.id,
          trashedAt: trashedAt,
          clearTrashedAt: clearTrashedAt,
        );
      }
    } catch (error) {
      apply(
        MailboxMutationResult(
          messages: previousMessages,
          folders: previousFolders,
          errorMessage: 'Could not update messages: $error',
        ),
      );
      return;
    }

    for (final MapEntry<String, List<MailMessage>> entry in byAccount.entries) {
      final MailFolder? destination = destinationByAccount[entry.key];
      if (destination == null) {
        continue;
      }
      softErrors.addAll(
        await _enqueueMove(
          entry.value,
          targetFolder: destination,
          action: action,
          folders: currentState().folders,
        ),
      );
    }

    if (softErrors.isNotEmpty) {
      apply(MailboxMutationResult(errorMessage: softErrors.first));
    }
  }

  Future<void> _hardDeleteTargets(
    MailboxState state,
    List<MailMessage> targets, {
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) async {
    final List<MailMessage> previousMessages = state.messages;
    final List<MailFolder> previousFolders = state.folders;
    _applyOptimisticRemoval(
      state,
      targets,
      apply: apply,
      currentState: currentState,
    );

    try {
      await _repository.hardDeleteLocalBulk(
        targets
            .map((MailMessage message) => message.id)
            .toList(growable: false),
      );
    } catch (error) {
      apply(
        MailboxMutationResult(
          messages: previousMessages,
          folders: previousFolders,
          errorMessage: 'Could not permanently delete: $error',
        ),
      );
      return;
    }

    final List<String> softErrors = await _enqueueDelete(
      targets,
      folders: currentState().folders,
    );
    if (softErrors.isNotEmpty) {
      apply(
        MailboxMutationResult(
          errorMessage:
              'Deleted locally. Server sync queued with warnings: ${softErrors.first}',
        ),
      );
    }
  }

  void _applyOptimisticMove(
    MailboxState state,
    List<MailMessage> targets, {
    required String destinationFolderId,
    required bool leaveCurrentView,
    int? trashedAt,
    bool clearTrashedAt = false,
    Map<String, String>? perMessageDestination,
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) {
    if (leaveCurrentView) {
      _applyOptimisticRemoval(
        state,
        targets,
        apply: apply,
        currentState: currentState,
      );
      return;
    }
    final Set<String> idSet = targets
        .map((MailMessage message) => message.id)
        .toSet();
    final List<MailMessage> patched = state.messages
        .map((MailMessage message) {
          if (!idSet.contains(message.id)) {
            return message;
          }
          final String nextFolder =
              perMessageDestination?[message.id] ?? destinationFolderId;
          return message.copyWith(
            folderId: nextFolder,
            trashedAt: trashedAt,
            clearTrashedAt: clearTrashedAt,
          );
        })
        .toList(growable: false);
    apply(
      MailboxMutationResult(
        messages: patched,
        clearSelectedMessageIds: true,
        clearError: true,
      ),
    );
  }

  void _applyOptimisticRemoval(
    MailboxState state,
    List<MailMessage> targets, {
    required MailboxMutationApply apply,
    required MailboxState Function() currentState,
  }) {
    final Set<String> removedIds = targets
        .map((MailMessage message) => message.id)
        .toSet();
    final List<MailMessage> previous = state.messages;
    final List<MailMessage> next = previous
        .where((MailMessage message) => !removedIds.contains(message.id))
        .toList(growable: false);
    final String? nextSelection = _selectionAfterRemoval(
      state,
      previous,
      removedIds,
    );
    final List<MailFolder> patchedFolders = _foldersAfterRemoval(
      state,
      targets,
    );
    apply(
      MailboxMutationResult(
        messages: next,
        folders: patchedFolders,
        selectedMessageId: nextSelection,
        clearSelectedMessageId: nextSelection == null,
        clearSelectedMessageIds: true,
        clearError: true,
        clearBodyError: true,
        fetchBodyMessageId: nextSelection,
      ),
    );
  }

  String? _selectionAfterRemoval(
    MailboxState state,
    List<MailMessage> previousMessages,
    Set<String> removedIds,
  ) {
    int anchorIndex = -1;
    final String? primaryId = state.selectedMessageId;
    if (primaryId != null) {
      anchorIndex = previousMessages.indexWhere(
        (MailMessage message) => message.id == primaryId,
      );
      if (anchorIndex >= 0 && !removedIds.contains(primaryId)) {
        return primaryId;
      }
    }
    if (anchorIndex < 0) {
      for (int i = 0; i < previousMessages.length; i++) {
        if (removedIds.contains(previousMessages[i].id)) {
          anchorIndex = i;
          break;
        }
      }
    }
    if (anchorIndex < 0) {
      return null;
    }
    for (int i = anchorIndex + 1; i < previousMessages.length; i++) {
      if (!removedIds.contains(previousMessages[i].id)) {
        return previousMessages[i].id;
      }
    }
    for (int i = anchorIndex - 1; i >= 0; i--) {
      if (!removedIds.contains(previousMessages[i].id)) {
        return previousMessages[i].id;
      }
    }
    return null;
  }

  List<MailFolder> _foldersAfterRemoval(
    MailboxState state,
    List<MailMessage> removed,
  ) {
    final Map<String, int> unreadDelta = <String, int>{};
    final Map<String, int> totalDelta = <String, int>{};
    for (final MailMessage message in removed) {
      final String? folderId = message.folderId;
      if (folderId == null) {
        continue;
      }
      totalDelta[folderId] = (totalDelta[folderId] ?? 0) - 1;
      if (message.unread) {
        unreadDelta[folderId] = (unreadDelta[folderId] ?? 0) - 1;
      }
    }
    if (unreadDelta.isEmpty && totalDelta.isEmpty) {
      return state.folders;
    }
    return state.folders
        .map((MailFolder folder) {
          final int unread = unreadDelta[folder.id] ?? 0;
          final int total = totalDelta[folder.id] ?? 0;
          if (unread == 0 && total == 0) {
            return folder;
          }
          return MailFolder(
            id: folder.id,
            accountId: folder.accountId,
            name: folder.name,
            remoteId: folder.remoteId,
            role: folder.role,
            parentRemoteId: folder.parentRemoteId,
            unreadCount: folder.unreadCount == null
                ? null
                : (folder.unreadCount! + unread).clamp(0, 1 << 30),
            totalCount: folder.totalCount == null
                ? null
                : (folder.totalCount! + total).clamp(0, 1 << 30),
          );
        })
        .toList(growable: false);
  }

  bool _messageLeavesCurrentView(
    MailboxState state, {
    required String destinationFolderId,
    required int? trashedAt,
    required bool clearTrashedAt,
    required bool hardDelete,
  }) {
    if (hardDelete) {
      return true;
    }
    if (!state.unified &&
        state.folderId != null &&
        state.folderId != destinationFolderId) {
      return true;
    }
    if (trashedAt != null && !_isTrashFolder(state.selectedFolder)) {
      return true;
    }
    if (clearTrashedAt && _isTrashFolder(state.selectedFolder)) {
      return true;
    }
    return false;
  }

  bool _isJunkFolderName(String? name) {
    final String normalized = (name ?? '').trim().toLowerCase();
    return normalized == 'junk' ||
        normalized == 'spam' ||
        normalized == 'junk email' ||
        normalized == 'junk e-mail' ||
        normalized == '[gmail]/spam';
  }

  bool _isTrashFolder(MailFolder? folder) {
    if (folder == null) {
      return false;
    }
    final String role = (folder.role ?? '').trim().toLowerCase();
    if (role == 'trash' || role == 'deleteditems' || role == 'deleted') {
      return true;
    }
    if (role.isNotEmpty) {
      return false;
    }
    final String name = folder.name.trim().toLowerCase();
    return name == 'trash' ||
        name == 'deleted items' ||
        name == 'deleted' ||
        name == 'bin' ||
        name == '[gmail]/trash';
  }

  static bool _isCreatableSystemRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'trash':
      case 'deleteditems':
      case 'deleted':
      case 'junk':
      case 'junkemail':
      case 'spam':
      case 'archive':
        return true;
      default:
        return false;
    }
  }

  static String? _canonicalSystemRole(String role) {
    switch (role.trim().toLowerCase()) {
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
      default:
        return role.trim().isEmpty ? null : role.trim().toLowerCase();
    }
  }

  MailFolder? _folderById(MailboxState state, String folderId) {
    for (final MailFolder folder in state.folders) {
      if (folder.id == folderId) {
        return folder;
      }
    }
    return null;
  }

  Future<String?> _folderRemoteIdForMessage(
    MailMessage message, {
    required List<MailFolder> folders,
  }) async {
    final String? folderId = message.folderId;
    if (folderId == null || folderId.isEmpty) {
      return null;
    }
    final MailFolder? fromRepo = await _repository.getFolder(folderId);
    if (fromRepo != null) {
      return fromRepo.remoteId;
    }
    for (final MailFolder folder in folders) {
      if (folder.id == folderId) {
        return folder.remoteId;
      }
    }
    return null;
  }

  Future<void> _enqueuePushMessageAction({
    required String accountId,
    required Map<String, Object?> payload,
  }) async {
    await _repository.enqueueSyncJob(
      accountId: accountId,
      type: 'push_message_action',
      payloadJson: jsonEncode(payload),
    );
    final SyncEngine? engine = _syncEngine;
    if (engine != null) {
      unawaited(engine.kick());
    }
  }

  Future<List<String>> _enqueueStarred(
    List<MailMessage> messages, {
    required bool starred,
  }) async {
    final List<String> errors = <String>[];
    for (final MailMessage message in messages) {
      final String? providerId = message.providerId;
      if (providerId == null || providerId.isEmpty) {
        errors.add(
          'Message ${message.id} has no provider id; skipped remote sync.',
        );
        continue;
      }
      await _enqueuePushMessageAction(
        accountId: message.accountId,
        payload: <String, Object?>{
          'messageId': message.id,
          'providerId': providerId,
          'action': 'star',
          'starred': starred,
        },
      );
    }
    return errors;
  }

  Future<List<String>> _enqueueReadState(
    List<MailMessage> messages, {
    required bool isRead,
    required List<MailFolder> folders,
  }) async {
    final List<String> errors = <String>[];
    for (final MailMessage message in messages) {
      final String? providerId = message.providerId;
      if (providerId == null || providerId.isEmpty) {
        continue;
      }
      final String? folderRemoteId = await _folderRemoteIdForMessage(
        message,
        folders: folders,
      );
      await _enqueuePushMessageAction(
        accountId: message.accountId,
        payload: <String, Object?>{
          'messageId': message.id,
          'providerId': providerId,
          'action': 'read',
          'isRead': isRead,
          'folderRemoteId': folderRemoteId,
        },
      );
    }
    return errors;
  }

  Future<List<String>> _enqueueMove(
    List<MailMessage> messages, {
    required MailFolder targetFolder,
    required String action,
    required List<MailFolder> folders,
  }) async {
    final List<String> errors = <String>[];
    for (final MailMessage message in messages) {
      final String? providerId = message.providerId;
      if (providerId == null || providerId.isEmpty) {
        errors.add(
          'Message ${message.id} has no provider id; skipped remote sync.',
        );
        continue;
      }
      final String? sourceFolderRemoteId = await _folderRemoteIdForMessage(
        message,
        folders: folders,
      );
      await _enqueuePushMessageAction(
        accountId: message.accountId,
        payload: <String, Object?>{
          'messageId': message.id,
          'providerId': providerId,
          'action': action,
          'folderRemoteId': targetFolder.remoteId,
          'folderId': targetFolder.id,
          'sourceFolderRemoteId': sourceFolderRemoteId,
        },
      );
    }
    return errors;
  }

  Future<List<String>> _enqueueDelete(
    List<MailMessage> messages, {
    required List<MailFolder> folders,
  }) async {
    final List<String> errors = <String>[];
    for (final MailMessage message in messages) {
      final String? providerId = message.providerId;
      if (providerId == null || providerId.isEmpty) {
        errors.add(
          'Message ${message.id} has no provider id; skipped remote sync.',
        );
        continue;
      }
      final String? folderRemoteId = await _folderRemoteIdForMessage(
        message,
        folders: folders,
      );
      await _enqueuePushMessageAction(
        accountId: message.accountId,
        payload: <String, Object?>{
          'messageId': message.id,
          'providerId': providerId,
          'action': 'delete',
          'permanent': true,
          'folderRemoteId': folderRemoteId,
        },
      );
    }
    return errors;
  }

  List<MailFolder> _foldersWithUnreadDelta(
    MailboxState state,
    List<MailMessage> changedMessages, {
    required bool unread,
  }) {
    final Map<String, int> folderDelta = <String, int>{};
    for (final MailMessage message in changedMessages) {
      if (message.unread == unread) {
        continue;
      }
      final String? folderId = _resolveFolderIdForUnread(state, message);
      if (folderId == null) {
        continue;
      }
      final int delta = unread ? 1 : -1;
      folderDelta[folderId] = (folderDelta[folderId] ?? 0) + delta;
    }
    if (folderDelta.isEmpty) {
      return state.folders;
    }
    return state.folders
        .map((MailFolder folder) {
          final int? delta = folderDelta[folder.id];
          if (delta == null || delta == 0) {
            return folder;
          }
          final int current = folder.unreadCount ?? 0;
          return MailFolder(
            id: folder.id,
            accountId: folder.accountId,
            name: folder.name,
            remoteId: folder.remoteId,
            role: folder.role,
            parentRemoteId: folder.parentRemoteId,
            unreadCount: (current + delta).clamp(0, 1 << 30),
            totalCount: folder.totalCount,
          );
        })
        .toList(growable: false);
  }

  /// Prefer the message's folder, then the open folder, then the account inbox.
  String? _resolveFolderIdForUnread(MailboxState state, MailMessage message) {
    final String? fromMessage = message.folderId?.trim();
    if (fromMessage != null && fromMessage.isNotEmpty) {
      return fromMessage;
    }
    final String? selected = state.folderId?.trim();
    if (selected != null &&
        selected.isNotEmpty &&
        (state.accountId == null || state.accountId == message.accountId)) {
      return selected;
    }
    final String inboxId = MailFolder.inboxId(message.accountId);
    for (final MailFolder folder in state.folders) {
      if (folder.id == inboxId ||
          (folder.accountId == message.accountId && folder.isInbox)) {
        return folder.id;
      }
    }
    return null;
  }
}
