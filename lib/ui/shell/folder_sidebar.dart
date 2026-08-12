// ==============================================================================
// File: lib/ui/shell/folder_sidebar.dart
// Description: Collapsible account/folder sidebar for mailbox workspace
// Component: UI
// Version: 1.5 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-08-12
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synesis/account/account_display.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/settings/app_settings_state.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/sync/sync_activity.dart';
import 'package:synesis/ui/mailbox/mailbox_state.dart';
import 'package:synesis/ui/sync/sync_status_presentation.dart';

/// Signature for folder-level "mark all as read/unread" (UI-P23).
typedef MarkFolderUnread = void Function(
  String accountId,
  String folderId,
  bool unread,
);

/// Shows the "Mark all as read/unread" context menu for [folderId] at
/// [globalPosition], invoking [onMarkFolderUnread] with the chosen state.
///
/// Shared by desktop right-click ([GestureDetector.onSecondaryTapDown]) and
/// mobile long-press ([GestureDetector.onLongPressStart]) so both surfaces
/// resolve a global tap position for [showMenu].
Future<void> _showFolderMarkReadMenu(
  BuildContext context,
  Offset globalPosition, {
  required String accountId,
  required String folderId,
  required MarkFolderUnread onMarkFolderUnread,
}) async {
  final RenderBox overlay =
      Overlay.of(context).context.findRenderObject()! as RenderBox;
  final String? action = await showMenu<String>(
    context: context,
    position: RelativeRect.fromRect(
      globalPosition & const Size(1, 1),
      Offset.zero & overlay.size,
    ),
    items: const <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        value: 'read',
        child: Text('Mark all as read'),
      ),
      PopupMenuItem<String>(
        value: 'unread',
        child: Text('Mark all as unread'),
      ),
    ],
  );
  if (action == null) {
    return;
  }
  onMarkFolderUnread(accountId, folderId, action == 'unread');
}

/// Opens a tall folder-picker sheet for the active drawer account.
///
/// Used when the phone drawer keeps a compact folders affordance and needs
/// roomy selection without restructuring the drawer chrome.
Future<void> showDrawerFolderPickerSheet({
  required BuildContext context,
  required MailboxState state,
  required String accountId,
  required void Function(String accountId, String folderId) onSelectFolder,
  required MarkFolderUnread onMarkFolderUnread,
}) async {
  final MailAccount? account = _accountById(state, accountId);
  if (account == null) {
    return;
  }
  final t = tokensOf(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      final double maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.88;
      return SafeArea(
        child: SizedBox(
          height: maxHeight,
          child: _DrawerFolderPickerSheet(
            state: state,
            account: account,
            onSelectFolder: (String id, String folderId) {
              Navigator.of(sheetContext).pop();
              onSelectFolder(id, folderId);
            },
            onMarkFolderUnread: onMarkFolderUnread,
          ),
        ),
      );
    },
  );
}

MailAccount? _accountById(MailboxState state, String accountId) {
  for (final MailAccount account in state.accounts) {
    if (account.id == accountId) {
      return account;
    }
  }
  return null;
}

/// Picks which account the folder-picker sheet should show.
///
/// Order: [state.accountId] if still present, else [fallbackAccountId]
/// (last-active from the caller), else first expanded account, else first
/// account. Returns null when there are no accounts.
String? resolveFolderPickerAccountId(
  MailboxState state, {
  String? fallbackAccountId,
}) {
  final List<MailAccount> accounts = state.accounts;
  if (accounts.isEmpty) {
    return null;
  }
  bool has(String id) => accounts.any((MailAccount a) => a.id == id);

  final String? current = state.accountId;
  if (current != null && has(current)) {
    return current;
  }
  final String? fallback = fallbackAccountId;
  if (fallback != null && has(fallback)) {
    return fallback;
  }
  for (final String expandedId in state.expandedAccountIds) {
    if (has(expandedId)) {
      return expandedId;
    }
  }
  return accounts.first.id;
}

class FolderSidebar extends StatelessWidget {
  const FolderSidebar({
    super.key,
    required this.state,
    required this.settings,
    required this.onHideSidebar,
    required this.onCollapseAll,
    required this.onSelectUnified,
    required this.onSelectVirtualView,
    required this.onToggleAccountExpanded,
    required this.onSelectAccount,
    required this.onSelectFolder,
    required this.onMarkFolderUnread,
    this.embeddedInDrawer = false,
    this.syncActivity = const SyncActivitySnapshot.idle(),
  });

