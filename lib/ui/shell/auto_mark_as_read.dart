// ==============================================================================
// File: lib/ui/shell/auto_mark_as_read.dart
// Description: Dwell-timer controller for DEF-034 / UI-P27 auto-mark-as-read.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:async';

/// Dwell time an unread message must stay open before it is auto-marked read.
///
/// Default-on, no settings toggle (DEF-034 / UI-P27).
const Duration kAutoMarkAsReadDwell = Duration(seconds: 5);

/// Schedules and cancels the [kAutoMarkAsReadDwell] timer for the reading pane.
///
/// Extracted from `ReadingPane` so the dwell/cancel behavior can be unit
/// tested without mounting a full widget tree. Callers should invoke [update]
/// whenever the displayed message, its unread state, or the mark-read
/// callback changes, and [dispose] when the owning widget is disposed.
class AutoMarkAsReadController {
  AutoMarkAsReadController({
    this.dwell = kAutoMarkAsReadDwell,
    Timer Function(Duration duration, void Function() callback)? createTimer,
  }) : _createTimer = createTimer ?? Timer.new;

  final Duration dwell;
  final Timer Function(Duration duration, void Function() callback)
      _createTimer;

  Timer? _timer;
  String? _scheduledMessageId;

  /// True while a dwell timer is pending.
  bool get isScheduled => _timer != null;

  /// The message id the pending timer targets, or null when idle.
  String? get scheduledMessageId => _scheduledMessageId;

  /// Reconciles the dwell timer against the currently displayed message.
  ///
  /// Starts a fresh timer when [messageId] is non-null, [unread] is true, and
  /// [onMarkRead] is available. Cancels any pending timer when the message
  /// changes, becomes read, or no callback is available. Calling [update]
  /// repeatedly for the same still-unread message id is a no-op so it is
  /// safe to call from `build`/`didUpdateWidget`.
  void update({
    required String? messageId,
    required bool unread,
    required void Function()? onMarkRead,
  }) {
    if (messageId == null || !unread || onMarkRead == null) {
      cancel();
      return;
    }
    if (_scheduledMessageId == messageId && _timer != null) {
      return;
    }
    cancel();
    _scheduledMessageId = messageId;
    _timer = _createTimer(dwell, () {
      _timer = null;
      _scheduledMessageId = null;
      onMarkRead();
    });
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
