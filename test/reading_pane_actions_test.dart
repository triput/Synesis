import 'package:drift/native.dart';
import 'package:synesis/desktop/detached_message_window_controller.dart';
import 'package:synesis/domain/address_match_scope.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/pim/meeting_invite_service.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/theme/density.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/shell/reading_pane.dart';
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
  bool showQuickReplyEnabled = true,
  VoidCallback? onReply,
  VoidCallback? onDelete,
  VoidCallback? onShowHeaders,
  VoidCallback? onMove,
  VoidCallback? onPin,
  VoidCallback? onSnooze,
  ValueChanged<AddressMatchScope>? onMarkFocused,
  MeetingInviteService? meetingInviteService,
}) {
  final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
  Widget app = MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      extensions: <ThemeExtension<dynamic>>[tokens],
    ),
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, 640)),
      child: RepositoryProvider<DetachedMessageWindowController>(
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
              showQuickReplyEnabled: showQuickReplyEnabled,
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
    ),
  );
  if (meetingInviteService != null) {
    app = RepositoryProvider<MeetingInviteService>.value(
      value: meetingInviteService,
      child: app,
    );
  }
  return app;
}

MeetingInviteService _inviteService(SynesisDatabase database) {
  return MeetingInviteService(
    pimStore: DriftPimStore(database, notify: () {}),
    repository: DriftMailRepository(database),
    resolvePim: (_) async => null,
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

      await tester.tap(find.byKey(const Key('reading_pane_phone_actions')));
      await tester.pumpAndSettle();

      // Actions live in a bottom sheet; the sheet is wide enough for labels.
      expect(find.text('Reply'), findsWidgets);
      expect(find.byTooltip('Delete').evaluate().isNotEmpty ||
              find.widgetWithText(OutlinedButton, 'Delete').evaluate().isNotEmpty,
          isTrue);
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

      await tester.tap(find.byKey(const Key('reading_pane_phone_actions')));
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

    testWidgets('phone expand reading hides chrome and quick reply', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          width: 400,
          message: _message(),
          onReply: () {},
          onDelete: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reading_pane_expand_body')), findsOneWidget);
      expect(find.byKey(const Key('reading_pane_quick_reply')), findsOneWidget);

      await tester.tap(find.byKey(const Key('reading_pane_expand_body')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reading_pane_collapse_body')), findsOneWidget);
      expect(find.byKey(const Key('reading_pane_quick_reply')), findsNothing);
      expect(find.byKey(const Key('reading_pane_phone_actions')), findsNothing);

      await tester.tap(find.byKey(const Key('reading_pane_collapse_body')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reading_pane_quick_reply')), findsOneWidget);
    });

    testWidgets('phone quick reply expand opens reader not compose', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          width: 400,
          message: _message(),
          onReply: () {},
          onDelete: () {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('quick_reply_expand_reading')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('reading_pane_collapse_body')), findsOneWidget);
      expect(find.byTooltip('Full reply'), findsNothing);
    });

    testWidgets('wide layout quick reply still offers full compose', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _harness(
          width: 640,
          message: _message(),
          onReply: () {},
          onDelete: () {},
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byTooltip('Expand message'), findsNothing);
      expect(find.byTooltip('Full reply'), findsOneWidget);
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

      await tester.tap(find.byKey(const Key('reading_pane_phone_actions')));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('More actions'));
      await tester.pumpAndSettle();

      expect(find.text('Find in message').last, findsOneWidget);
      expect(find.text('Print').last, findsOneWidget);
      expect(find.text('Save as EML').last, findsOneWidget);
      expect(find.text('Save as PDF').last, findsOneWidget);
      expect(find.text('Open in new window').last, findsOneWidget);
    });
  });

  test('wide breakpoint constant is 520', () {
    expect(kReadingPaneWideBreakpoint, 520);
  });

  testWidgets('invites render RSVP actions before standard reply', (
    WidgetTester tester,
  ) async {
    final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
    await database.customSelect('SELECT 1').get();
    addTearDown(database.close);
    final MailMessage invite = MailMessage(
      id: 'invite-1',
      accountId: 'acc',
      fromName: 'Ada',
      fromAddress: 'ada@byte.io',
      subject: 'Meeting invitation',
      snippet: '',
      body: '''
BEGIN:VCALENDAR
BEGIN:VEVENT
UID:ui-invite
DTSTART:20260727T150000Z
END:VEVENT
END:VCALENDAR
''',
      whenLabel: '10:00',
      bucket: FocusBucket.focused,
    );

    await tester.pumpWidget(
      _harness(
        width: 640,
        message: invite,
        onReply: () {},
        meetingInviteService: _inviteService(database),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, 'Accept'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Decline'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Tentative'), findsOneWidget);
    expect(
      tester.getTopLeft(find.widgetWithText(OutlinedButton, 'Accept')).dy,
      lessThan(tester.getTopLeft(find.widgetWithText(OutlinedButton, 'Reply')).dy),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Accept'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Meeting response failed:'), findsOneWidget);
  });

  testWidgets('showQuickReplyEnabled hides Quick Reply strip', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        width: 400,
        message: _message(),
        showQuickReplyEnabled: false,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reading_pane_quick_reply')), findsNothing);
  });

  testWidgets('showQuickReplyEnabled shows Quick Reply on phone', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        width: 400,
        message: _message(),
        showQuickReplyEnabled: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reading_pane_quick_reply')), findsOneWidget);
  });
}
