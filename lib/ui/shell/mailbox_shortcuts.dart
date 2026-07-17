// ==============================================================================
// File: lib/ui/shell/mailbox_shortcuts.dart
// Description: Hardware-key mailbox shortcuts and selection navigation helpers
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/desktop/keyboard_intents.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/ui/mailbox/mailbox_state.dart';

/// Callbacks for mailbox actions triggered by hardware shortcuts.
class MailboxShortcutActions {
  const MailboxShortcutActions({
    required this.onCompose,
    required this.onSearch,
    required this.onFindInMessage,
    required this.onShowHelp,
    required this.onPermanentDelete,
    required this.onReply,
    required this.onForward,
    required this.onSnooze,
  });

  final VoidCallback onCompose;
  final VoidCallback onSearch;
  final VoidCallback onFindInMessage;
  final VoidCallback onShowHelp;
  final void Function(MailboxCubit cubit) onPermanentDelete;
  final void Function(MailboxCubit cubit, {bool replyAll}) onReply;
  final void Function(MailboxCubit cubit) onForward;
  final void Function(MailboxCubit cubit) onSnooze;
}

/// Handles workspace hardware keys via a route-root [Focus.onKeyEvent].
///
/// Returns `true` when the event was consumed.
bool handleMailboxHardwareKey(
  KeyEvent event, {
  required BuildContext context,
  required MailboxShortcutActions actions,
}) {
  if (!context.mounted) {
    return false;
  }
  final AppSettingsState settings = context.read<AppSettingsCubit>().state;
  if (!settings.keyboardShortcutsEnabled) {
    return false;
  }
  if (ByteMailKeyboardShortcuts.isEditingText) {
    return false;
  }

  final MailboxCubit cubit = context.read<MailboxCubit>();
  if (ByteMailKeyboardShortcuts.isControlChord(
    event,
    LogicalKeyboardKey.keyJ,
  )) {
    moveMailboxSelection(context, cubit.state, 1);
    return true;
  }
  if (ByteMailKeyboardShortcuts.isControlChord(
    event,
    LogicalKeyboardKey.keyK,
  )) {
    moveMailboxSelection(context, cubit.state, -1);
    return true;
  }
  if (ByteMailKeyboardShortcuts.isControlChord(
    event,
    LogicalKeyboardKey.keyN,
  )) {
    actions.onCompose();
    return true;
  }
  if (ByteMailKeyboardShortcuts.isControlChord(
    event,
    LogicalKeyboardKey.keyF,
    shift: true,
  )) {
    actions.onSearch();
    return true;
  }
  if (ByteMailKeyboardShortcuts.isControlChord(
    event,
    LogicalKeyboardKey.keyF,
  )) {
    actions.onFindInMessage();
    return true;
  }
  if (ByteMailKeyboardShortcuts.isControlChord(
    event,
    LogicalKeyboardKey.keyU,
  )) {
    unawaited(cubit.toggleSelectedUnread());
    return true;
  }
  if (ByteMailKeyboardShortcuts.isControlChord(
    event,
    LogicalKeyboardKey.keyM,
    shift: true,
  )) {
    unawaited(
      context.read<AppSettingsCubit>().setVisualFocusEnabled(
        !settings.visualFocusEnabled,
      ),
    );
    return true;
  }

  // Bare action keys (skipped while editing text; Ctrl chords handled above).
  if (ByteMailKeyboardShortcuts.isBareKey(
    event,
    LogicalKeyboardKey.slash,
  )) {
    actions.onSearch();
    return true;
  }
  if (ByteMailKeyboardShortcuts.isKeymapHelpKey(event)) {
    actions.onShowHelp();
    return true;
  }
  if (ByteMailKeyboardShortcuts.isBareKey(
    event,
    LogicalKeyboardKey.delete,
    shift: true,
  )) {
    actions.onPermanentDelete(cubit);
    return true;
  }
  if (ByteMailKeyboardShortcuts.isBareKey(event, LogicalKeyboardKey.delete)) {
    if (cubit.isViewingTrash) {
      actions.onPermanentDelete(cubit);
    } else {
      unawaited(cubit.deleteSelected());
    }
    return true;
  }
  if (ByteMailKeyboardShortcuts.isBareKey(event, LogicalKeyboardKey.keyE)) {
    unawaited(cubit.archiveSelected());
    return true;
  }
  if (ByteMailKeyboardShortcuts.isBareKey(
    event,
    LogicalKeyboardKey.keyR,
    shift: true,
  )) {
    actions.onReply(cubit, replyAll: true);
    return true;
  }
  if (ByteMailKeyboardShortcuts.isBareKey(event, LogicalKeyboardKey.keyR)) {
    actions.onReply(cubit);
    return true;
  }
  if (ByteMailKeyboardShortcuts.isBareKey(event, LogicalKeyboardKey.keyF)) {
    actions.onForward(cubit);
    return true;
  }
  if (ByteMailKeyboardShortcuts.isBareKey(event, LogicalKeyboardKey.keyS)) {
    unawaited(cubit.toggleStarSelected());
    return true;
  }
  if (ByteMailKeyboardShortcuts.isBareKey(event, LogicalKeyboardKey.keyB)) {
    actions.onSnooze(cubit);
    return true;
  }
  return false;
}

/// Moves the list selection by [delta] messages (clamped to list bounds).
void moveMailboxSelection(
  BuildContext context,
  MailboxState mailbox,
  int delta,
) {
  if (mailbox.messages.isEmpty) {
    return;
  }
  final MailMessage current =
      mailbox.selectedMessage ?? mailbox.messages.first;
  final int index = mailbox.messages.indexWhere(
    (MailMessage m) => m.id == current.id,
  );
  final int next = (index + delta).clamp(0, mailbox.messages.length - 1);
  context.read<MailboxCubit>().selectMessage(mailbox.messages[next].id);
}
