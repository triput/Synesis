// ==============================================================================
// File: test/dav_pim_create_test.dart
// Description: Wave 6b CalDAV/CardDAV PUT create + SyncEngine copy rewrite.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-04
// Last Update: 2026-08-04
// ==============================================================================

import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/pim/ics_calendar_parser.dart';
import 'package:synesis/pim/ics_calendar_writer.dart';
import 'package:synesis/protocol/dav/dav_client.dart';
import 'package:synesis/protocol/dav/vcard_parser.dart';
import 'package:synesis/protocol/dav/vcard_writer.dart';
import 'package:synesis/protocol/dav_pim_provider.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/protocol/mail_provider.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/network_sync_policy.dart';
import 'package:synesis/sync/pim_sync_jobs.dart';
import 'package:synesis/sync/sync_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('IcsCalendarWriter / VCardWriter', () {
    test('writes minimal VEVENT fields Wave 6 copies', () {
      final CalendarEvent event = CalendarEvent(
        id: 'e1',
        accountId: 'a',
        calendarId: 'c',
        providerId: 'local:uid-1',
        title: 'Standup; note',
        body: 'Line1\nLine2',
        location: 'Room A, HQ',
        startEpochMs: DateTime.utc(2026, 8, 4, 15).millisecondsSinceEpoch,
        endEpochMs: DateTime.utc(2026, 8, 4, 16).millisecondsSinceEpoch,
        reminderMinutes: 15,
        updatedAt: 1,
      );
      final String ics = const IcsCalendarWriter().writeEvent(
        event: event,
        uid: 'uid-1',
        now: DateTime.utc(2026, 8, 4, 12),
      );
      expect(ics, contains('UID:uid-1'));
      expect(ics, contains(r'SUMMARY:Standup\; note'));
      expect(ics, contains(r'DESCRIPTION:Line1\nLine2'));
      expect(ics, contains(r'LOCATION:Room A\, HQ'));
      expect(ics, contains('DTSTART:20260804T150000Z'));
      expect(ics, contains('DTEND:20260804T160000Z'));
      expect(ics, contains('TRIGGER:-PT15M'));
      expect(ics, isNot(contains('ATTENDEE')));
      expect(ics, isNot(contains('RRULE')));

      final List<IcsEvent> parsed = const IcsCalendarParser().parse(ics).events;
      expect(parsed, hasLength(1));
      expect(parsed.single.summary, 'Standup; note');
      expect(parsed.single.uid, 'uid-1');
    });

    test('writes all-day VALUE=DATE', () {
      final CalendarEvent event = CalendarEvent(
        id: 'e1',
        accountId: 'a',
        calendarId: 'c',
        providerId: 'local:day',
        title: 'Holiday',
        allDay: true,
        startEpochMs: DateTime.utc(2026, 8, 4).millisecondsSinceEpoch,
        endEpochMs: DateTime.utc(2026, 8, 5).millisecondsSinceEpoch,
        updatedAt: 1,
      );
      final String ics = const IcsCalendarWriter().writeEvent(
        event: event,
        uid: 'day',
      );
      expect(ics, contains('DTSTART;VALUE=DATE:20260804'));
      expect(ics, contains('DTEND;VALUE=DATE:20260805'));
    });

    test('writes minimal vCard fields Wave 6 copies', () {
      final Contact contact = Contact(
        id: 'c1',
        accountId: 'a',
        contactListId: 'l',
        providerId: 'local:person-1',
        displayName: 'Ada Lovelace',
        givenName: 'Ada',
        familyName: 'Lovelace',
        company: 'Analytical Engines',
        notes: 'Pioneer',
        updatedAt: 1,
      );
      final String vcf = const VCardWriter().writeContact(
        contact: contact,
        uid: 'person-1',
        emails: const <ContactEmail>[
          ContactEmail(
            id: 'e',
            contactId: 'c1',
            address: 'ada@example.test',
            type: 'work',
          ),
        ],
        phones: const <ContactPhone>[
          ContactPhone(
            id: 'p',
            contactId: 'c1',
            number: '+15551212',
            type: 'mobile',
          ),
        ],
      );
      expect(vcf, contains('UID:person-1'));
      expect(vcf, contains('FN:Ada Lovelace'));
      expect(vcf, contains('N:Lovelace;Ada;;;'));
      expect(vcf, contains('ORG:Analytical Engines'));
      expect(vcf, contains('NOTE:Pioneer'));
      expect(vcf, contains('EMAIL;TYPE=WORK:ada@example.test'));
      expect(vcf, contains('TEL;TYPE=CELL:+15551212'));

      final DavVCard? parsed = const VCardParser().parse(vcf);
      expect(parsed, isNotNull);
      expect(parsed!.displayName, 'Ada Lovelace');
      expect(parsed.emails.single.value, 'ada@example.test');
      expect(parsed.phones.single.type, 'cell');
    });
  });

  group('DavClient.put', () {
    test('sends If-None-Match and returns Location/ETag', () async {
      http.Request? putRequest;
      final http.Client client = MockClient((http.Request request) async {
        expect(request.method, 'PUT');
        putRequest = request;
        return http.Response(
          '',
          201,
          headers: <String, String>{
            'etag': '"abc"',
            'location':
                'https://dav.example.test/calendars/me/personal/uid-1.ics',
          },
        );
      });
      final DavClient dav = DavClient(
        username: 'ada@example.test',
        password: 'secret',
        client: client,
      );
      addTearDown(dav.dispose);

      final DavPutResult result = await dav.put(
        Uri.parse('https://dav.example.test/calendars/me/personal/uid-1.ics'),
        body: 'BEGIN:VCALENDAR\r\nEND:VCALENDAR\r\n',
        contentType: 'text/calendar; charset=utf-8',
      );

      expect(putRequest!.headers['if-none-match'], '*');
      expect(putRequest!.headers['content-type'], contains('text/calendar'));
      expect(putRequest!.headers['authorization'], startsWith('Basic '));
      expect(
        result.href,
        'https://dav.example.test/calendars/me/personal/uid-1.ics',
      );
      expect(result.etag, '"abc"');
      expect(result.statusCode, 201);
    });

    test('maps 412 to ProtocolException', () async {
      final DavClient dav = DavClient(
        username: 'ada@example.test',
        password: 'secret',
        client: MockClient(
          (_) async => http.Response('Precondition Failed', 412),
        ),
      );
      addTearDown(dav.dispose);

      await expectLater(
        dav.put(
          Uri.parse('https://dav.example.test/cal/x.ics'),
          body: 'x',
          contentType: 'text/calendar; charset=utf-8',
        ),
        throwsA(
          isA<ProtocolException>().having(
            (ProtocolException e) => e.statusCode,
            'statusCode',
            412,
          ),
        ),
      );
    });
  });

  group('DavPimProvider create', () {
    test('createEvent PUTs .ics under collection href', () async {
      http.Request? putRequest;
      final http.Client client = MockClient((http.Request request) async {
        if (request.method == 'PUT') {
          putRequest = request;
          return http.Response(
            '',
            201,
            headers: const <String, String>{'etag': 'W/"ev1"'},
          );
        }
        fail('Unexpected ${request.method} ${request.url}');
      });
      final DavPimProvider provider = DavPimProvider(
        emailAddress: 'ada@example.test',
        password: 'secret',
        baseUrl: 'https://dav.example.test/',
        client: client,
      );

      final PimRemoteCreateResult created = await provider.createEvent(
        calendarProviderId: 'https://dav.example.test/calendars/me/personal/',
        event: CalendarEvent(
          id: 'local-row',
          accountId: 'dav',
          calendarId: 'cal',
          providerId: 'local:copy-uid',
          title: 'Copied',
          startEpochMs: DateTime.utc(2026, 8, 4, 10).millisecondsSinceEpoch,
          endEpochMs: DateTime.utc(2026, 8, 4, 11).millisecondsSinceEpoch,
          updatedAt: 1,
        ),
      );

      expect(putRequest, isNotNull);
      expect(
        putRequest!.url.toString(),
        'https://dav.example.test/calendars/me/personal/copy-uid.ics',
      );
      expect(putRequest!.headers['if-none-match'], '*');
      expect(putRequest!.body, contains('UID:copy-uid'));
      expect(putRequest!.body, contains('SUMMARY:Copied'));
      expect(
        created.providerId,
        'https://dav.example.test/calendars/me/personal/copy-uid.ics',
      );
      expect(created.etag, 'W/"ev1"');
    });

    test('createContact PUTs .vcf under collection href', () async {
      http.Request? putRequest;
      final http.Client client = MockClient((http.Request request) async {
        if (request.method == 'PUT') {
          putRequest = request;
          return http.Response(
            '',
            204,
            headers: const <String, String>{'etag': '"c1"'},
          );
        }
        fail('Unexpected ${request.method} ${request.url}');
      });
      final DavPimProvider provider = DavPimProvider(
        emailAddress: 'ada@example.test',
        password: 'secret',
        baseUrl: 'https://dav.example.test/',
        client: client,
      );

      final PimRemoteCreateResult created = await provider.createContact(
        folderProviderId: 'https://dav.example.test/addressbooks/me/contacts/',
        contact: Contact(
          id: 'local-row',
          accountId: 'dav',
          contactListId: 'list',
          providerId: 'local:person-uid',
          displayName: 'Ada',
          updatedAt: 1,
        ),
        emails: const <ContactEmail>[
          ContactEmail(
            id: 'e',
            contactId: 'local-row',
            address: 'ada@example.test',
          ),
        ],
      );

      expect(
        putRequest!.url.toString(),
        'https://dav.example.test/addressbooks/me/contacts/person-uid.vcf',
      );
      expect(putRequest!.headers['content-type'], contains('text/vcard'));
      expect(putRequest!.body, contains('FN:Ada'));
      expect(
        created.providerId,
        'https://dav.example.test/addressbooks/me/contacts/person-uid.vcf',
      );
      expect(created.etag, '"c1"');
    });
  });

  group('SyncEngine DAV copy', () {
    test('events_copy PUTs CalDAV create and rewrites providerId', () async {
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftMailRepository repo = DriftMailRepository(database);
      final DriftPimStore pim = DriftPimStore(database, notify: () {});

      await repo.upsertAccount(
        const MailAccount(
          id: 'dav',
          label: 'Runbox',
          address: 'd@runbox.com',
          accent: Color(0xFF112233),
          providerType: 'imap',
        ),
        providerType: 'imap',
      );

      const String calHref = 'https://dav.example/cal/';
      final String calId = PimIds.stableLocalId('dav', calHref);
      await pim.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'dav',
          providerId: calHref,
          name: 'Personal',
          colorArgb: 0xFF112233,
          isDefault: true,
        ),
      ]);
      final CalendarEvent local = await pim.createLocalEvent(
        accountId: 'dav',
        calendarId: calId,
        title: 'Copied standup',
        startEpochMs: DateTime.utc(2026, 8, 4, 15).millisecondsSinceEpoch,
        endEpochMs: DateTime.utc(2026, 8, 4, 16).millisecondsSinceEpoch,
      );
      final String uid = local.providerId.substring('local:'.length);

      http.Request? putRequest;
      final http.Client client = MockClient((http.Request request) async {
        if (request.method == 'PUT') {
          putRequest = request;
          return http.Response(
            '',
            201,
            headers: const <String, String>{'etag': '"dav-etag"'},
          );
        }
        fail('Unexpected ${request.method} ${request.url}');
      });

      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        pimStore: pim,
        resolvePim: (_) async => DavPimProvider(
          emailAddress: 'd@runbox.com',
          password: 'x',
          baseUrl: 'https://dav.example/',
          client: client,
        ),
        readConnectivity: () async =>
            const <ConnectivityResult>[ConnectivityResult.wifi],
        networkPolicy: const NetworkSyncPolicy(isDesktop: true),
      );

      await repo.enqueueSyncJob(
        accountId: 'dav',
        type: PimSyncJobs.eventsCopy,
        payloadJson: jsonEncode(<String, String>{
          'localEventId': local.id,
          'targetCalendarId': calId,
          'targetCalendarProviderId': calHref,
        }),
      );
      await engine.kick();

      expect(putRequest, isNotNull);
      expect(putRequest!.url.path, endsWith('/$uid.ics'));
      expect(putRequest!.headers['if-none-match'], '*');

      final CalendarEvent? rewritten = await pim.getEvent(local.id);
      expect(rewritten?.providerId, '$calHref$uid.ics');
      expect(rewritten?.etag, '"dav-etag"');
      expect(rewritten?.id, local.id);

      final List<SyncJob> jobs = await repo.listSyncJobs(limit: 5);
      expect(jobs.single.status, 'done');
    });

    test('contacts_copy PUTs CardDAV create and rewrites providerId', () async {
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftMailRepository repo = DriftMailRepository(database);
      final DriftPimStore pim = DriftPimStore(database, notify: () {});

      await repo.upsertAccount(
        const MailAccount(
          id: 'dav',
          label: 'Runbox',
          address: 'd@runbox.com',
          accent: Color(0xFF112233),
          providerType: 'imap',
        ),
        providerType: 'imap',
      );

      const String listHref = 'https://dav.example/ab/contacts/';
      final String listId = PimIds.stableLocalId('dav', listHref);
      await pim.upsertContactLists(<ContactList>[
        ContactList(
          id: listId,
          accountId: 'dav',
          providerId: listHref,
          name: 'Contacts',
          isDefault: true,
        ),
      ]);
      final Contact local = await pim.createLocalContact(
        accountId: 'dav',
        contactListId: listId,
        displayName: 'Ada',
        emails: const <ContactEmail>[
          ContactEmail(
            id: 'tmp',
            contactId: 'tmp',
            address: 'ada@example.test',
          ),
        ],
      );
      final String uid = local.providerId.substring('local:'.length);

      final http.Client client = MockClient((http.Request request) async {
        if (request.method == 'PUT') {
          return http.Response(
            '',
            201,
            headers: const <String, String>{'etag': '"card"'},
          );
        }
        fail('Unexpected ${request.method} ${request.url}');
      });

      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        pimStore: pim,
        resolvePim: (_) async => DavPimProvider(
          emailAddress: 'd@runbox.com',
          password: 'x',
          baseUrl: 'https://dav.example/',
          client: client,
        ),
        readConnectivity: () async =>
            const <ConnectivityResult>[ConnectivityResult.wifi],
        networkPolicy: const NetworkSyncPolicy(isDesktop: true),
      );

      await repo.enqueueSyncJob(
        accountId: 'dav',
        type: PimSyncJobs.contactsCopy,
        payloadJson: jsonEncode(<String, String>{
          'localContactId': local.id,
          'targetContactListId': listId,
          'targetContactListProviderId': listHref,
        }),
      );
      await engine.kick();

      final Contact? rewritten = await pim.getContact(local.id);
      expect(rewritten?.providerId, '${listHref}$uid.vcf');
      expect(rewritten?.etag, '"card"');
      expect((await repo.listSyncJobs(limit: 5)).single.status, 'done');
    });
  });
}
