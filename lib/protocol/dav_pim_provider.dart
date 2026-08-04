// ==============================================================================
// File: lib/protocol/dav_pim_provider.dart
// Description: CardDAV/CalDAV PIM adapter with create-only copy write (Wave 6b).
// Component: Protocol / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-08-04
// ==============================================================================

import 'package:http/http.dart' as http;
import 'package:synesis/domain/pim.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/pim/ics_calendar_parser.dart';
import 'package:synesis/pim/ics_calendar_writer.dart';
import 'package:synesis/protocol/dav/dav_client.dart';
import 'package:synesis/protocol/dav/dav_discovery.dart';
import 'package:synesis/protocol/dav/vcard_parser.dart';
import 'package:synesis/protocol/dav/vcard_writer.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:uuid/uuid.dart';

const Duration kDavEventHorizonPast = Duration(days: 90);
const Duration kDavEventHorizonFuture = Duration(days: 365);

class DavPimProvider extends GraphPimProvider {
  DavPimProvider({
    required this.emailAddress,
    required this.password,
    required this.baseUrl,
    this.carddavBaseUrl,
    this.caldavBaseUrl,
    this.imapHost,
    http.Client? client,
    Uuid? uuid,
  }) : _httpClient = client,
       _uuid = uuid ?? const Uuid(),
       super(() async => '', client: client);

  final String emailAddress;
  final String password;
  final String baseUrl;
  final String? carddavBaseUrl;
  final String? caldavBaseUrl;
  final String? imapHost;
  final http.Client? _httpClient;
  final Uuid _uuid;

  /// Creates a calendar object via CalDAV PUT (Wave 6b copy push).
  @override
  Future<PimRemoteCreateResult> createEvent({
    required String calendarProviderId,
    required CalendarEvent event,
  }) async {
    final String collectionHref = calendarProviderId.trim();
    if (collectionHref.isEmpty) {
      throw ArgumentError.value(
        calendarProviderId,
        'calendarProviderId',
        'Must not be empty.',
      );
    }
    final String uid = _uidForLocalProviderId(event.providerId);
    final Uri resourceUri = Uri.parse(collectionHref).resolve('$uid.ics');
    final String body = const IcsCalendarWriter().writeEvent(
      event: event,
      uid: uid,
    );
    final DavClient client = _client();
    try {
      final DavPutResult put = await client.put(
        resourceUri,
        body: body,
        contentType: 'text/calendar; charset=utf-8',
      );
      return PimRemoteCreateResult(
        providerId: put.href,
        etag: put.etag,
      );
    } finally {
      client.dispose();
    }
  }

  /// Creates an address-book object via CardDAV PUT (Wave 6b copy push).
  @override
  Future<PimRemoteCreateResult> createContact({
    required String folderProviderId,
    required Contact contact,
    List<ContactEmail> emails = const <ContactEmail>[],
    List<ContactPhone> phones = const <ContactPhone>[],
  }) async {
    final String collectionHref = folderProviderId.trim();
    if (collectionHref.isEmpty) {
      throw ArgumentError.value(
        folderProviderId,
        'folderProviderId',
        'Must not be empty.',
      );
    }
    final String uid = _uidForLocalProviderId(contact.providerId);
    final Uri resourceUri = Uri.parse(collectionHref).resolve('$uid.vcf');
    final String body = const VCardWriter().writeContact(
      contact: contact,
      uid: uid,
      emails: emails,
      phones: phones,
    );
    final DavClient client = _client();
    try {
      final DavPutResult put = await client.put(
        resourceUri,
        body: body,
        contentType: 'text/vcard; charset=utf-8',
      );
      return PimRemoteCreateResult(
        providerId: put.href,
        etag: put.etag,
      );
    } finally {
      client.dispose();
    }
  }

  @override
  Future<List<GraphContactFolder>> listContactFolders() async {
    final DavDiscovery discovery = _discovery(DavService.carddav);
    try {
      final DavDiscoveryResult result = await discovery.discover();
      return result.collections
          .map(
            (DavCollection collection) => GraphContactFolder(
              providerId: collection.href,
              name: collection.name,
              isDefault: collection.isDefault,
            ),
          )
          .toList(growable: false);
    } finally {
      discovery.dispose();
    }
  }

