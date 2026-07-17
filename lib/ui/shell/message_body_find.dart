// ==============================================================================
// File: lib/ui/shell/message_body_find.dart
// Description: Plain-text / stripped-HTML find ranges for in-message search
// Component: UI / Util
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

/// Inclusive start / exclusive end of a case-insensitive needle match.
class TextMatchRange {
  const TextMatchRange(this.start, this.end);

  final int start;
  final int end;

  int get length => end - start;
}

/// Returns non-overlapping case-insensitive matches of [needle] in [haystack].
List<TextMatchRange> findTextMatches(String haystack, String needle) {
  final String trimmedNeedle = needle.trim();
  if (trimmedNeedle.isEmpty || haystack.isEmpty) {
    return const <TextMatchRange>[];
  }
  final String lowerHaystack = haystack.toLowerCase();
  final String lowerNeedle = trimmedNeedle.toLowerCase();
  final List<TextMatchRange> matches = <TextMatchRange>[];
  int from = 0;
  while (from <= lowerHaystack.length - lowerNeedle.length) {
    final int index = lowerHaystack.indexOf(lowerNeedle, from);
    if (index < 0) {
      break;
    }
    matches.add(TextMatchRange(index, index + lowerNeedle.length));
    from = index + lowerNeedle.length;
  }
  return matches;
}

/// Best-effort HTML → plain text for match counting (not a full HTML parser).
String stripHtmlToPlainText(String body) {
  if (!RegExp(r'<[a-z!/][^>]*>', caseSensitive: false).hasMatch(body)) {
    return body;
  }
  return body
      .replaceAll(RegExp(r'<(br|hr)\s*/?>', caseSensitive: false), '\n')
      .replaceAll(
        RegExp(r'</(p|div|li|tr|h[1-6])>', caseSensitive: false),
        '\n',
      )
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

/// Wraps [activeIndex] into `[0, matchCount)`.
int wrapFindIndex(int activeIndex, int matchCount) {
  if (matchCount <= 0) {
    return 0;
  }
  final int mod = activeIndex % matchCount;
  return mod < 0 ? mod + matchCount : mod;
}
