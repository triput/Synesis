// ==============================================================================
// File: lib/ui/pim/pim_copy_ui.dart
// Description: Wave 6 desktop DnD payloads, lane drop targets, copy feedback.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-08-04
// Last Update: 2026-08-04
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/sync/pim_copy_service.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/shell/mail_split_layout.dart';

/// Drag payload for cross-calendar event copy (Wave 6 desktop DnD).
class PimEventDragData {
  const PimEventDragData({
    required this.eventId,
    required this.sourceCalendarId,
    required this.sourceAccountId,
    required this.title,
  });

  final String eventId;
  final String sourceCalendarId;
  final String sourceAccountId;
  final String title;
}

/// Drag payload for cross-list contact copy (Wave 6 desktop DnD).
class PimContactDragData {
  const PimContactDragData({
    required this.contactId,
    required this.sourceContactListId,
    required this.sourceAccountId,
    required this.displayName,
  });

  final String contactId;
  final String sourceContactListId;
  final String sourceAccountId;
  final String displayName;
}

/// True when desktop-style drag-and-drop should be enabled (width ≥ 600).
bool isDesktopPimDnDEnabled(BuildContext context) {
  return !isPortraitMobileLayout(context);
}

/// Returns whether dropping [data] onto [targetCalendar] is allowed.
bool isValidEventDropTarget({
  required PimEventDragData data,
  required Calendar targetCalendar,
}) {
  if (!targetCalendar.isSelectedForDisplay) {
    return false;
  }
  return targetCalendar.id != data.sourceCalendarId;
}

/// Returns whether dropping [data] onto [targetList] is allowed.
bool isValidContactDropTarget({
  required PimContactDragData data,
  required ContactList targetList,
}) {
  if (!targetList.isSelectedForDisplay) {
    return false;
  }
  return targetList.id != data.sourceContactListId;
}

String eventCopySuccessMessage({
  required String calendarName,
  required bool remotePushEnqueued,
}) {
  if (remotePushEnqueued) {
    return 'Copied to $calendarName. Syncing to your provider…';
  }
  return 'Copied locally to $calendarName. Not synced to the remote calendar.';
}

String contactCopySuccessMessage({
  required String listName,
  required bool remotePushEnqueued,
}) {
  if (remotePushEnqueued) {
    return 'Copied to $listName. Syncing to your provider…';
  }
  return 'Copied locally to $listName. Not synced to the remote address book.';
}

/// Shows a snackbar after a successful event copy; optional Undo soft-deletes
/// the duplicate locally. Pending `events_copy` jobs skip soft-deleted rows.
void showEventCopyResultSnackBar({
  required BuildContext context,
  required String calendarName,
  required PimCopyResult<CalendarEvent> result,
  Future<void> Function(String copiedEventId)? onUndo,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        eventCopySuccessMessage(
          calendarName: calendarName,
          remotePushEnqueued: result.remotePushEnqueued,
        ),
      ),
      action: onUndo == null
          ? null
          : SnackBarAction(
              label: 'Undo',
              onPressed: () {
                unawaited(onUndo(result.entity.id));
              },
            ),
    ),
  );
}

/// Shows a snackbar after a successful contact copy.
void showContactCopyResultSnackBar({
  required BuildContext context,
  required String listName,
  required PimCopyResult<Contact> result,
}) {
  final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        contactCopySuccessMessage(
          listName: listName,
          remotePushEnqueued: result.remotePushEnqueued,
        ),
      ),
    ),
  );
}

/// Horizontal strip of calendar lanes accepting event drops (desktop DnD).
class CalendarLaneDropBar extends StatelessWidget {
  const CalendarLaneDropBar({
    super.key,
    required this.calendars,
    required this.onAccept,
  });

  final List<Calendar> calendars;
  final Future<void> Function(
    PimEventDragData data,
    Calendar targetCalendar,
  )
  onAccept;

