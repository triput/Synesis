// ==============================================================================
// File: test/oauth_redirect_capture_test.dart
// Description: Loopback OAuth listener bind reuse and serialization coverage.
// Component: Test / Auth
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';
import 'dart:io';

import 'package:bytemail/auth/oauth_redirect_capture.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loopback capture can bind again after a cancelled wait', () async {
    final LoopbackOAuthRedirectCapture capture = LoopbackOAuthRedirectCapture(
      port: 18766,
    );

    final Future<Uri> first = capture.waitForAuthorizationRedirect(
      expectedState: 'state-a',
      timeout: const Duration(milliseconds: 80),
    );
    await expectLater(first, throwsA(isA<TimeoutException>()));

    final Future<Uri> second = capture.waitForAuthorizationRedirect(
      expectedState: 'state-b',
      timeout: const Duration(milliseconds: 80),
    );
    await expectLater(second, throwsA(isA<TimeoutException>()));
  });

  test(
    'loopback capture serializes concurrent waits on the same port',
    () async {
      final LoopbackOAuthRedirectCapture capture = LoopbackOAuthRedirectCapture(
        port: 18767,
      );

      final Future<Uri> a = capture.waitForAuthorizationRedirect(
        expectedState: 'state-a',
        timeout: const Duration(milliseconds: 120),
      );
      final Future<Uri> b = capture.waitForAuthorizationRedirect(
        expectedState: 'state-b',
        timeout: const Duration(milliseconds: 120),
      );

      final List<Object?> results =
          await Future.wait<Object?>(<Future<Object?>>[
            a.then<Object?>((_) => null).catchError((Object e) => e),
            b.then<Object?>((_) => null).catchError((Object e) => e),
          ]);

      expect(results, everyElement(isA<TimeoutException>()));
    },
  );
}
