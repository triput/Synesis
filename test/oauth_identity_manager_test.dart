import 'dart:async';
import 'dart:convert';

import 'package:bytemail/auth/oauth_identity_manager.dart';
import 'package:bytemail/auth/oauth_redirect_capture.dart';
import 'package:bytemail/auth/secure_credential_store.dart';
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
      expect(GoogleAuthConfig.androidRedirectUri, 'bytemail://google-auth');
      expect(GoogleAuthConfig.scopes, contains('https://mail.google.com/'));
    });
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
          expect(request.url.host, 'oauth2.googleapis.com');
          expect(request.url.path, '/token');
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
            }),
            200,
            headers: const <String, String>{'content-type': 'application/json'},
          );
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
              }),
              200,
              headers: const <String, String>{
                'content-type': 'application/json',
              },
            );
          }
          if (request.url.host == 'openidconnect.googleapis.com') {
            expect(
              request.headers['Authorization'],
              'Bearer google-access-sign-in',
            );
            return http.Response(
              jsonEncode(<String, Object?>{
                'email': 'casey@gmail.com',
                'name': 'Casey Google',
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

      final GoogleSignInResult result = await manager.signInGoogle();
      expect(result.accessToken, 'google-access-sign-in');
      expect(result.refreshToken, 'google-refresh-sign-in');
      expect(result.email, 'casey@gmail.com');
      expect(result.displayName, 'Casey Google');
      expect(launched, isNotEmpty);
      expect(launched.first.queryParameters['code_challenge_method'], 'S256');
      expect(launched.first.queryParameters['access_type'], 'offline');
      expect(
        launched.first.queryParameters['scope'],
        contains('https://mail.google.com/'),
      );
    });
  });
}
