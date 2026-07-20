// ==============================================================================
// File: lib/desktop/windows_desktop_controller.dart
// Description: Desktop tray, minimize, and notification integration boundary.
// Component: Platform Integration
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

typedef NewMailNotificationCallback =
    Future<void> Function(String title, String body);

abstract interface class DesktopController {
  bool get minimizeToTrayEnabled;

  /// Whether the primary window currently has OS focus (desktop only).
  bool get isWindowFocused;

  Future<void> initialize();

  Future<void> dispose();

  Future<void> setMinimizeToTrayEnabled(bool enabled);

  Future<void> minimize();

  Future<void> show();

  Future<void> hideToTray();

  Future<void> quit();

  Future<void> showNewMailToast({required String title, required String body});
}

class NoopDesktopController implements DesktopController {
  const NoopDesktopController();

  @override
  bool get minimizeToTrayEnabled => false;

  @override
  bool get isWindowFocused => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}

  @override
  Future<void> minimize() async {}

  @override
  Future<void> show() async {}

  @override
  Future<void> hideToTray() async {}

  @override
  Future<void> quit() async {}

  @override
  Future<void> setMinimizeToTrayEnabled(bool enabled) async {}

  @override
  Future<void> showNewMailToast({
    required String title,
    required String body,
  }) async {}
}

/// Windows tray + window-manager adapter.
class WindowsDesktopController
    with WindowListener, TrayListener
    implements DesktopController {
  WindowsDesktopController({
    bool minimizeToTrayEnabled = false,
    NewMailNotificationCallback? onNewMail,
    this.trayIconAsset = 'windows/runner/resources/app_icon.ico',
  }) : _minimizeToTrayEnabled = minimizeToTrayEnabled,
       onNewMail = onNewMail;

  bool _minimizeToTrayEnabled;
  bool _initialized = false;
  bool _isWindowFocused = true;
  final NewMailNotificationCallback? onNewMail;
  final String trayIconAsset;

  @override
  bool get minimizeToTrayEnabled => _minimizeToTrayEnabled;

  @override
  bool get isWindowFocused => _isWindowFocused;

  @override
  Future<void> initialize() async {
    if (_initialized || kIsWeb || !Platform.isWindows) {
      return;
    }
    await windowManager.ensureInitialized();
    windowManager.addListener(this);
    trayManager.addListener(this);
    await windowManager.setPreventClose(_minimizeToTrayEnabled);
    if (_minimizeToTrayEnabled) {
      await _ensureTray();
    }
    _initialized = true;
  }

  @override
  Future<void> dispose() async {
    if (!_initialized) {
      return;
    }
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    try {
      await trayManager.destroy();
    } catch (_) {
      // Tray may already be destroyed.
    }
    _initialized = false;
  }

  @override
  Future<void> minimize() async {
    if (_minimizeToTrayEnabled) {
      await hideToTray();
      return;
    }
    await windowManager.minimize();
  }

  @override
  Future<void> show() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  Future<void> hideToTray() async {
    await _ensureTray();
    await windowManager.hide();
  }

  @override
  Future<void> quit() async {
    await windowManager.setPreventClose(false);
    await windowManager.close();
  }

  @override
  Future<void> setMinimizeToTrayEnabled(bool enabled) async {
    _minimizeToTrayEnabled = enabled;
    if (!_initialized) {
      return;
    }
    await windowManager.setPreventClose(enabled);
    if (enabled) {
      await _ensureTray();
    } else {
      try {
        await trayManager.destroy();
      } catch (_) {
        // Ignore missing tray.
      }
    }
  }

  @override
  Future<void> showNewMailToast({required String title, required String body}) {
    return notifyNewMail(title: title, body: body);
  }

  Future<void> notifyNewMail({
    required String title,
    required String body,
  }) async {
    final NewMailNotificationCallback? callback = onNewMail;
    if (callback != null) {
      await callback(title, body);
    }
  }

  Future<void> _ensureTray() async {
    try {
      await trayManager.setIcon(trayIconAsset);
      await trayManager.setToolTip('ByteMail');
      await trayManager.setContextMenu(
        Menu(
          items: <MenuItem>[
            MenuItem(key: 'show_window', label: 'Show ByteMail'),
            MenuItem.separator(),
            MenuItem(key: 'exit_app', label: 'Quit'),
          ],
        ),
      );
    } on MissingPluginException catch (error, stackTrace) {
      debugPrint('Tray plugin unavailable: $error\n$stackTrace');
    }
  }

  @override
  void onWindowClose() {
    unawaited(_handleWindowClose());
  }

  @override
  void onWindowFocus() {
    _isWindowFocused = true;
  }

  @override
  void onWindowBlur() {
    _isWindowFocused = false;
  }

  @override
  void onWindowMinimize() {
    if (_minimizeToTrayEnabled) {
      unawaited(hideToTray());
    }
  }

  Future<void> _handleWindowClose() async {
    if (_minimizeToTrayEnabled) {
      await hideToTray();
      return;
    }
    await windowManager.destroy();
  }

  @override
  void onTrayIconMouseDown() {
    unawaited(trayManager.popUpContextMenu());
  }

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show_window':
        unawaited(show());
      case 'exit_app':
        unawaited(quit());
    }
  }
}
