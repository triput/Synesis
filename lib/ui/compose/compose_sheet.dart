// ==============================================================================
// File: lib/ui/compose/compose_sheet.dart
// Description: Compose sheet; message body fill uses ThemeTokens.content
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/outbox/send_error_messages.dart';
import 'package:bytemail/ui/compose/compose_prefill.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/sync/sync_engine.dart';

Future<void> showComposeSheet(
  BuildContext context, {
  ComposePrefill? prefill,
}) async {
  final mailbox = context.read<MailboxCubit>().state;
  final List<MailAccount> accounts = mailbox.accounts;
  if (accounts.isEmpty) {
    return;
  }

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
        child: _ComposeSheetBody(
          accounts: accounts,
          mailboxAccountId: mailbox.accountId,
          prefill: prefill,
        ),
      );
    },
  );
}

class _ComposeSheetBody extends StatefulWidget {
  const _ComposeSheetBody({
    required this.accounts,
    required this.mailboxAccountId,
    this.prefill,
  });

  final List<MailAccount> accounts;
  final String? mailboxAccountId;
  final ComposePrefill? prefill;

  @override
  State<_ComposeSheetBody> createState() => _ComposeSheetBodyState();
}

class _ComposeSheetBodyState extends State<_ComposeSheetBody> {
  late final TextEditingController _toController;
  late final TextEditingController _ccController;
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  late String _accountId;
  late final bool _lockAccount;
  String? _recipientError;
  String? _sendError;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final ComposePrefill? prefill = widget.prefill;
    _lockAccount = prefill != null;
    if (prefill != null &&
        widget.accounts.any((MailAccount a) => a.id == prefill.accountId)) {
      _accountId = prefill.accountId;
    } else {
      _accountId = widget.mailboxAccountId ?? widget.accounts.first.id;
    }
    _toController = TextEditingController(text: prefill?.to.join(', ') ?? '');
    _ccController = TextEditingController(text: prefill?.cc.join(', ') ?? '');
    _subjectController = TextEditingController(text: prefill?.subject ?? '');
    _bodyController = TextEditingController(text: prefill?.body ?? '');
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _queueSend() async {
    if (_busy) {
      return;
    }
    final List<String> toList = splitOutboxRecipients(_toController.text);
    final List<String> ccList = splitOutboxRecipients(_ccController.text);
    if (toList.isEmpty && ccList.isEmpty) {
      setState(() {
        _recipientError = 'Add at least one To or Cc recipient.';
        _sendError = null;
      });
      return;
    }
    setState(() {
      _recipientError = null;
      _sendError = null;
      _busy = true;
    });

    final MailRepository repo = context.read<MailRepository>();
    final MailboxCubit mailboxCubit = context.read<MailboxCubit>();
    final SyncEngine syncEngine = context.read<SyncEngine>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String accountLabel = () {
      for (final MailAccount a in widget.accounts) {
        if (a.id == _accountId) {
          return a.address;
        }
      }
      return _accountId;
    }();
    final String to = _toController.text.trim();
    final String cc = _ccController.text.trim();
    final String composeMode = widget.prefill?.composeModeValue ?? 'new';
    try {
      final String outboxId = await repo.enqueueOutbox(
        accountId: _accountId,
        to: to,
        subject: _subjectController.text.trim(),
        body: _bodyController.text,
        cc: cc.isEmpty ? null : cc,
        composeMode: composeMode,
        inReplyTo: widget.prefill?.inReplyTo,
        referencesJson: widget.prefill?.referencesJson,
      );
      await repo.enqueueSyncJob(
        accountId: _accountId,
        type: 'send_outbox',
      );
      await mailboxCubit.refresh();
      final OutboxItem? item = await _awaitOutboxOutcome(
        repo: repo,
        syncEngine: syncEngine,
        outboxId: outboxId,
      );
      if (!mounted) {
        return;
      }
      await mailboxCubit.refresh();
      if (item?.state == 'sent') {
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Message sent')),
        );
        return;
      }
      if (item?.state == 'failed') {
        setState(() {
          _sendError = actionableSendError(
            item!.lastError,
            accountHint: accountLabel,
          );
        });
        return;
      }
      // Still queued/sending after wait — stay open with guidance.
      setState(() {
        _sendError =
            'Send has not finished yet. Tap Sync in the mailbox, or try '
            'Queue send again. If it keeps failing, check SMTP settings for '
            '$accountLabel.';
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _sendError = actionableSendError(error, accountHint: accountLabel);
      });
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Drives sync until [outboxId] is `sent`/`failed`, or the wait budget ends.
  Future<OutboxItem?> _awaitOutboxOutcome({
    required MailRepository repo,
    required SyncEngine syncEngine,
    required String outboxId,
  }) async {
    const Duration budget = Duration(seconds: 45);
    final DateTime deadline = DateTime.now().add(budget);
    OutboxItem? latest;
    while (DateTime.now().isBefore(deadline)) {
      await syncEngine.kick();
      latest = await _findOutbox(repo, outboxId);
      if (latest == null ||
          latest.state == 'sent' ||
          latest.state == 'failed') {
        return latest;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    return latest ?? await _findOutbox(repo, outboxId);
  }

  Future<OutboxItem?> _findOutbox(MailRepository repo, String outboxId) async {
    final List<OutboxItem> outbox = await repo.listOutbox();
    for (final OutboxItem entry in outbox) {
      if (entry.id == outboxId) {
        return entry;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _composeTitle(widget.prefill?.mode),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _accountId,
          items: [
            for (final MailAccount a in widget.accounts)
              DropdownMenuItem<String>(value: a.id, child: Text(a.address)),
          ],
          onChanged: _lockAccount
              ? null
              : (String? value) {
                  if (value != null) {
                    setState(() => _accountId = value);
                  }
                },
          decoration: _fieldDecoration(t, labelText: 'From'),
        ),
        TextField(
          controller: _toController,
          style: TextStyle(color: t.text),
          onChanged: (_) {
            if (_recipientError != null) {
              setState(() => _recipientError = null);
            }
          },
          decoration: _fieldDecoration(
            t,
            labelText: 'To',
            errorText: _recipientError,
          ),
        ),
        TextField(
          controller: _ccController,
          style: TextStyle(color: t.text),
          onChanged: (_) {
            if (_recipientError != null) {
              setState(() => _recipientError = null);
            }
          },
          decoration: _fieldDecoration(t, labelText: 'Cc'),
        ),
        TextField(
          controller: _subjectController,
          style: TextStyle(color: t.text),
          decoration: _fieldDecoration(t, labelText: 'Subject'),
        ),
        TextField(
          controller: _bodyController,
          minLines: 4,
          maxLines: 8,
          style: TextStyle(color: t.text),
          cursorColor: t.teal,
          decoration: _bodyDecoration(t),
        ),
        if (_sendError != null) ...<Widget>[
          const SizedBox(height: 12),
          Material(
            color: t.coral.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Icon(Icons.error_outline, color: t.coral, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _sendError!,
                      style: TextStyle(color: t.text, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _queueSend,
          child: Text(_busy ? 'Sending…' : 'Send'),
        ),
      ],
    );
  }
}

String _composeTitle(ComposeMode? mode) {
  switch (mode) {
    case ComposeMode.reply:
      return 'Reply';
    case ComposeMode.replyAll:
      return 'Reply all';
    case ComposeMode.forward:
      return 'Forward';
    case ComposeMode.newMessage:
    case null:
      return 'Compose';
  }
}

InputDecoration _fieldDecoration(
  ThemeTokens t, {
  required String labelText,
  String? errorText,
}) {
  final Color secondaryText = Color.lerp(t.muted, t.text, 0.28)!;
  return InputDecoration(
    labelText: labelText,
    labelStyle: TextStyle(color: secondaryText),
    floatingLabelStyle: TextStyle(color: t.teal),
    errorText: errorText,
    filled: true,
    fillColor: t.panel2.withValues(alpha: 0.55),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: t.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: t.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: t.teal, width: 1.4),
    ),
  );
}

InputDecoration _bodyDecoration(ThemeTokens t) {
  final Color secondaryText = Color.lerp(t.muted, t.text, 0.28)!;
  return InputDecoration(
    labelText: 'Message',
    labelStyle: TextStyle(color: secondaryText),
    floatingLabelStyle: TextStyle(color: t.teal),
    hintText: 'Write your message…',
    hintStyle: TextStyle(color: secondaryText),
    filled: true,
    fillColor: t.content,
    alignLabelWithHint: true,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: t.line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: t.line),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: t.teal, width: 1.4),
    ),
  );
}
