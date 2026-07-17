// ==============================================================================
// File: lib/ui/shell/folder_sidebar.dart
// Description: Collapsible account/folder sidebar for mailbox workspace
// Component: UI
// Version: 1.2 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/ui/mailbox/mailbox_state.dart';

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

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
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
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                for (final MailAccount account in state.accounts)
                  _AccountSection(
                    account: account,
                    state: state,
                    settings: settings,
                    onToggleExpanded: () => onToggleAccountExpanded(account.id),
                    onSelectAccount: () => onSelectAccount(account.id),
                    onSelectFolder: onSelectFolder,
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

class _AccountSection extends StatelessWidget {
  const _AccountSection({
    required this.account,
    required this.state,
    required this.settings,
    required this.onToggleExpanded,
    required this.onSelectAccount,
    required this.onSelectFolder,
  });

  final MailAccount account;
  final MailboxState state;
  final AppSettingsState settings;
  final VoidCallback onToggleExpanded;
  final VoidCallback onSelectAccount;
  final void Function(String accountId, String folderId) onSelectFolder;

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
        if (expanded)
          for (final MailFolder folder in roots)
            ..._folderBranch(
              folder: folder,
              all: folders,
              depth: 1,
              tokensMuted: t.muted,
              tokensText: t.text,
              tokensTeal: t.teal,
            ),
      ],
    );
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

  List<Widget> _folderBranch({
    required MailFolder folder,
    required List<MailFolder> all,
    required int depth,
    required Color tokensMuted,
    required Color tokensText,
    required Color tokensTeal,
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
        trailing: (folder.unreadCount ?? 0) > 0
            ? '${folder.unreadCount}'
            : null,
        trailingColor: tokensTeal,
        onTap: () => onSelectFolder(account.id, folder.id),
      ),
      for (final MailFolder child in children)
        ..._folderBranch(
          folder: child,
          all: all,
          depth: depth + 1,
          tokensMuted: tokensMuted,
          tokensText: tokensText,
          tokensTeal: tokensTeal,
        ),
    ];
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? accent;
  final String? trailing;
  final Color? trailingColor;
  final Widget? leading;
  final double indent;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 2, left: indent),
      child: Material(
        color: selected ? t.teal.withValues(alpha: 0.12) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
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
    );
  }
}
