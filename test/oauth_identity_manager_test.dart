import 'dart:async';
import 'dart:convert';

import 'package:synesis/auth/oauth_identity_manager.dart';
import 'package:synesis/auth/oauth_redirect_capture.dart';
import 'package:synesis/auth/secure_credential_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _MemoryCredentialStore extends SecureCredentialStore {
  _MemoryCredentialStore() : super();

  final Map<String, Map<String, String>> secrets =
      <String, Map<String, String>>{};

  @override
  Future<void> writeSecret({
    required String credentialsRef,
    required String name,
    required String value,
  }) async {
    secrets.putIfAbsent(credentialsRef, () => <String, String>{})[name] = value;
  }

  @override
  Future<String?> readSecret({
    required String credentialsRef,
    required String name,
  }) async {
    return secrets[credentialsRef]?[name];
  }

  @override
  Future<void> deleteSecret({
    required String credentialsRef,
    required String name,
  }) async {
    secrets[credentialsRef]?.remove(name);
  }

  @override
  Future<void> deleteCredentials(String credentialsRef) async {
    secrets.remove(credentialsRef);
  }
}

class _StatefulRedirectCapture implements OAuthRedirectCapture {
  _StatefulRedirectCapture(
    this._stateFuture, {
    this.redirectBase = 'http://127.0.0.1:8765/callback',
  });

  final Future<String> _stateFuture;
  final String redirectBase;

  @override
  Future<Uri> waitForAuthorizationRedirect({
    required String expectedState,
    required Duration timeout,
  }) async {
    final String state = await _stateFuture.timeout(timeout);
    expect(state, expectedState);
    return Uri.parse('$redirectBase?code=auth-code&state=$expectedState');
  }
}

bool _isGoogleTokenInfo(http.Request request) {
  final bool oauth2Host =
      request.url.host == 'oauth2.googleapis.com' &&
      request.url.path == '/tokeninfo';
  final bool legacyHost =
      request.url.host == 'www.googleapis.com' &&
      request.url.path == '/oauth2/v3/tokeninfo';
  return request.method == 'POST' && (oauth2Host || legacyHost);
}

bool _isGoogleCalendarListPreflight(http.Request request) =>
    request.method == 'GET' &&
    request.url.host == 'www.googleapis.com' &&
    request.url.path == '/calendar/v3/users/me/calendarList';

bool _isGoogleContactGroupsPreflight(http.Request request) =>
    request.method == 'GET' &&
    request.url.host == 'people.googleapis.com' &&
    request.url.path == '/v1/contactGroups';

http.Response _googleTokenInfoResponse(String scope) {
  return http.Response(
    jsonEncode(<String, Object?>{'scope': scope}),
    200,
    headers: const <String, String>{'content-type': 'application/json'},
  );
}

http.Response _googlePimPreflightOk() {
  return http.Response(
    jsonEncode(<String, Object?>{'items': <Object?>[]}),
    200,
    headers: const <String, String>{'content-type': 'application/json'},
  );
}

/// Shared Google sign-in HTTP router for DEF-061 tests.
http.Response? _routeGoogleSignInHttp(
  http.Request request, {
  required String accessToken,
  required String scope,
  http.Response? calendarPreflight,
  http.Response? peoplePreflight,
}) {
  if (request.url.host == 'oauth2.googleapis.com' &&
      request.url.path == '/token') {
    return null; // caller handles token exchange
  }
  if (_isGoogleTokenInfo(request)) {
    expect(request.bodyFields['access_token'], accessToken);
    return _googleTokenInfoResponse(scope);
  }
  if (_isGoogleCalendarListPreflight(request)) {
    return calendarPreflight ?? _googlePimPreflightOk();
  }
  if (_isGoogleContactGroupsPreflight(request)) {
    return peoplePreflight ?? _googlePimPreflightOk();
  }
  if (request.url.host == 'openidconnect.googleapis.com') {
    return http.Response(
      jsonEncode(<String, Object?>{
        'email': 'casey@gmail.com',
        'name': 'Casey Google',
      }),
      200,
      headers: const <String, String>{'content-type': 'application/json'},
    );
  }
  return null;
}

