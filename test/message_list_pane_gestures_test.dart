// ==============================================================================
// File: test/message_list_pane_gestures_test.dart
// Description: Widget tests for pull-to-refresh and Android swipe dispatch
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/mailbox/message_list_projector.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/shell/message_list_pane.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MailMessage _msg(String id) {
  return MailMessage(
    id: id,
    accountId: 'acc',
    fromName: 'Ada',
    fromAddress: 'ada@byte.io',
    subject: 'Subject $id',
    snippet: 'Snippet',
    body: 'Body',
    whenLabel: '10:00',
    bucket: FocusBucket.focused,
    whenEpochMs: 1_700_000_000_000,
  );
}

Widget _harness({
  required List<MessageListSection> sections,
  required List<MailMessage> messages,
  Future<void> Function()? onRefresh,
  MessageSwipeCallback? onSwipe,
  Set<String> selectedIds = const <String>{},
  bool disableDestructiveSwipe = false,
  TargetPlatform platform = TargetPlatform.android,
}) {
  final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
  return MaterialApp(
    theme: ThemeData(
      useMaterial3: true,
      brightness: tokens.brightness,
      extensions: <ThemeExtension<dynamic>>[tokens],
    ),
    home: Scaffold(
      body: SizedBox(
        width: 420,
        height: 640,
        child: DebugDefaultTargetPlatformOverride(
          platform: platform,
          child: MessageListPane(
            sections: sections,
            messages: messages,
            accounts: const <MailAccount>[
              MailAccount(
                id: 'acc',
                label: 'Work',
                address: 'work@byte.io',
                accent: Color(0xFF2DD4BF),
              ),
            ],
            selectedId: messages.isEmpty ? null : messages.first.id,
            selectedIds: selectedIds,
            expandedThreadIds: const <String>{},
            focusEnabled: false,
            focusFilter: FocusBucket.focused,
            density: ViewDensity.compact,
            onSelect: (String id, {bool ctrl = false, bool shift = false}) {},
            onFocusFilter: (_) {},
            onRefresh: onRefresh,
            onSwipe: onSwipe,
            swipeRightAction: SwipeListAction.archive,
            swipeLeftAction: SwipeListAction.delete,
            disableDestructiveSwipe: disableDestructiveSwipe,
          ),
        ),
      ),
    ),
  );
}

/// Applies [debugDefaultTargetPlatformOverride] for a subtree via a StatefulWidget.
class DebugDefaultTargetPlatformOverride extends StatefulWidget {
  const DebugDefaultTargetPlatformOverride({
    super.key,
    required this.platform,
    required this.child,
  });

  final TargetPlatform platform;
  final Widget child;

  @override
  State<DebugDefaultTargetPlatformOverride> createState() =>
      _DebugDefaultTargetPlatformOverrideState();
}

class _DebugDefaultTargetPlatformOverrideState
    extends State<DebugDefaultTargetPlatformOverride> {
  TargetPlatform? _previous;

  @override
  void initState() {
    super.initState();
    _previous = debugDefaultTargetPlatformOverride;
    debugDefaultTargetPlatformOverride = widget.platform;
  }

  @override
  void dispose() {
    debugDefaultTargetPlatformOverride = _previous;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MailMessage m1 = _msg('m1');
  final List<MessageListSection> sections = <MessageListSection>[
    MessageListSection(
      title: 'Today',
      items: <MessageListItem>[FlatMessageItem(m1)],
    ),
  ];

  testWidgets('RefreshIndicator onRefresh is invoked', (
    WidgetTester tester,
  ) async {
    bool refreshed = false;
    await tester.pumpWidget(
      _harness(
        sections: sections,
        messages: <MailMessage>[m1],
        onRefresh: () async {
          refreshed = true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.fling(
      find.byType(RefreshIndicator),
      const Offset(0, 300),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(refreshed, isTrue);
  });

  testWidgets('Android swipe right dispatches archive', (
    WidgetTester tester,
  ) async {
    String? swipedId;
    SwipeListAction? swipedAction;
    await tester.pumpWidget(
      _harness(
        sections: sections,
        messages: <MailMessage>[m1],
        onRefresh: () async {},
        onSwipe: (String id, SwipeListAction action) {
          swipedId = id;
          swipedAction = action;
        },
      ),
    );
    await tester.pumpAndSettle();

    final Finder dismissible = find.byType(Dismissible);
    expect(dismissible, findsOneWidget);

    await tester.drag(dismissible, const Offset(320, 0));
    await tester.pumpAndSettle();

    expect(swipedId, 'm1');
    expect(swipedAction, SwipeListAction.archive);
  });

  testWidgets('swipe is disabled during multi-select', (
    WidgetTester tester,
  ) async {
    bool swiped = false;
    await tester.pumpWidget(
      _harness(
        sections: sections,
        messages: <MailMessage>[m1],
        selectedIds: <String>{'m1'},
        onRefresh: () async {},
        onSwipe: (String id, SwipeListAction action) {
          swiped = true;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Dismissible), findsNothing);
    expect(swiped, isFalse);
  });

  testWidgets('swipe is not wrapped on non-Android platforms', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _harness(
        sections: sections,
        messages: <MailMessage>[m1],
        platform: TargetPlatform.windows,
        onRefresh: () async {},
        onSwipe: (String id, SwipeListAction action) {},
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Dismissible), findsNothing);
  });
}
