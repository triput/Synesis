// ==============================================================================
// File: lib/notifications/notification_platform.dart
// Description: Platform adapter interface for OS new-mail notifications
// Component: Notifications
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-23
// ==============================================================================

/// Archive/Delete callbacks for a single-message toast action (D6-8).
///
/// Only populated when a toast represents exactly one message — aggregated
/// multi-message toasts never carry actions. Platforms that cannot render
/// inline notification buttons (Android) simply ignore this.
class NewMailToastActions {
  const NewMailToastActions({
    required this.onArchive,
    required this.onDelete,
  });

  /// Invoked with the toast's message id when the user picks Archive.
  final void Function(String messageId) onArchive;

  /// Invoked with the toast's message id when the user picks Delete.
  final void Function(String messageId) onDelete;
}

/// Thin platform boundary for showing local new-mail toasts/notifications.
abstract interface class NotificationPlatform {
  Future<void> initialize();

  /// Shows a new-mail toast.
  ///
  /// [messageId] and [actions] are only set for single-message toasts
  /// (D6-8 Windows toast Archive/Delete); platforms that do not support
  /// inline actions may ignore both.
  Future<void> showNewMail({
    required String title,
    required String body,
    String? messageId,
    NewMailToastActions? actions,
  });
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
    String? messageId,
    NewMailToastActions? actions,
  }) async {}
}
