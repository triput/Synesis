// ==============================================================================
// File: test/calendar_day_sheet_nav_inset_test.dart
// Description: Day-events sheet Add event clears Android viewPadding (DEF-074)
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'day events Add event sits above viewPadding.bottom (DEF-074)',
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
      await pimStore.createLocalEvent(
        accountId: 'work',
        calendarId: calendarId,
        title: 'Coursera learning time',
        startEpochMs: DateTime(2026, 8, 4, 9).millisecondsSinceEpoch,
        endEpochMs: DateTime(2026, 8, 4, 10).millisecondsSinceEpoch,
      );

      final CalendarCubit cubit = CalendarCubit(
        pimStore: pimStore,
        repository: repo,
        initialMonth: DateTime(2026, 8, 1),
      );
      addTearDown(cubit.close);
      await cubit.refresh();

      final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
      const double navInset = 48;
      const Size phone = Size(360, 640);

      await tester.binding.setSurfaceSize(phone);
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
              size: phone,
              viewPadding: EdgeInsets.only(bottom: navInset),
              padding: EdgeInsets.zero,
            ),
            child: Builder(
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () {
                        showDayEventsSheet(
                          context,
                          cubit: cubit,
                          state: cubit.state,
                          day: DateTime(2026, 8, 4),
                        );
                      },
                      child: const Text('Open day'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open day'));
      await tester.pumpAndSettle();

      final Finder add = find.byKey(const Key('calendar_day_add_event'));
      expect(add, findsOneWidget);
      final double buttonBottom = tester.getBottomLeft(add).dy;
      expect(
        buttonBottom,
        lessThanOrEqualTo(phone.height - navInset),
        reason: 'Add event must clear system nav inset',
      );
    },
  );
}
