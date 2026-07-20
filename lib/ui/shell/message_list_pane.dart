// ==============================================================================
// File: lib/ui/shell/message_list_pane.dart
// Description: Projected message list with filters, threads, swipes, and refresh
// Component: UI
// Version: 1.2 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-18
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:bytemail/domain/address_match_scope.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/saved_message_filter.dart';
import 'package:bytemail/mailbox/message_list_projector.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/common/empty_state.dart';
import 'package:bytemail/ui/mailbox/message_filter_bar.dart';
import 'package:bytemail/ui/shell/address_scope_action.dart';

typedef MessageSelectCallback =
    void Function(String id, {bool ctrl, bool shift});

typedef MessageSwipeCallback =
    void Function(String messageId, SwipeListAction action);

class MessageListPane extends StatelessWidget {
  const MessageListPane({
    super.key,
    required this.sections,
    required this.messages,
    required this.accounts,
    required this.selectedId,
    required this.selectedIds,
    required this.expandedThreadIds,
    required this.focusEnabled,
    required this.focusFilter,
    required this.density,
    required this.onSelect,
    required this.onFocusFilter,
    this.userFilter,
    this.onUserFilterChanged,
    this.onClearUserFilter,
    this.savedFilters = const <SavedMessageFilter>[],
    this.onApplySavedFilter,
    this.onSaveCurrentFilter,
    this.onRenameSavedFilter,
    this.onDeleteSavedFilter,
    this.onToggleThreadExpand,
    this.onMarkReadBulk,
    this.onMarkUnreadBulk,
    this.onArchiveBulk,
    this.onDeleteBulk,
    this.onStarBulk,
    this.onNotJunkBulk,
    this.onMarkFocusedBulk,
    this.onMarkOtherBulk,
    this.onReportJunkBulk,
    this.onToggleStar,
    this.onClearSelection,
    this.onShowSidebar,
    this.onRemoteSearch,
    this.onRefresh,
    this.onSwipe,
    this.swipeRightAction = SwipeListAction.archive,
    this.swipeLeftAction = SwipeListAction.delete,
    this.disableDestructiveSwipe = false,
  });

  /// Projected dated / threaded sections from [MailboxState.listSections].
  final List<MessageListSection> sections;

  /// Flat source messages (bulk sample address + empty checks).
  final List<MailMessage> messages;
  final List<MailAccount> accounts;
  final String? selectedId;
  final Set<String> selectedIds;
  final Set<String> expandedThreadIds;
  final bool focusEnabled;
  final FocusBucket focusFilter;
  final ViewDensity density;
  final MessageSelectCallback onSelect;
  final ValueChanged<FocusBucket> onFocusFilter;
  final MessageViewFilter? userFilter;
  final ValueChanged<MessageViewFilter>? onUserFilterChanged;
  final VoidCallback? onClearUserFilter;
  final List<SavedMessageFilter> savedFilters;
  final ValueChanged<MessageViewFilter>? onApplySavedFilter;
  final Future<bool> Function(String name, MessageViewFilter filter)?
      onSaveCurrentFilter;
  final Future<void> Function(String id, String newName)? onRenameSavedFilter;
  final Future<void> Function(String id)? onDeleteSavedFilter;
  final ValueChanged<String>? onToggleThreadExpand;
  final VoidCallback? onMarkReadBulk;
  final VoidCallback? onMarkUnreadBulk;
  final VoidCallback? onArchiveBulk;
  final VoidCallback? onDeleteBulk;
  final VoidCallback? onStarBulk;
  final ValueChanged<AddressMatchScope>? onNotJunkBulk;
  final ValueChanged<AddressMatchScope>? onMarkFocusedBulk;
  final ValueChanged<AddressMatchScope>? onMarkOtherBulk;
  final ValueChanged<AddressMatchScope>? onReportJunkBulk;
  final ValueChanged<String>? onToggleStar;
  final VoidCallback? onClearSelection;
  final VoidCallback? onShowSidebar;
  final VoidCallback? onRemoteSearch;

  /// Pull-to-refresh; typically [MailboxCubit.syncCurrentFolder].
  final Future<void> Function()? onRefresh;

  /// Android swipe action dispatcher (message id + configured action).
  final MessageSwipeCallback? onSwipe;

