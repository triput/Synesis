// ==============================================================================
// File: lib/desktop/detached_message_window_controller.dart
// Description: Multi-window controller for detached message reading.
// Component: Platform Integration
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-23
// ==============================================================================

import 'dart:convert';

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';

const String detachedMessageWindowType = 'detached_message';
const String detachedMessageUpdateMethod = 'show_message';

abstract interface class DetachedMessageWindowController {
  Future<void> showMessage(String messageId);
}

class NoopDetachedMessageWindowController
    implements DetachedMessageWindowController {
  const NoopDetachedMessageWindowController();

  @override
  Future<void> showMessage(String messageId) async {}
}

/// Opens unlimited concurrent detached readers (D6-1).
///
/// Each distinct [messageId] gets its own [WindowController] — unlike the
/// former V1 single-secondary-window policy, a new message never retargets
/// (and therefore never replaces) an already-open reader for a *different*
/// message. As a nice-to-have, if the same [messageId] is already showing in
/// an open window, that window is brought to the front instead of spawning a
/// duplicate.
class WindowsDetachedMessageWindowController
    implements DetachedMessageWindowController {
  @override
  Future<void> showMessage(String messageId) async {
    if (messageId.trim().isEmpty) {
      throw ArgumentError.value(messageId, 'messageId', 'Must not be empty.');
    }

    final WindowController? existing = await _findExistingFor(messageId);
    if (existing != null) {
      try {
        await existing.show();
        return;
      } catch (error, stackTrace) {
        // A stale native controller means the user already closed that
        // reader; fall through and open a fresh window for this message.
        debugPrint(
          'Recreating detached message window for $messageId: '
          '$error\n$stackTrace',
        );
      }
    }

    final WindowController controller = await WindowController.create(
      WindowConfiguration(
        arguments: jsonEncode(<String, String>{
          'type': detachedMessageWindowType,
          'messageId': messageId,
        }),
      ),
    );
    await controller.show();
  }

  /// Finds an already-open detached window for [messageId], if any.
  ///
  /// Detached windows never mutate their `arguments` after creation (each
  /// window maps 1:1 to the message it was opened for), so the message id
  /// encoded at creation time is a reliable, native-truth key — no local
  /// bookkeeping map is needed and stale entries cannot leak.
  Future<WindowController?> _findExistingFor(String messageId) async {
    final List<WindowController> windows = await WindowController.getAll();
    for (final WindowController controller in windows) {
      try {
        final Object? decoded = jsonDecode(controller.arguments);
        if (decoded is Map &&
            decoded['type'] == detachedMessageWindowType &&
            decoded['messageId'] == messageId) {
          return controller;
        }
      } on FormatException {
        continue;
      }
    }
    return null;
  }
}
