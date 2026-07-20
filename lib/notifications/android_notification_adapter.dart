// ==============================================================================
// File: lib/notifications/android_notification_adapter.dart
// Description: Android local notifications adapter for new-mail toasts
// Component: Notifications
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/notifications/notification_platform.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Android [flutter_local_notifications] adapter; tap resumes the app only.
class AndroidNotificationAdapter implements NotificationPlatform {
  AndroidNotificationAdapter({
    FlutterLocalNotificationsPlugin? plugin,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'bytemail_new_mail';
  static const String channelName = 'New mail';
  static const int coalesceNotificationId = 1001;

  /// Monochrome status-bar icon (Data Envelope silhouette).
  static const String smallIcon = '@drawable/ic_stat_bytemail';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings(smallIcon);
    await _plugin.initialize(
      const InitializationSettings(android: androidSettings),
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
  }) async {
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
      coalesceNotificationId,
      title,
      body,
      const NotificationDetails(android: androidDetails),
    );
  }
}
