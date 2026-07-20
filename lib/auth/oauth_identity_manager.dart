// ==============================================================================
// File: lib/auth/oauth_identity_manager.dart
// Description: Secure lifecycle management for Microsoft Graph and Google OAuth.
// Component: Auth / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bytemail/auth/oauth_redirect_capture.dart';
import 'package:bytemail/auth/secure_credential_store.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Opens the system browser for interactive OAuth sign-in.
typedef BrowserLauncher = Future<void> Function(Uri authorizationUrl);

/// Wall-clock source injectable for expiry tests.
typedef Clock = DateTime Function();

/// Entra application registration parameters for Microsoft Graph.
class GraphAuthConfig {
  const GraphAuthConfig({this.clientId = '', this.tenant = 'common'});

  factory GraphAuthConfig.fromEnvironment() => const GraphAuthConfig(
    clientId: String.fromEnvironment('BYTEMAIL_GRAPH_CLIENT_ID'),
    tenant: String.fromEnvironment(
      'BYTEMAIL_GRAPH_TENANT',
      defaultValue: 'common',
    ),
  );

  static const String desktopRedirectUri = 'http://127.0.0.1:8765/callback';
  static const String androidRedirectUri = 'bytemail://auth';

  static const List<String> scopes = <String>[
    'openid',
    'profile',
    'offline_access',
    'User.Read',
    'Mail.ReadWrite',
    'Mail.Send',
  ];

  final String clientId;
  final String tenant;

  /// Empty [clientId] means Entra is not configured for this build.
  bool get isConfigured => clientId.trim().isNotEmpty;

  String get redirectUri {
    if (Platform.isAndroid) {
      return androidRedirectUri;
    }
    return desktopRedirectUri;
  }

  Uri get authorizationEndpoint => Uri.parse(
    'https://login.microsoftonline.com/$tenant/oauth2/v2.0/authorize',
  );

  Uri get tokenEndpoint =>
      Uri.parse('https://login.microsoftonline.com/$tenant/oauth2/v2.0/token');
}

/// Google Cloud OAuth client parameters for Gmail IMAP/SMTP XOAUTH2.
class GoogleAuthConfig {
  const GoogleAuthConfig({this.clientId = '', this.clientSecret = ''});

  factory GoogleAuthConfig.fromEnvironment() => const GoogleAuthConfig(
    clientId: String.fromEnvironment('BYTEMAIL_GOOGLE_CLIENT_ID'),
    clientSecret: String.fromEnvironment('BYTEMAIL_GOOGLE_CLIENT_SECRET'),
  );

  static const String desktopRedirectUri = 'http://127.0.0.1:8766/callback';
  static const String androidRedirectUri = 'bytemail://google-auth';

  /// Full mail scope for classic IMAP/SMTP XOAUTH2, plus OpenID profile claims.
  static const List<String> scopes = <String>[
    'openid',
    'email',
    'profile',
    'https://mail.google.com/',
  ];

  final String clientId;
  final String clientSecret;

  /// Empty [clientId] means Google OAuth is not configured for this build.
  bool get isConfigured => clientId.trim().isNotEmpty;

  String get redirectUri {
    if (Platform.isAndroid) {
      return androidRedirectUri;
    }
    return desktopRedirectUri;
  }

  Uri get authorizationEndpoint =>
      Uri.parse('https://accounts.google.com/o/oauth2/v2/auth');

  Uri get tokenEndpoint => Uri.parse('https://oauth2.googleapis.com/token');

  Uri get userInfoEndpoint =>
      Uri.parse('https://openidconnect.googleapis.com/v1/userinfo');
}

/// Result of an interactive Microsoft Graph sign-in.
class MicrosoftSignInResult {
  const MicrosoftSignInResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.email,
    required this.displayName,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String email;
  final String displayName;
}

