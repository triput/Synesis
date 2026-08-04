// ==============================================================================
// File: lib/ui/mailbox/mailbox_state.dart
// Description: Mail workspace navigation and selection state
// Component: Bloc / UI
// Version: 1.4 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-22
// ==============================================================================

import 'package:equatable/equatable.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/mailbox/message_list_projector.dart';
import 'package:synesis/query/message_query.dart';
import 'package:synesis/settings/app_settings_state.dart';

/// Sidebar / toolbar virtual folders that are not real IMAP/Graph folders.
enum MailboxVirtualView {
  none,
  starred,
  pinned,
  snoozed,
}

class MailboxState extends Equatable {
  const MailboxState({
    this.unified = true,
    this.accountId,
    this.folderId,
    this.focusFilter = FocusBucket.focused,
    this.selectedMessageId,
    this.selectedMessageIds = const {},
    this.sidebarVisible = true,
    this.accounts = const [],
    this.folders = const [],
    this.expandedAccountIds = const {},
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingBody = false,
    this.headersLoadingMessageId,
    this.headersErrorMessageId,
    this.errorMessage,
    this.bodyErrorMessage,
    this.headersErrorMessage,
    this.syncStatusLabel = 'Synced · local',
    this.queuedOutboxCount = 0,
    this.failedOutboxCount = 0,
    this.userFilter,
    this.virtualView = MailboxVirtualView.none,
    this.dateGroupingMode = DateGroupingMode.outlookBuckets,
    this.expandedThreadIds = const {},
    this.threadDisplayMode = ThreadDisplayMode.threaded,
    this.stickySelectedMessage,
  });

  final bool unified;
  final String? accountId;
  final String? folderId;
  final FocusBucket focusFilter;
  final String? selectedMessageId;

  /// Multi-select ids for bulk mark read/unread (Ctrl/Shift-click).
  final Set<String> selectedMessageIds;
  final bool sidebarVisible;
  final List<MailAccount> accounts;
  final List<MailFolder> folders;

  /// Account rows that currently show their folder children. Empty = clean sidebar.
  final Set<String> expandedAccountIds;
  final List<MailMessage> messages;
  final bool isLoading;
  final bool isLoadingBody;
  final String? headersLoadingMessageId;
  final String? headersErrorMessageId;
  final String? errorMessage;
  final String? bodyErrorMessage;
  final String? headersErrorMessage;
  final String syncStatusLabel;
  final int queuedOutboxCount;
  final int failedOutboxCount;

  /// Optional user-authored filter stacked on folder/focus scope.
  final MessageViewFilter? userFilter;

  /// Virtual folder overlay (starred / pinned / snoozed).
  final MailboxVirtualView virtualView;

  /// Date section headers for the message list projector.
  final DateGroupingMode dateGroupingMode;

  /// Account-scoped thread expansion keys (`accountId::threadId`).
  final Set<String> expandedThreadIds;

  /// Mirrored from [AppSettingsState.threadDisplayMode] on refresh.
  final ThreadDisplayMode threadDisplayMode;

  /// Last known copy of the selected message (UI-P30), retained after it
  /// drops out of a restrictive filter (e.g. Unread following auto-mark) so
  /// the reading pane keeps showing it instead of clearing or jumping to
  /// another row. Kept in sync with [messages] by [copyWith] whenever the
  /// selected id is present in the latest list; cleared when the selection
  /// is cleared, changed to a different message, or the owning account is
  /// removed.
  final MailMessage? stickySelectedMessage;

  /// Projects [messages] into dated / threaded sections. Keeps raw [messages]
  /// as the source of truth; UI list rewrite (M4) consumes this getter.
  List<MessageListSection> get listSections {
    return MessageListProjector.project(
      messages: messages,
      threadMode: threadDisplayMode,
      dateGrouping: dateGroupingMode,
      expandedThreadIds: expandedThreadIds,
    );
  }

  /// Deduped message ids in projected list order (thread latests + flats).
  /// Used for portrait reading-pane prev/next navigation.
  List<String> get projectedNavigationIds {
    return MessageListProjector.navigationMessageIds(listSections);
  }

  MailFolder? get selectedFolder {
    final String? id = folderId;
    if (id == null) {
      return null;
    }
    for (final MailFolder folder in folders) {
      if (folder.id == id) {
        return folder;
      }
    }
    return null;
  }

  /// The message shown in the reading pane.
  ///
  /// When no message is explicitly selected, defaults to the first message
  /// in the current list (unchanged pre-UI-P30 behavior). When a specific
  /// [selectedMessageId] is set but no longer present in [messages] (e.g. it
  /// dropped out of a restrictive filter like Unread after an auto-mark),
  /// falls back to [stickySelectedMessage] instead of jumping to a different
  /// message or clearing the pane (UI-P30).
  MailMessage? get selectedMessage {
    final String? id = selectedMessageId;
    if (id == null) {
      return messages.isEmpty ? null : messages.first;
    }
    for (final MailMessage message in messages) {
      if (message.id == id) {
        return message;
      }
    }
    final MailMessage? sticky = stickySelectedMessage;
    if (sticky != null && sticky.id == id) {
      return sticky;
    }
    return null;
  }

  List<MailFolder> foldersForAccount(String accountId) {
    return folders
        .where((MailFolder folder) => folder.accountId == accountId)
        .toList(growable: false);
  }

