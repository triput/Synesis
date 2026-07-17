// ==============================================================================
// File: lib/ui/account/manage_accounts_sheet.dart
// Description: Settings sheet to list, edit, and remove mail accounts
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/ui/account/add_account_sheet.dart';
import 'package:bytemail/ui/account/edit_account_sheet.dart';
import 'package:bytemail/ui/account/remove_account_dialog.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';

Future<void> showManageAccountsSheet(BuildContext context) {
  final t = tokensOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 28,
        ),
        child: const _ManageAccountsSheet(),
      );
    },
  );
}

class _ManageAccountsSheet extends StatelessWidget {
  const _ManageAccountsSheet();

  String _providerLabel(MailAccount account) {
    switch (account.providerType) {
      case 'graph':
        return 'Microsoft';
      case 'imap':
        return 'IMAP';
      default:
        return account.providerType;
    }
  }

  Future<void> _removeAccount(
    BuildContext context,
    MailAccount account,
  ) async {
    final bool removed = await showRemoveAccountDialog(context, account);
    if (removed && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Removed ${account.address}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final List<MailAccount> accounts =
        context.watch<MailboxCubit>().state.accounts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Manage accounts',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Edit labels and credentials, or remove an account from this device.',
          style: TextStyle(color: t.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        if (accounts.isEmpty) ...[
          Text(
            'No accounts yet. Add one to start syncing mail.',
            style: TextStyle(color: t.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showAddAccountSheet(context);
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add account'),
          ),
        ] else
          for (final MailAccount account in accounts)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              color: t.ink,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          account.accent.withValues(alpha: 0.35),
                          t.ink,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        account.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            account.address,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _providerLabel(account),
                            style: TextStyle(color: t.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Edit',
                      onPressed: () => showEditAccountSheet(context, account),
                      icon: const Icon(Icons.edit_outlined),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      onPressed: () => _removeAccount(context, account),
                      icon: Icon(Icons.delete_outline, color: t.coral),
                    ),
                  ],
                ),
              ),
            ),
        if (accounts.isNotEmpty) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              showAddAccountSheet(context);
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add another account'),
          ),
        ],
      ],
    );
  }
}
