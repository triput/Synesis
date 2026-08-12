// ==============================================================================
// File: lib/ui/sync/sync_status_sheet.dart
// Description: In-app sync job queue viewer and per-account sync health.
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-08-12
// ==============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/sync_activity.dart';
import 'package:synesis/sync/sync_engine.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/mailbox/mailbox_cubit.dart';
import 'package:synesis/ui/sync/sync_status_presentation.dart';

/// Opens the sync health / job viewer sheet.
Future<void> showSyncStatusSheet(BuildContext context) async {
  final ThemeTokens t = tokensOf(context);
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (BuildContext context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: const SyncStatusSheetBody(),
      );
    },
  );
}

/// Public for widget tests.
class SyncStatusSheetBody extends StatefulWidget {
  const SyncStatusSheetBody({super.key});

  @override
  State<SyncStatusSheetBody> createState() => _SyncStatusSheetBodyState();
}

class _SyncStatusSheetBodyState extends State<SyncStatusSheetBody>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  StreamSubscription<void>? _watchSub;
  StreamSubscription<SyncActivitySnapshot>? _syncActivitySub;
  SyncActivitySnapshot _syncActivity = const SyncActivitySnapshot.idle();
  List<SyncJob> _jobs = const <SyncJob>[];
  List<AccountSyncHealth> _health = const <AccountSyncHealth>[];
  bool _loading = true;
  bool _busy = false;
  bool _didInit = false;
  String? _banner;
  bool _bannerIsError = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) {
      return;
    }
    _didInit = true;
    final MailRepository repo = context.read<MailRepository>();
    _watchSub = repo.watchChanges().listen((_) {
      if (mounted) {
        unawaited(_reload());
      }
    });
    final SyncActivity syncActivity = context.read<SyncActivity>();
    _syncActivity = syncActivity.value;
    _syncActivitySub = syncActivity.stream.listen((
      SyncActivitySnapshot snapshot,
    ) {
      if (mounted) {
        setState(() => _syncActivity = snapshot);
      }
    });
    unawaited(_reload());
  }

  @override
  void dispose() {
    unawaited(_watchSub?.cancel() ?? Future<void>.value());
    unawaited(_syncActivitySub?.cancel() ?? Future<void>.value());
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    final MailRepository repo = context.read<MailRepository>();
    final List<SyncJob> jobs = await repo.listSyncJobs(limit: 50);
    final List<AccountSyncHealth> health = await repo.listAccountSyncHealth();
    if (!mounted) {
      return;
    }
    setState(() {
      _jobs = jobs;
      _health = health;
      _loading = false;
    });
  }

  MailAccount? _accountFor(String accountId) {
    try {
      final List<MailAccount> accounts =
          context.read<MailboxCubit>().state.accounts;
      for (final MailAccount account in accounts) {
        if (account.id == accountId) {
          return account;
        }
      }
    } on Object {
      // Sheet may be opened without MailboxCubit in tests.
    }
    return null;
  }

  String _accountLabel(String accountId) {
    final MailAccount? account = _accountFor(accountId);
    if (account != null) {
      return account.address;
    }
    return accountId;
  }

  bool _supportsOAuthRefresh(String accountId) {
    final MailAccount? account = _accountFor(accountId);
    if (account == null) {
      return false;
    }
    if (account.providerType == 'graph' ||
        account.providerType == 'microsoft') {
      return true;
    }
    if (account.providerType == 'imap') {
      final String? ref = account.credentialsRef?.trim();
      if (ref != null && ref.startsWith('google:')) {
        return true;
      }
    }
    return false;
  }

  Future<void> _withBusy(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    if (_busy) {
      return;
    }
    setState(() {
      _busy = true;
      _banner = null;
    });
    MailboxCubit? mailbox;
    try {
      mailbox = context.read<MailboxCubit>();
    } on Object {
      mailbox = null;
    }
    try {
      await action();
      if (!mounted) {
        return;
      }
      await mailbox?.refresh();
      await _reload();
      if (mounted && successMessage != null) {
        setState(() {
          _banner = successMessage;
          _bannerIsError = false;
        });
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _banner = 'Sync action failed: $error';
          _bannerIsError = true;
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  SyncEngine? _syncEngineOrNull() {
    try {
      return context.read<SyncEngine>();
    } on Object {
      return null;
    }
  }

  Future<void> _retryJob(SyncJob job) async {
    await _withBusy(() async {
      final MailRepository repo = context.read<MailRepository>();
      final SyncEngine? sync = _syncEngineOrNull();
      await repo.retrySyncJob(job.id);
      sync?.kickNonBlocking();
    });
  }

  Future<void> _cancelJob(SyncJob job) async {
    await _withBusy(() async {
      await context.read<MailRepository>().cancelSyncJob(job.id);
    });
  }

  Future<void> _stopAllSync() async {
    final SyncEngine? sync = _syncEngineOrNull();
    if (sync == null) {
      return;
    }
    await _withBusy(() async {
      final ({int abortedRunning, int cancelledPending}) result =
          await sync.stopAllSync();
      final int total = result.abortedRunning + result.cancelledPending;
      if (mounted) {
        setState(() {
          _banner = total == 0
              ? 'No active sync jobs to stop.'
              : 'Stopped sync: ${result.cancelledPending} pending cancelled, '
                    '${result.abortedRunning} running aborted. '
                    'Local mail was not deleted.';
          _bannerIsError = false;
        });
      }
    });
  }

  Future<void> _stopAccountSync(String accountId) async {
    final SyncEngine? sync = _syncEngineOrNull();
    if (sync == null) {
      return;
    }
    await _withBusy(() async {
      final ({int abortedRunning, int cancelledPending}) result =
          await sync.stopAllSync(accountId: accountId);
      final int total = result.abortedRunning + result.cancelledPending;
      if (mounted) {
        setState(() {
          _banner = total == 0
              ? 'No active jobs for this account.'
              : 'Stopped sync for ${_accountLabel(accountId)}: '
                    '${result.cancelledPending} pending, '
                    '${result.abortedRunning} running. '
                    'Local mail was not deleted.';
          _bannerIsError = false;
        });
      }
    });
  }

  Future<bool> _confirmClearCursors(String accountLabel) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Clear sync cursors?'),
          content: Text(
            'Removes sync position markers for $accountLabel so the next '
            'sync re-fetches from the server.\n\n'
            'Downloaded mail and folders on this device are not deleted.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Clear cursors'),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _clearAccountCursors(String accountId) async {
    final String label = _accountLabel(accountId);
    final bool confirmed = await _confirmClearCursors(label);
    if (!confirmed || !mounted) {
      return;
    }
    final SyncEngine? sync = _syncEngineOrNull();
    if (sync == null) {
      return;
    }
    await _withBusy(() async {
      final int removed = await sync.clearSyncCursors(accountId: accountId);
      if (mounted) {
        setState(() {
          _banner = removed == 0
              ? 'No sync cursors stored for $label.'
              : 'Cleared $removed sync cursor(s) for $label. '
                    'Downloaded mail was not deleted.';
          _bannerIsError = false;
        });
      }
    });
  }

  Future<void> _forceRefreshToken(String accountId, {bool syncAfter = false}) async {
    final SyncEngine? sync = _syncEngineOrNull();
    if (sync == null) {
      return;
    }
    await _withBusy(() async {
      await sync.forceRefreshAuthToken(accountId);
      if (syncAfter) {
        await _enqueueAccountSync(accountId, sync);
      }
      if (mounted) {
        setState(() {
          _banner = syncAfter
              ? 'Token refreshed and sync queued for ${_accountLabel(accountId)}.'
              : 'Access token refreshed for ${_accountLabel(accountId)}.';
          _bannerIsError = false;
        });
      }
    });
  }

  Future<void> _enqueueAccountSync(String accountId, SyncEngine sync) async {
    final MailRepository repo = context.read<MailRepository>();
    await sync.enqueueIncremental(accountId);
    final List<MailFolder> folders = await repo.listFolders(
      accountId: accountId,
    );
    MailFolder? inbox;
    for (final MailFolder folder in folders) {
      if (folder.role == 'inbox' ||
          folder.id == MailFolder.inboxId(accountId)) {
        inbox = folder;
        break;
      }
    }
    final MailFolder? target = inbox;
    if (target != null && target.remoteId.isNotEmpty) {
      await repo.enqueueSyncJob(
        accountId: accountId,
        type: 'full_folder',
        payloadJson: jsonEncode(<String, String>{
          'folderId': target.id,
          'remoteId': target.remoteId,
        }),
      );
    }
    sync.kickNonBlocking();
  }

  Future<void> _syncAccountNow(AccountSyncHealth health) async {
    final SyncEngine? sync = _syncEngineOrNull();
    if (sync == null) {
      return;
    }
    await _withBusy(() async {
      await _enqueueAccountSync(health.accountId, sync);
    });
  }

  String _formatUpdated(int epochMs) {
    final DateTime time = DateTime.fromMillisecondsSinceEpoch(epochMs);
    final String hh = time.hour.toString().padLeft(2, '0');
    final String mm = time.minute.toString().padLeft(2, '0');
    final String ss = time.second.toString().padLeft(2, '0');
    return '$hh:$mm:$ss';
  }

  String _formatSuccess(DateTime? at) {
    if (at == null) {
      return 'Never';
    }
    final String hh = at.hour.toString().padLeft(2, '0');
    final String mm = at.minute.toString().padLeft(2, '0');
    return '${at.month}/${at.day} $hh:$mm';
  }

  bool get _hasActiveSyncWork =>
      _syncActivity.isRemoteSyncInFlight || _syncActivity.activeJobCount > 0;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    String repositoryLabel = 'Up to date';
    try {
      repositoryLabel = context.read<MailboxCubit>().state.syncStatusLabel;
    } on Object {
      // Sheet may open without MailboxCubit in tests.
    }
    final String statusSummary = SyncStatusPresentation.sheetSummary(
      activity: _syncActivity,
      repositoryLabel: repositoryLabel,
    );
    final bool needsAttention = SyncStatusPresentation.needsAttention(
      statusSummary,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.78,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Sync status', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Inspect the sync job queue and per-account health. Stop runaway '
            'sync, clear stale cursors, refresh OAuth tokens, or sync now.',
            style: TextStyle(color: t.muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: needsAttention
                  ? t.coral.withValues(alpha: 0.12)
                  : (_syncActivity.isRemoteSyncInFlight
                        ? t.teal.withValues(alpha: 0.12)
                        : t.panel2),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: needsAttention
                    ? t.coral.withValues(alpha: 0.35)
                    : t.line,
              ),
            ),
            child: Row(
              children: <Widget>[
                if (_syncActivity.isRemoteSyncInFlight)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: needsAttention ? t.coral : t.teal,
                      ),
                    ),
                  ),
                Expanded(
                  child: Text(
                    statusSummary,
                    style: TextStyle(
                      color: needsAttention ? t.coral : t.text,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_hasActiveSyncWork) ...<Widget>[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: _busy ? null : _stopAllSync,
                child: const Text('Stop all sync'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            labelColor: t.teal,
            unselectedLabelColor: t.muted,
            indicatorColor: t.teal,
            tabs: const <Widget>[
              Tab(text: 'Jobs'),
              Tab(text: 'Accounts'),
            ],
          ),
          if (_banner != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              _banner!,
              style: TextStyle(
                color: _bannerIsError ? t.coral : t.teal,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Flexible(
            child: _loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : TabBarView(
                    controller: _tabs,
                    children: <Widget>[
                      RefreshIndicator(
                        onRefresh: _reload,
                        child: _jobs.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 32,
                                    ),
                                    child: Text(
                                      'No sync jobs yet.',
                                      style: TextStyle(color: t.muted),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _jobs.length,
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        Divider(color: t.line, height: 1),
                                itemBuilder: (BuildContext context, int index) {
                                  final SyncJob job = _jobs[index];
                                  return _JobTile(
                                    job: job,
                                    accountLabel: _accountLabel(job.accountId),
                                    updatedLabel: _formatUpdated(job.updatedAt),
                                    busy: _busy,
                                    onRetry: job.status == 'failed'
                                        ? () => _retryJob(job)
                                        : null,
                                    onCancel: job.status == 'pending'
                                        ? () => _cancelJob(job)
                                        : null,
                                  );
                                },
                              ),
                      ),
                      RefreshIndicator(
                        onRefresh: _reload,
                        child: _health.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: <Widget>[
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 32,
                                    ),
                                    child: Text(
                                      'No accounts configured.',
                                      style: TextStyle(color: t.muted),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemCount: _health.length,
                                separatorBuilder:
                                    (BuildContext context, int index) =>
                                        Divider(color: t.line, height: 1),
                                itemBuilder: (BuildContext context, int index) {
                                  final AccountSyncHealth row = _health[index];
                                  final bool accountActive =
                                      row.syncing || row.pendingCount > 0;
                                  return _AccountHealthTile(
                                    health: row,
                                    accountLabel: _accountLabel(row.accountId),
                                    lastSuccessLabel: _formatSuccess(
                                      row.lastSuccessAt,
                                    ),
                                    busy: _busy,
                                    showStop: accountActive,
                                    showOAuthRefresh: _supportsOAuthRefresh(
                                      row.accountId,
                                    ),
                                    onSyncNow: () => _syncAccountNow(row),
                                    onStop: () => _stopAccountSync(
                                      row.accountId,
                                    ),
                                    onClearCursors: () => _clearAccountCursors(
                                      row.accountId,
                                    ),
                                    onRefreshToken: () => _forceRefreshToken(
                                      row.accountId,
                                      syncAfter: true,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _JobTile extends StatelessWidget {
  const _JobTile({
    required this.job,
    required this.accountLabel,
    required this.updatedLabel,
    required this.busy,
    this.onRetry,
    this.onCancel,
  });

  final SyncJob job;
  final String accountLabel;
  final String updatedLabel;
  final bool busy;
  final VoidCallback? onRetry;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final String? error = job.errorSnippet;
    final String shortError = error == null
        ? ''
        : (error.length > 96 ? '${error.substring(0, 96)}…' : error);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  job.type,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              _StatusChip(status: job.status),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '$accountLabel · $updatedLabel',
            style: TextStyle(color: t.muted, fontSize: 12),
          ),
          if (shortError.isNotEmpty) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              shortError,
              style: TextStyle(color: t.coral, fontSize: 12, height: 1.3),
            ),
          ],
          if (onRetry != null || onCancel != null) ...<Widget>[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                if (onRetry != null)
                  OutlinedButton(
                    onPressed: busy ? null : onRetry,
                    child: const Text('Retry'),
                  ),
                if (onCancel != null)
                  OutlinedButton(
                    onPressed: busy ? null : onCancel,
                    child: const Text('Cancel'),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountHealthTile extends StatelessWidget {
  const _AccountHealthTile({
    required this.health,
    required this.accountLabel,
    required this.lastSuccessLabel,
    required this.busy,
    required this.showStop,
    required this.showOAuthRefresh,
    required this.onSyncNow,
    required this.onStop,
    required this.onClearCursors,
    required this.onRefreshToken,
  });

  final AccountSyncHealth health;
  final String accountLabel;
  final String lastSuccessLabel;
  final bool busy;
  final bool showStop;
  final bool showOAuthRefresh;
  final VoidCallback onSyncNow;
  final VoidCallback onStop;
  final VoidCallback onClearCursors;
  final VoidCallback onRefreshToken;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final String statusBits = <String>[
      if (health.syncing) 'syncing',
      if (health.pendingCount > 0) '${health.pendingCount} pending',
      if (health.failedCount > 0) '${health.failedCount} failed',
      if (!health.syncing && health.pendingCount == 0 && health.failedCount == 0)
        'idle',
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            accountLabel,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Last success: $lastSuccessLabel · $statusBits',
            style: TextStyle(color: t.muted, fontSize: 12),
          ),
          if (health.lastError != null && health.lastError!.isNotEmpty) ...<
            Widget
          >[
            const SizedBox(height: 4),
            Text(
              health.lastError!.length > 96
                  ? '${health.lastError!.substring(0, 96)}…'
                  : health.lastError!,
              style: TextStyle(color: t.coral, fontSize: 12, height: 1.3),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              OutlinedButton(
                onPressed: busy ? null : onSyncNow,
                child: const Text('Sync now'),
              ),
              if (showStop)
                OutlinedButton(
                  onPressed: busy ? null : onStop,
                  child: const Text('Stop sync'),
                ),
              if (showOAuthRefresh)
                OutlinedButton(
                  onPressed: busy ? null : onRefreshToken,
                  child: const Text('Refresh token'),
                ),
              TextButton(
                onPressed: busy ? null : onClearCursors,
                child: const Text('Clear cursors'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final Color bg;
    final Color fg;
    switch (status) {
      case 'failed':
        bg = t.coral.withValues(alpha: 0.22);
        fg = t.coral;
      case 'running':
        bg = t.teal.withValues(alpha: 0.22);
        fg = t.teal;
      case 'pending':
        bg = t.amber.withValues(alpha: 0.22);
        fg = t.amber;
      default:
        bg = t.panel2;
        fg = t.muted;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