/// Result of an interactive Google sign-in for Gmail IMAP/SMTP.
class GoogleSignInResult {
  const GoogleSignInResult({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.email,
    required this.displayName,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String email;
  final String displayName;
}

/// Provides Graph and Google access tokens without putting secrets in SQLite.
///
/// Graph and Google flows share PKCE + browser redirect infrastructure but keep
/// distinct config, redirect URIs, secret names, and public methods.
class OAuthIdentityManager {
  OAuthIdentityManager(
    this._credentials, {
    this.config = const GraphAuthConfig(),
    this.googleConfig = const GoogleAuthConfig(),
    http.Client? httpClient,
    BrowserLauncher? launchBrowser,
    OAuthRedirectCapture? redirectCapture,
    OAuthRedirectCapture? googleRedirectCapture,
    Clock? clock,
    this._redirectTimeout = const Duration(minutes: 5),
    this._accessTokenSkew = const Duration(minutes: 2),
  }) : _httpClient = httpClient ?? http.Client(),
       _ownsHttpClient = httpClient == null,
       _launchBrowser = launchBrowser ?? _defaultLaunchBrowser,
       _redirectCapture =
           redirectCapture ?? createPlatformOAuthRedirectCapture(),
       _googleRedirectCapture =
           googleRedirectCapture ??
           createPlatformOAuthRedirectCapture(
             loopbackPort: 8766,
             appLinkHost: 'google-auth',
           ),
       _clock = clock ?? DateTime.now;

  static const String _graphAccessTokenName = 'graph.access-token';
  static const String _graphRefreshTokenName = 'graph.refresh-token';
  static const String _graphExpiresAtName = 'graph.access-token-expires-at';

  static const String _googleAccessTokenName = 'google.access-token';
  static const String _googleRefreshTokenName = 'google.refresh-token';
  static const String _googleExpiresAtName = 'google.access-token-expires-at';

  final SecureCredentialStore _credentials;
  final GraphAuthConfig config;
  final GoogleAuthConfig googleConfig;
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final BrowserLauncher _launchBrowser;
  final OAuthRedirectCapture _redirectCapture;
  final OAuthRedirectCapture _googleRedirectCapture;
  final Clock _clock;
  final Duration _redirectTimeout;
  final Duration _accessTokenSkew;
  Future<MicrosoftSignInResult>? _microsoftSignInInFlight;
  Future<GoogleSignInResult>? _googleSignInInFlight;

  Future<void> saveGraphToken(
    String credentialsRef,
    String accessToken, [
    String? refreshToken,
    DateTime? expiresAt,
  ]) async {
    if (accessToken.trim().isEmpty) {
      throw ArgumentError.value(
        accessToken,
        'accessToken',
        'Must not be empty.',
      );
    }
    await _credentials.writeSecret(
      credentialsRef: credentialsRef,
      name: _graphAccessTokenName,
      value: accessToken,
    );
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _credentials.writeSecret(
        credentialsRef: credentialsRef,
        name: _graphRefreshTokenName,
        value: refreshToken,
      );
    }
    if (expiresAt != null) {
      await _credentials.writeSecret(
        credentialsRef: credentialsRef,
        name: _graphExpiresAtName,
        value: expiresAt.toUtc().millisecondsSinceEpoch.toString(),
      );
    }
  }

  Future<void> saveGoogleToken(
    String credentialsRef,
    String accessToken, [
    String? refreshToken,
    DateTime? expiresAt,
  ]) async {
    if (accessToken.trim().isEmpty) {
      throw ArgumentError.value(
        accessToken,
        'accessToken',
        'Must not be empty.',
      );
    }
    await _credentials.writeSecret(
      credentialsRef: credentialsRef,
      name: _googleAccessTokenName,
      value: accessToken,
    );
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _credentials.writeSecret(
        credentialsRef: credentialsRef,
        name: _googleRefreshTokenName,
        value: refreshToken,
      );
    }
    if (expiresAt != null) {
      await _credentials.writeSecret(
        credentialsRef: credentialsRef,
        name: _googleExpiresAtName,
        value: expiresAt.toUtc().millisecondsSinceEpoch.toString(),
      );
    }
  }

