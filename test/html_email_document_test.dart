// ==============================================================================
// File: test/html_email_document_test.dart
// Description: Unit tests for HTML email document wrapper CSS contract.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-12
// Last Update: 2026-08-12
// ==============================================================================

import 'package:synesis/ui/shell/html_email_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('wrapHtmlEmailDocument', () {
    test('uses overflow-x auto on html and body', () {
      final String doc = wrapHtmlEmailDocument('<p>Hello</p>');

      expect(doc, contains('overflow-x: auto'));
      expect(doc, isNot(contains('overflow-x: hidden')));
    });

    test('keeps max-width scale-to-fit for images and tables', () {
      final String doc = wrapHtmlEmailDocument('<img src="x.png">');

      expect(doc, contains('img, table { max-width: 100%; }'));
      expect(doc, contains('img { height: auto; }'));
    });

    test('preserves vertical scroll on html and body', () {
      final String doc = wrapHtmlEmailDocument('<p>Tall</p>');

      expect(doc, contains('overflow-y: auto'));
    });
  });
}
