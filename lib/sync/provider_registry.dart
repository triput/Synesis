// ==============================================================================
// File: lib/sync/provider_registry.dart
// Description: Resolves persisted account credentials to concrete mail providers
// Component: Sync / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-16
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
    final String? reference = account?.credentialsRef;
    if (account == null || reference == null || reference.isEmpty) {
      return null;
    }

    if (account.providerType == 'graph' ||
        account.providerType == 'microsoft') {
      // Do not snapshot the token string — refresh may rotate it later.
      return GraphMailProvider(
        () => _identityManager.getValidAccessToken(reference),
        client: _httpClient,
        onUnauthorized: () async {
          await _identityManager.getValidAccessToken(
            reference,
            forceRefresh: true,
          );
        },
      );
    }

    if (account.providerType == 'imap') {
      final String? host = await _credentialStore.readSecret(
        credentialsRef: reference,
        name: 'imap.host',
      );
      final String? portRaw = await _credentialStore.readSecret(
        credentialsRef: reference,
        name: 'imap.port',
      );
      final String? user = await _credentialStore.readSecret(
        credentialsRef: reference,
        name: 'imap.user',
      );
      final String? password = await _credentialStore.readSecret(
        credentialsRef: reference,
        name: 'imap.password',
      );
      final String? smtpHost = await _credentialStore.readSecret(
        credentialsRef: reference,
        name: 'smtp.host',
      );
      final String? smtpPortRaw = await _credentialStore.readSecret(
        credentialsRef: reference,
        name: 'smtp.port',
      );
      final String? authModeRaw = await _credentialStore.readSecret(
        credentialsRef: reference,
        name: 'imap.auth',
      );
      final bool useXoauth2 =
          (authModeRaw ?? '').trim().toLowerCase() == 'xoauth2' ||
          ((password == null || password.isEmpty) &&
              reference.startsWith('google:'));

      if (host == null ||
          user == null ||
          portRaw == null ||
          smtpHost == null ||
          smtpPortRaw == null) {
        return null;
      }

      if (useXoauth2) {
        final String accessToken = await _identityManager
            .getValidGoogleAccessToken(reference);
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
}