  int unreadForAccount(String accountId) {
    var total = 0;
    for (final MailFolder folder in foldersForAccount(accountId)) {
      total += folder.unreadCount ?? 0;
    }
    return total;
  }

  MailboxState copyWith({
    bool? unified,
    String? accountId,
    bool clearAccountId = false,
    String? folderId,
    bool clearFolderId = false,
    FocusBucket? focusFilter,
    String? selectedMessageId,
    bool clearSelectedMessageId = false,
    Set<String>? selectedMessageIds,
    bool clearSelectedMessageIds = false,
    bool? sidebarVisible,
    List<MailAccount>? accounts,
    List<MailFolder>? folders,
    Set<String>? expandedAccountIds,
    List<MailMessage>? messages,
    bool? isLoading,
    bool? isLoadingBody,
    String? headersLoadingMessageId,
    bool clearHeadersLoading = false,
    String? headersErrorMessageId,
    bool clearHeadersErrorMessageId = false,
    String? errorMessage,
    bool clearError = false,
    String? bodyErrorMessage,
    bool clearBodyError = false,
    String? headersErrorMessage,
    bool clearHeadersError = false,
    String? syncStatusLabel,
    int? queuedOutboxCount,
    int? failedOutboxCount,
    MessageViewFilter? userFilter,
    bool clearUserFilter = false,
    MailboxVirtualView? virtualView,
    DateGroupingMode? dateGroupingMode,
    Set<String>? expandedThreadIds,
    ThreadDisplayMode? threadDisplayMode,
    MailMessage? stickySelectedMessage,
    bool clearStickySelectedMessage = false,
  }) {
    final String? nextSelectedMessageId = clearSelectedMessageId
        ? null
        : (selectedMessageId ?? this.selectedMessageId);
    final List<MailMessage> nextMessages = messages ?? this.messages;

    // UI-P30: keep stickySelectedMessage in sync automatically so callers
    // don't need to thread it through every selection/mutation call site.
    MailMessage? nextSticky;
    if (clearSelectedMessageId || clearStickySelectedMessage) {
      nextSticky = null;
    } else if (stickySelectedMessage != null) {
      nextSticky = stickySelectedMessage;
    } else if (nextSelectedMessageId != null) {
      MailMessage? freshMatch;
      for (final MailMessage candidate in nextMessages) {
        if (candidate.id == nextSelectedMessageId) {
          freshMatch = candidate;
          break;
        }
      }
      if (freshMatch != null) {
        nextSticky = freshMatch;
      } else if (this.stickySelectedMessage?.id == nextSelectedMessageId) {
        // Still the same selection, just dropped from the filtered list —
        // keep the last known copy instead of losing it (UI-P30).
        nextSticky = this.stickySelectedMessage;
      } else {
        nextSticky = null;
      }
    } else {
      nextSticky = null;
    }

    return MailboxState(
      unified: unified ?? this.unified,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
      focusFilter: focusFilter ?? this.focusFilter,
      selectedMessageId: nextSelectedMessageId,
      selectedMessageIds: clearSelectedMessageIds
          ? const <String>{}
          : (selectedMessageIds ?? this.selectedMessageIds),
      sidebarVisible: sidebarVisible ?? this.sidebarVisible,
      accounts: accounts ?? this.accounts,
      folders: folders ?? this.folders,
      expandedAccountIds: expandedAccountIds ?? this.expandedAccountIds,
      messages: nextMessages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingBody: isLoadingBody ?? this.isLoadingBody,
      headersLoadingMessageId: clearHeadersLoading
          ? null
          : (headersLoadingMessageId ?? this.headersLoadingMessageId),
      headersErrorMessageId: clearHeadersErrorMessageId
          ? null
          : (headersErrorMessageId ?? this.headersErrorMessageId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      bodyErrorMessage: clearBodyError
          ? null
          : (bodyErrorMessage ?? this.bodyErrorMessage),
      headersErrorMessage: clearHeadersError
          ? null
          : (headersErrorMessage ?? this.headersErrorMessage),
      syncStatusLabel: syncStatusLabel ?? this.syncStatusLabel,
      queuedOutboxCount: queuedOutboxCount ?? this.queuedOutboxCount,
      failedOutboxCount: failedOutboxCount ?? this.failedOutboxCount,
      userFilter: clearUserFilter ? null : (userFilter ?? this.userFilter),
      virtualView: virtualView ?? this.virtualView,
      dateGroupingMode: dateGroupingMode ?? this.dateGroupingMode,
      expandedThreadIds: expandedThreadIds ?? this.expandedThreadIds,
      threadDisplayMode: threadDisplayMode ?? this.threadDisplayMode,
      stickySelectedMessage: nextSticky,
    );
  }

  @override
  List<Object?> get props => [
    unified,
    accountId,
    folderId,
    focusFilter,
    selectedMessageId,
    selectedMessageIds,
    sidebarVisible,
    accounts,
    folders,
    expandedAccountIds,
    messages,
    isLoading,
    isLoadingBody,
    headersLoadingMessageId,
    headersErrorMessageId,
    errorMessage,
    bodyErrorMessage,
    headersErrorMessage,
    syncStatusLabel,
    queuedOutboxCount,
    failedOutboxCount,
    userFilter,
    virtualView,
    dateGroupingMode,
    expandedThreadIds,
    threadDisplayMode,
    stickySelectedMessage,
  ];
}
