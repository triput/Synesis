// ==============================================================================
// File: test/auto_mark_as_read_test.dart
// Description: Dwell-timer schedule/cancel/hold coverage for DEF-034 / UI-P27,
//   custom dwell/enabled overrides (UI-P28), and hold (UI-P30).
// Component: Test
// Version: 1.1 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-22
// ==============================================================================

import 'dart:async';

import 'package:synesis/ui/shell/auto_mark_as_read.dart';
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

  group('AutoMarkAsReadController UI-P28 dwell/enabled overrides', () {
    test('constructor dwell is used when update omits an override', () {
      Duration? usedDuration;
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        dwell: const Duration(seconds: 20),
        createTimer: (Duration duration, void Function() callback) {
          usedDuration = duration;
          return _FakeTimer(callback);
        },
      );

      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});

      expect(usedDuration, const Duration(seconds: 20));
    });

    test('update dwell override takes precedence over constructor dwell', () {
      Duration? usedDuration;
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          usedDuration = duration;
          return _FakeTimer(callback);
        },
      );

      controller.update(
        messageId: 'm1',
        unread: true,
        onMarkRead: () {},
        dwell: const Duration(seconds: 30),
      );

      expect(usedDuration, const Duration(seconds: 30));
    });

    test('a custom dwell of zero still schedules an immediate-fire timer', () {
      Duration? usedDuration;
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          usedDuration = duration;
          return _FakeTimer(callback);
        },
      );

      controller.update(
        messageId: 'm1',
        unread: true,
        onMarkRead: () {},
        dwell: Duration.zero,
      );

      expect(usedDuration, Duration.zero);
      expect(controller.isScheduled, isTrue);
    });

    test('enabled: false does not schedule (UI-P28 "Off")', () {
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) =>
            throw StateError('unexpected timer creation'),
      );

      controller.update(
        messageId: 'm1',
        unread: true,
        onMarkRead: () {},
        enabled: false,
      );

      expect(controller.isScheduled, isFalse);
    });

    test('enabled: false cancels a timer already pending for the message',
        () {
      final List<_FakeTimer> created = <_FakeTimer>[];
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          final _FakeTimer timer = _FakeTimer(callback);
          created.add(timer);
          return timer;
        },
      );

      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});
      expect(controller.isScheduled, isTrue);

      controller.update(
        messageId: 'm1',
        unread: true,
        onMarkRead: () {},
        enabled: false,
      );

      expect(created.single.isCancelled, isTrue);
      expect(controller.isScheduled, isFalse);
    });
  });

  group('AutoMarkAsReadController UI-P30 hold', () {
    test('holdCurrent prevents scheduling for the held message', () {
      final List<_FakeTimer> created = <_FakeTimer>[];
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          final _FakeTimer timer = _FakeTimer(callback);
          created.add(timer);
          return timer;
        },
      );

      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});
      controller.holdCurrent();

      expect(controller.isHeld, isTrue);
      expect(controller.heldMessageId, 'm1');

      final int createCountBeforeRetry = created.length;
      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});

      expect(controller.isScheduled, isFalse);
      expect(created, hasLength(createCountBeforeRetry));
    });

    test('holdCurrent cancels a timer already pending for the message', () {
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
      expect(controller.isScheduled, isTrue);

      controller.holdCurrent();

      expect(created.single.isCancelled, isTrue);
      expect(controller.isScheduled, isFalse);

      created.single.fire();
      expect(markReadCalls, 0);
    });

    test('releaseHold allows scheduling to resume on the next update', () {
      final List<_FakeTimer> created = <_FakeTimer>[];
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          final _FakeTimer timer = _FakeTimer(callback);
          created.add(timer);
          return timer;
        },
      );

      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});
      controller.holdCurrent();
      controller.releaseHold();

      expect(controller.isHeld, isFalse);

      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});

      expect(controller.isScheduled, isTrue);
      expect(created, hasLength(2));
    });

    test('a different message id clears an existing hold', () {
      final List<_FakeTimer> created = <_FakeTimer>[];
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) {
          final _FakeTimer timer = _FakeTimer(callback);
          created.add(timer);
          return timer;
        },
      );

      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});
      controller.holdCurrent();
      expect(controller.isHeld, isTrue);

      controller.update(messageId: 'm2', unread: true, onMarkRead: () {});

      expect(controller.isHeld, isFalse);
      expect(controller.heldMessageId, isNull);
      expect(controller.isScheduled, isTrue);
      expect(controller.scheduledMessageId, 'm2');

      // Holding m1 again after returning to it should not resurrect the
      // stale hold — it must be re-armed explicitly.
      controller.update(messageId: 'm1', unread: true, onMarkRead: () {});
      expect(controller.isScheduled, isTrue);
      expect(controller.scheduledMessageId, 'm1');
    });

    test('holdCurrent before any update() call is a no-op', () {
      final AutoMarkAsReadController controller = AutoMarkAsReadController(
        createTimer: (Duration duration, void Function() callback) =>
            throw StateError('unexpected timer creation'),
      );

      controller.holdCurrent();

      expect(controller.isHeld, isFalse);
      expect(controller.heldMessageId, isNull);
    });
  });
}
