// ==============================================================================
// File: test/template_placeholders_test.dart
// Description: Unit tests for D6-4 `{{token}}` template placeholder expansion
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-07-23
// ==============================================================================

import 'package:synesis/compose/template_placeholders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final DateTime fixedDate = DateTime(2026, 7, 23);

  TemplateVarContext contextWith({
    String? recipientName,
    String? recipientEmail,
    String fromName = 'Jules Bot',
    String fromEmail = 'jules@synesis.test',
    String subject = 'Hello there',
  }) {
    return TemplateVarContext(
      recipientName: recipientName,
      recipientEmail: recipientEmail,
      fromName: fromName,
      fromEmail: fromEmail,
      subject: subject,
      date: fixedDate,
    );
  }

  group('expandTemplatePlaceholders', () {
    test('expands {{name}} from an explicit recipient name', () {
      final String result = expandTemplatePlaceholders(
        'Hi {{name}},',
        contextWith(recipientName: 'Jane Doe', recipientEmail: 'jane@x.com'),
      );
      expect(result, 'Hi Jane Doe,');
    });

    test('{{name}} falls back to the email local-part when name is missing', () {
      final String result = expandTemplatePlaceholders(
        'Hi {{name}},',
        contextWith(recipientEmail: 'jane.doe@x.com'),
      );
      expect(result, 'Hi jane.doe,');
    });

    test('{{first_name}} resolves the first word of the resolved name', () {
      final String result = expandTemplatePlaceholders(
        'Hi {{first_name}}!',
        contextWith(recipientName: 'Jane Doe', recipientEmail: 'jane@x.com'),
      );
      expect(result, 'Hi Jane!');
    });

    test('{{first_name}} falls back to local-part when no name at all', () {
      final String result = expandTemplatePlaceholders(
        'Hi {{first_name}}!',
        contextWith(recipientEmail: 'jane@x.com'),
      );
      expect(result, 'Hi jane!');
    });

    test('{{email}} substitutes the recipient email', () {
      final String result = expandTemplatePlaceholders(
        'Reach me back at {{email}}',
        contextWith(recipientEmail: 'jane@x.com'),
      );
      expect(result, 'Reach me back at jane@x.com');
    });

    test('{{from_name}} and {{from_email}} substitute the sender', () {
      final String result = expandTemplatePlaceholders(
        '{{from_name}} <{{from_email}}>',
        contextWith(fromName: 'Support', fromEmail: 'support@synesis.test'),
      );
      expect(result, 'Support <support@synesis.test>');
    });

    test('{{subject}} substitutes the current subject field', () {
      final String result = expandTemplatePlaceholders(
        'Re: {{subject}}',
        contextWith(subject: 'Q3 Planning'),
      );
      expect(result, 'Re: Q3 Planning');
    });

    test('{{date}} substitutes a human-readable date', () {
      final String result = expandTemplatePlaceholders(
        'Sent on {{date}}',
        contextWith(),
      );
      expect(result, 'Sent on Jul 23, 2026');
    });

    test('unknown tokens are left unchanged', () {
      final String result = expandTemplatePlaceholders(
        'Value: {{totally_unknown}}',
        contextWith(),
      );
      expect(result, 'Value: {{totally_unknown}}');
    });

    test('known tokens with no resolvable value are left unchanged', () {
      final String result = expandTemplatePlaceholders(
        'Hi {{name}}, email {{email}}',
        contextWith(),
      );
      expect(result, 'Hi {{name}}, email {{email}}');
    });

    test('tokens are case-insensitive and tolerate inner whitespace', () {
      final String result = expandTemplatePlaceholders(
        'Hi {{ NAME }}',
        contextWith(recipientName: 'Jane'),
      );
      expect(result, 'Hi Jane');
    });

    test('expands multiple distinct tokens in one pass', () {
      final String result = expandTemplatePlaceholders(
        '{{name}} - {{from_name}} - {{subject}} - {{date}}',
        contextWith(
          recipientName: 'Jane',
          recipientEmail: 'jane@x.com',
          fromName: 'Bot',
          subject: 'Ping',
        ),
      );
      expect(result, 'Jane - Bot - Ping - Jul 23, 2026');
    });

    test('empty text returns empty text', () {
      expect(expandTemplatePlaceholders('', contextWith()), '');
    });
  });
}
