// ==============================================================================
// File: lib/domain/address_match_scope.dart
// Description: Sender vs domain scope for junk and Focus override actions.
// Component: Domain
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

/// Whether an address action applies to one mailbox or an entire domain.
enum AddressMatchScope {
  /// Exact From address (default).
  sender,

  /// Every address sharing the From domain (e.g. `news@brand.com` → `brand.com`).
  domain,
}
