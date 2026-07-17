import 'package:bytemail/domain/models.dart';
import 'package:bytemail/mime/eml_codec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('exports and parses a plain text message', () {
    const MailMessage original = MailMessage(
      id: 'message-1',
      accountId: 'account-1',
      fromName: 'Ada Lovelace',
      fromAddress: 'ada@example.com',
      subject: 'A useful note',
      snippet: 'First line',
      body: 'First line\r\nSecond line.',
      whenLabel: 'Today',
      whenEpochMs: 1767225600000,
      messageIdHeader: '<message-1@example.com>',
      rawHeaders: 'To: reader@example.com\r\nX-Test: retained',
      bucket: FocusBucket.focused,
    );

    final String eml = exportMessageToEml(original);
    final EmlPreview parsed = parseEmlPreview(eml);

    expect(eml, contains('To: reader@example.com'));
    expect(eml, contains('X-Test: retained'));
    expect(parsed.fromName, 'Ada Lovelace');
    expect(parsed.fromAddress, 'ada@example.com');
    expect(parsed.subject, original.subject);
    expect(parsed.body, original.body);
    expect(parsed.isHtml, isFalse);
  });

  test('round-trips unicode HTML using encoded headers and body', () {
    const MailMessage original = MailMessage(
      id: 'message-2',
      accountId: 'account-1',
      fromName: 'Renée',
      fromAddress: 'renee@example.com',
      subject: 'Résumé',
      snippet: 'Hello',
      body: '<html><body>Hello, 世界</body></html>',
      whenLabel: 'Today',
      bucket: FocusBucket.other,
    );

    final EmlPreview parsed = parseEmlPreview(exportMessageToEml(original));

    expect(parsed.fromName, original.fromName);
    expect(parsed.subject, original.subject);
    expect(parsed.body, original.body);
    expect(parsed.isHtml, isTrue);
  });
}
