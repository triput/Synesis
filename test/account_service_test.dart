import 'package:bytemail/account/account_service.dart';
import 'package:bytemail/auth/oauth_identity_manager.dart';
import 'package:bytemail/auth/secure_credential_store.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/widgets/widget_snapshot_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCredentialStore extends SecureCredentialStore {
  _FakeCredentialStore() : super();

  final List<String> deletedRefs = <String>[];
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
  Future<void> deleteCredentials(String credentialsRef) async {
    deletedRefs.add(credentialsRef);
    secrets.remove(credentialsRef);
  }
}

class _FakeIdentityManager extends OAuthIdentityManager {
  _FakeIdentityManager(this._store) : super(_store);

  final _FakeCredentialStore _store;
  final List<String> savedRefs = <String>[];
  final List<String> savedGoogleRefs = <String>[];

  @override
  Future<void> saveGraphToken(
    String credentialsRef,
    String accessToken, [
    String? refreshToken,
    DateTime? expiresAt,
  ]) async {
    savedRefs.add(credentialsRef);
    await _store.writeSecret(
      credentialsRef: credentialsRef,
      name: 'graph.access-token',
      value: accessToken,
    );
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _store.writeSecret(
        credentialsRef: credentialsRef,
        name: 'graph.refresh-token',
        value: refreshToken,
      );
    }
    if (expiresAt != null) {
      await _store.writeSecret(
        credentialsRef: credentialsRef,
        name: 'graph.access-token-expires-at',
        value: expiresAt.toUtc().millisecondsSinceEpoch.toString(),
      );
    }
  }

  @override
  Future<void> saveGoogleToken(
    String credentialsRef,
    String accessToken, [
    String? refreshToken,
    DateTime? expiresAt,
  ]) async {
    savedGoogleRefs.add(credentialsRef);
    await _store.writeSecret(
      credentialsRef: credentialsRef,
      name: 'google.access-token',
      value: accessToken,
    );
    if (refreshToken != null && refreshToken.trim().isNotEmpty) {
      await _store.writeSecret(
        credentialsRef: credentialsRef,
        name: 'google.refresh-token',
        value: refreshToken,
      );
    }
    if (expiresAt != null) {
      await _store.writeSecret(
        credentialsRef: credentialsRef,
        name: 'google.access-token-expires-at',
        value: expiresAt.toUtc().millisecondsSinceEpoch.toString(),
      );
    }
  }
}

class _FakeRepository implements MailRepository {
  final List<MailAccount> accounts;
  final List<String> wipedAccountIds = <String>[];
  final List<String> bootstrapAccountIds = <String>[];
  int listMessagesCalls = 0;

  _FakeRepository(this.accounts);

  @override
  Future<List<MailAccount>> listAccounts() async => accounts;

  @override
  Future<void> wipeAccount(String accountId) async {
    wipedAccountIds.add(accountId);
    accounts.removeWhere((MailAccount account) => account.id == accountId);
  }

  @override
  Future<void> upsertAccount(
    MailAccount account, {
    required String providerType,
    bool focusEnabled = true,
  }) async {
    accounts.removeWhere((MailAccount existing) => existing.id == account.id);
    accounts.add(account);
  }

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {
    if (type == 'bootstrap') {
      bootstrapAccountIds.add(accountId);
    }
  }

  @override
  Future<List<MailMessage>> listMessages(MessageQuery query) async {
    listMessagesCalls += 1;
    return const <MailMessage>[];
  }

