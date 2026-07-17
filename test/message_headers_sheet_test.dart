import 'package:bytemail/ui/shell/message_headers_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseRawHeaderValue', () {
    test('returns null when raw block is missing', () {
      expect(parseRawHeaderValue(null, 'to'), isNull);
      expect(parseRawHeaderValue('   ', 'to'), isNull);
    });

    test('extracts header case-insensitively', () {
      const String raw = 'FROM: Alice <a@byte.io>\nTO: Bob <b@byte.io>';
      expect(parseRawHeaderValue(raw, 'to'), 'Bob <b@byte.io>');
    });

    test('joins folded continuation lines', () {
      const String raw =
          'To: long-list@byte.io,\n'
          ' bob@byte.io\n'
          'Subject: Hi';
      expect(parseRawHeaderValue(raw, 'to'), 'long-list@byte.io, bob@byte.io');
    });
  });
}
