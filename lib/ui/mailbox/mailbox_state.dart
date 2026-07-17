// ==============================================================================
// File: lib/ui/mailbox/mailbox_state.dart
// Description: Mail workspace navigation and selection state
// Component: Bloc / UI
// Version: 1.3 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'package:equatable/equatable.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/mailbox/message_list_projector.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/settings/app_settings_state.dart';

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
    this.isLoadingHeaders = false,
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
  final bool isLoadingHeaders;
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

  MailMessage? get selectedMessage {
    if (messages.isEmpty) return null;
    final match = messages.where((m) => m.id == selectedMessageId);
    return match.isEmpty ? messages.first : match.first;
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
    bool? isLoadingHeaders,
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
  }) {
    return MailboxState(
      unified: unified ?? this.unified,
      accountId: clearAccountId ? null : (accountId ?? this.accountId),
      folderId: clearFolderId ? null : (folderId ?? this.folderId),
      focusFilter: focusFilter ?? this.focusFilter,
      selectedMessageId: clearSelectedMessageId
          ? null
          : (selectedMessageId ?? this.selectedMessageId),
      selectedMessageIds: clearSelectedMessageIds
          ? const <String>{}
          : (selectedMessageIds ?? this.selectedMessageIds),
      sidebarVisible: sidebarVisible ?? this.sidebarVisible,
      accounts: accounts ?? this.accounts,
      folders: folders ?? this.folders,
      expandedAccountIds: expandedAccountIds ?? this.expandedAccountIds,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isLoadingBody: isLoadingBody ?? this.isLoadingBody,
      isLoadingHeaders: isLoadingHeaders ?? this.isLoadingHeaders,
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
    isLoadingHeaders,
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
  ];
}
