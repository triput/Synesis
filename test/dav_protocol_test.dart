// ==============================================================================
// File: test/dav_protocol_test.dart
// Description: Fixture coverage for DAV discovery, CardDAV, and CalDAV parsing.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/protocol/dav/dav_discovery.dart';
import 'package:synesis/protocol/dav_pim_provider.dart';

void main() {
  test(
    'DavDiscovery follows principal home-set and collections fixtures',
    () async {
      final http.Client client = MockClient((http.Request request) async {
        expect(request.method, 'PROPFIND');
        expect(request.headers['authorization'], startsWith('Basic '));
        if (request.url.path == '/') {
          return _xml(_principalXml);
        }
        if (request.url.path == '/principals/me/') {
          return _xml(_addressBookHomeXml);
        }
        expect(request.url.path, '/addressbooks/me/');
        expect(request.headers['depth'], '1');
        return _xml(_addressBooksXml);
      });
      final DavDiscovery discovery = DavDiscovery(
        service: DavService.carddav,
        emailAddress: 'ada@example.test',
        password: 'not-a-secret',
        knownBaseUrl: 'https://dav.example.test/',
        client: client,
      );
      addTearDown(discovery.dispose);

      final DavDiscoveryResult result = await discovery.discover();
      expect(result.principalUrl, 'https://dav.example.test/principals/me/');
      expect(result.homeSetUrl, 'https://dav.example.test/addressbooks/me/');
      expect(result.collections.map((DavCollection c) => c.href), <String>[
        'https://dav.example.test/addressbooks/me/contacts/',
        'https://dav.example.test/addressbooks/me/team/',
      ]);
      expect(result.collections.first.isDefault, isTrue);
      expect(result.collections.last.name, 'Team');
    },
  );

  test(
    'DavPimProvider maps href identities and CalDAV windowed events',
    () async {
      String? reportBody;
      final http.Client client = MockClient((http.Request request) async {
        if (request.method == 'PROPFIND' && request.url.path == '/') {
          return _xml(_principalXml);
        }
        if (request.method == 'PROPFIND' &&
            request.url.path == '/principals/me/') {
          return _xml(
            request.body.contains('calendar-home-set')
                ? _calendarHomeXml
                : _addressBookHomeXml,
          );
        }
        if (request.method == 'PROPFIND' &&
            request.url.path == '/addressbooks/me/') {
          return _xml(_addressBooksXml);
        }
        if (request.method == 'PROPFIND' &&
            request.url.path == '/calendars/me/') {
          return _xml(_calendarsXml);
        }
        if (request.method == 'PROPFIND' &&
            request.url.path == '/addressbooks/me/contacts/') {
          return _xml(_contactResourcesXml);
        }
        if (request.method == 'GET') {
          return http.Response(_vcard, 200);
        }
        if (request.method == 'REPORT') {
          reportBody = request.body;
          return _xml(_calendarEventsXml);
        }
        fail('Unexpected DAV request: ${request.method} ${request.url}');
      });
      final DavPimProvider provider = DavPimProvider(
        emailAddress: 'ada@example.test',
        password: 'not-a-secret',
        baseUrl: 'https://dav.example.test/',
        client: client,
      );

      final List<dynamic> folders = await provider.listContactFolders();
      expect(
        folders.first.providerId,
        'https://dav.example.test/addressbooks/me/contacts/',
      );
      final String listId = PimIds.stableLocalId(
        'imap',
        'https://dav.example.test/addressbooks/me/contacts/',
      );
      final dynamic contacts = await provider.syncContacts(
        accountId: 'imap',
        contactListId: listId,
        folderProviderId: folders.first.providerId as String,
      );
      expect(
        contacts.changed.single.contact.providerId,
        'https://dav.example.test/addressbooks/me/contacts/ada.vcf',
      );

      final List<dynamic> calendars = await provider.listCalendars();
      final dynamic events = await provider.syncEvents(
        accountId: 'imap',
        calendarId: 'calendar-id',
        calendarProviderId: calendars.single.providerId as String,
        now: DateTime.utc(2026, 7, 27),
      );
      expect(
        events.changed.single.event.providerId,
        'https://dav.example.test/calendars/me/main/meeting.ics',
      );
      expect(reportBody, contains('20260428T000000Z'));
      expect(reportBody, contains('20270727T000000Z'));
    },
  );
}

http.Response _xml(String body) => http.Response(
  body,
  207,
  headers: const <String, String>{'content-type': 'application/xml'},
);

const String _principalXml = '''<?xml version="1.0"?>
<d:multistatus xmlns:d="DAV:"><d:response><d:href>/</d:href><d:propstat><d:prop><d:current-user-principal><d:href>/principals/me/</d:href></d:current-user-principal></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response></d:multistatus>''';
const String _addressBookHomeXml =
    '''<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:carddav"><d:response><d:href>/principals/me/</d:href><d:propstat><d:prop><c:addressbook-home-set><d:href>/addressbooks/me/</d:href></c:addressbook-home-set></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response></d:multistatus>''';
const String _calendarHomeXml =
    '''<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:response><d:href>/principals/me/</d:href><d:propstat><d:prop><c:calendar-home-set><d:href>/calendars/me/</d:href></c:calendar-home-set></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response></d:multistatus>''';
const String _addressBooksXml =
    '''<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:carddav"><d:response><d:href>/addressbooks/me/contacts/</d:href><d:propstat><d:prop><d:displayname>Contacts</d:displayname><d:resourcetype><d:collection/><c:addressbook/></d:resourcetype></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response><d:response><d:href>/addressbooks/me/team/</d:href><d:propstat><d:prop><d:displayname>Team</d:displayname><d:resourcetype><d:collection/><c:addressbook/></d:resourcetype></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response></d:multistatus>''';
const String _calendarsXml =
    '''<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:response><d:href>/calendars/me/main/</d:href><d:propstat><d:prop><d:displayname>Main</d:displayname><d:resourcetype><d:collection/><c:calendar/></d:resourcetype></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response></d:multistatus>''';
const String _contactResourcesXml =
    '''<d:multistatus xmlns:d="DAV:"><d:response><d:href>/addressbooks/me/contacts/ada.vcf</d:href><d:propstat><d:prop><d:getetag>"abc"</d:getetag></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response></d:multistatus>''';
const String _calendarEventsXml =
    '''<d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:response><d:href>/calendars/me/main/meeting.ics</d:href><d:propstat><d:prop><d:getetag>"event"</d:getetag><c:calendar-data>BEGIN:VCALENDAR
BEGIN:VEVENT
UID:meeting-1
DTSTART:20260728T120000Z
DTEND:20260728T130000Z
SUMMARY:Planning
END:VEVENT
END:VCALENDAR</c:calendar-data></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat></d:response></d:multistatus>''';
const String _vcard = '''BEGIN:VCARD
VERSION:4.0
FN:Ada Lovelace
N:Lovelace;Ada;;;
EMAIL;TYPE=work:ada@example.test
END:VCARD''';
