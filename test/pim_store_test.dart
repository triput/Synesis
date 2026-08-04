// ==============================================================================
// File: test/pim_store_test.dart
// Description: Empty, multi-collection, and preserve-on-upsert fixtures for DriftPimStore.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-08-04
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

  group('DriftPimStore.searchContacts', () {
    Future<
      (
        SynesisDatabase database,
        DriftPimStore store,
        String listVisible,
        String listHidden,
      )
    >
    seedTwoLists() async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      await _seedAccount(database, 'work');
      final String listVisible = _id('work', 'default');
      final String listHidden = _id('work', 'archive');
      await store.upsertContactLists(<ContactList>[
        ContactList(
          id: listVisible,
          accountId: 'work',
          providerId: 'default',
          name: 'Contacts',
          isDefault: true,
        ),
        ContactList(
          id: listHidden,
          accountId: 'work',
          providerId: 'archive',
          name: 'Archive',
          isSelectedForDisplay: false,
        ),
      ]);
      return (database, store, listVisible, listHidden);
    }

    test('finds contacts by display name via FTS', () async {
      final (
        SynesisDatabase database,
        DriftPimStore store,
        String listVisible,
        _,
      ) = await seedTwoLists();
      addTearDown(database.close);

      final String aliceId = _id('work', 'p1');
      await store.upsertContacts(<Contact>[
        Contact(
          id: aliceId,
          accountId: 'work',
          contactListId: listVisible,
          providerId: 'p1',
          displayName: 'Alice Anderson',
          updatedAt: 1,
        ),
        Contact(
          id: _id('work', 'p2'),
          accountId: 'work',
          contactListId: listVisible,
          providerId: 'p2',
          displayName: 'Bob Brown',
          updatedAt: 2,
        ),
      ]);

      final List<ContactSearchHit> hits = await store.searchContacts('Alice');
      expect(hits, hasLength(1));
      expect(hits.single.contact.id, aliceId);
      expect(hits.single.displayName, 'Alice Anderson');
    });

    test('finds contacts by email address via LIKE', () async {
      final (
        SynesisDatabase database,
        DriftPimStore store,
        String listVisible,
        _,
      ) = await seedTwoLists();
      addTearDown(database.close);

      final String contactId = _id('work', 'p1');
      await store.upsertContacts(<Contact>[
        Contact(
          id: contactId,
          accountId: 'work',
          contactListId: listVisible,
          providerId: 'p1',
          displayName: 'Someone Else',
          updatedAt: 1,
        ),
      ]);
      await store.upsertContactEmails(<ContactEmail>[
        ContactEmail(
          id: 'email-primary',
          contactId: contactId,
          address: 'quicksilver@example.com',
          isPrimary: true,
        ),
      ]);

      final List<ContactSearchHit> hits = await store.searchContacts(
        'quicksilver',
      );
      expect(hits, hasLength(1));
      expect(hits.single.contact.id, contactId);
      expect(hits.single.email, 'quicksilver@example.com');
    });

    test('selectedListsOnly excludes contacts in hidden lists', () async {
      final (
        SynesisDatabase database,
        DriftPimStore store,
        String listVisible,
        String listHidden,
      ) = await seedTwoLists();
      addTearDown(database.close);

      final String visibleContactId = _id('work', 'p1');
      final String hiddenContactId = _id('work', 'p2');
      await store.upsertContacts(<Contact>[
        Contact(
          id: visibleContactId,
          accountId: 'work',
          contactListId: listVisible,
          providerId: 'p1',
          displayName: 'Zephyr Visible',
          updatedAt: 1,
        ),
        Contact(
          id: hiddenContactId,
          accountId: 'work',
          contactListId: listHidden,
          providerId: 'p2',
          displayName: 'Zephyr Hidden',
          updatedAt: 2,
        ),
      ]);

      final List<ContactSearchHit> defaultHits = await store.searchContacts(
        'Zephyr',
      );
      expect(
        defaultHits.map((ContactSearchHit hit) => hit.contact.id).toSet(),
        <String>{visibleContactId},
      );

      final List<ContactSearchHit> allHits = await store.searchContacts(
        'Zephyr',
        selectedListsOnly: false,
      );
      expect(
        allHits.map((ContactSearchHit hit) => hit.contact.id).toSet(),
        <String>{visibleContactId, hiddenContactId},
      );
    });

    test('returns empty for blank query without touching the database', () async {
      final (
        SynesisDatabase database,
        DriftPimStore store,
        _,
        _,
      ) = await seedTwoLists();
      addTearDown(database.close);

      expect(await store.searchContacts('   '), isEmpty);
    });
  });

  group('DriftPimStore.listEventsInRange', () {
    test('overlap logic includes partial and excludes disjoint events', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');

      final String calId = _id('work', 'primary');
      await store.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'work',
          providerId: 'primary',
          name: 'Work',
          colorArgb: 0xFF112233,
          isDefault: true,
        ),
      ]);

      await store.upsertEvents(<CalendarEvent>[
        CalendarEvent(
          id: _id('work', 'before'),
          accountId: 'work',
          calendarId: calId,
          providerId: 'before',
          title: 'Before range',
          startEpochMs: 0,
          endEpochMs: 1000,
          updatedAt: 1,
        ),
        CalendarEvent(
          id: _id('work', 'overlap-start'),
          accountId: 'work',
          calendarId: calId,
          providerId: 'overlap-start',
          title: 'Overlaps range start',
          startEpochMs: 1500,
          endEpochMs: 2500,
          updatedAt: 1,
        ),
        CalendarEvent(
          id: _id('work', 'inside'),
          accountId: 'work',
          calendarId: calId,
          providerId: 'inside',
          title: 'Fully inside',
          startEpochMs: 3000,
          endEpochMs: 4000,
          updatedAt: 1,
        ),
        CalendarEvent(
          id: _id('work', 'overlap-end'),
          accountId: 'work',
          calendarId: calId,
          providerId: 'overlap-end',
          title: 'Overlaps range end',
          startEpochMs: 4500,
          endEpochMs: 5500,
          updatedAt: 1,
        ),
        CalendarEvent(
          id: _id('work', 'after'),
          accountId: 'work',
          calendarId: calId,
          providerId: 'after',
          title: 'After range',
          startEpochMs: 6000,
          endEpochMs: 7000,
          updatedAt: 1,
        ),
      ]);

      final List<CalendarEvent> inRange = await store.listEventsInRange(
        startEpochMsInclusive: 2000,
        endEpochMsExclusive: 5000,
      );

      expect(
        inRange.map((CalendarEvent event) => event.title).toList(),
        <String>['Overlaps range start', 'Fully inside', 'Overlaps range end'],
      );
    });

    test('scopes to selected calendars by default', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');

      final String visibleCal = _id('work', 'primary');
      final String hiddenCal = _id('work', 'archive');
      await store.upsertCalendars(<Calendar>[
        Calendar(
          id: visibleCal,
          accountId: 'work',
          providerId: 'primary',
          name: 'Work',
          colorArgb: 0xFF112233,
          isDefault: true,
        ),
        Calendar(
          id: hiddenCal,
          accountId: 'work',
          providerId: 'archive',
          name: 'Archive',
          colorArgb: 0xFF445566,
          isSelectedForDisplay: false,
        ),
      ]);

      await store.upsertEvents(<CalendarEvent>[
        CalendarEvent(
          id: _id('work', 'ev-visible'),
          accountId: 'work',
          calendarId: visibleCal,
          providerId: 'ev-visible',
          title: 'Visible event',
          startEpochMs: 1000,
          endEpochMs: 2000,
          updatedAt: 1,
        ),
        CalendarEvent(
          id: _id('work', 'ev-hidden'),
          accountId: 'work',
          calendarId: hiddenCal,
          providerId: 'ev-hidden',
          title: 'Hidden event',
          startEpochMs: 1000,
          endEpochMs: 2000,
          updatedAt: 1,
        ),
      ]);

      final List<CalendarEvent> defaultScoped = await store.listEventsInRange(
        startEpochMsInclusive: 0,
        endEpochMsExclusive: 3000,
      );
      expect(
        defaultScoped.map((CalendarEvent event) => event.title).toList(),
        <String>['Visible event'],
      );

      final List<CalendarEvent> allCalendars = await store.listEventsInRange(
        startEpochMsInclusive: 0,
        endEpochMsExclusive: 3000,
        selectedCalendarsOnly: false,
      );
      expect(
        allCalendars.map((CalendarEvent event) => event.title).toSet(),
        <String>{'Visible event', 'Hidden event'},
      );

      final List<CalendarEvent> explicitCalendars = await store
          .listEventsInRange(
            startEpochMsInclusive: 0,
            endEpochMsExclusive: 3000,
            calendarIds: <String>[hiddenCal],
          );
      expect(
        explicitCalendars.map((CalendarEvent event) => event.title).toList(),
        <String>['Hidden event'],
      );
    });
  });

  group('DriftPimStore display preference writers', () {
    test('setContactListDisplayPrefs persists partial updates', () async {
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
          sortIndex: 0,
        ),
      ]);

      await store.setContactListDisplayPrefs(
        listId,
        isSelectedForDisplay: false,
        sortIndex: 9,
      );

      ContactList reread = (await store.listContactLists(
        accountId: 'work',
      )).single;
      expect(reread.isSelectedForDisplay, isFalse);
      expect(reread.sortIndex, 9);
      expect(reread.name, 'Contacts');

      // Partial write of a single field must not clobber prior writes.
      await store.setContactListDisplayPrefs(listId, colorArgb: 0xFF00FF00);
      reread = (await store.listContactLists(accountId: 'work')).single;
      expect(reread.colorArgb, 0xFF00FF00);
      expect(reread.isSelectedForDisplay, isFalse);
      expect(reread.sortIndex, 9);

      // Display prefs (isSelectedForDisplay / sortIndex) survive a
      // subsequent provider upsert (preserve-on-upsert contract); colorArgb
      // is server metadata and is refreshed like name/isDefault.
      await store.upsertContactLists(<ContactList>[
        ContactList(
          id: 'ignored-caller-id',
          accountId: 'work',
          providerId: 'default',
          name: 'Renamed Contacts',
          isDefault: true,
        ),
      ]);

      reread = (await store.listContactLists(accountId: 'work')).single;
      expect(reread.name, 'Renamed Contacts');
      expect(reread.colorArgb, isNull);
      expect(reread.isSelectedForDisplay, isFalse);
      expect(reread.sortIndex, 9);
    });

    test('setCalendarDisplayPrefs persists partial updates', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');

      final String calId = _id('work', 'primary');
      await store.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'work',
          providerId: 'primary',
          name: 'Work',
          colorArgb: 0xFF112233,
          isDefault: true,
        ),
      ]);

      await store.setCalendarDisplayPrefs(
        calId,
        isSelectedForDisplay: false,
        colorOverrideArgb: 0xFFABCDEF,
      );

      Calendar reread = (await store.listCalendars(accountId: 'work')).single;
      expect(reread.isSelectedForDisplay, isFalse);
      expect(reread.colorOverrideArgb, 0xFFABCDEF);

      await store.setCalendarDisplayPrefs(calId, sortIndex: 4);
      await store.upsertCalendars(<Calendar>[
        Calendar(
          id: 'ignored-caller-id',
          accountId: 'work',
          providerId: 'primary',
          name: 'Work Renamed',
          colorArgb: 0xFF445566,
          isDefault: true,
        ),
      ]);

      reread = (await store.listCalendars(accountId: 'work')).single;
      expect(reread.name, 'Work Renamed');
      expect(reread.isSelectedForDisplay, isFalse);
      expect(reread.colorOverrideArgb, 0xFFABCDEF);
      expect(reread.sortIndex, 4);
    });
  });

  group('DriftPimStore local event CRUD', () {
    test('createLocalEvent defaults to the default calendar', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');

      final String calId = _id('work', 'primary');
      await store.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'work',
          providerId: 'primary',
          name: 'Work',
          colorArgb: 0xFF112233,
          isDefault: true,
        ),
      ]);

      final CalendarEvent created = await store.createLocalEvent(
        accountId: 'work',
        title: 'Dentist',
        startEpochMs: 1000,
        endEpochMs: 2000,
      );

      expect(created.calendarId, calId);
      expect(created.providerId, startsWith('local:'));
      expect(created.id, _id('work', created.providerId));

      final List<CalendarEvent> events = await store.listEvents(
        accountId: 'work',
      );
      expect(events, hasLength(1));
      expect(events.single.title, 'Dentist');
    });

    test('createLocalEvent throws when no calendar exists', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');

      expect(
        () => store.createLocalEvent(
          accountId: 'work',
          title: 'Orphan',
          startEpochMs: 1000,
          endEpochMs: 2000,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('updateLocalEvent overwrites mutable fields', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');

      final String calId = _id('work', 'primary');
      await store.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'work',
          providerId: 'primary',
          name: 'Work',
          colorArgb: 0xFF112233,
          isDefault: true,
        ),
      ]);

      final CalendarEvent created = await store.createLocalEvent(
        accountId: 'work',
        title: 'Original title',
        startEpochMs: 1000,
        endEpochMs: 2000,
      );

      final CalendarEvent updated = CalendarEvent(
        id: created.id,
        accountId: created.accountId,
        calendarId: created.calendarId,
        providerId: created.providerId,
        title: 'Updated title',
        body: 'New body',
        startEpochMs: 5000,
        endEpochMs: 6000,
        location: 'Room 42',
        updatedAt: created.updatedAt,
      );
      await store.updateLocalEvent(updated);

      final CalendarEvent reread = (await store.listEvents(
        accountId: 'work',
      )).single;
      expect(reread.title, 'Updated title');
      expect(reread.body, 'New body');
      expect(reread.startEpochMs, 5000);
      expect(reread.endEpochMs, 6000);
      expect(reread.location, 'Room 42');
      expect(reread.updatedAt, greaterThanOrEqualTo(created.updatedAt));
    });

    test('softDeleteEvent stamps deletedAt and hides from default list', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');

      final String calId = _id('work', 'primary');
      await store.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'work',
          providerId: 'primary',
          name: 'Work',
          colorArgb: 0xFF112233,
          isDefault: true,
        ),
      ]);

      final CalendarEvent created = await store.createLocalEvent(
        accountId: 'work',
        title: 'To delete',
        startEpochMs: 1000,
        endEpochMs: 2000,
      );

      await store.softDeleteEvent(created.id);

      expect(await store.listEvents(accountId: 'work'), isEmpty);
      final List<CalendarEvent> withDeleted = await store.listEvents(
        accountId: 'work',
        includeDeleted: true,
      );
      expect(withDeleted, hasLength(1));
      expect(withDeleted.single.deletedAt, isNotNull);
    });
  });

  group('DriftPimStore Wave 6 copy helpers', () {
    test('duplicateEventToCalendar clones fields, strips rrule, attendees',
        () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');
      await _seedAccount(database, 'personal');

      final String sourceCal = _id('work', 'primary');
      final String targetCal = _id('personal', 'primary');
      await store.upsertCalendars(<Calendar>[
        Calendar(
          id: sourceCal,
          accountId: 'work',
          providerId: 'primary',
          name: 'Work',
          colorArgb: 0xFF112233,
          isDefault: true,
        ),
        Calendar(
          id: targetCal,
          accountId: 'personal',
          providerId: 'primary',
          name: 'Personal',
          colorArgb: 0xFF445566,
          isDefault: true,
        ),
      ]);

      final CalendarEvent source = await store.createLocalEvent(
        accountId: 'work',
        calendarId: sourceCal,
        title: 'Series stub',
        body: 'Notes',
        startEpochMs: 1000,
        endEpochMs: 2000,
        location: 'HQ',
        rrule: 'FREQ=WEEKLY',
        reminderMinutes: 15,
        providerId: 'remote-ev-1',
      );
      await store.upsertEventAttendees(<EventAttendee>[
        EventAttendee(
          id: _id(source.id, 'attendee:a@byte.io'),
          eventId: source.id,
          email: 'a@byte.io',
          displayName: 'Ada',
          responseStatus: 'accepted',
          isOrganizer: true,
        ),
      ]);

      final CalendarEvent copy = await store.duplicateEventToCalendar(
        sourceEventId: source.id,
        targetAccountId: 'personal',
        targetCalendarId: targetCal,
      );

      expect(copy.accountId, 'personal');
      expect(copy.calendarId, targetCal);
      expect(copy.title, 'Series stub');
      expect(copy.body, 'Notes');
      expect(copy.location, 'HQ');
      expect(copy.reminderMinutes, 15);
      expect(copy.rrule, isNull);
      expect(copy.providerId, startsWith('local:'));
      expect(copy.id, isNot(source.id));

      final List<EventAttendee> attendees = await store.listEventAttendees(
        copy.id,
      );
      expect(attendees, hasLength(1));
      expect(attendees.single.email, 'a@byte.io');
      expect(attendees.single.isOrganizer, isFalse);
    });

    test('createLocalContact + duplicateContactToList copies emails/phones',
        () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');
      await _seedAccount(database, 'personal');

      final String sourceList = _id('work', 'default');
      final String targetList = _id('personal', 'default');
      await store.upsertContactLists(<ContactList>[
        ContactList(
          id: sourceList,
          accountId: 'work',
          providerId: 'default',
          name: 'Work',
          isDefault: true,
        ),
        ContactList(
          id: targetList,
          accountId: 'personal',
          providerId: 'default',
          name: 'Personal',
          isDefault: true,
        ),
      ]);

      final Contact source = await store.createLocalContact(
        accountId: 'work',
        contactListId: sourceList,
        displayName: 'Ada Lovelace',
        givenName: 'Ada',
        familyName: 'Lovelace',
        company: 'Analytical',
        emails: const <ContactEmail>[
          ContactEmail(
            id: 'tmp-email',
            contactId: 'tmp',
            address: 'ada@byte.io',
            type: 'work',
            isPrimary: true,
          ),
        ],
        phones: const <ContactPhone>[
          ContactPhone(
            id: 'tmp-phone',
            contactId: 'tmp',
            number: '+1-555-0100',
            type: 'mobile',
          ),
        ],
      );

      final Contact copy = await store.duplicateContactToList(
        sourceContactId: source.id,
        targetAccountId: 'personal',
        targetContactListId: targetList,
      );

      expect(copy.accountId, 'personal');
      expect(copy.contactListId, targetList);
      expect(copy.displayName, 'Ada Lovelace');
      expect(copy.givenName, 'Ada');
      expect(copy.company, 'Analytical');
      expect(copy.providerId, startsWith('local:'));

      final List<ContactEmail> emails = await store.listContactEmails(copy.id);
      final List<ContactPhone> phones = await store.listContactPhones(copy.id);
      expect(emails, hasLength(1));
      expect(emails.single.address, 'ada@byte.io');
      expect(phones.single.number, '+1-555-0100');
    });

    test('rewriteEventProviderId keeps local id stable', () async {
      final (SynesisDatabase database, DriftPimStore store) =
          await _openPimStore();
      addTearDown(database.close);
      await _seedAccount(database, 'work');

      final String calId = _id('work', 'primary');
      await store.upsertCalendars(<Calendar>[
        Calendar(
          id: calId,
          accountId: 'work',
          providerId: 'primary',
          name: 'Work',
          colorArgb: 0xFF112233,
          isDefault: true,
        ),
      ]);
      final CalendarEvent created = await store.createLocalEvent(
        accountId: 'work',
        title: 'Push me',
        startEpochMs: 1000,
        endEpochMs: 2000,
      );
      final String localId = created.id;
      await store.rewriteEventProviderId(
        eventId: localId,
        providerId: 'graph-remote-99',
        etag: 'W/"etag"',
      );
      final CalendarEvent? reread = await store.getEvent(localId);
      expect(reread, isNotNull);
      expect(reread!.id, localId);
      expect(reread.providerId, 'graph-remote-99');
      expect(reread.etag, 'W/"etag"');
      expect(
        await store.findEventByProviderId(
          accountId: 'work',
          providerId: 'graph-remote-99',
        ),
        isNotNull,
      );
    });
  });
}
