import 'package:bytemail/desktop/detached_message_window_controller.dart';
import 'package:bytemail/domain/address_match_scope.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/shell/reading_pane.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

MailMessage _message({
  bool unread = true,
  bool starred = false,
  bool pinned = false,
}) {
  return MailMessage(
    id: 'm1',
    accountId: 'acc',
    fromName: 'Ada',
    fromAddress: 'ada@byte.io',
    subject: 'Hello',
    snippet: 'Body preview',
    body: 'Full body',
    whenLabel: '10:00',
    bucket: FocusBucket.focused,
    unread: unread,
    starred: starred,
    pinned: pinned,
  );
}

Widget _harness({
  required double width,
  required MailMessage message,
  VoidCallback? onReply,
  VoidCallback? onDelete,
  VoidCallback? onShowHeaders,
  VoidCallback? onMove,
  VoidCallback? onPin,
  VoidCallback? onSnooze,
  ValueChanged<AddressMatchScope>? onMarkFocused,
}) {
  final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      extensions: <ThemeExtension<dynamic>>[tokens],
    ),
    home: RepositoryProvider<DetachedMessageWindowController>(
      create: (_) => const NoopDetachedMessageWindowController(),
      child: Scaffold(
        body: Center(
          child: SizedBox(
            width: width,
            height: 640,
            child: ReadingPane(
              message: message,
              accounts: const <MailAccount>[
                MailAccount(
                  id: 'acc',
                  label: 'Work',
                  address: 'work@byte.io',
                  accent: Color(0xFF2DD4BF),
                ),
              ],
              density: ViewDensity.compact,
              onReply: onReply,
              onReplyAll: () {},
              onForward: () {},
              onArchive: () {},
              onDelete: onDelete,
              onToggleStar: () {},
              onPin: onPin,
              onSnooze: onSnooze,
              onShowHeaders: onShowHeaders,
              onMove: onMove,
              onMarkFocused: onMarkFocused,
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('ReadingPane adaptive actions', () {
    testWidgets('wide layout shows icon+label primary actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          width: 640,
          message: _message(),
          onReply: () {},
          onDelete: () {},
          onShowHeaders: () {},
          onMove: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Reply'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Delete'), findsOneWidget);
      // Wide layout keeps primary actions labeled; icon-only Reply must not
      // appear (QuickReplyBar may still mount an "Open full compose" icon).
      expect(find.byTooltip('Reply'), findsNothing);
      expect(find.byTooltip('More actions'), findsOneWidget);
    });

    testWidgets('narrow layout uses icon tooltips for primary actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          width: 360,
          message: _message(),
          onReply: () {},
          onDelete: () {},
          onShowHeaders: () {},
          onMove: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Reply'), findsNothing);
      expect(find.byTooltip('Reply'), findsOneWidget);
      expect(find.byTooltip('Delete'), findsOneWidget);
      expect(find.byTooltip('More actions'), findsOneWidget);
    });

    testWidgets('overflow menu dispatches headers and move', (
      WidgetTester tester,
    ) async {
      bool headers = false;
      bool moved = false;
      await tester.pumpWidget(
        _harness(
          width: 360,
          message: _message(),
          onReply: () {},
          onDelete: () {},
          onShowHeaders: () => headers = true,
          onMove: () => moved = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Headers').last);
      await tester.pumpAndSettle();
      expect(headers, isTrue);

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Move').last);
      await tester.pumpAndSettle();
      expect(moved, isTrue);
    });

    testWidgets('destructive delete is coral-styled and dispatches', (
      WidgetTester tester,
    ) async {
      bool deleted = false;
      await tester.pumpWidget(
        _harness(
          width: 640,
          message: _message(),
          onReply: () {},
          onDelete: () => deleted = true,
        ),
      );
      await tester.pumpAndSettle();

      final OutlinedButton deleteButton = tester.widget<OutlinedButton>(
        find.widgetWithText(OutlinedButton, 'Delete'),
      );
      final ButtonStyle? style = deleteButton.style;
      final Color? foreground = style?.foregroundColor?.resolve(
        <WidgetState>{},
      );
      expect(foreground, ThemeTokens.dark.coral);

      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete'));
      await tester.pumpAndSettle();
      expect(deleted, isTrue);
    });

    testWidgets('pin and snooze appear when callbacks are provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          width: 640,
          message: _message(),
          onReply: () {},
          onDelete: () {},
          onPin: () {},
          onSnooze: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(OutlinedButton, 'Pin'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, 'Snooze'), findsOneWidget);
    });

    testWidgets('wide layout keeps Focused address-scope control visible', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          width: 640,
          message: _message(),
          onReply: () {},
          onDelete: () {},
          onShowHeaders: () {},
          onMarkFocused: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Focused'), findsOneWidget);
      expect(find.text('Reply'), findsOneWidget);
    });

    testWidgets('overflow menu always exposes desktop message actions', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          width: 360,
          message: _message(),
          onReply: () {},
          onDelete: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();

      expect(find.text('Find in message').last, findsOneWidget);
      expect(find.text('Print').last, findsOneWidget);
      expect(find.text('Save as EML').last, findsOneWidget);
      expect(find.text('Open in new window').last, findsOneWidget);
    });
  });

  test('wide breakpoint constant is 520', () {
    expect(kReadingPaneWideBreakpoint, 520);
  });
}
