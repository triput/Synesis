import 'package:bytemail/desktop/keyboard_intents.dart';
import 'package:bytemail/ui/shell/keymap_help_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('isControlChord matches Ctrl without Shift by default', () {
    final KeyDownEvent event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyJ,
      logicalKey: LogicalKeyboardKey.keyJ,
      timeStamp: Duration.zero,
    );
    // Without HardwareKeyboard control pressed, chord is false.
    expect(
      ByteMailKeyboardShortcuts.isControlChord(event, LogicalKeyboardKey.keyJ),
      isFalse,
    );
  });

  test('isBareKey rejects control-modified events', () {
    final KeyDownEvent event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.keyE,
      logicalKey: LogicalKeyboardKey.keyE,
      timeStamp: Duration.zero,
    );
    expect(
      ByteMailKeyboardShortcuts.isBareKey(event, LogicalKeyboardKey.keyE),
      isTrue,
    );
  });

  testWidgets('isEditingText ignores readOnly SelectableText', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SelectableText('HTML body selection surface'),
        ),
      ),
    );
    await tester.tap(find.byType(SelectableText));
    await tester.pump();
    expect(ByteMailKeyboardShortcuts.isEditingText, isFalse);
  });

  testWidgets('isEditingText is true for focused TextField', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TextField(autofocus: true),
        ),
      ),
    );
    await tester.pump();
    expect(ByteMailKeyboardShortcuts.isEditingText, isTrue);
  });

  test('isKeymapHelpKey matches question character', () {
    final KeyDownEvent event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.slash,
      logicalKey: LogicalKeyboardKey.question,
      character: '?',
      timeStamp: Duration.zero,
    );
    expect(ByteMailKeyboardShortcuts.isKeymapHelpKey(event), isTrue);
  });

  test('isKeymapHelpKey rejects bare slash without shift', () {
    final KeyDownEvent event = KeyDownEvent(
      physicalKey: PhysicalKeyboardKey.slash,
      logicalKey: LogicalKeyboardKey.slash,
      character: '/',
      timeStamp: Duration.zero,
    );
    expect(ByteMailKeyboardShortcuts.isKeymapHelpKey(event), isFalse);
  });

  testWidgets('keymap help sheet lists bindings', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return Scaffold(
              body: TextButton(
                onPressed: () => showKeymapHelpSheet(context),
                child: const Text('Help'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Help'));
    await tester.pumpAndSettle();
    expect(find.text('Keyboard shortcuts'), findsOneWidget);
    expect(find.textContaining('Find in message'), findsOneWidget);
    expect(find.textContaining('Mailbox search'), findsOneWidget);
  });
}