  @override
  List<ContactList> mapContactFolders(
    List<GraphContactFolder> folders, {
    required String accountId,
  }) => List<ContactList>.generate(folders.length, (int index) {
    final GraphContactFolder folder = folders[index];
    return ContactList(
      id: PimIds.stableLocalId(accountId, folder.providerId),
      accountId: accountId,
      providerId: folder.providerId,
      name: folder.name,
      isDefault: index == 0,
      isSelectedForDisplay: true,
      sortIndex: index,
    );
  }, growable: false);

  @override
  Future<List<GraphCalendarInfo>> listCalendars() async {
    final DavDiscovery discovery = _discovery(DavService.caldav);
    try {
      final DavDiscoveryResult result = await discovery.discover();
      return List<GraphCalendarInfo>.generate(result.collections.length, (
        int index,
      ) {
        final DavCollection collection = result.collections[index];
        return GraphCalendarInfo(
          providerId: collection.href,
          name: collection.name,
          colorArgb: 0xFF4285F4,
          isDefault: index == 0,
        );
      }, growable: false);
    } finally {
      discovery.dispose();
    }
  }

  @override
  List<Calendar> mapCalendars(
    List<GraphCalendarInfo> calendars, {
    required String accountId,
  }) => List<Calendar>.generate(calendars.length, (int index) {
    final GraphCalendarInfo calendar = calendars[index];
    return Calendar(
      id: PimIds.stableLocalId(accountId, calendar.providerId),
      accountId: accountId,
      providerId: calendar.providerId,
      name: calendar.name,
      colorArgb: calendar.colorArgb,
      isDefault: index == 0,
      isSelectedForDisplay: true,
      sortIndex: index,
    );
  }, growable: false);

  @override
  Future<GraphPimDeltaResult<GraphContactBundle>> syncContacts({
    required String accountId,
    required String contactListId,
    required String folderProviderId,
    String? deltaLink,
  }) async {
    final DavClient client = _client();
    try {
      final List<DavResponse> resources = await client.propFind(
        Uri.parse(folderProviderId),
        depth: 1,
        body: _contactResourcesRequest,
      );
      final List<GraphContactBundle> changed = <GraphContactBundle>[];
      for (final DavResponse resource in resources) {
        if (!resource.href.toLowerCase().endsWith('.vcf')) {
          continue;
        }
        final DavVCard? card = const VCardParser().parse(
          await client.get(Uri.parse(resource.href)),
        );
        if (card == null) {
          continue;
        }
        final String localId = PimIds.stableLocalId(accountId, resource.href);
        final int updated =
            DateTime.tryParse(card.revision ?? '')?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;
        changed.add(
          GraphContactBundle(
            contact: Contact(
              id: localId,
              accountId: accountId,
              contactListId: contactListId,
              providerId: resource.href,
              displayName: card.displayName,
              givenName: card.givenName,
              familyName: card.familyName,
              etag: resource.etag,
              updatedAt: updated,
            ),
            emails: List<ContactEmail>.generate(card.emails.length, (
              int index,
            ) {
              final DavVCardValue email = card.emails[index];
              return ContactEmail(
                id: PimIds.stableLocalId(
                  localId,
                  'email:${email.value.toLowerCase()}',
                ),
                contactId: localId,
                address: email.value,
                type: email.type,
                isPrimary: index == 0,
              );
            }, growable: false),
            phones: card.phones
                .map(
                  (DavVCardValue phone) => ContactPhone(
                    id: PimIds.stableLocalId(
                      localId,
                      'phone:${phone.type}:${phone.value}',
                    ),
                    contactId: localId,
                    number: phone.value,
                    type: phone.type,
                  ),
                )
                .toList(growable: false),
          ),
        );
      }
      return GraphPimDeltaResult<GraphContactBundle>(
        changed: changed,
        removedProviderIds: const <String>[],
        deltaLink: _cursor(resources),
      );
    } finally {
      client.dispose();
    }
  }

