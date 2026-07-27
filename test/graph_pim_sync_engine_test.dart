// ==============================================================================
// File: test/graph_pim_sync_engine_test.dart
// Description: SyncEngine Graph PIM job handlers with a fake GraphPimProvider.
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
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/network_sync_policy.dart';
import 'package:synesis/sync/pim_sync_jobs.dart';
import 'package:synesis/sync/sync_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('contact_lists_bootstrap upserts lists and enqueues contacts jobs',
      () async {
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

    final http.Client client = MockClient((http.Request request) async {
      if (request.url.path.contains('/contactFolders') &&
          !request.url.path.contains('/contacts')) {
        return http.Response(
          jsonEncode(<String, Object>{
            'value': <Map<String, Object>>[
              <String, Object>{
                'id': 'folder-1',
                'displayName': 'Contacts',
              },
            ],
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      // Fan-out contacts_bootstrap from the same kick loop.
      if (request.url.path.contains('/contacts')) {
        return http.Response(
          jsonEncode(<String, Object>{
            'value': <Object>[],
            r'@odata.deltaLink':
                'https://graph.microsoft.com/v1.0/me/contactFolders/folder-1/contacts/delta?\$deltatoken=seed',
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      fail('Unexpected Graph URL: ${request.url}');
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
      type: PimSyncJobs.contactListsBootstrap,
    );
    await engine.kick();

    final List<ContactList> lists = await pim.listContactLists(accountId: 'work');
    expect(lists, hasLength(1));
    expect(lists.single.id, PimIds.stableLocalId('work', 'folder-1'));

    final List<SyncJob> jobs = await repo.listSyncJobs(limit: 20);
    expect(
      jobs.any((SyncJob job) => job.type == PimSyncJobs.contactsBootstrap),
      isTrue,
    );
  });

  test('contacts_bootstrap writes contacts and preserves list display prefs',
      () async {
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
        isSelectedForDisplay: false,
        sortIndex: 9,
      ),
    ]);

    final http.Client client = MockClient((http.Request request) async {
      expect(request.url.path, contains('/contactFolders/'));
      expect(request.url.path, contains('/contacts/delta'));
      return http.Response(
        jsonEncode(<String, Object>{
          'value': <Map<String, Object>>[
            <String, Object>{
              'id': 'person-1',
              'displayName': 'Ada',
              'emailAddresses': <Map<String, String>>[
                <String, String>{'address': 'ada@example.com'},
              ],
              'lastModifiedDateTime': '2026-07-27T12:00:00Z',
            },
          ],
          r'@odata.deltaLink':
              'https://graph.microsoft.com/v1.0/me/contactFolders/folder-1/contacts/delta?\$deltatoken=x',
        }),
        200,
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
      type: PimSyncJobs.contactsBootstrap,
      payloadJson: jsonEncode(<String, String>{
        'contactListId': listId,
        'providerId': 'folder-1',
      }),
    );
    await engine.kick();

    final List<Contact> contacts = await pim.listContacts(accountId: 'work');
    expect(contacts, hasLength(1));
    expect(contacts.single.displayName, 'Ada');
    expect(contacts.single.contactListId, listId);

    final List<ContactEmail> emails =
        await pim.listContactEmails(contacts.single.id);
    expect(emails.single.address, 'ada@example.com');

    // Display prefs on the list must survive unrelated contact sync.
    final ContactList list = (await pim.listContactLists(accountId: 'work')).single;
    expect(list.isSelectedForDisplay, isFalse);
    expect(list.sortIndex, 9);

    final String? cursor = await repo.getCursor(
      'work',
      listId,
      PimSyncJobs.contactsCursorKey(listId),
    );
    expect(cursor, contains('deltatoken=x'));
  });

  test('calendars_bootstrap enqueues events jobs; push stays no-op', () async {
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

    final http.Client client = MockClient((http.Request request) async {
      if (request.url.path.contains('/me/calendars') &&
          !request.url.path.contains('/calendarView') &&
          !request.url.path.contains('/events')) {
        return http.Response(
          jsonEncode(<String, Object>{
            'value': <Map<String, Object>>[
              <String, Object>{
                'id': 'cal-1',
                'name': 'Calendar',
                'hexColor': '#0078D4',
                'isDefaultCalendar': true,
              },
            ],
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      if (request.url.path.contains('/calendarView') ||
          request.url.path.contains('/events')) {
        return http.Response(
          jsonEncode(<String, Object>{
            'value': <Object>[],
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      fail('Unexpected Graph URL: ${request.url}');
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
      type: PimSyncJobs.calendarsBootstrap,
    );
    await repo.enqueueSyncJob(
      accountId: 'work',
      type: PimSyncJobs.contactsPush,
    );
    await engine.kick();

    final List<Calendar> calendars = await pim.listCalendars(accountId: 'work');
    expect(calendars, hasLength(1));
    expect(calendars.single.providerId, 'cal-1');

    final List<SyncJob> jobs = await repo.listSyncJobs(limit: 30);
    expect(
      jobs.any((SyncJob job) => job.type == PimSyncJobs.eventsBootstrap),
      isTrue,
    );
  });

  test('enqueuePimBootstrap only for graph accounts', () async {
    final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final DriftMailRepository repo = DriftMailRepository(database);

    await repo.upsertAccount(
      const MailAccount(
        id: 'imap',
        label: 'IMAP',
        address: 'a@example.com',
        accent: Color(0xFF112233),
        providerType: 'imap',
      ),
      providerType: 'imap',
    );
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

    final SyncEngine engine = SyncEngine(
      repository: repo,
      resolveProvider: (_) async => null,
      readConnectivity: () async =>
          const <ConnectivityResult>[ConnectivityResult.wifi],
      networkPolicy: const NetworkSyncPolicy(isDesktop: true),
    );

    await engine.enqueuePimBootstrap('imap');
    await engine.enqueuePimBootstrap('graph');

    final List<SyncJob> jobs = await repo.listSyncJobs(limit: 20);
    expect(
      jobs.where((SyncJob j) => j.accountId == 'imap'),
      isEmpty,
    );
    expect(
      jobs
          .where((SyncJob j) => j.accountId == 'graph')
          .map((SyncJob j) => j.type)
          .toSet(),
      <String>{
        PimSyncJobs.contactListsBootstrap,
        PimSyncJobs.calendarsBootstrap,
      },
    );
  });
}
