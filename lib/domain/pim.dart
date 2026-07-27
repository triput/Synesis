// ==============================================================================
// File: lib/domain/pim.dart
// Description: Thin domain models for contacts, contact lists, calendars, events.
// Component: Domain
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

/// Address book / contact list belonging to a mail account.
class ContactList {
  const ContactList({
    required this.id,
    required this.accountId,
    required this.providerId,
    required this.name,
    this.colorArgb,
    this.isDefault = false,
    this.isSelectedForDisplay = true,
    this.sortIndex,
  });

  final String id;
  final String accountId;
  final String providerId;
  final String name;
  final int? colorArgb;
  final bool isDefault;
  final bool isSelectedForDisplay;
  final int? sortIndex;
}

/// Local contact row (soft-deletable via [deletedAt]).
class Contact {
  const Contact({
    required this.id,
    required this.accountId,
    required this.contactListId,
    required this.providerId,
    required this.displayName,
    required this.updatedAt,
    this.givenName,
    this.familyName,
    this.company,
    this.notes,
    this.etag,
    this.deletedAt,
  });

  final String id;
  final String accountId;
  final String contactListId;
  final String providerId;
  final String displayName;
  final String? givenName;
  final String? familyName;
  final String? company;
  final String? notes;
  final String? etag;
  final int updatedAt;
  final int? deletedAt;
}

/// Email address attached to a [Contact].
class ContactEmail {
  const ContactEmail({
    required this.id,
    required this.contactId,
    required this.address,
    this.type = 'other',
    this.isPrimary = false,
  });

  final String id;
  final String contactId;
  final String address;
  final String type;
  final bool isPrimary;
}

/// Phone number attached to a [Contact].
class ContactPhone {
  const ContactPhone({
    required this.id,
    required this.contactId,
    required this.number,
    this.type = 'other',
  });

  final String id;
  final String contactId;
  final String number;
  final String type;
}

/// Calendar collection belonging to a mail account.
class Calendar {
  const Calendar({
    required this.id,
    required this.accountId,
    required this.providerId,
    required this.name,
    required this.colorArgb,
    this.colorOverrideArgb,
    this.isDefault = false,
    this.isSelectedForDisplay = true,
    this.sortIndex,
  });

  final String id;
  final String accountId;
  final String providerId;
  final String name;
  final int colorArgb;
  final int? colorOverrideArgb;
  final bool isDefault;
  final bool isSelectedForDisplay;
  final int? sortIndex;

  /// Effective display color (override wins when set).
  int get effectiveColorArgb => colorOverrideArgb ?? colorArgb;
}

/// Calendar event row (soft-deletable via [deletedAt]).
class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.accountId,
    required this.calendarId,
    required this.providerId,
    required this.title,
    required this.startEpochMs,
    required this.endEpochMs,
    required this.updatedAt,
    this.body,
    this.allDay = false,
    this.location,
    this.rrule,
    this.reminderMinutes,
    this.etag,
    this.deletedAt,
  });

  final String id;
  final String accountId;
  final String calendarId;
  final String providerId;
  final String title;
  final String? body;
  final int startEpochMs;
  final int endEpochMs;
  final bool allDay;
  final String? location;
  final String? rrule;
  final int? reminderMinutes;
  final String? etag;
  final int updatedAt;
  final int? deletedAt;
}

/// Attendee on a [CalendarEvent] (P2 meeting-mail bridge).
class EventAttendee {
  const EventAttendee({
    required this.id,
    required this.eventId,
    required this.email,
    this.displayName,
    this.responseStatus = 'none',
    this.isOrganizer = false,
  });

  final String id;
  final String eventId;
  final String email;
  final String? displayName;
  final String responseStatus;
  final bool isOrganizer;
}
