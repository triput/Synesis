// ==============================================================================
// File: lib/ui/shell/mailbox_dialogs.dart
// Description: Confirm / move dialogs used by the mailbox workspace
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/ui/mailbox/mailbox_state.dart';
import 'package:bytemail/ui/shell/move_folder_dialog.dart';

/// Confirms creating a missing system folder (e.g. Archive / Junk) on the server.
Future<bool> confirmCreateSystemFolder(
  BuildContext context, {
  required String accountId,
  required String roleDisplayName,
  required List<MailAccount> accounts,
}) async {
  if (!context.mounted) {
    return false;
  }
  String address = accountId;
  for (final MailAccount account in accounts) {
    if (account.id == accountId) {
      address = account.address;
      break;
    }
  }
  final t = tokensOf(context);
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: t.panel,
        title: Text('Create $roleDisplayName folder?'),
        content: Text(
          'No $roleDisplayName folder found for $address. '
          'Create one on the server?',
          style: TextStyle(color: t.muted),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Create'),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}

/// Confirms permanent delete, then runs [MailboxCubit.deleteSelected].
Future<void> confirmPermanentDelete(
  BuildContext context,
  MailboxCubit cubit,
) async {
  if (cubit.state.selectedMessage == null &&
      cubit.state.selectedMessageIds.isEmpty) {
    return;
  }
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) {
      final t = tokensOf(dialogContext);
      return AlertDialog(
        backgroundColor: t.panel,
        title: const Text('Delete permanently?'),
        content: Text(
          'This cannot be undone.',
          style: TextStyle(color: t.muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: t.coral),
            child: const Text('Delete permanently'),
          ),
        ],
      );
    },
  );
  if (confirmed == true && context.mounted) {
    await cubit.deleteSelected(permanent: true);
  }
}

/// Shows the move-folder picker and moves the selection when a folder is chosen.
Future<void> showMailboxMoveDialog(
  BuildContext context,
  MailboxCubit cubit,
  MailboxState mailbox,
) async {
  final MailMessage? selected = mailbox.selectedMessage;
  if (selected == null) {
    return;
  }
  final List<MailFolder> folders = mailbox.foldersForAccount(
    selected.accountId,
  );
  final String? folderId = await showMoveFolderDialog(
    context,
    folders: folders,
  );
  if (folderId != null && context.mounted) {
    await cubit.moveSelectedToFolder(folderId);
  }
}
