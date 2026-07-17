// ==============================================================================
// File: test/message_body_view_find_test.dart
// Description: Widget tests for plain-text find navigation in ReadingPane
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/desktop/detached_message_window_controller.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/shell/reading_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

MailMessage _plainMessage() {
  return const MailMessage(
    id: 'm1',
    accountId: 'acc',
    fromName: 'Ada',
    fromAddress: 'ada@byte.io',
    subject: 'Find me',
    snippet: 'Body preview',
    body: 'First alpha line.\nSecond ALPHA line.\nThird alpha line.',
    whenLabel: '10:00',
    bucket: FocusBucket.focused,
  );
}

Widget _harness({
  required bool findRequested,
  VoidCallback? onFindHandled,
}) {
  final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
  return RepositoryProvider<DetachedMessageWindowController>.value(
    value: const NoopDetachedMessageWindowController(),
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: tokens.brightness,
        extensions: <ThemeExtension<dynamic>>[tokens],
      ),
      home: Scaffold(
        body: SizedBox(
          width: 640,
          height: 720,
          child: ReadingPane(
            message: _plainMessage(),
            accounts: const <MailAccount>[
              MailAccount(
                id: 'acc',
                label: 'Work',
                address: 'work@byte.io',
                accent: Color(0xFF2DD4BF),
              ),
            ],
            density: ViewDensity.compact,
            findInMessageRequested: findRequested,
            onFindRequestHandled: onFindHandled,
            onReply: () {},
            onShowHeaders: () {},
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('Ctrl+F request opens find bar and clears parent flag', (
    WidgetTester tester,
  ) async {
    bool handled = false;
    await tester.pumpWidget(
      _harness(
        findRequested: true,
        onFindHandled: () => handled = true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Find in message'), findsOneWidget);
    expect(handled, isTrue);
  });

  testWidgets('toggling find request after mount does not setState during build', (
    WidgetTester tester,
  ) async {
    bool handled = false;
    await tester.pumpWidget(
      _harness(
        findRequested: false,
        onFindHandled: () => handled = true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Find in message'), findsNothing);

    await tester.pumpWidget(
      _harness(
        findRequested: true,
        onFindHandled: () => handled = true,
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();

    expect(find.text('Find in message'), findsOneWidget);
    expect(handled, isTrue);
  });

  testWidgets('plain body find navigates match count', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_harness(findRequested: true));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'alpha');
    await tester.pumpAndSettle();

    expect(find.text('1 of 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Next match'));
    await tester.pumpAndSettle();
    expect(find.text('2 of 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Previous match'));
    await tester.pumpAndSettle();
    expect(find.text('1 of 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Close find'));
    await tester.pumpAndSettle();
    expect(find.text('Find in message'), findsNothing);
  });

  testWidgets('short reading pane does not overflow chrome + body', (
    WidgetTester tester,
  ) async {
    final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
    await tester.pumpWidget(
      RepositoryProvider<DetachedMessageWindowController>.value(
        value: const NoopDetachedMessageWindowController(),
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            brightness: tokens.brightness,
            extensions: <ThemeExtension<dynamic>>[tokens],
          ),
          home: Scaffold(
            body: SizedBox(
              width: 640,
              height: 220,
              child: ReadingPane(
                message: _plainMessage(),
                accounts: const <MailAccount>[
                  MailAccount(
                    id: 'acc',
                    label: 'Work',
                    address: 'work@byte.io',
                    accent: Color(0xFF2DD4BF),
                  ),
                ],
                density: ViewDensity.calm,
                findInMessageRequested: true,
                onFindRequestHandled: () {},
                onReply: () {},
                onShowHeaders: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Find me'), findsOneWidget);
    expect(find.textContaining('First alpha'), findsOneWidget);
  });
}
