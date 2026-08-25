// ==============================================================================
// File: lib/digest/digest_message.dart
// Description: Header-only mail row for offline digest classification.
// Component: Digest / Domain
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

/// Minimal provider-agnostic message surface for the digest classifier.
class DigestMessage {
  const DigestMessage({
    required this.id,
    required this.accountId,
    required this.accountAddress,
    required this.fromAddress,
    required this.fromName,
    required this.subject,
    required this.snippet,
    this.toAddresses = const <String>[],
    this.ccAddresses = const <String>[],
    this.receivedAt,
    this.listUnsubscribe,
    this.listId,
    this.gmailCategory,
    this.precedence,
  });

  final String id;
  final String accountId;

  /// Primary mailbox address for To/Cc presence checks.
  final String accountAddress;
  final String fromAddress;
  final String fromName;
  final String subject;
  final String snippet;
  final List<String> toAddresses;
  final List<String> ccAddresses;
  final DateTime? receivedAt;
  final String? listUnsubscribe;
  final String? listId;
  final String? gmailCategory;
  final String? precedence;
}
