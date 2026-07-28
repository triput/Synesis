// ==============================================================================
// File: lib/account/account_service.dart
// Description: Account provisioning that binds repository records to credentials.
// Component: Account / Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-27
// ==============================================================================

import 'package:synesis/auth/oauth_identity_manager.dart';
import 'package:synesis/auth/secure_credential_store.dart';
import 'package:synesis/diagnostics/diagnostics_service.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/protocol/dav/dav_discovery.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/pim_sync_jobs.dart';
import 'package:synesis/widgets/widget_snapshot_service.dart';
import 'package:flutter/material.dart';


/// Creates local account records and their durable initial sync work.
class AccountService {
  AccountService(
    this._repository,
    this._credentials,
    this._identityManager, {
    WidgetSnapshotService? widgetSnapshots,
  }) : _widgetSnapshots = widgetSnapshots;

  final MailRepository _repository;
  final SecureCredentialStore _credentials;
  final OAuthIdentityManager _identityManager;
  final WidgetSnapshotService? _widgetSnapshots;

  Future<MailAccount> addGraphAccount({
    required String id,
    required String label,
    required String address,
    required Color accent,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? credentialsRef,
    bool focusEnabled = true,
  }) async {
    final String ref = credentialsRef ?? 'graph:$id';
    final MailAccount account = MailAccount(
      id: id,
      label: label,
      address: address,
      accent: accent,
      providerType: 'graph',
      focusEnabled: focusEnabled,
      credentialsRef: ref,
    );
    await _identityManager.saveGraphToken(
      ref,
      accessToken,
      refreshToken,
      expiresAt,
    );
    await _repository.upsertAccount(
      account,
      providerType: 'graph',
      focusEnabled: focusEnabled,
    );
    await _repository.enqueueSyncJob(
      accountId: id,
      type: 'bootstrap',
    );
    await _enqueuePimBootstrap(id);
    return account;
  }

