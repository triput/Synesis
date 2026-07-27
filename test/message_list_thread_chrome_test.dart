// ==============================================================================
// File: test/message_list_thread_chrome_test.dart
// Description: DEF-041/042 thread expand badge and compact leading chrome
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/mailbox/message_list_projector.dart';
import 'package:synesis/settings/app_settings_state.dart';
import 'package:synesis/theme/density.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/shell/message_list_pane.dart';

MailMessage _msg(String id, {String? threadId}) {
  return MailMessage(
    id: id,
    accountId: 'acc',
    threadId: threadId,
    fromName: 'Ada Lovelace',
    fromAddress: 'ada@byte.io',
    subject: 'Director of Quality Engineering roles',
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
  ValueChanged<String>? onToggleThreadExpand,
  ValueChanged<String>? onToggleStar,
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
        width: 360,
        height: 640,
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
          selectedId: null,
          selectedIds: const <String>{},
          expandedThreadIds: const <String>{},
          focusEnabled: false,
          focusFilter: FocusBucket.focused,
          density: ViewDensity.compact,
          onSelect: (String id, {bool ctrl = false, bool shift = false}) {},
          onFocusFilter: (_) {},
          onToggleThreadExpand: onToggleThreadExpand,
          onToggleStar: onToggleStar,
        ),
      ),
    ),
  );
}

void main() {
  group('DEF-042 single-message thread chrome', () {
    testWidgets('hides expand control and count badge when count is 1', (
      WidgetTester tester,
    ) async {
      final MailMessage solo = _msg('m1', threadId: 't1');
      String? expandedKey;
      await tester.pumpWidget(
        _harness(
          messages: <MailMessage>[solo],
          sections: <MessageListSection>[
            MessageListSection(
              title: 'Today',
              items: <MessageListItem>[
                ThreadItem(
                  threadId: 't1',
                  latest: solo,
                  members: <MailMessage>[solo],
                  count: 1,
                  anyUnread: false,
                  anyStarred: false,
                  anyPinned: false,
                  participantSummary: solo.fromName,
                ),
              ],
            ),
          ],
          onToggleThreadExpand: (String key) => expandedKey = key,
          onToggleStar: (_) {},
        ),
      );

      expect(find.text('1'), findsNothing);
      expect(find.byTooltip('Expand thread'), findsNothing);
      expect(find.byTooltip('Collapse thread'), findsNothing);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(expandedKey, isNull);
    });

    testWidgets('keeps expand control and count for multi-message threads', (
      WidgetTester tester,
    ) async {
      final MailMessage a = _msg('m1', threadId: 't2');
      final MailMessage b = _msg('m2', threadId: 't2');
      String? expandedKey;
      await tester.pumpWidget(
        _harness(
          messages: <MailMessage>[a, b],
          sections: <MessageListSection>[
            MessageListSection(
              title: 'Today',
              items: <MessageListItem>[
                ThreadItem(
                  threadId: 't2',
                  latest: a,
                  members: <MailMessage>[a, b],
                  count: 2,
                  anyUnread: true,
                  anyStarred: false,
                  anyPinned: false,
                  participantSummary: a.fromName,
                ),
              ],
            ),
          ],
          onToggleThreadExpand: (String key) => expandedKey = key,
          onToggleStar: (_) {},
        ),
      );

      expect(find.text('2'), findsOneWidget);
      expect(find.byTooltip('Expand thread'), findsOneWidget);
      await tester.tap(find.byTooltip('Expand thread'));
      await tester.pump();
      expect(expandedKey, isNotNull);
    });
  });

  group('DEF-041 compact star chrome', () {
    testWidgets('star remains tappable on compact density', (
      WidgetTester tester,
    ) async {
      final MailMessage solo = _msg('m1');
      String? starredId;
      await tester.pumpWidget(
        _harness(
          messages: <MailMessage>[solo],
          sections: <MessageListSection>[
            MessageListSection(
              title: 'Today',
              items: <MessageListItem>[
                ThreadItem(
                  threadId: solo.id,
                  latest: solo,
                  members: <MailMessage>[solo],
                  count: 1,
                  anyUnread: false,
                  anyStarred: false,
                  anyPinned: false,
                  participantSummary: solo.fromName,
                ),
              ],
            ),
          ],
          onToggleStar: (String id) => starredId = id,
        ),
      );

      await tester.tap(find.byTooltip('Star'));
      await tester.pump();
      expect(starredId, 'm1');
    });
  });
}
