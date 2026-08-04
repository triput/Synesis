// ==============================================================================
// File: lib/protocol/dav/dav_client.dart
// Description: Authenticated WebDAV request and multistatus parsing helpers.
// Component: Protocol / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-08-04
// ==============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:synesis/protocol/mail_provider.dart';
import 'package:xml/xml.dart';

class DavResponse {
  const DavResponse({
    required this.href,
    required this.properties,
    this.etag,
    this.statusCode,
  });

  final String href;
  final Map<String, String> properties;
  final String? etag;
  final int? statusCode;

  bool hasResourceType(String value) =>
      (propertyNamed('resourcetype') ?? '').contains(value);

  String? propertyNamed(String localName) {
    for (final MapEntry<String, String> entry in properties.entries) {
      if (entry.key.endsWith(':$localName')) {
        return entry.value;
      }
    }
    return null;
  }
}

/// Result of a successful DAV PUT create (Wave 6b).
class DavPutResult {
  const DavPutResult({
    required this.href,
    required this.statusCode,
    this.etag,
  });

  /// Absolute resource href (Location when present, else request URI).
  final String href;

  final int statusCode;

  /// Opaque etag from the response `ETag` header when present.
  final String? etag;
}

class DavClient {
  DavClient({
    required String username,
    required String password,
    http.Client? client,
    Duration timeout = const Duration(seconds: 45),
  }) : _authorization =
           'Basic ${base64Encode(utf8.encode('$username:$password'))}',
       _inner = client ?? http.Client(),
       _ownsClient = client == null,
       _timeout = timeout;

  final String _authorization;
  final http.Client _inner;
  final bool _ownsClient;
  final Duration _timeout;
  bool _disposed = false;

  Future<List<DavResponse>> propFind(
    Uri uri, {
    required int depth,
    required String body,
  }) => _davXml('PROPFIND', uri, depth: depth, body: body);

  Future<List<DavResponse>> report(
    Uri uri, {
    required String body,
    int depth = 1,
  }) => _davXml('REPORT', uri, depth: depth, body: body);

  Future<String> get(Uri uri) async {
    final http.Response response = await _send(http.Request('GET', uri));
    _ensureSuccess(response);
    return response.body;
  }

  /// Creates a new resource with PUT + `If-None-Match: *` (Wave 6b).
  ///
  /// [contentType] is typically `text/calendar; charset=utf-8` or
  /// `text/vcard; charset=utf-8`. Success codes: 200, 201, 204.
  Future<DavPutResult> put(
    Uri uri, {
    required String body,
    required String contentType,
  }) async {
    final http.Request request = http.Request('PUT', uri)
      ..headers.addAll(<String, String>{
        'Content-Type': contentType,
        'If-None-Match': '*',
      })
      ..body = body;
    final http.Response response = await _send(request);
    _ensureSuccess(response);
    final String? location = response.headers['location'];
    final String href;
    if (location != null && location.trim().isNotEmpty) {
      href = uri.resolve(location.trim()).toString();
    } else {
      href = uri.toString();
    }
    final String? etag = _headerIgnoreCase(response.headers, 'etag');
    return DavPutResult(
      href: href,
      statusCode: response.statusCode,
      etag: etag == null || etag.isEmpty ? null : etag,
    );
  }

  Future<List<DavResponse>> _davXml(
    String method,
    Uri uri, {
    required int depth,
    required String body,
  }) async {
    final http.Request request = http.Request(method, uri)
      ..headers.addAll(<String, String>{
        'Depth': depth.toString(),
        'Content-Type': 'application/xml; charset=utf-8',
        'Accept': 'application/xml, text/xml',
      })
      ..body = body;
    final http.Response response = await _send(request);
    _ensureSuccess(response);
    try {
      return _parseMultistatus(response.body, uri);
    } on XmlException catch (error) {
      throw ProtocolException('DAV server returned invalid XML.', cause: error);
    }
  }

  Future<http.Response> _send(http.BaseRequest request) async {
    if (_disposed) {
      throw const ProtocolException('DAV client has been disposed.');
    }
    request.headers['Authorization'] = _authorization;
    request.headers['User-Agent'] = 'Synesis/2.0';
    try {
      final http.StreamedResponse streamed = await _inner
          .send(request)
          .timeout(_timeout);
      return http.Response.fromStream(streamed);
    } on TimeoutException catch (error) {
      throw ProtocolException('DAV request timed out.', cause: error);
    } on http.ClientException catch (error) {
      throw ProtocolException('DAV request failed.', cause: error);
    }
  }

  static List<DavResponse> _parseMultistatus(String body, Uri context) {
    final XmlDocument document = XmlDocument.parse(body);
    final List<DavResponse> responses = <DavResponse>[];
    for (final XmlElement response
        in document.descendants.whereType<XmlElement>().where(
          (XmlElement element) => element.localName == 'response',
        )) {
      final XmlElement? hrefElement = _first(response, 'href');
      if (hrefElement == null) {
        continue;
      }
      final Map<String, String> properties = <String, String>{};
      String? etag;
      for (final XmlElement propstat
          in response.descendants.whereType<XmlElement>().where(
            (XmlElement element) => element.localName == 'propstat',
          )) {
        final String status = _first(propstat, 'status')?.innerText ?? '';
        if (!status.contains(' 200 ')) {
          continue;
        }
        final XmlElement? prop = _first(propstat, 'prop');
        if (prop == null) {
          continue;
        }
        for (final XmlElement property in prop.childElements) {
          final String key =
              '${property.namespaceUri ?? ''}:${property.localName}';
          final List<XmlElement> hrefs = property.descendants
              .whereType<XmlElement>()
              .where((XmlElement element) => element.localName == 'href')
              .toList(growable: false);
          final String value;
          if (hrefs.isNotEmpty) {
            value = hrefs.first.innerText.trim();
          } else if (property.localName == 'resourcetype') {
            value = property.descendants
                .whereType<XmlElement>()
                .map((XmlElement element) => element.localName)
                .join(' ');
          } else {
            value = property.innerText.trim();
          }
          properties[key] = value;
          if (property.localName == 'getetag') {
            etag = value;
          }
        }
      }
      responses.add(
        DavResponse(
          href: context.resolve(hrefElement.innerText.trim()).toString(),
          properties: properties,
          etag: etag,
        ),
      );
    }
    return List<DavResponse>.unmodifiable(responses);
  }

  static XmlElement? _first(XmlElement parent, String localName) {
    for (final XmlElement element
        in parent.descendants.whereType<XmlElement>()) {
      if (element.localName == localName) {
        return element;
      }
    }
    return null;
  }

  static void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ProtocolException(
        response.body.trim().isEmpty
            ? 'DAV request failed with HTTP ${response.statusCode}.'
            : response.body.trim(),
        statusCode: response.statusCode,
      );
    }
  }

  static String? _headerIgnoreCase(
    Map<String, String> headers,
    String name,
  ) {
    final String lower = name.toLowerCase();
    for (final MapEntry<String, String> entry in headers.entries) {
      if (entry.key.toLowerCase() == lower) {
        return entry.value;
      }
    }
    return null;
  }

  void dispose() {
    if (!_disposed) {
      _disposed = true;
      if (_ownsClient) {
        _inner.close();
      }
    }
  }
}
