// ==============================================================================
// File: lib/notifications/windows_notification_adapter.dart
// Description: Windows toast adapter via local_notifier for new-mail alerts
// Component: Notifications
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-23
// ==============================================================================

import 'package:synesis/notifications/notification_platform.dart';
import 'package:local_notifier/local_notifier.dart';

/// Windows [local_notifier] adapter; optional click callback resumes the
/// window, and single-message toasts get inline Archive/Delete action
/// buttons (D6-8) when [NotificationPlatform.showNewMail] is given both a
/// `messageId` and [NewMailToastActions]. Aggregated multi-message toasts
/// never render actions.
class WindowsNotificationAdapter implements NotificationPlatform {
  WindowsNotificationAdapter({
    this.onNotificationClick,
    this.appName = 'Synesis',
  });

  /// Action button index for Archive, matching the order actions are added
  /// to the notification in [showNewMail].
  static const int archiveActionIndex = 0;

  /// Action button index for Delete, matching the order actions are added
  /// to the notification in [showNewMail].
  static const int deleteActionIndex = 1;

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
    String? messageId,
    NewMailToastActions? actions,
  }) async {
    if (!_initialized) {
      await initialize();
    }
    final bool hasActions = messageId != null && actions != null;
    final LocalNotification notification = LocalNotification(
      title: title,
      body: body,
      actions: hasActions
          ? <LocalNotificationAction>[
              LocalNotificationAction(text: 'Archive'),
              LocalNotificationAction(text: 'Delete'),
            ]
          : null,
    );
    final void Function()? onClick = onNotificationClick;
    if (onClick != null) {
      notification.onClick = onClick;
    }
    if (hasActions) {
      final String targetMessageId = messageId;
      final NewMailToastActions callbacks = actions;
      notification.onClickAction = (int actionIndex) {
        switch (actionIndex) {
          case archiveActionIndex:
            callbacks.onArchive(targetMessageId);
          case deleteActionIndex:
            callbacks.onDelete(targetMessageId);
        }
      };
    }
    await notification.show();
  }
}
