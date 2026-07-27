// ==============================================================================
// File: test/account_rail_overflow_test.dart
// Description: Short-height AccountRail overflow guard for Wave 0 identity tiles
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/shell/mail_workspace.dart';

Widget _themeWrap(Widget child) {
  final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      extensions: <ThemeExtension<dynamic>>[tokens],
    ),
    home: child,
  );
}

List<MailAccount> _manyAccounts(int count) {
  const List<Color> accents = <Color>[
    Color(0xFF2DD4BF),
    Color(0xFFA78BFA),
    Color(0xFF60A5FA),
    Color(0xFFF472B6),
  ];
  return List<MailAccount>.generate(count, (int i) {
    return MailAccount(
      id: 'acc-$i',
      label: 'Account $i',
      address: 'user$i@example.com',
      accent: accents[i % accents.length],
    );
  });
}

void main() {
  testWidgets(
    'AccountRail scrolls accounts without RenderFlex overflow at short height',
    (WidgetTester tester) async {
      FlutterErrorDetails? overflowError;
      final void Function(FlutterErrorDetails)? previousOnError =
          FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        final String message = details.exceptionAsString();
        if (message.contains('overflowed') ||
            message.contains('A RenderFlex overflowed')) {
          overflowError = details;
        }
        previousOnError?.call(details);
      };
      addTearDown(() {
        FlutterError.onError = previousOnError;
      });

      // Fixed chrome ≈ 160px; eight 48px tiles need ~448px — force scroll.
      const double shortHeight = 280;
      await tester.pumpWidget(
        _themeWrap(
          Scaffold(
            body: SizedBox(
              width: 88,
              height: shortHeight,
              child: AccountRail(
                accounts: _manyAccounts(8),
                unified: true,
                accountId: null,
                onSelectUnified: () {},
                onSelectAccount: (_) {},
                onCompose: () {},
                onAddAccount: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        overflowError,
        isNull,
        reason: overflowError?.exceptionAsString(),
      );
      expect(find.byType(ListView), findsOneWidget);
      expect(find.text('Account 0'), findsOneWidget);
      expect(find.byIcon(Icons.person_add_alt_1), findsOneWidget);
      expect(find.text('+'), findsOneWidget);
    },
  );
}
