// ==============================================================================
// File: lib/protocol/graph_pim_provider.dart
// Description: Microsoft Graph contacts and calendars adapter for PIM sync.
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
import 'package:synesis/protocol/graph_mail_provider.dart'
    show GraphAuthException, GraphUnauthorizedHandler;
import 'package:synesis/protocol/mail_provider.dart';

/// Default Outlook blue when Graph omits calendar [hexColor].
const int kGraphDefaultCalendarColorArgb = 0xFF0078D4;

/// Event sync horizon: include events starting within the past 90 days.
const Duration kGraphEventHorizonPast = Duration(days: 90);

/// Event sync horizon: include events starting within the next 365 days.
const Duration kGraphEventHorizonFuture = Duration(days: 365);

/// Result of a Graph contacts or events delta / page set.
class GraphPimDeltaResult<T> {
  const GraphPimDeltaResult({
    required this.changed,
    required this.removedProviderIds,
    this.deltaLink,
  });

  final List<T> changed;
  final List<String> removedProviderIds;
  final String? deltaLink;
}

/// Remote contact folder metadata before local [ContactList] mapping.
class GraphContactFolder {
  const GraphContactFolder({
    required this.providerId,
    required this.name,
    this.isDefault = false,
  });

  final String providerId;
  final String name;
  final bool isDefault;
}

/// Remote calendar metadata before local [Calendar] mapping.
class GraphCalendarInfo {
  const GraphCalendarInfo({
    required this.providerId,
    required this.name,
    required this.colorArgb,
    this.isDefault = false,
  });

  final String providerId;
  final String name;
  final int colorArgb;
  final bool isDefault;
}

/// Contact payload including optional emails / phones for store upserts.
class GraphContactBundle {
  const GraphContactBundle({
    required this.contact,
    this.emails = const <ContactEmail>[],
    this.phones = const <ContactPhone>[],
  });

  final Contact contact;
  final List<ContactEmail> emails;
  final List<ContactPhone> phones;
}

/// Event payload including optional attendees for store upserts.
class GraphEventBundle {
  const GraphEventBundle({
    required this.event,
    this.attendees = const <EventAttendee>[],
  });

  final CalendarEvent event;
  final List<EventAttendee> attendees;
}

/// Polling Microsoft Graph adapter for contacts and calendars.
///
/// Mirrors [GraphMailProvider] auth patterns: bearer token, single 401 refresh
/// retry, `@odata.nextLink` / `@odata.deltaLink` pagination, and HTTP 410 for
/// expired delta tokens.
///
/// ## Event window
///
/// Bootstrap and non-delta event pulls use `calendarView` bounded to
/// **past [kGraphEventHorizonPast] (90d) / future [kGraphEventHorizonFuture]
/// (365d)** from [DateTime.now] (UTC). Incremental resumes prefer events
/// delta when a [deltaLink] is stored; on 410 the caller should clear the
/// cursor and re-bootstrap the window.
class GraphPimProvider {
  GraphPimProvider(
    this._accessToken, {
    http.Client? client,
    Duration timeout = const Duration(seconds: 45),
    GraphUnauthorizedHandler? onUnauthorized,
  })  : _ownsClient = client == null,
        _innerClient = client ?? http.Client(),
        _onUnauthorized = onUnauthorized {
    _client = _TimeoutClient(_innerClient, timeout);
  }

  static final Uri _graphBaseUri = Uri.parse('https://graph.microsoft.com/v1.0');

  static const int _maxPages = 40;
  static const String _contactSelect =
      'id,displayName,givenName,surname,companyName,personalNotes,'
      'emailAddresses,businessPhones,mobilePhone,homePhones,lastModifiedDateTime';
  static const String _eventSelect =
      'id,subject,bodyPreview,body,start,end,isAllDay,location,recurrence,'
      'reminderMinutesBeforeStart,lastModifiedDateTime,attendees,organizer,'
      '@odata.etag';

  final Future<String> Function() _accessToken;
  final http.Client _innerClient;
  late final http.Client _client;
  final bool _ownsClient;
  final GraphUnauthorizedHandler? _onUnauthorized;
  bool _disposed = false;

