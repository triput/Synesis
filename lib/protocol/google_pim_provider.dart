// ==============================================================================
// File: lib/protocol/google_pim_provider.dart
// Description: Google People + Calendar API adapter for XOAUTH PIM sync.
// Component: Protocol / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:synesis/domain/pim.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/pim/meeting_rsvp.dart';
import 'package:synesis/protocol/graph_mail_provider.dart'
    show GraphAuthException, GraphUnauthorizedHandler;
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/protocol/mail_provider.dart';

/// Alias of [kGraphEventHorizonPast] — Google Calendar window parity (90d).
const Duration kGoogleEventHorizonPast = kGraphEventHorizonPast;

/// Alias of [kGraphEventHorizonFuture] — Google Calendar window parity (365d).
const Duration kGoogleEventHorizonFuture = kGraphEventHorizonFuture;

/// Default Google Calendar blue when [backgroundColor] is absent.
const int kGoogleDefaultCalendarColorArgb = 0xFF4285F4;

/// Provider id for the synthetic / system "My Contacts" book.
const String kGoogleMyContactsGroupId = 'contactGroups/myContacts';

/// Read-only Google People + Calendar API adapter for PIM synchronization.
///
/// Extends [GraphPimProvider] so [GraphPimResolver] / SyncEngine typing stays
/// unchanged (same pattern as [DavPimProvider]). Google XOAUTH accounts use
/// **People + Calendar API only** — never CardDAV/CalDAV.
///
/// ## Event window
///
/// Bootstrap and non-`syncToken` event pulls use `events.list` bounded to
/// **past [kGoogleEventHorizonPast] (90d) / future [kGoogleEventHorizonFuture]
/// (365d)** — aliases of the Graph horizon constants. Incremental resumes use
/// Calendar `syncToken` when stored as the cursor (`deltaLink`). A Google
/// `410 GONE` means the sync token expired; SyncEngine clears the cursor and
/// re-bootstraps the window (same as Graph delta expiry).
///
/// ## Soft-delete
///
/// Incremental People/Calendar syncs with a valid `syncToken` populate
/// [GraphPimDeltaResult.removedProviderIds] from deleted / cancelled resources.
/// Full pulls (no cursor) return an empty removed list; SyncEngine applies
/// DAV-style missing soft-delete for [GooglePimProvider] on those snapshots.
///
/// ## Out of scope (Wave G)
///
/// RSVP / write-back (`respondToEvent`, contacts/events push) remain unsupported.
class GooglePimProvider extends GraphPimProvider {
  GooglePimProvider(
    Future<String> Function() accessToken, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 45),
    GraphUnauthorizedHandler? onUnauthorized,
  }) : this._create(
         accessToken,
         client ?? http.Client(),
         ownsClient: client == null,
         timeout: timeout,
         onUnauthorized: onUnauthorized,
       );

  GooglePimProvider._create(
    Future<String> Function() accessToken,
    http.Client innerClient, {
    required bool ownsClient,
    required Duration timeout,
    GraphUnauthorizedHandler? onUnauthorized,
  }) : _accessToken = accessToken,
       _ownsClient = ownsClient,
       _innerClient = innerClient,
       _onUnauthorized = onUnauthorized,
       super(
         accessToken,
         client: innerClient,
         onUnauthorized: onUnauthorized,
       ) {
    _client = _TimeoutClient(_innerClient, timeout);
  }

  static final Uri _peopleBaseUri = Uri.parse(
    'https://people.googleapis.com/v1',
  );
  static final Uri _calendarBaseUri = Uri.parse(
    'https://www.googleapis.com/calendar/v3',
  );

  static const int _maxPages = 40;
  static const String _personFields =
      'names,emailAddresses,phoneNumbers,organizations,biographies,'
      'metadata,photos';

  final Future<String> Function() _accessToken;
  final http.Client _innerClient;
  late final http.Client _client;
  final bool _ownsClient;
  final GraphUnauthorizedHandler? _onUnauthorized;
  bool _googleDisposed = false;

  @override
  Future<List<GraphContactFolder>> listContactFolders() async {
    final List<Map<String, Object?>> groups = <Map<String, Object?>>[];
    String? pageToken;
    for (int page = 0; page < _maxPages; page++) {
      final Map<String, Object?> document = await _getPeople(
        '/contactGroups',
        queryParameters: <String, String>{
          'pageSize': '100',
          if (pageToken != null) 'pageToken': pageToken,
        },
      );
      final Object? raw = document['contactGroups'];
      if (raw is List<Object?>) {
        for (final Object? entry in raw) {
          if (entry is Map<Object?, Object?>) {
            groups.add(
              entry.map(
                (Object? key, Object? value) => MapEntry(key.toString(), value),
              ),
            );
          }
        }
      }
      pageToken = _nonEmpty(document['nextPageToken'] as String?);
      if (pageToken == null) {
        break;
      }
    }

    final List<GraphContactFolder> folders = <GraphContactFolder>[];
    for (final Map<String, Object?> group in groups) {
      final String? resourceName = _nonEmpty(group['resourceName'] as String?);
      final String? name = _nonEmpty(group['name'] as String?);
      if (resourceName == null || name == null) {
        continue;
      }
      // Skip empty system buckets that are not contact books (e.g. "chatGone").
      final String? groupType = _nonEmpty(group['groupType'] as String?);
      if (groupType == 'SYSTEM_CONTACT_GROUP' &&
          resourceName != kGoogleMyContactsGroupId &&
          !resourceName.endsWith('/starred') &&
          !resourceName.endsWith('/friends') &&
          !resourceName.endsWith('/family') &&
          !resourceName.endsWith('/coworkers')) {
        continue;
      }
      folders.add(
        GraphContactFolder(
          providerId: resourceName,
          name: name,
          isDefault: resourceName == kGoogleMyContactsGroupId,
        ),
      );
    }

    if (folders.isEmpty) {
      folders.add(
        const GraphContactFolder(
          providerId: kGoogleMyContactsGroupId,
          name: 'My Contacts',
          isDefault: true,
        ),
      );
    } else if (!folders.any((GraphContactFolder f) => f.isDefault)) {
      final int myIndex = folders.indexWhere(
        (GraphContactFolder f) => f.providerId == kGoogleMyContactsGroupId,
      );
      if (myIndex >= 0) {
        folders[myIndex] = GraphContactFolder(
          providerId: folders[myIndex].providerId,
          name: folders[myIndex].name,
          isDefault: true,
        );
      } else {
        folders.insert(
          0,
          const GraphContactFolder(
            providerId: kGoogleMyContactsGroupId,
            name: 'My Contacts',
            isDefault: true,
          ),
        );
      }
    }

    // Prefer My Contacts first for stable sortIndex = 0 default.
    folders.sort((GraphContactFolder a, GraphContactFolder b) {
      if (a.isDefault != b.isDefault) {
        return a.isDefault ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return List<GraphContactFolder>.unmodifiable(folders);
  }

  @override
  List<ContactList> mapContactFolders(
    List<GraphContactFolder> folders, {
    required String accountId,
  }) {
    return List<ContactList>.generate(folders.length, (int index) {
      final GraphContactFolder folder = folders[index];
      return ContactList(
        id: PimIds.stableLocalId(accountId, folder.providerId),
        accountId: accountId,
        providerId: folder.providerId,
        name: folder.name,
        isDefault: folder.isDefault,
        isSelectedForDisplay: true,
        sortIndex: index,
      );
    }, growable: false);
  }

  @override
  Future<List<GraphCalendarInfo>> listCalendars() async {
    final List<Map<String, Object?>> entries = <Map<String, Object?>>[];
    String? pageToken;
    for (int page = 0; page < _maxPages; page++) {
      final Map<String, Object?> document = await _getCalendar(
        '/users/me/calendarList',
        queryParameters: <String, String>{
          'maxResults': '100',
          if (pageToken != null) 'pageToken': pageToken,
        },
      );
      entries.addAll(_calendarItems(document));
      pageToken = _nonEmpty(document['nextPageToken'] as String?);
      if (pageToken == null) {
        break;
      }
    }
    return entries.map(_calendarFromJson).toList(growable: false);
  }

  @override
  List<Calendar> mapCalendars(
    List<GraphCalendarInfo> calendars, {
    required String accountId,
  }) {
    return List<Calendar>.generate(calendars.length, (int index) {
      final GraphCalendarInfo calendar = calendars[index];
      return Calendar(
        id: PimIds.stableLocalId(accountId, calendar.providerId),
        accountId: accountId,
        providerId: calendar.providerId,
        name: calendar.name,
        colorArgb: calendar.colorArgb,
        isDefault: calendar.isDefault,
        isSelectedForDisplay: true,
        sortIndex: index,
      );
    }, growable: false);
  }

  @override
  Future<GraphPimDeltaResult<GraphContactBundle>> syncContacts({
    required String accountId,
    required String contactListId,
    required String folderProviderId,
    String? deltaLink,
  }) async {
    if (_isMyContactsFolder(folderProviderId)) {
      return _syncMyContacts(
        accountId: accountId,
        contactListId: contactListId,
        syncToken: deltaLink,
      );
    }
    return _syncContactGroupMembers(
      accountId: accountId,
      contactListId: contactListId,
      groupResourceName: folderProviderId,
    );
  }

  @override
  Future<GraphPimDeltaResult<GraphEventBundle>> syncEvents({
    required String accountId,
    required String calendarId,
    required String calendarProviderId,
    String? deltaLink,
    DateTime? now,
  }) async {
    final DateTime anchor = (now ?? DateTime.now()).toUtc();
    if (deltaLink != null && deltaLink.trim().isNotEmpty) {
      return _eventsIncremental(
        accountId: accountId,
        calendarId: calendarId,
        calendarProviderId: calendarProviderId,
        syncToken: deltaLink.trim(),
      );
    }
    return _eventsWindow(
      accountId: accountId,
      calendarId: calendarId,
      calendarProviderId: calendarProviderId,
      start: anchor.subtract(kGoogleEventHorizonPast),
      end: anchor.add(kGoogleEventHorizonFuture),
    );
  }

  @override
  Future<void> respondToEvent(
    String providerEventId,
    MeetingRsvpResponse response, {
    bool sendResponse = true,
  }) async {
    throw UnsupportedError(
      'Google Calendar RSVP is out of Wave G scope.',
    );
  }

  @override
  Future<Map<String, Object?>?> fetchAssociatedEventForMessage(
    String messageProviderId,
  ) async {
    return null;
  }

  @override
  Future<String?> findEventIdByICalUId(String iCalUId) async {
    return null;
  }

  @override
  Future<void> dispose() async {
    if (!_googleDisposed) {
      _googleDisposed = true;
      if (_ownsClient) {
        _innerClient.close();
      }
    }
    // Parent may own a separate client when constructed with a shared client
    // reference; Graph dispose is a no-op close when !_ownsClient.
    await super.dispose();
  }

  Future<GraphPimDeltaResult<GraphContactBundle>> _syncMyContacts({
    required String accountId,
    required String contactListId,
    String? syncToken,
  }) async {
    final List<GraphContactBundle> changed = <GraphContactBundle>[];
    final List<String> removed = <String>[];
    String? nextSyncToken;
    String? pageToken;
    final bool incremental =
        syncToken != null && syncToken.trim().isNotEmpty;

    for (int page = 0; page < _maxPages; page++) {
      final Map<String, String> query = <String, String>{
        'personFields': _personFields,
        'pageSize': '100',
        'requestSyncToken': 'true',
        if (incremental) 'syncToken': syncToken.trim(),
        if (pageToken != null) 'pageToken': pageToken,
      };
      final Map<String, Object?> document = await _getPeople(
        '/people/me/connections',
        queryParameters: query,
      );

      final Object? connections = document['connections'];
      if (connections is List<Object?>) {
        for (final Object? entry in connections) {
          if (entry is! Map<Object?, Object?>) {
            continue;
          }
          final Map<String, Object?> person = entry.map(
            (Object? key, Object? value) => MapEntry(key.toString(), value),
          );
          final Object? metadata = person['metadata'];
          final bool deleted =
              metadata is Map<Object?, Object?> &&
              metadata['deleted'] == true;
          final String? resourceName = _nonEmpty(
            person['resourceName'] as String?,
          );
          if (deleted) {
            if (resourceName != null) {
              removed.add(resourceName);
            }
            continue;
          }
          final GraphContactBundle? bundle = _contactBundleFromPerson(
            person,
            accountId: accountId,
            contactListId: contactListId,
          );
          if (bundle != null) {
            changed.add(bundle);
          }
        }
      }

      nextSyncToken =
          _nonEmpty(document['nextSyncToken'] as String?) ?? nextSyncToken;
      pageToken = _nonEmpty(document['nextPageToken'] as String?);
      if (pageToken == null) {
        break;
      }
    }

    return GraphPimDeltaResult<GraphContactBundle>(
      changed: List<GraphContactBundle>.unmodifiable(changed),
      removedProviderIds: List<String>.unmodifiable(removed),
      deltaLink: nextSyncToken,
    );
  }

  Future<GraphPimDeltaResult<GraphContactBundle>> _syncContactGroupMembers({
    required String accountId,
    required String contactListId,
    required String groupResourceName,
  }) async {
    final String encoded = groupResourceName.startsWith('contactGroups/')
        ? groupResourceName.substring('contactGroups/'.length)
        : groupResourceName;
    final Map<String, Object?> group = await _getPeople(
      '/contactGroups/${Uri.encodeComponent(encoded)}',
      queryParameters: const <String, String>{'maxMembers': '1000'},
    );
    final Object? memberNames = group['memberResourceNames'];
    final List<String> resourceNames = <String>[];
    if (memberNames is List<Object?>) {
      for (final Object? name in memberNames) {
        final String? trimmed = _nonEmpty(name?.toString());
        if (trimmed != null) {
          resourceNames.add(trimmed);
        }
      }
    }
    if (resourceNames.isEmpty) {
      return const GraphPimDeltaResult<GraphContactBundle>(
        changed: <GraphContactBundle>[],
        removedProviderIds: <String>[],
      );
    }

    final List<GraphContactBundle> changed = <GraphContactBundle>[];
    const int batchSize = 50;
    for (int offset = 0; offset < resourceNames.length; offset += batchSize) {
      final List<String> slice = resourceNames.sublist(
        offset,
        offset + batchSize > resourceNames.length
            ? resourceNames.length
            : offset + batchSize,
      );
      final Map<String, Object?> document = await _getPeople(
        '/people:batchGet',
        queryParameters: <String, String>{
          'personFields': _personFields,
          // http.Client encodes repeated keys via queryParameters — Google
          // expects multiple `resourceNames` params; build manually.
        },
        extraQuery: slice
            .map((String name) => MapEntry<String, String>('resourceNames', name))
            .toList(growable: false),
      );
      final Object? responses = document['responses'];
      if (responses is! List<Object?>) {
        continue;
      }
      for (final Object? entry in responses) {
        if (entry is! Map<Object?, Object?>) {
          continue;
        }
        final Object? personRaw = entry['person'];
        if (personRaw is! Map<Object?, Object?>) {
          continue;
        }
        final GraphContactBundle? bundle = _contactBundleFromPerson(
          personRaw.map(
            (Object? key, Object? value) => MapEntry(key.toString(), value),
          ),
          accountId: accountId,
          contactListId: contactListId,
        );
        if (bundle != null) {
          changed.add(bundle);
        }
      }
    }

    return GraphPimDeltaResult<GraphContactBundle>(
      changed: List<GraphContactBundle>.unmodifiable(changed),
      removedProviderIds: const <String>[],
    );
  }

  Future<GraphPimDeltaResult<GraphEventBundle>> _eventsWindow({
    required String accountId,
    required String calendarId,
    required String calendarProviderId,
    required DateTime start,
    required DateTime end,
  }) async {
    final List<GraphEventBundle> changed = <GraphEventBundle>[];
    String? pageToken;
    for (int page = 0; page < _maxPages; page++) {
      final Map<String, Object?> document = await _getCalendar(
        '/calendars/${Uri.encodeComponent(calendarProviderId)}/events',
        queryParameters: <String, String>{
          'timeMin': start.toUtc().toIso8601String(),
          'timeMax': end.toUtc().toIso8601String(),
          'maxResults': '250',
          'singleEvents': 'true',
          'orderBy': 'startTime',
          if (pageToken != null) 'pageToken': pageToken,
        },
      );
      for (final Map<String, Object?> item in _calendarItems(document)) {
        final GraphEventBundle? bundle = _eventBundleFromJson(
          item,
          accountId: accountId,
          calendarId: calendarId,
        );
        if (bundle != null) {
          changed.add(bundle);
        }
      }
      pageToken = _nonEmpty(document['nextPageToken'] as String?);
      if (pageToken == null) {
        break;
      }
    }
    return GraphPimDeltaResult<GraphEventBundle>(
      changed: List<GraphEventBundle>.unmodifiable(changed),
      removedProviderIds: const <String>[],
      // Windowed singleEvents pulls are full snapshots. Calendar syncToken is
      // incompatible with singleEvents; SyncEngine applies missing soft-delete.
      deltaLink: null,
    );
  }

  Future<GraphPimDeltaResult<GraphEventBundle>> _eventsIncremental({
    required String accountId,
    required String calendarId,
    required String calendarProviderId,
    required String syncToken,
  }) async {
    final List<GraphEventBundle> changed = <GraphEventBundle>[];
    final List<String> removed = <String>[];
    String? pageToken;
    String? nextSyncToken;

    for (int page = 0; page < _maxPages; page++) {
      final Map<String, Object?> document = await _getCalendar(
        '/calendars/${Uri.encodeComponent(calendarProviderId)}/events',
        queryParameters: <String, String>{
          'syncToken': syncToken,
          'maxResults': '250',
          'showDeleted': 'true',
          if (pageToken != null) 'pageToken': pageToken,
        },
      );
      for (final Map<String, Object?> item in _calendarItems(document)) {
        final String? id = _nonEmpty(item['id'] as String?);
        final String? status = _nonEmpty(item['status'] as String?);
        if (status == 'cancelled') {
          if (id != null) {
            removed.add(id);
          }
          continue;
        }
        final GraphEventBundle? bundle = _eventBundleFromJson(
          item,
          accountId: accountId,
          calendarId: calendarId,
        );
        if (bundle != null) {
          changed.add(bundle);
        }
      }
      nextSyncToken =
          _nonEmpty(document['nextSyncToken'] as String?) ?? nextSyncToken;
      pageToken = _nonEmpty(document['nextPageToken'] as String?);
      if (pageToken == null) {
        break;
      }
    }

    return GraphPimDeltaResult<GraphEventBundle>(
      changed: List<GraphEventBundle>.unmodifiable(changed),
      removedProviderIds: List<String>.unmodifiable(removed),
      deltaLink: nextSyncToken,
    );
  }

  GraphCalendarInfo _calendarFromJson(Map<String, Object?> json) {
    final String? id = _nonEmpty(json['id'] as String?);
    final String? summary = _nonEmpty(json['summary'] as String?);
    if (id == null || summary == null) {
      throw const ProtocolException(
        'Google Calendar returned a calendar without an id or summary.',
      );
    }
    return GraphCalendarInfo(
      providerId: id,
      name: summary,
      colorArgb:
          _parseHexColor(json['backgroundColor'] as String?) ??
          kGoogleDefaultCalendarColorArgb,
      isDefault: json['primary'] == true,
    );
  }

  GraphContactBundle? _contactBundleFromPerson(
    Map<String, Object?> json, {
    required String accountId,
    required String contactListId,
  }) {
    final String? providerId = _nonEmpty(json['resourceName'] as String?);
    if (providerId == null) {
      return null;
    }
    final String localId = PimIds.stableLocalId(accountId, providerId);

    String? given;
    String? family;
    String displayName = '';
    final Object? names = json['names'];
    if (names is List<Object?> && names.isNotEmpty) {
      final Object? primary = names.first;
      if (primary is Map<Object?, Object?>) {
        given = _nonEmpty(primary['givenName']?.toString());
        family = _nonEmpty(primary['familyName']?.toString());
        displayName =
            _nonEmpty(primary['displayName']?.toString()) ??
            <String?>[given, family]
                .whereType<String>()
                .where((String part) => part.isNotEmpty)
                .join(' ');
      }
    }

    String? company;
    final Object? orgs = json['organizations'];
    if (orgs is List<Object?> && orgs.isNotEmpty) {
      final Object? first = orgs.first;
      if (first is Map<Object?, Object?>) {
        company = _nonEmpty(first['name']?.toString());
      }
    }

    String? notes;
    final Object? bios = json['biographies'];
    if (bios is List<Object?> && bios.isNotEmpty) {
      final Object? first = bios.first;
      if (first is Map<Object?, Object?>) {
        notes = _nonEmpty(first['value']?.toString());
      }
    }

    int updatedAt = DateTime.now().millisecondsSinceEpoch;
    final Object? metadata = json['metadata'];
    if (metadata is Map<Object?, Object?>) {
      final Object? sources = metadata['sources'];
      if (sources is List<Object?>) {
        for (final Object? source in sources) {
          if (source is! Map<Object?, Object?>) {
            continue;
          }
          final int? ms = _parseEpochMs(source['updateTime']?.toString());
          if (ms != null && ms > updatedAt) {
            updatedAt = ms;
          }
        }
      }
    }

    final Contact contact = Contact(
      id: localId,
      accountId: accountId,
      contactListId: contactListId,
      providerId: providerId,
      displayName: displayName.isEmpty ? '(No name)' : displayName,
      givenName: given,
      familyName: family,
      company: company,
      notes: notes,
      etag: _nonEmpty(json['etag'] as String?),
      updatedAt: updatedAt,
    );

    final List<ContactEmail> emails = <ContactEmail>[];
    final Object? emailAddresses = json['emailAddresses'];
    if (emailAddresses is List<Object?>) {
      for (int i = 0; i < emailAddresses.length; i++) {
        final Object? entry = emailAddresses[i];
        if (entry is! Map<Object?, Object?>) {
          continue;
        }
        final String? address = _nonEmpty(entry['value']?.toString());
        if (address == null) {
          continue;
        }
        emails.add(
          ContactEmail(
            id: PimIds.stableLocalId(localId, 'email:${address.toLowerCase()}'),
            contactId: localId,
            address: address,
            type: _nonEmpty(entry['type']?.toString()) ?? 'other',
            isPrimary: i == 0,
          ),
        );
      }
    }

    final List<ContactPhone> phones = <ContactPhone>[];
    final Object? phoneNumbers = json['phoneNumbers'];
    if (phoneNumbers is List<Object?>) {
      for (final Object? entry in phoneNumbers) {
        if (entry is! Map<Object?, Object?>) {
          continue;
        }
        final String? number = _nonEmpty(entry['value']?.toString());
        if (number == null) {
          continue;
        }
        final String type = _nonEmpty(entry['type']?.toString()) ?? 'other';
        phones.add(
          ContactPhone(
            id: PimIds.stableLocalId(localId, 'phone:$type:$number'),
            contactId: localId,
            number: number,
            type: type,
          ),
        );
      }
    }

    return GraphContactBundle(contact: contact, emails: emails, phones: phones);
  }

  GraphEventBundle? _eventBundleFromJson(
    Map<String, Object?> json, {
    required String accountId,
    required String calendarId,
  }) {
    final String? providerId = _nonEmpty(json['id'] as String?);
    if (providerId == null) {
      return null;
    }
    final int? startMs = _parseGoogleDateTime(json['start']);
    final int? endMs = _parseGoogleDateTime(json['end']);
    if (startMs == null || endMs == null) {
      return null;
    }
    final String localId = PimIds.stableLocalId(accountId, providerId);
    final bool allDay = json['start'] is Map<Object?, Object?> &&
        (json['start'] as Map<Object?, Object?>).containsKey('date') &&
        !(json['start'] as Map<Object?, Object?>).containsKey('dateTime');

    final CalendarEvent event = CalendarEvent(
      id: localId,
      accountId: accountId,
      calendarId: calendarId,
      providerId: providerId,
      title: _nonEmpty(json['summary'] as String?) ?? '(No title)',
      body: _nonEmpty(json['description'] as String?),
      startEpochMs: startMs,
      endEpochMs: endMs,
      allDay: allDay,
      location: _nonEmpty(json['location'] as String?),
      rrule: _rruleFromRecurrence(json['recurrence']),
      reminderMinutes: _reminderMinutes(json['reminders']),
      etag: _nonEmpty(json['etag'] as String?),
      updatedAt:
          _parseEpochMs(json['updated'] as String?) ??
          DateTime.now().millisecondsSinceEpoch,
    );

    final List<EventAttendee> attendees = <EventAttendee>[];
    final Object? rawAttendees = json['attendees'];
    if (rawAttendees is List<Object?>) {
      for (final Object? entry in rawAttendees) {
        if (entry is! Map<Object?, Object?>) {
          continue;
        }
        final String? email = _nonEmpty(entry['email']?.toString());
        if (email == null) {
          continue;
        }
        attendees.add(
          EventAttendee(
            id: PimIds.stableLocalId(
              localId,
              'attendee:${email.toLowerCase()}',
            ),
            eventId: localId,
            email: email,
            displayName: _nonEmpty(entry['displayName']?.toString()),
            responseStatus: _nonEmpty(entry['responseStatus']?.toString()) ??
                'none',
            isOrganizer: entry['organizer'] == true,
          ),
        );
      }
    }

    return GraphEventBundle(event: event, attendees: attendees);
  }

  static bool _isMyContactsFolder(String folderProviderId) {
    final String id = folderProviderId.trim();
    return id.isEmpty ||
        id == kGoogleMyContactsGroupId ||
        id == 'myContacts' ||
        id == 'contacts' ||
        id == 'default';
  }

  static int? _parseHexColor(String? hex) {
    if (hex == null) {
      return null;
    }
    String cleaned = hex.trim();
    if (cleaned.isEmpty) {
      return null;
    }
    if (cleaned.startsWith('#')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.length == 6) {
      cleaned = 'FF$cleaned';
    }
    if (cleaned.length != 8) {
      return null;
    }
    return int.tryParse(cleaned, radix: 16);
  }

  static int? _parseEpochMs(String? iso) {
    if (iso == null || iso.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(iso)?.millisecondsSinceEpoch;
  }

  static int? _parseGoogleDateTime(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final String? dateTime = raw['dateTime']?.toString();
    if (dateTime != null && dateTime.isNotEmpty) {
      return DateTime.tryParse(dateTime)?.toUtc().millisecondsSinceEpoch;
    }
    final String? date = raw['date']?.toString();
    if (date != null && date.isNotEmpty) {
      return DateTime.tryParse('${date}T00:00:00Z')
          ?.toUtc()
          .millisecondsSinceEpoch;
    }
    return null;
  }

  static String? _rruleFromRecurrence(Object? recurrence) {
    if (recurrence is! List<Object?>) {
      return null;
    }
    for (final Object? entry in recurrence) {
      final String? line = _nonEmpty(entry?.toString());
      if (line == null) {
        continue;
      }
      if (line.toUpperCase().startsWith('RRULE:')) {
        return line.substring(6);
      }
      if (line.toUpperCase().startsWith('FREQ=')) {
        return line;
      }
    }
    return null;
  }

  static int? _reminderMinutes(Object? reminders) {
    if (reminders is! Map<Object?, Object?>) {
      return null;
    }
    final Object? overrides = reminders['overrides'];
    if (overrides is! List<Object?> || overrides.isEmpty) {
      return null;
    }
    final Object? first = overrides.first;
    if (first is! Map<Object?, Object?>) {
      return null;
    }
    final Object? minutes = first['minutes'];
    if (minutes is int) {
      return minutes;
    }
    return int.tryParse(minutes?.toString() ?? '');
  }

  static String? _nonEmpty(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static List<Map<String, Object?>> _calendarItems(
    Map<String, Object?> document,
  ) {
    final Object? values = document['items'];
    if (values == null) {
      return const <Map<String, Object?>>[];
    }
    if (values is! List<Object?>) {
      throw const ProtocolException(
        'Google Calendar response did not contain an items collection.',
      );
    }
    return values
        .whereType<Map<Object?, Object?>>()
        .map(
          (Map<Object?, Object?> item) => item.map(
            (Object? key, Object? value) => MapEntry(key.toString(), value),
          ),
        )
        .toList(growable: false);
  }

  Future<Map<String, Object?>> _getPeople(
    String path, {
    Map<String, String> queryParameters = const <String, String>{},
    List<MapEntry<String, String>> extraQuery =
        const <MapEntry<String, String>>[],
  }) async {
    final Uri uri = _buildUri(
      _peopleBaseUri,
      path,
      queryParameters: queryParameters,
      extraQuery: extraQuery,
    );
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.get(uri, headers: headers),
    );
    return _decodeObjectResponse(response);
  }

  Future<Map<String, Object?>> _getCalendar(
    String path, {
    Map<String, String> queryParameters = const <String, String>{},
  }) async {
    final Uri uri = _buildUri(
      _calendarBaseUri,
      path,
      queryParameters: queryParameters,
    );
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.get(uri, headers: headers),
    );
    return _decodeObjectResponse(response);
  }

  Uri _buildUri(
    Uri base,
    String path, {
    Map<String, String> queryParameters = const <String, String>{},
    List<MapEntry<String, String>> extraQuery =
        const <MapEntry<String, String>>[],
  }) {
    final Uri withPath = base.replace(path: '${base.path}$path');
    if (extraQuery.isEmpty) {
      return withPath.replace(queryParameters: queryParameters);
    }
    final List<String> parts = <String>[];
    queryParameters.forEach((String key, String value) {
      parts.add(
        '${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}',
      );
    });
    for (final MapEntry<String, String> entry in extraQuery) {
      parts.add(
        '${Uri.encodeQueryComponent(entry.key)}='
        '${Uri.encodeQueryComponent(entry.value)}',
      );
    }
    return withPath.replace(query: parts.join('&'));
  }

  Map<String, Object?> _decodeObjectResponse(http.Response response) {
    _ensureSuccess(response);
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<Object?, Object?>) {
      throw const ProtocolException('Google API returned an invalid JSON object.');
    }
    return decoded.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
  }

  Future<http.Response> _sendAuthorized(
    Future<http.Response> Function(Map<String, String> headers) send,
  ) async {
    _ensureNotDisposed();
    Future<http.Response> once() async {
      return send(await _headers());
    }

    http.Response response = await once();
    final GraphUnauthorizedHandler? onUnauthorized = _onUnauthorized;
    if (response.statusCode == 401 && onUnauthorized != null) {
      await onUnauthorized();
      response = await once();
    }
    return response;
  }

  Future<Map<String, String>> _headers() async {
    final String token = await _accessToken();
    if (token.trim().isEmpty) {
      throw const ProtocolException(
        'No Google access token is available.',
      );
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  void _ensureSuccess(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401) {
        throw const GraphAuthException();
      }
      String message = response.body;
      try {
        final Object? decoded = jsonDecode(response.body);
        if (decoded is Map<Object?, Object?>) {
          final Object? error = decoded['error'];
          if (error is Map<Object?, Object?>) {
            message = error['message'] as String? ?? message;
          }
        }
      } on FormatException {
        // Keep raw body.
      }
      if (response.statusCode == 403 && _isInsufficientScopesMessage(message)) {
        throw const ProtocolException(
          'Google access token is missing People/Calendar scopes (DEF-061). '
          'Edit account → Re-authenticate with Google and enable every '
          'Contacts/Calendar checkbox on Google\'s consent screen (boxes may '
          'default unchecked). Also enable People + Calendar APIs in Google '
          'Cloud.',
          statusCode: 403,
        );
      }
      throw ProtocolException(message, statusCode: response.statusCode);
    }
  }

  static bool _isInsufficientScopesMessage(String message) {
    final String normalized = message.toLowerCase();
    return normalized.contains('insufficient authentication scopes') ||
        normalized.contains('access_token_scope_insufficient');
  }

  void _ensureNotDisposed() {
    if (_googleDisposed) {
      throw const ProtocolException(
        'This Google PIM provider has been disposed.',
      );
    }
  }
}

class _TimeoutClient extends http.BaseClient {
  _TimeoutClient(this._inner, this._timeout);

  final http.Client _inner;
  final Duration _timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner
        .send(request)
        .timeout(
          _timeout,
          onTimeout: () {
            throw TimeoutException(
              'Google PIM request timed out after ${_timeout.inSeconds}s',
              _timeout,
            );
          },
        );
  }

  @override
  void close() => _inner.close();
}
