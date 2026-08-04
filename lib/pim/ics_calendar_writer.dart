// ==============================================================================
// File: lib/pim/ics_calendar_writer.dart
// Description: Minimal RFC 5545 VEVENT serializer for CalDAV create (Wave 6b).
// Component: PIM / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-08-04
// Last Update: 2026-08-04
// ==============================================================================

import 'package:synesis/domain/pim.dart';

/// Builds a single-event VCALENDAR body for CalDAV PUT create.
///
/// Field set matches Wave 6 copy push (title/body/location/times/reminder).
/// Attendees and RRULE are intentionally omitted.
class IcsCalendarWriter {
  const IcsCalendarWriter();

  /// Serializes [event] as a VCALENDAR containing one VEVENT with [uid].
  String writeEvent({
    required CalendarEvent event,
    required String uid,
    DateTime? now,
  }) {
    final DateTime stamp = (now ?? DateTime.now()).toUtc();
    final List<String> lines = <String>[
      'BEGIN:VCALENDAR',
      'VERSION:2.0',
      'PRODID:-//Synesis//PIM//EN',
      'CALSCALE:GREGORIAN',
      'BEGIN:VEVENT',
      'UID:$uid',
      'DTSTAMP:${_formatUtcDateTime(stamp)}',
      'SUMMARY:${_escapeText(event.title)}',
    ];
    if (event.allDay) {
      lines.add(
        'DTSTART;VALUE=DATE:${_formatDate(event.startEpochMs)}',
      );
      lines.add(
        'DTEND;VALUE=DATE:${_formatDate(event.endEpochMs)}',
      );
    } else {
      lines.add(
        'DTSTART:${_formatUtcDateTime(
          DateTime.fromMillisecondsSinceEpoch(
            event.startEpochMs,
            isUtc: true,
          ),
        )}',
      );
      lines.add(
        'DTEND:${_formatUtcDateTime(
          DateTime.fromMillisecondsSinceEpoch(
            event.endEpochMs,
            isUtc: true,
          ),
        )}',
      );
    }
    final String? description = _nonEmpty(event.body);
    if (description != null) {
      lines.add('DESCRIPTION:${_escapeText(description)}');
    }
    final String? location = _nonEmpty(event.location);
    if (location != null) {
      lines.add('LOCATION:${_escapeText(location)}');
    }
    final int? reminder = event.reminderMinutes;
    if (reminder != null && reminder >= 0) {
      lines.addAll(<String>[
        'BEGIN:VALARM',
        'ACTION:DISPLAY',
        'DESCRIPTION:Reminder',
        'TRIGGER:-PT${reminder}M',
        'END:VALARM',
      ]);
    }
    lines.addAll(const <String>['END:VEVENT', 'END:VCALENDAR']);
    return '${lines.map(_foldLine).join('\r\n')}\r\n';
  }

  static String _formatUtcDateTime(DateTime value) {
    final DateTime utc = value.toUtc();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}'
        '${two(utc.month)}'
        '${two(utc.day)}'
        'T'
        '${two(utc.hour)}'
        '${two(utc.minute)}'
        '${two(utc.second)}'
        'Z';
  }

  static String _formatDate(int epochMs) {
    final DateTime utc = DateTime.fromMillisecondsSinceEpoch(
      epochMs,
      isUtc: true,
    );
    String two(int n) => n.toString().padLeft(2, '0');
    return '${utc.year.toString().padLeft(4, '0')}'
        '${two(utc.month)}'
        '${two(utc.day)}';
  }

  static String _escapeText(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('\r\n', r'\n')
        .replaceAll('\n', r'\n')
        .replaceAll('\r', r'\n')
        .replaceAll(',', r'\,')
        .replaceAll(';', r'\;');
  }

  static String _foldLine(String line) {
    // RFC 5545: fold at 75 octets. ASCII-only Synesis bodies → char == octet.
    if (line.length <= 75) {
      return line;
    }
    final StringBuffer buffer = StringBuffer(line.substring(0, 75));
    int index = 75;
    while (index < line.length) {
      final int end = index + 74 > line.length ? line.length : index + 74;
      buffer
        ..write('\r\n ')
        ..write(line.substring(index, end));
      index = end;
    }
    return buffer.toString();
  }

  static String? _nonEmpty(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