  @override
  Future<void> upsertWidgetSnapshot(
    String id,
    String kind,
    String payloadJson,
  ) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('AccountService.removeAccount', () {
    test('rejects incorrect confirmation phrase', () async {
      final _FakeRepository repo = _FakeRepository(<MailAccount>[
        const MailAccount(
          id: 'acct-1',
          label: 'A',
          address: 'a@byte.io',
          accent: Color(0xFF2563EB),
          credentialsRef: 'imap:acct-1',
        ),
      ]);
      final _FakeCredentialStore store = _FakeCredentialStore();
      final AccountService service = AccountService(
        repo,
        store,
        _FakeIdentityManager(store),
      );

      expect(
        () => service.removeAccount(
          accountId: 'acct-1',
          confirmation: 'WIPE wrong',
        ),
        throwsArgumentError,
      );
      expect(repo.wipedAccountIds, isEmpty);
      expect(store.deletedRefs, isEmpty);
    });

    test(
      'wipes demo account without credentialsRef and skips credential delete',
      () async {
        final _FakeRepository repo = _FakeRepository(<MailAccount>[
          const MailAccount(
            id: 'work',
            label: 'W',
            address: 'work@byte.io',
            accent: Color(0xFF2563EB),
          ),
        ]);
        final _FakeCredentialStore store = _FakeCredentialStore();
        final AccountService service = AccountService(
          repo,
          store,
          _FakeIdentityManager(store),
        );

        await service.removeAccount(
          accountId: 'work',
          confirmation: 'WIPE work',
        );

        expect(repo.wipedAccountIds, <String>['work']);
        expect(store.deletedRefs, isEmpty);
      },
    );

    test('wipes repository and deletes credentials on success', () async {
      final _FakeRepository repo = _FakeRepository(<MailAccount>[
        const MailAccount(
          id: 'acct-1',
          label: 'A',
          address: 'a@byte.io',
          accent: Color(0xFF2563EB),
          credentialsRef: 'imap:acct-1',
        ),
      ]);
      final _FakeCredentialStore store = _FakeCredentialStore();
      final AccountService service = AccountService(
        repo,
        store,
        _FakeIdentityManager(store),
      );

      await service.removeAccount(
        accountId: 'acct-1',
        confirmation: 'WIPE acct-1',
      );

      expect(repo.wipedAccountIds, <String>['acct-1']);
      expect(store.deletedRefs, <String>['imap:acct-1']);
      expect(repo.accounts, isEmpty);
    });

    test(
      'refreshes widget snapshots after wipe when service is provided',
      () async {
        final _FakeRepository repo = _FakeRepository(<MailAccount>[
          const MailAccount(
            id: 'acct-1',
            label: 'A',
            address: 'a@byte.io',
            accent: Color(0xFF2563EB),
            credentialsRef: 'imap:acct-1',
          ),
        ]);
        final _FakeCredentialStore store = _FakeCredentialStore();
        final WidgetSnapshotService widgets = WidgetSnapshotService(repo);
        final AccountService service = AccountService(
          repo,
          store,
          _FakeIdentityManager(store),
          widgetSnapshots: widgets,
        );

        await service.removeAccount(
          accountId: 'acct-1',
          confirmation: 'WIPE acct-1',
        );

        expect(repo.wipedAccountIds, <String>['acct-1']);
        expect(repo.listMessagesCalls, greaterThanOrEqualTo(1));
      },
    );
  });

  group('AccountService.updateAccountMetadata', () {
    test('persists label and accent without clearing v5 settings', () async {
      final _FakeRepository repo = _FakeRepository(<MailAccount>[
        const MailAccount(
          id: 'acct-1',
          label: 'A',
          address: 'a@byte.io',
          accent: Color(0xFF2563EB),
          providerType: 'graph',
          syncProfileId: 'profile-1',
          retentionDaysOverride: 30,
        ),
      ]);
      final _FakeCredentialStore store = _FakeCredentialStore();
      final AccountService service = AccountService(
        repo,
        store,
        _FakeIdentityManager(store),
      );

      final MailAccount updated = await service.updateAccountMetadata(
        account: repo.accounts.first,
        label: 'Work',
        accent: const Color(0xFF0F766E),
      );

      expect(updated.label, 'Work');
      expect(updated.accent, const Color(0xFF0F766E));
      expect(updated.syncProfileId, 'profile-1');
      expect(updated.retentionDaysOverride, 30);
      expect(repo.accounts.single.label, 'Work');
    });

    test('rejects empty label', () async {
      final _FakeRepository repo = _FakeRepository(<MailAccount>[
        const MailAccount(
          id: 'acct-1',
          label: 'A',
          address: 'a@byte.io',
          accent: Color(0xFF2563EB),
        ),
      ]);
      final _FakeCredentialStore store = _FakeCredentialStore();
      final AccountService service = AccountService(
        repo,
        store,
        _FakeIdentityManager(store),
      );

      expect(
        () => service.updateAccountMetadata(
          account: repo.accounts.first,
          label: '   ',
          accent: const Color(0xFF2563EB),
        ),
        throwsArgumentError,
      );
    });
  });

