// ==============================================================================
// File: lib/notifications/notification_platform.dart
// Description: Platform adapter interface for OS new-mail notifications
// Component: Notifications
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

/// Thin platform boundary for showing local new-mail toasts/notifications.
abstract interface class NotificationPlatform {
  Future<void> initialize();

  Future<void> showNewMail({required String title, required String body});
}

/// No-op adapter for unsupported platforms and unit tests.
class NoopNotificationPlatform implements NotificationPlatform {
  const NoopNotificationPlatform();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showNewMail({
    required String title,
    required String body,
  }) async {}
}
