// ==============================================================================
// File: lib/ui/shell/move_folder_dialog.dart
// Description: Simple folder picker dialog for moving selected messages
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/theme/app_theme.dart';

/// Shows an [AlertDialog] listing [folders] and returns the chosen folder id.
Future<String?> showMoveFolderDialog(
  BuildContext context, {
  required List<MailFolder> folders,
}) {
  final t = tokensOf(context);
  final List<MailFolder> sorted = List<MailFolder>.of(folders)
    ..sort(
      (MailFolder a, MailFolder b) =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
    );

  return showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: t.panel,
        title: const Text('Move to folder'),
        content: SizedBox(
          width: 320,
          child: sorted.isEmpty
              ? Text(
                  'No folders available for this account.',
                  style: TextStyle(color: t.muted),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: sorted.length,
                  itemBuilder: (BuildContext context, int index) {
                    final MailFolder folder = sorted[index];
                    return ListTile(
                      title: Text(folder.name),
                      subtitle: folder.role == null
                          ? null
                          : Text(
                              folder.role!,
                              style: TextStyle(color: t.muted, fontSize: 12),
                            ),
                      onTap: () => Navigator.of(dialogContext).pop(folder.id),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}
