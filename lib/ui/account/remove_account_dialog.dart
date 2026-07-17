// ==============================================================================
// File: lib/ui/account/remove_account_dialog.dart
// Description: Destructive account removal with typed WIPE confirmation
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/account/account_service.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/widgets/widget_snapshot_service.dart';

/// Shows a typed-confirmation dialog and removes the account when confirmed.
Future<bool> showRemoveAccountDialog(
  BuildContext context,
  MailAccount account,
) async {
  final bool? removed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => _RemoveAccountDialog(account: account),
  );
  return removed ?? false;
}

class _RemoveAccountDialog extends StatefulWidget {
  const _RemoveAccountDialog({required this.account});

  final MailAccount account;

  @override
  State<_RemoveAccountDialog> createState() => _RemoveAccountDialogState();
}

class _RemoveAccountDialogState extends State<_RemoveAccountDialog> {
  final TextEditingController _confirmation = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _confirmation.dispose();
    super.dispose();
  }

  String get _requiredPhrase =>
      AccountService.removeConfirmationFor(widget.account.id);

  bool get _canConfirm =>
      !_busy && _confirmation.text.trim() == _requiredPhrase;

  Future<void> _remove() async {
    if (!_canConfirm) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final AccountService service = context.read<AccountService>();
      await service.removeAccount(
        accountId: widget.account.id,
        confirmation: _confirmation.text.trim(),
      );
      if (!mounted) {
        return;
      }
      await context.read<AppSettingsCubit>().removeAccountFocus(
            widget.account.id,
          );
      if (!mounted) {
        return;
      }
      await context.read<MailboxCubit>().onAccountRemoved(widget.account.id);
      if (!mounted) {
        return;
      }
      await WidgetSnapshotService(context.read<MailRepository>()).refreshAll();
      if (!mounted) {
        return;
      }
      await context.read<SyncEngine>().kickFresh();
      if (!mounted) {
        return;
      }
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _busy = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    return AlertDialog(
      title: const Text('Remove account'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'This permanently deletes local mail, folders, sync jobs, and '
            'stored credentials for ${widget.account.address}. '
            'The server mailbox is not affected.',
            style: TextStyle(color: t.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Text(
            'Type the phrase below to confirm:',
            style: TextStyle(color: t.muted, fontSize: 12),
          ),
          const SizedBox(height: 4),
          SelectableText(
            _requiredPhrase,
            style: TextStyle(
              color: t.coral,
              fontWeight: FontWeight.w600,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _confirmation,
            decoration: const InputDecoration(
              labelText: 'Confirmation phrase',
            ),
            autocorrect: false,
            enableSuggestions: false,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => _canConfirm ? _remove() : null,
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(
              _error!,
              style: TextStyle(color: t.coral, fontSize: 13),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: t.coral,
          ),
          onPressed: _canConfirm ? _remove : null,
          child: Text(_busy ? 'Removing…' : 'Remove account'),
        ),
      ],
    );
  }
}
