// ==============================================================================
// File: lib/desktop/detached_message_window_controller.dart
// Description: Single-secondary-window controller for detached message reading.
// Component: Platform Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
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

/// Maintains at most one detached reader and retargets it for later messages.
class WindowsDetachedMessageWindowController
    implements DetachedMessageWindowController {
  WindowController? _detached;

  @override
  Future<void> showMessage(String messageId) async {
    if (messageId.trim().isEmpty) {
      throw ArgumentError.value(messageId, 'messageId', 'Must not be empty.');
    }
    WindowController? controller = _detached ?? await _findExisting();
    if (controller == null) {
      controller = await WindowController.create(
        WindowConfiguration(
          arguments: jsonEncode(<String, String>{
            'type': detachedMessageWindowType,
            'messageId': messageId,
          }),
        ),
      );
      _detached = controller;
      await controller.show();
      return;
    }

    _detached = controller;
    try {
      await controller.invokeMethod<void>(
        detachedMessageUpdateMethod,
        <String, String>{'messageId': messageId},
      );
      await controller.show();
    } catch (error, stackTrace) {
      // A stale native controller means the user already closed the reader.
      debugPrint('Recreating detached message window: $error\n$stackTrace');
      _detached = null;
      final WindowController replacement = await WindowController.create(
        WindowConfiguration(
          arguments: jsonEncode(<String, String>{
            'type': detachedMessageWindowType,
            'messageId': messageId,
          }),
        ),
      );
      _detached = replacement;
      await replacement.show();
    }
  }

  Future<WindowController?> _findExisting() async {
    final List<WindowController> windows = await WindowController.getAll();
    for (final WindowController controller in windows) {
      try {
        final Object? decoded = jsonDecode(controller.arguments);
        if (decoded is Map && decoded['type'] == detachedMessageWindowType) {
          return controller;
        }
      } on FormatException {
        continue;
      }
    }
    return null;
  }
}
