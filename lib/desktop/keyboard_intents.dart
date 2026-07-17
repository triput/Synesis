// ==============================================================================
// File: lib/desktop/keyboard_intents.dart
// Description: Documented keyboard-first intents and default desktop shortcuts
// Component: UI / Desktop
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Workspace shortcuts use Control chords so letter keys still type in fields.
///
/// - Ctrl+J / Ctrl+K — next / previous message
/// - Ctrl+N — compose (avoid Ctrl+C; that is copy)
/// - Ctrl+F — find in message · Ctrl+Shift+F / `/` — mailbox search
/// - Ctrl+U — toggle read/unread (bulk-aware)
/// - Ctrl+Shift+M — toggle Visual Focus layout
/// - `?` — keymap help
/// - Delete / Shift+Delete — trash / permanent delete
/// - E archive · R reply · Shift+R reply all · F forward · S star · B snooze
abstract final class ByteMailKeyboardShortcuts {
  static const SingleActivator nextMessage = SingleActivator(
    LogicalKeyboardKey.keyJ,
    control: true,
  );
  static const SingleActivator previousMessage = SingleActivator(
    LogicalKeyboardKey.keyK,
    control: true,
  );
  static const SingleActivator compose = SingleActivator(
    LogicalKeyboardKey.keyN,
    control: true,
  );
  static const SingleActivator findInMessage = SingleActivator(
    LogicalKeyboardKey.keyF,
    control: true,
  );
  static const SingleActivator searchMailbox = SingleActivator(
    LogicalKeyboardKey.keyF,
    control: true,
    shift: true,
  );
  static const SingleActivator toggleUnread = SingleActivator(
    LogicalKeyboardKey.keyU,
    control: true,
  );
  static const SingleActivator toggleVisualFocus = SingleActivator(
    LogicalKeyboardKey.keyM,
    control: true,
    shift: true,
  );

  /// Compact status-bar hint; full table lives in the keymap help sheet.
  static const String helpLabel =
      'Ctrl+J/K navigate · Ctrl+N compose · Ctrl+F find · Ctrl+Shift+F search · '
      'Ctrl+U read/unread · ? help · Del trash · E archive · R reply · F forward · S star';

  /// True when the primary focus is an editable text field (typing), not a
  /// read-only [SelectableText] / HTML selection surface.
  ///
  /// Ancestor-only: do not walk descendants (that falsely treats a parent
  /// Focus as "editing" when a TextField exists deeper in the tree).
  static bool get isEditingText {
    final FocusNode? focus = FocusManager.instance.primaryFocus;
    final BuildContext? context = focus?.context;
    if (context == null) {
      return false;
    }
    if (context.widget is EditableText) {
      return !(context.widget as EditableText).readOnly;
    }
    final EditableText? editable =
        context.findAncestorWidgetOfExactType<EditableText>();
    if (editable == null) {
      return false;
    }
    // SelectableText / HtmlWidget selection uses readOnly EditableText.
    return !editable.readOnly;
  }

  /// Match Control chords from a raw [KeyEvent] (Windows-reliable).
  ///
  /// When [shift] is false (default), Shift must not be held so Ctrl+Shift
  /// chords can be reserved for distinct actions (e.g. Visual Focus).
  static bool isControlChord(
    KeyEvent event,
    LogicalKeyboardKey key, {
    bool shift = false,
  }) {
    if (event is KeyRepeatEvent) {
      return false;
    }
    if (event is! KeyDownEvent) {
      return false;
    }
    if (event.logicalKey != key) {
      return false;
    }
    return HardwareKeyboard.instance.isControlPressed &&
        HardwareKeyboard.instance.isShiftPressed == shift &&
        !HardwareKeyboard.instance.isAltPressed &&
        !HardwareKeyboard.instance.isMetaPressed;
  }

  /// Match a bare letter/action key (no Ctrl/Alt/Meta). [shift] must match.
  static bool isBareKey(
    KeyEvent event,
    LogicalKeyboardKey key, {
    bool shift = false,
  }) {
    if (event is KeyRepeatEvent) {
      return false;
    }
    if (event is! KeyDownEvent) {
      return false;
    }
    if (event.logicalKey != key) {
      return false;
    }
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isMetaPressed) {
      return false;
    }
    return HardwareKeyboard.instance.isShiftPressed == shift;
  }

  /// Match keymap help (`?` / Shift+/). Shift may still be pressed when the
  /// platform reports [LogicalKeyboardKey.question].
  static bool isKeymapHelpKey(KeyEvent event) {
    if (event is KeyRepeatEvent) {
      return false;
    }
    if (event is! KeyDownEvent) {
      return false;
    }
    if (HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isAltPressed ||
        HardwareKeyboard.instance.isMetaPressed) {
      return false;
    }
    final String? character = event.character;
    if (character == '?') {
      return true;
    }
    if (event.logicalKey == LogicalKeyboardKey.question) {
      return true;
    }
    return event.logicalKey == LogicalKeyboardKey.slash &&
        HardwareKeyboard.instance.isShiftPressed;
  }
}

class NextMessageIntent extends Intent {
  const NextMessageIntent();
}

class PreviousMessageIntent extends Intent {
  const PreviousMessageIntent();
}

class ComposeMessageIntent extends Intent {
  const ComposeMessageIntent();
}

class SearchMailboxIntent extends Intent {
  const SearchMailboxIntent();
}

class ToggleUnreadIntent extends Intent {
  const ToggleUnreadIntent();
}
