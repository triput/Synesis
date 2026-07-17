// ==============================================================================
// File: lib/auth/oauth_redirect_capture.dart
// Description: Platform redirect capture for OAuth authorization codes.
// Component: Auth / Integration
// Version: 1.1 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';

/// Waits for an OAuth authorization redirect carrying `code` and `state`.
abstract class OAuthRedirectCapture {
  Future<Uri> waitForAuthorizationRedirect({
    required String expectedState,
    required Duration timeout,
  });
}

/// Desktop loopback listener (default Graph: `http://127.0.0.1:8765/callback`).
///
/// Serializes listeners per [host]/[port], binds with `shared: true`, and
/// force-closes any previous server so retrying sign-in does not hit Windows
/// "shared flag to bind()" errors when a prior attempt left the port held.
class LoopbackOAuthRedirectCapture implements OAuthRedirectCapture {
  LoopbackOAuthRedirectCapture({
    this.host = '127.0.0.1',
    this.port = 8765,
    this.path = '/callback',
  });

  final String host;
  final int port;
  final String path;

  /// One in-flight wait chain per loopback endpoint across isolates of this
  /// process (static so Graph/Google instances with the same port still serialize).
  static final Map<String, Future<void>> _endpointGates =
      <String, Future<void>>{};
  static final Map<String, HttpServer?> _activeServers =
      <String, HttpServer?>{};

  String get _endpointKey => '$host:$port';

  @override
  Future<Uri> waitForAuthorizationRedirect({
    required String expectedState,
    required Duration timeout,
  }) {
    final String key = _endpointKey;
    final Future<void> previous = _endpointGates[key] ?? Future<void>.value();
    final Completer<void> gate = Completer<void>();
    _endpointGates[key] = gate.future;

    return previous
        .catchError((Object _) {})
        .then((_) {
          return _waitExclusive(expectedState: expectedState, timeout: timeout);
        })
        .whenComplete(() {
          if (!gate.isCompleted) {
            gate.complete();
          }
          if (identical(_endpointGates[key], gate.future)) {
            _endpointGates.remove(key);
          }
        });
  }

  Future<Uri> _waitExclusive({
    required String expectedState,
    required Duration timeout,
  }) async {
    final String key = _endpointKey;
    await _closeActiveServer(key);

    final HttpServer server = await _bindWithRetry(key);
    _activeServers[key] = server;
    try {
      final HttpRequest request = await server.first.timeout(timeout);
      final Uri requestUri = request.requestedUri;
      const String html =
          '<!DOCTYPE html><html><body><h1>You can close this window</h1>'
          '<p>ByteMail sign-in finished.</p></body></html>';
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(html);
      await request.response.close();

      final String normalizedPath =
          requestUri.path.endsWith('/') && requestUri.path.length > 1
          ? requestUri.path.substring(0, requestUri.path.length - 1)
          : requestUri.path;
      if (normalizedPath != path) {
        throw StateError('Unexpected OAuth redirect path: ${requestUri.path}');
      }

      final String? state = requestUri.queryParameters['state'];
      if (state != expectedState) {
        throw StateError(
          'OAuth state mismatch; possible CSRF or stale redirect.',
        );
      }
      final String? error = requestUri.queryParameters['error'];
      if (error != null && error.isNotEmpty) {
        final String? description =
            requestUri.queryParameters['error_description'];
        throw StateError(
          description == null || description.isEmpty
              ? 'OAuth sign-in failed: $error'
              : 'OAuth sign-in failed: $error — $description',
        );
      }
      if ((requestUri.queryParameters['code'] ?? '').isEmpty) {
        throw StateError(
          'OAuth redirect did not include an authorization code.',
        );
      }
      return requestUri;
    } on TimeoutException {
      throw TimeoutException(
        'Timed out waiting for OAuth sign-in redirect.',
        timeout,
      );
    } finally {
      await _closeActiveServer(key);
    }
  }

  Future<HttpServer> _bindWithRetry(String key) async {
    Object? lastError;
    for (int attempt = 0; attempt < 4; attempt++) {
      await _closeActiveServer(key);
      if (attempt > 0) {
        await Future<void>.delayed(Duration(milliseconds: 150 * attempt));
      }
      try {
        return await HttpServer.bind(host, port, shared: true);
      } on SocketException catch (error) {
        lastError = error;
      }
    }
    throw StateError(
      'Could not open OAuth callback listener on $host:$port. '
      'Another ByteMail sign-in may still be waiting, or the port is in use. '
      'Close other ByteMail windows, wait a few seconds, and try again. '
      '($lastError)',
    );
  }

  Future<void> _closeActiveServer(String key) async {
    final HttpServer? existing = _activeServers.remove(key);
    if (existing == null) {
      return;
    }
    try {
      await existing.close(force: true);
    } on Object {
      // Best-effort; bind retry will surface a clear error if still held.
    }
  }
}

/// Android deep-link listener (default Graph: `bytemail://auth`).
class AppLinksOAuthRedirectCapture implements OAuthRedirectCapture {
  AppLinksOAuthRedirectCapture({
    AppLinks? appLinks,
    this.scheme = 'bytemail',
    this.host = 'auth',
  }) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  final String scheme;
  final String host;

  @override
  Future<Uri> waitForAuthorizationRedirect({
    required String expectedState,
    required Duration timeout,
  }) async {
    final Completer<Uri> completer = Completer<Uri>();
    StreamSubscription<Uri>? subscription;

    void handleUri(Uri uri) {
      if (completer.isCompleted) {
        return;
      }
      if (uri.scheme != scheme || uri.host != host) {
        return;
      }
      final String? state = uri.queryParameters['state'];
      if (state != expectedState) {
        return;
      }
      final String? error = uri.queryParameters['error'];
      if (error != null && error.isNotEmpty) {
        final String? description = uri.queryParameters['error_description'];
        completer.completeError(
          StateError(
            description == null || description.isEmpty
                ? 'OAuth sign-in failed: $error'
                : 'OAuth sign-in failed: $error — $description',
          ),
        );
        return;
      }
      if ((uri.queryParameters['code'] ?? '').isEmpty) {
        completer.completeError(
          StateError('OAuth redirect did not include an authorization code.'),
        );
        return;
      }
      completer.complete(uri);
    }

    subscription = _appLinks.uriLinkStream.listen(
      handleUri,
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
    );

    try {
      final Uri? initial = await _appLinks.getInitialLink();
      if (initial != null) {
        handleUri(initial);
      }
      return await completer.future.timeout(timeout);
    } on TimeoutException {
      throw TimeoutException(
        'Timed out waiting for OAuth sign-in redirect.',
        timeout,
      );
    } finally {
      await subscription.cancel();
    }
  }
}

/// Creates the platform-appropriate redirect capture.
///
/// Graph defaults: loopback port `8765`, Android host `auth`.
/// Google uses port `8766` and Android host `google-auth`.
OAuthRedirectCapture createPlatformOAuthRedirectCapture({
  int loopbackPort = 8765,
  String loopbackPath = '/callback',
  String appLinkScheme = 'bytemail',
  String appLinkHost = 'auth',
}) {
  if (Platform.isAndroid) {
    return AppLinksOAuthRedirectCapture(
      scheme: appLinkScheme,
      host: appLinkHost,
    );
  }
  return LoopbackOAuthRedirectCapture(port: loopbackPort, path: loopbackPath);
}
