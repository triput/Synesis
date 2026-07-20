// ==============================================================================
// File: lib/compose/account_signature.dart
// Description: Domain types for per-account HTML/plain signatures and assets.
// Component: Domain
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

/// App-layer signature (distinct from Drift [AccountSignature] row type).
class MailSignature {
  const MailSignature({
    required this.id,
    required this.accountId,
    required this.name,
    required this.bodyPlain,
    this.bodyHtml,
    this.isDefault = false,
    this.sortOrder = 0,
  });

  final String id;
  final String accountId;
  final String name;
  final String bodyPlain;
  final String? bodyHtml;
  final bool isDefault;
  final int sortOrder;
}

class MailSignatureAsset {
  const MailSignatureAsset({
    required this.id,
    required this.signatureId,
    required this.localPath,
    required this.contentId,
    required this.mimeType,
  });

  final String id;
  final String signatureId;
  final String localPath;
  final String contentId;
  final String mimeType;
}

class MailTemplate {
  const MailTemplate({
    required this.id,
    required this.name,
    required this.subject,
    required this.bodyHtml,
    this.accountId,
    this.sortOrder = 0,
  });

  final String id;
  final String? accountId;
  final String name;
  final String subject;
  final String bodyHtml;
  final int sortOrder;
}

class OutboundBlobRef {
  const OutboundBlobRef({
    required this.id,
    required this.accountId,
    required this.path,
    required this.sizeBytes,
    required this.createdAt,
  });

  final String id;
  final String accountId;
  final String path;
  final int sizeBytes;
  final int createdAt;
}
