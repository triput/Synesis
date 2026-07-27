import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/pim/ics_calendar_parser.dart';

void main() {
  const IcsCalendarParser parser = IcsCalendarParser();

  test('parses REQUEST invitation attendees and organizer', () {
    final IcsCalendar calendar = parser.parse('''
BEGIN:VCALENDAR
METHOD:REQUEST
BEGIN:VEVENT
UID:meeting-123@example.com
DTSTART:20260727T150000Z
DTEND:20260727T153000Z
SUMMARY:Planning
LOCATION:Room 3
ORGANIZER;CN=Casey:mailto:casey@example.com
ATTENDEE;CN=Alex:mailto:alex@example.com
ATTENDEE;CN=Blair:mailto:blair@example.com
DESCRIPTION:Agenda
END:VEVENT
END:VCALENDAR
''');

    expect(calendar.method, 'REQUEST');
    final IcsEvent event = calendar.events.single;
    expect(event.uid, 'meeting-123@example.com');
    expect(event.start, DateTime.utc(2026, 7, 27, 15));
    expect(event.end, DateTime.utc(2026, 7, 27, 15, 30));
    expect(event.organizer?.email, 'casey@example.com');
    expect(event.attendees.map((IcsAttendee a) => a.email), <String>[
      'alex@example.com',
      'blair@example.com',
    ]);
  });

  test('parses DATE values as an all-day event', () {
    final IcsEvent event = parser
        .parse('''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:all-day
DTSTART;VALUE=DATE:20260801
DTEND;VALUE=DATE:20260802
SUMMARY:Day off
END:VEVENT
END:VCALENDAR
''')
        .events
        .single;

    expect(event.allDay, isTrue);
    expect(event.start, DateTime.utc(2026, 8, 1));
    expect(event.end, DateTime.utc(2026, 8, 2));
  });

  test('unfolds lines, preserves TZID, and applies DURATION', () {
    final IcsEvent event = parser
        .parse('''
BEGIN:VCALENDAR
METHOD:PUBLISH
BEGIN:VEVENT
UID:folded
DTSTART;TZID=America/New_York:20260727T090000
DURATION:PT45M
SUMMARY:Quarterly
 planning
DESCRIPTION:Line one\\nLine two
END:VEVENT
END:VCALENDAR
''')
        .events
        .single;

    expect(event.startTimeZoneId, 'America/New_York');
    expect(event.end, DateTime.utc(2026, 7, 27, 9, 45));
    expect(event.summary, 'Quarterlyplanning');
    expect(event.description, 'Line one\nLine two');
  });

  test('returns no events for empty or malformed calendar content', () {
    expect(parser.parse('').events, isEmpty);
    expect(
      parser
          .parse('BEGIN:VCALENDAR\nBEGIN:VEVENT\nUID:broken')
          .events,
      isEmpty,
    );
  });

  test('does not map VEVENT entries missing UID or DTSTART', () {
    final IcsCalendar calendar = parser.parse('''
BEGIN:VCALENDAR
BEGIN:VEVENT
DTSTART:20260727T150000Z
END:VEVENT
BEGIN:VEVENT
UID:no-start
END:VEVENT
END:VCALENDAR
''');

    expect(calendar.events, isEmpty);
  });

  test('parses each valid VEVENT in source order', () {
    final IcsCalendar calendar = parser.parse('''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:first
DTSTART:20260727T150000Z
END:VEVENT
BEGIN:VEVENT
UID:second
DTSTART:20260727T160000Z
END:VEVENT
END:VCALENDAR
''');

    expect(calendar.events.map((IcsEvent event) => event.uid), <String>[
      'first',
      'second',
    ]);
  });
}
