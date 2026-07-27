// ==============================================================================
// File: lib/account/account_display.dart
// Description: Display-name seeding and monogram helpers for account identity
// Component: Domain / UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:synesis/domain/models.dart';

/// Wave 0 (A+B): [MailAccount.label] is a user-editable display name, seeded
/// from the address when the operator leaves the field blank.
abstract final class AccountDisplay {
  /// Seeds a multi-character display name from [address] (not a single letter).
  ///
  /// Prefers the email local-part when short; otherwise the domain host; falls
  /// back to a truncated local-part. Never returns an empty string.
  static String seedFromAddress(String address) {
    final String trimmed = address.trim();
    if (trimmed.isEmpty) {
      return 'Account';
    }
    final int at = trimmed.indexOf('@');
    final String local = at > 0 ? trimmed.substring(0, at).trim() : trimmed;
    final String domain = at > 0 && at < trimmed.length - 1
        ? trimmed.substring(at + 1).trim()
        : '';
    if (local.isNotEmpty && local.length <= 18) {
      return local;
    }
    if (domain.isNotEmpty) {
      final String host = domain.split('.').first.trim();
      if (host.isNotEmpty) {
        return host;
      }
      return domain.length <= 18 ? domain : '${domain.substring(0, 16)}…';
    }
    if (local.isNotEmpty) {
      return local.length <= 18 ? local : '${local.substring(0, 16)}…';
    }
    return 'Account';
  }

  /// Resolves the primary label shown in rails/chips (display name or seed).
  static String primaryLabel(MailAccount account) {
    final String label = account.label.trim();
    if (label.isNotEmpty) {
      return label;
    }
    return seedFromAddress(account.address);
  }

  /// Full address for secondary text / tooltips.
  static String secondaryLabel(MailAccount account) => account.address.trim();

  /// 1–2 character monogram for compact badges (from display name / seed).
  static String monogram(MailAccount account) {
    final String source = primaryLabel(account);
    final List<String> parts = source
        .split(RegExp(r'[\s._\-@]+'))
        .where((String p) => p.isNotEmpty)
        .toList(growable: false);
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final String token = parts.first;
      if (token.length == 1) {
        return token.toUpperCase();
      }
      return token.substring(0, 2).toUpperCase();
    }
    final String a = parts[0].substring(0, 1);
    final String b = parts[1].substring(0, 1);
    return '$a$b'.toUpperCase();
  }
}
