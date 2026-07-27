// ==============================================================================
// File: lib/compose/template_placeholders.dart
// Description: Pure `{{token}}` expansion for mail template subject/body text
// Component: Compose / Util
// Version: 1.0 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-07-23
// ==============================================================================

/// Resolved values available for `{{token}}` substitution in a mail template
/// (D6-4). All fields describe the *first* To recipient and the sending
/// account; other recipients are intentionally out of scope.
class TemplateVarContext {
  const TemplateVarContext({
    this.recipientName,
    this.recipientEmail,
    required this.fromName,
    required this.fromEmail,
    required this.subject,
    required this.date,
  });

  /// Display name of the first To recipient, if known.
  final String? recipientName;

  /// Bare email address of the first To recipient, if known.
  final String? recipientEmail;

  /// Sending account's display name.
  final String fromName;

  /// Sending account's email address.
  final String fromEmail;

  /// Current subject field value at expansion time.
  final String subject;

  /// Date substituted for `{{date}}`.
  final DateTime date;
}

const List<String> _kMonthAbbreviations = <String>[
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

/// Formats [date] as `Mon D, YYYY` (e.g. `Jul 23, 2026`) without depending on
/// the `intl` package, which is not a project dependency.
String formatTemplateDate(DateTime date) {
  final String month = _kMonthAbbreviations[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}

final RegExp _placeholderToken = RegExp(r'\{\{\s*([a-zA-Z_]+)\s*\}\}');

/// Local-part of [email] (before `@`), or the whole string when there is no
/// `@` to split on.
String _localPartOf(String email) {
  final int at = email.indexOf('@');
  return at > 0 ? email.substring(0, at) : email;
}

/// Resolves the effective recipient display name: [TemplateVarContext.recipientName]
/// when present, otherwise the local-part of [TemplateVarContext.recipientEmail],
/// otherwise null when neither is known.
String? _resolvedRecipientName(TemplateVarContext context) {
  final String? name = context.recipientName?.trim();
  if (name != null && name.isNotEmpty) {
    return name;
  }
  final String? email = context.recipientEmail?.trim();
  if (email != null && email.isNotEmpty) {
    return _localPartOf(email);
  }
  return null;
}

/// First whitespace-delimited word of [name], or [name] itself when it has
/// no internal whitespace.
String _firstWordOf(String name) {
  final int spaceIndex = name.indexOf(RegExp(r'\s'));
  return spaceIndex == -1 ? name : name.substring(0, spaceIndex);
}

/// Expands `{{token}}` placeholders in [text] using [context].
///
/// Supported tokens (case-insensitive): `{{name}}` (recipient full/display
/// name, falling back to the email local-part), `{{first_name}}` (first word
/// of the resolved name), `{{email}}` (recipient email), `{{from_name}}`,
/// `{{from_email}}`, `{{subject}}`, and `{{date}}`. Unknown tokens — or known
/// tokens whose value cannot be resolved (e.g. no recipient at all) — are
/// left unchanged in the output.
String expandTemplatePlaceholders(String text, TemplateVarContext context) {
  if (text.isEmpty) {
    return text;
  }
  return text.replaceAllMapped(_placeholderToken, (Match match) {
    final String raw = match.group(0)!;
    final String token = match.group(1)!.toLowerCase();
    switch (token) {
      case 'name':
        return _resolvedRecipientName(context) ?? raw;
      case 'first_name':
        final String? name = _resolvedRecipientName(context);
        return name == null ? raw : _firstWordOf(name);
      case 'email':
        final String? email = context.recipientEmail?.trim();
        return (email == null || email.isEmpty) ? raw : email;
      case 'from_name':
        return context.fromName.trim().isEmpty ? raw : context.fromName;
      case 'from_email':
        return context.fromEmail.trim().isEmpty ? raw : context.fromEmail;
      case 'subject':
        return context.subject;
      case 'date':
        return formatTemplateDate(context.date);
      default:
        return raw;
    }
  });
}
