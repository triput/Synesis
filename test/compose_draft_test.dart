// ==============================================================================
// File: test/compose_draft_test.dart
// Description: ComposeDraft factories and packing helpers for W4.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/compose/outgoing_message_builder.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/ui/compose/compose_draft.dart';
import 'package:bytemail/ui/compose/compose_prefill.dart';
import 'package:flutter_test/flutter_test.dart';

MailMessage _msg({
  String from = 'alice@example.com',
  String subject = 'Hello',
  String body = 'Body line',
  String? messageId = '<mid-1@example.com>',
  String? rawHeaders,
}) {
  return MailMessage(
    id: 'm1',
    accountId: 'acc1',
    fromName: 'Alice',
    fromAddress: from,
    subject: subject,
    snippet: body,
    body: body,
    whenLabel: 'now',
    bucket: FocusBucket.focused,
    messageIdHeader: messageId,
    rawHeaders: rawHeaders,
  );
}

void main() {
  test('ComposeDraft.fromPrefill maps reply fields', () {
    final ComposePrefill prefill = ComposePrefill.reply(_msg());
    final ComposeDraft draft = ComposeDraft.fromPrefill(prefill);
    expect(draft.mode, ComposeMode.reply);
    expect(draft.to, <String>['alice@example.com']);
    expect(draft.subject, startsWith('Re:'));
    expect(draft.inReplyTo, '<mid-1@example.com>');
    expect(draft.bodyPlain, contains('wrote:'));
    expect(draft.bodyHtml, isNotNull);
    expect(draft.references, isNotEmpty);
  });

  test('OutgoingMessageBuilder packs and unpacks html body', () {
    final String packed = OutgoingMessageBuilder.packBody(
      plain: 'hi',
      html: '<b>hi</b>',
    );
    expect(OutgoingMessageBuilder.unpackPlain(packed), 'hi');
    expect(packed, contains('---bytemail-html---'));
  });

  test('reply builds References JSON including Message-ID', () {
    final String? refs = ComposePrefill.buildReferencesJson(_msg());
    expect(refs, isNotNull);
    expect(refs, contains('mid-1@example.com'));
  });
}
