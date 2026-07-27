// ==============================================================================
// File: lib/repository/drift/drift_pim_store.dart
// Description: Drift read/write paths for contact lists, contacts, calendars, events.
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:drift/drift.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/repository/database.dart';

/// Thin PIM persistence facade (Wave 1 P0 — no provider adapters).
class DriftPimStore {
  DriftPimStore(
    this._database, {
    required void Function() notify,
  }) : _notify = notify;

  final SynesisDatabase _database;
  final void Function() _notify;

  // ---------------------------------------------------------------------------
  // Contact lists
  // ---------------------------------------------------------------------------

  Future<List<ContactList>> listContactLists({String? accountId}) async {
    final query = _database.select(_database.contactLists);
    if (accountId != null) {
      query.where(
        (ContactLists table) => table.accountId.equals(accountId),
      );
    }
    query.orderBy(<OrderingTerm Function(ContactLists)>[
      (ContactLists table) => OrderingTerm.asc(table.sortIndex),
      (ContactLists table) => OrderingTerm.asc(table.name),
    ]);
    final List<ContactListRow> rows = await query.get();
    return rows.map(_contactListFromRow).toList(growable: false);
  }

  /// Lists with [ContactList.isSelectedForDisplay] == true.
  Future<List<ContactList>> listSelectedContactLists({
    String? accountId,
  }) async {
    final List<ContactList> all = await listContactLists(accountId: accountId);
    return all
        .where((ContactList list) => list.isSelectedForDisplay)
        .toList(growable: false);
  }

