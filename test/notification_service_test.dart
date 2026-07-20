// ==============================================================================
// File: test/notification_service_test.dart
// Description: Unit tests for NotificationService filter and aggregation rules
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/notifications/notification_platform.dart';
import 'package:bytemail/notifications/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSettings implements NotificationSettingsSource {
  _FakeSettings({
    this.notificationsEnabled = true,
    this.notifyStarredOnly = false,
    this.quietHoursEnabled = false,
    this.quietHoursStartMinutes = 22 * 60,
    this.quietHoursEndMinutes = 7 * 60,
    Map<String, bool>? accountEnabled,
  }) : accountEnabled = accountEnabled ?? const <String, bool>{};

  @override
  bool notificationsEnabled;

  @override
  bool notifyStarredOnly;

  @override
  bool quietHoursEnabled;

  @override
  int quietHoursStartMinutes;

  @override
  int quietHoursEndMinutes;

  final Map<String, bool> accountEnabled;

  @override
  bool isAccountEnabled(String accountId) => accountEnabled[accountId] ?? true;
}

class _FakePlatform implements NotificationPlatform {
  final List<({String title, String body})> shown =
      <({String title, String body})>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showNewMail({
    required String title,
    required String body,
  }) async {
    shown.add((title: title, body: body));
  }
}

MailMessage _msg({
  required String id,
  String accountId = 'a1',
  String fromName = 'Ada',
  String subject = 'Hello',
  bool starred = false,
}) {
  return MailMessage(
    id: id,
    accountId: accountId,
    fromName: fromName,
    fromAddress: 'ada@example.com',
    subject: subject,
    snippet: subject,
    body: subject,
    whenLabel: 'now',
    bucket: FocusBucket.focused,
    unread: true,
    starred: starred,
  );
}

void main() {
  group('NotificationService', () {
    test('dedupes the same message id across calls', () async {
      final _FakePlatform platform = _FakePlatform();
      final NotificationService service = NotificationService(
        settings: _FakeSettings(),
        platform: platform,
        isAppForeground: () => false,
      );
      final MailMessage message = _msg(id: 'm1');

      await service.onNewMail(<MailMessage>[message]);
      await service.onNewMail(<MailMessage>[message]);

      expect(platform.shown, hasLength(1));
      expect(platform.shown.single.title, 'Ada');
      expect(platform.shown.single.body, 'Hello');
    });

    test('global off suppresses show', () async {
      final _FakePlatform platform = _FakePlatform();
      final NotificationService service = NotificationService(
        settings: _FakeSettings(notificationsEnabled: false),
        platform: platform,
        isAppForeground: () => false,
      );

      await service.onNewMail(<MailMessage>[_msg(id: 'm1')]);

      expect(platform.shown, isEmpty);
    });

    test('muted account suppresses show', () async {
      final _FakePlatform platform = _FakePlatform();
      final NotificationService service = NotificationService(
        settings: _FakeSettings(
          accountEnabled: <String, bool>{'a1': false},
        ),
        platform: platform,
        isAppForeground: () => false,
      );

      await service.onNewMail(<MailMessage>[_msg(id: 'm1', accountId: 'a1')]);

      expect(platform.shown, isEmpty);
    });

    test('quiet hours wrap past midnight', () async {
      final _FakePlatform platform = _FakePlatform();
      // Quiet 22:00–07:00; 23:30 is inside.
      final NotificationService nightService = NotificationService(
        settings: _FakeSettings(
          quietHoursEnabled: true,
          quietHoursStartMinutes: 22 * 60,
          quietHoursEndMinutes: 7 * 60,
        ),
        platform: platform,
        isAppForeground: () => false,
        clock: () => DateTime(2026, 7, 17, 23, 30),
      );
      await nightService.onNewMail(<MailMessage>[_msg(id: 'night')]);
      expect(platform.shown, isEmpty);

      // 08:00 is outside quiet hours.
      final _FakePlatform dayPlatform = _FakePlatform();
      final NotificationService dayService = NotificationService(
        settings: _FakeSettings(
          quietHoursEnabled: true,
          quietHoursStartMinutes: 22 * 60,
          quietHoursEndMinutes: 7 * 60,
        ),
        platform: dayPlatform,
        isAppForeground: () => false,
        clock: () => DateTime(2026, 7, 17, 8, 0),
      );
      await dayService.onNewMail(<MailMessage>[_msg(id: 'day')]);
      expect(dayPlatform.shown, hasLength(1));
    });

    test('starred-only filters non-starred', () async {
      final _FakePlatform platform = _FakePlatform();
      final NotificationService service = NotificationService(
        settings: _FakeSettings(notifyStarredOnly: true),
        platform: platform,
        isAppForeground: () => false,
      );

      await service.onNewMail(<MailMessage>[
        _msg(id: 'plain', starred: false),
        _msg(id: 'star', fromName: 'Star', subject: 'Pinned', starred: true),
      ]);

      expect(platform.shown, hasLength(1));
      expect(platform.shown.single.title, 'Star');
      expect(platform.shown.single.body, 'Pinned');
    });

    test('foreground suppresses show', () async {
      final _FakePlatform platform = _FakePlatform();
      final NotificationService service = NotificationService(
        settings: _FakeSettings(),
        platform: platform,
        isAppForeground: () => true,
      );

      await service.onNewMail(<MailMessage>[_msg(id: 'm1')]);

      expect(platform.shown, isEmpty);
    });

    test('aggregates multiple messages', () async {
      final _FakePlatform platform = _FakePlatform();
      final NotificationService service = NotificationService(
        settings: _FakeSettings(),
        platform: platform,
        isAppForeground: () => false,
      );

      await service.onNewMail(<MailMessage>[
        _msg(id: 'm1', subject: 'First'),
        _msg(id: 'm2', subject: 'Second'),
      ]);

      expect(platform.shown, hasLength(1));
      expect(platform.shown.single.title, '2 new messages');
      expect(platform.shown.single.body, 'First');
    });
  });
}
