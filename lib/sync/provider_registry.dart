// ==============================================================================
// File: lib/sync/provider_registry.dart
// Description: Resolves persisted account credentials to concrete mail providers
// Component: Sync / Integration
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/auth/oauth_identity_manager.dart';
import 'package:bytemail/auth/secure_credential_store.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/protocol/graph_mail_provider.dart';
import 'package:bytemail/protocol/imap_smtp_mail_provider.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:http/http.dart' as http;

class ProviderRegistry {
  ProviderRegistry({
    required MailRepository repository,
    required SecureCredentialStore credentialStore,
    required OAuthIdentityManager identityManager,
    http.Client? httpClient,
  }) : _repository = repository,
       _credentialStore = credentialStore,
       _identityManager = identityManager,
       _httpClient = httpClient;

  final MailRepository _repository;
  final SecureCredentialStore _credentialStore;
  final OAuthIdentityManager _identityManager;
  final http.Client? _httpClient;

  Future<MailProvider?> resolve(String accountId) async {
    final MailAccount? account = await _accountFor(accountId);
    if (account == null) {
      return null;
    }
    String? reference = account.credentialsRef?.trim();
    // Recover Google OAuth refs if the account row lost credentials_ref but
    // tokens were stored under the canonical google:$id key.
    if ((reference == null || reference.isEmpty) &&
        account.providerType == 'imap' &&
        _looksLikeGmailAddress(account.address)) {
      reference = 'google:${account.id}';
    }
    if (reference == null || reference.isEmpty) {
      return null;
    }
    final String credentialsRef = reference;

    if (account.providerType == 'graph' ||
        account.providerType == 'microsoft') {
      // Do not snapshot the token string — refresh may rotate it later.
      return GraphMailProvider(
        () => _identityManager.getValidAccessToken(credentialsRef),
        client: _httpClient,
        onUnauthorized: () async {
          await _identityManager.getValidAccessToken(
            credentialsRef,
            forceRefresh: true,
          );
        },
      );
    }

    if (account.providerType == 'imap') {
      final bool isGoogleRef = credentialsRef.startsWith('google:');
      String? host = await _credentialStore.readSecret(
        credentialsRef: credentialsRef,
        name: 'imap.host',
      );
      String? portRaw = await _credentialStore.readSecret(
        credentialsRef: credentialsRef,
        name: 'imap.port',
      );
      String? user = await _credentialStore.readSecret(
        credentialsRef: credentialsRef,
        name: 'imap.user',
      );
      final String? password = await _credentialStore.readSecret(
        credentialsRef: credentialsRef,
        name: 'imap.password',
      );
      String? smtpHost = await _credentialStore.readSecret(
        credentialsRef: credentialsRef,
        name: 'smtp.host',
      );
      String? smtpPortRaw = await _credentialStore.readSecret(
        credentialsRef: credentialsRef,
        name: 'smtp.port',
      );
      final String? authModeRaw = await _credentialStore.readSecret(
        credentialsRef: credentialsRef,
        name: 'imap.auth',
      );

      // Gmail OAuth accounts: connection endpoints are public. Prefer stored
      // secrets, but fall back so a flaky secure-storage write cannot leave the
      // account un-resolvable after a successful Sign in with Google.
      if (isGoogleRef) {
        host = _nonEmpty(host) ?? 'imap.gmail.com';
        portRaw = _nonEmpty(portRaw) ?? '993';
        user = _nonEmpty(user) ?? account.address.trim();
        smtpHost = _nonEmpty(smtpHost) ?? 'smtp.gmail.com';
        smtpPortRaw = _nonEmpty(smtpPortRaw) ?? '465';
      }

      final bool useXoauth2 =
          isGoogleRef ||
          (authModeRaw ?? '').trim().toLowerCase() == 'xoauth2';

      if (host == null ||
          user == null ||
          user.isEmpty ||
          portRaw == null ||
          smtpHost == null ||
          smtpPortRaw == null) {
        return null;
      }

      if (useXoauth2) {
        final String accessToken = await _identityManager
            .getValidGoogleAccessToken(credentialsRef);
        return ImapSmtpMailProvider(
          host: host,
          port: int.tryParse(portRaw) ?? 993,
          user: user,
          password: accessToken,
          smtpHost: smtpHost,
          smtpPort: int.tryParse(smtpPortRaw) ?? 465,
          authMode: ImapAuthMode.xoauth2,
        );
      }

      if (password == null) {
        return null;
      }
      return ImapSmtpMailProvider(
        host: host,
        port: int.tryParse(portRaw) ?? 993,
        user: user,
        password: password,
        smtpHost: smtpHost,
        smtpPort: int.tryParse(smtpPortRaw) ?? 465,
      );
    }

    return null;
  }

  Future<MailAccount?> _accountFor(String accountId) async {
    for (final MailAccount account in await _repository.listAccounts()) {
      if (account.id == accountId) {
        return account;
      }
    }
    return null;
  }

  static String? _nonEmpty(String? value) {
    if (value == null) {
      return null;
    }
    final String trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static bool _looksLikeGmailAddress(String address) {
    final String lower = address.trim().toLowerCase();
    return lower.endsWith('@gmail.com') || lower.endsWith('@googlemail.com');
  }
}
