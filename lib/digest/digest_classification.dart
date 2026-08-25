// ==============================================================================
// File: lib/digest/digest_classification.dart
// Description: Classifier output for one digest message row.
// Component: Digest / Domain
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'package:synesis/digest/digest_bucket.dart';

/// Result of exclusive-bucket classification plus optional money overlay.
class DigestClassification {
  const DigestClassification({
    required this.bucket,
    this.moneyConfidence = DigestMoneyConfidence.none,
  });

  final DigestBucket bucket;
  final DigestMoneyConfidence moneyConfidence;
}
