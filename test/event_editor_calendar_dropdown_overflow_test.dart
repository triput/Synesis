// ==============================================================================
// File: test/event_editor_calendar_dropdown_overflow_test.dart
// Description: Event editor Calendar dropdown no RenderFlex overflow (DEF-077)
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
      label: 'trish@trishputnam.com',
      address: 'trish@trishputnam.com',
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
    'event editor Calendar dropdown no overflow with long labels (DEF-077)',
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
          name: 'trish@trishputnam.com',
          colorArgb: 0xFF2DD4BF,
          isSelectedForDisplay: true,
        ),
      ]);

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
            child: Builder(
              builder: (BuildContext context) {
                return Scaffold(
                  body: Center(
                    child: TextButton(
                      onPressed: () {
                        showEventEditorSheet(
                          context,
                          cubit: cubit,
                          state: cubit.state,
                          initialDay: DateTime(2026, 8, 3),
                        );
                      },
                      child: const Text('New event'),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('New event'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('event_calendar_dropdown')), findsOneWidget);
      capture.expectClean(tester);
    },
  );
}
