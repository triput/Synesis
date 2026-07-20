// ==============================================================================
// File: lib/ui/shell/mail_workspace.dart
// Description: Multi-pane mailbox workspace driven by MailboxCubit
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/desktop/message_file_service.dart';
import 'package:bytemail/domain/address_match_scope.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/mime/eml_codec.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/ui/branding/bytemail_wordmark.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/ui/mailbox/mailbox_state.dart';
import 'package:bytemail/ui/settings/appearance_sheet.dart';
import 'package:bytemail/ui/settings/notifications_sheet.dart';
import 'package:bytemail/ui/shell/eml_preview_sheet.dart';
import 'package:bytemail/ui/shell/folder_sidebar.dart';
import 'package:bytemail/ui/shell/mail_split_layout.dart';
import 'package:bytemail/ui/shell/keymap_help_sheet.dart';
import 'package:bytemail/ui/shell/mailbox_dialogs.dart';
import 'package:bytemail/ui/shell/mailbox_shortcuts.dart';
import 'package:bytemail/ui/shell/message_list_pane.dart';
import 'package:bytemail/ui/shell/message_headers_sheet.dart';
import 'package:bytemail/ui/shell/reading_pane.dart';
import 'package:bytemail/ui/shell/snooze_dialog.dart';
import 'package:bytemail/ui/account/add_account_sheet.dart';
import 'package:bytemail/ui/compose/compose_prefill.dart';
import 'package:bytemail/ui/compose/compose_sheet.dart';
import 'package:bytemail/ui/outbox/outbox_sheet.dart';
import 'package:bytemail/ui/search/search_sheet.dart';
import 'package:bytemail/ui/sync/sync_status_sheet.dart';
import 'package:bytemail/sync/sync_engine.dart';

class MailWorkspace extends StatefulWidget {
  const MailWorkspace({super.key});

  @override
  State<MailWorkspace> createState() => _MailWorkspaceState();
}

class _MailWorkspaceState extends State<MailWorkspace> {
  late final FocusNode _workspaceFocus = FocusNode(
    debugLabel: 'ByteMailWorkspace',
  );
  bool _syncBusy = false;
  bool _findInMessageRequested = false;

  @override
  void initState() {
    super.initState();
    // Process-level handler: Focus.onKeyEvent alone misses keys when primary
    // focus is null or outside the workspace subtree (common after clicks).
    HardwareKeyboard.instance.addHandler(_onHardwareKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      context.read<MailboxCubit>().onConfirmCreateSystemFolder =
          _confirmCreateSystemFolder;
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onHardwareKey);
    _workspaceFocus.dispose();
    super.dispose();
  }

  bool _onHardwareKey(KeyEvent event) {
    if (!mounted) {
      return false;
    }
    return handleMailboxHardwareKey(
      event,
      context: context,
      actions: MailboxShortcutActions(
        onCompose: () => showComposeSheet(context),
        onSearch: () => showSearchSheet(context),
        onFindInMessage: () {
          setState(() => _findInMessageRequested = true);
        },
        onShowHelp: () {
          unawaited(showKeymapHelpSheet(context));
        },
        onPermanentDelete: (MailboxCubit cubit) {
          unawaited(confirmPermanentDelete(context, cubit));
        },
        onReply: (MailboxCubit cubit, {bool replyAll = false}) {
          _openReply(cubit, replyAll: replyAll);
        },
        onForward: _openForward,
        onSnooze: _openSnooze,
      ),
    );
  }

  Future<bool> _confirmCreateSystemFolder(
    String accountId,
    String roleDisplayName,
  ) {
    final MailboxCubit cubit = context.read<MailboxCubit>();
    return confirmCreateSystemFolder(
      context,
      accountId: accountId,
      roleDisplayName: roleDisplayName,
      accounts: cubit.state.accounts,
    );
  }

