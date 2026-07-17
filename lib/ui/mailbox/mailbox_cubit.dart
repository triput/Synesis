// ==============================================================================
// File: lib/ui/mailbox/mailbox_cubit.dart
// Description: Cubit façade for mailbox navigation, selection, and refresh
// Component: Bloc / UI
// Version: 1.4 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/domain/address_match_scope.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/mailbox/mailbox_mutation_result.dart';
import 'package:bytemail/mailbox/message_action_service.dart';
import 'package:bytemail/mailbox/message_body_cache.dart';
import 'package:bytemail/mailbox/message_list_projector.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/ui/mailbox/mailbox_state.dart';

export 'package:bytemail/mailbox/message_action_service.dart'
    show SystemFolderConfirm;

class MailboxCubit extends Cubit<MailboxState> {
  MailboxCubit({
    required MailRepository repository,
    required AppSettingsCubit settingsCubit,
    required MessageActionService actions,
    required MessageBodyCache bodyCache,
    SyncEngine? syncEngine,
    SystemFolderConfirm? onConfirmCreateSystemFolder,
  }) : _repository = repository,
       _settingsCubit = settingsCubit,
       _actions = actions,
       _bodyCache = bodyCache,
       _syncEngine = syncEngine,
       super(const MailboxState()) {
    if (onConfirmCreateSystemFolder != null) {
      _actions.onConfirmCreateSystemFolder = onConfirmCreateSystemFolder;
    }
    _settingsSub = _settingsCubit.stream.listen((_) => refresh());
    unawaited(refresh());
  }

  final MailRepository _repository;
  final AppSettingsCubit _settingsCubit;
  final MessageActionService _actions;
  final MessageBodyCache _bodyCache;
  final SyncEngine? _syncEngine;

  StreamSubscription<Object?>? _dbSub;
  StreamSubscription<AppSettingsState>? _settingsSub;
  Timer? _snoozeResurfaceTimer;

  /// When set (typically by the workspace UI), missing trash/junk/archive
  /// folders can be created after user confirmation.
  SystemFolderConfirm? get onConfirmCreateSystemFolder =>
      _actions.onConfirmCreateSystemFolder;

  set onConfirmCreateSystemFolder(SystemFolderConfirm? value) {
    _actions.onConfirmCreateSystemFolder = value;
  }

  Future<void> attachDbWatch() async {
    await _dbSub?.cancel();
    _dbSub = _repository.watchChanges().listen((_) => refresh());
  }

