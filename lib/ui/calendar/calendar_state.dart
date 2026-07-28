// ==============================================================================
// File: lib/ui/calendar/calendar_state.dart
// Description: Calendar workspace state — visible range, calendars, events.
// Component: Bloc / UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:equatable/equatable.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/settings/app_settings_state.dart';

/// Secondary calendar layout, alongside the always-available month grid.
enum CalendarSecondaryView {
  /// Chronological list of events in the visible range.
  agenda,
}

class CalendarState extends Equatable {
  const CalendarState({
    this.accounts = const <MailAccount>[],
    this.calendars = const <Calendar>[],
    this.events = const <CalendarEvent>[],
    this.focusedMonth,
    this.secondaryView = CalendarSecondaryView.agenda,
    this.showAgenda = false,
    this.viewMode = CalendarViewMode.overlay,
    this.isLoading = false,
    this.errorMessage,
  });

  final List<MailAccount> accounts;

  /// All calendars across accounts (for the picker sheet); filter on
  /// [Calendar.isSelectedForDisplay] for the calendars actually drawn.
  final List<Calendar> calendars;

  /// Events overlapping the current month, already scoped by the store to
  /// calendars with [Calendar.isSelectedForDisplay] == true.
  final List<CalendarEvent> events;

  /// First-of-month anchor for the visible month grid. Null until the first
  /// [CalendarCubit.refresh] completes.
  final DateTime? focusedMonth;

  final CalendarSecondaryView secondaryView;

  /// True when the Agenda secondary view is showing instead of the month grid.
  final bool showAgenda;

  /// Mirrored from [AppSettingsState.calendarViewMode] (Wave 5 UI consumer).
  final CalendarViewMode viewMode;
  final bool isLoading;
  final String? errorMessage;

  List<Calendar> get selectedCalendars => calendars
      .where((Calendar calendar) => calendar.isSelectedForDisplay)
      .toList(growable: false);

  bool get hasAnyCalendars => calendars.isNotEmpty;

  bool get hasSelectedCalendars => selectedCalendars.isNotEmpty;

  /// Events for [day] (local calendar date), sorted by [CalendarEvent.startEpochMs].
  List<CalendarEvent> eventsOnDay(DateTime day) {
    final DateTime start = DateTime(day.year, day.month, day.day);
    final DateTime end = start.add(const Duration(days: 1));
    final int startMs = start.millisecondsSinceEpoch;
    final int endMs = end.millisecondsSinceEpoch;
    final List<CalendarEvent> matches = events
        .where(
          (CalendarEvent event) =>
              event.startEpochMs < endMs && event.endEpochMs > startMs,
        )
        .toList()
      ..sort(
        (CalendarEvent a, CalendarEvent b) =>
            a.startEpochMs.compareTo(b.startEpochMs),
      );
    return matches;
  }

  Calendar? calendarById(String id) {
    for (final Calendar calendar in calendars) {
      if (calendar.id == id) {
        return calendar;
      }
    }
    return null;
  }

  CalendarState copyWith({
    List<MailAccount>? accounts,
    List<Calendar>? calendars,
    List<CalendarEvent>? events,
    DateTime? focusedMonth,
    CalendarSecondaryView? secondaryView,
    bool? showAgenda,
    CalendarViewMode? viewMode,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CalendarState(
      accounts: accounts ?? this.accounts,
      calendars: calendars ?? this.calendars,
      events: events ?? this.events,
      focusedMonth: focusedMonth ?? this.focusedMonth,
      secondaryView: secondaryView ?? this.secondaryView,
      showAgenda: showAgenda ?? this.showAgenda,
      viewMode: viewMode ?? this.viewMode,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    accounts,
    calendars,
    events,
    focusedMonth,
    secondaryView,
    showAgenda,
    viewMode,
    isLoading,
    errorMessage,
  ];
}
