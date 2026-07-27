// ==============================================================================
// File: lib/ui/shell/auto_mark_as_read.dart
// Description: Dwell-timer controller for DEF-034 / UI-P27 auto-mark-as-read,
//   with per-call dwell/enabled overrides (UI-P28) and hold support (UI-P30).
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-22
// ==============================================================================

import 'dart:async';

/// Dwell time an unread message must stay open before it is auto-marked read.
///
/// Default-on dwell for DEF-034 / UI-P27. UI-P28 lets the user override this
/// via [AppSettingsState.autoMarkAsReadSeconds]; callers pass the resolved
/// [Duration] into [AutoMarkAsReadController.update] rather than relying on
/// this constant directly once settings are wired up.
const Duration kAutoMarkAsReadDwell = Duration(seconds: 5);

/// Schedules and cancels the auto-mark-as-read dwell timer for the reading
/// pane, and tracks an optional per-message "hold" (UI-P30) that suppresses
/// scheduling while the user wants to keep reading without losing the row.
///
/// Extracted from `ReadingPane` so the dwell/cancel/hold behavior can be unit
/// tested without mounting a full widget tree. Callers should invoke [update]
/// whenever the displayed message, its unread state, the effective dwell, or
/// the mark-read callback changes, and [dispose] when the owning widget is
/// disposed.
class AutoMarkAsReadController {
  AutoMarkAsReadController({
    this.dwell = kAutoMarkAsReadDwell,
    Timer Function(Duration duration, void Function() callback)? createTimer,
  }) : _createTimer = createTimer ?? Timer.new;

  /// Fallback dwell used when [update] is called without an explicit
  /// per-call [Duration] override.
  final Duration dwell;
  final Timer Function(Duration duration, void Function() callback)
      _createTimer;

  Timer? _timer;
  String? _scheduledMessageId;

  /// Id most recently passed to [update], regardless of whether a timer was
  /// scheduled for it. Used to resolve [holdCurrent] and to detect message
  /// changes that should clear an existing hold.
  String? _lastMessageId;

  /// Id currently held via [holdCurrent], or null when nothing is held.
  String? _heldMessageId;

  /// True while a dwell timer is pending.
  bool get isScheduled => _timer != null;

  /// The message id the pending timer targets, or null when idle.
  String? get scheduledMessageId => _scheduledMessageId;

  /// True while the current (or most recently seen) message is held.
  bool get isHeld => _heldMessageId != null;

  /// The message id currently held, or null when nothing is held.
  String? get heldMessageId => _heldMessageId;

  /// Reconciles the dwell timer against the currently displayed message.
  ///
  /// Starts a fresh timer when [messageId] is non-null, [unread] is true,
  /// [enabled] is true, [onMarkRead] is available, and the message is not
  /// currently held via [holdCurrent]. Cancels any pending timer when the
  /// message changes, becomes read, is disabled, or has no callback. Calling
  /// [update] repeatedly for the same still-unread message id is a no-op so
  /// it is safe to call from `build`/`didUpdateWidget`.
  ///
  /// [dwell] overrides the constructor [AutoMarkAsReadController.dwell] for
  /// this call only (UI-P28 per-user delay). [enabled] lets callers disable
  /// auto-mark entirely (UI-P28 "Off") without tearing down the controller.
  void update({
    required String? messageId,
    required bool unread,
    required void Function()? onMarkRead,
    Duration? dwell,
    bool enabled = true,
  }) {
    if (messageId != _lastMessageId) {
      // A different message is now in view — any hold from the previous
      // message no longer applies (UI-P30).
      _heldMessageId = null;
      _lastMessageId = messageId;
    }

    if (messageId == null ||
        !unread ||
        onMarkRead == null ||
        !enabled ||
        _heldMessageId == messageId) {
      cancel();
      return;
    }
    if (_scheduledMessageId == messageId && _timer != null) {
      return;
    }
    cancel();
    _scheduledMessageId = messageId;
    final Duration effectiveDwell = dwell ?? this.dwell;
    _timer = _createTimer(effectiveDwell, () {
      _timer = null;
      _scheduledMessageId = null;
      onMarkRead();
    });
  }

  /// Holds the message most recently seen via [update], cancelling any
  /// pending timer for it. Subsequent [update] calls for that same message
  /// id will not schedule a new timer until [releaseHold] is called or the
  /// message changes (UI-P30 "Hold auto-mark" / "Keep unread while reading").
  ///
  /// No-op when [update] has never been called (nothing to hold yet).
  void holdCurrent() {
    final String? id = _lastMessageId;
    if (id == null) {
      return;
    }
    _heldMessageId = id;
    cancel();
  }

  /// Releases a hold set by [holdCurrent]. Does not itself reschedule a
  /// timer — callers should follow up with [update] to resume dwell tracking
  /// if the message is still open and unread.
  void releaseHold() {
    _heldMessageId = null;
  }

  /// Cancels any pending dwell timer.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    _scheduledMessageId = null;
  }

  /// Releases resources. Safe to call multiple times.
  void dispose() {
    cancel();
  }
}
