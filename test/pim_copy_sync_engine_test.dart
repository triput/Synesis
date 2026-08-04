// ==============================================================================
// File: test/pim_copy_sync_engine_test.dart
// Description: Wave 6/6b events_copy / contacts_copy SyncEngine + PimCopyService.
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
import 'package:synesis/protocol/dav_pim_provider.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/network_sync_policy.dart';
import 'package:synesis/sync/pim_copy_service.dart';
import 'package:synesis/sync/pim_sync_jobs.dart';
import 'package:synesis/sync/sync_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SyncEngine events_copy / contacts_copy', () {
    test('events_copy POSTs Graph create and rewrites providerId', () async {
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftMailRepository repo = DriftMailRepository(database);
      final DriftPimStore pim = DriftPimStore(database, notify: () {});

      await repo.upsertAccount(
        const MailAccount(
          id: 'work',
          label: 'Work',
          address: 'work@contoso.com',
          accent: Color(0xFF0078D4),
          providerType: 'graph',
        ),
        providerType: 'graph',
      );

      final String calId = PimIds.stableLocalId('work', 'cal-1');
      await pim.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'work',
          providerId: 'cal-1',
          name: 'Calendar',
          colorArgb: 0xFF0078D4,
          isDefault: true,
        ),
      ]);
      final CalendarEvent local = await pim.createLocalEvent(
        accountId: 'work',
        calendarId: calId,
        title: 'Copied standup',
        startEpochMs: DateTime.utc(2026, 8, 4, 15).millisecondsSinceEpoch,
        endEpochMs: DateTime.utc(2026, 8, 4, 16).millisecondsSinceEpoch,
      );

      http.Request? createRequest;
      final http.Client client = MockClient((http.Request request) async {
        if (request.method == 'POST' &&
            request.url.path.contains('/calendars/') &&
            request.url.path.endsWith('/events')) {
          createRequest = request;
          return http.Response(
            jsonEncode(<String, Object?>{
              'id': 'remote-ev-42',
              '@odata.etag': 'W/"etag-1"',
            }),
            201,
            headers: const <String, String>{
              'content-type': 'application/json',
            },
          );
        }
        fail('Unexpected Graph URL: ${request.method} ${request.url}');
      });

      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        pimStore: pim,
        resolvePim: (_) async => GraphPimProvider(
          () async => 'token',
          client: client,
        ),
        readConnectivity: () async =>
            const <ConnectivityResult>[ConnectivityResult.wifi],
        networkPolicy: const NetworkSyncPolicy(isDesktop: true),
      );

      await repo.enqueueSyncJob(
        accountId: 'work',
        type: PimSyncJobs.eventsCopy,
        payloadJson: jsonEncode(<String, String>{
          'localEventId': local.id,
          'targetCalendarId': calId,
          'targetCalendarProviderId': 'cal-1',
        }),
      );
      await engine.kick();

      expect(createRequest, isNotNull);
      final Object? body = jsonDecode(createRequest!.body);
      expect(body, isA<Map<Object?, Object?>>());
      expect((body as Map<Object?, Object?>)['subject'], 'Copied standup');
      expect(body.containsKey('attendees'), isFalse);
      expect(body.containsKey('recurrence'), isFalse);

      final CalendarEvent? rewritten = await pim.getEvent(local.id);
      expect(rewritten?.providerId, 'remote-ev-42');
      expect(rewritten?.etag, 'W/"etag-1"');
      expect(rewritten?.id, local.id);

      final List<SyncJob> jobs = await repo.listSyncJobs(limit: 5);
      expect(jobs.single.status, 'done');
    });

    test('contacts_copy POSTs Graph create and rewrites providerId', () async {
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftMailRepository repo = DriftMailRepository(database);
      final DriftPimStore pim = DriftPimStore(database, notify: () {});

      await repo.upsertAccount(
        const MailAccount(
          id: 'work',
          label: 'Work',
          address: 'work@contoso.com',
          accent: Color(0xFF0078D4),
          providerType: 'graph',
        ),
        providerType: 'graph',
      );

      final String listId = PimIds.stableLocalId('work', 'folder-1');
      await pim.upsertContactLists(<ContactList>[
        ContactList(
          id: listId,
          accountId: 'work',
          providerId: 'folder-1',
          name: 'Contacts',
          isDefault: true,
        ),
      ]);
      final Contact local = await pim.createLocalContact(
        accountId: 'work',
        contactListId: listId,
        displayName: 'Grace Hopper',
        givenName: 'Grace',
        familyName: 'Hopper',
        emails: const <ContactEmail>[
          ContactEmail(
            id: 'tmp',
            contactId: 'tmp',
            address: 'grace@navy.mil',
            isPrimary: true,
          ),
        ],
      );

      final http.Client client = MockClient((http.Request request) async {
        expect(request.method, 'POST');
        expect(request.url.path, contains('/contactFolders/'));
        expect(request.url.path, endsWith('/contacts'));
        return http.Response(
          jsonEncode(<String, Object?>{
            'id': 'remote-c-7',
            '@odata.etag': 'W/"c-etag"',
          }),
          201,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      });

      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        pimStore: pim,
        resolvePim: (_) async => GraphPimProvider(
          () async => 'token',
          client: client,
        ),
        readConnectivity: () async =>
            const <ConnectivityResult>[ConnectivityResult.wifi],
        networkPolicy: const NetworkSyncPolicy(isDesktop: true),
      );

      await repo.enqueueSyncJob(
        accountId: 'work',
        type: PimSyncJobs.contactsCopy,
        payloadJson: jsonEncode(<String, String>{
          'localContactId': local.id,
          'targetContactListId': listId,
          'targetContactListProviderId': 'folder-1',
        }),
      );
      await engine.kick();

      final Contact? rewritten = await pim.getContact(local.id);
      expect(rewritten?.providerId, 'remote-c-7');
      expect(rewritten?.id, local.id);
    });

    test('events_copy is idempotent when providerId already remote', () async {
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftMailRepository repo = DriftMailRepository(database);
      final DriftPimStore pim = DriftPimStore(database, notify: () {});

      await repo.upsertAccount(
        const MailAccount(
          id: 'work',
          label: 'Work',
          address: 'work@contoso.com',
          accent: Color(0xFF0078D4),
          providerType: 'graph',
        ),
        providerType: 'graph',
      );
      final String calId = PimIds.stableLocalId('work', 'cal-1');
      await pim.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'work',
          providerId: 'cal-1',
          name: 'Calendar',
          colorArgb: 0xFF0078D4,
          isDefault: true,
        ),
      ]);
      final CalendarEvent local = await pim.createLocalEvent(
        accountId: 'work',
        calendarId: calId,
        title: 'Already pushed',
        startEpochMs: 1000,
        endEpochMs: 2000,
        providerId: 'already-remote',
      );

      var postCount = 0;
      final http.Client client = MockClient((http.Request request) async {
        postCount++;
        fail('Should not POST when already remote: ${request.url}');
      });

      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        pimStore: pim,
        resolvePim: (_) async => GraphPimProvider(
          () async => 'token',
          client: client,
        ),
        readConnectivity: () async =>
            const <ConnectivityResult>[ConnectivityResult.wifi],
        networkPolicy: const NetworkSyncPolicy(isDesktop: true),
      );

      await repo.enqueueSyncJob(
        accountId: 'work',
        type: PimSyncJobs.eventsCopy,
        payloadJson: jsonEncode(<String, String>{
          'localEventId': local.id,
          'targetCalendarId': calId,
          'targetCalendarProviderId': 'cal-1',
        }),
      );
      await engine.kick();
      expect(postCount, 0);
      expect((await pim.getEvent(local.id))?.providerId, 'already-remote');
    });

    test('events_copy skips soft-deleted local row (undo before push)', () async {
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftMailRepository repo = DriftMailRepository(database);
      final DriftPimStore pim = DriftPimStore(database, notify: () {});

      await repo.upsertAccount(
        const MailAccount(
          id: 'work',
          label: 'Work',
          address: 'work@contoso.com',
          accent: Color(0xFF0078D4),
          providerType: 'graph',
        ),
        providerType: 'graph',
      );
      final String calId = PimIds.stableLocalId('work', 'cal-1');
      await pim.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'work',
          providerId: 'cal-1',
          name: 'Calendar',
          colorArgb: 0xFF0078D4,
          isDefault: true,
        ),
      ]);
      final CalendarEvent local = await pim.createLocalEvent(
        accountId: 'work',
        calendarId: calId,
        title: 'Undo me',
        startEpochMs: 1000,
        endEpochMs: 2000,
      );
      await pim.softDeleteEvent(local.id);

      var postCount = 0;
      final http.Client client = MockClient((http.Request request) async {
        postCount++;
        fail('Should not POST soft-deleted copy: ${request.url}');
      });

      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        pimStore: pim,
        resolvePim: (_) async => GraphPimProvider(
          () async => 'token',
          client: client,
        ),
        readConnectivity: () async =>
            const <ConnectivityResult>[ConnectivityResult.wifi],
        networkPolicy: const NetworkSyncPolicy(isDesktop: true),
      );

      await repo.enqueueSyncJob(
        accountId: 'work',
        type: PimSyncJobs.eventsCopy,
        payloadJson: jsonEncode(<String, String>{
          'localEventId': local.id,
          'targetCalendarId': calId,
          'targetCalendarProviderId': 'cal-1',
        }),
      );
      await engine.kick();
      expect(postCount, 0);
      expect(
        (await pim.getEvent(local.id))?.providerId,
        startsWith('local:'),
      );
    });
  });

  group('PimCopyService', () {
    test('enqueues events_copy for Graph target', () async {
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftMailRepository repo = DriftMailRepository(database);
      final DriftPimStore pim = DriftPimStore(database, notify: () {});

      await repo.upsertAccount(
        const MailAccount(
          id: 'a',
          label: 'A',
          address: 'a@contoso.com',
          accent: Color(0xFF0078D4),
          providerType: 'graph',
        ),
        providerType: 'graph',
      );
      await repo.upsertAccount(
        const MailAccount(
          id: 'b',
          label: 'B',
          address: 'b@contoso.com',
          accent: Color(0xFF0078D4),
          providerType: 'graph',
        ),
        providerType: 'graph',
      );

      final String calA = PimIds.stableLocalId('a', 'cal');
      final String calB = PimIds.stableLocalId('b', 'cal');
      await pim.upsertCalendars(<Calendar>[
        Calendar(
          id: calA,
          accountId: 'a',
          providerId: 'cal',
          name: 'A',
          colorArgb: 0xFF0078D4,
          isDefault: true,
        ),
        Calendar(
          id: calB,
          accountId: 'b',
          providerId: 'cal',
          name: 'B',
          colorArgb: 0xFF0078D4,
          isDefault: true,
        ),
      ]);
      final CalendarEvent source = await pim.createLocalEvent(
        accountId: 'a',
        calendarId: calA,
        title: 'Source',
        startEpochMs: 1000,
        endEpochMs: 2000,
      );

      final PimCopyService service = PimCopyService(
        pimStore: pim,
        repository: repo,
        resolvePim: (_) async => GraphPimProvider(() async => 'token'),
      );

      final PimCopyResult<CalendarEvent> result = await service
          .copyEventToCalendar(
            sourceEventId: source.id,
            targetAccountId: 'b',
            targetCalendarId: calB,
          );

      expect(result.remotePushEnqueued, isTrue);
      expect(result.entity.accountId, 'b');
      expect(result.entity.providerId, startsWith('local:'));

      final List<SyncJob> jobs = await repo.listSyncJobs(limit: 10);
      expect(
        jobs.where((SyncJob j) => j.type == PimSyncJobs.eventsCopy),
        hasLength(1),
      );
    });

    test('enqueues events_copy for DAV target', () async {
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftMailRepository repo = DriftMailRepository(database);
      final DriftPimStore pim = DriftPimStore(database, notify: () {});

      await repo.upsertAccount(
        const MailAccount(
          id: 'graph',
          label: 'Graph',
          address: 'g@contoso.com',
          accent: Color(0xFF0078D4),
          providerType: 'graph',
        ),
        providerType: 'graph',
      );
      await repo.upsertAccount(
        const MailAccount(
          id: 'dav',
          label: 'DAV',
          address: 'd@runbox.com',
          accent: Color(0xFF112233),
          providerType: 'imap',
        ),
        providerType: 'imap',
      );

      const String davCalProviderId = 'https://dav.example/cal/';
      final String calGraph = PimIds.stableLocalId('graph', 'cal');
      final String calDav = PimIds.stableLocalId('dav', davCalProviderId);
      await pim.upsertCalendars(<Calendar>[
        Calendar(
          id: calGraph,
          accountId: 'graph',
          providerId: 'cal',
          name: 'Graph',
          colorArgb: 0xFF0078D4,
          isDefault: true,
        ),
        Calendar(
          id: calDav,
          accountId: 'dav',
          providerId: davCalProviderId,
          name: 'DAV',
          colorArgb: 0xFF112233,
          isDefault: true,
        ),
      ]);
      final CalendarEvent source = await pim.createLocalEvent(
        accountId: 'graph',
        calendarId: calGraph,
        title: 'Source',
        startEpochMs: 1000,
        endEpochMs: 2000,
      );

      final PimCopyService service = PimCopyService(
        pimStore: pim,
        repository: repo,
        resolvePim: (String accountId) async {
          if (accountId == 'dav') {
            return DavPimProvider(
              emailAddress: 'd@runbox.com',
              password: 'x',
              baseUrl: 'https://dav.example/',
            );
          }
          return GraphPimProvider(() async => 'token');
        },
      );

      final PimCopyResult<CalendarEvent> result = await service
          .copyEventToCalendar(
            sourceEventId: source.id,
            targetAccountId: 'dav',
            targetCalendarId: calDav,
          );

      expect(result.remotePushEnqueued, isTrue);
      expect(result.entity.providerId, startsWith('local:'));
      final List<SyncJob> jobs = await repo.listSyncJobs(limit: 10);
      expect(
        jobs.where((SyncJob j) => j.type == PimSyncJobs.eventsCopy),
        hasLength(1),
      );
    });
  });

  group('full-pull soft-delete preserves local:*', () {
    test('Google-style missing soft-delete skips local provider ids', () async {
      // Exercise the same filter SyncEngine applies via a store-level assert
      // that local copies remain after a snapshot soft-delete of remotes.
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftPimStore pim = DriftPimStore(database, notify: () {});
      final DriftMailRepository repo = DriftMailRepository(database);
      await repo.upsertAccount(
        const MailAccount(
          id: 'g',
          label: 'G',
          address: 'g@gmail.com',
          accent: Color(0xFF4285F4),
          providerType: 'imap',
        ),
        providerType: 'imap',
      );
      final String calId = PimIds.stableLocalId('g', 'primary');
      await pim.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'g',
          providerId: 'primary',
          name: 'Primary',
          colorArgb: 0xFF4285F4,
          isDefault: true,
        ),
      ]);
      final CalendarEvent localCopy = await pim.createLocalEvent(
        accountId: 'g',
        calendarId: calId,
        title: 'Unpushed copy',
        startEpochMs: 1000,
        endEpochMs: 2000,
      );
      await pim.upsertEvents(<CalendarEvent>[
        CalendarEvent(
          id: PimIds.stableLocalId('g', 'remote-old'),
          accountId: 'g',
          calendarId: calId,
          providerId: 'remote-old',
          title: 'Gone from server',
          startEpochMs: 3000,
          endEpochMs: 4000,
          updatedAt: 1,
        ),
      ]);

      final Set<String> remoteIds = <String>{}; // empty snapshot
      final int now = DateTime.now().millisecondsSinceEpoch;
      final List<CalendarEvent> missing = (await pim.listEvents(
        accountId: 'g',
        calendarId: calId,
      ))
          .where(
            (CalendarEvent event) =>
                !PimIds.isLocalProviderId(event.providerId) &&
                !remoteIds.contains(event.providerId),
          )
          .map(
            (CalendarEvent event) => CalendarEvent(
              id: event.id,
              accountId: event.accountId,
              calendarId: event.calendarId,
              providerId: event.providerId,
              title: event.title,
              startEpochMs: event.startEpochMs,
              endEpochMs: event.endEpochMs,
              updatedAt: now,
              deletedAt: now,
            ),
          )
          .toList(growable: false);
      await pim.upsertEvents(missing);

      expect(await pim.getEvent(localCopy.id), isNotNull);
      expect(
        (await pim.getEvent(localCopy.id))!.deletedAt,
        isNull,
      );
      expect(
        await pim.findEventByProviderId(
          accountId: 'g',
          providerId: 'remote-old',
        ),
        isNotNull,
      );
      expect(
        (await pim.findEventByProviderId(
          accountId: 'g',
          providerId: 'remote-old',
        ))!.deletedAt,
        isNotNull,
      );
    });
  });
}
