// ==============================================================================
// File: lib/ui/settings/focus_rules_sheet.dart
// Description: CRUD sheet for per-sender/domain Focus override rules (TC-4)
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/domain/address_match_scope.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/focus/focus_header_map.dart';
import 'package:bytemail/focus/focus_override_registry.dart';
import 'package:bytemail/focus/focus_sender.dart';
import 'package:bytemail/focus/mail_message_draft.dart';
import 'package:bytemail/focus/rule_based_focus_scorer.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';

/// Prefix used for global (account-independent) sender override rule ids.
const String kFocusGlobalSenderPrefix = 'sender:global:';

/// Prefix used for global (account-independent) domain override rule ids.
const String kFocusGlobalDomainPrefix = 'domain:global:';

Future<void> showFocusRulesSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: tokensOf(context).panel,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return const _FocusRulesSheet();
    },
  );
}

class _FocusRulesSheet extends StatefulWidget {
  const _FocusRulesSheet();

  @override
  State<_FocusRulesSheet> createState() => _FocusRulesSheetState();
}

class _FocusRulesSheetState extends State<_FocusRulesSheet> {
  List<FocusRule> _rules = const <FocusRule>[];
  bool _loading = true;
  bool _busy = false;
  String? _error;

  final TextEditingController _patternController = TextEditingController();
  AddressMatchScope _matchScope = AddressMatchScope.sender;
  FocusBucket _bucket = FocusBucket.focused;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _patternController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final MailRepository repository = context.read<MailRepository>();
    final List<FocusRule> rules = await repository.listFocusRules();
    if (!mounted) {
      return;
    }
    setState(() {
      _rules = rules;
      _loading = false;
    });
  }

  Future<void> _reclassify(MailRepository repository) async {
    final FocusOverrideRegistry overrides = FocusOverrideRegistry(
      rules: await repository.listFocusRules(),
    );
    await repository.reclassifyFocusBuckets((MailMessage message) {
      return RuleBasedFocusScorer(
        overrides: overrides,
        accountId: message.accountId,
      ).score(
        MailMessageDraft(
          fromAddress: message.fromAddress,
          subject: message.subject,
          headers: focusHeadersFromRaw(message.rawHeaders),
        ),
      );
    });
  }

  Future<void> _addRule() async {
    final String rawPattern = _patternController.text.trim();
    if (rawPattern.isEmpty) {
      setState(() => _error = 'Enter a sender address or domain.');
      return;
    }
    final MailRepository repository = context.read<MailRepository>();
    final String? accountId = _accountId;
    final bool isDomain = _matchScope == AddressMatchScope.domain;
    final String pattern = isDomain
        ? rawPattern.toLowerCase().replaceFirst(RegExp(r'^@'), '')
        : normalizeFocusSender(rawPattern);
    if (pattern.isEmpty) {
      setState(() => _error = 'Enter a sender address or domain.');
      return;
    }

    final String id = accountId == null
        ? '${isDomain ? kFocusGlobalDomainPrefix : kFocusGlobalSenderPrefix}$pattern'
        : isDomain
            ? focusDomainRuleId(accountId: accountId, domain: pattern)
            : focusSenderRuleId(accountId: accountId, sender: pattern);

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.upsertFocusRule(
        FocusRule(
          id: id,
          accountId: accountId,
          pattern: pattern,
          matchType: isDomain
              ? FocusRuleMatchType.domain
              : FocusRuleMatchType.sender,
          bucket: _bucket,
        ),
      );
      await _reclassify(repository);
      final List<FocusRule> rules = await repository.listFocusRules();
      if (!mounted) {
        return;
      }
      setState(() {
        _rules = rules;
        _busy = false;
        _patternController.clear();
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = 'Unable to save rule: $error';
      });
    }
  }

  Future<void> _deleteRule(FocusRule rule) async {
    final MailRepository repository = context.read<MailRepository>();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await repository.deleteFocusRule(rule.id);
      await _reclassify(repository);
      final List<FocusRule> rules = await repository.listFocusRules();
      if (!mounted) {
        return;
      }
      setState(() {
        _rules = rules;
        _busy = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = 'Unable to delete rule: $error';
      });
    }
  }

  String _accountLabel(String? accountId, List<MailAccount> accounts) {
    if (accountId == null) {
      return 'Global';
    }
    for (final MailAccount account in accounts) {
      if (account.id == accountId) {
        return account.address;
      }
    }
    return accountId;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final List<MailAccount> accounts =
        context.watch<MailboxCubit>().state.accounts;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Focus override rules',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Force senders or domains into Always Focused or Other, '
              'regardless of the automatic classifier.',
              style: TextStyle(color: t.muted, fontSize: 12),
            ),
            const SizedBox(height: 18),
            _AddRuleForm(
              patternController: _patternController,
              matchScope: _matchScope,
              bucket: _bucket,
              accountId: _accountId,
              accounts: accounts,
              busy: _busy,
              onMatchScopeChanged: (AddressMatchScope scope) =>
                  setState(() => _matchScope = scope),
              onBucketChanged: (FocusBucket bucket) =>
                  setState(() => _bucket = bucket),
              onAccountChanged: (String? accountId) =>
                  setState(() => _accountId = accountId),
              onSubmit: _addRule,
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: t.coral, fontSize: 12)),
            ],
            const SizedBox(height: 18),
            Text('Rules', style: TextStyle(color: t.muted, fontSize: 12)),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_rules.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No override rules yet.',
                  style: TextStyle(color: t.muted, fontSize: 13),
                ),
              )
            else
              for (final FocusRule rule in _rules)
                _FocusRuleTile(
                  rule: rule,
                  accountLabel: _accountLabel(rule.accountId, accounts),
                  busy: _busy,
                  onDelete: () => _deleteRule(rule),
                ),
          ],
        ),
      ),
    );
  }
}

