// ==============================================================================
// File: test/pim_store_test.dart
// Description: Empty, multi-collection, and preserve-on-upsert fixtures for DriftPimStore.
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
import 'package:synesis/domain/pim_ids.dart';
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

String _id(String accountId, String providerId) =>
    DriftPimStore.stableLocalId(accountId, providerId);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PimIds.stableLocalId', () {
    test('is deterministic for accountId + providerId', () {
      expect(
        PimIds.stableLocalId('work', 'default'),
        PimIds.stableLocalId('work', 'default'),
      );
      expect(
        PimIds.stableLocalId('work', 'default'),
        isNot(PimIds.stableLocalId('personal', 'default')),
      );
      expect(
        DriftPimStore.stableLocalId('a', 'b'),
        PimIds.stableLocalId('a', 'b'),
      );
    });
  });

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

      final String listWorkDefault = _id('work', 'default');
      final String listWorkHidden = _id('work', 'archive');
      final String listPersonal = _id('personal', 'default');
      final String calWork = _id('work', 'primary');
      final String calWorkHolidays = _id('work', 'holidays');
      final String calPersonal = _id('personal', 'primary');
      final String c1 = _id('work', 'p1');
      final String c2 = _id('work', 'p2');
      final String c3 = _id('personal', 'p3');
      final String e1 = _id('work', 'ev1');
      final String e2 = _id('work', 'ev2');
      final String e3 = _id('personal', 'ev3');

      await store.upsertContactLists(<ContactList>[
        ContactList(
          id: listWorkDefault,
          accountId: 'work',
          providerId: 'default',
          name: 'Contacts',
          isDefault: true,
          isSelectedForDisplay: true,
          sortIndex: 0,
        ),
        ContactList(
          id: listWorkHidden,
          accountId: 'work',
          providerId: 'archive',
          name: 'Archive',
          isSelectedForDisplay: false,
          sortIndex: 1,
        ),
        ContactList(
          id: listPersonal,
          accountId: 'personal',
          providerId: 'default',
          name: 'Personal',
          isDefault: true,
          isSelectedForDisplay: true,
          sortIndex: 0,
          colorArgb: 0xFFAABBCC,
        ),
      ]);

      await store.upsertContacts(<Contact>[
        Contact(
          id: c1,
          accountId: 'work',
          contactListId: listWorkDefault,
          providerId: 'p1',
          displayName: 'Alice',
          updatedAt: 1,
        ),
        Contact(
          id: c2,
          accountId: 'work',
          contactListId: listWorkHidden,
          providerId: 'p2',
          displayName: 'Bob',
          updatedAt: 2,
        ),
        Contact(
          id: c3,
          accountId: 'personal',
          contactListId: listPersonal,
          providerId: 'p3',
          displayName: 'Carol',
          updatedAt: 3,
        ),
      ]);

      await store.upsertCalendars(<Calendar>[
        Calendar(
          id: calWork,
          accountId: 'work',
          providerId: 'primary',
          name: 'Work',
          colorArgb: 0xFF112233,
          isDefault: true,
          isSelectedForDisplay: true,
          sortIndex: 0,
        ),
        Calendar(
          id: calWorkHolidays,
          accountId: 'work',
          providerId: 'holidays',
          name: 'Holidays',
          colorArgb: 0xFF445566,
          isSelectedForDisplay: false,
          sortIndex: 1,
        ),
        Calendar(
          id: calPersonal,
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

      await store.upsertEvents(<CalendarEvent>[
        CalendarEvent(
          id: e1,
          accountId: 'work',
          calendarId: calWork,
          providerId: 'ev1',
          title: 'Standup',
          startEpochMs: 1000,
          endEpochMs: 2000,
          updatedAt: 1,
        ),
        CalendarEvent(
          id: e2,
          accountId: 'work',
          calendarId: calWorkHolidays,
          providerId: 'ev2',
          title: 'Holiday',
          startEpochMs: 3000,
          endEpochMs: 4000,
          allDay: true,
          updatedAt: 2,
        ),
        CalendarEvent(
          id: e3,
          accountId: 'personal',
          calendarId: calPersonal,
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
        <String>{listWorkDefault, listPersonal},
      );

      final List<Contact> selectedContacts =
          await store.listContactsForSelectedLists();
      expect(
        selectedContacts.map((Contact contact) => contact.id).toSet(),
        <String>{c1, c3},
      );

      final List<Calendar> selectedCals = await store.listSelectedCalendars();
      expect(
        selectedCals.map((Calendar calendar) => calendar.id).toSet(),
        <String>{calWork, calPersonal},
      );

      final List<CalendarEvent> selectedEvents =
          await store.listEventsForSelectedCalendars();
      expect(
        selectedEvents.map((CalendarEvent event) => event.id).toSet(),
        <String>{e1, e3},
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

  group('DriftPimStore preserve-on-upsert', () {
    test('contact list display prefs survive provider refresh', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');

      await store.upsertContactLists(const <ContactList>[
        ContactList(
          id: 'ignored-on-insert',
          accountId: 'work',
          providerId: 'default',
          name: 'Contacts',
          isDefault: true,
          isSelectedForDisplay: false,
          sortIndex: 7,
          colorArgb: 0xFF111111,
        ),
      ]);

      final ContactList? inserted = await store.findContactListByProviderId(
        accountId: 'work',
        providerId: 'default',
      );
      expect(inserted, isNotNull);
      expect(inserted!.id, _id('work', 'default'));
      expect(inserted.isSelectedForDisplay, isFalse);
      expect(inserted.sortIndex, 7);

      // Provider refresh with different display defaults + renamed list.
      await store.upsertContactLists(const <ContactList>[
        ContactList(
          id: 'different-caller-id',
          accountId: 'work',
          providerId: 'default',
          name: 'All Contacts',
          isDefault: true,
          isSelectedForDisplay: true,
          sortIndex: 0,
          colorArgb: 0xFF222222,
        ),
      ]);

      final List<ContactList> lists = await store.listContactLists(
        accountId: 'work',
      );
      expect(lists, hasLength(1));
      expect(lists.single.id, _id('work', 'default'));
      expect(lists.single.name, 'All Contacts');
      expect(lists.single.colorArgb, 0xFF222222);
      expect(lists.single.isSelectedForDisplay, isFalse);
      expect(lists.single.sortIndex, 7);
    });

    test('calendar display prefs survive provider refresh', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');

      await store.upsertCalendars(const <Calendar>[
        Calendar(
          id: 'ignored-on-insert',
          accountId: 'work',
          providerId: 'primary',
          name: 'Calendar',
          colorArgb: 0xFF112233,
          colorOverrideArgb: 0xFF00FF00,
          isDefault: true,
          isSelectedForDisplay: false,
          sortIndex: 3,
        ),
      ]);

      final Calendar? inserted = await store.findCalendarByProviderId(
        accountId: 'work',
        providerId: 'primary',
      );
      expect(inserted, isNotNull);
      expect(inserted!.id, _id('work', 'primary'));
      expect(inserted.colorOverrideArgb, 0xFF00FF00);
      expect(inserted.isSelectedForDisplay, isFalse);
      expect(inserted.sortIndex, 3);

      await store.upsertCalendars(const <Calendar>[
        Calendar(
          id: 'different-caller-id',
          accountId: 'work',
          providerId: 'primary',
          name: 'Work Calendar',
          colorArgb: 0xFF445566,
          colorOverrideArgb: 0xFFFF0000,
          isDefault: true,
          isSelectedForDisplay: true,
          sortIndex: 0,
        ),
      ]);

      final List<Calendar> calendars = await store.listCalendars(
        accountId: 'work',
      );
      expect(calendars, hasLength(1));
      expect(calendars.single.id, _id('work', 'primary'));
      expect(calendars.single.name, 'Work Calendar');
      expect(calendars.single.colorArgb, 0xFF445566);
      expect(calendars.single.colorOverrideArgb, 0xFF00FF00);
      expect(calendars.single.isSelectedForDisplay, isFalse);
      expect(calendars.single.sortIndex, 3);
    });

    test('contact upsert by providerId avoids duplicate rows', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');

      final String listId = _id('work', 'default');
      await store.upsertContactLists(<ContactList>[
        ContactList(
          id: listId,
          accountId: 'work',
          providerId: 'default',
          name: 'Contacts',
          isDefault: true,
        ),
      ]);

      await store.upsertContacts(<Contact>[
        Contact(
          id: 'caller-a',
          accountId: 'work',
          contactListId: listId,
          providerId: 'p1',
          displayName: 'Alice',
          updatedAt: 1,
        ),
      ]);
      await store.upsertContacts(<Contact>[
        Contact(
          id: 'caller-b',
          accountId: 'work',
          contactListId: listId,
          providerId: 'p1',
          displayName: 'Alice Updated',
          updatedAt: 2,
        ),
      ]);

      final List<Contact> contacts = await store.listContacts(accountId: 'work');
      expect(contacts, hasLength(1));
      expect(contacts.single.id, _id('work', 'p1'));
      expect(contacts.single.displayName, 'Alice Updated');
    });
  });
}
