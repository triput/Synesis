// ==============================================================================
// File: lib/ui/calendar/calendar_cubit.dart
// Description: Calendar workspace Cubit — local Drift range load + local CRUD.
// Component: Bloc / UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/settings/app_settings_cubit.dart';
import 'package:synesis/settings/app_settings_state.dart';
import 'package:synesis/ui/calendar/calendar_state.dart';

/// Owns the Calendar workspace's visible month range, calendar display
/// prefs, and local-only event CRUD (Wave 5 / V2.0c P6).
///
/// All reads/writes go through [DriftPimStore] — **no** network calls and
/// **no** sync-job enqueue: `events_push` remains a no-op in this wave, so
/// [createEvent]/[updateEvent]/[deleteEvent] only ever touch the local
/// Drift database. Refreshes automatically on [MailRepository.watchChanges]
/// (shared with the mail change stream — see `main.dart`) and on
/// [AppSettingsCubit.calendarViewMode] changes.
class CalendarCubit extends Cubit<CalendarState> {
  CalendarCubit({
    required DriftPimStore pimStore,
    required MailRepository repository,
    AppSettingsCubit? settingsCubit,
    DateTime? initialMonth,
  }) : _pimStore = pimStore,
       _repository = repository,
       super(
         CalendarState(
           focusedMonth: _startOfMonth(initialMonth ?? DateTime.now()),
           viewMode: settingsCubit?.state.calendarViewMode ??
               CalendarViewMode.overlay,
         ),
       ) {
    _changesSub = _repository.watchChanges().listen((_) => refresh());
    if (settingsCubit != null) {
      _settingsSub = settingsCubit.stream.listen((AppSettingsState settings) {
        if (settings.calendarViewMode != state.viewMode) {
          emit(state.copyWith(viewMode: settings.calendarViewMode));
        }
      });
    }
    unawaited(refresh());
  }

  final DriftPimStore _pimStore;
  final MailRepository _repository;
  StreamSubscription<void>? _changesSub;
  StreamSubscription<AppSettingsState>? _settingsSub;

  static DateTime _startOfMonth(DateTime day) =>
      DateTime(day.year, day.month, 1);

  /// `[start, end)` epoch-ms bounds of the calendar month containing [month].
  static (int, int) monthRangeMs(DateTime month) {
    final DateTime start = DateTime(month.year, month.month, 1);
    final DateTime end = DateTime(month.year, month.month + 1, 1);
    return (start.millisecondsSinceEpoch, end.millisecondsSinceEpoch);
  }

  Future<void> refresh() async {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final List<MailAccount> accounts = await _repository.listAccounts();
      final List<Calendar> calendars = await _pimStore.listCalendars();
      final DateTime month = state.focusedMonth ?? _startOfMonth(
        DateTime.now(),
      );
      final (int startMs, int endMs) = monthRangeMs(month);
      final List<CalendarEvent> events = await _pimStore.listEventsInRange(
        startEpochMsInclusive: startMs,
        endEpochMsExclusive: endMs,
      );
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          accounts: accounts,
          calendars: calendars,
          events: events,
          focusedMonth: month,
          isLoading: false,
        ),
      );
    } catch (error) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> goToMonth(DateTime month) async {
    emit(state.copyWith(focusedMonth: _startOfMonth(month)));
    await refresh();
  }

  Future<void> nextMonth() async {
    final DateTime current = state.focusedMonth ?? _startOfMonth(
      DateTime.now(),
    );
    await goToMonth(DateTime(current.year, current.month + 1, 1));
  }

  Future<void> previousMonth() async {
    final DateTime current = state.focusedMonth ?? _startOfMonth(
      DateTime.now(),
    );
    await goToMonth(DateTime(current.year, current.month - 1, 1));
  }

  Future<void> goToToday() => goToMonth(DateTime.now());

  void setShowAgenda(bool showAgenda) {
    if (state.showAgenda == showAgenda) {
      return;
    }
    emit(state.copyWith(showAgenda: showAgenda));
  }

  /// Toggles [Calendar.isSelectedForDisplay] for [calendarId]. Refresh is
  /// driven by the shared [MailRepository.watchChanges] notification that
  /// [DriftPimStore] fires on write.
  Future<void> setCalendarSelected(String calendarId, bool selected) {
    return _pimStore.setCalendarDisplayPrefs(
      calendarId,
      isSelectedForDisplay: selected,
    );
  }

  Future<void> setCalendarColorOverride(String calendarId, int? argb) {
    return _pimStore.setCalendarDisplayPrefs(
      calendarId,
      colorOverrideArgb: argb,
    );
  }

  /// Creates a **local-only** event; `events_push` is not enqueued in Wave 5.
  Future<CalendarEvent> createEvent({
    required String accountId,
    required String calendarId,
    required String title,
    required int startEpochMs,
    required int endEpochMs,
    String? body,
    bool allDay = false,
    String? location,
  }) {
    return _pimStore.createLocalEvent(
      accountId: accountId,
      calendarId: calendarId,
      title: title,
      startEpochMs: startEpochMs,
      endEpochMs: endEpochMs,
      body: body,
      allDay: allDay,
      location: location,
    );
  }

  /// Overwrites an existing event's mutable fields (local-only write path).
  Future<void> updateEvent(CalendarEvent event) =>
      _pimStore.updateLocalEvent(event);

  /// Soft-deletes an event locally — no CalDAV/Graph DELETE in Wave 5.
  Future<void> deleteEvent(String eventId) => _pimStore.softDeleteEvent(
    eventId,
  );

  @override
  Future<void> close() {
    unawaited(_changesSub?.cancel());
    unawaited(_settingsSub?.cancel());
    return super.close();
  }
}
