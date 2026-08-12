// ==============================================================================
// File: lib/ui/shell/mail_navigation_drawer.dart
// Description: Phone slide-out drawer for accounts, folders, and app actions
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-08-12
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:synesis/settings/app_settings_state.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/ui/branding/synesis_wordmark.dart';
import 'package:synesis/ui/mailbox/mailbox_state.dart';
import 'package:synesis/sync/sync_activity.dart';
import 'package:synesis/ui/shell/folder_sidebar.dart';

/// AquaMail-style navigation drawer for narrow/phone shells.
///
/// Reuses [FolderSidebar] in [FolderSidebar.embeddedInDrawer] mode and adds
/// footer actions (compose, outbox, sync status, settings).
class MailNavigationDrawer extends StatelessWidget {
  const MailNavigationDrawer({
    super.key,
    required this.state,
    required this.settings,
    required this.onCollapseAll,
    required this.onSelectUnified,
    required this.onSelectVirtualView,
    required this.onToggleAccountExpanded,
    required this.onSelectAccount,
    required this.onSelectFolder,
    required this.onMarkFolderUnread,
    required this.onCompose,
    required this.onOpenOutbox,
    required this.onOpenSettings,
    required this.onOpenSyncStatus,
    this.syncActivity = const SyncActivitySnapshot.idle(),
  });

  final MailboxState state;
  final AppSettingsState settings;
  final VoidCallback onCollapseAll;
  final VoidCallback onSelectUnified;
  final ValueChanged<MailboxVirtualView> onSelectVirtualView;
  final ValueChanged<String> onToggleAccountExpanded;
  final ValueChanged<String> onSelectAccount;
  final void Function(String accountId, String folderId) onSelectFolder;
  final MarkFolderUnread onMarkFolderUnread;
  final VoidCallback onCompose;
  final VoidCallback onOpenOutbox;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenSyncStatus;
  final SyncActivitySnapshot syncActivity;

  void _closeThen(BuildContext context, VoidCallback action) {
    Navigator.of(context).maybePop();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final int queued = state.queuedOutboxCount;
    final int failed = state.failedOutboxCount;
    final int outboxAttention = queued + failed;
    final String? outboxSubtitle = failed > 0
        ? (failed == 1 ? '1 failed' : '$failed failed')
        : (queued > 0
            ? (queued == 1 ? '1 queued' : '$queued queued')
            : null);
    return Drawer(
      backgroundColor: t.panel,
      width: 320,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 8),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SynesisWordmark(
                        fontSize: 18,
                        showIcon: true,
                        iconSize: 28,
                      ),
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
              child: FolderSidebar(
                state: state,
                settings: settings,
                syncActivity: syncActivity,
                embeddedInDrawer: true,
                onHideSidebar: () => Navigator.of(context).maybePop(),
                onCollapseAll: onCollapseAll,
                onSelectUnified: () => _closeThen(context, onSelectUnified),
                onSelectVirtualView: (MailboxVirtualView view) {
                  _closeThen(context, () => onSelectVirtualView(view));
                },
                onToggleAccountExpanded: onToggleAccountExpanded,
                onSelectAccount: (String id) {
                  _closeThen(context, () => onSelectAccount(id));
                },
                onSelectFolder: (String accountId, String folderId) {
                  _closeThen(
                    context,
                    () => onSelectFolder(accountId, folderId),
                  );
                },
                onMarkFolderUnread: onMarkFolderUnread,
              ),
            ),
            Divider(height: 1, color: t.line),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                children: <Widget>[
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.edit_outlined, color: t.teal),
                    title: Text('Compose', style: TextStyle(color: t.text)),
                    onTap: () => _closeThen(context, onCompose),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(
                      Icons.outbox_outlined,
                      color: failed > 0 ? t.coral : t.muted,
                    ),
                    title: Text('Outbox', style: TextStyle(color: t.text)),
                    subtitle: outboxSubtitle == null
                        ? null
                        : Text(
                            outboxSubtitle,
                            style: TextStyle(
                              color: failed > 0 ? t.coral : t.amber,
                              fontSize: 12,
                            ),
                          ),
                    trailing: outboxAttention > 0
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: failed > 0
                                  ? t.coral.withValues(alpha: 0.22)
                                  : t.amber.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '$outboxAttention',
                              style: TextStyle(
                                color: failed > 0 ? t.coral : t.amber,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : null,
                    onTap: () => _closeThen(context, onOpenOutbox),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.sync, color: t.muted),
                    title: Text('Sync status', style: TextStyle(color: t.text)),
                    onTap: () => _closeThen(context, onOpenSyncStatus),
                  ),
                  ListTile(
                    dense: true,
                    leading: Icon(Icons.settings_outlined, color: t.muted),
                    title: Text('Settings', style: TextStyle(color: t.text)),
                    onTap: () => _closeThen(context, onOpenSettings),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