  /// Lists contact folders (`/me/contactFolders`), including a synthetic
  /// default when Graph only exposes contacts via `/me/contacts`.
  Future<List<GraphContactFolder>> listContactFolders() async {
    final List<Map<String, Object?>> pages = <Map<String, Object?>>[];
    Map<String, Object?> document = await _getCollection(
      '/me/contactFolders',
      queryParameters: <String, String>{
        r'$select': 'id,displayName,parentFolderId',
        r'$top': '100',
      },
    );
    for (int page = 0; page < _maxPages; page++) {
      pages.addAll(_values(document));
      final String? next = document[r'@odata.nextLink'] as String?;
      if (next == null || next.trim().isEmpty) {
        break;
      }
      document = await _getAbsoluteUrl(next.trim());
    }

    final List<GraphContactFolder> folders = pages
        .map(_contactFolderFromJson)
        .toList(growable: true);

    if (folders.isEmpty) {
      folders.add(
        const GraphContactFolder(
          providerId: 'contacts',
          name: 'Contacts',
          isDefault: true,
        ),
      );
    } else {
      final bool hasDefault = folders.any(
        (GraphContactFolder folder) => folder.isDefault,
      );
      if (!hasDefault) {
        folders[0] = GraphContactFolder(
          providerId: folders[0].providerId,
          name: folders[0].name,
          isDefault: true,
        );
      }
    }
    return List<GraphContactFolder>.unmodifiable(folders);
  }

  /// Maps remote folders to domain [ContactList] rows with stable local ids.
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

  /// Lists calendars (`/me/calendars`).
  Future<List<GraphCalendarInfo>> listCalendars() async {
    final List<Map<String, Object?>> pages = <Map<String, Object?>>[];
    Map<String, Object?> document = await _getCollection(
      '/me/calendars',
      queryParameters: <String, String>{
        r'$select': 'id,name,hexColor,isDefaultCalendar,color',
        r'$top': '100',
      },
    );
    for (int page = 0; page < _maxPages; page++) {
      pages.addAll(_values(document));
      final String? next = document[r'@odata.nextLink'] as String?;
      if (next == null || next.trim().isEmpty) {
        break;
      }
      document = await _getAbsoluteUrl(next.trim());
    }
    return pages.map(_calendarFromJson).toList(growable: false);
  }

  /// Maps remote calendars to domain [Calendar] rows with stable local ids.
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

  /// Bootstrap or incremental contacts for a folder.
  ///
  /// When [deltaLink] is null, starts a contacts delta (or falls back to a
  /// full list). When set, resumes from that opaque URL.
  ///
  /// Use [folderProviderId] `contacts` (or empty) for the default
  /// `/me/contacts` collection; otherwise `/me/contactFolders/{id}/contacts`.
  Future<GraphPimDeltaResult<GraphContactBundle>> syncContacts({
    required String accountId,
    required String contactListId,
    required String folderProviderId,
    String? deltaLink,
  }) async {
    final bool useDefaultPath = _isDefaultContactsFolder(folderProviderId);
    final List<GraphContactBundle> changed = <GraphContactBundle>[];
    final List<String> removed = <String>[];
    String? nextDeltaLink;

    Map<String, Object?> document;
    if (deltaLink != null && deltaLink.trim().isNotEmpty) {
      document = await _getAbsoluteUrl(deltaLink.trim());
    } else {
      try {
        document = await _getCollection(
          useDefaultPath
              ? '/me/contacts/delta'
              : '/me/contactFolders/'
                  '${Uri.encodeComponent(folderProviderId)}/contacts/delta',
          queryParameters: <String, String>{
            r'$select': _contactSelect,
          },
        );
      } on ProtocolException catch (error) {
        // Some tenants reject contact delta — fall back to a full list page.
        if (error.statusCode == 410) {
          rethrow;
        }
        return _listAllContacts(
          accountId: accountId,
          contactListId: contactListId,
          folderProviderId: folderProviderId,
          useDefaultPath: useDefaultPath,
        );
      }
    }

    for (int page = 0; page < _maxPages; page++) {
      _mergeContactDeltaPage(
        document,
        accountId: accountId,
        contactListId: contactListId,
        changed: changed,
        removed: removed,
      );
      final String? link = document[r'@odata.deltaLink'] as String?;
      if (link != null && link.trim().isNotEmpty) {
        nextDeltaLink = link.trim();
        break;
      }
      final String? next = document[r'@odata.nextLink'] as String?;
      if (next == null || next.trim().isEmpty) {
        break;
      }
      document = await _getAbsoluteUrl(next.trim());
    }

    return GraphPimDeltaResult<GraphContactBundle>(
      changed: List<GraphContactBundle>.unmodifiable(changed),
      removedProviderIds: List<String>.unmodifiable(removed),
      deltaLink: nextDeltaLink,
    );
  }

