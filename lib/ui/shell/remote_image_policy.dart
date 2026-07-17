// ==============================================================================
// File: lib/ui/shell/remote_image_policy.dart
// Description: Detect and rewrite remote HTML image URLs for privacy controls
// Component: UI / Util
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

/// Transparent 1×1 GIF used when a remote image URL is blocked.
const String kBlockedRemoteImagePlaceholder =
    'data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7';

/// Outcome of applying [applyRemoteImagePolicy] to an HTML fragment.
class RemoteImagePolicyResult {
  const RemoteImagePolicyResult({
    required this.html,
    required this.blockedRemoteImages,
  });

  /// HTML after optional remote-image rewriting.
  final String html;

  /// True when at least one remote image URL was stripped/rewritten.
  final bool blockedRemoteImages;
}

final RegExp _imgSrcAttribute = RegExp(
  r'''(<img\b[^>]*?\bsrc\s*=\s*)(["']?)([^"'>\s]+)\2''',
  caseSensitive: false,
);

final RegExp _cssUrlFunction = RegExp(
  r'''url\(\s*(["']?)([^"')]+)\1\s*\)''',
  caseSensitive: false,
);

/// Returns true when [rawUrl] is an inline `cid:` or `data:` resource.
bool isAllowedInlineImageUrl(String rawUrl) {
  final String lower = rawUrl.trim().toLowerCase();
  return lower.startsWith('cid:') || lower.startsWith('data:');
}

/// Returns true when [rawUrl] loads over the network (http/https/`//`).
bool isRemoteImageUrl(String rawUrl) {
  final String url = rawUrl.trim();
  if (url.isEmpty || isAllowedInlineImageUrl(url)) {
    return false;
  }
  final String lower = url.toLowerCase();
  return lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('//');
}

/// True when [html] contains at least one remote `<img src>` or CSS `url()`.
bool htmlHasRemoteImages(String html) {
  for (final Match match in _imgSrcAttribute.allMatches(html)) {
    if (isRemoteImageUrl(match.group(3) ?? '')) {
      return true;
    }
  }
  for (final Match match in _cssUrlFunction.allMatches(html)) {
    if (isRemoteImageUrl(match.group(2) ?? '')) {
      return true;
    }
  }
  return false;
}

/// When [blockRemoteImages] is true, rewrites remote `img`/`url()` to a
/// placeholder (or `none` for CSS) while leaving `cid:` and `data:` intact.
RemoteImagePolicyResult applyRemoteImagePolicy(
  String html, {
  required bool blockRemoteImages,
}) {
  if (!blockRemoteImages) {
    return RemoteImagePolicyResult(html: html, blockedRemoteImages: false);
  }

  bool blocked = false;

  final String withoutRemoteImg = html.replaceAllMapped(_imgSrcAttribute, (
    Match match,
  ) {
    final String url = match.group(3) ?? '';
    if (!isRemoteImageUrl(url)) {
      return match.group(0)!;
    }
    blocked = true;
    final String quote = (match.group(2) ?? '').isEmpty
        ? '"'
        : match.group(2)!;
    final String prefix = match.group(1)!;
    return '$prefix$quote$kBlockedRemoteImagePlaceholder$quote';
  });

  final String rewritten = withoutRemoteImg.replaceAllMapped(_cssUrlFunction, (
    Match match,
  ) {
    final String url = match.group(2) ?? '';
    if (!isRemoteImageUrl(url)) {
      return match.group(0)!;
    }
    blocked = true;
    return 'none';
  });

  return RemoteImagePolicyResult(
    html: rewritten,
    blockedRemoteImages: blocked,
  );
}
