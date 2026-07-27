// ==============================================================================
// File: lib/pim/meeting_invite_resolver.dart
// Description: Detects mail calendar invitations and maps ICS events locally.
// Component: PIM / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/pim/ics_calendar_parser.dart';
import 'package:synesis/protocol/mail_provider.dart';

/// Graph identifiers that can associate a mail message with its event.
class MeetingGraphLookupKeys {
  const MeetingGraphLookupKeys({this.messageProviderId, this.iCalUId});

  final String? messageProviderId;
  final String? iCalUId;
}

/// Result of inspecting a message for a calendar invitation.
class MeetingInviteDetection {
  const MeetingInviteDetection({
    required this.isInvite,
    this.method,
    this.uid,
    this.event,
    this.graphLookupKeys = const MeetingGraphLookupKeys(),
  });

  final bool isInvite;
  final String? method;
  final String? uid;
  final IcsEvent? event;
  final MeetingGraphLookupKeys graphLookupKeys;
}

/// Converts calendar invitation data into persisted PIM values.
class MeetingInviteResolver {
  const MeetingInviteResolver({this.parser = const IcsCalendarParser()});

  final IcsCalendarParser parser;

  MeetingInviteDetection detect({
    required MailMessage message,
    List<MailAttachmentMeta>? attachments,
    String? icsText,
  }) {
    final String body = message.body;
    final String headers = message.rawHeaders ?? '';
    final bool hasIcsAttachment = (attachments ?? const <MailAttachmentMeta>[])
        .any(
          (MailAttachmentMeta attachment) =>
              attachment.name.toLowerCase().endsWith('.ics') ||
              attachment.contentType.toLowerCase().contains('text/calendar'),
        );
    final bool calendarContentType = headers.toLowerCase().contains(
      'content-type: text/calendar',
    );
    final bool bodyContainsCalendar =
        body.toUpperCase().contains('BEGIN:VCALENDAR') ||
        (icsText?.toUpperCase().contains('BEGIN:VCALENDAR') ?? false);
    final bool subjectLooksLikeInvite = RegExp(
      r'(^|\b)(invitation|meeting request|accepted|declined|tentative)(\b|$)',
      caseSensitive: false,
    ).hasMatch(message.subject);
    final bool heuristicallyInvite =
        hasIcsAttachment ||
        calendarContentType ||
        bodyContainsCalendar ||
        subjectLooksLikeInvite;
    final String? source = _calendarSource(icsText) ?? _calendarSource(body);
    if (source == null) {
      return MeetingInviteDetection(
        isInvite: heuristicallyInvite,
        graphLookupKeys: MeetingGraphLookupKeys(
          messageProviderId: _nonEmpty(message.providerId),
        ),
      );
    }

    final IcsCalendar calendar = parser.parse(source);
    final IcsEvent? event = calendar.events.isEmpty
        ? null
        : calendar.events.first;
    return MeetingInviteDetection(
      isInvite: heuristicallyInvite || event != null,
      method: calendar.method,
      uid: event?.uid,
      event: event,
      graphLookupKeys: MeetingGraphLookupKeys(
        messageProviderId: _nonEmpty(message.providerId),
        iCalUId: event?.uid,
      ),
    );
  }

  /// Creates a local event draft. ICS events never claim a Graph provider id.
  CalendarEvent mapEvent({
    required IcsEvent event,
    required String accountId,
    required String calendarId,
    DateTime? now,
  }) {
    final String providerId = 'ics:${_providerUid(event.uid)}';
    return CalendarEvent(
      id: PimIds.stableLocalId(accountId, providerId),
      accountId: accountId,
      calendarId: calendarId,
      providerId: providerId,
      title: event.summary ?? '(No title)',
      body: event.description,
      startEpochMs: event.start.millisecondsSinceEpoch,
      endEpochMs: event.end.millisecondsSinceEpoch,
      allDay: event.allDay,
      location: event.location,
      updatedAt: (now ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  /// Creates attendee rows with stable ids tied to the local event id.
  List<EventAttendee> mapAttendees({
    required IcsEvent event,
    required String eventId,
  }) {
    final Map<String, EventAttendee> mapped = <String, EventAttendee>{};
    void add(IcsAttendee attendee, {required bool isOrganizer}) {
      final String normalizedEmail = attendee.email.trim().toLowerCase();
      if (normalizedEmail.isEmpty) {
        return;
      }
      final String id = PimIds.stableLocalId(
        eventId,
        'attendee:$normalizedEmail',
      );
      final EventAttendee? existing = mapped[id];
      mapped[id] = EventAttendee(
        id: id,
        eventId: eventId,
        email: attendee.email.trim(),
        displayName: attendee.commonName ?? existing?.displayName,
        responseStatus: existing?.responseStatus ?? 'none',
        isOrganizer: isOrganizer || (existing?.isOrganizer ?? false),
      );
    }

    final IcsAttendee? organizer = event.organizer;
    if (organizer != null) {
      add(organizer, isOrganizer: true);
    }
    for (final IcsAttendee attendee in event.attendees) {
      add(attendee, isOrganizer: false);
    }
    return List<EventAttendee>.unmodifiable(mapped.values);
  }

  static String _providerUid(String uid) {
    return uid.trim().replaceAll('<', '').replaceAll('>', '');
  }

  static String? _calendarSource(String? value) {
    if (value == null) {
      return null;
    }
    final int start = value.toUpperCase().indexOf('BEGIN:VCALENDAR');
    if (start < 0) {
      return null;
    }
    return value.substring(start);
  }

  static String? _nonEmpty(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