  final SwipeListAction swipeRightAction;
  final SwipeListAction swipeLeftAction;

  /// When true (trash folder), delete swipes are disabled — permanent delete
  /// needs an explicit confirm path.
  final bool disableDestructiveSwipe;

  bool get _selectionMode => selectedIds.isNotEmpty;

  bool get _swipesEnabled =>
      onSwipe != null &&
      !_selectionMode &&
      defaultTargetPlatform == TargetPlatform.android;

  String _bulkSampleAddress() {
    for (final MailMessage message in messages) {
      if (selectedIds.contains(message.id)) {
        return message.fromAddress;
      }
    }
    return '';
  }

  List<_ListEntry> _flattenEntries() {
    final List<_ListEntry> entries = <_ListEntry>[];
    for (final MessageListSection section in sections) {
      if (section.title.isNotEmpty) {
        entries.add(_ListEntry.header(section.title));
      }
      for (final MessageListItem item in section.items) {
        entries.add(_ListEntry.item(item));
      }
    }
    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final List<_ListEntry> entries = _flattenEntries();
    return Container(
      decoration: BoxDecoration(
        color: t.ink,
        border: Border(right: BorderSide(color: t.line)),
      ),
      child: Column(
        children: <Widget>[
          if (_selectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: _BulkToolbar(
                count: selectedIds.length,
                sampleAddress: _bulkSampleAddress(),
                onMarkRead: onMarkReadBulk,
                onMarkUnread: onMarkUnreadBulk,
                onArchive: onArchiveBulk,
                onDelete: onDeleteBulk,
                onStar: onStarBulk,
                onNotJunk: onNotJunkBulk,
                onReportJunk: onReportJunkBulk,
                onMarkFocused: onMarkFocusedBulk,
                onMarkOther: onMarkOtherBulk,
                onClear: onClearSelection,
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(12, _selectionMode ? 8 : 12, 12, 8),
            child: Column(
              children: <Widget>[
                if (onShowSidebar != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onShowSidebar,
                      icon: Icon(Icons.menu, size: 16, color: t.teal),
                      label: Text(
                        'Show folders',
                        style: TextStyle(color: t.teal),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: t.ink.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: t.line),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.search, size: 18, color: t.amethyst),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Search local mail (FTS5)…',
                          style: TextStyle(color: t.muted, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                if (focusEnabled) ...<Widget>[
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: _FocusChip(
                          label: 'Focused',
                          selected: focusFilter == FocusBucket.focused,
                          selectedColors: <Color>[t.emerald, t.teal],
                          onTap: () => onFocusFilter(FocusBucket.focused),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: _FocusChip(
                          label: 'Other',
                          selected: focusFilter == FocusBucket.other,
                          selectedColors: <Color>[
                            t.coral,
                            const Color(0xFFFB923C),
                          ],
                          onTap: () => onFocusFilter(FocusBucket.other),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Focus off · showing all mail',
                        style: TextStyle(color: t.muted, fontSize: 12),
                      ),
                    ),
                  ),
                if (onUserFilterChanged != null &&
                    onClearUserFilter != null) ...<Widget>[
                  const SizedBox(height: 8),
                  MessageFilterBar(
                    filter: userFilter,
                    onFilterChanged: onUserFilterChanged!,
                    onClearFilters: onClearUserFilter!,
                    savedFilters: savedFilters,
                    onApplySavedFilter: onApplySavedFilter,
                    onSaveCurrentFilter: onSaveCurrentFilter,
                    onRenameSavedFilter: onRenameSavedFilter,
                    onDeleteSavedFilter: onDeleteSavedFilter,
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: OutlinedButton(
              onPressed: onRemoteSearch,
              style: OutlinedButton.styleFrom(
                foregroundColor: t.azure,
                side: BorderSide(color: t.azure.withValues(alpha: 0.45)),
                minimumSize: const Size.fromHeight(36),
              ),
              child: const Text(
                'Search older emails on the server',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
          Expanded(
            child: _buildMessageList(context, t, entries),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    BuildContext context,
    ThemeTokens t,
    List<_ListEntry> entries,
  ) {
    final Widget list = entries.isEmpty
        ? ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: <Widget>[
              SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.35,
                child: EmptyState(
                  title: 'No messages',
                  subtitle: 'Sync or change filters to see mail here.',
                  icon: Icons.mail_outline,
                  density: density,
                ),
              ),
            ],
          )
        : ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            itemCount: entries.length,
            itemBuilder: (BuildContext context, int index) {
              final _ListEntry entry = entries[index];
              if (entry.isHeader) {
                return Padding(
                  padding: EdgeInsets.fromLTRB(
                    4,
                    index == 0 ? 4 : 12,
                    4,
                    6,
                  ),
                  child: Text(
                    entry.headerTitle!,
                    style: TextStyle(
                      color: t.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.6,
                    ),
                  ),
                );
              }
              final MessageListItem item = entry.item!;
              final Widget row = Padding(
                padding: EdgeInsets.only(bottom: density.listGap),
                child: switch (item) {
                  ThreadItem thread => _ThreadRow(
                    thread: thread,
                    accounts: accounts,
                    selectedId: selectedId,
                    selectedIds: selectedIds,
                    expanded: expandedThreadIds.contains(
                      thread.expansionKey,
                    ),
                    showCheckbox: _selectionMode,
                    density: density,
                    onSelect: onSelect,
                    onToggleExpand: onToggleThreadExpand == null
                        ? null
                        : () => onToggleThreadExpand!(
                              thread.expansionKey,
                            ),
                    onToggleStar: onToggleStar == null
                        ? null
                        : () => onToggleStar!(thread.latest.id),
                  ),
                  FlatMessageItem flat => _MessageRow(
                    message: flat.message,
                    accent: _accentFor(flat.message.accountId, t),
                    selected: flat.message.id == selectedId,
                    bulkSelected: selectedIds.contains(
                      flat.message.id,
                    ),
                    showCheckbox: _selectionMode,
                    density: density,
                    indented: _isExpandedThreadChild(flat.message),
                    onTap: () {
                      final bool ctrl =
                          HardwareKeyboard.instance.isControlPressed;
                      final bool shift =
                          HardwareKeyboard.instance.isShiftPressed;
                      onSelect(
                        flat.message.id,
                        ctrl: ctrl,
                        shift: shift,
                      );
                    },
                    onCheckboxToggle: () =>
                        onSelect(flat.message.id, ctrl: true),
                    onToggleStar: onToggleStar == null
                        ? null
                        : () => onToggleStar!(flat.message.id),
                  ),
                },
              );
              final String swipeId = switch (item) {
                ThreadItem thread => thread.latest.id,
                FlatMessageItem flat => flat.message.id,
              };
              return _wrapSwipe(context, messageId: swipeId, child: row);
            },
          );

    if (onRefresh == null) {
      return list;
    }
    return RefreshIndicator(
      color: t.teal,
      onRefresh: onRefresh!,
      child: list,
    );
  }

  Widget _wrapSwipe(
    BuildContext context, {
    required String messageId,
    required Widget child,
  }) {
    if (!_swipesEnabled) {
      return child;
    }
    final SwipeListAction right = _effectiveAction(swipeRightAction);
    final SwipeListAction left = _effectiveAction(swipeLeftAction);
    if (right == SwipeListAction.none && left == SwipeListAction.none) {
      return child;
    }

    DismissDirection direction;
    if (right != SwipeListAction.none && left != SwipeListAction.none) {
      direction = DismissDirection.horizontal;
    } else if (right != SwipeListAction.none) {
      direction = DismissDirection.startToEnd;
    } else {
      direction = DismissDirection.endToStart;
    }

    final ThemeTokens t = tokensOf(context);
    return Dismissible(
      key: ValueKey<String>('swipe-$messageId'),
      direction: direction,
      dismissThresholds: const <DismissDirection, double>{
        DismissDirection.startToEnd: 0.28,
        DismissDirection.endToStart: 0.28,
      },
      confirmDismiss: (DismissDirection dismissDirection) async {
        final SwipeListAction action =
            dismissDirection == DismissDirection.startToEnd ? right : left;
        if (action == SwipeListAction.none) {
          return false;
        }
        onSwipe!(messageId, action);
        // Snap back; archive/delete remove the row via cubit refresh.
        // Star/snooze also keep the row.
        return false;
      },
      background: _SwipeBackground(
        action: right,
        alignment: Alignment.centerLeft,
        tokens: t,
      ),
      secondaryBackground: _SwipeBackground(
        action: left,
        alignment: Alignment.centerRight,
        tokens: t,
      ),
      child: child,
    );
  }

  SwipeListAction _effectiveAction(SwipeListAction action) {
    if (disableDestructiveSwipe && action == SwipeListAction.delete) {
      return SwipeListAction.none;
    }
    return action;
  }

  Color _accentFor(String accountId, ThemeTokens t) {
    for (final MailAccount account in accounts) {
      if (account.id == accountId) {
        return account.accent;
      }
    }
    return t.indigo;
  }

  /// Expanded thread children sit under a [ThreadItem]; indent them slightly.
  bool _isExpandedThreadChild(MailMessage message) {
    final String key = ThreadItem.expansionKeyFor(
      message.accountId,
      message.threadId ?? message.id,
    );
    return expandedThreadIds.contains(key);
  }
}

class _ListEntry {
  const _ListEntry._({this.headerTitle, this.item});

  factory _ListEntry.header(String title) => _ListEntry._(headerTitle: title);

  factory _ListEntry.item(MessageListItem item) => _ListEntry._(item: item);

  final String? headerTitle;
  final MessageListItem? item;

  bool get isHeader => headerTitle != null;
}

class _SwipeBackground extends StatelessWidget {
  const _SwipeBackground({
    required this.action,
    required this.alignment,
    required this.tokens,
  });

  final SwipeListAction action;
  final Alignment alignment;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color color, String label) = switch (action) {
      SwipeListAction.archive => (
          Icons.archive_outlined,
          tokens.teal,
          'Archive',
        ),
      SwipeListAction.delete => (
          Icons.delete_outline,
          tokens.coral,
          'Delete',
        ),
      SwipeListAction.star => (
          Icons.star_rounded,
          tokens.amber,
          'Star',
        ),
      SwipeListAction.snooze => (
          Icons.snooze,
          tokens.azure,
          'Snooze',
        ),
      SwipeListAction.none => (
          Icons.block,
          tokens.muted,
          '',
        ),
    };
    return Container(
      alignment: alignment,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (alignment == Alignment.centerLeft) ...<Widget>[
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ] else ...<Widget>[
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: color, size: 22),
          ],
        ],
      ),
    );
  }
}

class _BulkToolbar extends StatelessWidget {
  const _BulkToolbar({
    required this.count,
    required this.sampleAddress,
    this.onMarkRead,
    this.onMarkUnread,
    this.onArchive,
    this.onDelete,
    this.onStar,
    this.onNotJunk,
    this.onReportJunk,
    this.onMarkFocused,
    this.onMarkOther,
    this.onClear,
  });

  final int count;
  final String sampleAddress;
  final VoidCallback? onMarkRead;
  final VoidCallback? onMarkUnread;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final VoidCallback? onStar;
  final ValueChanged<AddressMatchScope>? onNotJunk;
  final ValueChanged<AddressMatchScope>? onReportJunk;
  final ValueChanged<AddressMatchScope>? onMarkFocused;
  final ValueChanged<AddressMatchScope>? onMarkOther;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: t.azure.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: t.azure.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: <Widget>[
          Text(
            '$count selected',
            style: TextStyle(
              color: t.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          if (onNotJunk != null)
            AddressScopeBulkAction(
              label: 'Not junk',
              color: t.emerald,
              sampleAddress: sampleAddress,
              onSelected: onNotJunk!,
            ),
          if (onReportJunk != null) ...<Widget>[
            if (onNotJunk != null) const SizedBox(width: 4),
            AddressScopeBulkAction(
              label: 'Junk',
              color: t.coral,
              sampleAddress: sampleAddress,
              onSelected: onReportJunk!,
            ),
          ],
          if (onMarkFocused != null) ...<Widget>[
            if (onNotJunk != null || onReportJunk != null)
              const SizedBox(width: 4),
            AddressScopeBulkAction(
              label: 'Focused',
              color: t.teal,
              sampleAddress: sampleAddress,
              onSelected: onMarkFocused!,
            ),
          ],
          if (onMarkOther != null) ...<Widget>[
            const SizedBox(width: 4),
            AddressScopeBulkAction(
              label: 'Other',
              color: t.azure,
              sampleAddress: sampleAddress,
              onSelected: onMarkOther!,
            ),
          ],
          if (onArchive != null) ...<Widget>[
            const SizedBox(width: 4),
            _BulkAction(label: 'Archive', color: t.teal, onPressed: onArchive!),
          ],
          if (onDelete != null) ...<Widget>[
            const SizedBox(width: 4),
            _BulkAction(label: 'Delete', color: t.coral, onPressed: onDelete!),
          ],
          if (onStar != null) ...<Widget>[
            const SizedBox(width: 4),
            _BulkAction(label: 'Star', color: t.amber, onPressed: onStar!),
          ],
          if (onMarkRead != null) ...<Widget>[
            const SizedBox(width: 4),
            _BulkAction(
              label: 'Mark read',
              color: t.teal,
              onPressed: onMarkRead!,
            ),
          ],
          if (onMarkUnread != null) ...<Widget>[
            const SizedBox(width: 4),
            _BulkAction(
              label: 'Mark unread',
              color: t.azure,
              onPressed: onMarkUnread!,
            ),
          ],
          if (onClear != null) ...<Widget>[
            const SizedBox(width: 4),
            IconButton(
              onPressed: onClear,
              icon: Icon(Icons.close, size: 16, color: t.muted),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Clear selection',
            ),
          ],
        ],
      ),
    );
  }
}

class _BulkAction extends StatelessWidget {
  const _BulkAction({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}

class _FocusChip extends StatelessWidget {
  const _FocusChip({
    required this.label,
    required this.selected,
    required this.selectedColors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final List<Color> selectedColors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: selected ? Colors.transparent : t.line),
            gradient: selected ? LinearGradient(colors: selectedColors) : null,
            color: selected ? null : t.panel.withValues(alpha: 0.6),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? t.onAccent : t.muted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThreadRow extends StatelessWidget {
  const _ThreadRow({
    required this.thread,
    required this.accounts,
    required this.selectedId,
    required this.selectedIds,
    required this.expanded,
    required this.showCheckbox,
    required this.density,
    required this.onSelect,
    this.onToggleExpand,
    this.onToggleStar,
  });

  final ThreadItem thread;
  final List<MailAccount> accounts;
  final String? selectedId;
  final Set<String> selectedIds;
  final bool expanded;
  final bool showCheckbox;
  final ViewDensity density;
  final MessageSelectCallback onSelect;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onToggleStar;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final MailMessage latest = thread.latest;
    final Color accent = () {
      for (final MailAccount account in accounts) {
        if (account.id == latest.accountId) {
          return account.accent;
        }
      }
      return t.indigo;
    }();
    final bool selected = latest.id == selectedId;
    final bool bulkSelected = selectedIds.contains(latest.id);
    final bool highlighted = selected || bulkSelected;
    final Color dim = t.muted.withValues(alpha: 0.85);
    final Color fromColor = thread.anyUnread ? t.text : dim;
    final Color subjectColor = thread.anyUnread
        ? t.text
        : t.muted.withValues(alpha: 0.9);
    final Color snippetColor = thread.anyUnread
        ? t.muted
        : t.muted.withValues(alpha: 0.7);

    return Material(
      color: highlighted
          ? t.azure.withValues(alpha: 0.16)
          : density == ViewDensity.calm
          ? t.panel.withValues(alpha: 0.55)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(density.messageRadius),
      child: InkWell(
        onTap: () {
          final bool ctrl = HardwareKeyboard.instance.isControlPressed;
          final bool shift = HardwareKeyboard.instance.isShiftPressed;
          onSelect(latest.id, ctrl: ctrl, shift: shift);
        },
        borderRadius: BorderRadius.circular(density.messageRadius),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Container(width: 4, color: accent),
              if (showCheckbox)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: Center(
                    child: Checkbox(
                      value: bulkSelected,
                      onChanged: (_) => onSelect(latest.id, ctrl: true),
                      activeColor: t.teal,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              if (onToggleStar != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Center(
                    child: IconButton(
                      onPressed: onToggleStar,
                      icon: Icon(
                        thread.anyStarred
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 18,
                        color: thread.anyStarred ? t.amber : t.muted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: thread.anyStarred ? 'Unstar' : 'Star',
                    ),
                  ),
                ),
              if (onToggleExpand != null)
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Center(
                    child: IconButton(
                      onPressed: onToggleExpand,
                      icon: Icon(
                        expanded
                            ? Icons.expand_more_rounded
                            : Icons.chevron_right_rounded,
                        size: 18,
                        color: t.muted,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 28,
                        minHeight: 28,
                      ),
                      tooltip: expanded ? 'Collapse thread' : 'Expand thread',
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: density.listRowPaddingH,
                    vertical: density.listRowPaddingV,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          if (thread.anyUnread)
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: t.teal,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          if (thread.anyPinned)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Icon(
                                Icons.push_pin_rounded,
                                size: 12,
                                color: t.amethyst,
                              ),
                            ),
                          Expanded(
                            child: Text(
                              thread.participantSummary.isEmpty
                                  ? latest.fromName
                                  : thread.participantSummary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: fromColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(left: 6, right: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: t.panel2,
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: t.line),
                            ),
                            child: Text(
                              '${thread.count}',
                              style: TextStyle(
                                color: t.muted,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            latest.whenLabel,
                            style: TextStyle(color: t.muted, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        latest.subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: subjectColor,
                          fontSize: density.subjectSize,
                          fontWeight: thread.anyUnread
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        latest.snippet,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: snippetColor,
                          fontSize: density.snippetSize,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.accent,
    required this.selected,
    required this.bulkSelected,
    required this.showCheckbox,
    required this.density,
    required this.onTap,
    this.indented = false,
    this.onCheckboxToggle,
    this.onToggleStar,
  });

  final MailMessage message;
  final Color accent;
  final bool selected;
  final bool bulkSelected;
  final bool showCheckbox;
  final ViewDensity density;
  final bool indented;
  final VoidCallback onTap;
  final VoidCallback? onCheckboxToggle;
  final VoidCallback? onToggleStar;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final bool highlighted = selected || bulkSelected;
    // UI-P2: mute from/subject/snippet on read rows.
    final Color fromColor = message.unread
        ? t.text
        : t.muted.withValues(alpha: 0.85);
    final Color subjectColor = message.unread
        ? t.text
        : t.muted.withValues(alpha: 0.9);
    final Color snippetColor = message.unread
        ? t.muted
        : t.muted.withValues(alpha: 0.7);

    return Padding(
      padding: EdgeInsets.only(left: indented ? 16 : 0),
      child: Material(
        // UI-P12: selection uses azure wash — distinct from account accent stripe.
        color: highlighted
            ? t.azure.withValues(alpha: 0.16)
            : density == ViewDensity.calm
            ? t.panel.withValues(alpha: 0.55)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(density.messageRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(density.messageRadius),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(width: 4, color: accent),
                if (showCheckbox)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Center(
                      child: Checkbox(
                        value: bulkSelected,
                        onChanged: onCheckboxToggle == null
                            ? null
                            : (_) => onCheckboxToggle!(),
                        activeColor: t.teal,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                if (onToggleStar != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Center(
                      child: IconButton(
                        onPressed: onToggleStar,
                        icon: Icon(
                          message.starred
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 18,
                          color: message.starred ? t.amber : t.muted,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 28,
                          minHeight: 28,
                        ),
                        tooltip: message.starred ? 'Unstar' : 'Star',
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: density.listRowPaddingH,
                      vertical: density.listRowPaddingV,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            if (message.unread)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: t.teal,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            if (message.pinned)
                              Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.push_pin_rounded,
                                  size: 12,
                                  color: t.amethyst,
                                ),
                              ),
                            Expanded(
                              child: Text(
                                message.fromName,
                                style: TextStyle(
                                  color: fromColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              message.whenLabel,
                              style: TextStyle(color: t.muted, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          message.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: subjectColor,
                            fontSize: density.subjectSize,
                            fontWeight: message.unread
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          message.snippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: snippetColor,
                            fontSize: density.snippetSize,
                          ),
                        ),
                      ],
                    ),
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
