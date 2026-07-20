// ==============================================================================
// File: lib/ui/mailbox/message_filter_bar.dart
// Description: Quick filter chips and advanced filter sheet for the message list
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-18
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:bytemail/domain/saved_message_filter.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/mailbox/saved_filters_sheet.dart';

/// Compact chip row for list filters. Focus chips stay independent of this bar.
class MessageFilterBar extends StatelessWidget {
  const MessageFilterBar({
    super.key,
    required this.filter,
    required this.onFilterChanged,
    required this.onClearFilters,
    this.savedFilters = const <SavedMessageFilter>[],
    this.onApplySavedFilter,
    this.onSaveCurrentFilter,
    this.onRenameSavedFilter,
    this.onDeleteSavedFilter,
  });

  final MessageViewFilter? filter;
  final ValueChanged<MessageViewFilter> onFilterChanged;
  final VoidCallback onClearFilters;
  final List<SavedMessageFilter> savedFilters;
  final ValueChanged<MessageViewFilter>? onApplySavedFilter;
  final Future<bool> Function(String name, MessageViewFilter filter)?
      onSaveCurrentFilter;
  final Future<void> Function(String id, String newName)? onRenameSavedFilter;
  final Future<void> Function(String id)? onDeleteSavedFilter;

  bool get _hasActiveFilter {
    final MessageViewFilter? f = filter;
    if (f == null) {
      return false;
    }
    return f.unread != null ||
        f.starred != null ||
        f.hasAttachments != null ||
        (f.senderContains != null && f.senderContains!.trim().isNotEmpty) ||
        (f.recipientContains != null &&
            f.recipientContains!.trim().isNotEmpty) ||
        f.receivedAfterEpochMs != null ||
        f.receivedBeforeEpochMs != null ||
        (f.keyword != null && f.keyword!.trim().isNotEmpty);
  }

  bool get _savedEnabled =>
      onApplySavedFilter != null &&
      onSaveCurrentFilter != null &&
      onRenameSavedFilter != null &&
      onDeleteSavedFilter != null;

  MessageViewFilter get _current => filter ?? const MessageViewFilter();

  void _toggleUnread() {
    final MessageViewFilter current = _current;
    if (current.unread == true) {
      onFilterChanged(current.copyWith(clearUnread: true));
    } else {
      onFilterChanged(current.copyWith(unread: true));
    }
  }

  void _toggleStarred() {
    final MessageViewFilter current = _current;
    if (current.starred == true) {
      onFilterChanged(current.copyWith(clearStarred: true));
    } else {
      onFilterChanged(current.copyWith(starred: true));
    }
  }

  void _toggleAttachments() {
    final MessageViewFilter current = _current;
    if (current.hasAttachments == true) {
      onFilterChanged(current.copyWith(clearHasAttachments: true));
    } else {
      onFilterChanged(current.copyWith(hasAttachments: true));
    }
  }

  Future<void> _openAdvancedSheet(BuildContext context) async {
    final MessageViewFilter? result = await showMessageFilterSheet(
      context,
      initial: _current,
    );
    if (result != null) {
      onFilterChanged(result);
    }
  }