  Future<void> _runManualSync() async {
    if (_syncBusy) {
      return;
    }
    setState(() => _syncBusy = true);
    final SyncEngine engine = context.read<SyncEngine>();
    final MailboxCubit cubit = context.read<MailboxCubit>();
    try {
      final List<MailAccount> linked = cubit.state.accounts
          .where((MailAccount a) => a.credentialsRef != null)
          .toList(growable: false);
      if (linked.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No linked accounts to sync. Add a Graph or IMAP account first.',
              ),
            ),
          );
        }
        return;
      }
      for (final MailAccount account in linked) {
        await engine.enqueueIncremental(account.id);
      }
      await engine.kickFresh();
      await cubit.refresh();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(cubit.state.syncStatusLabel)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync error: $error')));
      }
    } finally {
      if (mounted) {
        setState(() => _syncBusy = false);
      }
    }
  }

  Future<void> _openEmlFile() async {
    try {
      final EmlPreview? preview = await openEmlPreview();
      if (preview == null || !mounted) {
        return;
      }
      await showEmlPreviewSheet(context, preview: preview);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to open EML: $error')),
      );
    }
  }

  Future<void> _openSnooze(MailboxCubit cubit) async {
    if (cubit.state.selectedMessage == null &&
        cubit.state.selectedMessageIds.isEmpty) {
      return;
    }
    final int? until = await showSnoozeDialog(context);
    if (until == null || !mounted) {
      return;
    }
    await cubit.snoozeSelected(snoozedUntil: until);
  }

  void _openReply(MailboxCubit cubit, {bool replyAll = false}) {
    final MailMessage? selected = cubit.state.selectedMessage;
    if (selected == null) {
      return;
    }
    final String? ownAddress = _accountAddress(
      cubit.state.accounts,
      selected.accountId,
    );
    unawaited(
      showComposeSheet(
        context,
        prefill: ComposePrefill.reply(
          selected,
          replyAll: replyAll,
          ownAddress: ownAddress,
        ),
      ),
    );
  }

  void _openForward(MailboxCubit cubit) {
    final MailMessage? selected = cubit.state.selectedMessage;
    if (selected == null) {
      return;
    }
    unawaited(
      showComposeSheet(context, prefill: ComposePrefill.forward(selected)),
    );
  }

  String? _accountAddress(List<MailAccount> accounts, String accountId) {
    for (final MailAccount account in accounts) {
      if (account.id == accountId) {
        return account.address;
      }
    }
    return null;
  }

  void _toggleStarForMessage(MailboxCubit cubit, String messageId) {
    MailMessage? target;
    for (final MailMessage message in cubit.state.messages) {
      if (message.id == messageId) {
        target = message;
        break;
      }
    }
    if (target == null) {
      return;
    }
    unawaited(cubit.setStarredBulk(<String>[messageId], !target.starred));
  }

  Future<void> _handleListSwipe(
    MailboxCubit cubit,
    String messageId,
    SwipeListAction action,
  ) async {
    if (action == SwipeListAction.none) {
      return;
    }
    await cubit.selectMessage(messageId);
    if (!mounted) {
      return;
    }
    switch (action) {
      case SwipeListAction.archive:
        await cubit.archiveSelected();
      case SwipeListAction.delete:
        if (cubit.isViewingTrash) {
          await confirmPermanentDelete(context, cubit);
        } else {
          await cubit.deleteSelected();
        }
      case SwipeListAction.star:
        _toggleStarForMessage(cubit, messageId);
      case SwipeListAction.snooze:
        await _openSnooze(cubit);
      case SwipeListAction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MailboxCubit, MailboxState>(
      listenWhen: (MailboxState prev, MailboxState next) =>
          prev.errorMessage != next.errorMessage && next.errorMessage != null,
      listener: (BuildContext context, MailboxState mailbox) {
        final String? message = mailbox.errorMessage;
        if (message == null) {
          return;
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      },
      child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, settings) {
          return Focus(
            focusNode: _workspaceFocus,
            autofocus: true,
            child: BlocBuilder<MailboxCubit, MailboxState>(
              builder: (context, mailbox) {
                final t = tokensOf(context);
                final density = settings.density;
                final cubit = context.read<MailboxCubit>();
                final AppSettingsCubit settingsCubit =
                    context.read<AppSettingsCubit>();
                final focusEnabled = settings.focusEnabledForContext(
                  isUnified: mailbox.unified,
                  accountId: mailbox.accountId,
                );
                final selected = mailbox.selectedMessage;
                String contextLabel = 'Unified Inbox';
                if (!mailbox.unified && mailbox.accountId != null) {
                  final MailFolder? folder = mailbox.selectedFolder;
                  if (folder != null) {
                    contextLabel = folder.name;
                  } else {
                    final match = mailbox.accounts.where(
                      (a) => a.id == mailbox.accountId,
                    );
                    if (match.isNotEmpty) {
                      contextLabel = match.first.address;
                    }
                  }
                }

                return Scaffold(
                  backgroundColor: t.ink,
                  body: Column(
                    children: [
                      _TitleBar(
                        contextLabel: contextLabel,
                        syncLabel: mailbox.syncStatusLabel,
                        queued: mailbox.queuedOutboxCount,
                        failed: mailbox.failedOutboxCount,
                        syncing: _syncBusy || mailbox.isLoading,
                        visualFocusEnabled: settings.visualFocusEnabled,
                        onToggleVisualFocus: () {
                          unawaited(
                            context.read<AppSettingsCubit>().setVisualFocusEnabled(
                              !settings.visualFocusEnabled,
                            ),
                          );
                        },
                        onOpenAppearance: () => showAppearanceSheet(context),
                        onOpenNotifications: () =>
                            showNotificationsSheet(context),
                        onOpenEml: () => unawaited(_openEmlFile()),
                        onCompose: () => showComposeSheet(context),
                        onSearch: () => showSearchSheet(context),
                        onAddAccount: () => showAddAccountSheet(context),
                        onSync: _runManualSync,
                        onOpenOutbox: () => showOutboxSheet(context),
                        onOpenSyncStatus: () => showSyncStatusSheet(context),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            _AccountRail(
                              accounts: mailbox.accounts,
                              unified: mailbox.unified,
                              accountId: mailbox.accountId,
                              onSelectUnified: cubit.selectUnified,
                              onSelectAccount: cubit.selectAccount,
                              onCompose: () => showComposeSheet(context),
                              onAddAccount: () => showAddAccountSheet(context),
                            ),
                            Expanded(
                              child: MailSplitLayout(
                                position: settings.readingPanePosition,
                                visualFocusActive:
                                    settings.visualFocusEnabled &&
                                    selected != null,
                                showSidebar: mailbox.sidebarVisible,
                                sidebarWidth: density.sidebarWidth,
                                listWidth: density.listWidth,
                                forceHorizontalSplit:
                                    isPortraitMobileLayout(context),
                                sidebar: FolderSidebar(
                                  state: mailbox,
                                  settings: settings,
                                  onHideSidebar: () =>
                                      cubit.setSidebarVisible(false),
                                  onCollapseAll: cubit.collapseAllFolders,
                                  onSelectUnified: cubit.selectUnified,
                                  onSelectVirtualView:
                                      (MailboxVirtualView view) {
                                    unawaited(() async {
                                      if (!mailbox.unified) {
                                        await cubit.selectUnified();
                                      }
                                      await cubit.setVirtualView(view);
                                    }());
                                  },
                                  onToggleAccountExpanded:
                                      cubit.toggleAccountExpanded,
                                  onSelectAccount: cubit.selectAccount,
                                  onSelectFolder: cubit.selectFolder,
                                ),
                                listPane: MessageListPane(
                                  sections: mailbox.listSections,
                                  messages: mailbox.messages,
                                  accounts: mailbox.accounts,
                                  selectedId: selected?.id,
                                  selectedIds: mailbox.selectedMessageIds,
                                  expandedThreadIds: mailbox.expandedThreadIds,
                                  focusEnabled: focusEnabled,
                                  focusFilter: mailbox.focusFilter,
                                  density: density,
                                  userFilter: mailbox.userFilter,
                                  swipeRightAction: settings.swipeRightAction,
                                  swipeLeftAction: settings.swipeLeftAction,
                                  disableDestructiveSwipe: cubit.isViewingTrash,
                                  onRefresh: cubit.syncCurrentFolder,
                                  onSwipe: (String id, SwipeListAction action) {
                                    unawaited(
                                      _handleListSwipe(cubit, id, action),
                                    );
                                  },
                                  onUserFilterChanged:
                                      (MessageViewFilter filter) {
                                    unawaited(cubit.setUserFilter(filter));
                                  },
                                  onClearUserFilter: () {
                                    unawaited(cubit.clearUserFilter());
                                  },
                                  savedFilters: settings.savedFilters,
                                  onApplySavedFilter:
                                      (MessageViewFilter filter) {
                                    unawaited(cubit.setUserFilter(filter));
                                  },
                                  onSaveCurrentFilter:
                                      (String name, MessageViewFilter filter) {
                                    return settingsCubit.saveSavedFilter(
                                      name,
                                      filter,
                                    );
                                  },
                                  onRenameSavedFilter:
                                      settingsCubit.renameSavedFilter,
                                  onDeleteSavedFilter:
                                      settingsCubit.deleteSavedFilter,
                                  onToggleThreadExpand:
                                      cubit.toggleThreadExpanded,
                                  onSelect: cubit.selectMessageWithModifiers,
                                  onFocusFilter: cubit.setFocusFilter,
                                  onMarkReadBulk:
                                      mailbox.selectedMessageIds.isEmpty
                                      ? null
                                      : () => cubit.setUnreadBulk(
                                          mailbox.selectedMessageIds.toList(
                                            growable: false,
                                          ),
                                          false,
                                        ),
                                  onMarkUnreadBulk:
                                      mailbox.selectedMessageIds.isEmpty
                                      ? null
                                      : () => cubit.setUnreadBulk(
                                          mailbox.selectedMessageIds.toList(
                                            growable: false,
                                          ),
                                          true,
                                        ),
                                  onArchiveBulk:
                                      mailbox.selectedMessageIds.isEmpty
                                      ? null
                                      : () => unawaited(cubit.archiveSelected()),
                                  onDeleteBulk:
                                      mailbox.selectedMessageIds.isEmpty
                                      ? null
                                      : () {
                                          if (cubit.isViewingTrash) {
                                            unawaited(
                                              confirmPermanentDelete(
                                                context,
                                                cubit,
                                              ),
                                            );
                                          } else {
                                            unawaited(cubit.deleteSelected());
                                          }
                                        },
                                  onStarBulk:
                                      mailbox.selectedMessageIds.isEmpty
                                      ? null
                                      : () => unawaited(
                                          cubit.toggleStarSelected(),
                                        ),
                                  onNotJunkBulk:
                                      mailbox.selectedMessageIds.isEmpty ||
                                          !cubit.isViewingJunk
                                      ? null
                                      : (AddressMatchScope scope) =>
                                            unawaited(
                                              cubit.notJunk(scope: scope),
                                            ),
                                  onReportJunkBulk:
                                      mailbox.selectedMessageIds.isEmpty ||
                                          cubit.isViewingJunk ||
                                          cubit.isViewingTrash
                                      ? null
                                      : (AddressMatchScope scope) =>
                                            unawaited(
                                              cubit.reportJunk(scope: scope),
                                            ),
                                  onMarkFocusedBulk:
                                      mailbox.selectedMessageIds.isEmpty
                                      ? null
                                      : (AddressMatchScope scope) =>
                                            unawaited(
                                              cubit.markFocusBucket(
                                                FocusBucket.focused,
                                                scope: scope,
                                              ),
                                            ),
                                  onMarkOtherBulk:
                                      mailbox.selectedMessageIds.isEmpty
                                      ? null
                                      : (AddressMatchScope scope) =>
                                            unawaited(
                                              cubit.markFocusBucket(
                                                FocusBucket.other,
                                                scope: scope,
                                              ),
                                            ),
                                  onToggleStar: (String id) =>
                                      _toggleStarForMessage(cubit, id),
                                  onClearSelection: cubit.clearBulkSelection,
                                  onShowSidebar: mailbox.sidebarVisible
                                      ? null
                                      : () => cubit.setSidebarVisible(true),
                                  onRemoteSearch: () => showSearchSheet(
                                    context,
                                    preferRemote: true,
                                  ),
                                ),
                                readingPane: ReadingPane(
                                  message: selected,
                                  accounts: mailbox.accounts,
                                  density: density,
                                  folderRole: mailbox.selectedFolder?.role,
                                  isLoadingBody: mailbox.isLoadingBody,
                                  bodyErrorMessage: mailbox.bodyErrorMessage,
                                  blockRemoteImages: settings.blockRemoteImages,
                                  findInMessageRequested:
                                      _findInMessageRequested,
                                  onFindRequestHandled: () => setState(
                                    () => _findInMessageRequested = false,
                                  ),
                                  navigationIds:
                                      mailbox.projectedNavigationIds,
                                  navigationMessages: mailbox.messages,
                                  onNavigateToMessage: (String id) {
                                    unawaited(cubit.selectMessage(id));
                                  },
                                  onMarkRead: selected == null
                                      ? null
                                      : () => cubit.setUnread(
                                          selected.id,
                                          false,
                                        ),
                                  onMarkUnread: selected == null
                                      ? null
                                      : () =>
                                            cubit.setUnread(selected.id, true),
                                  onShowHeaders: selected == null
                                      ? null
                                      : () => showMessageHeadersSheet(
                                          context,
                                          message: selected,
                                        ),
                                  onReply: selected == null
                                      ? null
                                      : () => _openReply(cubit),
                                  onReplyAll: selected == null
                                      ? null
                                      : () =>
                                            _openReply(cubit, replyAll: true),
                                  onForward: selected == null
                                      ? null
                                      : () => _openForward(cubit),
                                  onArchive: selected == null
                                      ? null
                                      : () => unawaited(
                                          cubit.archiveSelected(),
                                        ),
                                  onDelete: selected == null
                                      ? null
                                      : () => unawaited(cubit.deleteSelected()),
                                  onPermanentDelete: selected == null
                                      ? null
                                      : () => unawaited(
                                          confirmPermanentDelete(
                                            context,
                                            cubit,
                                          ),
                                        ),
                                  onToggleStar: selected == null
                                      ? null
                                      : () => unawaited(
                                          cubit.toggleStarSelected(),
                                        ),
                                  onPin: selected == null
                                      ? null
                                      : () => unawaited(
                                          cubit.togglePinSelected(),
                                        ),
                                  onSnooze: selected == null
                                      ? null
                                      : () => unawaited(_openSnooze(cubit)),
                                  onMove: selected == null
                                      ? null
                                      : () => unawaited(
                                          showMailboxMoveDialog(
                                            context,
                                            cubit,
                                            mailbox,
                                          ),
                                        ),
                                  onReportJunk: selected == null
                                      ? null
                                      : (AddressMatchScope scope) =>
                                            unawaited(
                                              cubit.reportJunk(scope: scope),
                                            ),
                                  onRecover: selected == null
                                      ? null
                                      : () => unawaited(cubit.recoverSelected()),
                                  onNotJunk: selected == null
                                      ? null
                                      : (AddressMatchScope scope) =>
                                            unawaited(
                                              cubit.notJunk(scope: scope),
                                            ),
                                  onMarkFocused: selected == null
                                      ? null
                                      : (AddressMatchScope scope) =>
                                            unawaited(
                                              cubit.markFocusBucket(
                                                FocusBucket.focused,
                                                scope: scope,
                                              ),
                                            ),
                                  onMarkOther: selected == null
                                      ? null
                                      : (AddressMatchScope scope) =>
                                            unawaited(
                                              cubit.markFocusBucket(
                                                FocusBucket.other,
                                                scope: scope,
                                              ),
                                            ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

}

class _TitleBar extends StatelessWidget {
  const _TitleBar({
    required this.contextLabel,
    required this.syncLabel,
    required this.queued,
    required this.failed,
    required this.syncing,
    required this.visualFocusEnabled,
    required this.onToggleVisualFocus,
    required this.onOpenAppearance,
    required this.onOpenNotifications,
    required this.onOpenEml,
    required this.onCompose,
    required this.onSearch,
    required this.onAddAccount,
    required this.onSync,
    required this.onOpenOutbox,
    required this.onOpenSyncStatus,
  });

  final String contextLabel;
  final String syncLabel;
  final int queued;
  final int failed;
  final bool syncing;
  final bool visualFocusEnabled;
  final VoidCallback onToggleVisualFocus;
  final VoidCallback onOpenAppearance;
  final VoidCallback onOpenNotifications;
  final VoidCallback onOpenEml;
  final VoidCallback onCompose;
  final VoidCallback onSearch;
  final VoidCallback onAddAccount;
  final VoidCallback onSync;
  final VoidCallback onOpenOutbox;
  final VoidCallback onOpenSyncStatus;

  bool get _syncNeedsAttention {
    final String lower = syncLabel.toLowerCase();
    return lower.contains('failed') ||
        lower.contains('needs attention') ||
        lower.contains('waiting to send') ||
        lower.contains('incomplete');
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            t.indigo.withValues(alpha: 0.18),
            t.teal.withValues(alpha: 0.08),
          ],
        ),
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Row(
        children: [
          const BytemailWordmark(fontSize: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text('/', style: TextStyle(color: t.muted)),
          ),
          Text(contextLabel, style: TextStyle(color: t.muted, fontSize: 13)),
          const Spacer(),
          _Pill(
            label: syncLabel,
            color: _syncNeedsAttention
                ? t.coral.withValues(alpha: 0.22)
                : t.panel2,
            textColor: _syncNeedsAttention ? t.coral : t.muted,
            onTap: onOpenSyncStatus,
            tooltip: 'Sync status',
          ),
          if (failed > 0) ...[
            const SizedBox(width: 8),
            _Pill(
              label: failed == 1 ? '1 failed' : '$failed failed',
              color: t.coral,
              textColor: t.onAccent,
              onTap: onOpenOutbox,
              tooltip: 'View failed sends',
            ),
          ],
          if (queued > 0) ...[
            const SizedBox(width: 8),
            _Pill(
              label: queued == 1 ? '1 queued' : '$queued queued',
              color: t.amber,
              textColor: t.onAccent,
              onTap: onOpenOutbox,
              tooltip: 'View outbox queue',
            ),
          ],
          IconButton(
            onPressed: syncing ? null : onSync,
            style: IconButton.styleFrom(foregroundColor: t.muted),
            icon: syncing
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: t.teal,
                    ),
                  )
                : const Icon(Icons.sync, size: 20),
          ),
          IconButton(
            onPressed: onAddAccount,
            style: IconButton.styleFrom(foregroundColor: t.muted),
            icon: const Icon(Icons.person_add_alt_1_outlined, size: 20),
          ),
          IconButton(
            onPressed: onSearch,
            style: IconButton.styleFrom(foregroundColor: t.muted),
            icon: const Icon(Icons.search, size: 20),
          ),
          IconButton(
            onPressed: onCompose,
            style: IconButton.styleFrom(foregroundColor: t.muted),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            tooltip: visualFocusEnabled
                ? 'Exit Visual Focus (Ctrl+Shift+M)'
                : 'Visual Focus (Ctrl+Shift+M)',
            onPressed: onToggleVisualFocus,
            style: IconButton.styleFrom(
              foregroundColor: visualFocusEnabled ? t.teal : t.muted,
            ),
            icon: Icon(
              visualFocusEnabled
                  ? Icons.fullscreen_exit
                  : Icons.chrome_reader_mode_outlined,
              size: 20,
            ),
          ),
          IconButton(
            tooltip: 'Open EML…',
            onPressed: onOpenEml,
            style: IconButton.styleFrom(foregroundColor: t.muted),
            icon: const Icon(Icons.attach_email_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: onOpenNotifications,
            style: IconButton.styleFrom(foregroundColor: t.muted),
            icon: const Icon(Icons.notifications_outlined, size: 20),
          ),
          IconButton(
            onPressed: onOpenAppearance,
            style: IconButton.styleFrom(foregroundColor: t.muted),
            icon: const Icon(Icons.palette_outlined, size: 20),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.color,
    required this.textColor,
    this.onTap,
    this.tooltip,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (onTap != null) ...<Widget>[
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 14, color: textColor),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return child;
    }
    return Tooltip(
      message: tooltip ?? label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: child,
        ),
      ),
    );
  }
}

class _AccountRail extends StatelessWidget {
  const _AccountRail({
    required this.accounts,
    required this.unified,
    required this.accountId,
    required this.onSelectUnified,
    required this.onSelectAccount,
    required this.onCompose,
    required this.onAddAccount,
  });

  final List<MailAccount> accounts;
  final bool unified;
  final String? accountId;
  final VoidCallback onSelectUnified;
  final ValueChanged<String> onSelectAccount;
  final VoidCallback onCompose;
  final VoidCallback onAddAccount;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    return Container(
      width: 56,
      decoration: BoxDecoration(
        color: t.panel,
        border: Border(right: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          _RailButton(
            selected: unified,
            onTap: onSelectUnified,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(9)),
                gradient: SweepGradient(
                  colors: [
                    Color(0xFF2DD4BF),
                    Color(0xFFA78BFA),
                    Color(0xFF60A5FA),
                    Color(0xFF2DD4BF),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          for (final account in accounts) ...[
            _RailButton(
              selected: !unified && accountId == account.id,
              onTap: () => onSelectAccount(account.id),
              child: Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color.alphaBlend(
                    account.accent.withValues(alpha: 0.35),
                    t.ink,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  account.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          const Spacer(),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAddAccount,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: t.line),
                ),
                child: Icon(Icons.person_add_alt_1, color: t.muted, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onCompose,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(colors: [t.teal, t.indigo]),
                ),
                child: const Text(
                  '+',
                  style: TextStyle(fontSize: 22, height: 1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RailButton extends StatelessWidget {
  const _RailButton({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    return Material(
      color: selected ? t.indigo.withValues(alpha: 0.28) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 40, height: 40, child: Center(child: child)),
      ),
    );
  }
}