  /// Returns the current opaque Graph access token without refresh.
  Future<String> getAccessToken(String credentialsRef) async {
    final String? token = await _credentials.readSecret(
      credentialsRef: credentialsRef,
      name: _graphAccessTokenName,
    );
    if (token == null || token.trim().isEmpty) {
      throw StateError('No Graph access token is stored for $credentialsRef.');
    }
    return token;
  }

  Future<String?> getRefreshToken(String credentialsRef) => _credentials
      .readSecret(credentialsRef: credentialsRef, name: _graphRefreshTokenName);

  Future<String?> getGoogleRefreshToken(String credentialsRef) =>
      _credentials.readSecret(
        credentialsRef: credentialsRef,
        name: _googleRefreshTokenName,
      );

  /// Returns a usable Graph access token, refreshing when expiry is within skew.
  ///
  /// When [forceRefresh] is true, always exchanges the refresh token when one
  /// is available (used after Graph returns HTTP 401).
  Future<String> getValidAccessToken(
    String credentialsRef, {
    bool forceRefresh = false,
  }) async {
    final String? storedAccessToken = await _credentials.readSecret(
      credentialsRef: credentialsRef,
      name: _graphAccessTokenName,
    );
    final String? accessToken =
        (storedAccessToken != null && storedAccessToken.trim().isNotEmpty)
        ? storedAccessToken
        : null;
    final DateTime? expiresAt = await _readExpiresAt(
      credentialsRef,
      _graphExpiresAtName,
    );
    final DateTime refreshDeadline = _clock().toUtc().add(_accessTokenSkew);
    final bool needsRefresh =
        forceRefresh ||
        accessToken == null ||
        expiresAt == null ||
        !expiresAt.isAfter(refreshDeadline);

    if (!needsRefresh) {
      return accessToken;
    }

    final String? refreshToken = await getRefreshToken(credentialsRef);
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      if (accessToken != null) {
        return accessToken;
      }
      throw StateError(
        'No Graph access or refresh token is stored for $credentialsRef.',
      );
    }

    if (!config.isConfigured) {
      if (accessToken != null) {
        return accessToken;
      }
      throw StateError(
        'Cannot refresh Graph token: BYTEMAIL_GRAPH_CLIENT_ID is not configured.',
      );
    }

