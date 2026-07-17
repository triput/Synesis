// ==============================================================================
// File: test/compose_prefill_test.dart
// Description: ComposePrefill Re:/Fw: subject rules and reply-all header parse
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/ui/compose/compose_prefill.dart';
import 'package:flutter_test/flutter_test.dart';

MailMessage _message({
  String subject = 'Hello',
  String fromAddress = 'alice@example.com',
  String fromName = 'Alice',
  String? messageIdHeader = '<msg-1@example.com>',
  String? rawHeaders,
  String snippet = 'Snippet body',
  String body = 'Full body',
  String accountId = 'acct-1',
}) {
  return MailMessage(
    id: 'm1',
    accountId: accountId,
    fromName: fromName,
    fromAddress: fromAddress,
    subject: subject,
    snippet: snippet,
    body: body,
    whenLabel: 'Now',
    bucket: FocusBucket.focused,
    messageIdHeader: messageIdHeader,
    rawHeaders: rawHeaders,
  );
}

void main() {
  group('ensureReplySubject', () {
    test('prefixes Re: when missing', () {
      expect(ComposePrefill.ensureReplySubject('Hello'), 'Re: Hello');
    });

    test('does not double Re: prefix', () {
      expect(ComposePrefill.ensureReplySubject('Re: Hello'), 'Re: Hello');
      expect(ComposePrefill.ensureReplySubject('RE: Hello'), 'RE: Hello');
      expect(ComposePrefill.ensureReplySubject('re: Hello'), 're: Hello');
    });

    test('handles empty subject', () {
      expect(ComposePrefill.ensureReplySubject(''), 'Re:');
      expect(ComposePrefill.ensureReplySubject('   '), 'Re:');
    });
  });

  group('ensureForwardSubject', () {
    test('prefixes Fw: when missing', () {
      expect(ComposePrefill.ensureForwardSubject('Hello'), 'Fw: Hello');
    });

    test('does not double Fw:/Fwd: prefix', () {
      expect(ComposePrefill.ensureForwardSubject('Fw: Hello'), 'Fw: Hello');
      expect(ComposePrefill.ensureForwardSubject('Fwd: Hello'), 'Fwd: Hello');
      expect(ComposePrefill.ensureForwardSubject('FW: Hello'), 'FW: Hello');
    });
  });

  group('ComposePrefill.reply', () {
    test('sets to, Re: subject, and inReplyTo', () {
      final ComposePrefill prefill = ComposePrefill.reply(
        _message(subject: 'Status'),
      );
      expect(prefill.mode, ComposeMode.reply);
      expect(prefill.accountId, 'acct-1');
      expect(prefill.to, <String>['alice@example.com']);
      expect(prefill.cc, isEmpty);
      expect(prefill.subject, 'Re: Status');
      expect(prefill.inReplyTo, '<msg-1@example.com>');
      expect(prefill.composeModeValue, 'reply');
    });

    test('does not double Re: on reply', () {
      final ComposePrefill prefill = ComposePrefill.reply(
        _message(subject: 'Re: Status'),
      );
      expect(prefill.subject, 'Re: Status');
    });
  });

  group('ComposePrefill.replyAll', () {
    test('falls back to from-only when rawHeaders absent', () {
      final ComposePrefill prefill = ComposePrefill.reply(
        _message(rawHeaders: null),
        replyAll: true,
        ownAddress: 'me@byte.io',
      );
      expect(prefill.mode, ComposeMode.replyAll);
      expect(prefill.to, <String>['alice@example.com']);
      expect(prefill.cc, isEmpty);
      expect(prefill.composeModeValue, 'replyAll');
    });

    test('parses To/Cc and excludes own address', () {
      const String headers = '''
From: Alice <alice@example.com>
To: Me <me@byte.io>, Bob <bob@example.com>
Cc: Carol <carol@example.com>, me@byte.io
Subject: Team sync
Message-ID: <msg-1@example.com>
''';
      final ComposePrefill prefill = ComposePrefill.reply(
        _message(rawHeaders: headers),
        replyAll: true,
        ownAddress: 'me@byte.io',
      );
      expect(prefill.to, <String>['alice@example.com', 'bob@example.com']);
      expect(prefill.cc, <String>['carol@example.com']);
      expect(prefill.subject, 'Re: Hello');
    });

    test('handles folded header lines', () {
      const String headers = '''
To: Bob <bob@example.com>,
\tDana <dana@example.com>
Cc: Eve <eve@example.com>
''';
      final List<String> to = extractAddressesFromRawHeaders(headers, 'To');
      expect(to, <String>['bob@example.com', 'dana@example.com']);
    });
  });

  group('ComposePrefill.forward', () {
    test('sets Fw: subject and plain forward body from snippet', () {
      final ComposePrefill prefill = ComposePrefill.forward(
        _message(subject: 'Report', snippet: 'Here is the report.'),
      );
      expect(prefill.mode, ComposeMode.forward);
      expect(prefill.subject, 'Fw: Report');
      expect(prefill.to, isEmpty);
      expect(prefill.body, contains('---------- Forwarded message ----------'));
      expect(prefill.body, contains('From: Alice <alice@example.com>'));
      expect(prefill.body, contains('Here is the report.'));
      expect(prefill.composeModeValue, 'forward');
    });

    test('does not double Fw: prefix', () {
      final ComposePrefill prefill = ComposePrefill.forward(
        _message(subject: 'Fw: Report'),
      );
      expect(prefill.subject, 'Fw: Report');
    });

    test('falls back to stripped body when snippet empty', () {
      final ComposePrefill prefill = ComposePrefill.forward(
        _message(snippet: '', body: '<p>Plain&nbsp;ish</p>'),
      );
      expect(prefill.body, contains('Plain'));
      expect(prefill.body, isNot(contains('<p>')));
    });
  });

  group('splitOutboxRecipients', () {
    test('splits commas and semicolons', () {
      expect(
        splitOutboxRecipients('Ada <ada@byte.io>; bob@byte.io, carol@byte.io'),
        <String>['ada@byte.io', 'bob@byte.io', 'carol@byte.io'],
      );
    });
  });
}
