// ==============================================================================
// File: lib/sync/imap_idle_service.dart
// Description: Long-lived IMAP IDLE watches that enqueue push_wake on change.
// Component: Sync / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';

import 'package:bytemail/protocol/imap_smtp_mail_provider.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/sync/sync_engine.dart';

/// Manages per-account IMAP IDLE sessions outside short-lived sync jobs.
class ImapIdleService {
  ImapIdleService({
    required ProviderResolver resolveProvider,
    required Future<void> Function(String accountId) onMailboxChanged,
    required Future<bool> Function() allowPush,
  })  : _resolveProvider = resolveProvider,
        _onMailboxChanged = onMailboxChanged,
        _allowPush = allowPush;

  final ProviderResolver _resolveProvider;
  final Future<void> Function(String accountId) _onMailboxChanged;
  final Future<bool> Function() _allowPush;

  final Map<String, _IdleSession> _sessions = <String, _IdleSession>{};
  bool _disposed = false;

  /// Starts (or keeps) an IDLE watch for [accountId] when push is allowed.
  Future<void> ensureWatching(String accountId) async {
    if (_disposed) {
      return;
    }
    if (!await _allowPush()) {
      await stop(accountId);
      return;
    }
    if (_sessions.containsKey(accountId)) {
      return;
    }

    final MailProvider? provider = await _resolveProvider(accountId);
    if (provider is! ImapSmtpMailProvider) {
      await provider?.dispose();
      return;
    }
    if (!provider.capabilities.supportsPush) {
      await provider.dispose();
      return;
    }

    final _IdleSession session = _IdleSession(provider: provider);
    _sessions[accountId] = session;

    // Fire-and-forget async loop; errors end the session quietly.
    unawaited(_runLoop(accountId, session));
  }

  Future<void> _runLoop(String accountId, _IdleSession session) async {
    try {
      final bool started = await session.provider.runInboxIdleLoop(
        onMailboxChanged: () {
          if (session.wakeScheduled) {
            return;
          }
          session.wakeScheduled = true;
          unawaited(() async {
            try {
              await _onMailboxChanged(accountId);
            } finally {
              session.wakeScheduled = false;
            }
          }());
        },
        shouldContinue: () async {
          if (_disposed || session.cancelled) {
            return false;
          }
          return _allowPush();
        },
      );
      if (!started) {
        // Server has no IDLE — leave poll-only.
      }
    } on Object {
      // Watch ends; a later sync may restart it.
    } finally {
      if (identical(_sessions[accountId], session)) {
        _sessions.remove(accountId);
      }
      await session.provider.dispose();
    }
  }

  Future<void> stop(String accountId) async {
    final _IdleSession? session = _sessions.remove(accountId);
    if (session == null) {
      return;
    }
    session.cancelled = true;
    await session.provider.dispose();
  }

  Future<void> stopAll() async {
    final List<String> ids = _sessions.keys.toList(growable: false);
    for (final String id in ids) {
      await stop(id);
    }
  }

  /// Re-evaluates push policy and stops sessions that are no longer allowed.
  Future<void> refreshPolicy() async {
    if (!await _allowPush()) {
      await stopAll();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    await stopAll();
  }
}

class _IdleSession {
  _IdleSession({required this.provider});

  final ImapSmtpMailProvider provider;
  bool cancelled = false;
  bool wakeScheduled = false;
}
