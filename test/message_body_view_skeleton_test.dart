// ==============================================================================
// File: test/message_body_view_skeleton_test.dart
// Description: Wave 6P UI-P9 partial — reading-pane body-fetch skeleton.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/ui/shell/message_body_view.dart';

void main() {
  testWidgets('MessageBodyView shows skeleton blocks while body loads', (
    WidgetTester tester,
  ) async {
    final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: <ThemeExtension<dynamic>>[tokens],
        ),
        home: Scaffold(
          body: MessageBodyView(
            body: '',
            bodySize: 14,
            muted: tokens.muted,
            isLoadingBody: true,
          ),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(Container), findsWidgets);
  });
}
