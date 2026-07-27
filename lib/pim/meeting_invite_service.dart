// ==============================================================================
// File: lib/pim/meeting_invite_service.dart
// Description: Local-first invitation persistence and Graph RSVP coordination.
// Component: PIM / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'dart:convert';

import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/pim/ics_calendar_parser.dart';
import 'package:synesis/pim/meeting_invite_resolver.dart';
import 'package:synesis/pim/meeting_rsvp.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/protocol/mail_provider.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/sync_engine.dart'
    show GraphPimResolver, ProviderResolver;

/// Result of a local RSVP update and an optional remote Graph response.
class MeetingInviteActionResult {
  const MeetingInviteActionResult({
    required this.event,
    required this.serverResponseSent,
  });

  final CalendarEvent event;
  final bool serverResponseSent;
}

/// Bridges email invitations into the local calendar and Graph RSVP endpoints.
class MeetingInviteService {
  MeetingInviteService({
    required DriftPimStore pimStore,
    required MailRepository repository,
    required GraphPimResolver resolvePim,
    ProviderResolver? resolveMail,
    MeetingInviteResolver? resolver,
  }) : _pimStore = pimStore,
       _repository = repository,
       _resolvePim = resolvePim,
       _resolveMail = resolveMail,
       _resolver = resolver ?? const MeetingInviteResolver();

  final DriftPimStore _pimStore;
  final MailRepository _repository;
  final GraphPimResolver _resolvePim;
  final ProviderResolver? _resolveMail;
  final MeetingInviteResolver _resolver;

  Future<MeetingInviteDetection> detect({
    required MailMessage message,
    List<MailAttachmentMeta>? attachments,
    String? icsText,
  }) async {
    final List<MailAttachmentMeta> resolvedAttachments =
        attachments ?? await _listAttachments(message);
    final String? resolvedIcs =
        icsText ?? await _loadIcsAttachment(message, resolvedAttachments);
    return _resolver.detect(
      message: message,
      attachments: resolvedAttachments,
      icsText: resolvedIcs,
    );
  }

  /// Upserts an ICS event and attendees onto the account's default calendar.
  Future<CalendarEvent> addIcsToCalendar({
    required String accountId,
    required String icsText,
  }) async {
    final IcsEvent event = _requireEvent(icsText);
    return _upsertIcsEvent(accountId: accountId, event: event);
  }

  /// Sends a Graph RSVP when possible while always persisting an ICS draft.
  ///
  /// IMAP and other non-Graph accounts retain the response locally only.
  Future<MeetingInviteActionResult> respond({
    required MailMessage message,
    required MeetingRsvpResponse response,
    List<MailAttachmentMeta>? attachments,
    String? icsText,
  }) async {
    final MeetingInviteDetection detection = await detect(
      message: message,
      attachments: attachments,
      icsText: icsText,
    );
    final IcsEvent? parsedEvent = detection.event;
    if (!detection.isInvite || parsedEvent == null) {
      throw StateError(
        'This message does not contain a parseable calendar invitation.',
      );
    }
    final MailAccount account = await _requireAccount(message.accountId);
    final CalendarEvent event = await _upsertIcsEvent(
      accountId: account.id,
      event: parsedEvent,
    );
    if (!_isGraphAccount(account)) {
      return _saveLocalResponse(
        event: event,
        respondingAddress: account.address,
        response: response,
      );
    }

    final GraphPimProvider? provider = await _resolvePim(account.id);
    if (provider == null) {
      return _saveLocalResponse(
        event: event,
        respondingAddress: account.address,
        response: response,
      );
    }
    String? providerEventId;
    final String? messageProviderId =
        detection.graphLookupKeys.messageProviderId;
    if (messageProviderId != null) {
      final Map<String, Object?>? associated = await provider
          .fetchAssociatedEventForMessage(messageProviderId);
      providerEventId = _nonEmpty(associated?['id']?.toString());
    }
    providerEventId ??= await provider.findEventIdByICalUId(parsedEvent.uid);
    if (providerEventId == null) {
      return _saveLocalResponse(
        event: event,
        respondingAddress: account.address,
        response: response,
      );
    }
    await provider.respondToEvent(providerEventId, response);
    await _upsertRespondingAttendee(
      event: event,
      respondingAddress: account.address,
      response: response,
    );
    return MeetingInviteActionResult(event: event, serverResponseSent: true);
  }