  @override
  Widget build(BuildContext context) {
    if (calendars.isEmpty) {
      return const SizedBox.shrink();
    }
    final ThemeTokens t = tokensOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: <Widget>[
          for (final Calendar calendar in calendars)
            _CalendarLaneDropChip(
              calendar: calendar,
              onAccept: onAccept,
            ),
          Text(
            'Drop events onto a calendar',
            style: TextStyle(color: t.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _CalendarLaneDropChip extends StatelessWidget {
  const _CalendarLaneDropChip({
    required this.calendar,
    required this.onAccept,
  });

  final Calendar calendar;
  final Future<void> Function(
    PimEventDragData data,
    Calendar targetCalendar,
  )
  onAccept;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final Color accent = Color(calendar.effectiveColorArgb);
    return DragTarget<PimEventDragData>(
      key: Key('calendar_lane_drop_${calendar.id}'),
      onWillAcceptWithDetails: (DragTargetDetails<PimEventDragData> details) {
        return isValidEventDropTarget(
          data: details.data,
          targetCalendar: calendar,
        );
      },
      onAcceptWithDetails: (DragTargetDetails<PimEventDragData> details) {
        unawaited(onAccept(details.data, calendar));
      },
      builder: (
        BuildContext context,
        List<PimEventDragData?> candidateData,
        List<dynamic> rejectedData,
      ) {
        final bool hovering = candidateData.isNotEmpty;
        final bool rejected = rejectedData.isNotEmpty && !hovering;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: hovering
                ? t.teal.withValues(alpha: 0.22)
                : rejected
                ? t.coral.withValues(alpha: 0.12)
                : t.panel2.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hovering
                  ? t.teal
                  : rejected
                  ? t.coral.withValues(alpha: 0.6)
                  : accent.withValues(alpha: 0.55),
              width: hovering ? 1.6 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                calendar.name,
                style: TextStyle(
                  color: t.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Horizontal strip of contact-list lanes accepting contact drops (desktop).
class ContactListLaneDropBar extends StatelessWidget {
  const ContactListLaneDropBar({
    super.key,
    required this.contactLists,
    required this.onAccept,
  });

  final List<ContactList> contactLists;
  final Future<void> Function(
    PimContactDragData data,
    ContactList targetList,
  )
  onAccept;

  @override
  Widget build(BuildContext context) {
    if (contactLists.isEmpty) {
      return const SizedBox.shrink();
    }
    final ThemeTokens t = tokensOf(context);
    final List<ContactList> selected = contactLists
        .where((ContactList list) => list.isSelectedForDisplay)
        .toList(growable: false);
    if (selected.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: <Widget>[
          for (final ContactList list in selected)
            _ContactListLaneDropChip(
              contactList: list,
              onAccept: onAccept,
            ),
          Text(
            'Drop contacts onto a list',
            style: TextStyle(color: t.muted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _ContactListLaneDropChip extends StatelessWidget {
  const _ContactListLaneDropChip({
    required this.contactList,
    required this.onAccept,
  });

  final ContactList contactList;
  final Future<void> Function(
    PimContactDragData data,
    ContactList targetList,
  )
  onAccept;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return DragTarget<PimContactDragData>(
      key: Key('people_list_drop_${contactList.id}'),
      onWillAcceptWithDetails: (DragTargetDetails<PimContactDragData> details) {
        return isValidContactDropTarget(
          data: details.data,
          targetList: contactList,
        );
      },
      onAcceptWithDetails: (DragTargetDetails<PimContactDragData> details) {
        unawaited(onAccept(details.data, contactList));
      },
      builder: (
        BuildContext context,
        List<PimContactDragData?> candidateData,
        List<dynamic> rejectedData,
      ) {
        final bool hovering = candidateData.isNotEmpty;
        final bool rejected = rejectedData.isNotEmpty && !hovering;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: hovering
                ? t.teal.withValues(alpha: 0.22)
                : rejected
                ? t.coral.withValues(alpha: 0.12)
                : t.panel2.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: hovering
                  ? t.teal
                  : rejected
                  ? t.coral.withValues(alpha: 0.6)
                  : t.indigo.withValues(alpha: 0.45),
              width: hovering ? 1.6 : 1,
            ),
          ),
          child: Text(
            contactList.name,
            style: TextStyle(
              color: t.text,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      },
    );
  }
}

/// Wraps [child] in a desktop [Draggable] for calendar events when [enabled].
Widget desktopEventDraggable({
  required bool enabled,
  required PimEventDragData data,
  required Color accent,
  required Widget child,
}) {
  if (!enabled) {
    return child;
  }
  return Draggable<PimEventDragData>(
    key: Key('calendar_event_draggable_${data.eventId}'),
    data: data,
    feedback: Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          data.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    ),
    childWhenDragging: Opacity(opacity: 0.35, child: child),
    child: child,
  );
}

/// Wraps [child] in a desktop [Draggable] for contacts when [enabled].
Widget desktopContactDraggable({
  required bool enabled,
  required PimContactDragData data,
  required Widget child,
}) {
  if (!enabled) {
    return child;
  }
  return Draggable<PimContactDragData>(
    key: Key('people_contact_draggable_${data.contactId}'),
    data: data,
    feedback: Material(
      elevation: 4,
      shape: const CircleBorder(),
      child: CircleAvatar(
        radius: 22,
        backgroundColor: Colors.indigo,
        child: Text(
          data.displayName.isEmpty
              ? '?'
              : data.displayName[0].toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
    ),
    childWhenDragging: Opacity(opacity: 0.35, child: child),
    child: child,
  );
}

/// Wraps an agenda column (calendar lane) as a [DragTarget] on desktop.
class CalendarAgendaLaneDropTarget extends StatelessWidget {
  const CalendarAgendaLaneDropTarget({
    super.key,
    required this.calendar,
    required this.enabled,
    required this.onAccept,
    required this.child,
  });

  final Calendar calendar;
  final bool enabled;
  final Future<void> Function(PimEventDragData data) onAccept;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }
    final ThemeTokens t = tokensOf(context);
    return DragTarget<PimEventDragData>(
      key: Key('calendar_agenda_lane_drop_${calendar.id}'),
      onWillAcceptWithDetails: (DragTargetDetails<PimEventDragData> details) {
        return isValidEventDropTarget(
          data: details.data,
          targetCalendar: calendar,
        );
      },
      onAcceptWithDetails: (DragTargetDetails<PimEventDragData> details) {
        unawaited(onAccept(details.data));
      },
      builder: (
        BuildContext context,
        List<PimEventDragData?> candidateData,
        List<dynamic> rejectedData,
      ) {
        final bool hovering = candidateData.isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            border: hovering
                ? Border.all(color: t.teal, width: 2)
                : null,
          ),
          child: child,
        );
      },
    );
  }
}
