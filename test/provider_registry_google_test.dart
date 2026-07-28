// ==============================================================================
// File: test/provider_registry_google_test.dart
// Description: ProviderRegistry resolves Google XOAUTH2 accounts with host fallbacks.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'package:synesis/auth/oauth_identity_manager.dart';
import 'package:synesis/auth/secure_credential_store.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/protocol/dav_pim_provider.dart';
import 'package:synesis/protocol/google_pim_provider.dart';
import 'package:synesis/protocol/graph_pim_provider.dart';
import 'package:synesis/protocol/imap_smtp_mail_provider.dart';
import 'package:synesis/protocol/mail_provider.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/provider_registry.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryCredentials extends SecureCredentialStore {
  _MemoryCredentials() : super();

  final Map<String, String> values = <String, String>{};

  @override
  Future<void> writeSecret({
    required String credentialsRef,
    required String name,
    required String value,
  }) async {
    values['$credentialsRef::$name'] = value;
  }

  @override
  Future<String?> readSecret({
    required String credentialsRef,
    required String name,
  }) async {
    return values['$credentialsRef::$name'];
  }
}

class _StubRepo implements MailRepository {
  _StubRepo(this.accounts);

  final List<MailAccount> accounts;

  @override
  Future<List<MailAccount>> listAccounts() async => accounts;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Identity manager that only serves Google access tokens for registry tests.
class _StubIdentity extends OAuthIdentityManager {
  _StubIdentity(SecureCredentialStore store)
    : super(
        store,
        config: const GraphAuthConfig(clientId: 'graph-test'),
        googleConfig: const GoogleAuthConfig(
          clientId: 'google-test.apps.googleusercontent.com',
        ),
      );

  @override
  Future<String> getValidGoogleAccessToken(
    String credentialsRef, {
    bool forceRefresh = false,
  }) async {
    return 'ya29.token-for-$credentialsRef';
  }
}

void main() {
  test(
    'Google ref resolves XOAUTH2 even when imap host secrets are missing',
    () async {
      final _MemoryCredentials store = _MemoryCredentials();
      final ProviderRegistry registry = ProviderRegistry(
        repository: _StubRepo(<MailAccount>[
          const MailAccount(
            id: 'acct-1',
            label: 'Gmail',
            address: 'trish@gmail.com',
            accent: Color(0xFFEA4335),
            providerType: 'imap',
            credentialsRef: 'google:acct-1',
          ),
        ]),
        credentialStore: store,
        identityManager: _StubIdentity(store),
      );

      final MailProvider? provider = await registry.resolve('acct-1');
      expect(provider, isA<ImapSmtpMailProvider>());
      final ImapSmtpMailProvider imap = provider! as ImapSmtpMailProvider;
      expect(imap.host, 'imap.gmail.com');
      expect(imap.port, 993);
      expect(imap.user, 'trish@gmail.com');
      expect(imap.smtpHost, 'smtp.gmail.com');
      expect(imap.smtpPort, 465);
      expect(imap.authMode, ImapAuthMode.xoauth2);
      expect(imap.password, 'ya29.token-for-google:acct-1');
    },
  );

  test('resolvePim returns GooglePimProvider for google: refs', () async {
    final _MemoryCredentials store = _MemoryCredentials();
    final ProviderRegistry registry = ProviderRegistry(
      repository: _StubRepo(<MailAccount>[
        const MailAccount(
          id: 'acct-1',
          label: 'Gmail',
          address: 'trish@gmail.com',
          accent: Color(0xFFEA4335),
          providerType: 'imap',
          credentialsRef: 'google:acct-1',
        ),
      ]),
      credentialStore: store,
      identityManager: _StubIdentity(store),
    );

    final GraphPimProvider? pim = await registry.resolvePim('acct-1');
    expect(pim, isA<GooglePimProvider>());
    await pim?.dispose();
  });

  test('resolvePim returns GooglePimProvider for xoauth2 auth mode', () async {
    final _MemoryCredentials store = _MemoryCredentials();
    await store.writeSecret(
      credentialsRef: 'imap:xo',
      name: 'imap.auth',
      value: 'xoauth2',
    );
    final ProviderRegistry registry = ProviderRegistry(
      repository: _StubRepo(<MailAccount>[
        const MailAccount(
          id: 'xo',
          label: 'XO',
          address: 'user@example.com',
          accent: Color(0xFFEA4335),
          providerType: 'imap',
          credentialsRef: 'imap:xo',
        ),
      ]),
      credentialStore: store,
      identityManager: _StubIdentity(store),
    );

    final GraphPimProvider? pim = await registry.resolvePim('xo');
    expect(pim, isA<GooglePimProvider>());
    expect(pim, isNot(isA<DavPimProvider>()));
    await pim?.dispose();
  });

  test(
    'recovers google:\$id when credentialsRef is missing on a Gmail account',
    () async {
      final _MemoryCredentials store = _MemoryCredentials();
      final ProviderRegistry registry = ProviderRegistry(
        repository: _StubRepo(<MailAccount>[
          const MailAccount(
            id: 'acct-2',
            label: 'Gmail',
            address: 'trish.putnam@gmail.com',
            accent: Color(0xFFEA4335),
            providerType: 'imap',
          ),
        ]),
        credentialStore: store,
        identityManager: _StubIdentity(store),
      );

      final MailProvider? provider = await registry.resolve('acct-2');
      expect(provider, isA<ImapSmtpMailProvider>());
      final ImapSmtpMailProvider imap = provider! as ImapSmtpMailProvider;
      expect(imap.user, 'trish.putnam@gmail.com');
      expect(imap.password, 'ya29.token-for-google:acct-2');
    },
  );
}