class _AddRuleForm extends StatelessWidget {
  const _AddRuleForm({
    required this.patternController,
    required this.matchScope,
    required this.bucket,
    required this.accountId,
    required this.accounts,
    required this.busy,
    required this.onMatchScopeChanged,
    required this.onBucketChanged,
    required this.onAccountChanged,
    required this.onSubmit,
  });

  final TextEditingController patternController;
  final AddressMatchScope matchScope;
  final FocusBucket bucket;
  final String? accountId;
  final List<MailAccount> accounts;
  final bool busy;
  final ValueChanged<AddressMatchScope> onMatchScopeChanged;
  final ValueChanged<FocusBucket> onBucketChanged;
  final ValueChanged<String?> onAccountChanged;
  final Future<void> Function() onSubmit;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextField(
          controller: patternController,
          decoration: InputDecoration(
            labelText: matchScope == AddressMatchScope.domain
                ? 'Domain (e.g. example.com)'
                : 'Sender address (e.g. person@example.com)',
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            SegmentedButton<AddressMatchScope>(
              segments: const <ButtonSegment<AddressMatchScope>>[
                ButtonSegment<AddressMatchScope>(
                  value: AddressMatchScope.sender,
                  label: Text('Sender'),
                ),
                ButtonSegment<AddressMatchScope>(
                  value: AddressMatchScope.domain,
                  label: Text('Domain'),
                ),
              ],
              selected: <AddressMatchScope>{matchScope},
              onSelectionChanged: (Set<AddressMatchScope> value) =>
                  onMatchScopeChanged(value.first),
            ),
            SegmentedButton<FocusBucket>(
              segments: const <ButtonSegment<FocusBucket>>[
                ButtonSegment<FocusBucket>(
                  value: FocusBucket.focused,
                  label: Text('Always Focused'),
                ),
                ButtonSegment<FocusBucket>(
                  value: FocusBucket.other,
                  label: Text('Other'),
                ),
              ],
              selected: <FocusBucket>{bucket},
              onSelectionChanged: (Set<FocusBucket> value) =>
                  onBucketChanged(value.first),
            ),
          ],
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String?>(
          initialValue: accountId,
          decoration: const InputDecoration(
            labelText: 'Scope',
            border: OutlineInputBorder(),
          ),
          items: <DropdownMenuItem<String?>>[
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('Global (all accounts)'),
            ),
            for (final MailAccount account in accounts)
              DropdownMenuItem<String?>(
                value: account.id,
                child: Text(account.address),
              ),
          ],
          onChanged: onAccountChanged,
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: busy ? null : () => unawaited(onSubmit()),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add rule'),
        ),
        const SizedBox(height: 4),
        Divider(color: t.line),
      ],
    );
  }
}

class _FocusRuleTile extends StatelessWidget {
  const _FocusRuleTile({
    required this.rule,
    required this.accountLabel,
    required this.busy,
    required this.onDelete,
  });

  final FocusRule rule;
  final String accountLabel;
  final bool busy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final bool isFocused = rule.bucket == FocusBucket.focused;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isFocused
            ? Icons.center_focus_strong_outlined
            : Icons.filter_alt_outlined,
        color: isFocused ? t.amber : t.muted,
      ),
      title: Text(rule.pattern),
      subtitle: Text(
        '${rule.matchType == FocusRuleMatchType.domain ? "Domain" : "Sender"} '
        '· ${isFocused ? "Always Focused" : "Other"} · $accountLabel',
        style: TextStyle(color: t.muted, fontSize: 12),
      ),
      trailing: IconButton(
        tooltip: 'Delete rule',
        onPressed: busy ? null : onDelete,
        icon: Icon(Icons.delete_outline_rounded, color: t.coral),
      ),
    );
  }
}
