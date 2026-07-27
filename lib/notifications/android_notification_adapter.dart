// ==============================================================================
// File: lib/notifications/android_notification_adapter.dart
// Description: Android local notifications adapter for new-mail toasts
// Component: Notifications
// Version: 1.2 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-27
// ==============================================================================

import 'package:synesis/notifications/notification_platform.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android [flutter_local_notifications] adapter; tap resumes the app only.
class AndroidNotificationAdapter implements NotificationPlatform {
  AndroidNotificationAdapter({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'synesis_new_mail';
  static const String channelName = 'New mail';
  static const int coalesceNotificationId = 1001;

  /// Monochrome status-bar icon (Data Envelope silhouette).
  static const String smallIcon = '@drawable/ic_stat_synesis';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(smallIcon);
    // flutter_local_notifications ≥20: initialize/show use named params.
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings),
    );
    final AndroidFlutterLocalNotificationsPlugin? android =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        channelId,
        channelName,
        importance: Importance.defaultImportance,
      ),
    );
    await android?.requestNotificationsPermission();
    _initialized = true;
  }

  @override
  Future<void> showNewMail({
    required String title,
    required String body,
    String? messageId,
    NewMailToastActions? actions,
  }) async {
    // D6-8 toast Archive/Delete actions are Windows-only (local_notifier);
    // Android has no inline-action affordance here, so [messageId] and
    // [actions] are accepted for interface compatibility and intentionally
    // ignored — this notification remains title/body only.
    if (!_initialized) {
      await initialize();
    }
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: 'Notifications for new unread mail',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      icon: smallIcon,
    );
    await _plugin.show(
      id: coalesceNotificationId,
      title: title,
      body: body,
      notificationDetails: const NotificationDetails(android: androidDetails),
    );
  }
}
