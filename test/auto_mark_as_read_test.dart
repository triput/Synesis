// ==============================================================================
// File: test/auto_mark_as_read_test.dart
// Description: Dwell-timer schedule/cancel coverage for DEF-034 / UI-P27.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:async';

import 'package:bytemail/ui/shell/auto_mark_as_read.dart';
import 'package:flutter_test/flutter_test.dart';

/// Deterministic [Timer] double so dwell tests never wait on a real clock.
class _FakeTimer implements Timer {
  _FakeTimer(this._callback);

  final void Function() _callback;
  bool _cancelled = false;
  bool _fired = false;

  bool get isCancelled => _cancelled;

  void fire() {
    if (_cancelled || _fired) {
      return;
    }
    _fired = true;
    _callback();
  }

  @override
  void cancel() => _cancelled = true;

  @override
  bool get isActive => !_cancelled && !_fired;

  @override
  int get tick => _fired ? 1 : 0;
}

void main() {
  test('dwell constant is 5 seconds', () {
    expect(kAutoMarkAsReadDwell, const Duration(seconds: 5));
  });

  group('AutoMarkAsReadController', () {
    test('schedules a timer for an unread message with a callback', () {
      _FakeTimer? created;
      int markReadCalls = 0;
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          expect(duration, kAutoMarkAsReadDwell);
          created = _FakeTimer(callback);
          return created!;
        },
      );

      controller.update(
        messageId: 'm1',
        unread: true,
        onMarkRead: () => markReadCalls++,
      );

      expect(controller.isScheduled, isTrue);
      expect(controller.scheduledMessageId, 'm1');

      created!.fire();
      expect(markReadCalls, 1);
      expect(controller.isScheduled, isFalse);
      expect(controller.scheduledMessageId, isNull);
    });

    test('does not schedule when the message is already read', () {
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) =>
            throw StateError('unexpected timer creation'),
      );

      controller.update(messageId: 'm1', unread: false, onMarkRead: () {});

      expect(controller.isScheduled, isFalse);
    });

    test('does not schedule when onMarkRead is unavailable', () {
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) =>
            throw StateError('unexpected timer creation'),
      );

      controller.update(messageId: 'm1', unread: true, onMarkRead: null);

      expect(controller.isScheduled, isFalse);
    });

    test('does not schedule when messageId is null', () {
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) =>
            throw StateError('unexpected timer creation'),
      );

      controller.update(messageId: null, unread: true, onMarkRead: () {});

      expect(controller.isScheduled, isFalse);
    });

    test('cancels the pending timer when the message id changes', () {
      final List<_FakeTimer> created = <_FakeTimer>[];
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          final _FakeTimer timer = _FakeTimer(callback);
          created.add(timer);
          return timer;
        },
      );

      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});
      expect(created, hasLength(1));
      expect(created[0].isCancelled, isFalse);

      controller.update(messageId: 'm2', unread: true, onMarkRead: () {});
      expect(created[0].isCancelled, isTrue);
      expect(created, hasLength(2));
      expect(controller.scheduledMessageId, 'm2');
    });

    test('cancels the pending timer when the message becomes read', () {
      final List<_FakeTimer> created = <_FakeTimer>[];
      int markReadCalls = 0;
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          final _FakeTimer timer = _FakeTimer(callback);
          created.add(timer);
          return timer;
        },
      );

      controller.update(
        messageId: 'm1',
        unread: true,
        onMarkRead: () => markReadCalls++,
      );
      controller.update(
        messageId: 'm1',
        unread: false,
        onMarkRead: () => markReadCalls++,
      );

      expect(created.single.isCancelled, isTrue);
      expect(controller.isScheduled, isFalse);

      created.single.fire();
      expect(markReadCalls, 0);
    });

    test('re-calling update for the same unread message is a no-op', () {
      int createCount = 0;
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          createCount++;
          return _FakeTimer(callback);
        },
      );

      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});
      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});
      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});

      expect(createCount, 1);
    });

    test('dispose cancels a pending timer', () {
      _FakeTimer? created;
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          created = _FakeTimer(callback);
          return created!;
        },
      );

      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});
      controller.dispose();

      expect(created!.isCancelled, isTrue);
      expect(controller.isScheduled, isFalse);
    });

    test('cancel() clears state without invoking the callback', () {
      int markReadCalls = 0;
      _FakeTimer? created;
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          created = _FakeTimer(callback);
          return created!;
        },
      );

      controller.update(
        messageId: 'm1',
        unread: true,
        onMarkRead: () => markReadCalls++,
      );
      controller.cancel();
      created!.fire();

      expect(markReadCalls, 0);
      expect(controller.isScheduled, isFalse);
    });
  });
}
