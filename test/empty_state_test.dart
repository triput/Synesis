// ==============================================================================
// File: test/empty_state_test.dart
// Description: Widget coverage for shared EmptyState (UI-P8)
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/ui/common/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EmptyState renders title subtitle and CTA', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.materialThemeFor(ThemeId.dark),
        home: Scaffold(
          body: EmptyState(
            title: 'No messages',
            subtitle: 'Sync to see mail.',
            density: ViewDensity.calm,
            actionLabel: 'Sync now',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('No messages'), findsOneWidget);
    expect(find.text('Sync to see mail.'), findsOneWidget);
    await tester.tap(find.text('Sync now'));
    expect(tapped, isTrue);
  });

  testWidgets('EmptyState compact uses smaller icon metrics', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.materialThemeFor(ThemeId.dark),
        home: const Scaffold(
          body: EmptyState(
            title: 'Empty',
            density: ViewDensity.compact,
          ),
        ),
      ),
    );

    final Icon icon = tester.widget(find.byType(Icon));
    expect(icon.size, ViewDensity.compact.emptyStateIconSize);
  });
}
