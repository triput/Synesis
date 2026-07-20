// ==============================================================================
// File: lib/notifications/windows_notification_adapter.dart
// Description: Windows toast adapter via local_notifier for new-mail alerts
// Component: Notifications
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/notifications/notification_platform.dart';
import 'package:local_notifier/local_notifier.dart';

/// Windows [local_notifier] adapter; optional click callback resumes the window.
class WindowsNotificationAdapter implements NotificationPlatform {
  WindowsNotificationAdapter({
    this.onNotificationClick,
    this.appName = 'ByteMail',
  });

  final void Function()? onNotificationClick;
  final String appName;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    await localNotifier.setup(appName: appName);
    _initialized = true;
  }

  @override
  Future<void> showNewMail({
    required String title,
    required String body,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    final LocalNotification notification = LocalNotification(
      title: title,
      body: body,
    );
    final void Function()? onClick = onNotificationClick;
    if (onClick != null) {
      notification.onClick = onClick;
    }
    await notification.show();
  }
}
