// ==============================================================================
// File: lib/ui/calendar/calendar_workspace.dart
// Description: Calendar module UI — month grid + agenda, local event CRUD.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-08-04
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/settings/app_settings_state.dart';
import 'package:synesis/sync/pim_copy_service.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/branding/synesis_wordmark.dart';
import 'package:synesis/ui/calendar/calendar_cubit.dart';
import 'package:synesis/ui/calendar/calendar_state.dart';
import 'package:synesis/ui/pim/pim_copy_target_sheet.dart';
import 'package:synesis/ui/pim/pim_copy_ui.dart';
import 'package:synesis/ui/shell/mail_split_layout.dart';

/// Local-only write notice shown in the event editor and confirmation
/// snackbars (Wave 5 W5-2: `events_push` remains a no-op).
const String kLocalEventWriteNotice =
    'Local only — not yet pushed to your calendar provider (Graph/CalDAV).';

const List<String> _kWeekdayShortLabels = <String>[
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

/// Resolves the calendar accent for an event chip/row (override → sync → indigo).
Color _calendarAccentColor(CalendarState state, String calendarId, ThemeTokens t) {
  return Color(
    state.calendarById(calendarId)?.effectiveColorArgb ?? t.indigo.toARGB32(),
  );
}

/// Translucent fill from [accent] — dark themes use a slightly stronger wash
/// so chips stay visible on [ThemeTokens.panel] without washing out [text].
Color _calendarAccentWash(Color accent, ThemeTokens t) {
  final double alpha =
      t.brightness == Brightness.dark ? 0.28 : 0.18;
  return accent.withValues(alpha: alpha);
}

String _monthLabel(DateTime month) {
  const List<String> names = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return '${names[month.month - 1]} ${month.year}';
}

String _accountLabelFor(List<MailAccount> accounts, String accountId) {
  for (final MailAccount account in accounts) {
    if (account.id == accountId) {
      return account.label.isNotEmpty ? account.label : account.address;
    }
  }
  return accountId;
}

String _formatTimeOfDay(DateTime dt) {
  final int hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
  final String minute = dt.minute.toString().padLeft(2, '0');
  final String suffix = dt.hour < 12 ? 'AM' : 'PM';
  return '$hour12:$minute $suffix';
}

String _formatEventTimeRange(CalendarEvent event) {
  if (event.allDay) {
    return 'All day';
  }
  final DateTime start = DateTime.fromMillisecondsSinceEpoch(
    event.startEpochMs,
  );
  final DateTime end = DateTime.fromMillisecondsSinceEpoch(event.endEpochMs);
  return '${_formatTimeOfDay(start)} – ${_formatTimeOfDay(end)}';
}

PimCopyService? _pimCopyServiceOf(BuildContext context) {
  try {
    return RepositoryProvider.of<PimCopyService>(context, listen: false);
  } on ProviderNotFoundException {
    return null;
  }
}

VoidCallback? _eventCopyLongPressHandler(
  BuildContext context, {
  required CalendarEvent event,
  required CalendarCubit cubit,
  required CalendarState state,
}) {
  if (!isPortraitMobileLayout(context)) {
    return null;
  }
  final PimCopyService? copyService = _pimCopyServiceOf(context);
  if (copyService == null) {
    return null;
  }
  return () {
    unawaited(
      showEventCopyTargetSheet(
        context,
        sourceEvent: event,
        cubit: cubit,
        state: state,
        copyService: copyService,
      ),
    );
  };
}

Future<void> _acceptEventCopy(
  BuildContext context, {
  required CalendarCubit cubit,
  required PimEventDragData data,
  required Calendar targetCalendar,
}) async {
  try {
    final PimCopyResult<CalendarEvent> result = await cubit.copyEventToCalendar(
      sourceEventId: data.eventId,
      targetAccountId: targetCalendar.accountId,
      targetCalendarId: targetCalendar.id,
    );
    if (!context.mounted) {
      return;
    }
    showEventCopyResultSnackBar(
      context: context,
      calendarName: targetCalendar.name,
      result: result,
      onUndo: cubit.deleteEvent,
    );
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copy failed: $error')),
    );
  }
}

