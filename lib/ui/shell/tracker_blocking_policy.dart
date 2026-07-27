// ==============================================================================
// File: lib/ui/shell/tracker_blocking_policy.dart
// Description: Detect and strip known ESP/analytics tracking pixels and open
//              tracking beacons from HTML message bodies (D6-7)
// Component: UI / Util
// Version: 1.0 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-07-23
// ==============================================================================

import 'package:synesis/ui/shell/privacy_url_utils.dart';
import 'package:synesis/ui/shell/remote_image_policy.dart';

/// Outcome of applying [applyTrackerBlockingPolicy] to an HTML fragment.
class TrackerBlockingPolicyResult {
  const TrackerBlockingPolicyResult({
    required this.html,
    required this.blockedTrackers,
  });

  /// HTML after optional tracker rewriting.
  final String html;

  /// True when at least one known tracker URL was stripped/rewritten.
  final bool blockedTrackers;
}

/// Curated, locally-maintained denylist of ESP/marketing-analytics hosts
/// known to serve open-tracking pixels or click-analytics beacons. Matching
/// is a case-insensitive suffix match (see [isHostAllowlisted]), so entries
/// also cover their subdomains (e.g. `track.hubspot.com`).
///
/// This list intentionally stays local/curated per D6-7 scope — no runtime
/// fetch of a cloud-hosted tracker list.
const List<String> kTrackerHostDenylist = <String>[
  // Mailchimp / Intuit Mailchimp
  'list-manage.com',
  'list-manage1.com',
  'mmsend.com',
  'mmsend1.com',
  // SendGrid
  'sendgrid.net',
  // Mailgun
  'mailgun.org',
  // HubSpot
  'hs-analytics.net',
  'hubspotemail.net',
  'hubspotlinks.com',
  'hubspot.com',
  // Klaviyo
  'klclick.com',
  'klaviyomail.com',
  'klaviyo.com',
  // Braze
  'appboy.com',
  'braze.com',
  // Iterable
  'iterable.com',
  // Marketo
  'mktoresp.com',
  'marketo.net',
  // Salesforce Marketing Cloud / ExactTarget
  'exacttarget.com',
  'exct.net',
  // Constant Contact
  'rmkr.net',
  // Campaign Monitor
  'createsend.com',
  // ActiveCampaign
  'activehosted.com',
  // Google Analytics / Ads
  'google-analytics.com',
  'googletagmanager.com',
  'doubleclick.net',
  'googlesyndication.com',
  // Bing Ads
  'bat.bing.com',
  // LinkedIn Ads
  'px.ads.linkedin.com',
  // Mixpanel
  'mixpanel.com',
  // Segment
  'segment.io',
  // Amplitude
  'amplitude.com',
  // Customer.io
  'track.customer.io',
  // Sailthru
  'sailthru.com',
  // Listrak
  'listrakbi.com',
  // Emma
  'e2ma.net',
  // Drip
  'trk.drip.com',
  // ConvertKit
  'convertkit.com',
  // Omnisend
  'omnisend.com',
];

/// Common open-tracking pixel/beacon path substrings observed across ESPs,
/// matched case-insensitively regardless of host. Combined with the host
/// denylist to catch first-party-looking tracking endpoints (e.g. a sender's
/// own domain proxying an ESP's open-tracking pixel).
const List<String> kTrackerPathPatterns = <String>[
  '/wf/open',
  '/track/open',
  '/api/track',
  '/trk/open',
  '/email/open',
  '/o/open',
  'open.gif',
  'open.png',
  'pixel.gif',
  'beacon.gif',
  '/beacon.',
];

/// True when [rawUrl] resolves to a known tracker host or matches a common
/// open-tracking path pattern. Requires [rawUrl] to be a remote (http/https)
/// resource; inline `cid:`/`data:` URLs are never trackers.
bool isTrackerUrl(String rawUrl) {
  if (!isRemoteImageUrl(rawUrl)) {
    return false;
  }
  final String? host = extractHostFromUrl(rawUrl);
  if (isHostAllowlisted(host, kTrackerHostDenylist)) {
    return true;
  }
  final String lowerUrl = rawUrl.toLowerCase();
  for (final String pattern in kTrackerPathPatterns) {
    if (lowerUrl.contains(pattern)) {
      return true;
    }
  }
  return false;
}

