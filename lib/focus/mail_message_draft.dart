// ==============================================================================
// File: lib/focus/mail_message_draft.dart
// Description: Minimal incoming-message data used for Focus classification.
// Component: Domain / Focus
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

class MailMessageDraft {
  const MailMessageDraft({
    required this.fromAddress,
    required this.subject,
    this.headers = const <String, String>{},
  });

  final String fromAddress;
  final String subject;
  final Map<String, String> headers;
}
