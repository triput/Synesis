// ==============================================================================
// File: test/account_display_test.dart
// Description: Wave 0 account display-name seed and monogram coverage
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/account/account_display.dart';
import 'package:synesis/domain/models.dart';

void main() {
  group('AccountDisplay.seedFromAddress', () {
    test('uses local-part when short', () {
      expect(
        AccountDisplay.seedFromAddress('trish@example.com'),
        'trish',
      );
    });

    test('falls back to domain host when local-part is long', () {
      expect(
        AccountDisplay.seedFromAddress(
          'very.long.local.part.name@contoso.com',
        ),
        'contoso',
      );
    });

    test('does not force a single character', () {
      final String seed = AccountDisplay.seedFromAddress('work@acme.io');
      expect(seed.length, greaterThan(1));
      expect(seed, 'work');
    });
  });

  group('AccountDisplay monogram and primary', () {
    MailAccount account({
      required String label,
      String address = 'a@b.com',
    }) {
      return MailAccount(
        id: '1',
        label: label,
        address: address,
        accent: const Color(0xFF2DD4BF),
      );
    }

    test('primaryLabel prefers stored display name', () {
      expect(
        AccountDisplay.primaryLabel(account(label: 'Home')),
        'Home',
      );
    });

    test('primaryLabel seeds when label empty', () {
      expect(
        AccountDisplay.primaryLabel(account(label: '', address: 'me@x.com')),
        'me',
      );
    });

    test('monogram uses two letters from multi-word name', () {
      expect(
        AccountDisplay.monogram(account(label: 'Work Mail')),
        'WM',
      );
    });

    test('monogram keeps legacy single-letter labels', () {
      expect(AccountDisplay.monogram(account(label: 'T')), 'T');
    });

    test('monogram takes two chars from single token', () {
      expect(AccountDisplay.monogram(account(label: 'trish')), 'TR');
    });
  });
}
