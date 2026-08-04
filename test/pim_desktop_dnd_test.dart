// ==============================================================================
// File: test/pim_desktop_dnd_test.dart
// Description: Wave 6 desktop DnD copy widget tests (calendar + people).
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-04
// Last Update: 2026-08-04
// ==============================================================================

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/domain/pim_ids.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/sync/pim_copy_service.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/ui/calendar/calendar_cubit.dart';
import 'package:synesis/ui/calendar/calendar_workspace.dart';
import 'package:synesis/ui/people/people_cubit.dart';
import 'package:synesis/ui/people/people_workspace.dart';

Future<(SynesisDatabase, DriftMailRepository, DriftPimStore, PimCopyService)>
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
      address: 'a@contoso.com',
      accent: Color(0xFF0078D4),
      providerType: 'graph',
    ),
    providerType: 'graph',
  );
  await repo.upsertAccount(
    const MailAccount(
      id: 'b',
      label: 'Account B',
      address: 'b@contoso.com',
      accent: Color(0xFF2DD4BF),
      providerType: 'graph',
    ),
    providerType: 'graph',
  );
  final PimCopyService copyService = PimCopyService(
    pimStore: pimStore,
    repository: repo,
    resolvePim: (_) async => GraphPimProvider(() async => 'token'),
  );
  return (database, repo, pimStore, copyService);
}

Widget _desktopShell({required Widget child}) {
  return MaterialApp(
    theme: AppTheme.materialThemeFor(ThemeId.dark),
    home: MediaQuery(
      data: const MediaQueryData(size: Size(900, 700)),
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Calendar desktop DnD', () {
    testWidgets('drag event chip onto lane drop copies locally', (
      WidgetTester tester,
    ) async {
      final (
        SynesisDatabase database,
        DriftMailRepository repo,
        DriftPimStore pimStore,
        PimCopyService copyService,
      ) = await _openFixture();
      addTearDown(database.close);

      final String calA = PimIds.stableLocalId('a', 'primary');
      final String calB = PimIds.stableLocalId('b', 'primary');
      await pimStore.upsertCalendars(<Calendar>[
        Calendar(
          id: calA,
          accountId: 'a',
          providerId: 'primary',
          name: 'A Primary',
          colorArgb: 0xFF0078D4,
          isSelectedForDisplay: true,
        ),
        Calendar(
          id: calB,
          accountId: 'b',
          providerId: 'primary',
          name: 'B Primary',
          colorArgb: 0xFF2DD4BF,
          isSelectedForDisplay: true,
        ),
      ]);
      final CalendarEvent source = await pimStore.createLocalEvent(
        accountId: 'a',
        calendarId: calA,
        title: 'Standup',
        startEpochMs: DateTime(2026, 8, 4, 9).millisecondsSinceEpoch,
        endEpochMs: DateTime(2026, 8, 4, 10).millisecondsSinceEpoch,
      );

      final CalendarCubit cubit = CalendarCubit(
        pimStore: pimStore,
        repository: repo,
        copyService: copyService,
        initialMonth: DateTime(2026, 8, 1),
      );
      addTearDown(cubit.close);
      await cubit.refresh();

      await tester.pumpWidget(
        _desktopShell(
          child: BlocProvider<CalendarCubit>.value(
            value: cubit,
            child: const CalendarWorkspace(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(Key('calendar_event_draggable_${source.id}')), findsOneWidget);
      expect(find.byKey(Key('calendar_lane_drop_$calB')), findsOneWidget);

      final Offset dragStart = tester.getCenter(
        find.byKey(Key('calendar_event_draggable_${source.id}')),
      );
      final Offset dragEnd = tester.getCenter(
        find.byKey(Key('calendar_lane_drop_$calB')),
      );
      await tester.dragFrom(dragStart, dragEnd - dragStart);
      await tester.pumpAndSettle();

      expect(find.textContaining('Copied to B Primary'), findsOneWidget);

      final List<CalendarEvent> augustEvents = cubit.state.events
          .where((CalendarEvent e) => e.title == 'Standup')
          .toList();
      expect(augustEvents.length, 2);
    });
  });

  group('People desktop DnD', () {
    testWidgets('drag contact row onto list lane copies locally', (
      WidgetTester tester,
    ) async {
      final (
        SynesisDatabase database,
        DriftMailRepository repo,
        DriftPimStore pimStore,
        PimCopyService copyService,
      ) = await _openFixture();
      addTearDown(database.close);

      final String listA = PimIds.stableLocalId('a', 'contacts');
      final String listB = PimIds.stableLocalId('b', 'contacts');
      await pimStore.upsertContactLists(<ContactList>[
        ContactList(
          id: listA,
          accountId: 'a',
          providerId: 'contacts',
          name: 'A Contacts',
          isSelectedForDisplay: true,
        ),
        ContactList(
          id: listB,
          accountId: 'b',
          providerId: 'contacts',
          name: 'B Contacts',
          isSelectedForDisplay: true,
        ),
      ]);
      final Contact source = await pimStore.createLocalContact(
        accountId: 'a',
        contactListId: listA,
        displayName: 'Ada Lovelace',
      );

      final PeopleCubit cubit = PeopleCubit(
        pimStore: pimStore,
        repository: repo,
        copyService: copyService,
      );
      addTearDown(cubit.close);
      await cubit.refresh();

      await tester.pumpWidget(
        _desktopShell(
          child: BlocProvider<PeopleCubit>.value(
            value: cubit,
            child: const PeopleWorkspace(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(Key('people_contact_draggable_${source.id}')),
        findsOneWidget,
      );
      expect(find.byKey(Key('people_list_drop_$listB')), findsOneWidget);

      final Offset dragStart = tester.getCenter(
        find.byKey(Key('people_contact_draggable_${source.id}')),
      );
      final Offset dragEnd = tester.getCenter(
        find.byKey(Key('people_list_drop_$listB')),
      );
      await tester.dragFrom(dragStart, dragEnd - dragStart);
      await tester.pumpAndSettle();

      expect(find.textContaining('Copied to B Contacts'), findsOneWidget);

      final List<Contact> adaRows = cubit.state.contacts
          .where((Contact c) => c.displayName == 'Ada Lovelace')
          .toList();
      expect(adaRows.length, 2);
    });
  });
}
