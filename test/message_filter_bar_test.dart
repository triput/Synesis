import 'package:bytemail/domain/saved_message_filter.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/mailbox/message_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      extensions: <ThemeExtension<dynamic>>[tokens],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  testWidgets('toggles unread chip and clear filters', (WidgetTester tester) async {
    MessageViewFilter? filter;
    int clearCount = 0;

    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MessageFilterBar(
              filter: filter,
              onFilterChanged: (MessageViewFilter next) {
                setState(() => filter = next);
              },
              onClearFilters: () {
                setState(() {
                  filter = null;
                  clearCount += 1;
                });
              },
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();
    expect(filter?.unread, isTrue);
    expect(find.text('Clear'), findsOneWidget);

    await tester.tap(find.text('Starred'));
    await tester.pumpAndSettle();
    expect(filter?.starred, isTrue);
    expect(filter?.unread, isTrue);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();
    expect(filter, isNull);
    expect(clearCount, 1);
  });

  testWidgets('has attachment chip toggles hasAttachments', (
    WidgetTester tester,
  ) async {
    MessageViewFilter? filter;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MessageFilterBar(
              filter: filter,
              onFilterChanged: (MessageViewFilter next) {
                setState(() => filter = next);
              },
              onClearFilters: () => setState(() => filter = null),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Has attachment'));
    await tester.pumpAndSettle();
    expect(filter?.hasAttachments, isTrue);

    await tester.tap(find.text('Has attachment'));
    await tester.pumpAndSettle();
    expect(filter?.hasAttachments, isNull);
  });

  testWidgets('advanced sheet sets recipientContains', (
    WidgetTester tester,
  ) async {
    MessageViewFilter? filter;
    await tester.pumpWidget(
      _wrap(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return MessageFilterBar(
              filter: filter,
              onFilterChanged: (MessageViewFilter next) {
                setState(() => filter = next);
              },
              onClearFilters: () => setState(() => filter = null),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('More'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(1), 'carol@');
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(filter?.recipientContains, 'carol@');
    expect(find.text('Clear'), findsOneWidget);
  });

  testWidgets('shows Saved chip when callbacks provided', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        MessageFilterBar(
          filter: null,
          onFilterChanged: (_) {},
          onClearFilters: () {},
          savedFilters: const <SavedMessageFilter>[
            SavedMessageFilter(
              id: '1',
              name: 'Test',
              filter: MessageViewFilter(unread: true),
              createdAt: 1,
              updatedAt: 1,
            ),
          ],
          onApplySavedFilter: (_) {},
          onSaveCurrentFilter: (_, __) async => true,
          onRenameSavedFilter: (_, __) async {},
          onDeleteSavedFilter: (_) async {},
        ),
      ),
    );

    expect(find.text('Saved'), findsOneWidget);
  });
}