  Future<void> refresh() async {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      await _repository.clearExpiredSnoozes();
      await _repository.recountUnreadCounts();
      final accounts = await _repository.listAccounts();
      final folders = await _repository.listFolders();
      final focusEnabled = _settingsCubit.state.focusEnabledForContext(
        isUnified: state.unified,
        accountId: state.accountId,
      );
      final bool includeTrashed = _isTrashFolder(state.selectedFolder);
      final MessageQuery messageQuery = _buildMessageQuery(
        focusEnabled: focusEnabled,
        includeTrashed: includeTrashed,
      );
      final messages = await _repository.listMessages(messageQuery);
      final queued = await _repository.countQueuedOutbox();
      final failed = await _repository.countFailedOutbox();
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          accounts: accounts,
          folders: folders,
          messages: messages,
          isLoading: false,
          queuedOutboxCount: queued,
          failedOutboxCount: failed,
          syncStatusLabel: await _repository.syncStatusLabel(),
          threadDisplayMode: _settingsCubit.state.threadDisplayMode,
        ),
      );
      final MailMessage? selected = state.selectedMessage;
      if (selected != null) {
        unawaited(_ensureBodyCached(selected.id));
      }
      unawaited(_scheduleSnoozeResurface());
    } catch (e) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(isLoading: false, errorMessage: e.toString()));
    }
  }

  /// Builds the repository query from navigation + virtual-view + user filter.
  MessageQuery _buildMessageQuery({
    required bool focusEnabled,
    required bool includeTrashed,
  }) {
    final MailboxVirtualView view = state.virtualView;
    final bool starredOnly = view == MailboxVirtualView.starred;
    final bool pinnedOnly = view == MailboxVirtualView.pinned;
    final bool snoozedOnly = view == MailboxVirtualView.snoozed;

    return MessageQuery(
      accountId: state.unified ? null : state.accountId,
      folderId: state.unified ? null : state.folderId,
      focusFilter: focusEnabled ? state.focusFilter : null,
      userFilter: state.userFilter,
      starredOnly: starredOnly,
      pinnedOnly: pinnedOnly,
      snoozedOnly: snoozedOnly,
      excludeSnoozed: !snoozedOnly,
      includeTrashed: includeTrashed,
    );
  }

  Future<void> selectUnified() async {
    emit(
      state.copyWith(
        unified: true,
        clearAccountId: true,
        clearFolderId: true,
        clearSelectedMessageId: true,
        clearSelectedMessageIds: true,
        focusFilter: FocusBucket.focused,
        virtualView: MailboxVirtualView.none,
      ),
    );
    await refresh();
  }

  Future<void> selectAccount(String accountId) async {
    final String inboxId = MailFolder.inboxId(accountId);
    emit(
      state.copyWith(
        unified: false,
        accountId: accountId,
        folderId: inboxId,
        clearSelectedMessageId: true,
        clearSelectedMessageIds: true,
        focusFilter: FocusBucket.focused,
        virtualView: MailboxVirtualView.none,
      ),
    );
    await refresh();
    unawaited(_syncSelectedFolder());
  }

  Future<void> selectFolder(String accountId, String folderId) async {
    emit(
      state.copyWith(
        unified: false,
        accountId: accountId,
        folderId: folderId,
        clearSelectedMessageId: true,
        clearSelectedMessageIds: true,
        focusFilter: FocusBucket.focused,
        expandedAccountIds: <String>{...state.expandedAccountIds, accountId},
        virtualView: MailboxVirtualView.none,
      ),
    );
    await refresh();
    unawaited(_syncSelectedFolder());
  }

  void toggleAccountExpanded(String accountId) {
    final Set<String> next = Set<String>.from(state.expandedAccountIds);
    if (next.contains(accountId)) {
      next.remove(accountId);
    } else {
      next.add(accountId);
    }
    emit(state.copyWith(expandedAccountIds: next));
  }

  void collapseAllFolders() {
    if (state.expandedAccountIds.isEmpty) {
      return;
    }
    emit(state.copyWith(expandedAccountIds: const <String>{}));
  }

  Future<void> selectMessage(String id) async {
    emit(
      state.copyWith(
        selectedMessageId: id,
        clearSelectedMessageIds: true,
        clearError: true,
        clearBodyError: true,
      ),
    );
    await _ensureBodyCached(id);
  }

  /// Select a row with optional Ctrl (toggle) or Shift (range) modifiers.
  Future<void> selectMessageWithModifiers(
    String id, {
    bool ctrl = false,
    bool shift = false,
  }) async {
    if (ctrl) {
      final Set<String> next = Set<String>.from(state.selectedMessageIds);
      if (next.contains(id)) {
        next.remove(id);
      } else {
        next.add(id);
      }
      emit(
        state.copyWith(
          selectedMessageId: id,
          selectedMessageIds: next,
          clearError: true,
          clearBodyError: true,
        ),
      );
      await _ensureBodyCached(id);
      return;
    }
    if (shift && state.selectedMessageId != null) {
      final int anchorIndex = state.messages.indexWhere(
        (MailMessage m) => m.id == state.selectedMessageId,
      );
      final int targetIndex = state.messages.indexWhere(
        (MailMessage m) => m.id == id,
      );
      if (anchorIndex != -1 && targetIndex != -1) {
        final int start = anchorIndex < targetIndex ? anchorIndex : targetIndex;
        final int end = anchorIndex < targetIndex ? targetIndex : anchorIndex;
        final Set<String> range = <String>{
          for (int i = start; i <= end; i++) state.messages[i].id,
        };
        emit(
          state.copyWith(
            selectedMessageId: id,
            selectedMessageIds: range,
            clearError: true,
            clearBodyError: true,
          ),
        );
        await _ensureBodyCached(id);
        return;
      }
    }
    await selectMessage(id);
  }

  void clearBulkSelection() {
    if (state.selectedMessageIds.isEmpty) {
      return;
    }
    emit(state.copyWith(clearSelectedMessageIds: true));
  }

  Future<void> setUnread(String messageId, bool unread) async {
    await _actions.setUnread(
      state,
      messageId,
      unread,
      apply: _applyMutation,
      currentState: () => state,
    );
  }

  Future<void> setUnreadBulk(List<String> messageIds, bool unread) async {
    await _actions.setUnreadBulk(
      state,
      messageIds,
      unread,
      apply: _applyMutation,
      currentState: () => state,
    );
  }

  Future<void> toggleSelectedUnread() async {
    await _actions.toggleSelectedUnread(
      state,
      apply: _applyMutation,
      currentState: () => state,
    );
  }

  Future<void> toggleStarSelected() async {
    await _actions.toggleStarSelected(
      state,
      apply: _applyMutation,
      currentState: () => state,
    );
  }

  Future<void> setStarredBulk(List<String> ids, bool starred) async {
    await _actions.setStarredBulk(
      state,
      ids,
      starred,
      apply: _applyMutation,
      currentState: () => state,
    );
  }

  Future<void> setPinned(String messageId, bool pinned) async {
    await _actions.setPinned(
      state,
      messageId,
      pinned,
      apply: _applyMutation,
    );
  }

  Future<void> togglePinSelected() async {
    await _actions.togglePinSelected(
      state,
      apply: _applyMutation,
    );
  }

  Future<void> setPinnedBulk(List<String> ids, bool pinned) async {
    await _actions.setPinnedBulk(
      state,
      ids,
      pinned,
      apply: _applyMutation,
    );
  }

  Future<void> snoozeSelected({required int snoozedUntil}) async {
    await _actions.snoozeSelected(
      state,
      snoozedUntil: snoozedUntil,
      apply: _applyMutation,
    );
    await _scheduleSnoozeResurface();
  }

  Future<void> clearSnoozeSelected() async {
    await _actions.clearSnoozeSelected(
      state,
      apply: _applyMutation,
    );
    await _scheduleSnoozeResurface();
  }

  Future<void> archiveSelected() async {
    await _actions.archiveSelected(
      state,
      apply: _applyMutation,
      currentState: () => state,
    );
  }

  Future<void> deleteSelected({bool permanent = false}) async {
    await _actions.deleteSelected(
      state,
      permanent: permanent,
      viewingTrash: isViewingTrash,
      apply: _applyMutation,
      currentState: () => state,
    );
  }

  Future<void> recoverSelected() async {
    await _actions.recoverSelected(
      state,
      apply: _applyMutation,
      currentState: () => state,
    );
  }

  Future<void> moveSelectedToFolder(String folderId) async {
    await _actions.moveSelectedToFolder(
      state,
      folderId,
      apply: _applyMutation,
      currentState: () => state,
    );
  }

  Future<void> reportJunk({
    AddressMatchScope scope = AddressMatchScope.sender,
  }) async {
    await _actions.reportJunk(
      state,
      scope: scope,
      apply: _applyMutation,
      currentState: () => state,
    );
  }

  Future<void> notJunk({
    AddressMatchScope scope = AddressMatchScope.sender,
  }) async {
    await _actions.notJunk(
      state,
      scope: scope,
      apply: _applyMutation,
      currentState: () => state,
    );
  }

  /// Pins selected senders or domains to [bucket] and updates matching mail.
  Future<void> markFocusBucket(
    FocusBucket bucket, {
    AddressMatchScope scope = AddressMatchScope.sender,
  }) async {
    await _actions.markFocusBucket(
      state,
      bucket,
      scope: scope,
      apply: _applyMutation,
    );
  }

  /// Resolves a system folder by role, optionally creating it after confirmation.
  Future<MailFolder?> ensureSystemFolder({
    required String accountId,
    required String role,
    SystemFolderConfirm? confirmCreate,
  }) {
    return _actions.ensureSystemFolder(
      state: state,
      accountId: accountId,
      role: role,
      confirmCreate: confirmCreate,
      apply: _applyMutation,
    );
  }

  /// Loads raw RFC822 headers for [messageId], preferring local cache.
  Future<void> ensureHeadersCached(String messageId) async {
    await _bodyCache.ensureHeadersCached(
      state,
      messageId,
      apply: _applyMutation,
      isClosed: () => isClosed,
      currentState: () => state,
    );
  }

  bool get isViewingTrash => _isTrashFolder(state.selectedFolder);

  bool get isViewingJunk {
    final String role = (state.selectedFolder?.role ?? '').trim().toLowerCase();
    if (role == 'junk' || role == 'junkemail' || role == 'spam') {
      return true;
    }
    return _isJunkFolderName(state.selectedFolder?.name);
  }

  static String systemFolderDisplayName(String role) {
    return MessageActionService.systemFolderDisplayName(role);
  }

  Future<void> setFocusFilter(FocusBucket bucket) async {
    emit(
      state.copyWith(
        focusFilter: bucket,
        clearSelectedMessageId: true,
        clearSelectedMessageIds: true,
      ),
    );
    await refresh();
  }

  Future<void> setUserFilter(MessageViewFilter filter) async {
    emit(
      state.copyWith(
        userFilter: filter,
        clearSelectedMessageId: true,
        clearSelectedMessageIds: true,
      ),
    );
    await refresh();
  }

  Future<void> clearUserFilter() async {
    if (state.userFilter == null) {
      return;
    }
    emit(
      state.copyWith(
        clearUserFilter: true,
        clearSelectedMessageId: true,
        clearSelectedMessageIds: true,
      ),
    );
    await refresh();
  }

  Future<void> setVirtualView(MailboxVirtualView view) async {
    if (state.virtualView == view) {
      return;
    }
    emit(
      state.copyWith(
        virtualView: view,
        clearSelectedMessageId: true,
        clearSelectedMessageIds: true,
      ),
    );
    await refresh();
  }

  void setDateGrouping(DateGroupingMode mode) {
    if (state.dateGroupingMode == mode) {
      return;
    }
    emit(state.copyWith(dateGroupingMode: mode));
  }

  /// Toggles expansion for an account-scoped thread key.
  ///
  /// Prefer [ThreadItem.expansionKey] (`accountId::threadId`) so identical
  /// remote thread ids on different accounts stay independent.
  void toggleThreadExpanded(String expansionKey) {
    final Set<String> next = Set<String>.from(state.expandedThreadIds);
    if (next.contains(expansionKey)) {
      next.remove(expansionKey);
    } else {
      next.add(expansionKey);
    }
    emit(state.copyWith(expandedThreadIds: next));
  }

  void setSidebarVisible(bool visible) {
    emit(state.copyWith(sidebarVisible: visible));
  }

  /// Re-routes navigation after an account is removed from local storage.
  Future<void> onAccountRemoved(String removedAccountId) async {
    final Set<String> nextExpanded = Set<String>.from(state.expandedAccountIds)
      ..remove(removedAccountId);
    final bool selectedAccountRemoved = state.accountId == removedAccountId;
    final bool selectedFolderRemoved =
        state.folderId != null &&
        state.folders.any(
          (MailFolder folder) =>
              folder.id == state.folderId &&
              folder.accountId == removedAccountId,
        );
    final String? selectedMessageId = state.selectedMessageId;
    final bool primaryMessageRemoved =
        selectedMessageId != null &&
        _messageBelongsToAccount(selectedMessageId, removedAccountId);
    final Set<String> nextBulkIds = state.selectedMessageIds
        .where((String id) => !_messageBelongsToAccount(id, removedAccountId))
        .toSet();
    final bool bulkSelectionChanged =
        nextBulkIds.length != state.selectedMessageIds.length;

    if (selectedAccountRemoved) {
      emit(
        state.copyWith(
          unified: true,
          clearAccountId: true,
          clearFolderId: true,
          clearSelectedMessageId: true,
          clearSelectedMessageIds: true,
          expandedAccountIds: nextExpanded,
        ),
      );
    } else if (selectedFolderRemoved ||
        primaryMessageRemoved ||
        bulkSelectionChanged) {
      emit(
        state.copyWith(
          clearFolderId: selectedFolderRemoved,
          clearSelectedMessageId: primaryMessageRemoved,
          selectedMessageIds: bulkSelectionChanged ? nextBulkIds : null,
          clearSelectedMessageIds: bulkSelectionChanged && nextBulkIds.isEmpty,
          expandedAccountIds: nextExpanded,
        ),
      );
    } else if (nextExpanded.length != state.expandedAccountIds.length) {
      emit(state.copyWith(expandedAccountIds: nextExpanded));
    }
    await refresh();
  }

  FutureOr<void> _applyMutation(MailboxMutationResult result) {
    if (result.shouldRefresh) {
      return refresh();
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          messages: result.messages,
          folders: result.folders,
          selectedMessageId: result.selectedMessageId,
          clearSelectedMessageId: result.clearSelectedMessageId,
          selectedMessageIds: result.selectedMessageIds,
          clearSelectedMessageIds: result.clearSelectedMessageIds,
          errorMessage: result.errorMessage,
          clearError: result.clearError,
          isLoadingBody: result.isLoadingBody,
          isLoadingHeaders: result.isLoadingHeaders,
          bodyErrorMessage: result.bodyErrorMessage,
          clearBodyError: result.clearBodyError,
          headersErrorMessage: result.headersErrorMessage,
          clearHeadersError: result.clearHeadersError,
        ),
      );
      final String? bodyId = result.fetchBodyMessageId;
      if (bodyId != null) {
        unawaited(_ensureBodyCached(bodyId));
      }
    }
  }

  Future<void> _ensureBodyCached(String id) async {
    await _bodyCache.ensureBodyCached(
      state,
      id,
      apply: _applyMutation,
      isClosed: () => isClosed,
      currentState: () => state,
    );
  }

  /// Enqueues a folder (or unified) sync, then refreshes local state.
  ///
  /// Used by pull-to-refresh so [RefreshIndicator] awaits visible feedback.
  /// Unified inbox kicks incremental sync for every account; a single folder
  /// reuses [_syncSelectedFolder]. Always ends with [refresh].
  Future<void> syncCurrentFolder() async {
    final SyncEngine? engine = _syncEngine;
    if (engine != null) {
      if (state.unified) {
        for (final MailAccount account in state.accounts) {
          await engine.enqueueIncremental(account.id);
        }
        if (state.accounts.isNotEmpty) {
          await engine.kick();
        }
      } else {
        await _syncSelectedFolder();
      }
    }
    await refresh();
  }

  Future<void> _syncSelectedFolder() async {
    final SyncEngine? engine = _syncEngine;
    final String? accountId = state.accountId;
    final String? folderId = state.folderId;
    if (engine == null || accountId == null || folderId == null) {
      return;
    }
    final MailFolder? folder = state.selectedFolder;
    // Inbox can sync before the folder row exists locally (Graph bootstrap race).
    final String remoteId =
        folder?.remoteId ??
        (folderId == MailFolder.inboxId(accountId) ? 'inbox' : '');
    if (remoteId.isEmpty) {
      return;
    }
    await engine.enqueueFolderSync(
      accountId,
      folderId: folderId,
      remoteId: remoteId,
    );
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

  bool _messageBelongsToAccount(String messageId, String accountId) {
    for (final MailMessage message in state.messages) {
      if (message.id == messageId && message.accountId == accountId) {
        return true;
      }
    }
    return false;
  }

  Future<void> _scheduleSnoozeResurface() async {
    _snoozeResurfaceTimer?.cancel();
    _snoozeResurfaceTimer = null;
    if (isClosed) {
      return;
    }
    final int? nextExpiry = await _repository.nextSnoozeExpiryMs();
    if (isClosed || nextExpiry == null) {
      return;
    }
    final int nowMs = DateTime.now().millisecondsSinceEpoch;
    final int delayMs = nextExpiry - nowMs;
    if (delayMs <= 0) {
      unawaited(refresh());
      return;
    }
    // Cap very long delays so the timer stays practical; refresh re-schedules.
    final Duration delay = Duration(
      milliseconds: delayMs.clamp(1, 24 * 60 * 60 * 1000),
    );
    _snoozeResurfaceTimer = Timer(delay, () {
      if (!isClosed) {
        unawaited(refresh());
      }
    });
  }

  @override
  Future<void> close() async {
    _snoozeResurfaceTimer?.cancel();
    _snoozeResurfaceTimer = null;
    await _dbSub?.cancel();
    await _settingsSub?.cancel();
    return super.close();
  }
}
