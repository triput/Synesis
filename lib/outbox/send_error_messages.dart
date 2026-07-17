// ==============================================================================
// File: lib/outbox/send_error_messages.dart
// Description: Maps SMTP/IMAP/Graph send failures to actionable user copy.
// Component: Outbox
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

/// Turns a raw send/outbox error into short, actionable guidance for the UI.
String actionableSendError(Object? error, {String? accountHint}) {
  final String raw = (error?.toString() ?? '').trim();
  if (raw.isEmpty) {
    return 'Send failed. Check your account settings and try again.';
  }

  // Already mapped (e.g. stored on outbox.lastError).
  if (raw.startsWith('Send failed')) {
    return raw;
  }

  final String lower = raw.toLowerCase();
  final String? hint = accountHint?.trim();
  final String account =
      (hint == null || hint.isEmpty) ? 'this account' : hint;

  if (_matchesAny(lower, const <String>[
    'authentication failed',
    'auth failed',
    'invalid credentials',
    'login failed',
    'not authenticated',
    '535',
    '534',
    'username and password not accepted',
    'application-specific password',
    'xoauth',
    'oauth',
    'token',
    'unauthorized',
    '401',
  ])) {
    return 'Send failed: could not sign in to SMTP for $account. '
        'Update the password/app password, or re-authenticate Google/Microsoft, then try again.';
  }

  if (_matchesAny(lower, const <String>[
    'starttls',
    'tls',
    'ssl',
    'certificate',
    'handshake',
  ])) {
    return 'Send failed: secure connection to the SMTP server failed. '
        'Confirm SMTP host/port (Gmail: smtp.gmail.com port 465) and try again.';
  }

  if (_matchesAny(lower, const <String>[
    'socketexception',
    'connection refused',
    'connection reset',
    'network is unreachable',
    'failed host lookup',
    'timed out',
    'timeout',
    'os error',
  ])) {
    return 'Send failed: could not reach the SMTP server. '
        'Check SMTP host and port for $account, then your network, and try again.';
  }

  if (_matchesAny(lower, const <String>[
    'recipient',
    'rcpt',
    'mailbox unavailable',
    'user unknown',
    '550',
    '551',
    '553',
  ])) {
    return 'Send failed: the server rejected a recipient address. '
        'Check To/Cc and try again.';
  }

  if (_matchesAny(lower, const <String>[
    'rejected the message',
    '552',
    '554',
    'message too large',
  ])) {
    return 'Send failed: the SMTP server rejected the message. '
        'Try a shorter message or fewer recipients, then send again.';
  }

  if (_matchesAny(lower, const <String>[
    'no provider',
    'credentials',
    'not configured',
  ])) {
    return 'Send failed: $account is missing usable send credentials. '
        'Open Manage accounts, re-enter SMTP settings or sign in again.';
  }

  // Strip noisy exception type prefixes for leftover technical detail.
  String detail = raw
      .replaceFirst(RegExp(r'^ProtocolException(\([^)]*\))?:\s*'), '')
      .replaceFirst(RegExp(r'^StateError:\s*'), '')
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .trim();
  if (detail.length > 220) {
    detail = '${detail.substring(0, 217)}…';
  }
  return 'Send failed: $detail. Check account SMTP settings and try again.';
}

bool _matchesAny(String lower, List<String> needles) {
  for (final String needle in needles) {
    if (lower.contains(needle)) {
      return true;
    }
  }
  return false;
}