void main() {
  group('GraphAuthConfig', () {
    test('treats empty clientId as unconfigured', () {
      const GraphAuthConfig config = GraphAuthConfig(clientId: '');
      expect(config.isConfigured, isFalse);
    });

    test('tenant defaults to common', () {
      const GraphAuthConfig config = GraphAuthConfig(clientId: 'abc');
      expect(config.tenant, 'common');
      expect(config.isConfigured, isTrue);
    });

    test('includes mail and meeting-write PIM scopes', () {
      expect(GraphAuthConfig.scopes, contains('Mail.ReadWrite'));
      expect(GraphAuthConfig.scopes, contains('Mail.Send'));
      expect(GraphAuthConfig.scopes, contains('Contacts.Read'));
      expect(GraphAuthConfig.scopes, contains('Calendars.ReadWrite'));
    });
  });

  group('GoogleAuthConfig', () {
    test('treats empty clientId as unconfigured', () {
      const GoogleAuthConfig config = GoogleAuthConfig(clientId: '');
      expect(config.isConfigured, isFalse);
    });

    test('exposes Gmail XOAUTH2 redirect and scopes', () {
      const GoogleAuthConfig config = GoogleAuthConfig(clientId: 'google-1');
      expect(config.isConfigured, isTrue);
      expect(GoogleAuthConfig.desktopRedirectUri, contains('8766'));
      expect(
        GoogleAuthConfig.androidReverseClientRedirectUri(
          '000000000000-example.apps.googleusercontent.com',
        ),
        'com.googleusercontent.apps.000000000000-example:/oauth2redirect',
      );
      expect(GoogleAuthConfig.scopes, contains('https://mail.google.com/'));
      expect(
        GoogleAuthConfig.scopes,
        contains('https://www.googleapis.com/auth/contacts.readonly'),
      );
      expect(
        GoogleAuthConfig.scopes,
        contains('https://www.googleapis.com/auth/calendar'),
      );
      expect(
        GoogleAuthConfig.requiredGrantedScopes,
        contains('https://mail.google.com/'),
      );
      expect(
        GoogleAuthConfig.requiredGrantedScopes,
        contains('https://www.googleapis.com/auth/contacts.readonly'),
      );
      expect(
        GoogleAuthConfig.requiredGrantedScopes,
        contains('https://www.googleapis.com/auth/calendar'),
      );
    });

    test('parseGrantedScopes splits space-delimited Google scope strings', () {
      expect(
        GoogleAuthConfig.parseGrantedScopes(
          'openid email https://mail.google.com/ '
          'https://www.googleapis.com/auth/calendar',
        ),
        <String>{
          'openid',
          'email',
          'https://mail.google.com/',
          'https://www.googleapis.com/auth/calendar',
        },
      );
      expect(GoogleAuthConfig.parseGrantedScopes(null), isEmpty);
      expect(GoogleAuthConfig.parseGrantedScopes('  '), isEmpty);
    });

    test(
      'missingRequiredScopes uses exact tokens (DEF-061 false-positive guard)',
      () {
        // Realistic full grant from Google token / tokeninfo responses.
        expect(
          GoogleAuthConfig.missingRequiredScopes(
            'openid email profile https://mail.google.com/ '
            'https://www.googleapis.com/auth/contacts.readonly '
            'https://www.googleapis.com/auth/calendar',
          ),
          isEmpty,
        );
        expect(
          GoogleAuthConfig.hasRequiredGrantedScopes(
            'https://mail.google.com/ '
            'https://www.googleapis.com/auth/contacts.readonly '
            'https://www.googleapis.com/auth/calendar',
          ),
          isTrue,
        );

        // calendar.readonly / calendarlist authorize calendarList.list.
        expect(
          GoogleAuthConfig.missingRequiredScopes(
            'https://mail.google.com/ '
            'https://www.googleapis.com/auth/contacts.readonly '
            'https://www.googleapis.com/auth/calendar.readonly',
          ),
          isEmpty,
        );

        // Substring trap: calendar.events must NOT satisfy calendarList.
        expect(
          GoogleAuthConfig.missingRequiredScopes(
            'https://mail.google.com/ '
            'https://www.googleapis.com/auth/contacts.readonly '
            'https://www.googleapis.com/auth/calendar.events',
          ),
          <String>['https://www.googleapis.com/auth/calendar'],
        );
        expect(
          GoogleAuthConfig.missingRequiredScopes(
            'https://mail.google.com/ '
            'https://www.googleapis.com/auth/calendar',
          ),
          <String>['https://www.googleapis.com/auth/contacts.readonly'],
        );
      },
    );
  });

  group('OAuthIdentityManager.getValidAccessToken', () {
    test('returns stored token when expiry is far enough away', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final DateTime now = DateTime.utc(2026, 7, 16, 12);
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        config: const GraphAuthConfig(clientId: 'client-1'),
        clock: () => now,
        httpClient: MockClient((http.Request request) async {
          fail('Unexpected HTTP call: ${request.url}');
        }),
      );

      await manager.saveGraphToken(
        'graph:1',
        'access-fresh',
        'refresh-1',
        now.add(const Duration(hours: 1)),
      );

      final String token = await manager.getValidAccessToken('graph:1');
      expect(token, 'access-fresh');
    });

    test('refreshes when access token is expired', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final DateTime now = DateTime.utc(2026, 7, 16, 12);
      int refreshCalls = 0;
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        config: const GraphAuthConfig(clientId: 'client-1'),
        clock: () => now,
        httpClient: MockClient((http.Request request) async {
          expect(request.url.path, contains('/oauth2/v2.0/token'));
          expect(request.bodyFields['grant_type'], 'refresh_token');
          expect(request.bodyFields['refresh_token'], 'refresh-old');
          refreshCalls += 1;
          return http.Response(
            jsonEncode(<String, Object?>{
              'access_token': 'access-new',
              'refresh_token': 'refresh-new',
              'expires_in': 3600,
              'token_type': 'Bearer',
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      await manager.saveGraphToken(
        'graph:1',
        'access-old',
        'refresh-old',
        now.subtract(const Duration(minutes: 1)),
      );

      final String token = await manager.getValidAccessToken('graph:1');
      expect(token, 'access-new');
      expect(refreshCalls, 1);
      expect(store.secrets['graph:1']?['graph.access-token'], 'access-new');
      expect(store.secrets['graph:1']?['graph.refresh-token'], 'refresh-new');
      expect(
        store.secrets['graph:1']?['graph.access-token-expires-at'],
        now
            .add(const Duration(seconds: 3600))
            .millisecondsSinceEpoch
            .toString(),
      );
    });

    test('refreshes when expiry is within two-minute skew', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final DateTime now = DateTime.utc(2026, 7, 16, 12);
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        config: const GraphAuthConfig(clientId: 'client-1'),
        clock: () => now,
        httpClient: MockClient((http.Request request) async {
          return http.Response(
            jsonEncode(<String, Object?>{
              'access_token': 'access-skew',
              'expires_in': 3600,
              'token_type': 'Bearer',
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
        }),
      );

      await manager.saveGraphToken(
        'graph:1',
        'access-almost-expired',
        'refresh-1',
        now.add(const Duration(minutes: 1)),
      );

      expect(await manager.getValidAccessToken('graph:1'), 'access-skew');
    });

    test('falls back to access token when refresh token is missing', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final DateTime now = DateTime.utc(2026, 7, 16, 12);
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        config: const GraphAuthConfig(clientId: 'client-1'),
        clock: () => now,
        httpClient: MockClient((http.Request request) async {
          fail('Should not refresh without a refresh token');
        }),
      );

      await manager.saveGraphToken(
        'graph:1',
        'access-only',
        null,
        now.subtract(const Duration(hours: 1)),
      );

      expect(await manager.getValidAccessToken('graph:1'), 'access-only');
    });

    test(
      'forceRefresh exchanges refresh token even when access is fresh',
      () async {
        final _MemoryCredentialStore store = _MemoryCredentialStore();
        final DateTime now = DateTime.utc(2026, 7, 16, 12);
        int refreshCalls = 0;
        final OAuthIdentityManager manager = OAuthIdentityManager(
          store,
          config: const GraphAuthConfig(clientId: 'client-1'),
          clock: () => now,
          httpClient: MockClient((http.Request request) async {
            refreshCalls += 1;
            return http.Response(
              jsonEncode(<String, Object?>{
                'access_token': 'access-forced',
                'expires_in': 3600,
                'token_type': 'Bearer',
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }),
        );

        await manager.saveGraphToken(
          'graph:1',
          'access-fresh',
          'refresh-1',
          now.add(const Duration(hours: 1)),
        );

        expect(
          await manager.getValidAccessToken('graph:1', forceRefresh: true),
          'access-forced',
        );
        expect(refreshCalls, 1);
      },
    );
  });

  group('OAuthIdentityManager.signInMicrosoft', () {
    test('exchanges code and loads Graph /me profile', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final List<Uri> launched = <Uri>[];
      final Completer<String> stateCompleter = Completer<String>();
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        config: const GraphAuthConfig(clientId: 'client-1'),
        launchBrowser: (Uri url) async {
          launched.add(url);
          stateCompleter.complete(url.queryParameters['state']!);
        },
        redirectCapture: _StatefulRedirectCapture(stateCompleter.future),
        httpClient: MockClient((http.Request request) async {
          if (request.url.path.contains('/oauth2/v2.0/token')) {
            expect(request.bodyFields['grant_type'], 'authorization_code');
            expect(request.bodyFields['code'], 'auth-code');
            expect(request.bodyFields['code_verifier'], isNotEmpty);
            return http.Response(
              jsonEncode(<String, Object?>{
                'access_token': 'access-sign-in',
                'refresh_token': 'refresh-sign-in',
                'expires_in': 3600,
                'token_type': 'Bearer',
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }
          if (request.url.path.endsWith('/me')) {
            expect(request.headers['Authorization'], 'Bearer access-sign-in');
            return http.Response(
              jsonEncode(<String, Object?>{
                'mail': 'user@contoso.com',
                'userPrincipalName': 'user@contoso.com',
                'displayName': 'Casey Contoso',
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }
          fail('Unexpected HTTP call: ${request.url}');
        }),
      );

      final MicrosoftSignInResult result = await manager.signInMicrosoft();
      expect(result.accessToken, 'access-sign-in');
      expect(result.refreshToken, 'refresh-sign-in');
      expect(result.email, 'user@contoso.com');
      expect(result.displayName, 'Casey Contoso');
      expect(launched, isNotEmpty);
      expect(launched.first.queryParameters['code_challenge_method'], 'S256');
      expect(
        launched.first.queryParameters['scope'],
        contains('Mail.ReadWrite'),
      );
      expect(
        launched.first.queryParameters['scope'],
        contains('Contacts.Read'),
      );
      expect(
        launched.first.queryParameters['scope'],
        contains('Calendars.ReadWrite'),
      );
    });

    test('signOut deletes credential secrets', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        config: const GraphAuthConfig(clientId: 'client-1'),
        httpClient: MockClient((_) async => http.Response('', 500)),
        redirectCapture: _StatefulRedirectCapture(
          Future<String>.value('unused'),
        ),
      );
      await manager.saveGraphToken('graph:1', 'a', 'r', DateTime.utc(2026));
      await manager.signOut('graph:1');
      expect(store.secrets.containsKey('graph:1'), isFalse);
    });
  });

  group('OAuthIdentityManager.getValidGoogleAccessToken', () {
    test('returns stored token when expiry is far enough away', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final DateTime now = DateTime.utc(2026, 7, 16, 12);
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        googleConfig: const GoogleAuthConfig(clientId: 'google-client'),
        clock: () => now,
        httpClient: MockClient((http.Request request) async {
          fail('Unexpected HTTP call: ${request.url}');
        }),
      );

      await manager.saveGoogleToken(
        'google:1',
        'google-access-fresh',
        'google-refresh-1',
        now.add(const Duration(hours: 1)),
      );

      final String token = await manager.getValidGoogleAccessToken('google:1');
      expect(token, 'google-access-fresh');
    });

    test('refreshes when access token is expired', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final DateTime now = DateTime.utc(2026, 7, 16, 12);
      int refreshCalls = 0;
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        googleConfig: const GoogleAuthConfig(
          clientId: 'google-client',
          clientSecret: 'google-secret',
        ),
        clock: () => now,
        httpClient: MockClient((http.Request request) async {
          if (request.url.path == '/token') {
            expect(request.url.host, 'oauth2.googleapis.com');
            expect(request.bodyFields['grant_type'], 'refresh_token');
            expect(request.bodyFields['refresh_token'], 'google-refresh-old');
            expect(request.bodyFields['client_secret'], 'google-secret');
            refreshCalls += 1;
            return http.Response(
              jsonEncode(<String, Object?>{
                'access_token': 'google-access-new',
                'refresh_token': 'google-refresh-new',
                'expires_in': 3600,
                'token_type': 'Bearer',
                'scope': GoogleAuthConfig.scopes.join(' '),
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }
          if (_isGoogleTokenInfo(request)) {
            return _googleTokenInfoResponse(GoogleAuthConfig.scopes.join(' '));
          }
          fail('Unexpected HTTP call: ${request.url}');
        }),
      );

      await manager.saveGoogleToken(
        'google:1',
        'google-access-old',
        'google-refresh-old',
        now.subtract(const Duration(minutes: 1)),
      );

      final String token = await manager.getValidGoogleAccessToken('google:1');
      expect(token, 'google-access-new');
      expect(refreshCalls, 1);
      expect(
        store.secrets['google:1']?['google.access-token'],
        'google-access-new',
      );
      expect(
        store.secrets['google:1']?['google.refresh-token'],
        'google-refresh-new',
      );
    });
  });

  group('OAuthIdentityManager.signInGoogle', () {
    test('exchanges code and loads Google userinfo', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final List<Uri> launched = <Uri>[];
      final Completer<String> stateCompleter = Completer<String>();
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        googleConfig: const GoogleAuthConfig(clientId: 'google-client'),
        launchBrowser: (Uri url) async {
          launched.add(url);
          stateCompleter.complete(url.queryParameters['state']!);
        },
        googleRedirectCapture: _StatefulRedirectCapture(
          stateCompleter.future,
          redirectBase: 'http://127.0.0.1:8766/callback',
        ),
        httpClient: MockClient((http.Request request) async {
          if (request.url.host == 'oauth2.googleapis.com' &&
              request.url.path == '/token') {
            expect(request.bodyFields['grant_type'], 'authorization_code');
            expect(request.bodyFields['code'], 'auth-code');
            expect(request.bodyFields['code_verifier'], isNotEmpty);
            expect(
              request.bodyFields['redirect_uri'],
              'http://127.0.0.1:8766/callback',
            );
            return http.Response(
              jsonEncode(<String, Object?>{
                'access_token': 'google-access-sign-in',
                'refresh_token': 'google-refresh-sign-in',
                'expires_in': 3600,
                'token_type': 'Bearer',
                'scope': GoogleAuthConfig.scopes.join(' '),
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }
          final http.Response? routed = _routeGoogleSignInHttp(
            request,
            accessToken: 'google-access-sign-in',
            scope: GoogleAuthConfig.scopes.join(' '),
          );
          if (routed != null) {
            return routed;
          }
          fail('Unexpected HTTP call: ${request.url}');
        }),
      );

      final GoogleSignInResult result = await manager.signInGoogle();
      expect(result.accessToken, 'google-access-sign-in');
      expect(result.refreshToken, 'google-refresh-sign-in');
      expect(result.email, 'casey@gmail.com');
      expect(result.displayName, 'Casey Google');
      expect(launched, isNotEmpty);
      expect(launched.first.queryParameters['code_challenge_method'], 'S256');
      expect(launched.first.queryParameters['access_type'], 'offline');
      expect(
        launched.first.queryParameters['include_granted_scopes'],
        'true',
      );
      expect(
        launched.first.queryParameters['prompt'],
        'select_account consent',
      );
      expect(
        launched.first.queryParameters['scope'],
        contains('https://mail.google.com/'),
      );
      expect(
        launched.first.queryParameters['scope'],
        contains('https://www.googleapis.com/auth/contacts.readonly'),
      );
      expect(
        launched.first.queryParameters['scope'],
        contains('https://www.googleapis.com/auth/calendar'),
      );
    });

    test('rejects token response missing Gmail mail scope', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final Completer<String> stateCompleter = Completer<String>();
      const String scope = 'openid email profile';
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        googleConfig: const GoogleAuthConfig(clientId: 'google-client'),
        launchBrowser: (Uri url) async {
          stateCompleter.complete(url.queryParameters['state']!);
        },
        googleRedirectCapture: _StatefulRedirectCapture(
          stateCompleter.future,
          redirectBase: 'http://127.0.0.1:8766/callback',
        ),
        httpClient: MockClient((http.Request request) async {
          if (request.url.host == 'oauth2.googleapis.com' &&
              request.url.path == '/token') {
            return http.Response(
              jsonEncode(<String, Object?>{
                'access_token': 'google-access-no-mail',
                'refresh_token': 'google-refresh-no-mail',
                'expires_in': 3600,
                'token_type': 'Bearer',
                'scope': scope,
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }
          if (_isGoogleTokenInfo(request)) {
            return _googleTokenInfoResponse(scope);
          }
          fail('Unexpected HTTP call: ${request.url}');
        }),
      );

      await expectLater(
        manager.signInGoogle(),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('https://mail.google.com/'),
          ),
        ),
      );
    });

    test('rejects token response missing Calendar scope (DEF-061)', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final Completer<String> stateCompleter = Completer<String>();
      const String scope =
          'openid email profile https://mail.google.com/ '
          'https://www.googleapis.com/auth/contacts.readonly';
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        googleConfig: const GoogleAuthConfig(clientId: 'google-client'),
        launchBrowser: (Uri url) async {
          stateCompleter.complete(url.queryParameters['state']!);
        },
        googleRedirectCapture: _StatefulRedirectCapture(
          stateCompleter.future,
          redirectBase: 'http://127.0.0.1:8766/callback',
        ),
        httpClient: MockClient((http.Request request) async {
          if (request.url.host == 'oauth2.googleapis.com' &&
              request.url.path == '/token') {
            return http.Response(
              jsonEncode(<String, Object?>{
                'access_token': 'google-access-mail-only-pim',
                'refresh_token': 'google-refresh-mail-only-pim',
                'expires_in': 3600,
                'token_type': 'Bearer',
                // Granular consent: mail granted, Calendar/People unchecked.
                'scope': scope,
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }
          if (_isGoogleTokenInfo(request)) {
            return _googleTokenInfoResponse(scope);
          }
          fail('Unexpected HTTP call: ${request.url}');
        }),
      );

      await expectLater(
        manager.signInGoogle(),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            allOf(
              contains('https://www.googleapis.com/auth/calendar'),
              contains('checkbox'),
            ),
          ),
        ),
      );
    });

    test('rejects token response missing Contacts scope (DEF-061)', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final Completer<String> stateCompleter = Completer<String>();
      const String scope =
          'openid email profile https://mail.google.com/ '
          'https://www.googleapis.com/auth/calendar';
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        googleConfig: const GoogleAuthConfig(clientId: 'google-client'),
        launchBrowser: (Uri url) async {
          stateCompleter.complete(url.queryParameters['state']!);
        },
        googleRedirectCapture: _StatefulRedirectCapture(
          stateCompleter.future,
          redirectBase: 'http://127.0.0.1:8766/callback',
        ),
        httpClient: MockClient((http.Request request) async {
          if (request.url.host == 'oauth2.googleapis.com' &&
              request.url.path == '/token') {
            return http.Response(
              jsonEncode(<String, Object?>{
                'access_token': 'google-access-no-contacts',
                'refresh_token': 'google-refresh-no-contacts',
                'expires_in': 3600,
                'token_type': 'Bearer',
                'scope': scope,
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }
          if (_isGoogleTokenInfo(request)) {
            return _googleTokenInfoResponse(scope);
          }
          fail('Unexpected HTTP call: ${request.url}');
        }),
      );

      await expectLater(
        manager.signInGoogle(),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('https://www.googleapis.com/auth/contacts.readonly'),
          ),
        ),
      );
    });

    test('rejects sign-in when Google omits refresh_token (DEF-061)', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final Completer<String> stateCompleter = Completer<String>();
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        googleConfig: const GoogleAuthConfig(clientId: 'google-client'),
        launchBrowser: (Uri url) async {
          stateCompleter.complete(url.queryParameters['state']!);
        },
        googleRedirectCapture: _StatefulRedirectCapture(
          stateCompleter.future,
          redirectBase: 'http://127.0.0.1:8766/callback',
        ),
        httpClient: MockClient((http.Request request) async {
          if (request.url.host == 'oauth2.googleapis.com' &&
              request.url.path == '/token') {
            return http.Response(
              jsonEncode(<String, Object?>{
                'access_token': 'google-access-no-rt',
                'expires_in': 3600,
                'token_type': 'Bearer',
                'scope': GoogleAuthConfig.scopes.join(' '),
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }
          fail('Unexpected HTTP call: ${request.url}');
        }),
      );

      await expectLater(
        manager.signInGoogle(),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('refresh token'),
          ),
        ),
      );
    });

    test('rejects sign-in when tokeninfo is unavailable (DEF-061)', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final Completer<String> stateCompleter = Completer<String>();
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        googleConfig: const GoogleAuthConfig(clientId: 'google-client'),
        launchBrowser: (Uri url) async {
          stateCompleter.complete(url.queryParameters['state']!);
        },
        googleRedirectCapture: _StatefulRedirectCapture(
          stateCompleter.future,
          redirectBase: 'http://127.0.0.1:8766/callback',
        ),
        httpClient: MockClient((http.Request request) async {
          if (request.url.host == 'oauth2.googleapis.com' &&
              request.url.path == '/token') {
            return http.Response(
              jsonEncode(<String, Object?>{
                'access_token': 'google-access-no-tokeninfo',
                'refresh_token': 'google-refresh-no-tokeninfo',
                'expires_in': 3600,
                'token_type': 'Bearer',
                // Token endpoint claims full scopes — must NOT be trusted alone.
                'scope': GoogleAuthConfig.scopes.join(' '),
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }
          if (_isGoogleTokenInfo(request)) {
            return http.Response('{"error":"invalid_token"}', 400);
          }
          fail('Unexpected HTTP call: ${request.url}');
        }),
      );

      await expectLater(
        manager.signInGoogle(),
        throwsA(
          isA<StateError>().having(
            (StateError e) => e.message,
            'message',
            contains('tokeninfo'),
          ),
        ),
      );
    });

    test(
      'rejects sign-in when Calendar API is disabled (DEF-061 GCP)',
      () async {
        final _MemoryCredentialStore store = _MemoryCredentialStore();
        final Completer<String> stateCompleter = Completer<String>();
        final String fullScope = GoogleAuthConfig.scopes.join(' ');
        final OAuthIdentityManager manager = OAuthIdentityManager(
          store,
          googleConfig: const GoogleAuthConfig(clientId: 'google-client'),
          launchBrowser: (Uri url) async {
            stateCompleter.complete(url.queryParameters['state']!);
          },
          googleRedirectCapture: _StatefulRedirectCapture(
            stateCompleter.future,
            redirectBase: 'http://127.0.0.1:8766/callback',
          ),
          httpClient: MockClient((http.Request request) async {
            if (request.url.host == 'oauth2.googleapis.com' &&
                request.url.path == '/token') {
              return http.Response(
                jsonEncode(<String, Object?>{
                  'access_token': 'google-access-api-disabled',
                  'refresh_token': 'google-refresh-api-disabled',
                  'expires_in': 3600,
                  'token_type': 'Bearer',
                  'scope': fullScope,
                }),
                200,
                headers: const <String, String>{
                  'content-type': 'application/json',
                },
              );
            }
            final http.Response? routed = _routeGoogleSignInHttp(
              request,
              accessToken: 'google-access-api-disabled',
              scope: fullScope,
              calendarPreflight: http.Response(
                jsonEncode(<String, Object?>{
                  'error': <String, Object?>{
                    'code': 403,
                    'message':
                        'Google Calendar API has not been used in project '
                        '123 before or it is disabled.',
                    'status': 'PERMISSION_DENIED',
                    'details': <Object?>[
                      <String, Object?>{
                        '@type': 'type.googleapis.com/google.rpc.ErrorInfo',
                        'reason': 'SERVICE_DISABLED',
                        'domain': 'googleapis.com',
                      },
                    ],
                  },
                }),
                403,
                headers: const <String, String>{
                  'content-type': 'application/json',
                },
              ),
            );
            if (routed != null) {
              return routed;
            }
            fail('Unexpected HTTP call: ${request.url}');
          }),
        );

        await expectLater(
          manager.signInGoogle(),
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              allOf(
                contains('Google Calendar API'),
                contains('SERVICE_DISABLED'),
                contains('console.cloud.google.com'),
              ),
            ),
          ),
        );
      },
    );
  });

  group('OAuthIdentityManager Google refresh scope guard (DEF-061)', () {
    test(
      'refuses to persist mail-only refresh result over expanded grant',
      () async {
        final _MemoryCredentialStore store = _MemoryCredentialStore();
        final DateTime now = DateTime.utc(2026, 7, 16, 12);
        int refreshCalls = 0;
        final OAuthIdentityManager manager = OAuthIdentityManager(
          store,
          googleConfig: const GoogleAuthConfig(
            clientId: 'google-client',
            clientSecret: 'google-secret',
          ),
          clock: () => now,
          httpClient: MockClient((http.Request request) async {
            if (request.url.path == '/token') {
              refreshCalls += 1;
              return http.Response(
                jsonEncode(<String, Object?>{
                  'access_token': 'google-access-mail-only-from-stale-rt',
                  'expires_in': 3600,
                  'token_type': 'Bearer',
                  // Stale RT predates Wave G — mints mail-only AT.
                  'scope': 'openid email profile https://mail.google.com/',
                }),
                200,
                headers: const <String, String>{
                  'content-type': 'application/json',
                },
              );
            }
            if (_isGoogleTokenInfo(request)) {
              return _googleTokenInfoResponse(
                'openid email profile https://mail.google.com/',
              );
            }
            fail('Unexpected HTTP call: ${request.url}');
          }),
        );

        await manager.saveGoogleToken(
          'google:1',
          'google-access-full-scopes',
          'google-refresh-stale-mail-only',
          now.subtract(const Duration(minutes: 1)),
        );

        await expectLater(
          manager.getValidGoogleAccessToken('google:1'),
          throwsA(
            isA<StateError>().having(
              (StateError e) => e.message,
              'message',
              allOf(
                contains('https://www.googleapis.com/auth/calendar'),
                contains('refresh token predates'),
              ),
            ),
          ),
        );
        expect(refreshCalls, 1);
        // Must not overwrite the prior access token with the narrowed grant.
        expect(
          store.secrets['google:1']?['google.access-token'],
          'google-access-full-scopes',
        );
      },
    );

    test('replaceGoogleToken clears prior refresh token first', () async {
      final _MemoryCredentialStore store = _MemoryCredentialStore();
      final OAuthIdentityManager manager = OAuthIdentityManager(
        store,
        googleConfig: const GoogleAuthConfig(clientId: 'google-client'),
      );
      await manager.saveGoogleToken(
        'google:1',
        'old-access',
        'old-refresh-mail-only',
        DateTime.utc(2026, 7, 16, 12),
      );

      await manager.replaceGoogleToken(
        'google:1',
        'new-access',
        refreshToken: 'new-refresh-full',
        expiresAt: DateTime.utc(2026, 7, 16, 13),
      );

      expect(store.secrets['google:1']?['google.access-token'], 'new-access');
      expect(
        store.secrets['google:1']?['google.refresh-token'],
        'new-refresh-full',
      );
    });
  });
}
