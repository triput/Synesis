// ==============================================================================
// File: lib/ui/shell/mail_workspace.dart
// Description: Multi-pane mailbox workspace driven by MailboxCubit
// Component: UI
// Version: 1.4 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-08-12
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synesis/account/account_display.dart';
import 'package:synesis/desktop/message_file_service.dart';
import 'package:synesis/domain/address_match_scope.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/mime/eml_codec.dart';
import 'package:synesis/settings/app_settings_cubit.dart';
import 'package:synesis/settings/app_settings_state.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/density.dart';
import 'package:synesis/query/message_query.dart';
import 'package:synesis/ui/branding/synesis_wordmark.dart';
import 'package:synesis/sync/sync_activity.dart';
import 'package:synesis/ui/sync/sync_status_presentation.dart';
import 'package:synesis/ui/mailbox/mailbox_cubit.dart';
import 'package:synesis/ui/mailbox/mailbox_state.dart';
import 'package:synesis/ui/settings/notifications_sheet.dart';
import 'package:synesis/ui/settings/settings_shell.dart';
import 'package:synesis/ui/shell/eml_preview_sheet.dart';
import 'package:synesis/ui/shell/folder_sidebar.dart';
import 'package:synesis/ui/shell/mail_navigation_drawer.dart';
import 'package:synesis/ui/shell/mail_split_layout.dart';
import 'package:synesis/ui/shell/keymap_help_sheet.dart';
import 'package:synesis/ui/shell/mailbox_dialogs.dart';
import 'package:synesis/ui/shell/mailbox_shortcuts.dart';
import 'package:synesis/ui/shell/message_list_pane.dart';
import 'package:synesis/ui/shell/message_headers_sheet.dart';
import 'package:synesis/ui/shell/reading_pane.dart';
import 'package:synesis/ui/shell/snooze_dialog.dart';
import 'package:synesis/ui/account/add_account_sheet.dart';
import 'package:synesis/ui/compose/compose_prefill.dart';
import 'package:synesis/ui/compose/compose_sheet.dart';
import 'package:synesis/ui/outbox/outbox_sheet.dart';
import 'package:synesis/ui/search/search_sheet.dart';
import 'package:synesis/ui/sync/sync_status_sheet.dart';
import 'package:synesis/sync/sync_engine.dart';

class MailWorkspace extends StatefulWidget {
  const MailWorkspace({super.key});

  @override
  State<MailWorkspace> createState() => _MailWorkspaceState();
}

class _MailWorkspaceState extends State<MailWorkspace> {
  late final FocusNode _workspaceFocus = FocusNode(
    debugLabel: 'SynesisWorkspace',
  );
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SyncActivitySnapshot _syncActivity = const SyncActivitySnapshot.idle();
  StreamSubscription<SyncActivitySnapshot>? _syncActivitySub;
  bool _findInMessageRequested = false;