  Future<MailAccount> addImapAccount({
    required String id,
    required String label,
    required String address,
    required Color accent,
    required String host,
    required int port,
    required String user,
    required String password,
    required String smtpHost,
    required int smtpPort,
    String? credentialsRef,
    String? davBaseUrl,
    bool focusEnabled = true,
  }) async {
    if (port < 1 || port > 65535 || smtpPort < 1 || smtpPort > 65535) {
      throw ArgumentError('IMAP and SMTP ports must be between 1 and 65535.');
    }
    final String ref = credentialsRef ?? 'imap:$id';
    final MailAccount account = MailAccount(
      id: id,
      label: label,
      address: address,
      accent: accent,
      providerType: 'imap',
      focusEnabled: focusEnabled,
      credentialsRef: ref,
    );
    final String? resolvedDavBaseUrl = _davBaseUrl(
      davBaseUrl,
      address: address,
      imapHost: host,
    );
    final List<Future<void>> writes = <Future<void>>[
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'imap.host',
        value: host,
      ),
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'imap.port',
        value: port.toString(),
      ),
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'imap.user',
        value: user,
      ),
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'imap.password',
        value: password,
      ),
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'smtp.host',
        value: smtpHost,
      ),
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'smtp.port',
        value: smtpPort.toString(),
      ),
    ];
    if (resolvedDavBaseUrl != null) {
      writes.add(
        _credentials.writeSecret(
          credentialsRef: ref,
          name: 'dav.baseUrl',
          value: resolvedDavBaseUrl,
        ),
      );
    }
    await Future.wait(writes);
    await _repository.upsertAccount(
      account,
      providerType: 'imap',
      focusEnabled: focusEnabled,
    );
    await _repository.enqueueSyncJob(
      accountId: id,
      type: 'bootstrap',
    );
    if (resolvedDavBaseUrl != null) {
      await _enqueueDavPimBootstrap(id);
    }
    return account;
  }

  /// Adds a Gmail IMAP/SMTP account authenticated with Google OAuth (XOAUTH2).
  ///
  /// Persists `providerType: imap` (Drift CHECK) with `credentialsRef` of the
  /// form `google:$id`, Gmail host secrets, `imap.auth=xoauth2`, and Google
  /// token secrets — not an app password.
  Future<MailAccount> addGoogleImapAccount({
    required String id,
    required String label,
    required String address,
    required Color accent,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    String? credentialsRef,
    bool focusEnabled = true,
  }) async {
    if (accessToken.trim().isEmpty) {
      throw ArgumentError.value(
        accessToken,
        'accessToken',
        'Must not be empty.',
      );
    }
    final String trimmedAddress = address.trim();
    if (trimmedAddress.isEmpty) {
      throw ArgumentError.value(address, 'address', 'Must not be empty.');
    }
    final String ref = credentialsRef ?? 'google:$id';
    final MailAccount account = MailAccount(
      id: id,
      label: label,
      address: trimmedAddress,
      accent: accent,
      providerType: 'imap',
      focusEnabled: focusEnabled,
      credentialsRef: ref,
    );
    await _identityManager.saveGoogleToken(
      ref,
      accessToken,
      refreshToken,
      expiresAt,
    );
    await Future.wait(<Future<void>>[
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'imap.host',
        value: 'imap.gmail.com',
      ),
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'imap.port',
        value: '993',
      ),
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'imap.user',
        value: trimmedAddress,
      ),
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'imap.auth',
        value: 'xoauth2',
      ),
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'smtp.host',
        value: 'smtp.gmail.com',
      ),
      _credentials.writeSecret(
        credentialsRef: ref,
        name: 'smtp.port',
        value: '465',
      ),
    ]);
    await _repository.upsertAccount(
      account,
      providerType: 'imap',
      focusEnabled: focusEnabled,
    );
    // Seed Inbox so the sidebar can expand immediately while bootstrap LIST runs.
    await _repository.upsertFolders(<MailFolder>[
      MailFolder(
        id: MailFolder.inboxId(id),
        accountId: id,
        name: 'Inbox',
        remoteId: 'INBOX',
        role: 'inbox',
      ),
    ]);
    await _repository.enqueueSyncJob(accountId: id, type: 'bootstrap');
    await _enqueuePimBootstrap(id);
    return account;
  }

  /// Updates display metadata while keeping provider identity and credentials stable.
  Future<MailAccount> updateAccountMetadata({
    required MailAccount account,
    required String label,
    required Color accent,
    String? syncProfileId,
    int? retentionDaysOverride,
    bool clearRetentionOverride = false,
  }) async {
    final String trimmedLabel = label.trim();
    if (trimmedLabel.isEmpty) {
      throw ArgumentError.value(label, 'label', 'Label must not be empty.');
    }
    final MailAccount updated = MailAccount(
      id: account.id,
      label: trimmedLabel,
      address: account.address,
      accent: accent,
      providerType: account.providerType,
      storageType: account.storageType,
      focusEnabled: account.focusEnabled,
      credentialsRef: account.credentialsRef,
      syncProfileId: syncProfileId ?? account.syncProfileId,
      retentionDaysOverride: clearRetentionOverride
          ? null
          : (retentionDaysOverride ?? account.retentionDaysOverride),
    );
    await _repository.upsertAccount(
      updated,
      providerType: account.providerType,
      focusEnabled: account.focusEnabled,
    );
    return updated;
  }

  /// Assigns a sync profile and optional retention override for [account].
  Future<MailAccount> updateSyncSettings({
    required MailAccount account,
    String? syncProfileId,
    int? retentionDaysOverride,
    bool clearRetentionOverride = false,
  }) {
    return updateAccountMetadata(
      account: account,
      label: account.label,
      accent: account.accent,
      syncProfileId: syncProfileId,
      retentionDaysOverride: retentionDaysOverride,
      clearRetentionOverride: clearRetentionOverride,
    );
  }

  /// Replaces Graph tokens for an existing account without changing [credentialsRef].
  Future<void> updateGraphCredentials({
    required MailAccount account,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    bool enqueueBootstrap = true,
  }) async {
    if (accessToken.trim().isEmpty) {
      throw ArgumentError.value(
        accessToken,
        'accessToken',
        'Must not be empty.',
      );
    }
    final String ref = account.credentialsRef ?? 'graph:${account.id}';
    await _identityManager.saveGraphToken(
      ref,
      accessToken,
      refreshToken,
      expiresAt,
    );
    if (enqueueBootstrap) {
      await _repository.enqueueSyncJob(
        accountId: account.id,
        type: 'bootstrap',
      );
      await _enqueuePimBootstrap(account.id);
    }
  }

  /// Replaces Google OAuth tokens for an existing XOAUTH account.
  ///
  /// Used after Edit account → Re-authenticate with Google (Wave G scope
  /// expansion). Clears prior Google secrets first so a stale mail-only
  /// refresh token cannot remain (DEF-061). Requires [refreshToken].
  /// Enqueues mail + PIM bootstrap when [enqueueBootstrap] is true.
  Future<void> updateGoogleCredentials({
    required MailAccount account,
    required String accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    bool enqueueBootstrap = true,
  }) async {
    if (accessToken.trim().isEmpty) {
      throw ArgumentError.value(
        accessToken,
        'accessToken',
        'Must not be empty.',
      );
    }
    final String? trimmedRefresh = refreshToken?.trim();
    if (trimmedRefresh == null || trimmedRefresh.isEmpty) {
      throw ArgumentError.value(
        refreshToken,
        'refreshToken',
        'Re-authenticate with Google must return a new offline refresh token. '
        'Remove Synesis under Google Account → Third-party access, then retry.',
      );
    }
    final String ref = account.credentialsRef ?? 'google:${account.id}';
    await _identityManager.replaceGoogleToken(
      ref,
      accessToken,
      refreshToken: trimmedRefresh,
      expiresAt: expiresAt,
    );
    if (enqueueBootstrap) {
      await _repository.enqueueSyncJob(
        accountId: account.id,
        type: 'bootstrap',
      );
      await _enqueuePimBootstrap(account.id);
    }
  }

  /// Enqueues contact-list + calendar bootstrap jobs (Graph / Google / DAV PIM).
  Future<void> _enqueuePimBootstrap(String accountId) async {
    await _repository.enqueueSyncJob(
      accountId: accountId,
      type: PimSyncJobs.contactListsBootstrap,
    );
    await _repository.enqueueSyncJob(
      accountId: accountId,
      type: PimSyncJobs.calendarsBootstrap,
    );
  }

  /// Replaces supplied IMAP/SMTP/DAV secrets without changing [credentialsRef].
  Future<void> updateImapCredentials({
    required MailAccount account,
    String? password,
    String? host,
    int? port,
    String? user,
    String? smtpHost,
    int? smtpPort,
    String? davBaseUrl,
    bool enqueueBootstrap = true,
  }) async {
    if (password != null && password.trim().isEmpty) {
      throw ArgumentError.value(
        password,
        'password',
        'Password must not be empty.',
      );
    }
    if (port != null && (port < 1 || port > 65535)) {
      throw ArgumentError.value(port, 'port', 'IMAP port must be between 1 and 65535.');
    }
    if (smtpPort != null && (smtpPort < 1 || smtpPort > 65535)) {
      throw ArgumentError.value(
        smtpPort,
        'smtpPort',
        'SMTP port must be between 1 and 65535.',
      );
    }
    final String ref = account.credentialsRef ?? 'imap:${account.id}';
    final List<Future<void>> writes = <Future<void>>[];
    if (password != null) {
      writes.addAll(<Future<void>>[
        _credentials.writeSecret(
          credentialsRef: ref,
          name: 'imap.password',
          value: password,
        ),
        _credentials.writeSecret(
          credentialsRef: ref,
          name: 'imap.auth',
          value: 'password',
        ),
      ]);
    }
    if (host != null && host.trim().isNotEmpty) {
      writes.add(
        _credentials.writeSecret(
          credentialsRef: ref,
          name: 'imap.host',
          value: host.trim(),
        ),
      );
    }
    if (port != null) {
      writes.add(
        _credentials.writeSecret(
          credentialsRef: ref,
          name: 'imap.port',
          value: port.toString(),
        ),
      );
    }
    if (user != null && user.trim().isNotEmpty) {
      writes.add(
        _credentials.writeSecret(
          credentialsRef: ref,
          name: 'imap.user',
          value: user.trim(),
        ),
      );
    }
    if (smtpHost != null && smtpHost.trim().isNotEmpty) {
      writes.add(
        _credentials.writeSecret(
          credentialsRef: ref,
          name: 'smtp.host',
          value: smtpHost.trim(),
        ),
      );
    }
    if (smtpPort != null) {
      writes.add(
        _credentials.writeSecret(
          credentialsRef: ref,
          name: 'smtp.port',
          value: smtpPort.toString(),
        ),
      );
    }
    final String? resolvedDavBaseUrl = _davBaseUrl(
      davBaseUrl,
      address: account.address,
      imapHost: host,
    );
    if (resolvedDavBaseUrl != null) {
      writes.add(
        _credentials.writeSecret(
          credentialsRef: ref,
          name: 'dav.baseUrl',
          value: resolvedDavBaseUrl,
        ),
      );
    }
    await Future.wait(writes);
    if (enqueueBootstrap) {
      await _repository.enqueueSyncJob(
        accountId: account.id,
        type: 'bootstrap',
      );
      if (await isDavPimEnabled(account)) {
        await _enqueueDavPimBootstrap(account.id);
      }
    }
  }

  /// Returns the configured shared CardDAV/CalDAV base URL, if one exists.
  Future<String?> readDavBaseUrl(MailAccount account) {
    final String ref = account.credentialsRef ?? 'imap:${account.id}';
    return _credentials.readSecret(credentialsRef: ref, name: 'dav.baseUrl');
  }

  /// Wipes local mailbox data and deletes secure credentials for an account.
  Future<void> removeAccount({
    required String accountId,
    required String confirmation,
  }) async {
    final String requiredConfirmation =
        DiagnosticsService.confirmationFor(accountId);
    if (confirmation != requiredConfirmation) {
      throw ArgumentError.value(
        confirmation,
        'confirmation',
        'Enter "$requiredConfirmation" to remove this account.',
      );
    }
    final List<MailAccount> accounts = await _repository.listAccounts();
    MailAccount? account;
    for (final MailAccount candidate in accounts) {
      if (candidate.id == accountId) {
        account = candidate;
        break;
      }
    }
    final String? credentialsRef = account?.credentialsRef;
    await _repository.wipeAccount(accountId);
    if (credentialsRef != null && credentialsRef.trim().isNotEmpty) {
      await _credentials.deleteCredentials(credentialsRef);
    }
    // Rebuild aggregate widget payloads (counter may omit accountId).
    await _widgetSnapshots?.refreshAll();
  }

  static String removeConfirmationFor(String accountId) =>
      DiagnosticsService.confirmationFor(accountId);

  /// Whether an IMAP Basic-auth account is eligible for DAV PIM sync.
  Future<bool> isDavPimEnabled(MailAccount account) async {
    if (account.providerType != 'imap' ||
        (account.credentialsRef ?? '').startsWith('google:')) {
      return false;
    }
    final String ref = account.credentialsRef ?? 'imap:${account.id}';
    final String? auth = await _credentials.readSecret(
      credentialsRef: ref,
      name: 'imap.auth',
    );
    if ((auth ?? 'password').trim().toLowerCase() == 'xoauth2') {
      return false;
    }
    final String? dav = await _credentials.readSecret(
      credentialsRef: ref,
      name: 'dav.baseUrl',
    );
    final String? host = await _credentials.readSecret(
      credentialsRef: ref,
      name: 'imap.host',
    );
    return dav != null || DavDiscovery.isRunboxHint(account.address, host);
  }

  Future<void> _enqueueDavPimBootstrap(String accountId) =>
      _enqueuePimBootstrap(accountId);

  static String? _davBaseUrl(
    String? value, {
    required String address,
    required String? imapHost,
  }) {
    final String? normalized = DavDiscovery.normalizeBaseUrl(value);
    return normalized ??
        (DavDiscovery.isRunboxHint(address, imapHost)
            ? DavDiscovery.runboxDavUrl
            : null);
  }
}
