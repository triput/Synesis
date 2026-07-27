// ==============================================================================
// File: lib/auth/oauth_public_clients.dart
// Description: Synesis-owned public OAuth client ID placeholders (filled via env).
// Component: Auth / Integration
// Version: 1.1 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-27
// ==============================================================================

/// Product defaults for Microsoft Graph + Google OAuth (public / native PKCE clients).
///
/// Real client IDs and the Google installed-app secret are **not** committed.
/// Provide them via (first wins): dart-define → OS env → `oauth_local.json`.
/// See [oauth_local.json.example](../../oauth_local.json.example).
///
/// Empty shipped defaults keep GitHub push protection happy while still allowing
/// Sign-in when local/CI config is present.
abstract final class OAuthPublicClients {
  /// Microsoft Entra Application (client) ID for Synesis (public client).
  /// Redirects: `http://127.0.0.1:8765/callback`, `synesis://auth`.
  static const String graphClientId = '';

  /// Entra tenant segment (`common`, `organizations`, `consumers`, or a GUID).
  static const String graphTenant = 'common';

  /// Google Cloud OAuth client ID (Desktop / installed app) for Synesis.
  /// Redirects: `http://127.0.0.1:8766/callback`.
  static const String googleClientId = '';

  /// Google Cloud OAuth client ID (Android) for Synesis.
  /// Package: `net.livebytes.synesis`. Redirect:
  /// `com.googleusercontent.apps.<PREFIX>:/oauth2redirect`.
  static const String googleAndroidClientId = '';

  /// Google Desktop client secret. Google treats installed-app secrets as
  /// non-confidential (still required on the token endpoint for many clients).
  /// Android clients are secretless — never send this on Android token calls.
  static const String googleClientSecret = '';
}
