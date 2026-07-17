// ==============================================================================
// File: lib/protocol/mail_date_parser.dart
// Description: Tolerant RFC5322 / asctime / UTC mail Date header parsing.
// Component: Protocol
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:io';

/// Parses common email `Date:` header forms without relying on enough_mail's
/// strict decoder (which `print`s on asctime/`UTC` dates and returns null).
DateTime? parseMailDate(String? raw) {
  if (raw == null) {
    return null;
  }
  final String text = raw.trim();
  if (text.isEmpty) {
    return null;
  }

  final DateTime? iso = DateTime.tryParse(text);
  if (iso != null) {
    return iso;
  }

  try {
    return HttpDate.parse(text);
  } on Object {
    // Not an HTTP-date; try mail-specific forms below.
  }

  final DateTime? asctime = _parseAsctimeUtc(text);
  if (asctime != null) {
    return asctime;
  }

  final DateTime? rfc5322 = _parseRfc5322Loose(text);
  if (rfc5322 != null) {
    return rfc5322;
  }

  return null;
}

/// `Tue Aug 20 15:10:06 UTC 2019` / `Aug 20 15:10:06 GMT 2019`
DateTime? _parseAsctimeUtc(String text) {
  final Match? match = RegExp(
    r'^(?:(?:Mon|Tue|Wed|Thu|Fri|Sat|Sun)\s+)?'
    r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+'
    r'(\d{1,2})\s+'
    r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s+'
    r'(?:UTC|GMT|UT)\s+'
    r'(\d{4})\s*$',
    caseSensitive: false,
  ).firstMatch(text);
  if (match == null) {
    return null;
  }
  final int? month = _monthIndex(match.group(1)!);
  final int? day = int.tryParse(match.group(2)!);
  final int? hour = int.tryParse(match.group(3)!);
  final int? minute = int.tryParse(match.group(4)!);
  final int second = int.tryParse(match.group(5) ?? '0') ?? 0;
  final int? year = int.tryParse(match.group(6)!);
  if (month == null ||
      day == null ||
      hour == null ||
      minute == null ||
      year == null) {
    return null;
  }
  return DateTime.utc(year, month, day, hour, minute, second);
}

/// Loose RFC 5322: `Tue, 20 Aug 2019 15:10:06 +0000` / `-0000` / `UT`
DateTime? _parseRfc5322Loose(String text) {
  String reminder = text;
  final int comma = reminder.indexOf(',');
  if (comma != -1) {
    reminder = reminder.substring(comma + 1).trim();
  }

  final Match? match = RegExp(
    r'^(\d{1,2})\s+'
    r'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+'
    r'(\d{2,4})\s+'
    r'(\d{1,2}):(\d{2})(?::(\d{2}))?\s*'
    r'(?:'
    r'([+-]\d{4})|'
    r'(UTC|GMT|UT)'
    r')?\s*$',
    caseSensitive: false,
  ).firstMatch(reminder);
  if (match == null) {
    return null;
  }

  final int? day = int.tryParse(match.group(1)!);
  final int? month = _monthIndex(match.group(2)!);
  int? year = int.tryParse(match.group(3)!);
  final int? hour = int.tryParse(match.group(4)!);
  final int? minute = int.tryParse(match.group(5)!);
  final int second = int.tryParse(match.group(6) ?? '0') ?? 0;
  if (day == null ||
      month == null ||
      year == null ||
      hour == null ||
      minute == null) {
    return null;
  }
  if (year < 100) {
    year += 2000;
  }

  final String? numericZone = match.group(7);
  final String? namedZone = match.group(8);
  if (numericZone != null && numericZone.length == 5) {
    final int sign = numericZone.startsWith('-') ? -1 : 1;
    final int? zh = int.tryParse(numericZone.substring(1, 3));
    final int? zm = int.tryParse(numericZone.substring(3, 5));
    if (zh == null || zm == null) {
      return null;
    }
    final DateTime localish = DateTime.utc(year, month, day, hour, minute, second);
    return localish.subtract(Duration(minutes: sign * (zh * 60 + zm)));
  }
  if (namedZone != null || numericZone == null) {
    return DateTime.utc(year, month, day, hour, minute, second);
  }
  return null;
}

int? _monthIndex(String name) {
  const Map<String, int> months = <String, int>{
    'jan': 1,
    'feb': 2,
    'mar': 3,
    'apr': 4,
    'may': 5,
    'jun': 6,
    'jul': 7,
    'aug': 8,
    'sep': 9,
    'oct': 10,
    'nov': 11,
    'dec': 12,
  };
  return months[name.toLowerCase()];
}
