// ==============================================================================
// File: lib/pim/ics_calendar_parser.dart
// Description: Pure Dart RFC 5545 calendar invitation parser.
// Component: PIM / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

/// A parsed iCalendar document containing zero or more events.
class IcsCalendar {
  const IcsCalendar({required this.events, this.method});

  final String? method;
  final List<IcsEvent> events;
}

/// A parsed calendar event suitable for local calendar mapping.
class IcsEvent {
  const IcsEvent({
    required this.uid,
    required this.start,
    required this.end,
    required this.allDay,
    this.summary,
    this.location,
    this.organizer,
    this.description,
    this.startTimeZoneId,
    this.endTimeZoneId,
    this.attendees = const <IcsAttendee>[],
  });

  final String uid;
  final DateTime start;
  final DateTime end;
  final bool allDay;
  final String? summary;
  final String? location;
  final IcsAttendee? organizer;
  final String? description;
  final String? startTimeZoneId;
  final String? endTimeZoneId;
  final List<IcsAttendee> attendees;
}

/// An organizer or attendee declared in an iCalendar event.
class IcsAttendee {
  const IcsAttendee({required this.email, this.commonName});

  final String email;
  final String? commonName;
}

/// Parses RFC 5545 VCALENDAR content without platform-specific dependencies.
class IcsCalendarParser {
  const IcsCalendarParser();

  IcsCalendar parse(String content) {
    final List<String> lines = _unfold(content);
    String? method;
    final List<IcsEvent> events = <IcsEvent>[];
    _EventBuilder? event;

    for (final String line in lines) {
      final _IcsProperty? property = _IcsProperty.tryParse(line);
      if (property == null) {
        continue;
      }
      if (property.name == 'METHOD' && event == null) {
        method = _nonEmpty(property.value)?.toUpperCase();
        continue;
      }
      if (property.name == 'BEGIN' &&
          property.value.toUpperCase() == 'VEVENT') {
        event = _EventBuilder();
        continue;
      }
      if (property.name == 'END' && property.value.toUpperCase() == 'VEVENT') {
        final _EventBuilder? completed = event;
        event = null;
        if (completed != null) {
          final IcsEvent? parsed = completed.build();
          if (parsed != null) {
            events.add(parsed);
          }
        }
        continue;
      }
      event?.add(property);
    }

    return IcsCalendar(
      method: method,
      events: List<IcsEvent>.unmodifiable(events),
    );
  }

  static List<String> _unfold(String content) {
    final List<String> physical = content.replaceAll('\r\n', '\n').split('\n');
    final List<String> unfolded = <String>[];
    for (final String line in physical) {
      if ((line.startsWith(' ') || line.startsWith('\t')) &&
          unfolded.isNotEmpty) {
        unfolded[unfolded.length - 1] = '${unfolded.last}${line.substring(1)}';
      } else {
        unfolded.add(line);
      }
    }
    return unfolded;
  }
}

class _EventBuilder {
  String? uid;
  _IcsDateValue? start;
  _IcsDateValue? end;
  Duration? duration;
  String? summary;
  String? location;
  IcsAttendee? organizer;
  String? description;
  final List<IcsAttendee> attendees = <IcsAttendee>[];

  void add(_IcsProperty property) {
    switch (property.name) {
      case 'UID':
        uid = _nonEmpty(property.value);
      case 'DTSTART':
        start = _IcsDateValue.tryParse(property);
      case 'DTEND':
        end = _IcsDateValue.tryParse(property);
      case 'DURATION':
        duration = _parseDuration(property.value);
      case 'SUMMARY':
        summary = _unescapeText(property.value);
      case 'LOCATION':
        location = _unescapeText(property.value);
      case 'DESCRIPTION':
        description = _unescapeText(property.value);
      case 'ORGANIZER':
        organizer = _parseAttendee(property);
      case 'ATTENDEE':
        final IcsAttendee? attendee = _parseAttendee(property);
        if (attendee != null) {
          attendees.add(attendee);
        }
    }
  }

  IcsEvent? build() {
    final String? normalizedUid = _nonEmpty(uid);
    final _IcsDateValue? startValue = start;
    if (normalizedUid == null || startValue == null) {
      return null;
    }
    final _IcsDateValue? endValue = end;
    final DateTime resolvedEnd =
        endValue?.value ??
        startValue.value.add(
          duration ??
              (startValue.allDay ? const Duration(days: 1) : Duration.zero),
        );
    return IcsEvent(
      uid: normalizedUid,
      start: startValue.value,
      end: resolvedEnd,
      allDay: startValue.allDay,
      summary: _nonEmpty(summary),
      location: _nonEmpty(location),
      organizer: organizer,
      description: _nonEmpty(description),
      startTimeZoneId: startValue.timeZoneId,
      endTimeZoneId: endValue?.timeZoneId,
      attendees: List<IcsAttendee>.unmodifiable(attendees),
    );
  }

