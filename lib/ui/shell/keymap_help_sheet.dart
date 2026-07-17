// ==============================================================================
// File: lib/ui/shell/keymap_help_sheet.dart
// Description: Overlay listing workspace keyboard shortcuts
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Shows the documented ByteMail workspace keymap.
Future<void> showKeymapHelpSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: tokensOf(context).panel,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) {
      final ThemeTokens t = tokensOf(context);
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Keyboard shortcuts',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Shortcuts are skipped while typing in a text field.',
              style: TextStyle(color: t.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: const <Widget>[
                  _KeymapRow(keys: 'Ctrl+J / Ctrl+K', action: 'Next / previous message'),
                  _KeymapRow(keys: 'Ctrl+N', action: 'Compose'),
                  _KeymapRow(keys: 'Ctrl+F', action: 'Find in message'),
                  _KeymapRow(keys: 'Ctrl+Shift+F or /', action: 'Mailbox search'),
                  _KeymapRow(keys: 'Ctrl+U', action: 'Toggle read/unread (bulk-aware)'),
                  _KeymapRow(keys: 'Ctrl+Shift+M', action: 'Toggle Visual Focus'),
                  _KeymapRow(keys: '?', action: 'Show this help'),
                  _KeymapRow(keys: 'Delete', action: 'Trash (or permanent delete in Trash)'),
                  _KeymapRow(keys: 'Shift+Delete', action: 'Permanent delete'),
                  _KeymapRow(keys: 'E', action: 'Archive'),
                  _KeymapRow(keys: 'R / Shift+R', action: 'Reply / reply all'),
                  _KeymapRow(keys: 'F', action: 'Forward'),
                  _KeymapRow(keys: 'S', action: 'Star'),
                  _KeymapRow(keys: 'B', action: 'Snooze'),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _KeymapRow extends StatelessWidget {
  const _KeymapRow({required this.keys, required this.action});

  final String keys;
  final String action;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 160,
            child: Text(
              keys,
              style: TextStyle(
                color: t.text,
                fontWeight: FontWeight.w600,
                fontFamily: 'Consolas',
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(action, style: TextStyle(color: t.muted, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
