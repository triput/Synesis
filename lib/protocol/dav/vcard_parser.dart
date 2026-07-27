// ==============================================================================
// File: lib/protocol/dav/vcard_parser.dart
// Description: Minimal RFC 6350 vCard parser for CardDAV contact sync.
// Component: Protocol / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

class DavVCard {
  const DavVCard({
    required this.displayName,
    this.uid,
    this.givenName,
    this.familyName,
    this.revision,
    this.emails = const <DavVCardValue>[],
    this.phones = const <DavVCardValue>[],
  });

  final String displayName;
  final String? uid;
  final String? givenName;
  final String? familyName;
  final String? revision;
  final List<DavVCardValue> emails;
  final List<DavVCardValue> phones;
}

class DavVCardValue {
  const DavVCardValue({required this.value, this.type = 'other'});

  final String value;
  final String type;
}

class VCardParser {
  const VCardParser();

  DavVCard? parse(String source) {
    String? fn;
    String? uid;
    String? given;
    String? family;
    String? revision;
    final List<DavVCardValue> emails = <DavVCardValue>[];
    final List<DavVCardValue> phones = <DavVCardValue>[];
    for (final String line in _unfold(source)) {
      final int separator = line.indexOf(':');
      if (separator < 1) {
        continue;
      }
      final List<String> parts = line.substring(0, separator).split(';');
      final String name = parts.first.toUpperCase();
      final String value = _unescape(line.substring(separator + 1)).trim();
      if (value.isEmpty) {
        continue;
      }
      final String type = _type(parts.skip(1));
      switch (name) {
        case 'FN':
          fn = value;
        case 'UID':
          uid = value;
        case 'N':
          final List<String> names = value.split(';');
          family = _nonEmpty(names.isEmpty ? null : names.first);
          given = _nonEmpty(names.length < 2 ? null : names[1]);
        case 'REV':
          revision = value;
        case 'EMAIL':
          emails.add(DavVCardValue(value: value, type: type));
        case 'TEL':
          phones.add(DavVCardValue(value: value, type: type));
      }
    }
    final String name =
        _nonEmpty(fn) ??
        <String?>[given, family].whereType<String>().join(' ').trim();
    if (name.isEmpty && uid == null && emails.isEmpty && phones.isEmpty) {
      return null;
    }
    return DavVCard(
      displayName: name.isEmpty ? '(No name)' : name,
      uid: _nonEmpty(uid),
      givenName: _nonEmpty(given),
      familyName: _nonEmpty(family),
      revision: _nonEmpty(revision),
      emails: List<DavVCardValue>.unmodifiable(emails),
      phones: List<DavVCardValue>.unmodifiable(phones),
    );
  }

  static List<String> _unfold(String source) {
    final List<String> result = <String>[];
    for (final String line in source.replaceAll('\r\n', '\n').split('\n')) {
      if ((line.startsWith(' ') || line.startsWith('\t')) &&
          result.isNotEmpty) {
        result[result.length - 1] = '${result.last}${line.substring(1)}';
      } else {
        result.add(line);
      }
    }
    return result;
  }

  static String _type(Iterable<String> parameters) {
    for (final String parameter in parameters) {
      final String upper = parameter.toUpperCase();
      if (upper.startsWith('TYPE=')) {
        return upper.substring(5).split(',').first.toLowerCase();
      }
    }
    return 'other';
  }

  static String _unescape(String value) => value
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\N', '\n')
      .replaceAll(r'\,', ',')
      .replaceAll(r'\;', ';')
      .replaceAll(r'\\', r'\');

  static String? _nonEmpty(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
