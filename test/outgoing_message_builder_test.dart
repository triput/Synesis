// ==============================================================================
// File: test/outgoing_message_builder_test.dart
// Description: OutgoingMessageBuilder pack/quote merge tests (DEF-087 W2b).
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'package:synesis/compose/outgoing_message_builder.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutgoingMessageBuilder.packComposeWithQuote', () {
    test('merges user text with HTML quote block', () {
      const String quoteHtml =
          '<blockquote><div>On Alice wrote:</div><p>Hi</p></blockquote>';
      const String quotePlain = 'On Alice wrote:\n> Hi';
      final String packed = OutgoingMessageBuilder.packComposeWithQuote(
        userPlain: 'Thanks!',
        userHtml: '<div>Thanks!</div>',
        quotedHtml: quoteHtml,
        quotedPlain: quotePlain,
      );
      expect(packed, contains('Thanks!'));
      expect(packed, contains('On Alice wrote:'));
      expect(packed, contains('---synesis-html---'));
      expect(
        packed.substring(packed.indexOf('---synesis-html---')),
        contains('<blockquote>'),
      );
    });

    test('quote-only when user body empty', () {
      const String quoteHtml = '<blockquote><p>Original</p></blockquote>';
      final String packed = OutgoingMessageBuilder.packComposeWithQuote(
        userPlain: '',
        userHtml: '<div></div>',
        quotedHtml: quoteHtml,
      );
      expect(packed, contains('Original'));
      expect(packed, contains('<blockquote>'));
    });
  });
}