  static IcsAttendee? _parseAttendee(_IcsProperty property) {
    String email = property.value.trim();
    if (email.toLowerCase().startsWith('mailto:')) {
      email = email.substring('mailto:'.length);
    }
    if (email.isEmpty) {
      return null;
    }
    return IcsAttendee(
      email: email,
      commonName: _nonEmpty(_unescapeText(property.parameters['CN'] ?? '')),
    );
  }

  static Duration? _parseDuration(String raw) {
    final RegExpMatch? match = RegExp(
      r'^([+-])?P(?:(\d+)W)?(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$',
      caseSensitive: false,
    ).firstMatch(raw.trim());
    if (match == null) {
      return null;
    }
    final int sign = match.group(1) == '-' ? -1 : 1;
    int value(int group) => int.tryParse(match.group(group) ?? '') ?? 0;
    final Duration result = Duration(
      days: value(2) * 7 + value(3),
      hours: value(4),
      minutes: value(5),
      seconds: value(6),
    );
    return sign == -1 ? -result : result;
  }
}

class _IcsDateValue {
  const _IcsDateValue({
    required this.value,
    required this.allDay,
    this.timeZoneId,
  });

  final DateTime value;
  final bool allDay;
  final String? timeZoneId;

  static _IcsDateValue? tryParse(_IcsProperty property) {
    final String raw = property.value.trim();
    final bool isDate =
        property.parameters['VALUE']?.toUpperCase() == 'DATE' ||
        RegExp(r'^\d{8}$').hasMatch(raw);
    if (isDate) {
      if (raw.length != 8) {
        return null;
      }
      final int? year = int.tryParse(raw.substring(0, 4));
      final int? month = int.tryParse(raw.substring(4, 6));
      final int? day = int.tryParse(raw.substring(6, 8));
      if (year == null || month == null || day == null) {
        return null;
      }
      return _IcsDateValue(value: DateTime.utc(year, month, day), allDay: true);
    }

    final RegExpMatch? match = RegExp(
      r'^(\d{4})(\d{2})(\d{2})T(\d{2})(\d{2})(\d{2})(Z)?$',
    ).firstMatch(raw);
    if (match == null) {
      return null;
    }
    int value(int group) => int.parse(match.group(group)!);
    // Without a timezone database, a TZID value is preserved for callers and
    // represented as its calendar wall time in UTC. This avoids host timezone
    // drift while retaining the original TZID for a later timezone-aware layer.
    return _IcsDateValue(
      value: DateTime.utc(
        value(1),
        value(2),
        value(3),
        value(4),
        value(5),
        value(6),
      ),
      allDay: false,
      timeZoneId: _nonEmpty(property.parameters['TZID']),
    );
  }
}

class _IcsProperty {
  const _IcsProperty({
    required this.name,
    required this.parameters,
    required this.value,
  });

  final String name;
  final Map<String, String> parameters;
  final String value;

  static _IcsProperty? tryParse(String line) {
    final int separator = line.indexOf(':');
    if (separator < 1) {
      return null;
    }
    final List<String> nameParts = line.substring(0, separator).split(';');
    final String name = nameParts.first.trim().toUpperCase();
    if (name.isEmpty) {
      return null;
    }
    final Map<String, String> parameters = <String, String>{};
    for (final String part in nameParts.skip(1)) {
      final int equals = part.indexOf('=');
      if (equals < 1) {
        continue;
      }
      final String key = part.substring(0, equals).trim().toUpperCase();
      String value = part.substring(equals + 1).trim();
      if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      parameters[key] = value;
    }
    return _IcsProperty(
      name: name,
      parameters: parameters,
      value: line.substring(separator + 1),
    );
  }
}

String? _nonEmpty(String? value) {
  if (value == null) {
    return null;
  }
  final String trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _unescapeText(String value) {
  return value
      .replaceAll(r'\n', '\n')
      .replaceAll(r'\N', '\n')
      .replaceAll(r'\,', ',')
      .replaceAll(r'\;', ';')
      .replaceAll(r'\\', r'\');
}
