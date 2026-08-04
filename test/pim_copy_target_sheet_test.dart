// ==============================================================================
// File: test/pim_copy_target_sheet_test.dart
// Description: Wave 6 P3 mobile copy target sheet open + invoke tests.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-04
// Last Update: 2026-08-04
// ==============================================================================

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/pim_copy_service.dart';
import 'package:synesis/sync/pim_sync_jobs.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/ui/calendar/calendar_cubit.dart';
import 'package:synesis/ui/calendar/calendar_workspace.dart';
import 'package:synesis/ui/people/people_cubit.dart';
import 'package:synesis/ui/people/people_workspace.dart';

Future<
  (
    SynesisDatabase,
    DriftMailRepository,
    DriftPimStore,
    PimCopyService,
    CalendarCubit,
    PeopleCubit,
  )
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
      id: 'a',
      label: 'Account A',
      address: 'a@example.com',
      accent: Color(0xFF0078D4),
      providerType: 'graph',
    ),
    providerType: 'graph',
  );
  await repo.upsertAccount(
    const MailAccount(
      id: 'b',
      label: 'Account B',
      address: 'b@example.com',
      accent: Color(0xFF34A853),
      providerType: 'graph',
    ),
    providerType: 'graph',
  );

  final String calA = PimIds.stableLocalId('a', 'cal-a');
  final String calB = PimIds.stableLocalId('b', 'cal-b');
  await pimStore.upsertCalendars(<Calendar>[
    Calendar(
      id: calA,
      accountId: 'a',
      providerId: 'cal-a',
      name: 'A Calendar',
      colorArgb: 0xFF0078D4,
      isDefault: true,
      isSelectedForDisplay: true,
    ),
    Calendar(
      id: calB,
      accountId: 'b',
      providerId: 'cal-b',
      name: 'B Calendar',
      colorArgb: 0xFF34A853,
      isDefault: true,
      isSelectedForDisplay: true,
    ),
  ]);

  final String listA = PimIds.stableLocalId('a', 'list-a');
  final String listB = PimIds.stableLocalId('b', 'list-b');
  await pimStore.upsertContactLists(<ContactList>[
    ContactList(
      id: listA,
      accountId: 'a',
      providerId: 'list-a',
      name: 'A Contacts',
      isSelectedForDisplay: true,
    ),
    ContactList(
      id: listB,
      accountId: 'b',
      providerId: 'list-b',
      name: 'B Contacts',
      isSelectedForDisplay: true,
    ),
  ]);

  final DateTime now = DateTime.now();
  final DateTime start = DateTime(now.year, now.month, 15, 10);
  final DateTime end = start.add(const Duration(hours: 1));

  await pimStore.createLocalEvent(
    accountId: 'a',
    calendarId: calA,
    title: 'Standup',
    startEpochMs: start.millisecondsSinceEpoch,
    endEpochMs: end.millisecondsSinceEpoch,
  );
  final String contactId = PimIds.stableLocalId('a', 'c1');
  await pimStore.upsertContacts(<Contact>[
    Contact(
      id: contactId,
      accountId: 'a',
      contactListId: listA,
      providerId: 'c1',
      displayName: 'Ada Lovelace',
      updatedAt: 1,
    ),
  ]);

  final PimCopyService copyService = PimCopyService(
    pimStore: pimStore,
    repository: repo,
    resolvePim: (_) async => GraphPimProvider(() async => 'token'),
  );
  final CalendarCubit calendarCubit = CalendarCubit(
    pimStore: pimStore,
    repository: repo,
    copyService: copyService,
  );
  final PeopleCubit peopleCubit = PeopleCubit(
    pimStore: pimStore,
    repository: repo,
    copyService: copyService,
  );
  await calendarCubit.refresh();
  await peopleCubit.refresh();

  return (
    database,
    repo,
    pimStore,
    copyService,
    calendarCubit,
    peopleCubit,
  );
}

Widget _phoneShell({
  required Widget child,
  required PimCopyService copyService,
}) {
  return MaterialApp(
    theme: AppTheme.materialThemeFor(ThemeId.dark),
    home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844)),
      child: RepositoryProvider<PimCopyService>.value(
        value: copyService,
        child: child,
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Wave 6 P3 copy target sheets', () {
    testWidgets('event long-press opens Copy to calendar sheet and copies', (
      WidgetTester tester,
    ) async {
      final (
        SynesisDatabase database,
        DriftMailRepository repo,
        DriftPimStore _,
        PimCopyService copyService,
        CalendarCubit calendarCubit,
        PeopleCubit _,
      ) = await _openFixture();
      addTearDown(database.close);

      await tester.pumpWidget(
        _phoneShell(
          copyService: copyService,
          child: BlocProvider<CalendarCubit>.value(
            value: calendarCubit,
            child: const CalendarWorkspace(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      calendarCubit.setShowAgenda(true);
      await tester.pumpAndSettle();

      final String eventId = calendarCubit.state.events.first.id;
      await tester.longPress(
        find.byKey(ValueKey<String>('calendar_agenda_event_$eventId')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Copy to calendar…'), findsOneWidget);
      expect(find.text('Standup'), findsWidgets);
      expect(find.text('B Calendar'), findsOneWidget);

      await tester.tap(find.text('B Calendar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Copied to B Calendar'), findsOneWidget);

      final jobs = await repo.listSyncJobs(limit: 10);
      expect(
        jobs.where((SyncJob j) => j.type == PimSyncJobs.eventsCopy),
        isNotEmpty,
      );
    });

    testWidgets('contact long-press opens Copy to list sheet and copies', (
      WidgetTester tester,
    ) async {
      final (
        SynesisDatabase database,
        DriftMailRepository _,
        DriftPimStore _,
        PimCopyService copyService,
        CalendarCubit _,
        PeopleCubit peopleCubit,
      ) = await _openFixture();
      addTearDown(database.close);

      final String resolvedContactId = peopleCubit.state.contacts.first.id;

      await tester.pumpWidget(
        _phoneShell(
          copyService: copyService,
          child: BlocProvider<PeopleCubit>.value(
            value: peopleCubit,
            child: const PeopleWorkspace(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(
        find.byKey(ValueKey<String>('people_contact_row_$resolvedContactId')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Copy to list…'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsWidgets);
      expect(find.text('B Contacts'), findsOneWidget);

      await tester.tap(find.text('B Contacts'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Copied to B Contacts'), findsOneWidget);
    });
  });
}
