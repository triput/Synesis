// ==============================================================================
// File: test/google_pim_sync_engine_test.dart
// Description: SyncEngine Google PIM bootstrap fan-out into DriftPimStore.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
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
import 'package:synesis/protocol/google_pim_provider.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/network_sync_policy.dart';
import 'package:synesis/sync/pim_sync_jobs.dart';
import 'package:synesis/sync/sync_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Google contact_lists_bootstrap upserts lists and enqueues contacts jobs',
    () async {
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftMailRepository repo = DriftMailRepository(database);
      final DriftPimStore pim = DriftPimStore(database, notify: () {});

      await repo.upsertAccount(
        const MailAccount(
          id: 'g1',
          label: 'Gmail',
          address: 'trish@gmail.com',
          accent: Color(0xFFEA4335),
          providerType: 'imap',
          credentialsRef: 'google:g1',
        ),
        providerType: 'imap',
      );

      final http.Client client = MockClient((http.Request request) async {
        if (request.url.path.contains('/contactGroups') &&
            !request.url.path.contains('/people')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'contactGroups': <Map<String, Object>>[
                <String, Object>{
                  'resourceName': 'contactGroups/myContacts',
                  'name': 'My Contacts',
                  'groupType': 'SYSTEM_CONTACT_GROUP',
                },
              ],
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/people/me/connections')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'connections': <Object>[],
              'nextSyncToken': 'seed',
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }
        fail('Unexpected Google URL: ${request.url}');
      });

      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        pimStore: pim,
        resolvePim: (_) async => GooglePimProvider(
          () async => 'token',
          client: client,
        ),
        readConnectivity: () async =>
            const <ConnectivityResult>[ConnectivityResult.wifi],
        networkPolicy: const NetworkSyncPolicy(isDesktop: true),
      );

      await repo.enqueueSyncJob(
        accountId: 'g1',
        type: PimSyncJobs.contactListsBootstrap,
      );
      await engine.kick();

      final List<ContactList> lists =
          await pim.listContactLists(accountId: 'g1');
      expect(lists, hasLength(1));
      expect(
        lists.single.id,
        PimIds.stableLocalId('g1', kGoogleMyContactsGroupId),
      );

      final List<SyncJob> jobs = await repo.listSyncJobs(limit: 20);
      expect(
        jobs.any((SyncJob job) => job.type == PimSyncJobs.contactsBootstrap),
        isTrue,
      );
    },
  );

  test(
    'Google calendars_bootstrap enqueues events; soft-deletes missing on window',
    () async {
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftMailRepository repo = DriftMailRepository(database);
      final DriftPimStore pim = DriftPimStore(database, notify: () {});

      await repo.upsertAccount(
        const MailAccount(
          id: 'g1',
          label: 'Gmail',
          address: 'trish@gmail.com',
          accent: Color(0xFFEA4335),
          providerType: 'imap',
          credentialsRef: 'google:g1',
        ),
        providerType: 'imap',
      );

      final String calId = PimIds.stableLocalId('g1', 'primary');
      await pim.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'g1',
          providerId: 'primary',
          name: 'Primary',
          colorArgb: kGoogleDefaultCalendarColorArgb,
          isDefault: true,
          isSelectedForDisplay: false,
          sortIndex: 3,
        ),
      ]);
      await pim.upsertEvents(<CalendarEvent>[
        CalendarEvent(
          id: PimIds.stableLocalId('g1', 'ev-old'),
          accountId: 'g1',
          calendarId: calId,
          providerId: 'ev-old',
          title: 'Gone',
          startEpochMs: DateTime.utc(2026, 7, 20).millisecondsSinceEpoch,
          endEpochMs: DateTime.utc(2026, 7, 20, 1).millisecondsSinceEpoch,
          updatedAt: DateTime.utc(2026, 7, 20).millisecondsSinceEpoch,
        ),
      ]);

      int eventPulls = 0;
      final http.Client client = MockClient((http.Request request) async {
        if (request.url.path.contains('/calendarList')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'items': <Map<String, Object>>[
                <String, Object>{
                  'id': 'primary',
                  'summary': 'Primary',
                  'primary': true,
                  'backgroundColor': '#4285f4',
                },
              ],
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }
        if (request.url.path.contains('/events')) {
          eventPulls += 1;
          return http.Response(
            jsonEncode(<String, Object>{
              'items': <Map<String, Object>>[
                <String, Object>{
                  'id': 'ev-keep',
                  'summary': 'Keep',
                  'start': <String, String>{
                    'dateTime': '2026-07-28T10:00:00Z',
                  },
                  'end': <String, String>{
                    'dateTime': '2026-07-28T11:00:00Z',
                  },
                },
              ],
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }
        fail('Unexpected Google URL: ${request.url}');
      });

      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        pimStore: pim,
        resolvePim: (_) async => GooglePimProvider(
          () async => 'token',
          client: client,
        ),
        readConnectivity: () async =>
            const <ConnectivityResult>[ConnectivityResult.wifi],
        networkPolicy: const NetworkSyncPolicy(isDesktop: true),
      );

      await repo.enqueueSyncJob(
        accountId: 'g1',
        type: PimSyncJobs.calendarsBootstrap,
      );
      await engine.kick();

      expect(eventPulls, greaterThan(0));
      final List<Calendar> calendars = await pim.listCalendars(accountId: 'g1');
      expect(calendars.single.isSelectedForDisplay, isFalse);
      expect(calendars.single.sortIndex, 3);

      final List<CalendarEvent> live =
          await pim.listEvents(accountId: 'g1', calendarId: calId);
      expect(live.map((CalendarEvent e) => e.providerId), <String>['ev-keep']);
      expect(
        (await pim.listEvents(
          accountId: 'g1',
          calendarId: calId,
          includeDeleted: true,
        )).length,
        2,
      );
    },
  );
}
