// ==============================================================================
// File: test/pim_store_test.dart
// Description: Empty and multi-collection fixtures for DriftPimStore read paths.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';

Future<(SynesisDatabase, DriftPimStore)> _openPimStore() async {
  final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
  await database.customSelect('SELECT 1').get();
  final DriftPimStore store = DriftPimStore(database, notify: () {});
  return (database, store);
}

Future<void> _seedAccount(SynesisDatabase database, String accountId) async {
  final DriftMailRepository repo = DriftMailRepository(database);
  await repo.upsertAccount(
    MailAccount(
      id: accountId,
      label: accountId,
      address: '$accountId@byte.io',
      accent: const Color(0xFF2DD4BF),
    ),
    providerType: 'imap',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DriftPimStore empty queries', () {
    test('list helpers return empty on fresh schema', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);

      expect(await store.listContactLists(), isEmpty);
      expect(await store.listSelectedContactLists(), isEmpty);
      expect(await store.listContacts(), isEmpty);
      expect(await store.listContactsForSelectedLists(), isEmpty);
      expect(await store.listCalendars(), isEmpty);
      expect(await store.listSelectedCalendars(), isEmpty);
      expect(await store.listEvents(), isEmpty);
      expect(await store.listEventsForSelectedCalendars(), isEmpty);
      expect(await store.calendarsGroupedByAccount(), isEmpty);
    });
  });

  group('DriftPimStore multi-list / multi-calendar', () {
    test('selected helpers filter by isSelectedForDisplay', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);

      await _seedAccount(database, 'work');
      await _seedAccount(database, 'personal');

      await store.upsertContactLists(const <ContactList>[
        ContactList(
          id: 'list-work-default',
          accountId: 'work',
          providerId: 'default',
          name: 'Contacts',
          isDefault: true,
          isSelectedForDisplay: true,
          sortIndex: 0,
        ),
        ContactList(
          id: 'list-work-hidden',
          accountId: 'work',
          providerId: 'archive',
          name: 'Archive',
          isSelectedForDisplay: false,
          sortIndex: 1,
        ),
        ContactList(
          id: 'list-personal',
          accountId: 'personal',
          providerId: 'default',
          name: 'Personal',
          isDefault: true,
          isSelectedForDisplay: true,
          sortIndex: 0,
          colorArgb: 0xFFAABBCC,
        ),
      ]);

      await store.upsertContacts(const <Contact>[
        Contact(
          id: 'c1',
          accountId: 'work',
          contactListId: 'list-work-default',
          providerId: 'p1',
          displayName: 'Alice',
          updatedAt: 1,
        ),
        Contact(
          id: 'c2',
          accountId: 'work',
          contactListId: 'list-work-hidden',
          providerId: 'p2',
          displayName: 'Bob',
          updatedAt: 2,
        ),
        Contact(
          id: 'c3',
          accountId: 'personal',
          contactListId: 'list-personal',
          providerId: 'p3',
          displayName: 'Carol',
          updatedAt: 3,
        ),
      ]);

      await store.upsertCalendars(const <Calendar>[
        Calendar(
          id: 'cal-work',
          accountId: 'work',
          providerId: 'primary',
          name: 'Work',
          colorArgb: 0xFF112233,
          isDefault: true,
          isSelectedForDisplay: true,
          sortIndex: 0,
        ),
        Calendar(
          id: 'cal-work-holidays',
          accountId: 'work',
          providerId: 'holidays',
          name: 'Holidays',
          colorArgb: 0xFF445566,
          isSelectedForDisplay: false,
          sortIndex: 1,
        ),
        Calendar(
          id: 'cal-personal',
          accountId: 'personal',
          providerId: 'primary',
          name: 'Personal',
          colorArgb: 0xFF778899,
          colorOverrideArgb: 0xFF00FF00,
          isDefault: true,
          isSelectedForDisplay: true,
          sortIndex: 0,
        ),
      ]);

      await store.upsertEvents(const <CalendarEvent>[
        CalendarEvent(
          id: 'e1',
          accountId: 'work',
          calendarId: 'cal-work',
          providerId: 'ev1',
          title: 'Standup',
          startEpochMs: 1000,
          endEpochMs: 2000,
          updatedAt: 1,
        ),
        CalendarEvent(
          id: 'e2',
          accountId: 'work',
          calendarId: 'cal-work-holidays',
          providerId: 'ev2',
          title: 'Holiday',
          startEpochMs: 3000,
          endEpochMs: 4000,
          allDay: true,
          updatedAt: 2,
        ),
        CalendarEvent(
          id: 'e3',
          accountId: 'personal',
          calendarId: 'cal-personal',
          providerId: 'ev3',
          title: 'Dentist',
          startEpochMs: 5000,
          endEpochMs: 6000,
          updatedAt: 3,
        ),
      ]);

      final List<ContactList> selectedLists =
          await store.listSelectedContactLists();
      expect(
        selectedLists.map((ContactList list) => list.id).toSet(),
        <String>{'list-work-default', 'list-personal'},
      );

      final List<Contact> selectedContacts =
          await store.listContactsForSelectedLists();
      expect(
        selectedContacts.map((Contact contact) => contact.id).toSet(),
        <String>{'c1', 'c3'},
      );

      final List<Calendar> selectedCals = await store.listSelectedCalendars();
      expect(
        selectedCals.map((Calendar calendar) => calendar.id).toSet(),
        <String>{'cal-work', 'cal-personal'},
      );

      final List<CalendarEvent> selectedEvents =
          await store.listEventsForSelectedCalendars();
      expect(
        selectedEvents.map((CalendarEvent event) => event.id).toSet(),
        <String>{'e1', 'e3'},
      );

      final Map<String, List<Calendar>> grouped =
          await store.calendarsGroupedByAccount();
      expect(grouped.keys.toSet(), <String>{'work', 'personal'});
      expect(grouped['work']!.length, 2);
      expect(grouped['personal']!.single.effectiveColorArgb, 0xFF00FF00);

      expect(await store.listContactLists(accountId: 'work'), hasLength(2));
      expect(await store.listCalendars(accountId: 'personal'), hasLength(1));
    });
  });
}
