// ==============================================================================
// File: test/meeting_invite_service_test.dart
// Description: Local draft persistence and remote RSVP ordering coverage.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/pim/meeting_invite_service.dart';
import 'package:synesis/pim/meeting_rsvp.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/protocol/mail_provider.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';

const String _ics = '''
BEGIN:VCALENDAR
METHOD:REQUEST
BEGIN:VEVENT
UID:invite-42@example.com
DTSTART:20260727T150000Z
DTEND:20260727T160000Z
SUMMARY:Design review
ORGANIZER;CN=Casey:mailto:casey@example.com
ATTENDEE;CN=Alex:mailto:alex@example.com
END:VEVENT
END:VCALENDAR
''';

class _Fixture {
  _Fixture(this.database, this.pimStore, this.repository);

  final SynesisDatabase database;
  final DriftPimStore pimStore;
  final DriftMailRepository repository;
}

Future<_Fixture> _openFixture({
  String providerType = 'imap',
  bool withCalendar = true,
}) async {
  final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
  await database.customSelect('SELECT 1').get();
  final DriftPimStore pimStore = DriftPimStore(database, notify: () {});
  final DriftMailRepository repository = DriftMailRepository(database);
  await repository.upsertAccount(
    MailAccount(
      id: 'work',
      label: 'Work',
      address: 'alex@example.com',
      accent: const Color(0xFF2DD4BF),
      providerType: providerType,
    ),
    providerType: providerType,
  );
  if (withCalendar) {
    await pimStore.upsertCalendars(const <Calendar>[
      Calendar(
        id: 'ignored',
        accountId: 'work',
        providerId: 'primary',
        name: 'Calendar',
        colorArgb: 0xFF0078D4,
        isDefault: true,
      ),
    ]);
  }
  return _Fixture(database, pimStore, repository);
}

MailMessage _message() {
  return const MailMessage(
    id: 'local-message',
    accountId: 'work',
    fromName: 'Casey',
    fromAddress: 'casey@example.com',
    subject: 'Meeting invitation',
    snippet: '',
    body: _ics,
    whenLabel: 'now',
    bucket: FocusBucket.focused,
    providerId: 'message-1',
  );
}

MeetingInviteService _service(
  _Fixture fixture, {
  required Future<GraphPimProvider?> Function(String accountId) resolvePim,
}) {
  return MeetingInviteService(
    pimStore: fixture.pimStore,
    repository: fixture.repository,
    resolvePim: resolvePim,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('missing default calendar throws without writing an event', () async {
    final _Fixture fixture = await _openFixture(withCalendar: false);
    addTearDown(fixture.database.close);
    final MeetingInviteService service = _service(
      fixture,
      resolvePim: (_) async => null,
    );

    await expectLater(
      service.addIcsToCalendar(accountId: 'work', icsText: _ics),
      throwsStateError,
    );
    expect(await fixture.pimStore.listEvents(accountId: 'work'), isEmpty);
  });

  test('repeated ICS persistence and response keep one local event', () async {
    final _Fixture fixture = await _openFixture();
    addTearDown(fixture.database.close);
    final MeetingInviteService service = _service(
      fixture,
      resolvePim: (_) async => null,
    );

    await service.addIcsToCalendar(accountId: 'work', icsText: _ics);
    final MeetingInviteActionResult result = await service.respond(
      message: _message(),
      response: MeetingRsvpResponse.accept,
    );
    await service.addIcsToCalendar(accountId: 'work', icsText: _ics);

    final List<CalendarEvent> events = await fixture.pimStore.listEvents(
      accountId: 'work',
    );
    expect(events, hasLength(1));
    expect(events.single.providerId, 'ics:invite-42@example.com');
    expect(result.event.id, events.single.id);
  });

  test('non-Graph accounts persist the RSVP locally only', () async {
    final _Fixture fixture = await _openFixture();
    addTearDown(fixture.database.close);
    final MeetingInviteService service = _service(
      fixture,
      resolvePim: (_) async => null,
    );

    final MeetingInviteActionResult result = await service.respond(
      message: _message(),
      response: MeetingRsvpResponse.accept,
    );

    expect(result.serverResponseSent, isFalse);
    final List<EventAttendee> attendees = await fixture.pimStore
        .listEventAttendees(result.event.id);
    expect(
      attendees.singleWhere((EventAttendee attendee) => attendee.email == 'alex@example.com').responseStatus,
      'accepted',
    );
  });

  test('Graph falls back from a missing message event to iCalUId', () async {
    final _Fixture fixture = await _openFixture(providerType: 'graph');
    addTearDown(fixture.database.close);
    final List<String> paths = <String>[];
    final GraphPimProvider provider = GraphPimProvider(
      () async => 'token',
      client: MockClient((http.Request request) async {
        paths.add(request.url.path);
        if (request.url.path.endsWith('/messages/message-1/event')) {
          return http.Response('{"error":{"message":"Not found"}}', 404);
        }
        if (request.url.path.endsWith('/me/events')) {
          return http.Response(
            jsonEncode(<String, Object>{
              'value': <Map<String, String>>[
                <String, String>{'id': 'remote-event'},
              ],
            }),
            200,
          );
        }
        if (request.url.path.endsWith('/events/remote-event/accept')) {
          return http.Response('', 202);
        }
        throw StateError('Unexpected Graph request: ${request.url}');
      }),
    );
    addTearDown(provider.dispose);
    final MeetingInviteService service = _service(
      fixture,
      resolvePim: (_) async => provider,
    );

    final MeetingInviteActionResult result = await service.respond(
      message: _message(),
      response: MeetingRsvpResponse.accept,
    );

    expect(result.serverResponseSent, isTrue);
    expect(paths, <String>[
      '/v1.0/me/messages/message-1/event',
      '/v1.0/me/events',
      '/v1.0/me/events/remote-event/accept',
    ]);
    final List<EventAttendee> attendees = await fixture.pimStore
        .listEventAttendees(result.event.id);
    expect(
      attendees.singleWhere((EventAttendee attendee) => attendee.email == 'alex@example.com').responseStatus,
      'accepted',
    );
  });

  test('failed Graph RSVP preserves the ICS attendee response', () async {
    final _Fixture fixture = await _openFixture(providerType: 'graph');
    addTearDown(fixture.database.close);
    final GraphPimProvider provider = GraphPimProvider(
      () async => 'token',
      client: MockClient((http.Request request) async {
        if (request.url.path.endsWith('/messages/message-1/event')) {
          return http.Response(jsonEncode(<String, String>{'id': 'remote-event'}), 200);
        }
        if (request.url.path.endsWith('/events/remote-event/accept')) {
          return http.Response('{"error":{"message":"Forbidden"}}', 403);
        }
        throw StateError('Unexpected Graph request: ${request.url}');
      }),
    );
    addTearDown(provider.dispose);
    final MeetingInviteService service = _service(
      fixture,
      resolvePim: (_) async => provider,
    );

    await expectLater(
      service.respond(
        message: _message(),
        response: MeetingRsvpResponse.accept,
      ),
      throwsA(isA<ProtocolException>()),
    );

    final CalendarEvent event = (await fixture.pimStore.listEvents(
      accountId: 'work',
    )).single;
    final List<EventAttendee> attendees = await fixture.pimStore
        .listEventAttendees(event.id);
    expect(
      attendees.singleWhere((EventAttendee attendee) => attendee.email == 'alex@example.com').responseStatus,
      'none',
    );
  });
}
