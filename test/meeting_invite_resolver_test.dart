import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/pim/meeting_invite_resolver.dart';
import 'package:synesis/protocol/mail_provider.dart';

void main() {
  const MeetingInviteResolver resolver = MeetingInviteResolver();

  test('detects a text/calendar attachment and maps stable local values', () {
    const String ics = '''
BEGIN:VCALENDAR
METHOD:REQUEST
BEGIN:VEVENT
UID:<invite-42@example.com>
DTSTART:20260727T150000Z
DTEND:20260727T160000Z
SUMMARY:Design review
ORGANIZER;CN=Casey:mailto:casey@example.com
ATTENDEE;CN=Alex:mailto:alex@example.com
END:VEVENT
END:VCALENDAR
''';
    final MeetingInviteDetection detection = resolver.detect(
      message: _message(),
      attachments: const <MailAttachmentMeta>[
        MailAttachmentMeta(
          partId: 'part-1',
          name: 'invite.ics',
          contentType: 'text/calendar',
        ),
      ],
      icsText: ics,
    );

    expect(detection.isInvite, isTrue);
    expect(detection.method, 'REQUEST');
    expect(detection.uid, '<invite-42@example.com>');
    expect(detection.graphLookupKeys.messageProviderId, 'graph-message-1');

    final event = resolver.mapEvent(
      event: detection.event!,
      accountId: 'work',
      calendarId: 'cal-local',
      now: DateTime.utc(2026, 7, 27),
    );
    expect(event.providerId, 'ics:invite-42@example.com');
    expect(event.id, PimIds.stableLocalId('work', 'ics:invite-42@example.com'));
    final attendees = resolver.mapAttendees(
      event: detection.event!,
      eventId: event.id,
    );
    expect(attendees, hasLength(2));
    expect(
      attendees.where((attendee) => attendee.isOrganizer).single.email,
      'casey@example.com',
    );
  });

  test('detects BEGIN:VCALENDAR in message body without attachments', () {
    final MeetingInviteDetection detection = resolver.detect(
      message: _message(
        body: '''
Please review:
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:body-invite
DTSTART:20260727T150000Z
DTEND:20260727T160000Z
END:VEVENT
END:VCALENDAR
''',
      ),
    );

    expect(detection.isInvite, isTrue);
    expect(detection.uid, 'body-invite');
  });

  test('treats malformed calendar content as a non-mapped invite', () {
    final MeetingInviteDetection detection = resolver.detect(
      message: _message(body: 'BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:missing-end'),
    );

    expect(detection.isInvite, isTrue);
    expect(detection.event, isNull);
    expect(detection.uid, isNull);
  });

  test('uses the first valid event when a calendar contains multiple VEVENTs', () {
    final MeetingInviteDetection detection = resolver.detect(
      message: _message(
        body: '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:first-invite
DTSTART:20260727T150000Z
END:VEVENT
BEGIN:VEVENT
UID:second-invite
DTSTART:20260727T160000Z
END:VEVENT
END:VCALENDAR
''',
      ),
    );

    expect(detection.isInvite, isTrue);
    expect(detection.uid, 'first-invite');
  });
}

MailMessage _message({String body = 'Normal mail body'}) {
  return MailMessage(
    id: 'local-1',
    accountId: 'work',
    fromName: 'Casey',
    fromAddress: 'casey@example.com',
    subject: 'Meeting invitation',
    snippet: '',
    body: body,
    whenLabel: 'now',
    bucket: FocusBucket.focused,
    providerId: 'graph-message-1',
  );
}