  Future<void> upsertContactLists(List<ContactList> lists) async {
    if (lists.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final ContactList list in lists) {
        await _database.into(_database.contactLists).insertOnConflictUpdate(
              ContactListsCompanion.insert(
                id: list.id,
                accountId: list.accountId,
                providerId: list.providerId,
                name: list.name,
                colorArgb: Value<int?>(list.colorArgb),
                isDefault: Value<bool>(list.isDefault),
                isSelectedForDisplay: Value<bool>(list.isSelectedForDisplay),
                sortIndex: Value<int?>(list.sortIndex),
              ),
            );
      }
    });
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Contacts
  // ---------------------------------------------------------------------------

  Future<List<Contact>> listContacts({
    String? accountId,
    String? contactListId,
    bool includeDeleted = false,
  }) async {
    final query = _database.select(_database.contacts);
    query.where((Contacts table) {
      Expression<bool> predicate = const Constant<bool>(true);
      if (accountId != null) {
        predicate = predicate & table.accountId.equals(accountId);
      }
      if (contactListId != null) {
        predicate = predicate & table.contactListId.equals(contactListId);
      }
      if (!includeDeleted) {
        predicate = predicate & table.deletedAt.isNull();
      }
      return predicate;
    });
    query.orderBy(<OrderingTerm Function(Contacts)>[
      (Contacts table) => OrderingTerm.asc(table.displayName),
    ]);
    final List<ContactRow> rows = await query.get();
    return rows.map(_contactFromRow).toList(growable: false);
  }

  /// Contacts belonging to lists currently selected for display.
  Future<List<Contact>> listContactsForSelectedLists({
    String? accountId,
  }) async {
    final List<ContactList> selected = await listSelectedContactLists(
      accountId: accountId,
    );
    if (selected.isEmpty) {
      return const <Contact>[];
    }
    final Set<String> listIds =
        selected.map((ContactList list) => list.id).toSet();
    final List<Contact> contacts = await listContacts(accountId: accountId);
    return contacts
        .where((Contact contact) => listIds.contains(contact.contactListId))
        .toList(growable: false);
  }

  Future<void> upsertContacts(List<Contact> contacts) async {
    if (contacts.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final Contact contact in contacts) {
        await _database.into(_database.contacts).insertOnConflictUpdate(
              ContactsCompanion.insert(
                id: contact.id,
                accountId: contact.accountId,
                contactListId: contact.contactListId,
                providerId: contact.providerId,
                displayName: contact.displayName,
                givenName: Value<String?>(contact.givenName),
                familyName: Value<String?>(contact.familyName),
                company: Value<String?>(contact.company),
                notes: Value<String?>(contact.notes),
                etag: Value<String?>(contact.etag),
                updatedAt: contact.updatedAt,
                deletedAt: Value<int?>(contact.deletedAt),
              ),
            );
      }
    });
    _notify();
  }

  Future<List<ContactEmail>> listContactEmails(String contactId) async {
    final List<ContactEmailRow> rows = await (_database.select(
      _database.contactEmails,
    )..where((ContactEmails table) => table.contactId.equals(contactId)))
        .get();
    return rows.map(_contactEmailFromRow).toList(growable: false);
  }

  Future<List<ContactPhone>> listContactPhones(String contactId) async {
    final List<ContactPhoneRow> rows = await (_database.select(
      _database.contactPhones,
    )..where((ContactPhones table) => table.contactId.equals(contactId)))
        .get();
    return rows.map(_contactPhoneFromRow).toList(growable: false);
  }

  Future<void> upsertContactEmails(List<ContactEmail> emails) async {
    if (emails.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final ContactEmail email in emails) {
        await _database.into(_database.contactEmails).insertOnConflictUpdate(
              ContactEmailsCompanion.insert(
                id: email.id,
                contactId: email.contactId,
                address: email.address,
                type: Value<String>(email.type),
                isPrimary: Value<bool>(email.isPrimary),
              ),
            );
      }
    });
    _notify();
  }

  Future<void> upsertContactPhones(List<ContactPhone> phones) async {
    if (phones.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final ContactPhone phone in phones) {
        await _database.into(_database.contactPhones).insertOnConflictUpdate(
              ContactPhonesCompanion.insert(
                id: phone.id,
                contactId: phone.contactId,
                number: phone.number,
                type: Value<String>(phone.type),
              ),
            );
      }
    });
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Calendars
  // ---------------------------------------------------------------------------

  Future<List<Calendar>> listCalendars({String? accountId}) async {
    final query = _database.select(_database.calendars);
    if (accountId != null) {
      query.where((Calendars table) => table.accountId.equals(accountId));
    }
    query.orderBy(<OrderingTerm Function(Calendars)>[
      (Calendars table) => OrderingTerm.asc(table.sortIndex),
      (Calendars table) => OrderingTerm.asc(table.name),
    ]);
    final List<CalendarRow> rows = await query.get();
    return rows.map(_calendarFromRow).toList(growable: false);
  }

  /// Calendars with [Calendar.isSelectedForDisplay] == true.
  Future<List<Calendar>> listSelectedCalendars({String? accountId}) async {
    final List<Calendar> all = await listCalendars(accountId: accountId);
    return all
        .where((Calendar calendar) => calendar.isSelectedForDisplay)
        .toList(growable: false);
  }

  /// Groups calendars by [Calendar.accountId] (stable account-id order).
  Future<Map<String, List<Calendar>>> calendarsGroupedByAccount({
    String? accountId,
  }) async {
    final List<Calendar> calendars = await listCalendars(accountId: accountId);
    final Map<String, List<Calendar>> grouped = <String, List<Calendar>>{};
    for (final Calendar calendar in calendars) {
      grouped
          .putIfAbsent(calendar.accountId, () => <Calendar>[])
          .add(calendar);
    }
    return grouped;
  }

  Future<void> upsertCalendars(List<Calendar> calendars) async {
    if (calendars.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final Calendar calendar in calendars) {
        await _database.into(_database.calendars).insertOnConflictUpdate(
              CalendarsCompanion.insert(
                id: calendar.id,
                accountId: calendar.accountId,
                providerId: calendar.providerId,
                name: calendar.name,
                colorArgb: calendar.colorArgb,
                colorOverrideArgb: Value<int?>(calendar.colorOverrideArgb),
                isDefault: Value<bool>(calendar.isDefault),
                isSelectedForDisplay: Value<bool>(
                  calendar.isSelectedForDisplay,
                ),
                sortIndex: Value<int?>(calendar.sortIndex),
              ),
            );
      }
    });
    _notify();
  }

  // ---------------------------------------------------------------------------
  // Events
  // ---------------------------------------------------------------------------

  Future<List<CalendarEvent>> listEvents({
    String? accountId,
    String? calendarId,
    bool includeDeleted = false,
  }) async {
    final query = _database.select(_database.events);
    query.where((Events table) {
      Expression<bool> predicate = const Constant<bool>(true);
      if (accountId != null) {
        predicate = predicate & table.accountId.equals(accountId);
      }
      if (calendarId != null) {
        predicate = predicate & table.calendarId.equals(calendarId);
      }
      if (!includeDeleted) {
        predicate = predicate & table.deletedAt.isNull();
      }
      return predicate;
    });
    query.orderBy(<OrderingTerm Function(Events)>[
      (Events table) => OrderingTerm.asc(table.startEpochMs),
    ]);
    final List<EventRow> rows = await query.get();
    return rows.map(_eventFromRow).toList(growable: false);
  }

  /// Events on calendars currently selected for display.
  Future<List<CalendarEvent>> listEventsForSelectedCalendars({
    String? accountId,
  }) async {
    final List<Calendar> selected = await listSelectedCalendars(
      accountId: accountId,
    );
    if (selected.isEmpty) {
      return const <CalendarEvent>[];
    }
    final Set<String> calendarIds =
        selected.map((Calendar calendar) => calendar.id).toSet();
    final List<CalendarEvent> events = await listEvents(accountId: accountId);
    return events
        .where((CalendarEvent event) => calendarIds.contains(event.calendarId))
        .toList(growable: false);
  }

  Future<void> upsertEvents(List<CalendarEvent> events) async {
    if (events.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final CalendarEvent event in events) {
        await _database.into(_database.events).insertOnConflictUpdate(
              EventsCompanion.insert(
                id: event.id,
                accountId: event.accountId,
                calendarId: event.calendarId,
                providerId: event.providerId,
                title: event.title,
                body: Value<String?>(event.body),
                startEpochMs: event.startEpochMs,
                endEpochMs: event.endEpochMs,
                allDay: Value<bool>(event.allDay),
                location: Value<String?>(event.location),
                rrule: Value<String?>(event.rrule),
                reminderMinutes: Value<int?>(event.reminderMinutes),
                etag: Value<String?>(event.etag),
                updatedAt: event.updatedAt,
                deletedAt: Value<int?>(event.deletedAt),
              ),
            );
      }
    });
    _notify();
  }

  Future<List<EventAttendee>> listEventAttendees(String eventId) async {
    final List<EventAttendeeRow> rows = await (_database.select(
      _database.eventAttendees,
    )..where((EventAttendees table) => table.eventId.equals(eventId)))
        .get();
    return rows.map(_attendeeFromRow).toList(growable: false);
  }

  Future<void> upsertEventAttendees(List<EventAttendee> attendees) async {
    if (attendees.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final EventAttendee attendee in attendees) {
        await _database.into(_database.eventAttendees).insertOnConflictUpdate(
              EventAttendeesCompanion.insert(
                id: attendee.id,
                eventId: attendee.eventId,
                email: attendee.email,
                displayName: Value<String?>(attendee.displayName),
                responseStatus: Value<String>(attendee.responseStatus),
                isOrganizer: Value<bool>(attendee.isOrganizer),
              ),
            );
      }
    });
    _notify();
  }

  /// Deletes all PIM rows for [accountId] (child tables first).
  Future<void> wipeAccountPim(String accountId) async {
    await _database.transaction(() async {
      await _database.customStatement(
        'DELETE FROM event_attendees WHERE event_id IN '
        '(SELECT id FROM events WHERE account_id = ?)',
        <Object>[accountId],
      );
      await (_database.delete(
        _database.events,
      )..where((Events table) => table.accountId.equals(accountId))).go();
      await (_database.delete(
        _database.calendars,
      )..where((Calendars table) => table.accountId.equals(accountId))).go();
      await _database.customStatement(
        'DELETE FROM contact_emails WHERE contact_id IN '
        '(SELECT id FROM contacts WHERE account_id = ?)',
        <Object>[accountId],
      );
      await _database.customStatement(
        'DELETE FROM contact_phones WHERE contact_id IN '
        '(SELECT id FROM contacts WHERE account_id = ?)',
        <Object>[accountId],
      );
      await (_database.delete(
        _database.contacts,
      )..where((Contacts table) => table.accountId.equals(accountId))).go();
      await (_database.delete(
        _database.contactLists,
      )..where((ContactLists table) => table.accountId.equals(accountId)))
          .go();
    });
  }

  static ContactList _contactListFromRow(ContactListRow row) => ContactList(
        id: row.id,
        accountId: row.accountId,
        providerId: row.providerId,
        name: row.name,
        colorArgb: row.colorArgb,
        isDefault: row.isDefault,
        isSelectedForDisplay: row.isSelectedForDisplay,
        sortIndex: row.sortIndex,
      );

  static Contact _contactFromRow(ContactRow row) => Contact(
        id: row.id,
        accountId: row.accountId,
        contactListId: row.contactListId,
        providerId: row.providerId,
        displayName: row.displayName,
        givenName: row.givenName,
        familyName: row.familyName,
        company: row.company,
        notes: row.notes,
        etag: row.etag,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
      );

  static ContactEmail _contactEmailFromRow(ContactEmailRow row) => ContactEmail(
        id: row.id,
        contactId: row.contactId,
        address: row.address,
        type: row.type,
        isPrimary: row.isPrimary,
      );

  static ContactPhone _contactPhoneFromRow(ContactPhoneRow row) => ContactPhone(
        id: row.id,
        contactId: row.contactId,
        number: row.number,
        type: row.type,
      );

  static Calendar _calendarFromRow(CalendarRow row) => Calendar(
        id: row.id,
        accountId: row.accountId,
        providerId: row.providerId,
        name: row.name,
        colorArgb: row.colorArgb,
        colorOverrideArgb: row.colorOverrideArgb,
        isDefault: row.isDefault,
        isSelectedForDisplay: row.isSelectedForDisplay,
        sortIndex: row.sortIndex,
      );

  static CalendarEvent _eventFromRow(EventRow row) => CalendarEvent(
        id: row.id,
        accountId: row.accountId,
        calendarId: row.calendarId,
        providerId: row.providerId,
        title: row.title,
        body: row.body,
        startEpochMs: row.startEpochMs,
        endEpochMs: row.endEpochMs,
        allDay: row.allDay,
        location: row.location,
        rrule: row.rrule,
        reminderMinutes: row.reminderMinutes,
        etag: row.etag,
        updatedAt: row.updatedAt,
        deletedAt: row.deletedAt,
      );

  static EventAttendee _attendeeFromRow(EventAttendeeRow row) => EventAttendee(
        id: row.id,
        eventId: row.eventId,
        email: row.email,
        displayName: row.displayName,
        responseStatus: row.responseStatus,
        isOrganizer: row.isOrganizer,
      );
}