/// Month-grid + agenda Calendar workspace (Wave 5 / V2.0c P6).
///
/// Reads and writes only through [CalendarCubit] → `DriftPimStore` — there is
/// no widget-level network call. Local create/edit/delete never enqueue an
/// `events_push` sync job (see [kLocalEventWriteNotice]).
class CalendarWorkspace extends StatelessWidget {
  const CalendarWorkspace({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarCubit, CalendarState>(
      builder: (BuildContext context, CalendarState state) {
        final ThemeTokens t = tokensOf(context);
        final CalendarCubit cubit = context.read<CalendarCubit>();
        final bool dndEnabled = isDesktopPimDnDEnabled(context);
        return Scaffold(
          backgroundColor: t.ink,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                _CalendarHeader(state: state, cubit: cubit),
                if (dndEnabled && state.hasSelectedCalendars)
                  CalendarLaneDropBar(
                    calendars: state.selectedCalendars,
                    onAccept: (PimEventDragData data, Calendar calendar) =>
                        _acceptEventCopy(
                      context,
                      cubit: cubit,
                      data: data,
                      targetCalendar: calendar,
                    ),
                  ),
                Expanded(
                  child: state.isLoading && state.calendars.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : !state.hasAnyCalendars
                          ? _EmptyCalendarState(state: state)
                          : (state.showAgenda
                                ? _AgendaView(
                                    state: state,
                                    cubit: cubit,
                                    dndEnabled: dndEnabled,
                                  )
                                : _MonthGridView(
                                    state: state,
                                    cubit: cubit,
                                    dndEnabled: dndEnabled,
                                  )),
                ),
              ],
            ),
          ),
          floatingActionButton: state.hasSelectedCalendars
              ? FloatingActionButton(
                  key: const Key('calendar_new_event_fab'),
                  tooltip: 'New event',
                  onPressed: () => showEventEditorSheet(
                    context,
                    cubit: cubit,
                    state: state,
                  ),
                  child: const Icon(Icons.add),
                )
              : null,
        );
      },
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({required this.state, required this.cubit});