  final MailboxState state;
  final AppSettingsState settings;
  final VoidCallback onHideSidebar;
  final VoidCallback onCollapseAll;
  final VoidCallback onSelectUnified;
  final ValueChanged<MailboxVirtualView> onSelectVirtualView;
  final ValueChanged<String> onToggleAccountExpanded;
  final ValueChanged<String> onSelectAccount;
  final void Function(String accountId, String folderId) onSelectFolder;

  /// UI-P23: right-click / long-press on a folder row → mark all read/unread.
  final MarkFolderUnread onMarkFolderUnread;

  /// When true (phone drawer), hide the desktop "Hide" control and use
  /// drawer-friendly padding; retention dial stays.
  final bool embeddedInDrawer;

  /// Wave 6P UI-P11 — remote sync lifecycle for honest sidebar labels.
  final SyncActivitySnapshot syncActivity;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    if (embeddedInDrawer) {
      // Phone drawer: one scrollable column. A Column+Expanded here overflows
      // when the drawer footer (compose/settings/…) leaves < ~200px for MAIL
      // tiles — yellow/black "BOTTOM OVERFLOWED BY ~49 PIXELS" (DEF-063).
      return Container(
        color: t.panel,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Text(
              'MAIL',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: t.muted,
                fontSize: 12,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            _NavTile(
              label: 'Unified Inbox',
              selected: state.unified &&
                  state.virtualView == MailboxVirtualView.none,
              onTap: onSelectUnified,
            ),
            _NavTile(
              label: 'Starred',
              selected: state.virtualView == MailboxVirtualView.starred,
              indent: 12,
              leading:
                  Icon(Icons.star_outline_rounded, size: 16, color: t.amber),
              onTap: () => onSelectVirtualView(MailboxVirtualView.starred),
            ),
            _NavTile(
              label: 'Pinned',
              selected: state.virtualView == MailboxVirtualView.pinned,
              indent: 12,
              leading: Icon(
                Icons.push_pin_outlined,
                size: 16,
                color: t.amethyst,
              ),
              onTap: () => onSelectVirtualView(MailboxVirtualView.pinned),
            ),
            _NavTile(
              label: 'Snoozed',
              selected: state.virtualView == MailboxVirtualView.snoozed,
              indent: 12,
              leading: Icon(Icons.snooze_rounded, size: 16, color: t.azure),
              onTap: () => onSelectVirtualView(MailboxVirtualView.snoozed),
            ),
            const SizedBox(height: 12),
            Text(
              'ACCOUNTS',
              style: TextStyle(
                color: t.muted.withValues(alpha: 0.7),
                fontSize: 10,
                letterSpacing: 1.4,
              ),
            ),
            const SizedBox(height: 6),
            _DrawerAccountsBody(
              state: state,
              syncActivity: syncActivity,
              onSelectAccount: onSelectAccount,
              onSelectFolder: onSelectFolder,
              onMarkFolderUnread: onMarkFolderUnread,
              shrinkWrap: true,
            ),
          ],
        ),
      );
    }
    return Container(
      color: t.panel,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'MAILBOX',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.muted,
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (state.expandedAccountIds.isNotEmpty)
                TextButton(
                  onPressed: onCollapseAll,
                  style: TextButton.styleFrom(
                    foregroundColor: t.muted,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('Collapse', style: TextStyle(fontSize: 11)),
                ),
              TextButton(
                onPressed: onHideSidebar,
                style: TextButton.styleFrom(
                  foregroundColor: t.teal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Hide', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _NavTile(
            label: 'Unified Inbox',
            selected: state.unified &&
                state.virtualView == MailboxVirtualView.none,
            onTap: onSelectUnified,
          ),
          _NavTile(
            label: 'Starred',
            selected: state.virtualView == MailboxVirtualView.starred,
            indent: 12,
            leading: Icon(Icons.star_outline_rounded, size: 16, color: t.amber),
            onTap: () => onSelectVirtualView(MailboxVirtualView.starred),
          ),
          _NavTile(
            label: 'Pinned',
            selected: state.virtualView == MailboxVirtualView.pinned,
            indent: 12,
            leading: Icon(
              Icons.push_pin_outlined,
              size: 16,
              color: t.amethyst,
            ),
            onTap: () => onSelectVirtualView(MailboxVirtualView.pinned),
          ),
          _NavTile(
            label: 'Snoozed',
            selected: state.virtualView == MailboxVirtualView.snoozed,
            indent: 12,
            leading: Icon(Icons.snooze_rounded, size: 16, color: t.azure),
            onTap: () => onSelectVirtualView(MailboxVirtualView.snoozed),
          ),
          const SizedBox(height: 12),
          Text(
            'ACCOUNTS',
            style: TextStyle(
              color: t.muted.withValues(alpha: 0.7),
              fontSize: 10,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: _AccountsScrollArea(
              showMoreHint: false,
              moreHintLabel: 'More accounts',
              children: <Widget>[
                for (final MailAccount account in state.accounts)
                  _AccountSection(
                    account: account,
                    state: state,
                    settings: settings,
                    syncActivity: syncActivity,
                    onToggleExpanded: () =>
                        onToggleAccountExpanded(account.id),
                    onSelectAccount: () => onSelectAccount(account.id),
                    onSelectFolder: onSelectFolder,
                    onMarkFolderUnread: onMarkFolderUnread,
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: t.line),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  t.indigo.withValues(alpha: 0.2),
                  t.teal.withValues(alpha: 0.08),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RETENTION DIAL',
                  style: TextStyle(
                    color: t.muted,
                    fontSize: 10,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${settings.retentionDays} days · this device',
                  style: const TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (settings.retentionDays / 365).clamp(0.05, 1),
                    minHeight: 6,
                    backgroundColor: Colors.black38,
                    color: t.teal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Scrollable accounts list with an optional "more below" fade + chevron when
/// content overflows (phone drawer).
class _AccountsScrollArea extends StatefulWidget {
  const _AccountsScrollArea({
    required this.children,
    required this.showMoreHint,
    this.moreHintLabel = 'More accounts',
  });

  final List<Widget> children;
  final bool showMoreHint;
  final String moreHintLabel;

  @override
  State<_AccountsScrollArea> createState() => _AccountsScrollAreaState();
}

class _AccountsScrollAreaState extends State<_AccountsScrollArea> {
  final ScrollController _controller = ScrollController();
  bool _canScrollMore = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHint());
  }

  @override
  void didUpdateWidget(covariant _AccountsScrollArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateHint());
  }

  @override
  void dispose() {
    _controller.removeListener(_updateHint);
    _controller.dispose();
    super.dispose();
  }

  void _updateHint() {
    if (!widget.showMoreHint || !mounted) {
      return;
    }
    if (!_controller.hasClients) {
      return;
    }
    final ScrollPosition pos = _controller.position;
    final bool more =
        pos.maxScrollExtent > 8 && pos.pixels < (pos.maxScrollExtent - 8);
    if (more != _canScrollMore) {
      setState(() => _canScrollMore = more);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (ScrollMetricsNotification notification) {
        _updateHint();
        return false;
      },
      child: Stack(
        children: <Widget>[
          ListView(
            controller: _controller,
            padding: EdgeInsets.zero,
            children: widget.children,
          ),
          if (widget.showMoreHint && _canScrollMore)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: <Color>[
                        t.panel.withValues(alpha: 0),
                        t.panel.withValues(alpha: 0.92),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 22,
                          color: t.teal,
                        ),
                        Text(
                          widget.moreHintLabel,
                          style: TextStyle(
                            color: t.muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Phone drawer: vertical account list + folders launch for the resolved account.
class _DrawerAccountsBody extends StatefulWidget {
  const _DrawerAccountsBody({
    required this.state,
    required this.syncActivity,
    required this.onSelectAccount,
    required this.onSelectFolder,
    required this.onMarkFolderUnread,
    this.shrinkWrap = false,
  });

  final MailboxState state;
  final SyncActivitySnapshot syncActivity;
  final ValueChanged<String> onSelectAccount;
  final void Function(String accountId, String folderId) onSelectFolder;
  final MarkFolderUnread onMarkFolderUnread;

  /// When true, nest inside a parent [ListView] (drawer MAIL+ACCOUNTS scroll).
  final bool shrinkWrap;

  @override
  State<_DrawerAccountsBody> createState() => _DrawerAccountsBodyState();
}

class _DrawerAccountsBodyState extends State<_DrawerAccountsBody> {
  String? _lastAccountId;

  @override
  void initState() {
    super.initState();
    _rememberAccount(widget.state.accountId);
  }

  @override
  void didUpdateWidget(covariant _DrawerAccountsBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    _rememberAccount(widget.state.accountId);
  }

  void _rememberAccount(String? accountId) {
    if (accountId != null && accountId.isNotEmpty) {
      _lastAccountId = accountId;
    }
  }

  String? _activeAccountId() {
    return resolveFolderPickerAccountId(
      widget.state,
      fallbackAccountId: _lastAccountId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? activeId = _activeAccountId();
    MailAccount? resolved;
    if (activeId != null) {
      for (final MailAccount account in widget.state.accounts) {
        if (account.id == activeId) {
          resolved = account;
          break;
        }
      }
    }

    final List<MailFolder> folders = activeId == null
        ? const <MailFolder>[]
        : widget.state.foldersForAccount(activeId);
    final MailFolder? selectedFolder = _selectedFolderForAccount(
      widget.state,
      activeId,
    );

    return ListView(
      padding: EdgeInsets.zero,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.shrinkWrap
          ? const NeverScrollableScrollPhysics()
          : null,
      children: <Widget>[
        for (final MailAccount account in widget.state.accounts)
          _DrawerAccountTile(
            account: account,
            selected: account.id == activeId,
            unread: widget.state.unreadForAccount(account.id),
            onTap: () => widget.onSelectAccount(account.id),
          ),
        const SizedBox(height: 12),
        _FoldersLaunchTile(
          account: resolved,
          folderCount: folders.length,
          selectedFolderName: selectedFolder?.name,
          syncing: widget.syncActivity.isRemoteSyncInFlight,
          syncStatusLabel: SyncStatusPresentation.composeLabel(
            activity: widget.syncActivity,
            repositoryLabel: widget.state.syncStatusLabel,
          ),
          syncSubtitle: SyncStatusPresentation.activeSyncSubtitle(
            activity: widget.syncActivity,
            repositoryLabel: widget.state.syncStatusLabel,
          ),
          onOpen: resolved == null
              ? null
              : () {
                  final String accountId = resolved!.id;
                  unawaited(
                    showDrawerFolderPickerSheet(
                      context: context,
                      state: widget.state,
                      accountId: accountId,
                      onSelectFolder: widget.onSelectFolder,
                      onMarkFolderUnread: widget.onMarkFolderUnread,
                    ),
                  );
                },
        ),
      ],
    );
  }
}

MailFolder? _selectedFolderForAccount(MailboxState state, String? accountId) {
  if (accountId == null ||
      state.unified ||
      state.virtualView != MailboxVirtualView.none ||
      state.folderId == null ||
      state.accountId != accountId) {
    return null;
  }
  for (final MailFolder folder in state.foldersForAccount(accountId)) {
    if (folder.id == state.folderId) {
      return folder;
    }
  }
  return null;
}

/// Compact drawer affordance that opens the full folder picker sheet.
class _FoldersLaunchTile extends StatelessWidget {
  const _FoldersLaunchTile({
    required this.account,
    required this.folderCount,
    required this.selectedFolderName,
    required this.syncing,
    required this.syncStatusLabel,
    this.syncSubtitle,
    required this.onOpen,
  });

  final MailAccount? account;
  final int folderCount;
  final String? selectedFolderName;
  final bool syncing;
  final String syncStatusLabel;
  final String? syncSubtitle;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final String subtitle;
    if (account == null) {
      subtitle = 'No accounts yet';
    } else if (syncing) {
      subtitle = syncSubtitle ??
          (syncStatusLabel.toLowerCase().contains('folder list')
              ? 'Folder list incomplete — open Sync status'
              : 'Syncing folders…');
    } else if (selectedFolderName != null) {
      subtitle = selectedFolderName!;
    } else if (folderCount == 1) {
      subtitle = '1 folder';
    } else {
      subtitle = '$folderCount folders';
    }

    return Material(
      color: t.teal.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'FOLDERS',
                      style: TextStyle(
                        color: t.muted.withValues(alpha: 0.7),
                        fontSize: 10,
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (account != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        account!.address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: t.teal,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(
                      onOpen == null ? subtitle : '$subtitle · Tap to browse',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.unfold_more_rounded,
                color: onOpen == null ? t.muted.withValues(alpha: 0.4) : t.teal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DrawerFolderPickerSheet extends StatelessWidget {
  const _DrawerFolderPickerSheet({
    required this.state,
    required this.account,
    required this.onSelectFolder,
    required this.onMarkFolderUnread,
  });

  final MailboxState state;
  final MailAccount account;
  final void Function(String accountId, String folderId) onSelectFolder;
  final MarkFolderUnread onMarkFolderUnread;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final List<MailFolder> folders = state.foldersForAccount(account.id);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 12, 8),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Folders',
                      style: TextStyle(
                        color: t.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.address,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.teal, fontSize: 13),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).maybePop(),
                icon: Icon(Icons.close_rounded, color: t.muted),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: t.line),
        Expanded(
          child: folders.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.syncStatusLabel.toLowerCase().contains('folder list')
                          ? 'Folder list incomplete — open Sync status'
                          : 'Syncing folders…',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: t.muted, fontSize: 14),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                  children: <Widget>[
                    for (final MailFolder folder in _rootFolders(folders))
                      ..._folderBranchWidgets(
                        context: context,
                        accountId: account.id,
                        folder: folder,
                        all: folders,
                        depth: 0,
                        state: state,
                        tokensTeal: t.teal,
                        onSelectFolder: onSelectFolder,
                        onMarkFolderUnread: onMarkFolderUnread,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// Compact full-width account row for the phone drawer accounts list (DEF-082).
class _DrawerAccountTile extends StatelessWidget {
  const _DrawerAccountTile({
    required this.account,
    required this.selected,
    required this.unread,
    required this.onTap,
  });

  final MailAccount account;
  final bool selected;
  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final String label = AccountDisplay.primaryLabel(account);
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Tooltip(
        message: AccountDisplay.secondaryLabel(account),
        waitDuration: const Duration(milliseconds: 400),
        child: Material(
          color: selected ? t.teal.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: account.accent,
                      shape: BoxShape.circle,
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: account.accent.withValues(alpha: 0.35),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? t.text : t.muted,
                        fontSize: 13,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (unread > 0) ...<Widget>[
                    const SizedBox(width: 8),
                    Text(
                      '$unread',
                      style: TextStyle(
                        color: t.teal,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

List<MailFolder> _rootFolders(List<MailFolder> folders) {
  final Set<String> remoteIds = folders.map((f) => f.remoteId).toSet();
  final List<MailFolder> roots = folders
      .where(
        (MailFolder folder) =>
            folder.parentRemoteId == null ||
            folder.parentRemoteId!.isEmpty ||
            !remoteIds.contains(folder.parentRemoteId),
      )
      .toList(growable: false);
  if (roots.isEmpty) {
    return folders;
  }
  return roots;
}

List<Widget> _folderBranchWidgets({
  required BuildContext context,
  required String accountId,
  required MailFolder folder,
  required List<MailFolder> all,
  required int depth,
  required MailboxState state,
  required Color tokensTeal,
  required void Function(String accountId, String folderId) onSelectFolder,
  required MarkFolderUnread onMarkFolderUnread,
}) {
  final bool selected = !state.unified &&
      state.virtualView == MailboxVirtualView.none &&
      state.folderId == folder.id;
  final List<MailFolder> children = all
      .where((MailFolder child) => child.parentRemoteId == folder.remoteId)
      .toList(growable: false);
  return <Widget>[
    _NavTile(
      label: folder.name,
      selected: selected,
      indent: 12.0 + (depth * 12.0),
      trailing: (folder.unreadCount ?? 0) > 0 ? '${folder.unreadCount}' : null,
      trailingColor: tokensTeal,
      onTap: () => onSelectFolder(accountId, folder.id),
      onShowContextMenu: (Offset globalPosition) => _showFolderMarkReadMenu(
        context,
        globalPosition,
        accountId: accountId,
        folderId: folder.id,
        onMarkFolderUnread: onMarkFolderUnread,
      ),
    ),
    for (final MailFolder child in children)
      ..._folderBranchWidgets(
        context: context,
        accountId: accountId,
        folder: child,
        all: all,
        depth: depth + 1,
        state: state,
        tokensTeal: tokensTeal,
        onSelectFolder: onSelectFolder,
        onMarkFolderUnread: onMarkFolderUnread,
      ),
  ];
}

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.account,
    required this.state,
    required this.settings,
    required this.syncActivity,
    required this.onToggleExpanded,
    required this.onSelectAccount,
    required this.onSelectFolder,
    required this.onMarkFolderUnread,
  });

  final MailAccount account;
  final MailboxState state;
  final AppSettingsState settings;
  final SyncActivitySnapshot syncActivity;
  final VoidCallback onToggleExpanded;
  final VoidCallback onSelectAccount;
  final void Function(String accountId, String folderId) onSelectFolder;
  final MarkFolderUnread onMarkFolderUnread;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final bool expanded = state.expandedAccountIds.contains(account.id);
    final List<MailFolder> folders = state.foldersForAccount(account.id);
    final bool accountSelected =
        !state.unified &&
        state.virtualView == MailboxVirtualView.none &&
        state.accountId == account.id &&
        state.folderId == null;
    final bool accountHasSelection =
        !state.unified &&
        state.virtualView == MailboxVirtualView.none &&
        state.accountId == account.id;
    final int unread = state.unreadForAccount(account.id);
    final List<MailFolder> roots = _rootFolders(folders);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NavTile(
          label: account.address,
          selected:
              accountSelected ||
              (accountHasSelection && !expanded && state.folderId != null),
          accent: account.accent,
          leading: IconButton(
            onPressed: folders.isEmpty ? null : onToggleExpanded,
            icon: Icon(
              expanded ? Icons.expand_more : Icons.chevron_right,
              size: 18,
              color: folders.isEmpty
                  ? t.muted.withValues(alpha: 0.35)
                  : t.muted,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            splashRadius: 16,
            tooltip: expanded ? 'Collapse folders' : 'Expand folders',
          ),
          trailing: unread > 0
              ? '$unread'
              : (settings.isAccountFocusEnabled(account.id)
                    ? null
                    : 'no focus'),
          trailingColor: unread > 0 ? t.teal : t.amber,
          onTap: onSelectAccount,
        ),
        if (folders.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(40, 2, 12, 8),
            child: Text(
              SyncStatusPresentation.activeSyncSubtitle(
                    activity: syncActivity,
                    repositoryLabel: state.syncStatusLabel,
                  ) ??
                  (state.syncStatusLabel.toLowerCase().contains('folder list')
                      ? 'Folder list incomplete — open Sync status'
                      : 'Syncing folders…'),
              style: TextStyle(color: t.muted, fontSize: 12),
            ),
          )
        else if (expanded)
          for (final MailFolder folder in roots)
            ..._folderBranchWidgets(
              context: context,
              accountId: account.id,
              folder: folder,
              all: folders,
              depth: 1,
              state: state,
              tokensTeal: t.teal,
              onSelectFolder: onSelectFolder,
              onMarkFolderUnread: onMarkFolderUnread,
            ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent,
    this.trailing,
    this.trailingColor,
    this.leading,
    this.indent = 0,
    this.onShowContextMenu,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;
  final String? trailing;
  final Color? trailingColor;
  final Widget? leading;
  final double indent;

  /// UI-P23: desktop right-click / mobile long-press → mark all read/unread.
  /// Receives the tap's global position for [showMenu] placement.
  final ValueChanged<Offset>? onShowContextMenu;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final ValueChanged<Offset>? showContextMenu = onShowContextMenu;
    return Padding(
      padding: EdgeInsets.only(bottom: 2, left: indent),
      child: Material(
        color: selected ? t.teal.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onSecondaryTapDown: showContextMenu == null
              ? null
              : (TapDownDetails details) =>
                  showContextMenu(details.globalPosition),
          onLongPressStart: showContextMenu == null
              ? null
              : (LongPressStartDetails details) =>
                  showContextMenu(details.globalPosition),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  if (leading != null) leading!,
                  if (accent != null) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: accent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: accent!.withValues(alpha: 0.35),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? t.text : t.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: TextStyle(
                        color: trailingColor ?? t.amber,
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
