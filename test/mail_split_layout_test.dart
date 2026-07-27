// ==============================================================================
// File: test/mail_split_layout_test.dart
// Description: Widget tests for MailSplitLayout position axis and Visual Focus
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-23
// ==============================================================================

import 'package:synesis/settings/app_settings_state.dart';
import 'package:synesis/ui/shell/mail_split_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _harness({
  required ReadingPanePosition position,
  required bool visualFocusActive,
  required bool showSidebar,
  required bool forceHorizontalSplit,
  Size size = const Size(1200, 800),
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: MailSplitLayout(
            position: position,
            visualFocusActive: visualFocusActive,
            showSidebar: showSidebar,
            sidebarWidth: 200,
            listWidth: 320,
            forceHorizontalSplit: forceHorizontalSplit,
            sidebar: const ColoredBox(
              color: Colors.blue,
              child: Center(child: Text('sidebar')),
            ),
            listPane: const ColoredBox(
              color: Colors.green,
              child: Center(child: Text('list')),
            ),
            readingPane: const ColoredBox(
              color: Colors.orange,
              child: Center(child: Text('reading')),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('MailSplitLayout visibility', () {
    testWidgets('right position keeps horizontal split with sidebar + list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          position: ReadingPanePosition.right,
          visualFocusActive: false,
          showSidebar: true,
          forceHorizontalSplit: false,
        ),
      );

      expect(find.byKey(MailSplitLayoutKeys.horizontalSplit), findsOneWidget);
      expect(find.byKey(MailSplitLayoutKeys.sidebar), findsOneWidget);
      expect(find.byKey(MailSplitLayoutKeys.list), findsOneWidget);
      expect(find.byKey(MailSplitLayoutKeys.reading), findsOneWidget);
      expect(find.byKey(MailSplitLayoutKeys.visualFocus), findsNothing);
      expect(find.text('sidebar'), findsOneWidget);
      expect(find.text('list'), findsOneWidget);
      expect(find.text('reading'), findsOneWidget);
    });

    testWidgets('bottom position uses vertical split with list above reading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          position: ReadingPanePosition.bottom,
          visualFocusActive: false,
          showSidebar: true,
          forceHorizontalSplit: false,
        ),
      );

      expect(find.byKey(MailSplitLayoutKeys.verticalSplit), findsOneWidget);
      expect(find.byKey(MailSplitLayoutKeys.horizontalSplit), findsNothing);
      expect(find.byKey(MailSplitLayoutKeys.list), findsOneWidget);
      expect(find.byKey(MailSplitLayoutKeys.reading), findsOneWidget);

      final Column column = tester.widget(
        find.byKey(MailSplitLayoutKeys.verticalSplit),
      );
      expect(column.children.length, 2);
      expect(
        (column.children.first as Expanded).child.key,
        MailSplitLayoutKeys.list,
      );
      expect(
        (column.children.last as Expanded).child.key,
        MailSplitLayoutKeys.reading,
      );
    });

    testWidgets('top position uses vertical split with reading above list', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          position: ReadingPanePosition.top,
          visualFocusActive: false,
          showSidebar: false,
          forceHorizontalSplit: false,
        ),
      );

      expect(find.byKey(MailSplitLayoutKeys.verticalSplit), findsOneWidget);
      expect(find.byKey(MailSplitLayoutKeys.sidebar), findsNothing);

      final Column column = tester.widget(
        find.byKey(MailSplitLayoutKeys.verticalSplit),
      );
      expect(
        (column.children.first as Expanded).child.key,
        MailSplitLayoutKeys.reading,
      );
      expect(
        (column.children.last as Expanded).child.key,
        MailSplitLayoutKeys.list,
      );
    });

    testWidgets('Visual Focus hides sidebar and list, keeps reading', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          position: ReadingPanePosition.right,
          visualFocusActive: true,
          showSidebar: true,
          forceHorizontalSplit: false,
        ),
      );

      expect(find.byKey(MailSplitLayoutKeys.visualFocus), findsOneWidget);
      expect(find.byKey(MailSplitLayoutKeys.sidebar), findsNothing);
      expect(find.byKey(MailSplitLayoutKeys.list), findsNothing);
      expect(find.byKey(MailSplitLayoutKeys.reading), findsOneWidget);
      expect(find.text('reading'), findsOneWidget);
      expect(find.text('list'), findsNothing);
      expect(find.text('sidebar'), findsNothing);
    });

    testWidgets(
      'portrait mobile forceHorizontalSplit ignores top/bottom preference',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _harness(
            position: ReadingPanePosition.bottom,
            visualFocusActive: false,
            showSidebar: true,
            forceHorizontalSplit: true,
            size: const Size(390, 844),
          ),
        );

        expect(find.byKey(MailSplitLayoutKeys.horizontalSplit), findsOneWidget);
        expect(find.byKey(MailSplitLayoutKeys.verticalSplit), findsNothing);
        expect(find.byKey(MailSplitLayoutKeys.list), findsOneWidget);
        // List fills remaining width; reading is full-bleed via Visual Focus.
        expect(find.byKey(MailSplitLayoutKeys.reading), findsNothing);
        expect(find.text('list'), findsOneWidget);
        expect(find.text('reading'), findsNothing);
      },
    );

    testWidgets(
      'portrait mobile does not overflow with desktop listWidth',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _harness(
            position: ReadingPanePosition.right,
            visualFocusActive: false,
            showSidebar: false,
            forceHorizontalSplit: true,
            size: const Size(360, 780),
          ),
        );

        expect(tester.takeException(), isNull);
        final Size listSize = tester.getSize(
          find.byKey(MailSplitLayoutKeys.list),
        );
        expect(listSize.width, lessThanOrEqualTo(360));
      },
    );
  });

  group('isPortraitMobileLayout', () {
    testWidgets('true for phone portrait', (WidgetTester tester) async {
      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
            ),
            child: Builder(
              builder: (BuildContext context) {
                result = isPortraitMobileLayout(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(result, isTrue);
    });

    testWidgets('true when keyboard shrinks height below width', (
      WidgetTester tester,
    ) async {
      // adjustResize: 360×780 → ~360×320; Orientation would be landscape.
      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 320),
            ),
            child: Builder(
              builder: (BuildContext context) {
                result = isPortraitMobileLayout(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(result, isTrue);
    });

    testWidgets('false for wide landscape', (WidgetTester tester) async {
      late bool result;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1280, 720),
            ),
            child: Builder(
              builder: (BuildContext context) {
                result = isPortraitMobileLayout(context);
                return const SizedBox.shrink();
              },
            ),
          ),
        ),
      );
      expect(result, isFalse);
    });
  });
}