  final CalendarState state;
  final CalendarCubit cubit;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final DateTime month = state.focusedMonth ?? DateTime.now();
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            t.indigo.withValues(alpha: 0.18),
            t.teal.withValues(alpha: 0.08),
          ],
        ),
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // Month nav + Today + Month/Agenda SegmentedButton exceeds ~360dp
          // (~203px RIGHT overflow on phone). Stack chrome under this width.
          final bool narrow = constraints.maxWidth < 520;
          final Widget viewToggle = SegmentedButton<bool>(
            key: const Key('calendar_view_toggle'),
            segments: const <ButtonSegment<bool>>[
              ButtonSegment<bool>(value: false, label: Text('Month')),
              ButtonSegment<bool>(value: true, label: Text('Agenda')),
            ],
            selected: <bool>{state.showAgenda},
            onSelectionChanged: (Set<bool> value) =>
                cubit.setShowAgenda(value.first),
          );
          final Widget todayButton = TextButton(
            onPressed: cubit.goToToday,
            child: const Text('Today'),
          );
          final Widget monthNav = Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Previous month',
                onPressed: cubit.previousMonth,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.chevron_left, color: t.muted),
              ),
              Expanded(
                child: Text(
                  _monthLabel(month),
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                tooltip: 'Next month',
                onPressed: cubit.nextMonth,
                visualDensity: VisualDensity.compact,
                icon: Icon(Icons.chevron_right, color: t.muted),
              ),
            ],
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const SynesisWordmark(fontSize: 15),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text('/', style: TextStyle(color: t.muted)),
                  ),
                  Expanded(
                    child: Text(
                      'Calendar',
                      style: TextStyle(color: t.muted, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    key: const Key('calendar_picker_button'),
                    tooltip: 'Choose calendars',
                    onPressed: () => showCalendarPickerSheet(
                      context,
                      cubit: cubit,
                    ),
                    icon: Icon(Icons.tune, color: t.muted, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (narrow) ...<Widget>[
                monthNav,
                const SizedBox(height: 4),
                Row(
                  children: <Widget>[
                    todayButton,
                    const SizedBox(width: 8),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: viewToggle,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else
                Row(
                  children: <Widget>[
                    Expanded(child: monthNav),
                    todayButton,
                    const SizedBox(width: 8),
                    viewToggle,
                  ],
                ),
              if (state.showAgenda &&
                  state.viewMode == CalendarViewMode.sideBySide &&
                  state.selectedCalendars.length > 1) ...<Widget>[
                const SizedBox(height: 6),
                Text(
                  'Side-by-side: month view stays overlaid; Agenda shows one '
                  'lane per selected calendar.',
                  style: TextStyle(color: t.muted, fontSize: 11),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EmptyCalendarState extends StatelessWidget {
  const _EmptyCalendarState({required this.state});

  final CalendarState state;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final bool hasAccounts = state.accounts.isNotEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.calendar_month_outlined, size: 40, color: t.muted),
            const SizedBox(height: 12),
            Text(
              hasAccounts
                  ? 'No calendars yet. Sync a Graph or DAV account to see '
                        'calendars here.'
                  : 'Add a Graph or DAV account to get calendars.',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayHeaderRow extends StatelessWidget {
  const _WeekdayHeaderRow();

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: <Widget>[
          for (final String label in _kWeekdayShortLabels)
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: t.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthGridView extends StatelessWidget {
  const _MonthGridView({
    required this.state,
    required this.cubit,
    required this.dndEnabled,
  });

  final CalendarState state;
  final CalendarCubit cubit;
  final bool dndEnabled;

  @override
  Widget build(BuildContext context) {
    final DateTime month = state.focusedMonth ?? DateTime.now();
    final DateTime firstOfMonth = DateTime(month.year, month.month, 1);
    final int leadingBlanks = (firstOfMonth.weekday - DateTime.monday) % 7;
    final DateTime gridStart = firstOfMonth.subtract(
      Duration(days: leadingBlanks),
    );
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final int totalCells = leadingBlanks + daysInMonth;
    final int rows = (totalCells / 7).ceil();
    final int cellCount = rows * 7;
    final DateTime today = DateTime.now();

    return Column(
      children: <Widget>[
        const _WeekdayHeaderRow(),
        Expanded(
          child: GridView.builder(
            key: const Key('calendar_month_grid'),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              // 6-row months need taller cells (lower ratio) or chips overflow
              // by fractional pixels on phone heights.
              childAspectRatio: rows <= 5 ? 1.0 : 0.78,
            ),
            itemCount: cellCount,
            itemBuilder: (BuildContext context, int index) {
              final DateTime day = gridStart.add(Duration(days: index));
              final bool inMonth = day.month == month.month;
              final bool isToday =
                  day.year == today.year &&
                  day.month == today.month &&
                  day.day == today.day;
              final List<CalendarEvent> events = state.eventsOnDay(day);
              return _DayCell(
                day: day,
                inMonth: inMonth,
                isToday: isToday,
                events: events,
                state: state,
                dndEnabled: dndEnabled,
                onTap: () => showDayEventsSheet(
                  context,
                  cubit: cubit,
                  state: state,
                  day: day,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CalendarEventChip extends StatelessWidget {
  const _CalendarEventChip({
    required this.title,
    required this.accent,
    required this.tokens,
  });

  final String title;
  final Color accent;
  final ThemeTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 0),
      decoration: BoxDecoration(
        color: _calendarAccentWash(accent, tokens),
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(color: accent, width: 2)),
      ),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: tokens.text, fontSize: 10, height: 1.15),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.inMonth,
    required this.isToday,
    required this.events,
    required this.state,
    required this.dndEnabled,
    required this.onTap,
  });

  final DateTime day;
  final bool inMonth;
  final bool isToday;
  final List<CalendarEvent> events;
  final CalendarState state;
  final bool dndEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(1),
        padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
        decoration: BoxDecoration(
          color: inMonth ? t.panel : t.panel.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(8),
          border: isToday ? Border.all(color: t.teal, width: 1.4) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${day.day}',
              style: TextStyle(
                color: inMonth ? t.text : t.muted,
                fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  // Fit chips to remaining height — fixed maxVisible=3 caused
                  // BOTTOM OVERFLOWED BY ~0.76px on 6-row phone months.
                  const double chipExtent = 13;
                  final double maxH = constraints.maxHeight;
                  final int capacity =
                      maxH <= 0 ? 0 : (maxH / chipExtent).floor();
                  if (capacity <= 0 || events.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final List<CalendarEvent> visible;
                  final int overflowCount;
                  if (events.length <= capacity) {
                    visible = events;
                    overflowCount = 0;
                  } else if (capacity == 1) {
                    visible = const <CalendarEvent>[];
                    overflowCount = events.length;
                  } else {
                    visible = events.take(capacity - 1).toList();
                    overflowCount = events.length - visible.length;
                  }
                  return ListView(
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    children: <Widget>[
                      for (final CalendarEvent event in visible)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: desktopEventDraggable(
                            enabled: dndEnabled,
                            data: PimEventDragData(
                              eventId: event.id,
                              sourceCalendarId: event.calendarId,
                              sourceAccountId: event.accountId,
                              title: event.title,
                            ),
                            accent: _calendarAccentColor(
                              state,
                              event.calendarId,
                              t,
                            ),
                            child: _CalendarEventChip(
                              title: event.title,
                              accent: _calendarAccentColor(
                                state,
                                event.calendarId,
                                t,
                              ),
                              tokens: t,
                            ),
                          ),
                        ),
                      if (overflowCount > 0)
                        Text(
                          '+$overflowCount more',
                          style: TextStyle(
                            color: t.muted,
                            fontSize: 10,
                            height: 1.0,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AgendaView extends StatelessWidget {
  const _AgendaView({
    required this.state,
    required this.cubit,
    required this.dndEnabled,
  });

  final CalendarState state;
  final CalendarCubit cubit;
  final bool dndEnabled;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final List<CalendarEvent> events = List<CalendarEvent>.from(state.events)
      ..sort(
        (CalendarEvent a, CalendarEvent b) =>
            a.startEpochMs.compareTo(b.startEpochMs),
      );

    if (state.viewMode == CalendarViewMode.sideBySide &&
        state.selectedCalendars.length > 1) {
      return Row(
        key: const Key('calendar_agenda_side_by_side'),
        children: <Widget>[
          for (int i = 0; i < state.selectedCalendars.length; i++) ...<Widget>[
            if (i > 0) VerticalDivider(width: 1, color: t.line),
            Expanded(
              child: _AgendaColumn(
                calendar: state.selectedCalendars[i],
                events: events
                    .where(
                      (CalendarEvent e) =>
                          e.calendarId == state.selectedCalendars[i].id,
                    )
                    .toList(growable: false),
                dndEnabled: dndEnabled,
                onTapEvent: (CalendarEvent e) => showEventEditorSheet(
                  context,
                  cubit: cubit,
                  state: state,
                  event: e,
                ),
                onLongPressEvent: (CalendarEvent e) {
                  _eventCopyLongPressHandler(
                    context,
                    event: e,
                    cubit: cubit,
                    state: state,
                  )?.call();
                },
                onAcceptDrop: (PimEventDragData data) => _acceptEventCopy(
                  context,
                  cubit: cubit,
                  data: data,
                  targetCalendar: state.selectedCalendars[i],
                ),
              ),
            ),
          ],
        ],
      );
    }

    if (events.isEmpty) {
      return Center(
        child: Text(
          'No events this month.',
          style: TextStyle(color: t.muted),
        ),
      );
    }
    return ListView.builder(
      key: const Key('calendar_agenda_list'),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: events.length,
      itemBuilder: (BuildContext context, int index) {
        final CalendarEvent event = events[index];
        return _AgendaEventTile(
          event: event,
          calendar: state.calendarById(event.calendarId),
          dndEnabled: dndEnabled,
          onTap: () => showEventEditorSheet(
            context,
            cubit: cubit,
            state: state,
            event: event,
          ),
          onLongPress: _eventCopyLongPressHandler(
            context,
            event: event,
            cubit: cubit,
            state: state,
          ),
        );
      },
    );
  }
}

class _AgendaColumn extends StatelessWidget {
  const _AgendaColumn({
    required this.calendar,
    required this.events,
    required this.onTapEvent,
    required this.dndEnabled,
    required this.onAcceptDrop,
    this.onLongPressEvent,
  });

  final Calendar calendar;
  final List<CalendarEvent> events;
  final ValueChanged<CalendarEvent> onTapEvent;
  final bool dndEnabled;
  final Future<void> Function(PimEventDragData data) onAcceptDrop;
  final ValueChanged<CalendarEvent>? onLongPressEvent;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return CalendarAgendaLaneDropTarget(
      calendar: calendar,
      enabled: dndEnabled,
      onAccept: onAcceptDrop,
      child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: <Widget>[
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Color(calendar.effectiveColorArgb),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  calendar.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: events.isEmpty
              ? Center(
                  child: Text(
                    'No events',
                    style: TextStyle(color: t.muted, fontSize: 11),
                  ),
                )
              : ListView.builder(
                  itemCount: events.length,
                  itemBuilder: (BuildContext context, int index) {
                    final CalendarEvent event = events[index];
                    return _AgendaEventTile(
                      event: event,
                      calendar: calendar,
                      dndEnabled: dndEnabled,
                      onTap: () => onTapEvent(event),
                      onLongPress: onLongPressEvent == null
                          ? null
                          : () => onLongPressEvent!(event),
                      dense: true,
                    );
                  },
                ),
        ),
      ],
      ),
    );
  }
}

class _AgendaEventTile extends StatelessWidget {
  const _AgendaEventTile({
    required this.event,
    required this.calendar,
    required this.onTap,
    this.onLongPress,
    this.dndEnabled = false,
    this.dense = false,
  });

  final CalendarEvent event;
  final Calendar? calendar;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final bool dndEnabled;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final DateTime start = DateTime.fromMillisecondsSinceEpoch(
      event.startEpochMs,
    );
    final Color accent = Color(
      calendar?.effectiveColorArgb ?? t.indigo.toARGB32(),
    );
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 6 : 12,
        vertical: dense ? 2 : 4,
      ),
      child: desktopEventDraggable(
        enabled: dndEnabled,
        data: PimEventDragData(
          eventId: event.id,
          sourceCalendarId: event.calendarId,
          sourceAccountId: event.accountId,
          title: event.title,
        ),
        accent: accent,
        child: Material(
          color: _calendarAccentWash(accent, t),
          borderRadius: BorderRadius.circular(8),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onLongPress: onLongPress,
            child: InkWell(
              key: ValueKey<String>('calendar_agenda_event_${event.id}'),
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: accent, width: 3),
                  ),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: dense ? 10 : 12,
                  vertical: dense ? 8 : 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      event.title,
                      style: TextStyle(
                        color: t.text,
                        fontWeight: FontWeight.w600,
                        fontSize: dense ? 13 : 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${start.month}/${start.day} · ${_formatEventTimeRange(event)}'
                      '${calendar == null ? '' : ' · ${calendar!.name}'}',
                      style: TextStyle(color: t.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the bottom sheet listing all events on [day], with an "Add event"
/// shortcut pre-filled to that day.
Future<void> showDayEventsSheet(
  BuildContext context, {
  required CalendarCubit cubit,
  required CalendarState state,
  required DateTime day,
}) {
  final ThemeTokens t = tokensOf(context);
  final List<CalendarEvent> events = state.eventsOnDay(day);
  // Capture before the modal route; sheet MediaQuery often reports
  // viewPadding.bottom == 0 (DEF-074).
  final double systemBottom = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      final double keyboard = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final double bottomInset = keyboard + systemBottom;
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: bottomInset + 12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              '${day.year}-${day.month.toString().padLeft(2, '0')}-'
              '${day.day.toString().padLeft(2, '0')}',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No events on this day.',
                  style: TextStyle(color: t.muted),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: events.length,
                  itemBuilder: (BuildContext context, int index) {
                    final CalendarEvent event = events[index];
                    return _AgendaEventTile(
                      event: event,
                      calendar: state.calendarById(event.calendarId),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        showEventEditorSheet(
                          context,
                          cubit: cubit,
                          state: state,
                          event: event,
                        );
                      },
                      onLongPress: _eventCopyLongPressHandler(
                        sheetContext,
                        event: event,
                        cubit: cubit,
                        state: state,
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('calendar_day_add_event'),
              onPressed: () {
                Navigator.of(sheetContext).pop();
                showEventEditorSheet(
                  context,
                  cubit: cubit,
                  state: state,
                  initialDay: day,
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add event'),
            ),
          ],
        ),
      );
    },
  );
}

/// Opens the checkbox picker sheet for calendar display selection
/// ([DriftPimStore.setCalendarDisplayPrefs]).
///
/// Listens to [CalendarCubit] so toggles rebuild after
/// [CalendarCubit.setCalendarSelected] persists + refreshes (DEF-060).
Future<void> showCalendarPickerSheet(
  BuildContext context, {
  required CalendarCubit cubit,
}) {
  final ThemeTokens t = tokensOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return BlocBuilder<CalendarCubit, CalendarState>(
        bloc: cubit,
        builder: (BuildContext context, CalendarState state) {
          final Map<String, List<Calendar>> byAccount =
              <String, List<Calendar>>{};
          for (final Calendar calendar in state.calendars) {
            byAccount
                .putIfAbsent(calendar.accountId, () => <Calendar>[])
                .add(calendar);
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Calendars',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose which calendars display on the workspace.',
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      for (final MapEntry<String, List<Calendar>> entry
                          in byAccount.entries) ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 2),
                          child: Text(
                            _accountLabelFor(state.accounts, entry.key),
                            style: TextStyle(
                              color: t.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        for (final Calendar calendar in entry.value)
                          SwitchListTile(
                            key: ValueKey<String>(
                              'calendar_toggle_${calendar.id}',
                            ),
                            contentPadding: EdgeInsets.zero,
                            secondary: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(calendar.effectiveColorArgb),
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(calendar.name),
                            value: calendar.isSelectedForDisplay,
                            onChanged: (bool value) =>
                                cubit.setCalendarSelected(
                              calendar.id,
                              value,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Opens the event create/edit sheet. Local-only writes — no `events_push`
/// enqueue (see [kLocalEventWriteNotice]).
Future<void> showEventEditorSheet(
  BuildContext context, {
  required CalendarCubit cubit,
  required CalendarState state,
  CalendarEvent? event,
  DateTime? initialDay,
}) {
  final ThemeTokens t = tokensOf(context);
  final double systemBottom = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      final double keyboard = MediaQuery.viewInsetsOf(sheetContext).bottom;
      final double bottomInset = keyboard + systemBottom;
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: bottomInset + 12,
        ),
        child: _EventEditorForm(
          cubit: cubit,
          state: state,
          event: event,
          initialDay: initialDay,
        ),
      );
    },
  );
}

class _EventEditorForm extends StatefulWidget {
  const _EventEditorForm({
    required this.cubit,
    required this.state,
    this.event,
    this.initialDay,
  });

  final CalendarCubit cubit;
  final CalendarState state;
  final CalendarEvent? event;
  final DateTime? initialDay;

  @override
  State<_EventEditorForm> createState() => _EventEditorFormState();
}

class _EventEditorFormState extends State<_EventEditorForm> {
  late final TextEditingController _titleController;
  late final TextEditingController _locationController;
  late final TextEditingController _notesController;
  late String _calendarId;
  late DateTime _start;
  late DateTime _end;
  late bool _allDay;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final CalendarEvent? event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _locationController = TextEditingController(text: event?.location ?? '');
    _notesController = TextEditingController(text: event?.body ?? '');
    _allDay = event?.allDay ?? false;
    if (event != null) {
      _start = DateTime.fromMillisecondsSinceEpoch(event.startEpochMs);
      _end = DateTime.fromMillisecondsSinceEpoch(event.endEpochMs);
      _calendarId = event.calendarId;
    } else {
      final DateTime day = widget.initialDay ?? DateTime.now();
      final DateTime baseline = DateTime.now();
      _start = DateTime(day.year, day.month, day.day, baseline.hour + 1);
      _end = _start.add(const Duration(hours: 1));
      final List<Calendar> selected = widget.state.selectedCalendars;
      _calendarId = selected.isNotEmpty
          ? selected.first.id
          : widget.state.calendars.first.id;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final DateTime current = isStart ? _start : _end;
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 5),
      lastDate: DateTime(current.year + 5),
    );
    if (date == null || !mounted) {
      return;
    }
    if (_allDay) {
      setState(() {
        if (isStart) {
          _start = DateTime(date.year, date.month, date.day);
        } else {
          _end = DateTime(date.year, date.month, date.day + 1);
        }
      });
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (time == null || !mounted) {
      return;
    }
    setState(() {
      final DateTime combined = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
      if (isStart) {
        _start = combined;
        if (!_end.isAfter(_start)) {
          _end = _start.add(const Duration(hours: 1));
        }
      } else {
        _end = combined;
      }
    });
  }

  Future<void> _save() async {
    final String title = _titleController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'Title is required.');
      return;
    }
    if (!_end.isAfter(_start)) {
      setState(() => _error = 'End time must be after the start time.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final Calendar? calendar = widget.state.calendarById(_calendarId);
    if (calendar == null) {
      setState(() {
        _busy = false;
        _error = 'Select a calendar.';
      });
      return;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      final CalendarEvent? existing = widget.event;
      if (existing == null) {
        await widget.cubit.createEvent(
          accountId: calendar.accountId,
          calendarId: _calendarId,
          title: title,
          startEpochMs: _start.millisecondsSinceEpoch,
          endEpochMs: _end.millisecondsSinceEpoch,
          allDay: _allDay,
          location: _locationController.text.trim().isEmpty
              ? null
              : _locationController.text.trim(),
          body: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );
      } else {
        await widget.cubit.updateEvent(
          CalendarEvent(
            id: existing.id,
            accountId: existing.accountId,
            calendarId: _calendarId,
            providerId: existing.providerId,
            title: title,
            body: _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
            startEpochMs: _start.millisecondsSinceEpoch,
            endEpochMs: _end.millisecondsSinceEpoch,
            allDay: _allDay,
            location: _locationController.text.trim().isEmpty
                ? null
                : _locationController.text.trim(),
            rrule: existing.rrule,
            reminderMinutes: existing.reminderMinutes,
            etag: existing.etag,
            updatedAt: existing.updatedAt,
            deletedAt: existing.deletedAt,
          ),
        );
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text(kLocalEventWriteNotice)),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _delete() async {
    final CalendarEvent? existing = widget.event;
    if (existing == null) {
      return;
    }
    setState(() => _busy = true);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    try {
      await widget.cubit.deleteEvent(existing.id);
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Event deleted (local only).')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final bool isEditing = widget.event != null;
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            isEditing ? 'Edit event' : 'New event',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            kLocalEventWriteNotice,
            style: TextStyle(color: t.muted, fontSize: 11),
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('event_title_field'),
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: const Key('event_calendar_dropdown'),
            initialValue: _calendarId,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Calendar'),
            items: <DropdownMenuItem<String>>[
              for (final Calendar calendar in widget.state.calendars)
                DropdownMenuItem<String>(
                  value: calendar.id,
                  child: Text(
                    '${calendar.name} '
                    '(${_accountLabelFor(widget.state.accounts, calendar.accountId)})',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                setState(() => _calendarId = value);
              }
            },
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            key: const Key('event_all_day_switch'),
            contentPadding: EdgeInsets.zero,
            title: const Text('All day'),
            value: _allDay,
            onChanged: (bool value) => setState(() => _allDay = value),
          ),
          ListTile(
            key: const Key('event_start_tile'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Starts'),
            subtitle: Text(
              _allDay
                  ? '${_start.year}-${_start.month}-${_start.day}'
                  : _start.toString(),
            ),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () => _pickDateTime(isStart: true),
          ),
          ListTile(
            key: const Key('event_end_tile'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Ends'),
            subtitle: Text(
              _allDay
                  ? '${_end.year}-${_end.month}-${_end.day}'
                  : _end.toString(),
            ),
            trailing: const Icon(Icons.edit_calendar_outlined),
            onTap: () => _pickDateTime(isStart: false),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('event_location_field'),
            controller: _locationController,
            decoration: const InputDecoration(labelText: 'Location'),
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('event_notes_field'),
            controller: _notesController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          if (_error != null) ...<Widget>[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: t.coral)),
          ],
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              if (isEditing)
                TextButton(
                  key: const Key('event_delete_button'),
                  onPressed: _busy ? null : _delete,
                  style: TextButton.styleFrom(foregroundColor: t.coral),
                  child: const Text('Delete'),
                ),
              const Spacer(),
              FilledButton(
                key: const Key('event_save_button'),
                onPressed: _busy ? null : _save,
                child: Text(_busy ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
