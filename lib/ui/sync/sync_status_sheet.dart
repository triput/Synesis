// ==============================================================================
// File: lib/ui/sync/sync_status_sheet.dart
// Description: In-app sync job queue viewer and per-account sync health.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';

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
  List<SyncJob> _jobs = const <SyncJob>[];
  List<AccountSyncHealth> _health = const <AccountSyncHealth>[];
  bool _loading = true;
  bool _busy = false;
  bool _didInit = false;
  String? _banner;

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
    unawaited(_reload());
  }

  @override
  void dispose() {
    unawaited(_watchSub?.cancel() ?? Future<void>.value());
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

  String _accountLabel(String accountId) {
    try {
      final List<MailAccount> accounts =
          context.read<MailboxCubit>().state.accounts;
      for (final MailAccount account in accounts) {
        if (account.id == accountId) {
          return account.address;
        }
      }
    } on Object {
      // Sheet may be opened without MailboxCubit in tests.
    }
    return accountId;
  }

  Future<void> _withBusy(Future<void> Function() action) async {
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
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _banner = 'Sync action failed: $error';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _retryJob(SyncJob job) async {
    await _withBusy(() async {
      final MailRepository repo = context.read<MailRepository>();
      SyncEngine? sync;
      try {
        sync = context.read<SyncEngine>();
      } on Object {
        sync = null;
      }
      await repo.retrySyncJob(job.id);
      await sync?.kick();
    });
  }

  Future<void> _cancelJob(SyncJob job) async {
    await _withBusy(() async {
      await context.read<MailRepository>().cancelSyncJob(job.id);
    });
  }

  Future<void> _syncAccountNow(AccountSyncHealth health) async {
    await _withBusy(() async {
      final MailRepository repo = context.read<MailRepository>();
      final SyncEngine sync = context.read<SyncEngine>();
      await sync.enqueueIncremental(health.accountId);
      final List<MailFolder> folders = await repo.listFolders(
        accountId: health.accountId,
      );
      MailFolder? inbox;
      for (final MailFolder folder in folders) {
        if (folder.role == 'inbox' ||
            folder.id == MailFolder.inboxId(health.accountId)) {
          inbox = folder;
          break;
        }
      }
      final MailFolder? target = inbox;
      if (target != null && target.remoteId.isNotEmpty) {
        await repo.enqueueSyncJob(
          accountId: health.accountId,
          type: 'full_folder',
          payloadJson: jsonEncode(<String, String>{
            'folderId': target.id,
            'remoteId': target.remoteId,
          }),
        );
      }
      await sync.kick();
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

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
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
            'Inspect the sync job queue and per-account health. Retry failed jobs or sync an account now.',
            style: TextStyle(color: t.muted, height: 1.35),
          ),
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
            Text(_banner!, style: TextStyle(color: t.coral, height: 1.35)),
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
                                separatorBuilder: (BuildContext context, int index) =>
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
                                separatorBuilder: (BuildContext context, int index) =>
                                    Divider(color: t.line, height: 1),
                                itemBuilder: (BuildContext context, int index) {
                                  final AccountSyncHealth row = _health[index];
                                  return _AccountHealthTile(
                                    health: row,
                                    accountLabel: _accountLabel(row.accountId),
                                    lastSuccessLabel: _formatSuccess(
                                      row.lastSuccessAt,
                                    ),
                                    busy: _busy,
                                    onSyncNow: () => _syncAccountNow(row),
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
    required this.onSyncNow,
  });

  final AccountSyncHealth health;
  final String accountLabel;
  final String lastSuccessLabel;
  final bool busy;
  final VoidCallback onSyncNow;

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
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  accountLabel,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              OutlinedButton(
                onPressed: busy ? null : onSyncNow,
                child: const Text('Sync now'),
              ),
            ],
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
