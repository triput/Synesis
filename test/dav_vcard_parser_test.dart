// ==============================================================================
// File: test/dav_vcard_parser_test.dart
// Description: Unit coverage for minimal CardDAV vCard mapping.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/protocol/dav/vcard_parser.dart';

void main() {
  test('parses folded vCard names, UID, email and phone values', () {
    const VCardParser parser = VCardParser();
    final DavVCard? card = parser.parse('''
BEGIN:VCARD
VERSION:4.0
UID:urn:uuid:ada
FN:Ada Lovelace
N:Lovelace;Ada;;;
EMAIL;TYPE=work:ada@example.com
TEL;TYPE=cell:+1-555-0100
REV:2026-07-27T12:00:00Z
END:VCARD
''');

    expect(card, isNotNull);
    expect(card!.displayName, 'Ada Lovelace');
    expect(card.uid, 'urn:uuid:ada');
    expect(card.givenName, 'Ada');
    expect(card.familyName, 'Lovelace');
    expect(card.emails.single.value, 'ada@example.com');
    expect(card.emails.single.type, 'work');
    expect(card.phones.single.type, 'cell');
  });
}
