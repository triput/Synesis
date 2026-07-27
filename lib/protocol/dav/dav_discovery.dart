// ==============================================================================
// File: lib/protocol/dav/dav_discovery.dart
// Description: Shared CardDAV and CalDAV discovery chain.
// Component: Protocol / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:http/http.dart' as http;
import 'package:synesis/protocol/dav/dav_client.dart';
import 'package:synesis/protocol/mail_provider.dart';

enum DavService { carddav, caldav }

class DavCollection {
  const DavCollection({
    required this.href,
    required this.name,
    required this.isDefault,
    this.ctag,
    this.syncToken,
  });

  final String href;
  final String name;
  final bool isDefault;
  final String? ctag;
  final String? syncToken;
}

class DavDiscoveryResult {
  const DavDiscoveryResult({
    required this.contextUrl,
    required this.principalUrl,
    required this.homeSetUrl,
    required this.collections,
  });

  final String contextUrl;
  final String principalUrl;
  final String homeSetUrl;
  final List<DavCollection> collections;
}

class DavDiscovery {
  DavDiscovery({
    required this.service,
    required this.emailAddress,
    required this.password,
    this.knownBaseUrl,
    this.imapHost,
    http.Client? client,
  }) : _client = DavClient(
         username: emailAddress,
         password: password,
         client: client,
       );

  final DavService service;
  final String emailAddress;
  final String password;
  final String? knownBaseUrl;
  final String? imapHost;
  final DavClient _client;

  static const String runboxDavUrl = 'https://dav.runbox.com/';

  static bool isRunboxHint(String emailAddress, String? imapHost) {
    final String domain = emailAddress.trim().toLowerCase().split('@').last;
    final String host = imapHost?.trim().toLowerCase() ?? '';
    return domain == 'runbox.com' || host == 'mail.runbox.com';
  }

  Future<DavDiscoveryResult> discover() async {
    ProtocolException? lastError;
    for (final Uri candidate in _candidates()) {
      try {
        return await _discoverAt(candidate);
      } on ProtocolException catch (error) {
        lastError = error;
        if (error.statusCode != 404) {
          continue;
        }
      }
    }
    throw lastError ??
        const ProtocolException('No usable CardDAV/CalDAV endpoint was found.');
  }

  List<Uri> _candidates() {
    final List<Uri> candidates = <Uri>[];
    void add(String? value) {
      final String? normalized = normalizeBaseUrl(value);
      if (normalized != null &&
          !candidates.any((Uri uri) => uri.toString() == normalized)) {
        candidates.add(Uri.parse(normalized));
      }
    }

    add(knownBaseUrl);
    if (isRunboxHint(emailAddress, imapHost)) {
      add(runboxDavUrl);
    }
    final String domain = emailAddress.trim().split('@').last;
    if (domain.isNotEmpty) {
      add('https://$domain/.well-known/${service.name}');
      add('https://$domain/');
    }
    return candidates;
  }

  Future<DavDiscoveryResult> _discoverAt(Uri context) async {
    List<DavResponse> bootstrap;
    try {
      bootstrap = await _client.propFind(
        context,
        depth: 0,
        body: _principalRequest,
      );
    } on ProtocolException catch (error) {
      if (error.statusCode != 404 || context.path == '/') {
        rethrow;
      }
      bootstrap = await _client.propFind(
        context.replace(path: '/'),
        depth: 0,
        body: _principalRequest,
      );
      context = context.replace(path: '/');
    }
    final DavResponse response = _firstResponse(bootstrap);
    final String? principal = response.propertyNamed('current-user-principal');
    final String? directHome = response.propertyNamed(_homeSetName);
    final Uri principalUri = principal == null || principal.isEmpty
        ? context
        : context.resolve(principal);
    final Uri homeUri;
    if (directHome != null && directHome.isNotEmpty) {
      homeUri = context.resolve(directHome);
    } else {
      final DavResponse principalResponse = _firstResponse(
        await _client.propFind(principalUri, depth: 0, body: _homeSetRequest),
      );
      final String? home = principalResponse.propertyNamed(_homeSetName);
      if (home == null || home.isEmpty) {
        throw const ProtocolException(
          'DAV principal did not provide a home set.',
        );
      }
      homeUri = principalUri.resolve(home);
    }
    final List<DavResponse> resources = await _client.propFind(
      homeUri,
      depth: 1,
      body: _collectionRequest,
    );
    final List<DavCollection> collections = <DavCollection>[];
    for (final DavResponse item in resources) {
      if (!item.hasResourceType(_collectionType)) {
        continue;
      }
      collections.add(
        DavCollection(
          href: item.href,
          name:
              _nonEmpty(item.propertyNamed('displayname')) ??
              (service == DavService.carddav ? 'Contacts' : 'Calendar'),
          isDefault: collections.isEmpty,
          ctag: _nonEmpty(item.propertyNamed('getctag')),
          syncToken: _nonEmpty(item.propertyNamed('sync-token')),
        ),
      );
    }
    return DavDiscoveryResult(
      contextUrl: context.toString(),
      principalUrl: principalUri.toString(),
      homeSetUrl: homeUri.toString(),
      collections: List<DavCollection>.unmodifiable(collections),
    );
  }

  String get _homeSetProperty => service == DavService.carddav
      ? 'urn:ietf:params:xml:ns:carddav:addressbook-home-set'
      : 'urn:ietf:params:xml:ns:caldav:calendar-home-set';

  String get _homeSetName => service == DavService.carddav
      ? 'addressbook-home-set'
      : 'calendar-home-set';

  String get _collectionType =>
      service == DavService.carddav ? 'addressbook' : 'calendar';

  String get _principalRequest =>
      '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop>'
      '<d:current-user-principal/><d:principal-URL/>'
      '</d:prop></d:propfind>';

  String get _homeSetRequest => service == DavService.carddav
      ? '<?xml version="1.0"?><d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:carddav"><d:prop><c:addressbook-home-set/></d:prop></d:propfind>'
      : '<?xml version="1.0"?><d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:prop><c:calendar-home-set/></d:prop></d:propfind>';

  String get _collectionRequest => service == DavService.carddav
      ? '<?xml version="1.0"?><d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:carddav"><d:prop><d:resourcetype/><d:displayname/><d:sync-token/><c:addressbook-description/></d:prop></d:propfind>'
      : '<?xml version="1.0"?><d:propfind xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav" xmlns:cs="http://calendarserver.org/ns/"><d:prop><d:resourcetype/><d:displayname/><d:sync-token/><cs:getctag/></d:prop></d:propfind>';

  static DavResponse _firstResponse(List<DavResponse> responses) {
    if (responses.isEmpty) {
      throw const ProtocolException('DAV response contained no resources.');
    }
    return responses.first;
  }

  static String? normalizeBaseUrl(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }
    final Uri? uri = Uri.tryParse(trimmed);
    if (uri == null ||
        !uri.hasScheme ||
        uri.host.isEmpty ||
        uri.scheme != 'https') {
      throw ArgumentError.value(
        value,
        'davBaseUrl',
        'Must be an absolute HTTPS URL.',
      );
    }
    return uri
        .replace(path: uri.path.endsWith('/') ? uri.path : '${uri.path}/')
        .toString();
  }

  static String? _nonEmpty(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  void dispose() => _client.dispose();
}