  Future<CalendarEvent> _upsertIcsEvent({
    required String accountId,
    required IcsEvent event,
  }) async {
    final Calendar calendar = await _requireDefaultCalendar(accountId);
    final CalendarEvent mapped = _resolver.mapEvent(
      event: event,
      accountId: accountId,
      calendarId: calendar.id,
    );
    await _pimStore.upsertEvents(<CalendarEvent>[mapped]);
    final List<EventAttendee> attendees = _resolver
        .mapAttendees(event: event, eventId: mapped.id)
        .toList(growable: true);
    await _pimStore.upsertEventAttendees(attendees);
    return mapped;
  }

  Future<MeetingInviteActionResult> _saveLocalResponse({
    required CalendarEvent event,
    required String respondingAddress,
    required MeetingRsvpResponse response,
  }) async {
    await _upsertRespondingAttendee(
      event: event,
      respondingAddress: respondingAddress,
      response: response,
    );
    return MeetingInviteActionResult(event: event, serverResponseSent: false);
  }

  Future<void> _upsertRespondingAttendee({
    required CalendarEvent event,
    required String respondingAddress,
    required MeetingRsvpResponse response,
  }) async {
    final String normalized = respondingAddress.trim().toLowerCase();
    final List<EventAttendee> attendees = await _pimStore.listEventAttendees(
      event.id,
    );
    final int index = attendees.indexWhere(
      (EventAttendee attendee) =>
          attendee.email.trim().toLowerCase() == normalized,
    );
    final EventAttendee? original = index >= 0 ? attendees[index] : null;
    await _pimStore.upsertEventAttendees(<EventAttendee>[
      EventAttendee(
        id: PimIds.stableLocalId(event.id, 'attendee:$normalized'),
        eventId: event.id,
        email: respondingAddress.trim(),
        displayName: original?.displayName,
        responseStatus: _responseStatus(response),
        isOrganizer: original?.isOrganizer ?? false,
      ),
    ]);
  }

  IcsEvent _requireEvent(String icsText) {
    final IcsCalendar calendar = _resolver.parser.parse(icsText);
    if (calendar.events.isEmpty) {
      throw StateError('The calendar data did not contain a valid VEVENT.');
    }
    return calendar.events.first;
  }

  Future<Calendar> _requireDefaultCalendar(String accountId) async {
    final Calendar? calendar = await _pimStore.findDefaultCalendar(accountId);
    if (calendar == null) {
      throw StateError(
        'No local calendar is available for this account. Sync calendars first.',
      );
    }
    return calendar;
  }

  Future<MailAccount> _requireAccount(String accountId) async {
    for (final MailAccount account in await _repository.listAccounts()) {
      if (account.id == accountId) {
        return account;
      }
    }
    throw StateError('No account exists for this invitation.');
  }

  Future<List<MailAttachmentMeta>> _listAttachments(MailMessage message) async {
    final String? providerId = _nonEmpty(message.providerId);
    final ProviderResolver? resolveMail = _resolveMail;
    if (providerId == null || resolveMail == null) {
      return const <MailAttachmentMeta>[];
    }
    final MailProvider? provider = await resolveMail(message.accountId);
    if (provider == null) {
      return const <MailAttachmentMeta>[];
    }
    try {
      return await provider.listAttachments(providerId);
    } on UnsupportedError {
      return const <MailAttachmentMeta>[];
    }
  }

  Future<String?> _loadIcsAttachment(
    MailMessage message,
    List<MailAttachmentMeta> attachments,
  ) async {
    final String? providerId = _nonEmpty(message.providerId);
    final ProviderResolver? resolveMail = _resolveMail;
    final MailAttachmentMeta? attachment = attachments
        .cast<MailAttachmentMeta?>()
        .firstWhere(
          (MailAttachmentMeta? item) =>
              item != null &&
              (item.name.toLowerCase().endsWith('.ics') ||
                  item.contentType.toLowerCase().contains('text/calendar')),
          orElse: () => null,
        );
    if (providerId == null || resolveMail == null || attachment == null) {
      return null;
    }
    final MailProvider? provider = await resolveMail(message.accountId);
    if (provider == null) {
      return null;
    }
    try {
      final MailAttachmentBytes bytes = await provider.fetchAttachment(
        providerId,
        attachment.partId,
      );
      return utf8.decode(bytes.bytes, allowMalformed: true);
    } on UnsupportedError {
      return null;
    }
  }

  static bool _isGraphAccount(MailAccount account) {
    return account.providerType == 'graph' ||
        account.providerType == 'microsoft';
  }

  static String _responseStatus(MeetingRsvpResponse response) {
    return switch (response) {
      MeetingRsvpResponse.accept => 'accepted',
      MeetingRsvpResponse.decline => 'declined',
      MeetingRsvpResponse.tentative => 'tentativelyAccepted',
    };
  }

  static String? _nonEmpty(String? value) {
    final String trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }
}
