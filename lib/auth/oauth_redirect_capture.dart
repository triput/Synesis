// ==============================================================================
// File: lib/auth/oauth_redirect_capture.dart
// Description: Platform redirect capture for OAuth authorization codes.
// Component: Auth / Integration
// Version: 1.1 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-23
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
          '<p>Synesis sign-in finished.</p></body></html>';
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
      'Another Synesis sign-in may still be waiting, or the port is in use. '
      'Close other Synesis windows, wait a few seconds, and try again. '
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

/// Android deep-link listener (default Graph: `synesis://auth`).
///
/// Google Android uses reverse-client URIs such as
/// `com.googleusercontent.apps.<PREFIX>:/oauth2redirect` ([path] match,
/// empty [host]).
class AppLinksOAuthRedirectCapture implements OAuthRedirectCapture {
  AppLinksOAuthRedirectCapture({
    AppLinks? appLinks,
    this.scheme = 'synesis',
    this.host = 'auth',
    this.path,
  }) : _appLinks = appLinks ?? AppLinks();

  final AppLinks _appLinks;
  final String scheme;
  final String host;

  /// When set, match [Uri.path] (and common host-parsed variants) instead of
  /// requiring [host] alone.
  final String? path;

  bool _matchesRedirect(Uri uri) {
    if (uri.scheme != scheme) {
      return false;
    }
    final String? expectedPath = path;
    if (expectedPath == null || expectedPath.isEmpty) {
      return uri.host == host;
    }
    final String normalizedPath =
        uri.path.endsWith('/') && uri.path.length > 1
        ? uri.path.substring(0, uri.path.length - 1)
        : uri.path;
    if (normalizedPath == expectedPath) {
      return true;
    }
    // Some stacks parse `scheme:/oauth2redirect` as host=oauth2redirect.
    final String pathAsHost = expectedPath.startsWith('/')
        ? expectedPath.substring(1)
        : expectedPath;
    return uri.host == pathAsHost;
  }

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
      if (!_matchesRedirect(uri)) {
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
OAuthRedirectCapture createPlatformOAuthRedirectCapture({
  int loopbackPort = 8765,
  String loopbackPath = '/callback',
  String appLinkScheme = 'synesis',
  String appLinkHost = 'auth',
  String? appLinkPath,
}) {
  if (Platform.isAndroid) {
    return AppLinksOAuthRedirectCapture(
      scheme: appLinkScheme,
      host: appLinkHost,
      path: appLinkPath,
    );
  }
  return LoopbackOAuthRedirectCapture(port: loopbackPort, path: loopbackPath);
}

/// Google redirect capture: Android reverse-client scheme, else loopback :8766.
///
/// Pass [androidRedirectUri] from [GoogleAuthConfig.redirectUri] (ignored on
/// non-Android).
OAuthRedirectCapture createGoogleOAuthRedirectCapture({
  required String androidRedirectUri,
}) {
  if (Platform.isAndroid) {
    final Uri redirect = Uri.parse(androidRedirectUri);
    return AppLinksOAuthRedirectCapture(
      scheme: redirect.scheme,
      host: redirect.host,
      path: redirect.path.isEmpty ? '/oauth2redirect' : redirect.path,
    );
  }
  return LoopbackOAuthRedirectCapture(port: 8766, path: '/callback');
}