  /// Last non-null mailbox account id for folder-picker under Unified/virtual.
  String? _lastFolderPickerAccountId;

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
      final SyncActivity activity = context.read<SyncActivity>();
      _syncActivity = activity.value;
      _syncActivitySub = activity.stream.listen((
        SyncActivitySnapshot snapshot,
      ) {
        if (mounted) {
          setState(() => _syncActivity = snapshot);
        }
      });
    });
  }

  @override
  void dispose() {
    unawaited(_syncActivitySub?.cancel());
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

  /// Opens the shared folder-picker sheet for the current/last-active account.
  void _openFolderPicker(MailboxState mailbox, MailboxCubit cubit) {
    final String? accountId = resolveFolderPickerAccountId(
      mailbox,
      fallbackAccountId: _lastFolderPickerAccountId,
    );
    if (accountId == null) {
      return;
    }
    _lastFolderPickerAccountId = accountId;
    unawaited(
      showDrawerFolderPickerSheet(
        context: context,
        state: mailbox,
        accountId: accountId,
        onSelectFolder: (String a, String f) {
          unawaited(cubit.selectFolder(a, f));
        },
        onMarkFolderUnread:
            (String accountId, String folderId, bool unread) => unawaited(
              cubit.markFolderUnread(
                accountId: accountId,
                folderId: folderId,
                unread: unread,
              ),
            ),
      ),
    );
  }

  Future<void> _runManualSync() async {
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
      unawaited(engine.kickFreshNonBlocking());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync started')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync error: $error')));
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
                final bool portraitMobile = isPortraitMobileLayout(context);
                // Phone list density: flat clickable rows (not Calm cards).
                final ViewDensity listDensity =
                    portraitMobile ? ViewDensity.compact : density;
                // Desktop keeps first-row fallback for the reading pane; phone
                // only opens a message when the user (or pager) set an id —
                // otherwise the list stays full-bleed on launch.
                final MailMessage? selected = portraitMobile
                    ? (mailbox.selectedMessageId == null
                        ? null
                        : mailbox.selectedMessage)
                    : mailbox.selectedMessage;
                // Phone: open message full-bleed (same path as Visual Focus).
                final bool readingFullBleed = selected != null &&
                    (settings.visualFocusEnabled || portraitMobile);
                final String? mailboxAccountId = mailbox.accountId;
                if (mailboxAccountId != null) {
                  _lastFolderPickerAccountId = mailboxAccountId;
                }
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
                } else if (mailbox.virtualView == MailboxVirtualView.starred) {
                  contextLabel = 'Starred';
                } else if (mailbox.virtualView == MailboxVirtualView.pinned) {
                  contextLabel = 'Pinned';
                } else if (mailbox.virtualView == MailboxVirtualView.snoozed) {
                  contextLabel = 'Snoozed';
                }

                return PopScope(
                  canPop: !(portraitMobile && selected != null),
                  onPopInvokedWithResult: (bool didPop, Object? result) {
                    if (didPop) {
                      return;
                    }
                    if (portraitMobile && selected != null) {
                      cubit.clearSelectedMessage();
                    }
                  },
                  child: Scaffold(
                    key: _scaffoldKey,
                    backgroundColor: t.ink,
                    resizeToAvoidBottomInset: true,
                    drawer: portraitMobile
                        ? MailNavigationDrawer(
                            state: mailbox,
                            settings: settings,
                            syncActivity: _syncActivity,
                            onCollapseAll: cubit.collapseAllFolders,
                            onSelectUnified: () {
                              unawaited(cubit.selectUnified());
                            },
                            onSelectVirtualView: (MailboxVirtualView view) {
                              unawaited(() async {
                                if (!mailbox.unified) {
                                  await cubit.selectUnified();
                                }
                                await cubit.setVirtualView(view);
                              }());
                            },
                            onToggleAccountExpanded:
                                cubit.toggleAccountExpanded,
                            onSelectAccount: (String id) {
                              unawaited(cubit.selectAccount(id));
                            },
                            onSelectFolder: cubit.selectFolder,
                            onMarkFolderUnread:
                                (
                                  String accountId,
                                  String folderId,
                                  bool unread,
                                ) => unawaited(
                                  cubit.markFolderUnread(
                                    accountId: accountId,
                                    folderId: folderId,
                                    unread: unread,
                                  ),
                                ),
                            onCompose: () => showComposeSheet(context),
                            onOpenOutbox: () => showOutboxSheet(context),
                            onOpenSettings: () => showSettingsSheet(context),
                            onOpenSyncStatus: () =>
                                showSyncStatusSheet(context),
                          )
                        : null,
                    body: Column(
                      children: [
                      if (!portraitMobile || !readingFullBleed)
                        _TitleBar(
                        contextLabel: contextLabel,
                        syncLabel: SyncStatusPresentation.composeLabel(
                          activity: _syncActivity,
                          repositoryLabel: mailbox.syncStatusLabel,
                        ),
                        queued: mailbox.queuedOutboxCount,
                        failed: mailbox.failedOutboxCount,
                        syncing: _syncActivity.isRemoteSyncInFlight,
                        compact: portraitMobile,
                        // Edge swipe opens the drawer; hamburger stays for a11y.
                        onOpenDrawer: portraitMobile && !readingFullBleed
                            ? () => _scaffoldKey.currentState?.openDrawer()
                            : null,
                        onOpenFolderPicker: portraitMobile
                            ? () => _openFolderPicker(mailbox, cubit)
                            : null,
                        visualFocusEnabled: settings.visualFocusEnabled,
                        onToggleVisualFocus: () {
                          unawaited(
                            context.read<AppSettingsCubit>().setVisualFocusEnabled(
                              !settings.visualFocusEnabled,
                            ),
                          );
                        },
                        onOpenSettings: () => showSettingsSheet(context),
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
                            if (!portraitMobile)
                              AccountRail(
                                accounts: mailbox.accounts,
                                unified: mailbox.unified,
                                accountId: mailbox.accountId,
                                onSelectUnified: cubit.selectUnified,
                                onSelectAccount: cubit.selectAccount,
                                onCompose: () => showComposeSheet(context),
                                onAddAccount: () =>
                                    showAddAccountSheet(context),
                              ),
                            Expanded(
                              child: MailSplitLayout(
                                position: settings.readingPanePosition,
                                visualFocusActive: readingFullBleed,
                                showSidebar: portraitMobile
                                    ? false
                                    : mailbox.sidebarVisible,
                                sidebarWidth: density.sidebarWidth,
                                listWidth: density.listWidth,
                                forceHorizontalSplit: portraitMobile,
                                sidebar: FolderSidebar(
                                  state: mailbox,
                                  settings: settings,
                                  syncActivity: _syncActivity,
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
                                  onMarkFolderUnread:
                                      (
                                        String accountId,
                                        String folderId,
                                        bool unread,
                                      ) => unawaited(
                                        cubit.markFolderUnread(
                                          accountId: accountId,
                                          folderId: folderId,
                                          unread: unread,
                                        ),
                                      ),
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
                                  density: listDensity,
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
                                  onShowSidebar: portraitMobile
                                      ? () => _openFolderPicker(mailbox, cubit)
                                      : (mailbox.sidebarVisible
                                          ? null
                                          : () => cubit.setSidebarVisible(
                                              true,
                                            )),
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
                                  // Detached reader is a desktop affordance.
                                  allowOpenInNewWindow: !portraitMobile,
                                  isLoadingBody: mailbox.isLoadingBody,
                                  bodyErrorMessage: mailbox.bodyErrorMessage,
                                  blockRemoteImages: settings.blockRemoteImages,
                                  accountBlockRemoteImages:
                                      settings.accountBlockRemoteImages,
                                  accountImageAllowlistDomains:
                                      settings.accountImageAllowlistDomains,
                                  blockTrackers: settings.blockTrackers,
                                  showQuickReplyEnabled:
                                      settings.showQuickReplyEnabled,
                                  autoMarkAsReadEnabled:
                                      settings.autoMarkAsReadEnabled,
                                  autoMarkAsReadDwell: Duration(
                                    seconds: settings.autoMarkAsReadSeconds,
                                  ),
                                  findInMessageRequested:
                                      _findInMessageRequested,
                                  onFindRequestHandled: () => setState(
                                    () => _findInMessageRequested = false,
                                  ),
                                  navigationIds:
                                      mailbox.projectedNavigationIds,
                                  navigationMessages:
                                      mailbox.readingNavigationMessages,
                                  onNavigateToMessage: (String id) {
                                    unawaited(cubit.selectMessage(id));
                                  },
                                  onBackToList: portraitMobile
                                      ? cubit.clearSelectedMessage
                                      : null,
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
    required this.compact,
    this.onOpenDrawer,
    this.onOpenFolderPicker,
    required this.visualFocusEnabled,
    required this.onToggleVisualFocus,
    required this.onOpenSettings,
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

  /// Phone-width chrome: fewer inline icons, overflow menu for the rest.
  final bool compact;

  /// Opens the phone navigation drawer (hamburger). Null while reading.
  final VoidCallback? onOpenDrawer;

  /// Opens the shared folder-picker sheet (list + reading on phone).
  final VoidCallback? onOpenFolderPicker;
  final bool visualFocusEnabled;
  final VoidCallback onToggleVisualFocus;
  final VoidCallback onOpenSettings;
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
          if (compact && onOpenDrawer != null)
            IconButton(
              key: const Key('mail_nav_drawer_menu'),
              tooltip: 'Folders and accounts (or swipe from left edge)',
              onPressed: onOpenDrawer,
              style: IconButton.styleFrom(foregroundColor: t.muted),
              icon: const Icon(Icons.menu_rounded, size: 22),
            ),
          if (!compact || onOpenDrawer == null) ...[
            const SynesisWordmark(fontSize: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('/', style: TextStyle(color: t.muted)),
            ),
          ] else
            const SizedBox(width: 4),
          Expanded(
            child: compact && onOpenFolderPicker != null
                ? Tooltip(
                    message: 'Browse folders',
                    child: InkWell(
                      key: const Key('mail_folder_picker'),
                      onTap: onOpenFolderPicker,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 6,
                        ),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                contextLabel,
                                style: TextStyle(
                                  color: t.muted,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.folder_open_rounded,
                              size: 18,
                              color: t.teal,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Text(
                    contextLabel,
                    style: TextStyle(color: t.muted, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
          ),
          if (!compact) ...[
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
              onPressed: onSync,
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
              tooltip: 'Settings',
              onPressed: onOpenSettings,
              style: IconButton.styleFrom(foregroundColor: t.muted),
              icon: const Icon(Icons.settings_outlined, size: 20),
            ),
          ] else ...[
            if (_syncNeedsAttention || failed > 0 || queued > 0)
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _Pill(
                    label: failed > 0
                        ? (failed == 1 ? '1 failed' : '$failed failed')
                        : (queued > 0
                            ? (queued == 1 ? '1 queued' : '$queued queued')
                            : syncLabel),
                    color: failed > 0 || _syncNeedsAttention
                        ? t.coral.withValues(alpha: failed > 0 ? 1 : 0.22)
                        : t.amber,
                    textColor: failed > 0 || queued > 0 ? t.onAccent : t.coral,
                    onTap: failed > 0 || queued > 0
                        ? onOpenOutbox
                        : onOpenSyncStatus,
                    tooltip: syncLabel,
                    compact: true,
                  ),
                ),
              ),
            IconButton(
              onPressed: onSync,
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
              onPressed: onCompose,
              style: IconButton.styleFrom(foregroundColor: t.muted),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            PopupMenuButton<String>(
              tooltip: 'More',
              icon: Icon(Icons.more_vert, color: t.muted, size: 20),
              onSelected: (String value) {
                switch (value) {
                  case 'search':
                    onSearch();
                  case 'add_account':
                    onAddAccount();
                  case 'sync_status':
                    onOpenSyncStatus();
                  case 'eml':
                    onOpenEml();
                  case 'notifications':
                    onOpenNotifications();
                  case 'settings':
                    onOpenSettings();
                  case 'visual_focus':
                    onToggleVisualFocus();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'search',
                  child: Text('Search'),
                ),
                const PopupMenuItem<String>(
                  value: 'add_account',
                  child: Text('Add account'),
                ),
                const PopupMenuItem<String>(
                  value: 'sync_status',
                  child: Text('Sync status'),
                ),
                PopupMenuItem<String>(
                  value: 'visual_focus',
                  child: Text(
                    visualFocusEnabled
                        ? 'Exit Visual Focus'
                        : 'Visual Focus',
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'eml',
                  child: Text('Open EML…'),
                ),
                const PopupMenuItem<String>(
                  value: 'notifications',
                  child: Text('Notifications'),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Text('Settings'),
                ),
              ],
            ),
          ],
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
    this.compact = false,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final Widget child = Container(
      constraints: compact
          ? const BoxConstraints(maxWidth: 140)
          : const BoxConstraints(),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
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

/// Narrow desktop account rail: Unified header, scrollable accounts, footer chrome.
///
/// Accounts scroll inside [Expanded] so monogram+label tiles cannot force a
/// RenderFlex overflow when the shell height is short.
class AccountRail extends StatelessWidget {
  const AccountRail({
    super.key,
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
      width: 88,
      decoration: BoxDecoration(
        color: t.panel,
        border: Border(right: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
      child: Column(
        children: <Widget>[
          _RailButton(
            selected: unified,
            onTap: onSelectUnified,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(9)),
                gradient: SweepGradient(
                  colors: <Color>[
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
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: accounts.length,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(height: 8);
              },
              itemBuilder: (BuildContext context, int index) {
                final MailAccount account = accounts[index];
                return Tooltip(
                  message: AccountDisplay.secondaryLabel(account),
                  waitDuration: const Duration(milliseconds: 400),
                  child: _RailButton(
                    selected: !unified && accountId == account.id,
                    onTap: () => onSelectAccount(account.id),
                    width: 76,
                    height: 48,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
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
                            AccountDisplay.monogram(account),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        SizedBox(
                          width: 68,
                          child: Text(
                            AccountDisplay.primaryLabel(account),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: t.muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
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
                  gradient: LinearGradient(colors: <Color>[t.teal, t.indigo]),
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
    this.width = 40,
    this.height = 40,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    return Material(
      color: selected ? t.indigo.withValues(alpha: 0.28) : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: width,
          height: height,
          child: Center(child: child),
        ),
      ),
    );
  }
}