  @override
  Future<GraphPimDeltaResult<GraphEventBundle>> syncEvents({
    required String accountId,
    required String calendarId,
    required String calendarProviderId,
    String? deltaLink,
    DateTime? now,
  }) async {
    final DavClient client = _client();
    try {
      final DateTime anchor = (now ?? DateTime.now()).toUtc();
      final List<DavResponse> resources = await client.report(
        Uri.parse(calendarProviderId),
        body: _calendarQuery(
          anchor.subtract(kDavEventHorizonPast),
          anchor.add(kDavEventHorizonFuture),
        ),
      );
      final List<GraphEventBundle> changed = <GraphEventBundle>[];
      for (final DavResponse resource in resources) {
        final String calendarData =
            resource.propertyNamed('calendar-data') ?? '';
        final List<IcsEvent> events = const IcsCalendarParser()
            .parse(calendarData)
            .events;
        for (final IcsEvent event in events) {
          final String providerId = resource.href;
          final String localId = PimIds.stableLocalId(accountId, providerId);
          changed.add(
            GraphEventBundle(
              event: CalendarEvent(
                id: localId,
                accountId: accountId,
                calendarId: calendarId,
                providerId: providerId,
                title: event.summary ?? '(No title)',
                body: event.description,
                startEpochMs: event.start.millisecondsSinceEpoch,
                endEpochMs: event.end.millisecondsSinceEpoch,
                allDay: event.allDay,
                location: event.location,
                etag: resource.etag,
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              ),
              attendees: _attendees(localId, event),
            ),
          );
        }
      }
      return GraphPimDeltaResult<GraphEventBundle>(
        changed: changed,
        removedProviderIds: const <String>[],
        deltaLink: _cursor(resources),
      );
    } finally {
      client.dispose();
    }
  }

  DavDiscovery _discovery(DavService service) => DavDiscovery(
    service: service,
    emailAddress: emailAddress,
    password: password,
    knownBaseUrl: service == DavService.carddav
        ? (carddavBaseUrl ?? baseUrl)
        : (caldavBaseUrl ?? baseUrl),
    imapHost: imapHost,
    client: _httpClient,
  );

  DavClient _client() => DavClient(
    username: emailAddress,
    password: password,
    client: _httpClient,
  );

  /// Prefer uuid from `local:{uuid}`; otherwise mint a fresh id for the PUT.
  String _uidForLocalProviderId(String providerId) {
    if (PimIds.isLocalProviderId(providerId)) {
      final String stem = providerId.substring('local:'.length).trim();
      if (stem.isNotEmpty) {
        return stem;
      }
    }
    return _uuid.v4();
  }

  static List<EventAttendee> _attendees(String eventId, IcsEvent event) {
    final List<IcsAttendee> people = <IcsAttendee>[
      if (event.organizer != null) event.organizer!,
      ...event.attendees,
    ];
    return List<EventAttendee>.generate(people.length, (int index) {
      final IcsAttendee person = people[index];
      return EventAttendee(
        id: PimIds.stableLocalId(
          eventId,
          'attendee:${person.email.toLowerCase()}',
        ),
        eventId: eventId,
        email: person.email,
        displayName: person.commonName,
        isOrganizer: event.organizer?.email == person.email,
      );
    }, growable: false);
  }

  static String? _cursor(List<DavResponse> resources) {
    for (final DavResponse response in resources) {
      final String? token = response.propertyNamed('sync-token');
      if (token != null && token.isNotEmpty) {
        return token;
      }
    }
    return null;
  }

  static const String _contactResourcesRequest =
      '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:getetag/><d:resourcetype/><d:sync-token/></d:prop></d:propfind>';

  static String _calendarQuery(DateTime start, DateTime end) =>
      '<?xml version="1.0"?><c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav"><d:prop><d:getetag/><d:sync-token/><c:calendar-data/></d:prop><c:filter><c:comp-filter name="VCALENDAR"><c:comp-filter name="VEVENT"><c:time-range start="${_ical(start)}" end="${_ical(end)}"/></c:comp-filter></c:comp-filter></c:filter></c:calendar-query>';

  static String _ical(DateTime value) =>
      value
          .toUtc()
          .toIso8601String()
          .replaceAll('-', '')
          .replaceAll(':', '')
          .split('.')
          .first +
      'Z';

  @override
  Future<void> dispose() async {}
}
