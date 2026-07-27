// ==============================================================================
// File: test/graph_pim_provider_test.dart
// Description: Graph PIM mapping fixtures — folders, calendars, contacts, events.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/protocol/mail_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('listContactFolders maps to stable ContactList ids', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(request.url.path, contains('/me/contactFolders'));
      return http.Response(
        jsonEncode(<String, Object>{
          'value': <Map<String, Object>>[
            <String, Object>{
              'id': 'folder-default',
              'displayName': 'Contacts',
            },
            <String, Object>{
              'id': 'folder-vip',
              'displayName': 'VIP',
            },
          ],
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GraphPimProvider provider = GraphPimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    final List<GraphContactFolder> folders =
        await provider.listContactFolders();
    expect(folders, hasLength(2));
    expect(folders.first.isDefault, isTrue);

    final List<ContactList> lists = provider.mapContactFolders(
      folders,
      accountId: 'work',
    );
    expect(lists.singleWhere((ContactList l) => l.providerId == 'folder-default').id,
        PimIds.stableLocalId('work', 'folder-default'));
    expect(lists.map((ContactList l) => l.providerId).toList(),
        <String>['folder-default', 'folder-vip']);
  });

  test('listCalendars parses hexColor and default flag', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(request.url.path, contains('/me/calendars'));
      return http.Response(
        jsonEncode(<String, Object>{
          'value': <Map<String, Object>>[
            <String, Object>{
              'id': 'cal-1',
              'name': 'Calendar',
              'hexColor': '#FF0000',
              'isDefaultCalendar': true,
            },
            <String, Object>{
              'id': 'cal-2',
              'name': 'Birthdays',
              'isDefaultCalendar': false,
            },
          ],
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GraphPimProvider provider = GraphPimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    final List<GraphCalendarInfo> remote = await provider.listCalendars();
    expect(remote.first.colorArgb, 0xFFFF0000);
    expect(remote.first.isDefault, isTrue);
    expect(remote.last.colorArgb, kGraphDefaultCalendarColorArgb);

    final List<Calendar> calendars = provider.mapCalendars(
      remote,
      accountId: 'work',
    );
    expect(calendars.first.id, PimIds.stableLocalId('work', 'cal-1'));
  });

  test('syncContacts merges delta pages and removed ids', () async {
    int page = 0;
    final http.Client client = MockClient((http.Request request) async {
      page += 1;
      if (page == 1) {
        expect(request.url.path, contains('/contacts/delta'));
        return http.Response(
          jsonEncode(<String, Object>{
            'value': <Map<String, Object>>[
              <String, Object>{
                'id': 'c1',
                'displayName': 'Alice',
                'givenName': 'Alice',
                'surname': 'A',
                'emailAddresses': <Map<String, String>>[
                  <String, String>{'address': 'a@example.com'},
                ],
                'businessPhones': <String>['555-0100'],
                'lastModifiedDateTime': '2026-07-27T12:00:00Z',
              },
              <String, Object>{
                'id': 'c-gone',
                r'@removed': <String, String>{'reason': 'deleted'},
              },
            ],
            r'@odata.nextLink':
                'https://graph.microsoft.com/v1.0/me/contacts/delta?\$skiptoken=p2',
          }),
          200,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      return http.Response(
        jsonEncode(<String, Object>{
          'value': <Map<String, Object>>[
            <String, Object>{
              'id': 'c2',
              'displayName': 'Bob',
              'lastModifiedDateTime': '2026-07-27T13:00:00Z',
            },
          ],
          r'@odata.deltaLink':
              'https://graph.microsoft.com/v1.0/me/contacts/delta?\$deltatoken=abc',
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GraphPimProvider provider = GraphPimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    final String listId = PimIds.stableLocalId('work', 'contacts');
    final GraphPimDeltaResult<GraphContactBundle> result =
        await provider.syncContacts(
      accountId: 'work',
      contactListId: listId,
      folderProviderId: 'contacts',
    );

    expect(
      result.changed.map((GraphContactBundle b) => b.contact.providerId),
      <String>['c1', 'c2'],
    );
    expect(result.changed.first.emails.single.address, 'a@example.com');
    expect(result.changed.first.phones.single.number, '555-0100');
    expect(result.removedProviderIds, <String>['c-gone']);
    expect(result.deltaLink, contains('deltatoken=abc'));
    expect(
      result.changed.first.contact.id,
      PimIds.stableLocalId('work', 'c1'),
    );
  });

  test('syncEvents uses calendarView window when no deltaLink', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(request.url.path, contains('/calendarView'));
      expect(request.url.queryParameters.containsKey('startDateTime'), isTrue);
      expect(request.url.queryParameters.containsKey('endDateTime'), isTrue);
      return http.Response(
        jsonEncode(<String, Object>{
          'value': <Map<String, Object>>[
            <String, Object>{
              'id': 'ev1',
              'subject': 'Standup',
              'isAllDay': false,
              'start': <String, String>{
                'dateTime': '2026-07-27T15:00:00.0000000',
                'timeZone': 'UTC',
              },
              'end': <String, String>{
                'dateTime': '2026-07-27T15:30:00.0000000',
                'timeZone': 'UTC',
              },
              'location': <String, String>{'displayName': 'Room A'},
              'attendees': <Map<String, Object>>[
                <String, Object>{
                  'emailAddress': <String, String>{
                    'address': 'b@example.com',
                    'name': 'Bob',
                  },
                  'status': <String, String>{'response': 'accepted'},
                },
              ],
              'organizer': <String, Object>{
                'emailAddress': <String, String>{
                  'address': 'a@example.com',
                  'name': 'Alice',
                },
              },
              'lastModifiedDateTime': '2026-07-27T12:00:00Z',
            },
          ],
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GraphPimProvider provider = GraphPimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    final String calendarId = PimIds.stableLocalId('work', 'cal-1');
    final GraphPimDeltaResult<GraphEventBundle> result =
        await provider.syncEvents(
      accountId: 'work',
      calendarId: calendarId,
      calendarProviderId: 'cal-1',
      now: DateTime.utc(2026, 7, 27),
    );

    expect(result.changed, hasLength(1));
    expect(result.changed.single.event.title, 'Standup');
    expect(result.changed.single.event.location, 'Room A');
    expect(result.changed.single.attendees, hasLength(2));
    expect(
      result.changed.single.attendees
          .where((EventAttendee a) => a.isOrganizer)
          .single
          .email,
      'a@example.com',
    );
  });

  test('syncContacts surfaces HTTP 410 for expired delta', () async {
    final http.Client client = MockClient((http.Request request) async {
      return http.Response(
        jsonEncode(<String, Object>{
          'error': <String, String>{
            'code': 'resyncRequired',
            'message': 'Delta token expired',
          },
        }),
        410,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GraphPimProvider provider = GraphPimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    expect(
      () => provider.syncContacts(
        accountId: 'work',
        contactListId: 'list',
        folderProviderId: 'contacts',
        deltaLink:
            'https://graph.microsoft.com/v1.0/me/contacts/delta?\$deltatoken=old',
      ),
      throwsA(
        isA<ProtocolException>().having(
          (ProtocolException e) => e.statusCode,
          'statusCode',
          410,
        ),
      ),
    );
  });
}
