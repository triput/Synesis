// ==============================================================================
// File: lib/focus/focus_sender.dart
// Description: Normalize sender addresses for Focus override rule keys.
// Component: Domain / Focus
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

/// Lower-cases and unwraps `Name <addr@host>` forms for Focus sender rules.
String normalizeFocusSender(String address) {
  final Match? bracketed =
      RegExp(r'<\s*([^>\s]+@[^>\s]+)\s*>').firstMatch(address);
  return (bracketed?.group(1) ?? address).trim().toLowerCase();
}

/// Domain portion of [address], or null when missing/`@` malformed.
String? domainFromFocusSender(String address) {
  final String sender = normalizeFocusSender(address);
  final int at = sender.lastIndexOf('@');
  if (at <= 0 || at == sender.length - 1) {
    return null;
  }
  return sender.substring(at + 1);
}

/// Stable primary key for a per-account sender Focus override.
String focusSenderRuleId({
  required String accountId,
  required String sender,
}) {
  return 'sender:$accountId:${normalizeFocusSender(sender)}';
}

/// Stable primary key for a per-account domain Focus override.
String focusDomainRuleId({
  required String accountId,
  required String domain,
}) {
  return 'domain:$accountId:${domain.trim().toLowerCase().replaceFirst(RegExp(r'^@'), '')}';
}
