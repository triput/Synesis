// ==============================================================================
// File: lib/ui/mailbox/saved_filters_sheet.dart
// Description: Apply, save, rename, and delete named message list filters.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:bytemail/domain/saved_message_filter.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';

/// Opens the saved-filters management sheet.
Future<void> showSavedFiltersSheet(
  BuildContext context, {
  required List<SavedMessageFilter> savedFilters,
  required MessageViewFilter currentFilter,
  required ValueChanged<MessageViewFilter> onApply,
  required Future<bool> Function(String name, MessageViewFilter filter)
      onSaveCurrent,
  required Future<void> Function(String id, String newName) onRename,
  required Future<void> Function(String id) onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: tokensOf(context).panel,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (BuildContext context) {
      return _SavedFiltersSheet(
        savedFilters: savedFilters,
        currentFilter: currentFilter,
        onApply: onApply,
        onSaveCurrent: onSaveCurrent,
        onRename: onRename,
        onDelete: onDelete,
      );
    },
  );
}

class _SavedFiltersSheet extends StatefulWidget {
  const _SavedFiltersSheet({
    required this.savedFilters,
    required this.currentFilter,
    required this.onApply,
    required this.onSaveCurrent,
    required this.onRename,
    required this.onDelete,
  });

  final List<SavedMessageFilter> savedFilters;
  final MessageViewFilter currentFilter;
  final ValueChanged<MessageViewFilter> onApply;
  final Future<bool> Function(String name, MessageViewFilter filter)
      onSaveCurrent;
  final Future<void> Function(String id, String newName) onRename;
  final Future<void> Function(String id) onDelete;

  @override
  State<_SavedFiltersSheet> createState() => _SavedFiltersSheetState();
}

class _SavedFiltersSheetState extends State<_SavedFiltersSheet> {
  late List<SavedMessageFilter> _filters;

  @override
  void initState() {
    super.initState();
    _filters = List<SavedMessageFilter>.from(widget.savedFilters);
  }

  Future<void> _saveCurrent() async {
    final String? name = await _promptForName(
      context,
      title: 'Save filter',
      hint: 'Filter name',
    );
    if (name == null || !mounted) {
      return;
    }
    final bool saved = await widget.onSaveCurrent(name, widget.currentFilter);
    if (!mounted) {
      return;
    }
    if (!saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save filter (name empty or limit reached).'),
        ),
      );
      return;
    }
    Navigator.of(context).pop();
  }

  Future<void> _renameFilter(SavedMessageFilter filter) async {
    final String? name = await _promptForName(
      context,
      title: 'Rename filter',
      hint: 'Filter name',
      initial: filter.name,
    );
    if (name == null || !mounted) {
      return;
    }
    await widget.onRename(filter.id, name);
    if (!mounted) {
      return;
    }
    setState(() {
      _filters = _filters
          .map(
            (SavedMessageFilter entry) => entry.id == filter.id
                ? entry.copyWith(name: name.trim())
                : entry,
          )
          .toList(growable: false);
    });
  }

  Future<void> _deleteFilter(SavedMessageFilter filter) async {
    await widget.onDelete(filter.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _filters = _filters
          .where((SavedMessageFilter entry) => entry.id != filter.id)
          .toList(growable: false);
    });
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
            'Saved filters',
            style: TextStyle(
              color: t.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (_filters.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No saved filters yet.',
                style: TextStyle(color: t.muted, fontSize: 13),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => Divider(color: t.line, height: 1),
                itemBuilder: (BuildContext context, int index) {
                  final SavedMessageFilter filter = _filters[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      filter.name,
                      style: TextStyle(color: t.text, fontSize: 14),
                    ),
                    onTap: () {
                      widget.onApply(filter.filter);
                      Navigator.of(context).pop();
                    },
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_horiz_rounded, color: t.muted),
                      onSelected: (String action) {
                        switch (action) {
                          case 'rename':
                            unawaited(_renameFilter(filter));
                          case 'delete':
                            unawaited(_deleteFilter(filter));
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                          const <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'rename',
                          child: Text('Rename'),
                        ),
                        PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _saveCurrent,
            icon: const Icon(Icons.bookmark_add_outlined, size: 18),
            label: const Text('Save current filter'),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ),
        ],
      ),
    );
  }
}

Future<String?> _promptForName(
  BuildContext context, {
  required String title,
  required String hint,
  String initial = '',
}) {
  final TextEditingController controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: hint,
            border: const OutlineInputBorder(),
          ),
          onSubmitted: (String value) {
            final String trimmed = value.trim();
            Navigator.of(dialogContext).pop(trimmed.isEmpty ? null : trimmed);
          },
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final String trimmed = controller.text.trim();
              Navigator.of(dialogContext).pop(trimmed.isEmpty ? null : trimmed);
            },
            child: const Text('Save'),
          ),
        ],
      );
    },
  );
}