  group('AccountService.addGoogleImapAccount', () {
    test(
      'stores Gmail hosts, xoauth2 auth, google tokens, and bootstrap',
      () async {
        final _FakeRepository repo = _FakeRepository(<MailAccount>[]);
        final _FakeCredentialStore store = _FakeCredentialStore();
        final _FakeIdentityManager identity = _FakeIdentityManager(store);
        final AccountService service = AccountService(repo, store, identity);
        final DateTime expiresAt = DateTime.utc(2026, 7, 16, 18);

        final MailAccount account = await service.addGoogleImapAccount(
          id: 'g1',
          label: 'G',
          address: 'casey@gmail.com',
          accent: const Color(0xFFEA4335),
          accessToken: 'google-access',
          refreshToken: 'google-refresh',
          expiresAt: expiresAt,
        );

        expect(account.providerType, 'imap');
        expect(account.credentialsRef, 'google:g1');
        expect(account.address, 'casey@gmail.com');
        expect(identity.savedGoogleRefs, <String>['google:g1']);
        expect(repo.bootstrapAccountIds, <String>['g1']);
        expect(repo.accounts.single.providerType, 'imap');

        final Map<String, String> secrets = store.secrets['google:g1']!;
        expect(secrets['imap.host'], 'imap.gmail.com');
        expect(secrets['imap.port'], '993');
        expect(secrets['imap.user'], 'casey@gmail.com');
        expect(secrets['imap.auth'], 'xoauth2');
        expect(secrets['smtp.host'], 'smtp.gmail.com');
        expect(secrets['smtp.port'], '465');
        expect(secrets.containsKey('imap.password'), isFalse);
        expect(secrets['google.access-token'], 'google-access');
        expect(secrets['google.refresh-token'], 'google-refresh');
        expect(
          secrets['google.access-token-expires-at'],
          expiresAt.millisecondsSinceEpoch.toString(),
        );
      },
    );

    test('rejects empty access token', () async {
      final _FakeRepository repo = _FakeRepository(<MailAccount>[]);
      final _FakeCredentialStore store = _FakeCredentialStore();
      final AccountService service = AccountService(
        repo,
        store,
        _FakeIdentityManager(store),
      );

      expect(
        () => service.addGoogleImapAccount(
          id: 'g1',
          label: 'G',
          address: 'casey@gmail.com',
          accent: const Color(0xFFEA4335),
          accessToken: '   ',
        ),
        throwsArgumentError,
      );
      expect(repo.accounts, isEmpty);
      expect(repo.bootstrapAccountIds, isEmpty);
    });
  });

  group('AccountService.updateGraphCredentials', () {
    test('saves token and enqueues bootstrap', () async {
      final _FakeRepository repo = _FakeRepository(<MailAccount>[
        const MailAccount(
          id: 'acct-1',
          label: 'A',
          address: 'a@byte.io',
          accent: Color(0xFF2563EB),
          providerType: 'graph',
          credentialsRef: 'graph:acct-1',
        ),
      ]);
      final _FakeCredentialStore store = _FakeCredentialStore();
      final _FakeIdentityManager identity = _FakeIdentityManager(store);
      final AccountService service = AccountService(repo, store, identity);

      await service.updateGraphCredentials(
        account: repo.accounts.first,
        accessToken: 'token-123',
      );

      expect(identity.savedRefs, <String>['graph:acct-1']);
      expect(repo.bootstrapAccountIds, <String>['acct-1']);
    });

    test('rejects empty access token', () async {
      final _FakeRepository repo = _FakeRepository(<MailAccount>[
        const MailAccount(
          id: 'acct-1',
          label: 'A',
          address: 'a@byte.io',
          accent: Color(0xFF2563EB),
          providerType: 'graph',
          credentialsRef: 'graph:acct-1',
        ),
      ]);
      final _FakeCredentialStore store = _FakeCredentialStore();
      final AccountService service = AccountService(
        repo,
        store,
        _FakeIdentityManager(store),
      );

      expect(
        () => service.updateGraphCredentials(
          account: repo.accounts.first,
          accessToken: '   ',
        ),
        throwsArgumentError,
      );
      expect(repo.bootstrapAccountIds, isEmpty);
    });
  });

  group('AccountService.updateImapCredentials', () {
    test('switches an XOAUTH2 account to password authentication', () async {
      final _FakeRepository repo = _FakeRepository(<MailAccount>[
        const MailAccount(
          id: 'g1',
          label: 'G',
          address: 'casey@gmail.com',
          accent: Color(0xFFEA4335),
          providerType: 'imap',
          credentialsRef: 'google:g1',
        ),
      ]);
      final _FakeCredentialStore store = _FakeCredentialStore();
      store.secrets['google:g1'] = <String, String>{'imap.auth': 'xoauth2'};
      final AccountService service = AccountService(
        repo,
        store,
        _FakeIdentityManager(store),
      );

      await service.updateImapCredentials(
        account: repo.accounts.first,
        password: 'app-password',
      );

      expect(store.secrets['google:g1']?['imap.password'], 'app-password');
      expect(store.secrets['google:g1']?['imap.auth'], 'password');
      expect(repo.bootstrapAccountIds, <String>['g1']);
    });
  });
}
