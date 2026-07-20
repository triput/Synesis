// ==============================================================================
// File: lib/notifications/notification_service.dart
// Description: Filters new unread mail and shows OS notifications when allowed
// Component: Notifications
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/notifications/notification_platform.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/app_settings_state.dart';

/// Read-only notification prefs so [NotificationService] stays Cubit-free.
abstract interface class NotificationSettingsSource {
  bool get notificationsEnabled;

  bool get notifyStarredOnly;

  bool get quietHoursEnabled;

  /// Minutes since midnight, inclusive start of quiet window (0–1439).
  int get quietHoursStartMinutes;

  /// Minutes since midnight, exclusive end of quiet window (0–1439).
  int get quietHoursEndMinutes;

  bool isAccountEnabled(String accountId);
}

/// Adapts [AppSettingsCubit] / [AppSettingsState] for notification filtering.
class AppSettingsNotificationSource implements NotificationSettingsSource {
  AppSettingsNotificationSource(this._cubit);

  final AppSettingsCubit _cubit;

  AppSettingsState get _state => _cubit.state;

  @override
  bool get notificationsEnabled => _state.notificationsEnabled;

  @override
  bool get notifyStarredOnly => _state.notifyStarredOnly;

  @override
  bool get quietHoursEnabled => _state.notificationQuietHoursEnabled;

  @override
  int get quietHoursStartMinutes => _state.quietHoursStartMinutes;

  @override
  int get quietHoursEndMinutes => _state.quietHoursEndMinutes;

  @override
  bool isAccountEnabled(String accountId) =>
      _state.isAccountNotificationsEnabled(accountId);
}

/// Applies product filters, aggregates, dedupes, then shows via [platform].
class NotificationService {
  NotificationService({
    required NotificationSettingsSource settings,
    required NotificationPlatform platform,
    bool Function()? isAppForeground,
    DateTime Function()? clock,
    Set<String>? initialNotifiedIds,
  }) : _settings = settings,
       _platform = platform,
       _isAppForeground = isAppForeground ?? (() => false),
       _clock = clock ?? DateTime.now,
       _notifiedIds = <String>{...(initialNotifiedIds ?? const <String>{})};

  static const int _maxNotifiedIds = 500;

  final NotificationSettingsSource _settings;
  final NotificationPlatform _platform;
  final bool Function() _isAppForeground;
  final DateTime Function() _clock;
  final Set<String> _notifiedIds;

  Future<void> initialize() => _platform.initialize();

  /// Filter newly unread messages and show an OS notification when allowed.
  Future<void> onNewMail(List<MailMessage> messages) async {
    if (messages.isEmpty) {
      return;
    }
    if (!_settings.notificationsEnabled) {
      return;
    }
    if (_isAppForeground()) {
      return;
    }
    if (_isInQuietHours(_clock())) {
      return;
    }

    final List<MailMessage> eligible = <MailMessage>[];
    for (final MailMessage message in messages) {
      if (!_settings.isAccountEnabled(message.accountId)) {
        continue;
      }
      if (_settings.notifyStarredOnly && !message.starred) {
        continue;
      }
      if (_notifiedIds.contains(message.id)) {
        continue;
      }
      eligible.add(message);
    }

    if (eligible.isEmpty) {
      return;
    }

    for (final MailMessage message in eligible) {
      _rememberNotified(message.id);
    }

    final ({String title, String body}) aggregate = _aggregate(eligible);
    await _platform.showNewMail(title: aggregate.title, body: aggregate.body);
  }

  bool _isInQuietHours(DateTime now) {
    if (!_settings.quietHoursEnabled) {
      return false;
    }
    final int start = _settings.quietHoursStartMinutes.clamp(0, 1439);
    final int end = _settings.quietHoursEndMinutes.clamp(0, 1439);
    final int minutes = now.hour * 60 + now.minute;
    if (start == end) {
      return false;
    }
    if (start < end) {
      return minutes >= start && minutes < end;
    }
    // Wraps past midnight: [start, 1440) U [0, end).
    return minutes >= start || minutes < end;
  }

  ({String title, String body}) _aggregate(List<MailMessage> messages) {
    if (messages.length == 1) {
      final MailMessage message = messages.first;
      final String from = message.fromName.trim().isEmpty
          ? message.fromAddress
          : message.fromName;
      final String subject = message.subject.trim().isEmpty
          ? '(no subject)'
          : message.subject.trim();
      return (title: from, body: subject);
    }
    final MailMessage first = messages.first;
    final String snippet = first.subject.trim().isEmpty
        ? (first.snippet.trim().isEmpty ? '(no subject)' : first.snippet.trim())
        : first.subject.trim();
    return (
      title: '${messages.length} new messages',
      body: snippet,
    );
  }

  void _rememberNotified(String id) {
    _notifiedIds.add(id);
    while (_notifiedIds.length > _maxNotifiedIds) {
      _notifiedIds.remove(_notifiedIds.first);
    }
  }
}
