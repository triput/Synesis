// ==============================================================================
// File: lib/outbox/outbox_recipients.dart
// Description: Parse typed/stored outbox recipient fields into bare addresses
// Component: Outbox / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

/// Parses a comma/semicolon-separated RFC-ish address list into bare emails.
List<String> parseAddressList(String value) {
  final List<String> results = <String>[];
  final List<String> parts = _splitAddressList(value);
  for (final String part in parts) {
    final String? address = _extractEmail(part);
    if (address != null) {
      results.add(address);
    }
  }
  return results;
}

/// Splits a typed or stored outbox recipient field into bare addresses.
///
/// Accepts comma/semicolon lists and legacy JSON arrays of address strings.
List<String> splitOutboxRecipients(String? value) {
  if (value == null) {
    return const <String>[];
  }
  final String trimmed = value.trim();
  if (trimmed.isEmpty) {
    return const <String>[];
  }
  if (trimmed.startsWith('[')) {
    try {
      final Object? decoded = jsonDecode(trimmed);
      if (decoded is List) {
        final List<String> fromJson = <String>[];
        for (final Object? entry in decoded) {
          final String piece = entry?.toString().trim() ?? '';
          if (piece.isEmpty) {
            continue;
          }
          fromJson.addAll(parseAddressList(piece));
        }
        return fromJson;
      }
    } on FormatException {
      // Fall through to plain parsing.
    }
  }
  return parseAddressList(trimmed);
}

List<String> _splitAddressList(String value) {
  final List<String> parts = <String>[];
  final StringBuffer current = StringBuffer();
  int depth = 0;
  bool inQuotes = false;
  for (int i = 0; i < value.length; i++) {
    final String ch = value[i];
    if (ch == '"') {
      inQuotes = !inQuotes;
      current.write(ch);
      continue;
    }
    if (!inQuotes) {
      if (ch == '<') {
        depth++;
      } else if (ch == '>' && depth > 0) {
        depth--;
      } else if ((ch == ',' || ch == ';') && depth == 0) {
        final String piece = current.toString().trim();
        if (piece.isNotEmpty) {
          parts.add(piece);
        }
        current.clear();
        continue;
      }
    }
    current.write(ch);
  }
  final String trailing = current.toString().trim();
  if (trailing.isNotEmpty) {
    parts.add(trailing);
  }
  return parts;
}

String? _extractEmail(String part) {
  final String trimmed = part.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final Match? angle = RegExp(r'<([^<>\s@]+@[^<>\s@]+)>').firstMatch(trimmed);
  if (angle != null) {
    return angle.group(1)!.trim();
  }
  final Match? bare = RegExp(r'([^\s,;<>"]+@[^\s,;<>"]+)').firstMatch(trimmed);
  return bare?.group(1)?.trim();
}
