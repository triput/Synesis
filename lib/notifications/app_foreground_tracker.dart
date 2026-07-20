// ==============================================================================
// File: lib/notifications/app_foreground_tracker.dart
// Description: Tracks Flutter app lifecycle for notification foreground suppress
// Component: Notifications
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/widgets.dart';

/// Simple lifecycle tracker: true while the app is resumed / visible.
class AppForegroundTracker with WidgetsBindingObserver {
  AppForegroundTracker({bool initiallyForeground = true})
      : _isForeground = initiallyForeground;

  bool _isForeground;
  bool _observing = false;

  bool get isForeground => _isForeground;

  void attach() {
    if (_observing) {
      return;
    }
    WidgetsBinding.instance.addObserver(this);
    _observing = true;
  }

  void detach() {
    if (!_observing) {
      return;
    }
    WidgetsBinding.instance.removeObserver(this);
    _observing = false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        _isForeground = true;
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _isForeground = false;
    }
  }
}
