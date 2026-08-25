// ==============================================================================
// File: lib/digest/digest_bucket.dart
// Description: Exclusive mail-hygiene digest buckets (Wave MH slice 1).
// Component: Digest / Domain
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

/// First-match-wins exclusive bucket for inbox hygiene classification.
enum DigestBucket {
  urgent,
  personalNonUrgent,
  newsletters,
  social,
  other,
}

/// Parallel money overlay (not exclusive with [DigestBucket]).
enum DigestMoneyConfidence {
  none,
  maybe,
  high,
}
