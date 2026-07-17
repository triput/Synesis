// ==============================================================================
// File: lib/account/imap_autoconfig.dart
// Description: Thunderbird/Mozilla ISPDB autoconfig discovery for IMAP/SMTP.
// Component: Account / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-16
// ==============================================================================

import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

/// Socket security advertised by Thunderbird clientConfig XML.
enum AutoconfigSocketType {
  ssl,
  startTls,
  plain,
}

/// Parsed IMAP + SMTP endpoints from an autoconfig document.
class AutoconfigResult {
  const AutoconfigResult({
    required this.imapHost,
    required this.imapPort,
    required this.imapSocketType,
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpSocketType,
    required this.username,
  });

  final String imapHost;
  final int imapPort;
  final AutoconfigSocketType imapSocketType;
  final String smtpHost;
  final int smtpPort;
  final AutoconfigSocketType smtpSocketType;

  /// Username after template substitution (`%EMAILADDRESS%`, etc.).
  final String username;
}

/// Thrown when [emailAddress] is not a usable `local@domain` address.
class AutoconfigInvalidEmailException implements Exception {
  const AutoconfigInvalidEmailException(this.emailAddress);

  final String emailAddress;

  @override
  String toString() =>
      'AutoconfigInvalidEmailException: invalid email "$emailAddress"';
}

/// Discovers IMAP/SMTP settings via Mozilla ISPDB / Thunderbird autoconfig XML.
///
/// Lookup order:
/// 1. `https://autoconfig.thunderbird.net/v1.1/{domain}`
/// 2. `https://{domain}/.well-known/autoconfig/mail/config-v1.1.xml`
///
/// DNS SRV (`_imap._tcp` / `_submission._tcp`) is intentionally not implemented
/// here — it would require an additional DNS package and is deferred.
class ImapAutoconfig {
  const ImapAutoconfig({
    this.requestTimeout = const Duration(seconds: 8),
  });

  final Duration requestTimeout;

  /// Fetches and parses autoconfig for [emailAddress].
  ///
  /// Returns `null` when no usable IMAP+SMTP pair is found (network errors,
  /// empty responses, or XML without both server types). Throws
  /// [AutoconfigInvalidEmailException] for malformed addresses.
  Future<AutoconfigResult?> discover(
    String emailAddress, {
    http.Client? client,
  }) async {
    final String domain = extractDomain(emailAddress);
    final http.Client owned = client ?? http.Client();
    final bool ownsClient = client == null;
    try {
      final List<Uri> candidates = <Uri>[
        Uri.https('autoconfig.thunderbird.net', '/v1.1/$domain'),
        Uri.https(domain, '/.well-known/autoconfig/mail/config-v1.1.xml'),
      ];
      for (final Uri uri in candidates) {
        final String? body = await _fetchXml(owned, uri);
        if (body == null || body.trim().isEmpty) {
          continue;
        }
        final AutoconfigResult? parsed = parseClientConfig(body, emailAddress);
        if (parsed != null) {
          return parsed;
        }
      }
      return null;
    } finally {
      if (ownsClient) {
        owned.close();
      }
    }
  }

  /// Parses Thunderbird `clientConfig` XML for IMAP + SMTP servers.
  ///
  /// Returns `null` when either server type is missing or unusable.
  AutoconfigResult? parseClientConfig(String xml, String emailAddress) {
    final String trimmedEmail = emailAddress.trim();
    extractDomain(trimmedEmail);

    final XmlDocument document;
    try {
      document = XmlDocument.parse(xml);
    } on XmlException {
      return null;
    }

    final XmlElement? imapServer = _firstServer(
      document,
      tag: 'incomingServer',
      type: 'imap',
    );
    final XmlElement? smtpServer = _firstServer(
      document,
      tag: 'outgoingServer',
      type: 'smtp',
    );
    if (imapServer == null || smtpServer == null) {
      return null;
    }

    final _ServerEndpoint? imap = _parseServer(imapServer);
    final _ServerEndpoint? smtp = _parseServer(smtpServer);
    if (imap == null || smtp == null) {
      return null;
    }

    final String usernameTemplate = _childText(imapServer, 'username') ??
        _childText(smtpServer, 'username') ??
        '%EMAILADDRESS%';

    return AutoconfigResult(
      imapHost: imap.host,
      imapPort: imap.port,
      imapSocketType: imap.socketType,
      smtpHost: smtp.host,
      smtpPort: smtp.port,
      smtpSocketType: smtp.socketType,
      username: applyUsernameTemplate(usernameTemplate, trimmedEmail),
    );
  }

