// ==============================================================================
// File: lib/domain/pim_ids.dart
// Description: Deterministic local primary keys for provider-scoped PIM rows.
// Component: Domain
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-08-04
// ==============================================================================

import 'dart:convert';

/// Stable identity helpers for contact lists, contacts, calendars, and events.
///
/// Local rows are keyed by a deterministic encoding of
/// `accountId + NUL + providerId` so sync refreshes do not create duplicates
/// when the same remote object is upserted again (see Wave 2 / V2.0a P0 QA).
abstract final class PimIds {
  /// Prefix for client-generated provider ids awaiting remote create (Wave 6).
  static const String localProviderIdPrefix = 'local:';

  /// Returns a URL-safe, padding-stripped base64 local id for [accountId] and
  /// [providerId]. Identical inputs always yield the same id.
  static String stableLocalId(String accountId, String providerId) {
    return base64Url
        .encode(utf8.encode('$accountId\u0000$providerId'))
        .replaceAll('=', '');
  }

  /// Whether [providerId] is a Synesis-local id not yet rewritten to a remote
  /// Graph/Google/DAV identity (Wave 6 copy / local CRUD).
  static bool isLocalProviderId(String providerId) =>
      providerId.startsWith(localProviderIdPrefix);
}