/// True when [html] contains at least one detectable tracker resource.
bool htmlHasTrackers(String html) {
  final TrackerBlockingPolicyResult probe = applyTrackerBlockingPolicy(
    html,
    blockTrackers: true,
  );
  return probe.blockedTrackers;
}

/// When [blockTrackers] is true, strips known tracker `img`/`srcset`/CSS
/// `url()` resources (see [isTrackerUrl]) while leaving other remote images
/// untouched — independent of the general remote-image-blocking policy.
/// URLs whose host matches [allowlistDomains] are always left intact, since
/// the user explicitly trusted that domain for images.
TrackerBlockingPolicyResult applyTrackerBlockingPolicy(
  String html, {
  required bool blockTrackers,
  List<String> allowlistDomains = const <String>[],
}) {
  if (!blockTrackers) {
    return TrackerBlockingPolicyResult(html: html, blockedTrackers: false);
  }

  bool shouldStrip(String url) {
    if (!isTrackerUrl(url)) {
      return false;
    }
    return !isHostAllowlisted(extractHostFromUrl(url), allowlistDomains);
  }

  final RemoteImagePolicyResult result = _applyTrackerRewrite(
    html,
    shouldStrip: shouldStrip,
  );
  return TrackerBlockingPolicyResult(
    html: result.html,
    blockedTrackers: result.blockedRemoteImages,
  );
}

final RegExp _imgSrcAttribute = RegExp(
  r'''(<img\b[^>]*?\bsrc\s*=\s*)(["']?)([^"'>\s]+)\2''',
  caseSensitive: false,
);

final RegExp _srcsetAttribute = RegExp(
  r'''(<(?:img|source)\b[^>]*?\bsrcset\s*=\s*)(["'])([^"']*)\2''',
  caseSensitive: false,
);

final RegExp _cssUrlFunction = RegExp(
  r'''url\(\s*(["']?)([^"')]+)\1\s*\)''',
  caseSensitive: false,
);

RemoteImagePolicyResult _applyTrackerRewrite(
  String html, {
  required bool Function(String url) shouldStrip,
}) {
  bool blocked = false;

  final String withoutTrackerImg = html.replaceAllMapped(_imgSrcAttribute, (
    Match match,
  ) {
    final String url = match.group(3) ?? '';
    if (!shouldStrip(url)) {
      return match.group(0)!;
    }
    blocked = true;
    final String quote = (match.group(2) ?? '').isEmpty
        ? '"'
        : match.group(2)!;
    final String prefix = match.group(1)!;
    return '$prefix$quote$kBlockedRemoteImagePlaceholder$quote';
  });

  final String withoutTrackerSrcset = withoutTrackerImg.replaceAllMapped(
    _srcsetAttribute,
    (Match match) {
      final String srcset = match.group(3) ?? '';
      bool anyBlocked = false;
      final List<String> rewritten = <String>[];
      for (final String rawCandidate in srcset.split(',')) {
        final String candidate = rawCandidate.trim();
        if (candidate.isEmpty) {
          continue;
        }
        final int splitIndex = candidate.indexOf(RegExp(r'\s'));
        final String url = splitIndex == -1
            ? candidate
            : candidate.substring(0, splitIndex);
        final String descriptor = splitIndex == -1
            ? ''
            : candidate.substring(splitIndex);
        if (shouldStrip(url)) {
          anyBlocked = true;
          rewritten.add('$kBlockedRemoteImagePlaceholder$descriptor');
        } else {
          rewritten.add(candidate);
        }
      }
      if (!anyBlocked) {
        return match.group(0)!;
      }
      blocked = true;
      final String prefix = match.group(1)!;
      final String quote = match.group(2)!;
      return '$prefix$quote${rewritten.join(', ')}$quote';
    },
  );

  final String rewritten = withoutTrackerSrcset.replaceAllMapped(
    _cssUrlFunction,
    (Match match) {
      final String url = match.group(2) ?? '';
      if (!shouldStrip(url)) {
        return match.group(0)!;
      }
      blocked = true;
      return 'none';
    },
  );

  return RemoteImagePolicyResult(
    html: rewritten,
    blockedRemoteImages: blocked,
  );
}
