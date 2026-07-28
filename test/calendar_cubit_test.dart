// ==============================================================================
// File: test/calendar_cubit_test.dart
// Description: CalendarCubit month-range load and local event CRUD tests.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/ui/calendar/calendar_cubit.dart';

Future<
  (SynesisDatabase, DriftMailRepository, DriftPimStore)
>
_openFixture() async {
  final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
  await database.customSelect('SELECT 1').get();
  final DriftMailRepository repo = DriftMailRepository(database);
  final DriftPimStore pimStore = DriftPimStore(
    database,
    notify: repo.notifyChanges,
  );
  await repo.upsertAccount(
    const MailAccount(
      id: 'work',
      label: 'Work',
      address: 'work@byte.io',
      accent: Color(0xFF2DD4BF),
    ),
    providerType: 'imap',
  );
  return (database, repo, pimStore);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CalendarCubit.refresh', () {
    test('loads events overlapping the focused month only', () async {
      final (
        SynesisDatabase database,
        DriftMailRepository repo,
        DriftPimStore pimStore,
      ) = await _openFixture();
      addTearDown(database.close);

      final String calendarId = DriftPimStore.stableLocalId(
        'work',
        'primary',
      );
      await pimStore.upsertCalendars(<Calendar>[
        Calendar(
          id: calendarId,
          accountId: 'work',
          providerId: 'primary',
          name: 'Primary',
          colorArgb: 0xFF2DD4BF,
          isSelectedForDisplay: true,
        ),
      ]);

      final DateTime focused = DateTime(2026, 7, 1);
      final CalendarCubit cubit = CalendarCubit(
        pimStore: pimStore,
        repository: repo,
        initialMonth: focused,
      );
      addTearDown(cubit.close);

      // Inside July: should appear once refreshed.
      await pimStore.createLocalEvent(
        accountId: 'work',
        calendarId: calendarId,
        title: 'July standup',
        startEpochMs: DateTime(2026, 7, 15, 9).millisecondsSinceEpoch,
        endEpochMs: DateTime(2026, 7, 15, 10).millisecondsSinceEpoch,
      );
      // Outside July: must not leak into the July range query.
      await pimStore.createLocalEvent(
        accountId: 'work',
        calendarId: calendarId,
        title: 'August retro',
        startEpochMs: DateTime(2026, 8, 3, 9).millisecondsSinceEpoch,
        endEpochMs: DateTime(2026, 8, 3, 10).millisecondsSinceEpoch,
      );

      await cubit.refresh();

      expect(cubit.state.events, hasLength(1));
      expect(cubit.state.events.single.title, 'July standup');
      expect(cubit.state.calendars, hasLength(1));
      expect(cubit.state.hasSelectedCalendars, isTrue);
    });

    test('goToMonth/nextMonth/previousMonth reload the visible range', () async {
      final (
        SynesisDatabase database,
        DriftMailRepository repo,
        DriftPimStore pimStore,
      ) = await _openFixture();
      addTearDown(database.close);

      final String calendarId = DriftPimStore.stableLocalId(
        'work',
        'primary',
      );
      await pimStore.upsertCalendars(<Calendar>[
        Calendar(
          id: calendarId,
          accountId: 'work',
          providerId: 'primary',
          name: 'Primary',
          colorArgb: 0xFF2DD4BF,
        ),
      ]);
      await pimStore.createLocalEvent(
        accountId: 'work',
        calendarId: calendarId,
        title: 'August kickoff',
        startEpochMs: DateTime(2026, 8, 3, 9).millisecondsSinceEpoch,
        endEpochMs: DateTime(2026, 8, 3, 10).millisecondsSinceEpoch,
      );

      final CalendarCubit cubit = CalendarCubit(
        pimStore: pimStore,
        repository: repo,
        initialMonth: DateTime(2026, 7, 1),
      );
      addTearDown(cubit.close);
      await cubit.refresh();
      expect(cubit.state.events, isEmpty);

      await cubit.nextMonth();
      expect(cubit.state.focusedMonth, DateTime(2026, 8, 1));
      expect(cubit.state.events, hasLength(1));

      await cubit.previousMonth();
      expect(cubit.state.focusedMonth, DateTime(2026, 7, 1));
      expect(cubit.state.events, isEmpty);
    });
  });

  group('CalendarCubit local event CRUD', () {
    test('createEvent + deleteEvent soft-deletes and drops from state', () async {
      final (
        SynesisDatabase database,
        DriftMailRepository repo,
        DriftPimStore pimStore,
      ) = await _openFixture();
      addTearDown(database.close);

      final String calendarId = DriftPimStore.stableLocalId(
        'work',
        'primary',
      );
      await pimStore.upsertCalendars(<Calendar>[
        Calendar(
          id: calendarId,
          accountId: 'work',
          providerId: 'primary',
          name: 'Primary',
          colorArgb: 0xFF2DD4BF,
        ),
      ]);

      final CalendarCubit cubit = CalendarCubit(
        pimStore: pimStore,
        repository: repo,
        initialMonth: DateTime(2026, 7, 1),
      );
      addTearDown(cubit.close);
      await cubit.refresh();

      final CalendarEvent created = await cubit.createEvent(
        accountId: 'work',
        calendarId: calendarId,
        title: 'Local-only planning',
        startEpochMs: DateTime(2026, 7, 20, 14).millisecondsSinceEpoch,
        endEpochMs: DateTime(2026, 7, 20, 15).millisecondsSinceEpoch,
      );

      // The shared MailRepository change stream fan-out is async; force a
      // deterministic refresh rather than racing `notify()`.
      await cubit.refresh();
      expect(cubit.state.events.map((CalendarEvent e) => e.id), contains(created.id));

      await cubit.deleteEvent(created.id);
      await cubit.refresh();
      expect(
        cubit.state.events.map((CalendarEvent e) => e.id),
        isNot(contains(created.id)),
      );

      // Soft-deleted, not hard-deleted, at the store level.
      final List<CalendarEvent> raw = await pimStore.listEvents(
        includeDeleted: true,
      );
      final CalendarEvent stored = raw.singleWhere(
        (CalendarEvent e) => e.id == created.id,
      );
      expect(stored.deletedAt, isNotNull);
    });

    test('setCalendarSelected toggles isSelectedForDisplay', () async {
      final (
        SynesisDatabase database,
        DriftMailRepository repo,
        DriftPimStore pimStore,
      ) = await _openFixture();
      addTearDown(database.close);

      final String calendarId = DriftPimStore.stableLocalId(
        'work',
        'primary',
      );
      await pimStore.upsertCalendars(<Calendar>[
        Calendar(
          id: calendarId,
          accountId: 'work',
          providerId: 'primary',
          name: 'Primary',
          colorArgb: 0xFF2DD4BF,
          isSelectedForDisplay: true,
        ),
      ]);

      final CalendarCubit cubit = CalendarCubit(
        pimStore: pimStore,
        repository: repo,
        initialMonth: DateTime(2026, 7, 1),
      );
      addTearDown(cubit.close);
      await cubit.refresh();
      expect(cubit.state.hasSelectedCalendars, isTrue);

      await cubit.setCalendarSelected(calendarId, false);
      await cubit.refresh();
      expect(cubit.state.hasSelectedCalendars, isFalse);
    });
  });
}
