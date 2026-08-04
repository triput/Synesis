// ==============================================================================
// File: test/reading_pane_remote_images_overflow_test.dart
// Description: Phone-size overflow guards for remote-images banner + Quick Reply
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/shell/message_attachments_panel.dart';
import 'package:synesis/ui/shell/message_body_view.dart';

MailMessage _htmlWithRemoteImage() {
  return const MailMessage(
    id: 'm-remote',
    accountId: 'acc',
    fromName: 'Alert',
    fromAddress: 'noreply@example.com',
    subject: 'Air quality',
    snippet: 'Alert body',
    body:
        '<html><body><p>Alert</p>'
        '<img src="https://cdn.example/tracker.png" alt="x"/>'
        '</body></html>',
    whenLabel: '17:17',
    bucket: FocusBucket.focused,
  );
}

class _OverflowCapture {
  _OverflowCapture() {
    _previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String message = details.exceptionAsString();
      if (message.contains('overflowed') ||
          message.contains('A RenderFlex overflowed') ||
          message.contains('OVERFLOWING')) {
        overflow ??= details;
      }
      _previous?.call(details);
    };
  }

  void Function(FlutterErrorDetails)? _previous;
  FlutterErrorDetails? overflow;

  void restore() {
    FlutterError.onError = _previous;
  }

  void expectClean(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    expect(
      overflow,
      isNull,
      reason: overflow?.exceptionAsString(),
    );
  }
}

void main() {
  testWidgets(
    'remote-images banner stacks on phone width without crushing label (DEF-069)',
    (WidgetTester tester) async {
      final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
      final _OverflowCapture capture = _OverflowCapture();
      addTearDown(capture.restore);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            brightness: tokens.brightness,
            extensions: <ThemeExtension<dynamic>>[tokens],
          ),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 640),
              viewPadding: EdgeInsets.only(bottom: 48),
              padding: EdgeInsets.zero,
            ),
            child: Scaffold(
              bottomNavigationBar: const SizedBox(
                height: 56,
                child: ColoredBox(color: Colors.black26),
              ),
              body: ColoredBox(
                color: tokens.panel,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: MessageBodyView(
                        body: _htmlWithRemoteImage().body,
                        bodySize: 14,
                        muted: tokens.muted,
                        blockRemoteImages: true,
                      ),
                    ),
                    QuickReplyBar(message: _htmlWithRemoteImage()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      capture.expectClean(tester);
      expect(find.text('Remote images blocked'), findsOneWidget);
      expect(find.text('Load images for this message'), findsOneWidget);

      final Size labelSize = tester.getSize(find.text('Remote images blocked'));
      expect(
        labelSize.width,
        greaterThan(80),
        reason: 'label must not collapse to one-letter column',
      );
      expect(
        labelSize.height,
        lessThan(40),
        reason: 'label must stay single-line height, not vertical letter stack',
      );
    },
  );
}