    final _TokenResponse tokens = await _exchangeGraphRefreshToken(
      refreshToken,
    );
    await saveGraphToken(
      credentialsRef,
      tokens.accessToken,
      tokens.refreshToken ?? refreshToken,
      tokens.expiresAt,
    );
    return tokens.accessToken;
  }

  /// Returns a usable Google access token, refreshing when expiry is within skew.
  Future<String> getValidGoogleAccessToken(String credentialsRef) async {
    final String? storedAccessToken = await _credentials.readSecret(
      credentialsRef: credentialsRef,
      name: _googleAccessTokenName,
    );
    final String? accessToken =
        (storedAccessToken != null && storedAccessToken.trim().isNotEmpty)
        ? storedAccessToken
        : null;
    final DateTime? expiresAt = await _readExpiresAt(
      credentialsRef,
      _googleExpiresAtName,
    );
    final DateTime refreshDeadline = _clock().toUtc().add(_accessTokenSkew);
    final bool needsRefresh =
        accessToken == null ||
        expiresAt == null ||
        !expiresAt.isAfter(refreshDeadline);

    if (!needsRefresh) {
      return accessToken;
    }

    final String? refreshToken = await getGoogleRefreshToken(credentialsRef);
    if (refreshToken == null || refreshToken.trim().isEmpty) {
      if (accessToken != null) {
        return accessToken;
      }
      throw StateError(
        'No Google access or refresh token is stored for $credentialsRef.',
      );
    }

    if (!googleConfig.isConfigured) {
      if (accessToken != null) {
        return accessToken;
      }
      throw StateError(
        'Cannot refresh Google token: BYTEMAIL_GOOGLE_CLIENT_ID is not configured.',
      );
    }

    final _TokenResponse tokens = await _exchangeGoogleRefreshToken(
      refreshToken,
    );
    await saveGoogleToken(
      credentialsRef,
      tokens.accessToken,
      tokens.refreshToken ?? refreshToken,
      tokens.expiresAt,
    );
    return tokens.accessToken;
  }

  /// Interactive Microsoft Entra authorization code + PKCE sign-in.
  Future<MicrosoftSignInResult> signInMicrosoft() {
    final Future<MicrosoftSignInResult>? inFlight = _microsoftSignInInFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final Future<MicrosoftSignInResult> started = _signInMicrosoftExclusive();
    _microsoftSignInInFlight = started;
    return started.whenComplete(() {
      if (identical(_microsoftSignInInFlight, started)) {
        _microsoftSignInInFlight = null;
      }
    });
  }

  Future<MicrosoftSignInResult> _signInMicrosoftExclusive() async {
    if (!config.isConfigured) {
      throw StateError(
        'Microsoft Graph client ID is not configured. Pass '
        '--dart-define=BYTEMAIL_GRAPH_CLIENT_ID=... or use manual token entry.',
      );
    }

    final String state = _randomUrlSafe(32);
    final String codeVerifier = _randomUrlSafe(64);
    final String codeChallenge = _codeChallengeS256(codeVerifier);
    final Uri authorizeUrl = config.authorizationEndpoint.replace(
      queryParameters: <String, String>{
        'client_id': config.clientId.trim(),
        'response_type': 'code',
        'redirect_uri': config.redirectUri,
        'response_mode': 'query',
        'scope': GraphAuthConfig.scopes.join(' '),
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'prompt': 'select_account',
      },
    );

    final Future<Uri> redirectFuture = _redirectCapture
        .waitForAuthorizationRedirect(
          expectedState: state,
          timeout: _redirectTimeout,
        );
    await _launchBrowser(authorizeUrl);
    final Uri redirectUri = await redirectFuture;
    final String code = redirectUri.queryParameters['code']!;

    final _TokenResponse tokens = await _exchangeGraphAuthorizationCode(
      code: code,
      codeVerifier: codeVerifier,
    );
    final _UserProfile profile = await _fetchGraphMe(tokens.accessToken);

    return MicrosoftSignInResult(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.expiresAt,
      email: profile.email,
      displayName: profile.displayName,
    );
  }

  /// Interactive Google authorization code + PKCE sign-in for Gmail XOAUTH2.
  Future<GoogleSignInResult> signInGoogle() {
    final Future<GoogleSignInResult>? inFlight = _googleSignInInFlight;
    if (inFlight != null) {
      return inFlight;
    }
    final Future<GoogleSignInResult> started = _signInGoogleExclusive();
    _googleSignInInFlight = started;
    return started.whenComplete(() {
      if (identical(_googleSignInInFlight, started)) {
        _googleSignInInFlight = null;
      }
    });
  }

  Future<GoogleSignInResult> _signInGoogleExclusive() async {
    if (!googleConfig.isConfigured) {
      throw StateError(
        'Google client ID is not configured. Pass '
        '--dart-define=BYTEMAIL_GOOGLE_CLIENT_ID=... or use the IMAP tab '
        'with an app password.',
      );
    }

    final String state = _randomUrlSafe(32);
    final String codeVerifier = _randomUrlSafe(64);
    final String codeChallenge = _codeChallengeS256(codeVerifier);
    final Uri authorizeUrl = googleConfig.authorizationEndpoint.replace(
      queryParameters: <String, String>{
        'client_id': googleConfig.clientId.trim(),
        'response_type': 'code',
        'redirect_uri': googleConfig.redirectUri,
        'scope': GoogleAuthConfig.scopes.join(' '),
        'state': state,
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'access_type': 'offline',
        'prompt': 'consent',
      },
    );

    final Future<Uri> redirectFuture = _googleRedirectCapture
        .waitForAuthorizationRedirect(
          expectedState: state,
          timeout: _redirectTimeout,
        );
    await _launchBrowser(authorizeUrl);
    final Uri redirectUri = await redirectFuture;
    final String code = redirectUri.queryParameters['code']!;

    final _TokenResponse tokens = await _exchangeGoogleAuthorizationCode(
      code: code,
      codeVerifier: codeVerifier,
    );
    _ensureGoogleMailScope(tokens.scope);
    final _UserProfile profile = await _fetchGoogleUserInfo(tokens.accessToken);

    return GoogleSignInResult(
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: tokens.expiresAt,
      email: profile.email,
      displayName: profile.displayName,
    );
  }

  /// Gmail IMAP/SMTP XOAUTH2 requires the full-mail scope on the access token.
  static void _ensureGoogleMailScope(String? scope) {
    const String required = 'https://mail.google.com/';
    final String normalized = (scope ?? '').toLowerCase();
    if (normalized.contains(required)) {
      return;
    }
    throw StateError(
      'Google sign-in succeeded but the access token is missing '
      '$required — Gmail IMAP will fail with AUTHENTICATIONFAILED.\n\n'
      'In Google Cloud → OAuth consent screen, add the Gmail scope '
      '"$required" (and enable the Gmail API), ensure your account is a '
      'test user, then remove this account in ByteMail and Sign in with '
      'Google again (consent must be re-granted).',
    );
  }

  /// Deletes stored secrets for [credentialsRef].
  Future<void> signOut(String credentialsRef) =>
      _credentials.deleteCredentials(credentialsRef);

  /// Saves a manually obtained Graph token for local spike testing.
  ///
  /// Available only when Entra is not configured via dart-define.
  Future<void> startDeviceOrManualTokenEntry({
    required String credentialsRef,
    required String pastedAccessToken,
    String? refreshToken,
    DateTime? expiresAt,
  }) async {
    if (config.isConfigured) {
      throw StateError(
        'Interactive Entra OAuth must be completed in the system browser; '
        'manual token entry is only available before a client ID is configured.',
      );
    }
    await saveGraphToken(
      credentialsRef,
      pastedAccessToken,
      refreshToken,
      expiresAt,
    );
  }

  Future<void> dispose() async {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }

  Future<DateTime?> _readExpiresAt(
    String credentialsRef,
    String secretName,
  ) async {
    final String? raw = await _credentials.readSecret(
      credentialsRef: credentialsRef,
      name: secretName,
    );
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }
    final int? millis = int.tryParse(raw.trim());
    if (millis == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);
  }

  Future<_TokenResponse> _exchangeGraphAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) {
    return _postToken(
      endpoint: config.tokenEndpoint,
      providerLabel: 'Microsoft',
      body: <String, String>{
        'client_id': config.clientId.trim(),
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': config.redirectUri,
        'code_verifier': codeVerifier,
        'scope': GraphAuthConfig.scopes.join(' '),
      },
    );
  }

  Future<_TokenResponse> _exchangeGraphRefreshToken(String refreshToken) {
    return _postToken(
      endpoint: config.tokenEndpoint,
      providerLabel: 'Microsoft',
      body: <String, String>{
        'client_id': config.clientId.trim(),
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'scope': GraphAuthConfig.scopes.join(' '),
      },
    );
  }

  Future<_TokenResponse> _exchangeGoogleAuthorizationCode({
    required String code,
    required String codeVerifier,
  }) {
    final Map<String, String> body = <String, String>{
      'client_id': googleConfig.clientId.trim(),
      'grant_type': 'authorization_code',
      'code': code,
      'redirect_uri': googleConfig.redirectUri,
      'code_verifier': codeVerifier,
    };
    final String secret = googleConfig.clientSecret.trim();
    if (secret.isNotEmpty) {
      body['client_secret'] = secret;
    }
    return _postToken(
      endpoint: googleConfig.tokenEndpoint,
      providerLabel: 'Google',
      body: body,
    );
  }

  Future<_TokenResponse> _exchangeGoogleRefreshToken(String refreshToken) {
    final Map<String, String> body = <String, String>{
      'client_id': googleConfig.clientId.trim(),
      'grant_type': 'refresh_token',
      'refresh_token': refreshToken,
    };
    final String secret = googleConfig.clientSecret.trim();
    if (secret.isNotEmpty) {
      body['client_secret'] = secret;
    }
    return _postToken(
      endpoint: googleConfig.tokenEndpoint,
      providerLabel: 'Google',
      body: body,
    );
  }

  Future<_TokenResponse> _postToken({
    required Uri endpoint,
    required String providerLabel,
    required Map<String, String> body,
  }) async {
    final http.Response response = await _httpClient.post(
      endpoint,
      headers: const <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      },
      body: body,
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        '$providerLabel token endpoint failed (${response.statusCode}): '
        '${response.body}',
      );
    }
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<Object?, Object?>) {
      throw StateError('$providerLabel token endpoint returned invalid JSON.');
    }
    final Map<String, Object?> json = decoded.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
    final String? accessToken = json['access_token'] as String?;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('$providerLabel token response omitted access_token.');
    }
    final Object? expiresInRaw = json['expires_in'];
    final int expiresInSeconds = expiresInRaw is int
        ? expiresInRaw
        : int.tryParse(expiresInRaw?.toString() ?? '') ?? 3600;
    return _TokenResponse(
      accessToken: accessToken,
      refreshToken: json['refresh_token'] as String?,
      expiresAt: _clock().toUtc().add(Duration(seconds: expiresInSeconds)),
      scope: (json['scope'] as String?)?.trim(),
    );
  }

  Future<_UserProfile> _fetchGraphMe(String accessToken) async {
    final http.Response response = await _httpClient.get(
      Uri.parse('https://graph.microsoft.com/v1.0/me'),
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Graph /me failed (${response.statusCode}): ${response.body}',
      );
    }
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<Object?, Object?>) {
      throw StateError('Graph /me returned invalid JSON.');
    }
    final Map<String, Object?> json = decoded.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
    final String email = (json['mail'] as String?)?.trim().isNotEmpty == true
        ? (json['mail'] as String).trim()
        : (json['userPrincipalName'] as String?)?.trim() ?? '';
    if (email.isEmpty) {
      throw StateError('Graph /me did not return a mailbox address.');
    }
    final String displayName =
        (json['displayName'] as String?)?.trim().isNotEmpty == true
        ? (json['displayName'] as String).trim()
        : email;
    return _UserProfile(email: email, displayName: displayName);
  }

  Future<_UserProfile> _fetchGoogleUserInfo(String accessToken) async {
    final http.Response response = await _httpClient.get(
      googleConfig.userInfoEndpoint,
      headers: <String, String>{
        'Authorization': 'Bearer $accessToken',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError(
        'Google userinfo failed (${response.statusCode}): ${response.body}',
      );
    }
    final Object? decoded = jsonDecode(response.body);
    if (decoded is! Map<Object?, Object?>) {
      throw StateError('Google userinfo returned invalid JSON.');
    }
    final Map<String, Object?> json = decoded.map(
      (Object? key, Object? value) => MapEntry(key.toString(), value),
    );
    final String email = (json['email'] as String?)?.trim() ?? '';
    if (email.isEmpty) {
      throw StateError('Google userinfo did not return an email address.');
    }
    final String displayName =
        (json['name'] as String?)?.trim().isNotEmpty == true
        ? (json['name'] as String).trim()
        : email;
    return _UserProfile(email: email, displayName: displayName);
  }

  static Future<void> _defaultLaunchBrowser(Uri authorizationUrl) async {
    final bool launched = await launchUrl(
      authorizationUrl,
      mode: LaunchMode.externalApplication,
    );
    if (!launched) {
      throw StateError('Could not open the system browser for OAuth sign-in.');
    }
  }

  static String _randomUrlSafe(int byteLength) {
    final Random random = Random.secure();
    final List<int> bytes = List<int>.generate(
      byteLength,
      (_) => random.nextInt(256),
    );
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  static String _codeChallengeS256(String verifier) {
    final Digest digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
}

class _TokenResponse {
  const _TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    this.scope,
  });

  final String accessToken;
  final String? refreshToken;
  final DateTime expiresAt;
  final String? scope;
}

class _UserProfile {
  const _UserProfile({required this.email, required this.displayName});

  final String email;
  final String displayName;
}