  /// Bootstrap or incremental events for a calendar.
  ///
  /// Prefer [deltaLink] when present. Otherwise loads a windowed
  /// `calendarView` (past 90d / future 365d). When delta is unavailable or
  /// fails (non-410), callers re-pull the same window on the next incremental.
  Future<GraphPimDeltaResult<GraphEventBundle>> syncEvents({
    required String accountId,
    required String calendarId,
    required String calendarProviderId,
    String? deltaLink,
    DateTime? now,
  }) async {
    final DateTime anchor = (now ?? DateTime.now()).toUtc();
    if (deltaLink != null && deltaLink.trim().isNotEmpty) {
      try {
        return await _eventsDelta(
          accountId: accountId,
          calendarId: calendarId,
          calendarProviderId: calendarProviderId,
          deltaLink: deltaLink.trim(),
        );
      } on ProtocolException catch (error) {
        if (error.statusCode == 410) {
          rethrow;
        }
        // Fall through to windowed calendarView.
      } on Object {
        // Fall through to windowed calendarView.
      }
    }

    return _calendarView(
      accountId: accountId,
      calendarId: calendarId,
      calendarProviderId: calendarProviderId,
      start: anchor.subtract(kGraphEventHorizonPast),
      end: anchor.add(kGraphEventHorizonFuture),
    );
  }

  Future<void> dispose() async {
    if (!_disposed) {
      _disposed = true;
      if (_ownsClient) {
        _innerClient.close();
      }
    }
  }

  Future<GraphPimDeltaResult<GraphContactBundle>> _listAllContacts({
    required String accountId,
    required String contactListId,
    required String folderProviderId,
    required bool useDefaultPath,
  }) async {
    final List<GraphContactBundle> changed = <GraphContactBundle>[];
    Map<String, Object?> document = await _getCollection(
      useDefaultPath
          ? '/me/contacts'
          : '/me/contactFolders/'
              '${Uri.encodeComponent(folderProviderId)}/contacts',
      queryParameters: <String, String>{
        r'$select': _contactSelect,
        r'$top': '100',
      },
    );
    for (int page = 0; page < _maxPages; page++) {
      for (final Map<String, Object?> item in _values(document)) {
        final GraphContactBundle? bundle = _contactBundleFromJson(
          item,
          accountId: accountId,
          contactListId: contactListId,
        );
        if (bundle != null) {
          changed.add(bundle);
        }
      }
      final String? next = document[r'@odata.nextLink'] as String?;
      if (next == null || next.trim().isEmpty) {
        break;
      }
      document = await _getAbsoluteUrl(next.trim());
    }
    return GraphPimDeltaResult<GraphContactBundle>(
      changed: List<GraphContactBundle>.unmodifiable(changed),
      removedProviderIds: const <String>[],
    );
  }

  Future<GraphPimDeltaResult<GraphEventBundle>> _calendarView({
    required String accountId,
    required String calendarId,
    required String calendarProviderId,
    required DateTime start,
    required DateTime end,
  }) async {
    final List<GraphEventBundle> changed = <GraphEventBundle>[];
    Map<String, Object?> document = await _getCollection(
      '/me/calendars/${Uri.encodeComponent(calendarProviderId)}/calendarView',
      queryParameters: <String, String>{
        'startDateTime': start.toUtc().toIso8601String(),
        'endDateTime': end.toUtc().toIso8601String(),
        r'$select': _eventSelect,
        r'$top': '100',
      },
    );
    for (int page = 0; page < _maxPages; page++) {
      for (final Map<String, Object?> item in _values(document)) {
        final GraphEventBundle? bundle = _eventBundleFromJson(
          item,
          accountId: accountId,
          calendarId: calendarId,
        );
        if (bundle != null) {
          changed.add(bundle);
        }
      }
      final String? next = document[r'@odata.nextLink'] as String?;
      if (next == null || next.trim().isEmpty) {
        break;
      }
      document = await _getAbsoluteUrl(next.trim());
    }
    return GraphPimDeltaResult<GraphEventBundle>(
      changed: List<GraphEventBundle>.unmodifiable(changed),
      removedProviderIds: const <String>[],
    );
  }

