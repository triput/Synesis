// ==============================================================================
// File: test/html_email_fallback_test.dart
// Description: Unit tests for HTML → widget fallback when WebView fails.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/ui/shell/html_email_body.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('htmlEmailShouldUseWidgetFallback', () {
    test('detects unsupported_platform PlatformException', () {
      expect(
        htmlEmailShouldUseWidgetFallback(
          PlatformException(
            code: 'unsupported_platform',
            message: 'The platform is not supported',
          ),
        ),
        isTrue,
      );
    });

    test('detects environment_creation_failed', () {
      expect(
        htmlEmailShouldUseWidgetFallback(
          PlatformException(
            code: 'environment_creation_failed',
            message: 'WebView2 missing',
          ),
        ),
        isTrue,
      );
    });

    test('detects webview_creation_failed composition HRESULT', () {
      expect(
        htmlEmailShouldUseWidgetFallback(
          PlatformException(
            code: 'webview_creation_failed',
            message:
                'Creating the webview failed: CreateCoreWebView2CompositionController '
                'failed. (HRESULT: -0x7ff8ffa9)',
          ),
        ),
        isTrue,
      );
    });

    test('ignores unrelated errors', () {
      expect(
        htmlEmailShouldUseWidgetFallback(Exception('network down')),
        isFalse,
      );
      expect(
        htmlEmailShouldUseWidgetFallback(
          PlatformException(code: 'unknown', message: 'nope'),
        ),
        isFalse,
      );
    });
  });
}
