// ==============================================================================
// File: lib/mime/outgoing_envelope.dart
// Description: Value type describing an outgoing MIME message to serialize.
// Component: MIME / Domain
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-16
// ==============================================================================

/// Fields required to build an RFC-ish multipart MIME message.
class OutgoingEnvelope {
  const OutgoingEnvelope({
    required this.from,
    required this.to,
    required this.subject,
    required this.textBody,
    this.cc = const <String>[],
    this.bcc = const <String>[],
    this.htmlBody,
    this.attachmentPaths = const <String>[],
    this.inReplyTo,
    this.references,
  });

  final String from;
  final List<String> to;
  final List<String> cc;
  final List<String> bcc;
  final String subject;
  final String textBody;
  final String? htmlBody;
  final List<String> attachmentPaths;
  final String? inReplyTo;
  final String? references;
}
