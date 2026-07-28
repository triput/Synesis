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
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_mappers.dart';
import 'package:uuid/uuid.dart';

/// Thin PIM persistence facade (Wave 1 P0 — no provider adapters).
///
/// Collection upserts ([upsertContactLists] / [upsertCalendars]) preserve local
/// display preferences on conflict so provider refreshes do not clobber user
/// toggles (Wave 2 / V2.0a P0 QA). New rows use [PimIds.stableLocalId] after a
/// lookup by `(accountId, providerId)` to avoid duplicate local rows.
class DriftPimStore {
  DriftPimStore(this._database, {required void Function() notify})
    : _notify = notify;

  final SynesisDatabase _database;
  final void Function() _notify;
  final Uuid _uuid = const Uuid();

  /// Deterministic local primary key for a provider-scoped PIM row.
  ///
  /// Prefer this (or [PimIds.stableLocalId]) when constructing domain models
  /// before insert; upserts also apply it for new rows.
  static String stableLocalId(String accountId, String providerId) =>
      PimIds.stableLocalId(accountId, providerId);

  // ---------------------------------------------------------------------------
  // Contact lists
  // ---------------------------------------------------------------------------

  Future<List<ContactList>> listContactLists({String? accountId}) async {
    final query = _database.select(_database.contactLists);
    if (accountId != null) {
      query.where((ContactLists table) => table.accountId.equals(accountId));
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

  /// Looks up a contact list by account + remote provider id.
  Future<ContactList?> findContactListByProviderId({
    required String accountId,
    required String providerId,
  }) async {
    final ContactListRow? row = await _findContactListRow(
      accountId: accountId,
      providerId: providerId,
    );
    return row == null ? null : _contactListFromRow(row);
  }

  /// Upserts contact lists by `(accountId, providerId)`.
  ///
  /// On conflict, updates server metadata (`name`, `colorArgb`, `isDefault`)
  /// but leaves [ContactList.isSelectedForDisplay] and [ContactList.sortIndex]
  /// unchanged. New rows insert with [stableLocalId] and the provided display
  /// defaults.
  Future<void> upsertContactLists(List<ContactList> lists) async {
    if (lists.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final ContactList list in lists) {
        final ContactListRow? existing = await _findContactListRow(
          accountId: list.accountId,
          providerId: list.providerId,
        );
        if (existing != null) {
          await (_database.update(
            _database.contactLists,
          )..where((ContactLists table) => table.id.equals(existing.id))).write(
            ContactListsCompanion(
              name: Value<String>(list.name),
              colorArgb: Value<int?>(list.colorArgb),
              isDefault: Value<bool>(list.isDefault),
              // Preserve local display prefs on provider refresh.
              isSelectedForDisplay: const Value.absent(),
              sortIndex: const Value.absent(),
            ),
          );
        } else {
          final String id = stableLocalId(list.accountId, list.providerId);
          await _database
              .into(_database.contactLists)
              .insert(
                ContactListsCompanion.insert(
                  id: id,
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
      }
    });
    _notify();
  }

  /// Partially updates local display preferences for a contact list.
  /// Only non-null arguments are written; leaves other columns untouched.
  Future<void> setContactListDisplayPrefs(
    String listId, {
    bool? isSelectedForDisplay,
    int? sortIndex,
    int? colorArgb,
  }) async {
    if (isSelectedForDisplay == null && sortIndex == null && colorArgb == null) {
      return;
    }
    await (_database.update(
      _database.contactLists,
    )..where((ContactLists table) => table.id.equals(listId))).write(
      ContactListsCompanion(
        isSelectedForDisplay: isSelectedForDisplay == null
            ? const Value.absent()
            : Value<bool>(isSelectedForDisplay),
        sortIndex: sortIndex == null
            ? const Value.absent()
            : Value<int?>(sortIndex),
        colorArgb: colorArgb == null
            ? const Value.absent()
            : Value<int?>(colorArgb),
      ),
    );
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
    final Set<String> listIds = selected
        .map((ContactList list) => list.id)
        .toSet();
    final List<Contact> contacts = await listContacts(accountId: accountId);
    return contacts
        .where((Contact contact) => listIds.contains(contact.contactListId))
        .toList(growable: false);
  }

  /// Looks up a contact by account + remote provider id.
  Future<Contact?> findContactByProviderId({
    required String accountId,
    required String providerId,
  }) async {
    final ContactRow? row = await _findContactRow(
      accountId: accountId,
      providerId: providerId,
    );
    return row == null ? null : _contactFromRow(row);
  }

  /// Upserts contacts by `(accountId, providerId)`. New rows use [stableLocalId].
  Future<void> upsertContacts(List<Contact> contacts) async {
    if (contacts.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final Contact contact in contacts) {
        final ContactRow? existing = await _findContactRow(
          accountId: contact.accountId,
          providerId: contact.providerId,
        );
        final String id =
            existing?.id ??
            stableLocalId(contact.accountId, contact.providerId);
        await _database
            .into(_database.contacts)
            .insertOnConflictUpdate(
              ContactsCompanion.insert(
                id: id,
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
    )..where((ContactEmails table) => table.contactId.equals(contactId))).get();
    return rows.map(_contactEmailFromRow).toList(growable: false);
  }

  Future<List<ContactPhone>> listContactPhones(String contactId) async {
    final List<ContactPhoneRow> rows = await (_database.select(
      _database.contactPhones,
    )..where((ContactPhones table) => table.contactId.equals(contactId))).get();
    return rows.map(_contactPhoneFromRow).toList(growable: false);
  }

  Future<void> upsertContactEmails(List<ContactEmail> emails) async {
    if (emails.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final ContactEmail email in emails) {
        await _database
            .into(_database.contactEmails)
            .insertOnConflictUpdate(
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
        await _database
            .into(_database.contactPhones)
            .insertOnConflictUpdate(
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

  /// Searches contacts by [query] against display name / company / notes
  /// (via `contact_fts`) and email address (via `LIKE` on `contact_emails`,
  /// which FTS does not index), merged and de-duplicated by contact id.
  ///
  /// Scopes to [listSelectedContactLists] when [selectedListsOnly] (default),
  /// always excludes soft-deleted contacts, and caps results at [limit].
  Future<List<ContactSearchHit>> searchContacts(
    String query, {
    String? accountId,
    bool selectedListsOnly = true,
    int limit = 25,
  }) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty || limit <= 0) {
      return const <ContactSearchHit>[];
    }

    Set<String>? allowedListIds;
    if (selectedListsOnly) {
      final List<ContactList> selected = await listSelectedContactLists(
        accountId: accountId,
      );
      if (selected.isEmpty) {
        return const <ContactSearchHit>[];
      }
      allowedListIds = selected.map((ContactList list) => list.id).toSet();
    }

    final List<String> ftsIds = await _ftsContactIds(trimmed);
    final List<String> emailMatchIds = await _emailMatchContactIds(trimmed);
    final Set<String> ftsIdSet = ftsIds.toSet();
    final List<String> orderedCandidateIds = <String>[
      ...ftsIds,
      for (final String id in emailMatchIds)
        if (!ftsIdSet.contains(id)) id,
    ];
    if (orderedCandidateIds.isEmpty) {
      return const <ContactSearchHit>[];
    }

    final query2 = _database.select(_database.contacts)
      ..where(
        (Contacts table) =>
            table.id.isIn(orderedCandidateIds) & table.deletedAt.isNull(),
      );
    if (accountId != null) {
      query2.where((Contacts table) => table.accountId.equals(accountId));
    }
    final List<ContactRow> rows = await query2.get();
    final Map<String, ContactRow> rowsById = <String, ContactRow>{
      for (final ContactRow row in rows) row.id: row,
    };

    final List<ContactSearchHit> hits = <ContactSearchHit>[];
    for (final String id in orderedCandidateIds) {
      final ContactRow? row = rowsById[id];
      if (row == null) {
        continue;
      }
      if (allowedListIds != null &&
          !allowedListIds.contains(row.contactListId)) {
        continue;
      }
      final Contact contact = _contactFromRow(row);
      final List<ContactEmail> emails = await listContactEmails(id);
      ContactEmail? bestEmail;
      for (final ContactEmail email in emails) {
        if (email.isPrimary) {
          bestEmail = email;
          break;
        }
      }
      bestEmail ??= emails.isNotEmpty ? emails.first : null;
      hits.add(
        ContactSearchHit(
          contact: contact,
          displayName: contact.displayName,
          email: bestEmail?.address,
        ),
      );
      if (hits.length >= limit) {
        break;
      }
    }
    return hits;
  }

  /// Contact ids ranked by FTS relevance (`bm25`) for [query].
  Future<List<String>> _ftsContactIds(String query) async {
    final String matchQuery = toFtsQuery(query);
    if (matchQuery.isEmpty) {
      return const <String>[];
    }
    final List<QueryRow> hits = await _database
        .customSelect(
          'SELECT contact_id FROM contact_fts WHERE contact_fts MATCH ? '
          'ORDER BY bm25(contact_fts)',
          variables: <Variable<Object>>[Variable<String>(matchQuery)],
        )
        .get();
    return hits
        .map((QueryRow row) => row.read<String>('contact_id'))
        .toList(growable: false);
  }

  /// Contact ids whose email address contains [query] (case-insensitive
  /// `LIKE`), in first-match order, de-duplicated.
  Future<List<String>> _emailMatchContactIds(String query) async {
    final String pattern = '%${_escapeLike(query)}%';
    final List<ContactEmailRow> rows = await (_database.select(
      _database.contactEmails,
    )..where(
          (ContactEmails table) =>
              table.address.like(pattern, escapeChar: r'\'),
        ))
        .get();
    final List<String> ids = <String>[];
    final Set<String> seen = <String>{};
    for (final ContactEmailRow row in rows) {
      if (seen.add(row.contactId)) {
        ids.add(row.contactId);
      }
    }
    return ids;
  }

  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

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

  /// Returns the marked default calendar, falling back to the first calendar.
  Future<Calendar?> findDefaultCalendar(String accountId) async {
    final List<Calendar> calendars = await listCalendars(accountId: accountId);
    for (final Calendar calendar in calendars) {
      if (calendar.isDefault) {
        return calendar;
      }
    }
    return calendars.isEmpty ? null : calendars.first;
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
      grouped.putIfAbsent(calendar.accountId, () => <Calendar>[]).add(calendar);
    }
    return grouped;
  }

  /// Looks up a calendar by account + remote provider id.
  Future<Calendar?> findCalendarByProviderId({
    required String accountId,
    required String providerId,
  }) async {
    final CalendarRow? row = await _findCalendarRow(
      accountId: accountId,
      providerId: providerId,
    );
    return row == null ? null : _calendarFromRow(row);
  }

  /// Upserts calendars by `(accountId, providerId)`.
  ///
  /// On conflict, updates server metadata (`name`, `colorArgb`, `isDefault`)
  /// but leaves [Calendar.isSelectedForDisplay], [Calendar.sortIndex], and
  /// [Calendar.colorOverrideArgb] unchanged. New rows insert with
  /// [stableLocalId] and the provided display defaults.
  Future<void> upsertCalendars(List<Calendar> calendars) async {
    if (calendars.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final Calendar calendar in calendars) {
        final CalendarRow? existing = await _findCalendarRow(
          accountId: calendar.accountId,
          providerId: calendar.providerId,
        );
        if (existing != null) {
          await (_database.update(
            _database.calendars,
          )..where((Calendars table) => table.id.equals(existing.id))).write(
            CalendarsCompanion(
              name: Value<String>(calendar.name),
              colorArgb: Value<int>(calendar.colorArgb),
              isDefault: Value<bool>(calendar.isDefault),
              // Preserve local display prefs on provider refresh.
              colorOverrideArgb: const Value.absent(),
              isSelectedForDisplay: const Value.absent(),
              sortIndex: const Value.absent(),
            ),
          );
        } else {
          final String id = stableLocalId(
            calendar.accountId,
            calendar.providerId,
          );
          await _database
              .into(_database.calendars)
              .insert(
                CalendarsCompanion.insert(
                  id: id,
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
      }
    });
    _notify();
  }

  /// Partially updates local display preferences for a calendar. Only
  /// non-null arguments are written; leaves other columns untouched.
  Future<void> setCalendarDisplayPrefs(
    String calendarId, {
    bool? isSelectedForDisplay,
    int? sortIndex,
    int? colorOverrideArgb,
  }) async {
    if (isSelectedForDisplay == null &&
        sortIndex == null &&
        colorOverrideArgb == null) {
      return;
    }
    await (_database.update(
      _database.calendars,
    )..where((Calendars table) => table.id.equals(calendarId))).write(
      CalendarsCompanion(
        isSelectedForDisplay: isSelectedForDisplay == null
            ? const Value.absent()
            : Value<bool>(isSelectedForDisplay),
        sortIndex: sortIndex == null
            ? const Value.absent()
            : Value<int?>(sortIndex),
        colorOverrideArgb: colorOverrideArgb == null
            ? const Value.absent()
            : Value<int?>(colorOverrideArgb),
      ),
    );
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
    final Set<String> calendarIds = selected
        .map((Calendar calendar) => calendar.id)
        .toSet();
    final List<CalendarEvent> events = await listEvents(accountId: accountId);
    return events
        .where((CalendarEvent event) => calendarIds.contains(event.calendarId))
        .toList(growable: false);
  }

  /// Events overlapping `[startEpochMsInclusive, endEpochMsExclusive)`.
  ///
  /// Overlap uses the standard interval test: the event starts before the
  /// range end AND ends after the range start. When [calendarIds] is `null`
  /// and [selectedCalendarsOnly] is true (default), scopes to
  /// [listSelectedCalendars]; pass an explicit (possibly empty) [calendarIds]
  /// list to override that default.
  Future<List<CalendarEvent>> listEventsInRange({
    required int startEpochMsInclusive,
    required int endEpochMsExclusive,
    String? accountId,
    List<String>? calendarIds,
    bool selectedCalendarsOnly = true,
    bool includeDeleted = false,
  }) async {
    Set<String>? allowedCalendarIds;
    if (calendarIds != null) {
      allowedCalendarIds = calendarIds.toSet();
      if (allowedCalendarIds.isEmpty) {
        return const <CalendarEvent>[];
      }
    } else if (selectedCalendarsOnly) {
      final List<Calendar> selected = await listSelectedCalendars(
        accountId: accountId,
      );
      if (selected.isEmpty) {
        return const <CalendarEvent>[];
      }
      allowedCalendarIds = selected
          .map((Calendar calendar) => calendar.id)
          .toSet();
    }

    final query = _database.select(_database.events);
    query.where((Events table) {
      Expression<bool> predicate =
          table.startEpochMs.isSmallerThanValue(endEpochMsExclusive) &
          table.endEpochMs.isBiggerThanValue(startEpochMsInclusive);
      if (accountId != null) {
        predicate = predicate & table.accountId.equals(accountId);
      }
      final Set<String>? allowed = allowedCalendarIds;
      if (allowed != null) {
        predicate = predicate & table.calendarId.isIn(allowed);
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

  /// Looks up an event by account + remote provider id.
  Future<CalendarEvent?> findEventByProviderId({
    required String accountId,
    required String providerId,
  }) async {
    final EventRow? row = await _findEventRow(
      accountId: accountId,
      providerId: providerId,
    );
    return row == null ? null : _eventFromRow(row);
  }

  /// Upserts events by `(accountId, providerId)`. New rows use [stableLocalId].
  Future<void> upsertEvents(List<CalendarEvent> events) async {
    if (events.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final CalendarEvent event in events) {
        final EventRow? existing = await _findEventRow(
          accountId: event.accountId,
          providerId: event.providerId,
        );
        final String id =
            existing?.id ?? stableLocalId(event.accountId, event.providerId);
        await _database
            .into(_database.events)
            .insertOnConflictUpdate(
              EventsCompanion.insert(
                id: id,
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

  /// Creates a **local-only** event (no sync job enqueued — callers that
  /// need provider push must go through the sync/outbox layer separately).
  ///
  /// When [providerId] is omitted, generates `local:{uuid}` so the row still
  /// has a stable `(accountId, providerId)` identity consistent with synced
  /// rows. Defaults to [findDefaultCalendar] when [calendarId] is omitted;
  /// throws [StateError] if the account has no calendars in either case.
  Future<CalendarEvent> createLocalEvent({
    required String accountId,
    required String title,
    required int startEpochMs,
    required int endEpochMs,
    String? calendarId,
    String? body,
    bool allDay = false,
    String? location,
    String? rrule,
    int? reminderMinutes,
    String? providerId,
  }) async {
    final String effectiveProviderId = providerId ?? 'local:${_uuid.v4()}';
    String? targetCalendarId = calendarId;
    if (targetCalendarId == null) {
      final Calendar? defaultCalendar = await findDefaultCalendar(accountId);
      if (defaultCalendar == null) {
        throw StateError(
          'createLocalEvent requires an explicit calendarId: account '
          '"$accountId" has no calendars.',
        );
      }
      targetCalendarId = defaultCalendar.id;
    }
    final CalendarEvent event = CalendarEvent(
      id: stableLocalId(accountId, effectiveProviderId),
      accountId: accountId,
      calendarId: targetCalendarId,
      providerId: effectiveProviderId,
      title: title,
      body: body,
      startEpochMs: startEpochMs,
      endEpochMs: endEpochMs,
      allDay: allDay,
      location: location,
      rrule: rrule,
      reminderMinutes: reminderMinutes,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    await _database
        .into(_database.events)
        .insert(
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
            updatedAt: event.updatedAt,
          ),
        );
    _notify();
    return event;
  }

  /// Overwrites all mutable fields of an existing event by [CalendarEvent.id]
  /// (local-only write path — no sync job enqueued). Stamps `updatedAt` to
  /// now regardless of the value on [event].
  Future<void> updateLocalEvent(CalendarEvent event) async {
    await (_database.update(
      _database.events,
    )..where((Events table) => table.id.equals(event.id))).write(
      EventsCompanion(
        calendarId: Value<String>(event.calendarId),
        title: Value<String>(event.title),
        body: Value<String?>(event.body),
        startEpochMs: Value<int>(event.startEpochMs),
        endEpochMs: Value<int>(event.endEpochMs),
        allDay: Value<bool>(event.allDay),
        location: Value<String?>(event.location),
        rrule: Value<String?>(event.rrule),
        reminderMinutes: Value<int?>(event.reminderMinutes),
        etag: Value<String?>(event.etag),
        updatedAt: Value<int>(DateTime.now().millisecondsSinceEpoch),
        deletedAt: Value<int?>(event.deletedAt),
      ),
    );
    _notify();
  }

  /// Marks an event deleted locally by stamping `deletedAt` (local-only —
  /// no sync job enqueued).
  Future<void> softDeleteEvent(String eventId) async {
    final int now = DateTime.now().millisecondsSinceEpoch;
    await (_database.update(
      _database.events,
    )..where((Events table) => table.id.equals(eventId))).write(
      EventsCompanion(deletedAt: Value<int?>(now), updatedAt: Value<int>(now)),
    );
    _notify();
  }

  Future<List<EventAttendee>> listEventAttendees(String eventId) async {
    final List<EventAttendeeRow> rows = await (_database.select(
      _database.eventAttendees,
    )..where((EventAttendees table) => table.eventId.equals(eventId))).get();
    return rows.map(_attendeeFromRow).toList(growable: false);
  }

  Future<void> upsertEventAttendees(List<EventAttendee> attendees) async {
    if (attendees.isEmpty) {
      return;
    }
    await _database.transaction(() async {
      for (final EventAttendee attendee in attendees) {
        await _database
            .into(_database.eventAttendees)
            .insertOnConflictUpdate(
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
      )..where((ContactLists table) => table.accountId.equals(accountId))).go();
    });
  }

  Future<ContactListRow?> _findContactListRow({
    required String accountId,
    required String providerId,
  }) {
    return (_database.select(_database.contactLists)
          ..where(
            (ContactLists table) =>
                table.accountId.equals(accountId) &
                table.providerId.equals(providerId),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<ContactRow?> _findContactRow({
    required String accountId,
    required String providerId,
  }) {
    return (_database.select(_database.contacts)
          ..where(
            (Contacts table) =>
                table.accountId.equals(accountId) &
                table.providerId.equals(providerId),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<CalendarRow?> _findCalendarRow({
    required String accountId,
    required String providerId,
  }) {
    return (_database.select(_database.calendars)
          ..where(
            (Calendars table) =>
                table.accountId.equals(accountId) &
                table.providerId.equals(providerId),
          )
          ..limit(1))
        .getSingleOrNull();
  }

  Future<EventRow?> _findEventRow({
    required String accountId,
    required String providerId,
  }) {
    return (_database.select(_database.events)
          ..where(
            (Events table) =>
                table.accountId.equals(accountId) &
                table.providerId.equals(providerId),
          )
          ..limit(1))
        .getSingleOrNull();
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
