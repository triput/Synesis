// ==============================================================================
// File: lib/ui/shell/privacy_url_utils.dart
// Description: Shared host-extraction and domain-allowlist matching helpers
//              used by the remote-image and tracker-blocking privacy policies
// Component: UI / Util
// Version: 1.0 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-07-23
// ==============================================================================

/// Extracts the lowercase host from [rawUrl], returning null when the URL is
/// relative, an inline `cid:`/`data:` resource, or otherwise unparsable.
///
/// Handles protocol-relative URLs (`//host/path`) by assuming `https:`.
String? extractHostFromUrl(String rawUrl) {
  final String trimmed = rawUrl.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final String candidate = trimmed.startsWith('//')
      ? 'https:$trimmed'
      : trimmed;
  final Uri? parsed = Uri.tryParse(candidate);
  if (parsed == null || parsed.host.isEmpty) {
    return null;
  }
  return parsed.host.toLowerCase();
}

/// Case-insensitive suffix match: [host] matches an allowlist entry when it
/// equals the entry exactly or is a subdomain of it (e.g. `img.example.com`
/// matches an `example.com` allowlist entry).
bool isHostAllowlisted(String? host, List<String> allowlistDomains) {
  if (host == null || host.isEmpty || allowlistDomains.isEmpty) {
    return false;
  }
  final String normalizedHost = host.toLowerCase();
  for (final String rawDomain in allowlistDomains) {
    final String domain = rawDomain.trim().toLowerCase();
    if (domain.isEmpty) {
      continue;
    }
    if (normalizedHost == domain || normalizedHost.endsWith('.$domain')) {
      return true;
    }
  }
  return false;
}