  Future<void> _openSavedSheet(BuildContext context) async {
    if (!_savedEnabled) {
      return;
    }
    await showSavedFiltersSheet(
      context,
      savedFilters: savedFilters,
      currentFilter: _current,
      onApply: onApplySavedFilter!,
      onSaveCurrent: onSaveCurrentFilter!,
      onRename: onRenameSavedFilter!,
      onDelete: onDeleteSavedFilter!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final MessageViewFilter current = _current;
    final bool advancedActive =
        (current.senderContains != null &&
            current.senderContains!.trim().isNotEmpty) ||
        (current.recipientContains != null &&
            current.recipientContains!.trim().isNotEmpty) ||
        current.receivedAfterEpochMs != null ||
        current.receivedBeforeEpochMs != null ||
        (current.keyword != null && current.keyword!.trim().isNotEmpty);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          _FilterChip(
            label: 'Unread',
            selected: current.unread == true,
            onTap: _toggleUnread,
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Starred',
            selected: current.starred == true,
            onTap: _toggleStarred,
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'Has attachment',
            selected: current.hasAttachments == true,
            onTap: _toggleAttachments,
          ),
          const SizedBox(width: 6),
          _FilterChip(
            label: 'More',
            selected: advancedActive,
            icon: Icons.tune_rounded,
            onTap: () => _openAdvancedSheet(context),
          ),
          if (_savedEnabled) ...<Widget>[
            const SizedBox(width: 6),
            _FilterChip(
              label: 'Saved',
              selected: false,
              icon: Icons.bookmarks_outlined,
              onTap: () => _openSavedSheet(context),
            ),
          ],
          if (_hasActiveFilter) ...<Widget>[
            const SizedBox(width: 6),
            TextButton(
              onPressed: onClearFilters,
              style: TextButton.styleFrom(
                foregroundColor: t.coral,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Clear', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? t.teal.withValues(alpha: 0.55) : t.line,
            ),
            color: selected
                ? t.teal.withValues(alpha: 0.16)
                : t.panel.withValues(alpha: 0.55),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (icon != null) ...<Widget>[
                  Icon(
                    icon,
                    size: 14,
                    color: selected ? t.teal : t.muted,
                  ),
                  const SizedBox(width: 4),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? t.teal : t.muted,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
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

/// Modal sheet for sender, recipient, date range, and keyword filters.
Future<MessageViewFilter?> showMessageFilterSheet(
  BuildContext context, {
  required MessageViewFilter initial,
}) {
  return showModalBottomSheet<MessageViewFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: tokensOf(context).panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return _MessageFilterSheet(initial: initial);
    },
  );
}

class _MessageFilterSheet extends StatefulWidget {
  const _MessageFilterSheet({required this.initial});

  final MessageViewFilter initial;

  @override
  State<_MessageFilterSheet> createState() => _MessageFilterSheetState();
}

class _MessageFilterSheetState extends State<_MessageFilterSheet> {
  late final TextEditingController _senderController;
  late final TextEditingController _recipientController;
  late final TextEditingController _keywordController;
  DateTime? _after;
  DateTime? _before;

  @override
  void initState() {
    super.initState();
    _senderController = TextEditingController(
      text: widget.initial.senderContains ?? '',
    );
    _recipientController = TextEditingController(
      text: widget.initial.recipientContains ?? '',
    );
    _keywordController = TextEditingController(
      text: widget.initial.keyword ?? '',
    );
    final int? afterMs = widget.initial.receivedAfterEpochMs;
    final int? beforeMs = widget.initial.receivedBeforeEpochMs;
    if (afterMs != null) {
      _after = DateTime.fromMillisecondsSinceEpoch(afterMs);
    }
    if (beforeMs != null) {
      _before = DateTime.fromMillisecondsSinceEpoch(beforeMs);
    }
  }

  @override
  void dispose() {
    _senderController.dispose();
    _recipientController.dispose();
    _keywordController.dispose();
    super.dispose();
  }

  Future<void> _pickAfter() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _after ?? now,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _after = picked);
    }
  }

  Future<void> _pickBefore() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _before ?? now,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked != null) {
      setState(() => _before = picked);
    }
  }

  void _apply() {
    final String sender = _senderController.text.trim();
    final String recipient = _recipientController.text.trim();
    final String keyword = _keywordController.text.trim();
    final MessageViewFilter next = widget.initial.copyWith(
      senderContains: sender.isEmpty ? null : sender,
      clearSenderContains: sender.isEmpty,
      recipientContains: recipient.isEmpty ? null : recipient,
      clearRecipientContains: recipient.isEmpty,
      keyword: keyword.isEmpty ? null : keyword,
      clearKeyword: keyword.isEmpty,
      receivedAfterEpochMs: _after == null
          ? null
          : DateTime(_after!.year, _after!.month, _after!.day)
              .millisecondsSinceEpoch,
      clearReceivedAfterEpochMs: _after == null,
      receivedBeforeEpochMs: _before == null
          ? null
          : DateTime(_before!.year, _before!.month, _before!.day, 23, 59, 59)
              .millisecondsSinceEpoch,
      clearReceivedBeforeEpochMs: _before == null,
    );
    Navigator.of(context).pop(next);
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Any';
    }
    final String y = value.year.toString().padLeft(4, '0');
    final String m = value.month.toString().padLeft(2, '0');
    final String d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Filter messages',
            style: TextStyle(
              color: t.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _senderController,
            decoration: const InputDecoration(
              labelText: 'Sender contains',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _recipientController,
            decoration: const InputDecoration(
              labelText: 'Recipient contains',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keywordController,
            decoration: const InputDecoration(
              labelText: 'Keyword',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickAfter,
                  child: Text('From ${_formatDate(_after)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _pickBefore,
                  child: Text('To ${_formatDate(_before)}'),
                ),
              ),
            ],
          ),
          if (_after != null || _before != null) ...<Widget>[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() {
                  _after = null;
                  _before = null;
                }),
                child: const Text('Clear dates'),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _apply,
                child: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
