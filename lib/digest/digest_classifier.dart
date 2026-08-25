// ==============================================================================
// File: lib/digest/digest_classifier.dart
// Description: Exclusive-bucket + money-overlay classifier for mail hygiene digest.
// Component: Digest / Logic
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'package:synesis/digest/digest_bucket.dart';
import 'package:synesis/digest/digest_classification.dart';
import 'package:synesis/digest/digest_message.dart';

/// Header/snippet heuristics for Wave MH slice 1 (no LLM, no live API).
class DigestClassifier {
  const DigestClassifier({
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  static const Set<String> _socialSenderDomains = <String>{
    'linkedin.com',
    'facebook.com',
    'instagram.com',
    'nextdoor.com',
    'twitter.com',
    'x.com',
  };

  DigestClassification classify(DigestMessage message) {
    final DigestBucket bucket = _exclusiveBucket(message);
    final DigestMoneyConfidence money = _moneyConfidence(message);
    return DigestClassification(bucket: bucket, moneyConfidence: money);
  }

  DigestBucket _exclusiveBucket(DigestMessage message) {
    final bool onToOrCc = _userOnToOrCc(message);
    if (onToOrCc && _isUrgent(message)) {
      return DigestBucket.urgent;
    }
    if (onToOrCc && !_isListMail(message)) {
      return DigestBucket.personalNonUrgent;
    }
    if (_isNewsletter(message)) {
      return DigestBucket.newsletters;
    }
    if (_isSocial(message)) {
      return DigestBucket.social;
    }
    return DigestBucket.other;
  }

  DigestMoneyConfidence _moneyConfidence(DigestMessage message) {
    final String haystack =
        '${message.subject}\n${message.snippet}'.toLowerCase();
    const List<String> highSignals = <String>[
      'receipt',
      'invoice',
      'order confirmation',
      'your order',
      'billed',
      'subscription renewed',
      'trial ends',
      'upcoming charge',
    ];
    for (final String signal in highSignals) {
      if (haystack.contains(signal)) {
        return DigestMoneyConfidence.high;
      }
    }
    const List<String> maybeSignals = <String>[
      'payment',
      'renewal',
      'statement',
      'purchase',
    ];
    for (final String signal in maybeSignals) {
      if (haystack.contains(signal)) {
        return DigestMoneyConfidence.maybe;
      }
    }
    final String? category = message.gmailCategory?.toLowerCase();
    if (category == 'purchases') {
      return DigestMoneyConfidence.high;
    }
    return DigestMoneyConfidence.none;
  }

  bool _userOnToOrCc(DigestMessage message) {
    final String needle = message.accountAddress.trim().toLowerCase();
    if (needle.isEmpty) {
      return false;
    }
    for (final String address in <String>[
      ...message.toAddresses,
      ...message.ccAddresses,
    ]) {
      if (_normalizeAddress(address) == needle) {
        return true;
      }
    }
    return false;
  }

  String _normalizeAddress(String raw) {
    final String trimmed = raw.trim().toLowerCase();
    final int start = trimmed.indexOf('<');
    final int end = trimmed.indexOf('>');
    if (start != -1 && end > start) {
      return trimmed.substring(start + 1, end);
    }
    return trimmed;
  }

  bool _isUrgent(DigestMessage message) {
    final String haystack =
        '${message.subject}\n${message.snippet}'.toLowerCase();
    if (_looksLikePlainReceipt(haystack) && !_looksLikeDunning(haystack)) {
      return false;
    }
    const List<String> urgentSignals = <String>[
      'action required',
      'please review',
      'security alert',
      'unusual sign-in',
      'verify your account',
      'password reset',
      'payment failed',
      'past due',
      'service will be suspended',
      'cutoff',
      'rsvp',
      'signature required',
      'respond by',
      'deadline',
    ];
    for (final String signal in urgentSignals) {
      if (haystack.contains(signal)) {
        return true;
      }
    }
    return _hasNearTermDeadline(haystack);
  }

  bool _looksLikePlainReceipt(String haystack) {
    return haystack.contains('receipt') ||
        haystack.contains('invoice') ||
        haystack.contains('order confirmation');
  }

  bool _looksLikeDunning(String haystack) {
    return haystack.contains('past due') ||
        haystack.contains('payment failed') ||
        haystack.contains('cutoff') ||
        haystack.contains('service will be suspended');
  }

  bool _hasNearTermDeadline(String haystack) {
    if (!haystack.contains('by ') && !haystack.contains('before ')) {
      return false;
    }
    final DateTime now = _now();
    final RegExp isoDate = RegExp(r'\b20\d{2}-\d{2}-\d{2}\b');
    for (final RegExpMatch match in isoDate.allMatches(haystack)) {
      final DateTime? parsed = DateTime.tryParse(match.group(0)!);
      if (parsed == null) {
        continue;
      }
      if (!parsed.isBefore(now) &&
          parsed.difference(now).inDays <= 14) {
        return true;
      }
    }
    return false;
  }

  bool _isListMail(DigestMessage message) {
    return _isNewsletter(message);
  }

  bool _isNewsletter(DigestMessage message) {
    if (message.listUnsubscribe != null &&
        message.listUnsubscribe!.trim().isNotEmpty) {
      return true;
    }
    if (message.listId != null && message.listId!.trim().isNotEmpty) {
      return true;
    }
    final String? precedence = message.precedence?.toLowerCase();
    if (precedence == 'list' || precedence == 'bulk') {
      return true;
    }
    final String? category = message.gmailCategory?.toLowerCase();
    return category == 'promotions';
  }

  bool _isSocial(DigestMessage message) {
    final String? category = message.gmailCategory?.toLowerCase();
    if (category == 'social') {
      return true;
    }
    final String domain = _senderDomain(message.fromAddress);
    return _socialSenderDomains.contains(domain);
  }

  String _senderDomain(String address) {
    final String normalized = _normalizeAddress(address);
    final int at = normalized.lastIndexOf('@');
    if (at == -1 || at == normalized.length - 1) {
      return normalized;
    }
    return normalized.substring(at + 1);
  }
}
