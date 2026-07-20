// ==============================================================================
// File: lib/auth/oauth_public_clients.dart
// Description: ByteMail-owned public OAuth client IDs shipped with the app.
// Component: Auth / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

/// Product defaults for Microsoft Graph + Google OAuth (public / native PKCE clients).
///
/// These Application (client) IDs are **not secrets** — they identify ByteMail to
/// Entra / Google. End users never enter them; they only click Sign in.
///
/// Override order (see [OAuthConfigResolver]): dart-define → OS env →
/// `oauth_local.json` → these shipped defaults.
///
/// Google Desktop clients typically require [googleClientSecret] on the token
/// endpoint; Google documents that secret as non-confidential for installed apps.
abstract final class OAuthPublicClients {
  /// Microsoft Entra Application (client) ID for ByteMail (public client).
  /// Redirects: `http://127.0.0.1:8765/callback`, `bytemail://auth`.
  static const String graphClientId =
      '256f327c-e7ac-4996-9cb7-d08ae959f576';

  /// Entra tenant segment (`common`, `organizations`, `consumers`, or a GUID).
  static const String graphTenant = 'common';

  /// Google Cloud OAuth client ID (Desktop / installed app) for ByteMail.
  /// Redirects: `http://127.0.0.1:8766/callback`, `bytemail://google-auth`.
  static const String googleClientId =
      '516797703585-jpuio3imo76ga5c8b00el8tqc3n78ov5.apps.googleusercontent.com';

  /// Google Desktop client secret. Google treats installed-app secrets as
  /// non-confidential (still required on the token endpoint for many clients).
  static const String googleClientSecret =
      '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';
}
