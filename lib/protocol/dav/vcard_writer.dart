// ==============================================================================
// File: lib/protocol/dav/vcard_writer.dart
// Description: Minimal RFC 6350 vCard serializer for CardDAV create (Wave 6b).
// Component: Protocol / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-08-04
// Last Update: 2026-08-04
// ==============================================================================

import 'package:synesis/domain/pim.dart';

/// Builds a vCard 3.0 body for CardDAV PUT create.
///
/// Field set matches Wave 6 copy push (names, company, notes, emails, phones).
class VCardWriter {
  const VCardWriter();

  /// Serializes [contact] plus [emails]/[phones] with [uid].
  String writeContact({
    required Contact contact,
    required String uid,
    List<ContactEmail> emails = const <ContactEmail>[],
    List<ContactPhone> phones = const <ContactPhone>[],
  }) {
    final String displayName = _nonEmpty(contact.displayName) ?? '(No name)';
    final List<String> lines = <String>[
      'BEGIN:VCARD',
      'VERSION:3.0',
      'UID:$uid',
      'FN:${_escapeText(displayName)}',
      'N:${_escapeText(_nonEmpty(contact.familyName) ?? '')};'
          '${_escapeText(_nonEmpty(contact.givenName) ?? '')};;;',
    ];
    final String? company = _nonEmpty(contact.company);
    if (company != null) {
      lines.add('ORG:${_escapeText(company)}');
    }
    final String? notes = _nonEmpty(contact.notes);
    if (notes != null) {
      lines.add('NOTE:${_escapeText(notes)}');
    }
    for (final ContactEmail email in emails) {
      final String address = email.address.trim();
      if (address.isEmpty) {
        continue;
      }
      final String? type = _emailType(email.type);
      if (type == null) {
        lines.add('EMAIL:${_escapeText(address)}');
      } else {
        lines.add('EMAIL;TYPE=$type:${_escapeText(address)}');
      }
    }
    for (final ContactPhone phone in phones) {
      final String number = phone.number.trim();
      if (number.isEmpty) {
        continue;
      }
      final String? type = _phoneType(phone.type);
      if (type == null) {
        lines.add('TEL:${_escapeText(number)}');
      } else {
        lines.add('TEL;TYPE=$type:${_escapeText(number)}');
      }
    }
    lines.add('END:VCARD');
    return '${lines.map(_foldLine).join('\r\n')}\r\n';
  }

  static String? _emailType(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'home':
        return 'HOME';
      case 'work':
      case 'business':
        return 'WORK';
      default:
        return null;
    }
  }

  static String? _phoneType(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'mobile':
      case 'cell':
        return 'CELL';
      case 'home':
        return 'HOME';
      case 'work':
      case 'business':
        return 'WORK';
      default:
        return null;
    }
  }

  static String _escapeText(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\n')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;');
  }

  static String _foldLine(String line) {
    if (line.length <= 75) {
      return line;
    }
    final StringBuffer buffer = StringBuffer(line.substring(0, 75));
    int index = 75;
    while (index < line.length) {
      final int end = index + 74 > line.length ? line.length : index + 74;
      buffer
        ..write('\r\n ')
        ..write(line.substring(index, end));
      index = end;
    }
    return buffer.toString();
  }

  static String? _nonEmpty(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
