// ==============================================================================
// File: lib/protocol/thread_id.dart
// Description: Pure helpers for deriving stable mail thread / conversation keys.
// Component: Protocol
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

/// Resolves an unscoped thread key for a remote message header.
///
/// Preference order:
/// 1. Provider conversation id (e.g. Graph `conversationId`)
/// 2. Root of the RFC `References` chain (first Message-ID token)
/// 3. `In-Reply-To`
/// 4. `Message-ID`
/// 5. [fallbackProviderId]
///
/// Account scoping (`'$accountId:$root'`) is applied by SyncEngine.
String? resolveThreadId({
  String? conversationId,
  String? messageId,
  String? inReplyTo,
  String? references,
  String? fallbackProviderId,
}) {
  final String? conversation = _normalizeMessageId(conversationId);
  if (conversation != null) {
    return conversation;
  }
  final String? rootReference = _rootReference(references);
  if (rootReference != null) {
    return rootReference;
  }
  final String? replyTo = _normalizeMessageId(inReplyTo);
  if (replyTo != null) {
    return replyTo;
  }
  final String? mid = _normalizeMessageId(messageId);
  if (mid != null) {
    return mid;
  }
  final String? fallback = fallbackProviderId?.trim();
  if (fallback != null && fallback.isNotEmpty) {
    return fallback;
  }
  return null;
}

String? _rootReference(String? references) {
  if (references == null) {
    return null;
  }
  final String trimmed = references.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final Iterable<RegExpMatch> matches = RegExp(
    r'<[^>]+>|[^\s<>]+',
  ).allMatches(trimmed);
  for (final RegExpMatch match in matches) {
    final String? normalized = _normalizeMessageId(match.group(0));
    if (normalized != null) {
      return normalized;
    }
  }
  return null;
}

/// Strips angle brackets and lowercases for stable comparison / keys.
String? _normalizeMessageId(String? raw) {
  if (raw == null) {
    return null;
  }
  String value = raw.trim();
  if (value.isEmpty) {
    return null;
  }
  if (value.startsWith('<') && value.endsWith('>') && value.length > 2) {
    value = value.substring(1, value.length - 1).trim();
  }
  if (value.isEmpty) {
    return null;
  }
  return value.toLowerCase();
}
