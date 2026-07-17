import 'package:bytemail/desktop/message_print_service.dart';
import 'package:bytemail/domain/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('buildMessagePdf emits a non-empty PDF document', () async {
    const MailMessage message = MailMessage(
      id: 'message-1',
      accountId: 'account-1',
      fromName: 'Ada',
      fromAddress: 'ada@example.com',
      subject: 'Printable message',
      snippet: 'Hello',
      body: '<p>Hello <strong>from ByteMail</strong>.</p>',
      whenLabel: 'Today',
      bucket: FocusBucket.focused,
    );

    final List<int> bytes = await buildMessagePdf(message, PdfPageFormat.a4);

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('buildMessagePdf draws Unicode punctuation without Helvetica fallback',
      () async {
    const MailMessage message = MailMessage(
      id: 'message-unicode',
      accountId: 'account-1',
      fromName: 'Ada',
      fromAddress: 'ada@example.com',
      subject: 'Jobs — software manager',
      snippet: 'Em dash body',
      body:
          '<p>Your alert for “software” roles — Actively recruiting…</p>',
      whenLabel: 'Today',
      bucket: FocusBucket.focused,
    );

    final List<int> bytes = await buildMessagePdf(message, PdfPageFormat.a4);

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('buildMessagePdf paginates a very long body without throwing', () async {
    final String longPlainBody = List<String>.generate(
      600,
      (int index) =>
          'Line ${index + 1}: long printable email content for pagination.',
    ).join('\n');
    final String longHtmlBody =
        '<div>${List<String>.generate(80, (int index) => '<p>Paragraph ${index + 1}. ${'word ' * 120}</p>').join()}</div>';

    for (final String body in <String>[longPlainBody, longHtmlBody]) {
      final MailMessage message = MailMessage(
        id: 'message-long',
        accountId: 'account-1',
        fromName: 'Ada',
        fromAddress: 'ada@example.com',
        subject: 'Long printable message',
        snippet: 'Long body',
        body: body,
        whenLabel: 'Today',
        bucket: FocusBucket.focused,
      );

      final List<int> bytes = await buildMessagePdf(message, PdfPageFormat.a4);

      expect(bytes, isNotEmpty);
      expect(String.fromCharCodes(bytes.take(4)), '%PDF');
    }
  });
}
