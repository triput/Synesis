// ==============================================================================
// File: lib/ui/outbox/outbox_sheet.dart
// Description: Inspect, retry, and clear pending/failed outbox sends.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/outbox/send_error_messages.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';

/// Opens the outbox inspector so users can see queued/failed sends and act.
Future<void> showOutboxSheet(BuildContext context) async {
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
        child: const _OutboxSheetBody(),
      );
    },
  );
}

class _OutboxSheetBody extends StatefulWidget {
  const _OutboxSheetBody();

  @override
  State<_OutboxSheetBody> createState() => _OutboxSheetBodyState();
}

class _OutboxSheetBodyState extends State<_OutboxSheetBody> {
  List<OutboxItem> _items = const <OutboxItem>[];
  bool _loading = true;
  bool _busy = false;
  String? _banner;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final MailRepository repo = context.read<MailRepository>();
    final List<OutboxItem> all = await repo.listOutbox();
    final List<OutboxItem> active = all
        .where(
          (OutboxItem item) =>
              item.state == 'queued' ||
              item.state == 'sending' ||
              item.state == 'failed',
        )
        .toList(growable: false);
    if (!mounted) {
      return;
    }
    setState(() {
      _items = active;
      _loading = false;
    });
  }

  String _accountLabel(String accountId) {
    final List<MailAccount> accounts =
        context.read<MailboxCubit>().state.accounts;
    for (final MailAccount account in accounts) {
      if (account.id == accountId) {
        return account.address;
      }
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
    try {
      await action();
      await context.read<MailboxCubit>().refresh();
      await _reload();
    } on Object catch (error) {
      if (mounted) {
        setState(() {
          _banner = actionableSendError(error);
        });
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _retry(OutboxItem item) async {
    await _withBusy(() async {
      final MailRepository repo = context.read<MailRepository>();
      final SyncEngine sync = context.read<SyncEngine>();
      await repo.updateOutboxState(item.id, 'queued');
      await repo.enqueueSyncJob(
        accountId: item.accountId,
        type: 'send_outbox',
      );
      await sync.kick();
    });
  }

  Future<void> _discard(OutboxItem item) async {
    await _withBusy(() async {
      await context.read<MailRepository>().deleteOutbox(item.id);
    });
  }

  Future<void> _clearStates(List<String> states, String emptyMessage) async {
    await _withBusy(() async {
      final int removed =
          await context.read<MailRepository>().deleteOutboxInStates(states);
      if (mounted) {
        setState(() {
          _banner = removed == 0
              ? emptyMessage
              : 'Removed $removed outbox item${removed == 1 ? '' : 's'}.';
        });
      }
    });
  }

  Future<void> _sendNow() async {
    await _withBusy(() async {
      final MailRepository repo = context.read<MailRepository>();
      final SyncEngine sync = context.read<SyncEngine>();
      final Set<String> accountIds = <String>{};
      for (final OutboxItem item in _items) {
        if (item.state == 'queued' || item.state == 'failed') {
          accountIds.add(item.accountId);
          if (item.state == 'failed') {
            await repo.updateOutboxState(item.id, 'queued');
          }
        }
      }
      for (final String accountId in accountIds) {
        await repo.enqueueSyncJob(
          accountId: accountId,
          type: 'send_outbox',
        );
      }
      await sync.kickFresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final int failedCount =
        _items.where((OutboxItem i) => i.state == 'failed').length;
    final int queuedCount = _items
        .where(
          (OutboxItem i) => i.state == 'queued' || i.state == 'sending',
        )
        .length;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Outbox', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Queued and failed sends stay here until they succeed or you clear them.',
            style: TextStyle(color: t.muted, height: 1.35),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton(
                onPressed: _busy || _items.isEmpty ? null : _sendNow,
                child: Text(_busy ? 'Working…' : 'Retry send now'),
              ),
              OutlinedButton(
                onPressed: _busy || queuedCount == 0
                    ? null
                    : () => _clearStates(
                          <String>['queued', 'sending'],
                          'No queued items to clear.',
                        ),
                child: const Text('Clear queued'),
              ),
              OutlinedButton(
                onPressed: _busy || failedCount == 0
                    ? null
                    : () => _clearStates(
                          <String>['failed'],
                          'No failed items to clear.',
                        ),
                child: const Text('Clear failed'),
              ),
            ],
          ),
          if (_banner != null) ...<Widget>[
            const SizedBox(height: 12),
            Text(_banner!, style: TextStyle(color: t.coral, height: 1.35)),
          ],
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Outbox is empty.',
                style: TextStyle(color: t.muted),
              ),
            )
          else
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: _items.length,
                separatorBuilder: (_, __) => Divider(color: t.line, height: 1),
                itemBuilder: (BuildContext context, int index) {
                  return _OutboxTile(
                    item: _items[index],
                    accountLabel: _accountLabel(_items[index].accountId),
                    busy: _busy,
                    onRetry: () => _retry(_items[index]),
                    onDiscard: () => _discard(_items[index]),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _OutboxTile extends StatelessWidget {
  const _OutboxTile({
    required this.item,
    required this.accountLabel,
    required this.busy,
    required this.onRetry,
    required this.onDiscard,
  });

  final OutboxItem item;
  final String accountLabel;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final String subject =
        item.subject.trim().isEmpty ? '(no subject)' : item.subject.trim();
    final String? error = item.lastError?.trim();
    final String statusLabel = switch (item.state) {
      'failed' => 'Failed',
      'sending' => 'Sending',
      _ => 'Queued',
    };
    final Color statusColor = switch (item.state) {
      'failed' => t.coral,
      'sending' => t.teal,
      _ => t.amber,
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  subject,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: t.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'To ${item.to.isEmpty ? '(none)' : item.to} · from $accountLabel',
            style: TextStyle(color: t.muted, fontSize: 12, height: 1.3),
          ),
          if (error != null && error.isNotEmpty) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              actionableSendError(error, accountHint: accountLabel),
              style: TextStyle(color: t.coral, fontSize: 12, height: 1.35),
            ),
          ] else if (item.state == 'queued' || item.state == 'sending') ...<Widget>[
            const SizedBox(height: 6),
            Text(
              item.state == 'sending'
                  ? 'Send is in progress. If this sticks, use Retry send now.'
                  : 'Waiting for sync to send. Use Retry send now if it sits here.',
              style: TextStyle(color: t.muted, fontSize: 12, height: 1.35),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              TextButton(
                onPressed: busy || item.state == 'sending' ? null : onRetry,
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: busy ? null : onDiscard,
                child: Text('Discard', style: TextStyle(color: t.coral)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
