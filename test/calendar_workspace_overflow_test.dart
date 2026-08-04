// ==============================================================================
// File: test/calendar_workspace_overflow_test.dart
// Description: Phone-size RenderFlex overflow guards for Calendar month view
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/calendar/calendar_cubit.dart';
import 'package:synesis/ui/calendar/calendar_workspace.dart';

Future<(SynesisDatabase, DriftMailRepository, DriftPimStore)>
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

class _OverflowCapture {
  _OverflowCapture() {
    _previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String message = details.exceptionAsString();
      if (message.contains('overflowed') ||
          message.contains('A RenderFlex overflowed') ||
          message.contains('OVERFLOWING')) {
        overflow ??= details;
      }
      _previous?.call(details);
    };
  }

  void Function(FlutterErrorDetails)? _previous;
  FlutterErrorDetails? overflow;

  void restore() {
    FlutterError.onError = _previous;
  }

  void expectClean(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    expect(
      overflow,
      isNull,
      reason: overflow?.exceptionAsString(),
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'CalendarWorkspace month view no RenderFlex overflow at 360x640 (DEF-070)',
    (WidgetTester tester) async {
      final (
        SynesisDatabase database,
        DriftMailRepository repo,
        DriftPimStore pimStore,
      ) = await _openFixture();
      addTearDown(database.close);

      final String calendarId = DriftPimStore.stableLocalId('work', 'primary');
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

      // August 2026 is a 6-row month — the tight aspect-ratio path.
      for (int day = 1; day <= 10; day++) {
        await pimStore.createLocalEvent(
          accountId: 'work',
          calendarId: calendarId,
          title: 'Event $day A',
          startEpochMs: DateTime(2026, 8, day, 9).millisecondsSinceEpoch,
          endEpochMs: DateTime(2026, 8, day, 10).millisecondsSinceEpoch,
        );
        await pimStore.createLocalEvent(
          accountId: 'work',
          calendarId: calendarId,
          title: 'Event $day B',
          startEpochMs: DateTime(2026, 8, day, 11).millisecondsSinceEpoch,
          endEpochMs: DateTime(2026, 8, day, 12).millisecondsSinceEpoch,
        );
        await pimStore.createLocalEvent(
          accountId: 'work',
          calendarId: calendarId,
          title: 'Event $day C',
          startEpochMs: DateTime(2026, 8, day, 13).millisecondsSinceEpoch,
          endEpochMs: DateTime(2026, 8, day, 14).millisecondsSinceEpoch,
        );
      }

      final CalendarCubit cubit = CalendarCubit(
        pimStore: pimStore,
        repository: repo,
        initialMonth: DateTime(2026, 8, 1),
      );
      addTearDown(cubit.close);
      await cubit.refresh();

      final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
      final _OverflowCapture capture = _OverflowCapture();
      addTearDown(capture.restore);

      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            brightness: tokens.brightness,
            extensions: <ThemeExtension<dynamic>>[tokens],
          ),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              viewPadding: EdgeInsets.only(bottom: 48),
              padding: EdgeInsets.zero,
            ),
            child: BlocProvider<CalendarCubit>.value(
              value: cubit,
              child: const Scaffold(
                bottomNavigationBar: SizedBox(height: 56),
                body: CalendarWorkspace(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('calendar_month_grid')), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.byKey(const Key('calendar_view_toggle')), findsOneWidget);
      capture.expectClean(tester);
    },
  );
}
