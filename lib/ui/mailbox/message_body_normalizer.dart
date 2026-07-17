// ==============================================================================
// File: lib/ui/mailbox/message_body_normalizer.dart
// Description: Detect and prepare message bodies (HTML preferred, plain fallback)
// Component: UI / Util
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

/// True when [raw] looks like an HTML message/part rather than plain text.
bool isHtmlMessageBody(String raw) {
  final String trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final String lower = trimmed.toLowerCase();
  return lower.contains('<html') ||
      lower.contains('<!doctype html') ||
      lower.contains('<body') ||
      lower.contains('<div') ||
      lower.contains('<table') ||
      lower.contains('<p>') ||
      lower.contains('<br') ||
      lower.contains('<img') ||
      lower.contains('<a ');
}

/// Preserve remote body content for the reading pane (HTML is not stripped).
String prepareMessageBody(String raw) => raw.trim();