  Future<GraphPimDeltaResult<GraphEventBundle>> _eventsDelta({
    required String accountId,
    required String calendarId,
    required String calendarProviderId,
    String? deltaLink,
  }) async {
    final List<GraphEventBundle> changed = <GraphEventBundle>[];
    final List<String> removed = <String>[];
    String? nextDeltaLink;

    Map<String, Object?> document;
    if (deltaLink != null && deltaLink.isNotEmpty) {
      document = await _getAbsoluteUrl(deltaLink);
    } else {
      document = await _getCollection(
        '/me/calendars/${Uri.encodeComponent(calendarProviderId)}/events/delta',
        queryParameters: <String, String>{
          r'$select': _eventSelect,
        },
      );
    }

    for (int page = 0; page < _maxPages; page++) {
      for (final Map<String, Object?> item in _values(document)) {
        final Object? removedMeta = item[r'@removed'];
        final String? id = item['id'] as String?;
        if (removedMeta != null) {
          if (id != null && id.isNotEmpty) {
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
      final String? link = document[r'@odata.deltaLink'] as String?;
      if (link != null && link.trim().isNotEmpty) {
        nextDeltaLink = link.trim();
        break;
      }
      final String? next = document[r'@odata.nextLink'] as String?;
      if (next == null || next.trim().isEmpty) {
        break;
      }
      document = await _getAbsoluteUrl(next.trim());
    }

    return GraphPimDeltaResult<GraphEventBundle>(
      changed: List<GraphEventBundle>.unmodifiable(changed),
      removedProviderIds: List<String>.unmodifiable(removed),
      deltaLink: nextDeltaLink,
    );
  }

  void _mergeContactDeltaPage(
    Map<String, Object?> document, {
    required String accountId,
    required String contactListId,
    required List<GraphContactBundle> changed,
    required List<String> removed,
  }) {
    for (final Map<String, Object?> item in _values(document)) {
      final Object? removedMeta = item[r'@removed'];
      final String? id = item['id'] as String?;
      if (removedMeta != null) {
        if (id != null && id.isNotEmpty) {
          removed.add(id);
        }
        continue;
      }
      final GraphContactBundle? bundle = _contactBundleFromJson(
        item,
        accountId: accountId,
        contactListId: contactListId,
      );
      if (bundle != null) {
        changed.add(bundle);
      }
    }
  }

  GraphContactFolder _contactFolderFromJson(Map<String, Object?> json) {
    final String? id = json['id'] as String?;
    final String? name = json['displayName'] as String?;
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      throw const ProtocolException(
        'Graph returned a contact folder without an id or name.',
      );
    }
    final bool isDefault = name.toLowerCase() == 'contacts';
    return GraphContactFolder(
      providerId: id,
      name: name,
      isDefault: isDefault,
    );
  }

  GraphCalendarInfo _calendarFromJson(Map<String, Object?> json) {
    final String? id = json['id'] as String?;
    final String? name = json['name'] as String?;
    if (id == null || id.isEmpty || name == null || name.isEmpty) {
      throw const ProtocolException(
        'Graph returned a calendar without an id or name.',
      );
    }
    return GraphCalendarInfo(
      providerId: id,
      name: name,
      colorArgb: _parseGraphColor(json['hexColor'] as String?) ??
          kGraphDefaultCalendarColorArgb,
      isDefault: json['isDefaultCalendar'] as bool? ?? false,
    );
  }

  GraphContactBundle? _contactBundleFromJson(
    Map<String, Object?> json, {
    required String accountId,
    required String contactListId,
  }) {
    final String? providerId = json['id'] as String?;
    if (providerId == null || providerId.isEmpty) {
      return null;
    }
    final String localId = PimIds.stableLocalId(accountId, providerId);
    final String displayName = (json['displayName'] as String?)?.trim() ?? '';
    final String? given = (json['givenName'] as String?)?.trim();
    final String? family = (json['surname'] as String?)?.trim();
    final String resolvedName = displayName.isNotEmpty
        ? displayName
        : <String?>[given, family]
            .whereType<String>()
            .where((String part) => part.isNotEmpty)
            .join(' ');
    final int updatedAt = _parseEpochMs(
          json['lastModifiedDateTime'] as String?,
        ) ??
        DateTime.now().millisecondsSinceEpoch;

    final Contact contact = Contact(
      id: localId,
      accountId: accountId,
      contactListId: contactListId,
      providerId: providerId,
      displayName: resolvedName.isEmpty ? '(No name)' : resolvedName,
      givenName: given?.isEmpty == true ? null : given,
      familyName: family?.isEmpty == true ? null : family,
      company: _nonEmpty(json['companyName'] as String?),
      notes: _nonEmpty(json['personalNotes'] as String?),
      etag: _nonEmpty(json['@odata.etag'] as String?),
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
        final String? address =
            _nonEmpty(entry['address']?.toString());
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
    void addPhones(Object? raw, String type) {
      if (raw is List<Object?>) {
        for (final Object? entry in raw) {
          final String? number = _nonEmpty(entry?.toString());
          if (number == null) {
            continue;
          }
          phones.add(
            ContactPhone(
              id: PimIds.stableLocalId(localId, 'phone:$type:$number'),
              contactId: localId,
              number: number,
              type: type,
            ),
          );
        }
      } else {
        final String? number = _nonEmpty(raw?.toString());
        if (number != null) {
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
    }

    addPhones(json['businessPhones'], 'business');
    addPhones(json['homePhones'], 'home');
    addPhones(json['mobilePhone'], 'mobile');

    return GraphContactBundle(
      contact: contact,
      emails: emails,
      phones: phones,
    );
  }

  GraphEventBundle? _eventBundleFromJson(
    Map<String, Object?> json, {
    required String accountId,
    required String calendarId,
  }) {
    final String? providerId = json['id'] as String?;
    if (providerId == null || providerId.isEmpty) {
      return null;
    }
    final String localId = PimIds.stableLocalId(accountId, providerId);
    final int? startMs = _parseGraphDateTime(json['start']);
    final int? endMs = _parseGraphDateTime(json['end']);
    if (startMs == null || endMs == null) {
      return null;
    }
    final String title =
        _nonEmpty(json['subject'] as String?) ?? '(No title)';
    final String? bodyPreview = _nonEmpty(json['bodyPreview'] as String?);
    String? body = bodyPreview;
    final Object? bodyObj = json['body'];
    if (bodyObj is Map<Object?, Object?>) {
      body = _nonEmpty(bodyObj['content']?.toString()) ?? bodyPreview;
    }
    final Object? location = json['location'];
    String? locationName;
    if (location is Map<Object?, Object?>) {
      locationName = _nonEmpty(location['displayName']?.toString());
    }
    final int updatedAt = _parseEpochMs(
          json['lastModifiedDateTime'] as String?,
        ) ??
        DateTime.now().millisecondsSinceEpoch;

    final CalendarEvent event = CalendarEvent(
      id: localId,
      accountId: accountId,
      calendarId: calendarId,
      providerId: providerId,
      title: title,
      body: body,
      startEpochMs: startMs,
      endEpochMs: endMs,
      allDay: json['isAllDay'] as bool? ?? false,
      location: locationName,
      rrule: _rruleFromRecurrence(json['recurrence']),
      reminderMinutes: json['reminderMinutesBeforeStart'] as int?,
      etag: _nonEmpty(json['@odata.etag'] as String?) ??
          _nonEmpty(json['odata.etag'] as String?),
      updatedAt: updatedAt,
    );

    final List<EventAttendee> attendees = <EventAttendee>[];
    final Object? rawAttendees = json['attendees'];
    if (rawAttendees is List<Object?>) {
      for (final Object? entry in rawAttendees) {
        if (entry is! Map<Object?, Object?>) {
          continue;
        }
        final Map<Object?, Object?>? emailAddress =
            entry['emailAddress'] as Map<Object?, Object?>?;
        final String? email =
            _nonEmpty(emailAddress?['address']?.toString());
        if (email == null) {
          continue;
        }
        final Object? status = entry['status'];
        String response = 'none';
        if (status is Map<Object?, Object?>) {
          response = _nonEmpty(status['response']?.toString()) ?? 'none';
        }
        attendees.add(
          EventAttendee(
            id: PimIds.stableLocalId(localId, 'attendee:${email.toLowerCase()}'),
            eventId: localId,
            email: email,
            displayName: _nonEmpty(emailAddress?['name']?.toString()),
            responseStatus: response,
            isOrganizer: false,
          ),
        );
      }
    }
    final Object? organizer = json['organizer'];
    if (organizer is Map<Object?, Object?>) {
      final Map<Object?, Object?>? emailAddress =
          organizer['emailAddress'] as Map<Object?, Object?>?;
      final String? email = _nonEmpty(emailAddress?['address']?.toString());
      if (email != null) {
        final String attendeeId =
            PimIds.stableLocalId(localId, 'attendee:${email.toLowerCase()}');
        final int existing = attendees.indexWhere(
          (EventAttendee a) => a.id == attendeeId,
        );
        if (existing >= 0) {
          attendees[existing] = EventAttendee(
            id: attendeeId,
            eventId: localId,
            email: email,
            displayName: attendees[existing].displayName ??
                _nonEmpty(emailAddress?['name']?.toString()),
            responseStatus: attendees[existing].responseStatus,
            isOrganizer: true,
          );
        } else {
          attendees.add(
            EventAttendee(
              id: attendeeId,
              eventId: localId,
              email: email,
              displayName: _nonEmpty(emailAddress?['name']?.toString()),
              isOrganizer: true,
            ),
          );
        }
      }
    }

    return GraphEventBundle(event: event, attendees: attendees);
  }

  static bool _isDefaultContactsFolder(String folderProviderId) {
    final String id = folderProviderId.trim().toLowerCase();
    return id.isEmpty || id == 'contacts' || id == 'default';
  }

  static int? _parseGraphColor(String? hex) {
    if (hex == null) {
      return null;
    }
    String cleaned = hex.trim();
    if (cleaned.isEmpty || cleaned.toLowerCase() == 'auto') {
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

  static int? _parseGraphDateTime(Object? raw) {
    if (raw is! Map<Object?, Object?>) {
      return null;
    }
    final String? dateTime = raw['dateTime']?.toString();
    if (dateTime == null || dateTime.isEmpty) {
      return null;
    }
    // Graph may omit Z; treat as UTC when timezone is UTC / empty.
    final String? timeZone = raw['timeZone']?.toString();
    final String candidate = dateTime.endsWith('Z') || dateTime.contains('+')
        ? dateTime
        : (timeZone == null ||
                timeZone.isEmpty ||
                timeZone.toUpperCase() == 'UTC')
            ? '${dateTime}Z'
            : dateTime;
    return DateTime.tryParse(candidate)?.toUtc().millisecondsSinceEpoch;
  }

  static String? _rruleFromRecurrence(Object? recurrence) {
    // Wave 2 stores a compact marker; full RRULE expansion is later-wave.
    if (recurrence is! Map<Object?, Object?>) {
      return null;
    }
    final Object? pattern = recurrence['pattern'];
    if (pattern is! Map<Object?, Object?>) {
      return null;
    }
    final String? type = pattern['type']?.toString();
    if (type == null || type.isEmpty) {
      return null;
    }
    return 'FREQ=${type.toUpperCase()}';
  }

  static String? _nonEmpty(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  Future<Map<String, Object?>> _getCollection(
    String path, {
    required Map<String, String> queryParameters,
  }) =>
      _getObject(path, queryParameters: queryParameters);

  Future<Map<String, Object?>> _getObject(
    String path, {
    Map<String, String> queryParameters = const <String, String>{},
  }) async {
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.get(
        _uri(path, queryParameters: queryParameters),
        headers: headers,
      ),
    );
    return _decodeObjectResponse(response);
  }

  Future<Map<String, Object?>> _getAbsoluteUrl(String url) async {
    final Uri uri = Uri.parse(url);
    final http.Response response = await _sendAuthorized(
      (Map<String, String> headers) => _client.get(uri, headers: headers),
    );
    return _decodeObjectResponse(response);
  }

  Map<String, Object?> _decodeObjectResponse(http.Response response) {
    _ensureSuccess(response);
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<Object?, Object?>) {
      throw const ProtocolException('Graph returned an invalid JSON object.');
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

  Uri _uri(
    String path, {
    Map<String, String> queryParameters = const <String, String>{},
  }) =>
      _graphBaseUri.replace(
        path: '${_graphBaseUri.path}$path',
        queryParameters: queryParameters,
      );

  Future<Map<String, String>> _headers() async {
    final String token = await _accessToken();
    if (token.trim().isEmpty) {
      throw const ProtocolException(
        'No Microsoft Graph access token is available.',
      );
    }
    return <String, String>{
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    };
  }

  List<Map<String, Object?>> _values(Map<String, Object?> document) {
    final Object? values = document['value'];
    if (values is! List<Object?>) {
      throw const ProtocolException(
        'Graph response did not contain a value collection.',
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
      throw ProtocolException(message, statusCode: response.statusCode);
    }
  }

  void _ensureNotDisposed() {
    if (_disposed) {
      throw const ProtocolException('This Graph PIM provider has been disposed.');
    }
  }
}

class _TimeoutClient extends http.BaseClient {
  _TimeoutClient(this._inner, this._timeout);

  final http.Client _inner;
  final Duration _timeout;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    return _inner.send(request).timeout(
      _timeout,
      onTimeout: () {
        throw TimeoutException(
          'Microsoft Graph PIM request timed out after ${_timeout.inSeconds}s',
          _timeout,
        );
      },
    );
  }

  @override
  void close() => _inner.close();
}
