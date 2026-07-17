// ==============================================================================
// File: lib/focus/rule_based_focus_scorer.dart
// Description: Deterministic Focus scorer for automated and bulk messages.
// Component: Domain / Focus
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/focus/focus_override_registry.dart';
import 'package:bytemail/focus/focus_scorer.dart';
import 'package:bytemail/focus/mail_message_draft.dart';

class RuleBasedFocusScorer implements FocusScorer {
  const RuleBasedFocusScorer({
    this.overrides,
    this.accountId,
  });

  final FocusOverrideRegistry? overrides;
  final String? accountId;

  static const Set<String> _bulkLocalParts = <String>{
    'noreply',
    'no-reply',
    'donotreply',
    'do-not-reply',
    'mailer-daemon',
    'newsletter',
    'newsletters',
    'marketing',
    'promo',
    'promotions',
    'notifications',
    'notification',
    'digest',
    'bounce',
    'bounces',
    'campaign',
  };

  static final RegExp _otherSubject = RegExp(
    r'\b(unsubscribe|newsletter|weekly\s+digest|daily\s+digest|'
    r'email\s+preferences|view\s+in\s+(browser|app)|'
    r'%\s*off|limited\s+time|special\s+offer)\b',
    caseSensitive: false,
  );

  @override
  FocusBucket score(MailMessageDraft draft) {
    final FocusBucket baseline = _algorithmicScore(draft);
    return overrides?.match(draft, accountId: accountId) ?? baseline;
  }

  FocusBucket _algorithmicScore(MailMessageDraft draft) {
    final Map<String, String> headers = _normalisedHeaders(draft.headers);
    final String sender = draft.fromAddress.toLowerCase().trim();
    final String precedence = headers['precedence']?.trim().toLowerCase() ?? '';
    final String localPart = _localPart(sender);

    if (headers.containsKey('list-id') ||
        headers.containsKey('list-unsubscribe') ||
        headers.containsKey('list-unsubscribe-post') ||
        headers.containsKey('x-campaign') ||
        headers.containsKey('feedback-id') ||
        precedence == 'bulk' ||
        precedence == 'list' ||
        headers.containsKey('auto-submitted') ||
        _looksLikeMailer(headers['x-mailer']) ||
        _bulkLocalParts.contains(localPart) ||
        localPart.contains('noreply') ||
        localPart.contains('no-reply') ||
        localPart.contains('donotreply') ||
        localPart.contains('newsletter') ||
        localPart.contains('mailer-daemon') ||
        _otherSubject.hasMatch(draft.subject)) {
      return FocusBucket.other;
    }
    return FocusBucket.focused;
  }

  bool _looksLikeMailer(String? xMailer) {
    if (xMailer == null || xMailer.trim().isEmpty) {
      return false;
    }
    final String lower = xMailer.toLowerCase();
    return lower.contains('mailchimp') ||
        lower.contains('sendgrid') ||
        lower.contains('constant contact') ||
        lower.contains('klaviyo') ||
        lower.contains('hubspot') ||
        lower.contains('marketo') ||
        lower.contains('mailgun') ||
        lower.contains('campaign monitor') ||
        lower.contains('exacttarget') ||
        lower.contains('salesforce') ||
        lower.contains('amazon ses');
  }

  String _localPart(String sender) {
    final Match? bracketed =
        RegExp(r'<\s*([^>\s]+@[^>\s]+)\s*>').firstMatch(sender);
    final String address = (bracketed?.group(1) ?? sender).trim().toLowerCase();
    final int at = address.indexOf('@');
    if (at <= 0) {
      return address;
    }
    return address.substring(0, at);
  }

  Map<String, String> _normalisedHeaders(Map<String, String> headers) {
    return <String, String>{
      for (final MapEntry<String, String> entry in headers.entries)
        entry.key.trim().toLowerCase(): entry.value,
    };
  }
}
