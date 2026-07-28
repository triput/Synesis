// ==============================================================================
// File: test/google_pim_provider_test.dart
// Description: Google People + Calendar PIM mapping fixtures (MockClient).
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
import 'package:synesis/protocol/google_pim_provider.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/protocol/mail_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('listContactFolders maps My Contacts to stable ContactList ids', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(request.url.host, 'people.googleapis.com');
      expect(request.url.path, contains('/contactGroups'));
      return http.Response(
        jsonEncode(<String, Object>{
          'contactGroups': <Map<String, Object>>[
            <String, Object>{
              'resourceName': 'contactGroups/myContacts',
              'name': 'My Contacts',
              'groupType': 'SYSTEM_CONTACT_GROUP',
            },
            <String, Object>{
              'resourceName': 'contactGroups/abc',
              'name': 'VIP',
              'groupType': 'USER_CONTACT_GROUP',
            },
          ],
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GooglePimProvider provider = GooglePimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    final List<GraphContactFolder> folders = await provider.listContactFolders();
    expect(folders.first.providerId, kGoogleMyContactsGroupId);
    expect(folders.first.isDefault, isTrue);

    final List<ContactList> lists = provider.mapContactFolders(
      folders,
      accountId: 'g1',
    );
    expect(
      lists.first.id,
      PimIds.stableLocalId('g1', kGoogleMyContactsGroupId),
    );
  });

  test('listCalendars parses backgroundColor and primary flag', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(request.url.host, 'www.googleapis.com');
      expect(request.url.path, contains('/calendarList'));
      return http.Response(
        jsonEncode(<String, Object>{
          'items': <Map<String, Object>>[
            <String, Object>{
              'id': 'primary',
              'summary': 'Trish',
              'backgroundColor': '#4285f4',
              'primary': true,
            },
            <String, Object>{
              'id': 'holidays',
              'summary': 'Holidays',
            },
          ],
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GooglePimProvider provider = GooglePimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    final List<GraphCalendarInfo> remote = await provider.listCalendars();
    expect(remote.first.colorArgb, 0xFF4285F4);
    expect(remote.first.isDefault, isTrue);
    expect(remote.last.colorArgb, kGoogleDefaultCalendarColorArgb);

    final List<Calendar> calendars = provider.mapCalendars(
      remote,
      accountId: 'g1',
    );
    expect(calendars.first.id, PimIds.stableLocalId('g1', 'primary'));
  });

  test('syncContacts maps connections and returns syncToken', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(request.url.path, contains('/people/me/connections'));
      expect(request.url.queryParameters['personFields'], isNotEmpty);
      expect(request.url.queryParameters['requestSyncToken'], 'true');
      return http.Response(
        jsonEncode(<String, Object>{
          'connections': <Map<String, Object>>[
            <String, Object>{
              'resourceName': 'people/c1',
              'etag': 'etag-1',
              'names': <Map<String, String>>[
                <String, String>{
                  'displayName': 'Ada Lovelace',
                  'givenName': 'Ada',
                  'familyName': 'Lovelace',
                },
              ],
              'emailAddresses': <Map<String, String>>[
                <String, String>{'value': 'ada@example.com', 'type': 'work'},
              ],
              'phoneNumbers': <Map<String, String>>[
                <String, String>{'value': '555-0100', 'type': 'mobile'},
              ],
              'organizations': <Map<String, String>>[
                <String, String>{'name': 'Analytical Engines'},
              ],
              'biographies': <Map<String, String>>[
                <String, String>{'value': 'Notes'},
              ],
              'metadata': <String, Object>{
                'sources': <Map<String, String>>[
                  <String, String>{'updateTime': '2026-07-27T12:00:00Z'},
                ],
              },
            },
            <String, Object>{
              'resourceName': 'people/gone',
              'metadata': <String, Object>{'deleted': true},
            },
          ],
          'nextSyncToken': 'people-sync-abc',
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GooglePimProvider provider = GooglePimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    final String listId = PimIds.stableLocalId('g1', kGoogleMyContactsGroupId);
    final GraphPimDeltaResult<GraphContactBundle> result = await provider
        .syncContacts(
          accountId: 'g1',
          contactListId: listId,
          folderProviderId: kGoogleMyContactsGroupId,
        );

    expect(result.changed, hasLength(1));
    expect(result.changed.single.contact.displayName, 'Ada Lovelace');
    expect(result.changed.single.contact.company, 'Analytical Engines');
    expect(result.changed.single.emails.single.address, 'ada@example.com');
    expect(result.changed.single.phones.single.number, '555-0100');
    expect(
      result.changed.single.contact.id,
      PimIds.stableLocalId('g1', 'people/c1'),
    );
    expect(result.removedProviderIds, <String>['people/gone']);
    expect(result.deltaLink, 'people-sync-abc');
  });

  test('syncEvents uses 90d/365d window query params', () async {
    final DateTime now = DateTime.utc(2026, 7, 27, 12);
    final http.Client client = MockClient((http.Request request) async {
      expect(request.url.path, contains('/calendars/primary/events'));
      final DateTime timeMin = DateTime.parse(
        request.url.queryParameters['timeMin']!,
      );
      final DateTime timeMax = DateTime.parse(
        request.url.queryParameters['timeMax']!,
      );
      expect(timeMin, now.subtract(kGoogleEventHorizonPast));
      expect(timeMax, now.add(kGoogleEventHorizonFuture));
      expect(request.url.queryParameters['singleEvents'], 'true');
      return http.Response(
        jsonEncode(<String, Object>{
          'items': <Map<String, Object>>[
            <String, Object>{
              'id': 'ev1',
              'summary': 'Standup',
              'description': 'Daily',
              'location': 'Room A',
              'start': <String, String>{'dateTime': '2026-07-27T15:00:00Z'},
              'end': <String, String>{'dateTime': '2026-07-27T15:30:00Z'},
              'updated': '2026-07-27T12:00:00Z',
              'attendees': <Map<String, Object>>[
                <String, Object>{
                  'email': 'ada@example.com',
                  'displayName': 'Ada',
                  'responseStatus': 'accepted',
                  'organizer': true,
                },
              ],
            },
          ],
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GooglePimProvider provider = GooglePimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    final String calId = PimIds.stableLocalId('g1', 'primary');
    final GraphPimDeltaResult<GraphEventBundle> result = await provider
        .syncEvents(
          accountId: 'g1',
          calendarId: calId,
          calendarProviderId: 'primary',
          now: now,
        );

    expect(result.changed, hasLength(1));
    expect(result.changed.single.event.title, 'Standup');
    expect(result.changed.single.event.id, PimIds.stableLocalId('g1', 'ev1'));
    expect(result.changed.single.attendees.single.email, 'ada@example.com');
    expect(result.deltaLink, isNull);
  });

  test('syncEvents with syncToken maps cancelled and throws on 410', () async {
    int calls = 0;
    final http.Client client = MockClient((http.Request request) async {
      calls += 1;
      if (calls == 1) {
        expect(request.url.queryParameters['syncToken'], 'stale-token');
        expect(request.url.queryParameters['showDeleted'], 'true');
        return http.Response(
          jsonEncode(<String, Object>{
            'error': <String, Object>{
              'code': 410,
              'message': 'Sync token is no longer valid',
            },
          }),
          410,
          headers: const <String, String>{'content-type': 'application/json'},
        );
      }
      fail('Unexpected second call in 410 test');
    });

    final GooglePimProvider provider = GooglePimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    await expectLater(
      provider.syncEvents(
        accountId: 'g1',
        calendarId: PimIds.stableLocalId('g1', 'primary'),
        calendarProviderId: 'primary',
        deltaLink: 'stale-token',
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

  test('syncEvents syncToken path returns cancelled as removed', () async {
    final http.Client client = MockClient((http.Request request) async {
      expect(request.url.queryParameters['syncToken'], 'good-token');
      return http.Response(
        jsonEncode(<String, Object>{
          'items': <Map<String, Object>>[
            <String, Object>{
              'id': 'ev-new',
              'summary': 'New',
              'start': <String, String>{'dateTime': '2026-08-01T10:00:00Z'},
              'end': <String, String>{'dateTime': '2026-08-01T11:00:00Z'},
            },
            <String, Object>{
              'id': 'ev-gone',
              'status': 'cancelled',
            },
          ],
          'nextSyncToken': 'good-token-2',
        }),
        200,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GooglePimProvider provider = GooglePimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    final GraphPimDeltaResult<GraphEventBundle> result = await provider
        .syncEvents(
          accountId: 'g1',
          calendarId: PimIds.stableLocalId('g1', 'primary'),
          calendarProviderId: 'primary',
          deltaLink: 'good-token',
        );

    expect(
      result.changed.map((GraphEventBundle b) => b.event.providerId),
      <String>['ev-new'],
    );
    expect(result.removedProviderIds, <String>['ev-gone']);
    expect(result.deltaLink, 'good-token-2');
  });

  test('listCalendars maps 403 insufficient scopes to DEF-061 guidance', () async {
    final http.Client client = MockClient((http.Request request) async {
      return http.Response(
        jsonEncode(<String, Object>{
          'error': <String, Object>{
            'code': 403,
            'message': 'Request had insufficient authentication scopes.',
            'status': 'PERMISSION_DENIED',
            'details': <Object>[
              <String, Object>{
                '@type': 'type.googleapis.com/google.rpc.ErrorInfo',
                'reason': 'ACCESS_TOKEN_SCOPE_INSUFFICIENT',
                'domain': 'googleapis.com',
              },
            ],
          },
        }),
        403,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GooglePimProvider provider = GooglePimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    await expectLater(
      provider.listCalendars(),
      throwsA(
        isA<ProtocolException>()
            .having(
              (ProtocolException e) => e.statusCode,
              'statusCode',
              403,
            )
            .having(
              (ProtocolException e) => e.message,
              'message',
              allOf(
                contains('DEF-061'),
                contains('ACCESS_TOKEN_SCOPE_INSUFFICIENT'),
                contains('Third-party'),
                contains('checkbox'),
              ),
            ),
      ),
    );
  });

  test('listCalendars maps 403 SERVICE_DISABLED to GCP enablement guidance', () async {
    final http.Client client = MockClient((http.Request request) async {
      return http.Response(
        jsonEncode(<String, Object>{
          'error': <String, Object>{
            'code': 403,
            'message':
                'Google Calendar API has not been used in project 1 before '
                'or it is disabled.',
            'status': 'PERMISSION_DENIED',
            'details': <Object>[
              <String, Object>{
                '@type': 'type.googleapis.com/google.rpc.ErrorInfo',
                'reason': 'SERVICE_DISABLED',
                'domain': 'googleapis.com',
              },
            ],
          },
        }),
        403,
        headers: const <String, String>{'content-type': 'application/json'},
      );
    });

    final GooglePimProvider provider = GooglePimProvider(
      () async => 'token',
      client: client,
    );
    addTearDown(provider.dispose);

    await expectLater(
      provider.listCalendars(),
      throwsA(
        isA<ProtocolException>()
            .having(
              (ProtocolException e) => e.statusCode,
              'statusCode',
              403,
            )
            .having(
              (ProtocolException e) => e.message,
              'message',
              allOf(
                contains('DEF-061'),
                contains('SERVICE_DISABLED'),
                contains('APIs & Services'),
                contains('SYNESIS_GOOGLE_CLIENT_ID'),
              ),
            ),
      ),
    );
  });
}
