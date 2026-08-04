// ==============================================================================
// File: lib/ui/account/manage_accounts_sheet.dart
// Description: Settings sheet to list, edit, and remove mail accounts
// Component: UI
// Version: 1.3 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-08-03
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synesis/account/account_display.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/density.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/account/add_account_sheet.dart';
import 'package:synesis/ui/account/edit_account_sheet.dart';
import 'package:synesis/ui/account/remove_account_dialog.dart';
import 'package:synesis/ui/common/empty_state.dart';
import 'package:synesis/ui/mailbox/mailbox_cubit.dart';

Future<void> showManageAccountsSheet(BuildContext context) {
  final t = tokensOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (sheetContext) {
      final MediaQueryData mq = MediaQuery.of(sheetContext);
      // Keyboard only here — SafeArea owns system nav. Never force a
      // SizedBox taller than the sheet's max constraint (DEF-063 ribbon).
      return Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Tight height from *already-padded* max — never a fixed
              // fraction of the full screen (that overshoots SafeArea +
              // drag-handle inset and paints the DEF-063 ribbon).
              final double maxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : (mq.size.height -
                        mq.padding.vertical -
                        mq.viewInsets.vertical)
                      .clamp(240.0, mq.size.height);
              return SizedBox(
                height: maxH * 0.95,
                width: double.infinity,
                child: const Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: ManageAccountsSheetBody(primaryScroll: true),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

/// List/edit/remove accounts content (UI-P21 Accounts section).
///
/// [primaryScroll] — when true, owns scrolling inside a height-bounded parent
/// (modal / Settings Accounts). When false, shrink-wraps for rare embed cases.
class ManageAccountsSheetBody extends StatelessWidget {
  const ManageAccountsSheetBody({
    super.key,
    this.primaryScroll = false,
  });

  /// When true, fill a bounded parent and scroll the account list.
  final bool primaryScroll;

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

  Widget _accountCard(BuildContext context, MailAccount account, ThemeTokens t) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: t.ink,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
        child: Row(
          children: <Widget>[
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
                AccountDisplay.monogram(account),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AccountDisplay.primaryLabel(account),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    AccountDisplay.secondaryLabel(account),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _providerLabel(account),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: t.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit',
              visualDensity: VisualDensity.compact,
              onPressed: () => showEditAccountSheet(context, account),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              onPressed: () => _removeAccount(context, account),
              icon: Icon(Icons.delete_outline, color: t.coral),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final List<MailAccount> accounts =
        context.watch<MailboxCubit>().state.accounts;

    final List<Widget> header = <Widget>[
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
    ];

    final Widget? addAnother = accounts.isEmpty
        ? null
        : OutlinedButton.icon(
            onPressed: () {
              // Modal sheet pops; Settings Accounts has no route to pop — ignore.
              final NavigatorState nav = Navigator.of(context);
              if (nav.canPop()) {
                nav.pop();
              }
              showAddAccountSheet(context);
            },
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add another account'),
          );

    if (accounts.isEmpty) {
      final Widget empty = EmptyState(
        title: 'No accounts yet',
        subtitle: 'Add an account to start syncing mail on this device.',
        icon: Icons.person_add_alt_1_outlined,
        density: ViewDensity.calm,
        actionLabel: 'Add account',
        onAction: () {
          final NavigatorState nav = Navigator.of(context);
          if (nav.canPop()) {
            nav.pop();
          }
          showAddAccountSheet(context);
        },
      );
      if (primaryScroll) {
        return ListView(
          children: <Widget>[
            ...header,
            empty,
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ...header,
          empty,
        ],
      );
    }

    if (primaryScroll) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          ...header,
          Expanded(
            child: ListView.builder(
              itemCount: accounts.length,
              itemBuilder: (BuildContext context, int index) {
                return _accountCard(context, accounts[index], t);
              },
            ),
          ),
          const SizedBox(height: 8),
          addAnother!,
        ],
      );
    }

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: <Widget>[
        ...header,
        for (final MailAccount account in accounts)
          _accountCard(context, account, t),
        const SizedBox(height: 8),
        addAnother!,
      ],
    );
  }
}