  /// Extracts the domain portion of [emailAddress].
  ///
  /// Throws [AutoconfigInvalidEmailException] when the address is not
  /// `local@domain` with a non-empty domain.
  static String extractDomain(String emailAddress) {
    final String trimmed = emailAddress.trim();
    final int at = trimmed.lastIndexOf('@');
    if (at <= 0 || at >= trimmed.length - 1) {
      throw AutoconfigInvalidEmailException(emailAddress);
    }
    final String domain = trimmed.substring(at + 1).trim().toLowerCase();
    if (domain.isEmpty || domain.contains('@') || domain.contains(' ')) {
      throw AutoconfigInvalidEmailException(emailAddress);
    }
    return domain;
  }

  /// Substitutes Thunderbird username placeholders.
  static String applyUsernameTemplate(String template, String emailAddress) {
    final String trimmed = emailAddress.trim();
    final int at = trimmed.lastIndexOf('@');
    final String local = at > 0 ? trimmed.substring(0, at) : trimmed;
    final String domain = at > 0 && at < trimmed.length - 1
        ? trimmed.substring(at + 1)
        : '';
    return template
        .replaceAll('%EMAILADDRESS%', trimmed)
        .replaceAll('%EMAILLOCALPART%', local)
        .replaceAll('%EMAILDOMAIN%', domain);
  }

  static AutoconfigSocketType parseSocketType(String? raw) {
    switch ((raw ?? '').trim().toUpperCase()) {
      case 'SSL':
      case 'SSL/TLS':
      case 'TLS':
        return AutoconfigSocketType.ssl;
      case 'STARTTLS':
        return AutoconfigSocketType.startTls;
      case 'PLAIN':
      case 'NONE':
      case '':
        return AutoconfigSocketType.plain;
      default:
        return AutoconfigSocketType.plain;
    }
  }

  Future<String?> _fetchXml(http.Client client, Uri uri) async {
    try {
      final http.Response response = await client
          .get(uri, headers: const <String, String>{
            'Accept': 'text/xml, application/xml, */*',
          })
          .timeout(requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }
      return response.body;
    } on Object {
      return null;
    }
  }

  static XmlElement? _firstServer(
    XmlDocument document, {
    required String tag,
    required String type,
  }) {
    for (final XmlElement element in document.findAllElements(tag)) {
      final String? serverType = element.getAttribute('type');
      if (serverType != null &&
          serverType.trim().toLowerCase() == type.toLowerCase()) {
        return element;
      }
    }
    return null;
  }

  static _ServerEndpoint? _parseServer(XmlElement server) {
    final String? host = _childText(server, 'hostname');
    final String? portRaw = _childText(server, 'port');
    if (host == null || host.isEmpty || portRaw == null) {
      return null;
    }
    final int? port = int.tryParse(portRaw.trim());
    if (port == null || port < 1 || port > 65535) {
      return null;
    }
    return _ServerEndpoint(
      host: host.trim(),
      port: port,
      socketType: parseSocketType(_childText(server, 'socketType')),
    );
  }

  static String? _childText(XmlElement parent, String name) {
    final Iterable<XmlElement> children = parent.findElements(name);
    if (children.isEmpty) {
      return null;
    }
    final String text = children.first.innerText.trim();
    return text.isEmpty ? null : text;
  }
}

class _ServerEndpoint {
  const _ServerEndpoint({
    required this.host,
    required this.port,
    required this.socketType,
  });

  final String host;
  final int port;
  final AutoconfigSocketType socketType;
}
