// ==============================================================================
// File: test/dav_pim_sync_engine_test.dart
// Description: SyncEngine DAV full-pull reconciliation with local PIM storage.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/protocol/dav_pim_provider.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/sync/network_sync_policy.dart';
import 'package:synesis/sync/pim_sync_jobs.dart';
import 'package:synesis/sync/sync_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'DAV bootstrap preserves collection prefs and soft-deletes missing rows',
    () async {
      final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final DriftMailRepository repo = DriftMailRepository(database);
      final DriftPimStore store = DriftPimStore(database, notify: () {});
      await repo.upsertAccount(
        const MailAccount(
          id: 'imap',
          label: 'IMAP',
          address: 'ada@example.test',
          accent: Color(0xFF112233),
          providerType: 'imap',
        ),
        providerType: 'imap',
      );
      final _FixtureDavProvider provider = _FixtureDavProvider();
      final SyncEngine engine = SyncEngine(
        repository: repo,
        resolveProvider: (_) async => null,
        pimStore: store,
        resolvePim: (_) async => provider,
        readConnectivity: () async => const <ConnectivityResult>[
          ConnectivityResult.wifi,
        ],
        networkPolicy: const NetworkSyncPolicy(isDesktop: true),
      );
      await repo.enqueueSyncJob(
        accountId: 'imap',
        type: PimSyncJobs.contactListsBootstrap,
      );
      await repo.enqueueSyncJob(
        accountId: 'imap',
        type: PimSyncJobs.calendarsBootstrap,
      );
      await engine.kick();

      expect((await store.listContacts(accountId: 'imap')), hasLength(2));
      expect((await store.listEvents(accountId: 'imap')), hasLength(2));

      provider.removeSecond = true;
      await repo.enqueueSyncJob(
        accountId: 'imap',
        type: PimSyncJobs.contactListsIncremental,
      );
      await repo.enqueueSyncJob(
        accountId: 'imap',
        type: PimSyncJobs.calendarsIncremental,
      );
      await engine.kick();

      expect((await store.listContacts(accountId: 'imap')), hasLength(1));
      expect((await store.listEvents(accountId: 'imap')), hasLength(1));
      expect(
        (await store.listContacts(accountId: 'imap', includeDeleted: true)),
        hasLength(2),
      );
      expect(
        (await store.listEvents(accountId: 'imap', includeDeleted: true)),
        hasLength(2),
      );
      final ContactList persisted = (await store.listContactLists(
        accountId: 'imap',
      )).single;
      expect(persisted.isSelectedForDisplay, isFalse);
      expect(persisted.sortIndex, 0);
    },
  );
}

class _FixtureDavProvider extends DavPimProvider {
  _FixtureDavProvider()
    : super(
        emailAddress: 'ada@example.test',
        password: 'fixture',
        baseUrl: 'https://dav.example.test/',
      );

  static const String book = 'https://dav.example.test/books/default/';
  static const String calendar = 'https://dav.example.test/calendars/default/';
  bool removeSecond = false;

  @override
  Future<List<GraphContactFolder>> listContactFolders() async =>
      const <GraphContactFolder>[
        GraphContactFolder(providerId: book, name: 'Contacts', isDefault: true),
      ];

  @override
  Future<List<GraphCalendarInfo>> listCalendars() async =>
      const <GraphCalendarInfo>[
        GraphCalendarInfo(
          providerId: calendar,
          name: 'Calendar',
          colorArgb: 0xFF4285F4,
          isDefault: true,
        ),
      ];

  @override
  List<ContactList> mapContactFolders(
    List<GraphContactFolder> folders, {
    required String accountId,
  }) => <ContactList>[
    ContactList(
      id: PimIds.stableLocalId(accountId, book),
      accountId: accountId,
      providerId: book,
      name: 'Contacts',
      isDefault: true,
      isSelectedForDisplay: false,
      sortIndex: 0,
    ),
  ];

  @override
  Future<GraphPimDeltaResult<GraphContactBundle>> syncContacts({
    required String accountId,
    required String contactListId,
    required String folderProviderId,
    String? deltaLink,
  }) async => GraphPimDeltaResult<GraphContactBundle>(
    changed: _contacts(accountId, contactListId),
    removedProviderIds: const <String>[],
    deltaLink: 'fixture-contact-token',
  );

  @override
  Future<GraphPimDeltaResult<GraphEventBundle>> syncEvents({
    required String accountId,
    required String calendarId,
    required String calendarProviderId,
    String? deltaLink,
    DateTime? now,
  }) async => GraphPimDeltaResult<GraphEventBundle>(
    changed: _events(accountId, calendarId),
    removedProviderIds: const <String>[],
    deltaLink: 'fixture-event-token',
  );

  List<GraphContactBundle> _contacts(String accountId, String listId) =>
      List<GraphContactBundle>.generate(removeSecond ? 1 : 2, (int index) {
        final String providerId = '$book${index + 1}.vcf';
        return GraphContactBundle(
          contact: Contact(
            id: PimIds.stableLocalId(accountId, providerId),
            accountId: accountId,
            contactListId: listId,
            providerId: providerId,
            displayName: 'Person ${index + 1}',
            updatedAt: 1,
          ),
        );
      });

  List<GraphEventBundle> _events(String accountId, String calendarId) =>
      List<GraphEventBundle>.generate(removeSecond ? 1 : 2, (int index) {
        final String providerId = '$calendar${index + 1}.ics';
        return GraphEventBundle(
          event: CalendarEvent(
            id: PimIds.stableLocalId(accountId, providerId),
            accountId: accountId,
            calendarId: calendarId,
            providerId: providerId,
            title: 'Event ${index + 1}',
            startEpochMs: 1,
            endEpochMs: 2,
            updatedAt: 1,
          ),
        );
      });
}
