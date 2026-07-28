// ==============================================================================
// File: test/contact_picker_test.dart
// Description: Unit tests for compose contact-picker recipient formatting.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/ui/compose/contact_picker.dart';

Contact _contact({
  String id = 'c1',
  String displayName = 'Maya Chen',
  String? company,
}) {
  return Contact(
    id: id,
    accountId: 'work',
    contactListId: 'list1',
    providerId: 'p1',
    displayName: displayName,
    updatedAt: 0,
    company: company,
  );
}

void main() {
  group('formatContactRecipient', () {
    test('formats "Display Name <email>" when both are present', () {
      final ContactSearchHit hit = ContactSearchHit(
        contact: _contact(),
        displayName: 'Maya Chen',
        email: 'maya@byte.io',
      );
      expect(formatContactRecipient(hit), 'Maya Chen <maya@byte.io>');
    });

    test('returns bare email when display name is empty', () {
      final ContactSearchHit hit = ContactSearchHit(
        contact: _contact(displayName: ''),
        displayName: '',
        email: 'maya@byte.io',
      );
      expect(formatContactRecipient(hit), 'maya@byte.io');
    });

    test('returns null when the hit has no email', () {
      final ContactSearchHit hit = ContactSearchHit(
        contact: _contact(),
        displayName: 'Maya Chen',
      );
      expect(formatContactRecipient(hit), isNull);
    });

    test('quotes a display name containing a comma', () {
      final ContactSearchHit hit = ContactSearchHit(
        contact: _contact(displayName: 'Chen, Maya'),
        displayName: 'Chen, Maya',
        email: 'maya@byte.io',
      );
      expect(
        formatContactRecipient(hit),
        '"Chen, Maya" <maya@byte.io>',
      );
    });

    test('escapes an embedded quote in the display name', () {
      final ContactSearchHit hit = ContactSearchHit(
        contact: _contact(displayName: 'Maya "M" Chen'),
        displayName: 'Maya "M" Chen',
        email: 'maya@byte.io',
      );
      expect(
        formatContactRecipient(hit),
        '"Maya \\"M\\" Chen" <maya@byte.io>',
      );
    });
  });

  group('currentRecipientToken', () {
    test('returns the whole string when there is no comma', () {
      expect(currentRecipientToken('may'), 'may');
    });

    test('returns text after the last comma, trimmed', () {
      expect(
        currentRecipientToken('alice@byte.io, may'),
        'may',
      );
    });

    test('returns empty string right after a trailing comma', () {
      expect(currentRecipientToken('alice@byte.io, '), '');
    });
  });

  group('insertContactIntoField', () {
    test('inserts a single recipient with a trailing separator', () {
      final ContactSearchHit hit = ContactSearchHit(
        contact: _contact(),
        displayName: 'Maya Chen',
        email: 'maya@byte.io',
      );
      expect(
        insertContactIntoField('may', hit),
        'Maya Chen <maya@byte.io>, ',
      );
    });

    test('preserves already-entered recipients before the token', () {
      final ContactSearchHit hit = ContactSearchHit(
        contact: _contact(),
        displayName: 'Maya Chen',
        email: 'maya@byte.io',
      );
      expect(
        insertContactIntoField('alice@byte.io, may', hit),
        'alice@byte.io, Maya Chen <maya@byte.io>, ',
      );
    });

    test('returns null and leaves the field alone when there is no email', () {
      final ContactSearchHit hit = ContactSearchHit(
        contact: _contact(),
        displayName: 'Maya Chen',
      );
      expect(insertContactIntoField('may', hit), isNull);
    });
  });
}
