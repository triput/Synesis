// ==============================================================================
// File: lib/outbox/send_error_messages.dart
// Description: Maps SMTP/IMAP/Graph send failures to actionable user copy.
// Component: Outbox
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-24
// ==============================================================================

/// Turns a raw send/outbox error into short, actionable guidance for the UI.
///
/// DEF-047: SMTP servers reuse the same 5xx status-code ranges for both
/// `MAIL FROM` (envelope sender) and `RCPT TO` (recipient) rejections, and
/// the human-readable text does not always contain the word "recipient".
/// Bucket matching below therefore checks From/sender-policy failures
/// (Gmail "Sender address rejected", DMARC/SPF policy failures, etc.) before
/// falling back to the recipient bucket, and every bucket appends the
/// sanitized raw server detail so the real cause is visible even when a
/// bucket guess is imprecise.
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
  final String detail = _sanitizedDetail(raw);

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
        'Update the password/app password, or re-authenticate Google/Microsoft, '
        'then try again.${_withDetail(detail)}';
  }

  if (_matchesAny(lower, const <String>[
    'starttls',
    'tls',
    'ssl',
    'certificate',
    'handshake',
  ])) {
    return 'Send failed: secure connection to the SMTP server failed. '
        'Confirm SMTP host/port (Gmail: smtp.gmail.com port 465) and try '
        'again.${_withDetail(detail)}';
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
        'Check SMTP host and port for $account, then your network, and try '
        'again.${_withDetail(detail)}';
  }

  // Sender / envelope-from rejections. Must be checked before the recipient
  // bucket below: Gmail's "Sender address rejected: not owned by user" and
  // DMARC/SPF policy failures both surface with 5xx codes that overlap with
  // recipient-rejection codes, but the fix is entirely different (verify the
  // From address / domain authorization, not the To/Cc list).
  if (_matchesAny(lower, const <String>[
    'sender address rejected',
    'sender rejected',
    'not owned by user',
    'mail from command rejected',
    'sender verify failed',
    'envelope sender',
    'domain does not match',
    'unauthenticated email is not accepted',
    'dmarc',
    'spf',
    '5.7.1',
    '5.7.25',
    '5.7.26',
    '5.7.27',
  ])) {
    return 'Send failed: the server rejected the From address for $account. '
        'If this is a custom domain sent through Gmail/Workspace SMTP, '
        'confirm the address is a verified "Send mail as" alias and that '
        'SPF/DKIM/DMARC for the domain authorize Google, then try '
        'again.${_withDetail(detail)}';
  }

  // Client-side enough_mail guard when MimeMessage.recipientAddresses is
  // empty (see DEF-048). Must not be mistaken for a real RCPT rejection.
  if (_matchesAny(lower, const <String>[
    '500 no recipients',
    'no recipients',
  ])) {
    return 'Send failed: the message had no SMTP recipients after build. '
        'Close Compose and try Send again.${_withDetail(detail)}';
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
        'Check To/Cc and try again.${_withDetail(detail)}';
  }

  if (_matchesAny(lower, const <String>[
    'rejected the message',
    '552',
    '554',
    'message too large',
  ])) {
    return 'Send failed: the SMTP server rejected the message. '
        'Try a shorter message or fewer recipients, then send '
        'again.${_withDetail(detail)}';
  }

  if (_matchesAny(lower, const <String>[
    'no provider',
    'credentials',
    'not configured',
  ])) {
    return 'Send failed: $account is missing usable send credentials. '
        'Open Manage accounts, re-enter SMTP settings or sign in '
        'again.${_withDetail(detail)}';
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

/// Strips noisy exception-type/wrapper prefixes so the leftover text is a
/// short, human-readable snippet of what the server actually said.
String _sanitizedDetail(String raw) {
  String detail = raw
      .replaceFirst(RegExp(r'^ProtocolException(\([^)]*\))?:\s*'), '')
      .replaceFirst(RegExp(r'^StateError:\s*'), '')
      .replaceFirst(RegExp(r'^Exception:\s*'), '')
      .replaceFirst(
        RegExp(r'Unable to send SMTP mail\.\s*Cause:\s*', caseSensitive: false),
        '',
      )
      .replaceFirst(RegExp(r'^SmtpException:\s*'), '')
      .trim();
  // Collapse newlines/whitespace so multi-line SMTP responses render as one
  // readable line in the UI.
  detail = detail.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (detail.length > 200) {
    detail = '${detail.substring(0, 197)}…';
  }
  return detail;
}

/// Renders sanitized server [detail] as a UI-safe suffix, or '' when empty.
String _withDetail(String detail) {
  if (detail.isEmpty) {
    return '';
  }
  return ' (Server said: $detail)';
}
