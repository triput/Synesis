// ==============================================================================
// File: lib/focus/focus_header_map.dart
// Description: Parse raw RFC822 header text into a Focus classification map.
// Component: Domain / Focus
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

/// Converts raw header text (`Name: value` lines) into a lower-cased name map.
Map<String, String> focusHeadersFromRaw(String? rawHeaders) {
  if (rawHeaders == null || rawHeaders.trim().isEmpty) {
    return const <String, String>{};
  }
  final Map<String, String> headers = <String, String>{};
  String? currentName;
  final StringBuffer currentValue = StringBuffer();

  void flush() {
    final String? name = currentName;
    if (name == null) {
      return;
    }
    final String value = currentValue.toString().trim();
    if (value.isNotEmpty) {
      headers[name] = value;
    }
    currentName = null;
    currentValue.clear();
  }

  for (final String rawLine in rawHeaders.replaceAll('\r\n', '\n').split('\n')) {
    if (rawLine.isEmpty) {
      flush();
      continue;
    }
    if (rawLine.startsWith(' ') || rawLine.startsWith('\t')) {
      if (currentName != null) {
        currentValue.write(' ');
        currentValue.write(rawLine.trim());
      }
      continue;
    }
    final int colon = rawLine.indexOf(':');
    if (colon <= 0) {
      continue;
    }
    flush();
    currentName = rawLine.substring(0, colon).trim().toLowerCase();
    currentValue.write(rawLine.substring(colon + 1).trim());
  }
  flush();
  return headers;
}

/// Builds a classification header map from known IMAP/Graph header fields.
Map<String, String> focusHeadersFromFields({
  String? listId,
  String? listUnsubscribe,
  String? listUnsubscribePost,
  String? precedence,
  String? autoSubmitted,
  String? xCampaign,
  String? feedbackId,
  String? xMailer,
  Map<String, String>? extra,
}) {
  final Map<String, String> headers = <String, String>{
    if (extra != null) ...extra,
  };
  void put(String name, String? value) {
    final String? trimmed = value?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      headers[name] = trimmed;
    }
  }

  put('list-id', listId);
  put('list-unsubscribe', listUnsubscribe);
  put('list-unsubscribe-post', listUnsubscribePost);
  put('precedence', precedence);
  put('auto-submitted', autoSubmitted);
  put('x-campaign', xCampaign);
  put('feedback-id', feedbackId);
  put('x-mailer', xMailer);
  return headers;
}
