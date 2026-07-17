// ==============================================================================
// File: test/imap_autoconfig_test.dart
// Description: Unit tests for Thunderbird ISPDB XML parsing and username templates.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-16
// ==============================================================================

import 'package:bytemail/account/imap_autoconfig.dart';
import 'package:flutter_test/flutter_test.dart';

const String _gmailLikeXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<clientConfig version="1.1">
  <emailProvider id="googlemail.com">
    <domain>gmail.com</domain>
    <domain>googlemail.com</domain>
    <displayName>Google Mail</displayName>
    <displayShortName>GMail</displayShortName>
    <incomingServer type="imap">
      <hostname>imap.gmail.com</hostname>
      <port>993</port>
      <socketType>SSL</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
    <incomingServer type="pop3">
      <hostname>pop.gmail.com</hostname>
      <port>995</port>
      <socketType>SSL</socketType>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
    <outgoingServer type="smtp">
      <hostname>smtp.gmail.com</hostname>
      <port>465</port>
      <socketType>SSL</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILADDRESS%</username>
    </outgoingServer>
  </emailProvider>
</clientConfig>
''';

const String _genericIspXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<clientConfig version="1.1">
  <emailProvider id="example-isp.net">
    <domain>example-isp.net</domain>
    <displayName>Example ISP</displayName>
    <incomingServer type="imap">
      <hostname>mail.example-isp.net</hostname>
      <port>143</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILLOCALPART%</username>
    </incomingServer>
    <outgoingServer type="smtp">
      <hostname>smtp.example-isp.net</hostname>
      <port>587</port>
      <socketType>STARTTLS</socketType>
      <authentication>password-cleartext</authentication>
      <username>%EMAILLOCALPART%@%EMAILDOMAIN%</username>
    </outgoingServer>
  </emailProvider>
</clientConfig>
''';

const String _missingSmtpXml = '''
<?xml version="1.0" encoding="UTF-8"?>
<clientConfig version="1.1">
  <emailProvider id="incomplete.example">
    <domain>incomplete.example</domain>
    <incomingServer type="imap">
      <hostname>imap.incomplete.example</hostname>
      <port>993</port>
      <socketType>SSL</socketType>
      <username>%EMAILADDRESS%</username>
    </incomingServer>
  </emailProvider>
</clientConfig>
''';

void main() {
  const ImapAutoconfig autoconfig = ImapAutoconfig();

  group('parseClientConfig', () {
    test('parses gmail-like Thunderbird XML', () {
      final AutoconfigResult? result = autoconfig.parseClientConfig(
        _gmailLikeXml,
        'user@gmail.com',
      );

      expect(result, isNotNull);
      expect(result!.imapHost, 'imap.gmail.com');
      expect(result.imapPort, 993);
      expect(result.imapSocketType, AutoconfigSocketType.ssl);
      expect(result.smtpHost, 'smtp.gmail.com');
      expect(result.smtpPort, 465);
      expect(result.smtpSocketType, AutoconfigSocketType.ssl);
      expect(result.username, 'user@gmail.com');
    });

    test('parses generic ISP XML with STARTTLS and local-part username', () {
      final AutoconfigResult? result = autoconfig.parseClientConfig(
        _genericIspXml,
        'alice@example-isp.net',
      );

      expect(result, isNotNull);
      expect(result!.imapHost, 'mail.example-isp.net');
      expect(result.imapPort, 143);
      expect(result.imapSocketType, AutoconfigSocketType.startTls);
      expect(result.smtpHost, 'smtp.example-isp.net');
      expect(result.smtpPort, 587);
      expect(result.smtpSocketType, AutoconfigSocketType.startTls);
      expect(result.username, 'alice');
    });

    test('returns null when SMTP server is missing', () {
      final AutoconfigResult? result = autoconfig.parseClientConfig(
        _missingSmtpXml,
        'user@incomplete.example',
      );
      expect(result, isNull);
    });

    test('returns null for invalid XML', () {
      final AutoconfigResult? result = autoconfig.parseClientConfig(
        '<not-valid',
        'user@example.com',
      );
      expect(result, isNull);
    });

    test('throws on invalid email when parsing', () {
      expect(
        () => autoconfig.parseClientConfig(_gmailLikeXml, 'not-an-email'),
        throwsA(isA<AutoconfigInvalidEmailException>()),
      );
    });
  });

  group('applyUsernameTemplate', () {
    test('substitutes EMAILADDRESS', () {
      expect(
        ImapAutoconfig.applyUsernameTemplate(
          '%EMAILADDRESS%',
          'pat@contoso.com',
        ),
        'pat@contoso.com',
      );
    });

    test('substitutes EMAILLOCALPART and EMAILDOMAIN', () {
      expect(
        ImapAutoconfig.applyUsernameTemplate(
          '%EMAILLOCALPART%@%EMAILDOMAIN%',
          'pat@contoso.com',
        ),
        'pat@contoso.com',
      );
      expect(
        ImapAutoconfig.applyUsernameTemplate(
          '%EMAILLOCALPART%',
          'pat@contoso.com',
        ),
        'pat',
      );
    });
  });

  group('extractDomain', () {
    test('returns lowercase domain', () {
      expect(ImapAutoconfig.extractDomain('User@Example.COM'), 'example.com');
    });

    test('throws typed error for invalid addresses', () {
      expect(
        () => ImapAutoconfig.extractDomain(''),
        throwsA(isA<AutoconfigInvalidEmailException>()),
      );
      expect(
        () => ImapAutoconfig.extractDomain('nodomain'),
        throwsA(isA<AutoconfigInvalidEmailException>()),
      );
      expect(
        () => ImapAutoconfig.extractDomain('@nodomain'),
        throwsA(isA<AutoconfigInvalidEmailException>()),
      );
      expect(
        () => ImapAutoconfig.extractDomain('user@'),
        throwsA(isA<AutoconfigInvalidEmailException>()),
      );
    });
  });

  group('discover', () {
    test('throws typed error for invalid email without network', () async {
      await expectLater(
        const ImapAutoconfig().discover('bad'),
        throwsA(isA<AutoconfigInvalidEmailException>()),
      );
    });
  });
}
