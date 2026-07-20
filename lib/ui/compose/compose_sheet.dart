// ==============================================================================
// File: lib/ui/compose/compose_sheet.dart
// Description: Unified ComposeDraft sheet — BCC, attach, signature, schedule, drafts.
// Component: UI
// Version: 2.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';
import 'dart:convert';

import 'package:bytemail/compose/account_signature.dart';
import 'package:bytemail/compose/outgoing_message_builder.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/outbox/send_error_messages.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/compose/compose_draft.dart';
import 'package:bytemail/ui/compose/compose_prefill.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> showComposeSheet(
  BuildContext context, {
  ComposePrefill? prefill,
  ComposeDraft? draft,
  OutboxItem? resumeOutbox,
}) async {
  final mailbox = context.read<MailboxCubit>().state;
  final List<MailAccount> accounts = mailbox.accounts;
  if (accounts.isEmpty) {
    return;
  }

  ComposeDraft initial;
  if (draft != null) {
    initial = draft;
  } else if (resumeOutbox != null) {
    initial = _draftFromOutbox(resumeOutbox);
  } else if (prefill != null) {
    initial = ComposeDraft.fromPrefill(prefill);
  } else {
    initial = ComposeDraft.newMessage(
      mailbox.accountId ?? accounts.first.id,
    );
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
          initial: initial,
        ),
      );
    },
  );
}

ComposeDraft _draftFromOutbox(OutboxItem item) {
  ComposeMode mode = ComposeMode.newMessage;
  switch (item.composeMode) {
    case 'reply':
      mode = ComposeMode.reply;
    case 'replyAll':
      mode = ComposeMode.replyAll;
    case 'forward':
      mode = ComposeMode.forward;
    default:
      mode = ComposeMode.newMessage;
  }
  final List<LocalAttachmentRef> attachments = <LocalAttachmentRef>[];
  final String? refs = item.attachmentRefsJson;
  if (refs != null && refs.trim().isNotEmpty) {
    try {
      final Object? decoded = jsonDecodeSafe(refs);
      if (decoded is List<Object?>) {
        for (final Object? e in decoded) {
          if (e is Map) {
            attachments.add(
              LocalAttachmentRef.fromJson(Map<String, Object?>.from(e)),
            );
          }
        }
      }
    } on FormatException {
      // ignore
    }
  }
  return ComposeDraft(
    mode: mode,
    accountId: item.accountId,
    to: splitOutboxRecipients(item.to),
    cc: splitOutboxRecipients(item.cc),
    bcc: splitOutboxRecipients(item.bcc),
    subject: item.subject,
    bodyPlain: OutgoingMessageBuilder.unpackPlain(item.body),
    bodyHtml: () {
      const String marker = '\n---bytemail-html---\n';
      final int idx = item.body.indexOf(marker);
      if (idx < 0) {
        return null;
      }
      return item.body.substring(idx + marker.length);
    }(),
    inReplyTo: item.inReplyTo,
    signatureId: item.signatureId,
    attachments: attachments,
    outboxDraftId: item.id,
    sendAfterMs: item.sendAfter,
  );
}

Object? jsonDecodeSafe(String raw) => jsonDecode(raw);

class _ComposeSheetBody extends StatefulWidget {
  const _ComposeSheetBody({
    required this.accounts,
    required this.mailboxAccountId,
    required this.initial,
  });

  final List<MailAccount> accounts;
  final String? mailboxAccountId;
  final ComposeDraft initial;

  @override
  State<_ComposeSheetBody> createState() => _ComposeSheetBodyState();
}

class _ComposeSheetBodyState extends State<_ComposeSheetBody> {
  late final TextEditingController _toController;
  late final TextEditingController _ccController;
  late final TextEditingController _bccController;
  late final TextEditingController _subjectController;
  late final TextEditingController _bodyController;
  late String _accountId;
  late final bool _lockAccount;
  late List<LocalAttachmentRef> _attachments;
  String? _signatureId;
  String? _outboxDraftId;
  int? _sendAfterMs;
  bool _showCcBcc = false;
  String? _recipientError;
  String? _sendError;
  bool _busy = false;
  bool _attaching = false;
  List<MailSignature> _signatures = const <MailSignature>[];
  List<MailTemplate> _templates = const <MailTemplate>[];
  Timer? _autosaveTimer;

  @override
  void initState() {
    super.initState();
    final ComposeDraft initial = widget.initial;
    _lockAccount = initial.mode != ComposeMode.newMessage;
    if (widget.accounts.any((MailAccount a) => a.id == initial.accountId)) {
      _accountId = initial.accountId;
    } else {
      _accountId = widget.mailboxAccountId ?? widget.accounts.first.id;
    }
    _toController = TextEditingController(text: initial.to.join(', '));
    _ccController = TextEditingController(text: initial.cc.join(', '));
    _bccController = TextEditingController(text: initial.bcc.join(', '));
    _subjectController = TextEditingController(text: initial.subject);
    final String packedHtml = initial.bodyHtml ?? '';
    _bodyController = TextEditingController(
      text: initial.bodyPlain.isNotEmpty
          ? initial.bodyPlain
          : (packedHtml.isNotEmpty ? _stripHtmlLite(packedHtml) : ''),
    );
    _attachments = List<LocalAttachmentRef>.from(initial.attachments);
    _signatureId = initial.signatureId;
    _outboxDraftId = initial.outboxDraftId;
    _sendAfterMs = initial.sendAfterMs;
    _showCcBcc = initial.cc.isNotEmpty || initial.bcc.isNotEmpty;
    _bodyController.addListener(_scheduleAutosave);
    _toController.addListener(_scheduleAutosave);
    _subjectController.addListener(_scheduleAutosave);
    unawaited(_loadComposeAssets());
  }

  @override
  void dispose() {
    _autosaveTimer?.cancel();
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _loadComposeAssets() async {
    final MailRepository repo = context.read<MailRepository>();
    final List<MailSignature> sigs = await repo.listSignatures(_accountId);
    final List<MailTemplate> templates =
        await repo.listTemplates(accountId: _accountId);
    if (!mounted) {
      return;
    }
    setState(() {
      _signatures = sigs;
      _templates = templates;
      if (_signatureId == null) {
        for (final MailSignature s in sigs) {
          if (s.isDefault) {
            _signatureId = s.id;
            break;
          }
        }
      }
    });
  }

  void _scheduleAutosave() {
    _autosaveTimer?.cancel();
    _autosaveTimer = Timer(const Duration(seconds: 2), () {
      unawaited(_autosaveDraft());
    });
  }

  Future<void> _autosaveDraft() async {
    if (!mounted || _busy) {
      return;
    }
    final MailRepository repo = context.read<MailRepository>();
    final String body = OutgoingMessageBuilder.packBody(
      plain: _bodyController.text,
      html: _bodyHtmlFromPlain(_bodyController.text),
    );
        final String? attachJson = _attachments.isEmpty
        ? null
        : jsonEncode(
            _attachments.map((LocalAttachmentRef a) => a.toJson()).toList(),
          );
    try {
      if (_outboxDraftId == null) {
        final String id = await repo.enqueueOutbox(
          accountId: _accountId,
          to: _toController.text.trim(),
          subject: _subjectController.text.trim(),
          body: body,
          cc: _ccController.text.trim().isEmpty
              ? null
              : _ccController.text.trim(),
          bcc: _bccController.text.trim().isEmpty
              ? null
              : _bccController.text.trim(),
          composeMode: widget.initial.composeModeValue,
          inReplyTo: widget.initial.inReplyTo,
          referencesJson: widget.initial.referencesJson,
          attachmentRefsJson: attachJson,
          signatureId: _signatureId,
          sendAfter: _sendAfterMs,
          state: 'draft',
        );
        if (mounted) {
          setState(() => _outboxDraftId = id);
        }
      } else {
        await repo.updateOutboxContent(
          _outboxDraftId!,
          to: _toController.text.trim(),
          subject: _subjectController.text.trim(),
          body: body,
          cc: _ccController.text.trim(),
          bcc: _bccController.text.trim(),
          attachmentRefsJson: attachJson,
          signatureId: _signatureId,
          sendAfter: _sendAfterMs,
          clearSendAfter: _sendAfterMs == null,
        );
        await repo.updateOutboxState(_outboxDraftId!, 'draft');
      }
    } on Object {
      // Autosave is best-effort.
    }
  }

  Future<void> _pickAttachments() async {
    if (_attaching) {
      return;
    }
    setState(() => _attaching = true);
    try {
      final MailRepository repo = context.read<MailRepository>();
      final ResolvedSyncPolicy policy = await repo.resolvePolicy(_accountId);
      final int capBytes = policy.attachmentMaxMb * 1024 * 1024;
      final FilePickerResult? result = await FilePicker.pickFiles(
        allowMultiple: true,
        withData: false,
      );
      if (result == null) {
        return;
      }
      final List<LocalAttachmentRef> next =
          List<LocalAttachmentRef>.from(_attachments);
      int total = next.fold<int>(
        0,
        (int sum, LocalAttachmentRef a) => sum + a.sizeBytes,
      );
      for (final PlatformFile file in result.files) {
        final String? path = file.path;
        if (path == null) {
          continue;
        }
        final int size = file.size;
        if (total + size > capBytes) {
          if (mounted) {
            setState(() {
              _sendError =
                  'Attachments exceed the ${policy.attachmentMaxMb} MB cap.';
            });
          }
          break;
        }
        final OutboundBlobRef blob = await repo.stageAttachmentBlob(
          accountId: _accountId,
          sourcePath: path,
          fileName: file.name,
        );
        next.add(
          LocalAttachmentRef(
            blobId: blob.id,
            fileName: file.name,
            sizeBytes: blob.sizeBytes,
          ),
        );
        total += blob.sizeBytes;
      }
      if (mounted) {
        setState(() => _attachments = next);
        _scheduleAutosave();
      }
    } on Object catch (error) {
      if (mounted) {
        setState(() => _sendError = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _attaching = false);
      }
    }
  }

  Future<void> _queueSend({bool scheduleOnly = false}) async {
    if (_busy) {
      return;
    }
    final List<String> toList = splitOutboxRecipients(_toController.text);
    final List<String> ccList = splitOutboxRecipients(_ccController.text);
    final List<String> bccList = splitOutboxRecipients(_bccController.text);
    if (toList.isEmpty && ccList.isEmpty && bccList.isEmpty) {
      setState(() {
        _recipientError = 'Add at least one To, Cc, or Bcc recipient.';
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

    final ResolvedSyncPolicy policy = await repo.resolvePolicy(_accountId);
    final int capBytes = policy.attachmentMaxMb * 1024 * 1024;
    final int totalAttach = _attachments.fold<int>(
      0,
      (int sum, LocalAttachmentRef a) => sum + a.sizeBytes,
    );
    if (totalAttach > capBytes) {
      setState(() {
        _busy = false;
        _sendError =
            'Attachments exceed the ${policy.attachmentMaxMb} MB cap.';
      });
      return;
    }

    final String body = OutgoingMessageBuilder.packBody(
      plain: _bodyController.text,
      html: _bodyHtmlFromPlain(_bodyController.text),
    );
        final String? attachJson = _attachments.isEmpty
        ? null
        : jsonEncode(
            _attachments.map((LocalAttachmentRef a) => a.toJson()).toList(),
          );
    final int? sendAfter = scheduleOnly ? _sendAfterMs : _sendAfterMs;

    try {
      String outboxId;
      if (_outboxDraftId != null) {
        outboxId = _outboxDraftId!;
        await repo.updateOutboxContent(
          outboxId,
          to: _toController.text.trim(),
          subject: _subjectController.text.trim(),
          body: body,
          cc: _ccController.text.trim(),
          bcc: _bccController.text.trim(),
          composeMode: widget.initial.composeModeValue,
          inReplyTo: widget.initial.inReplyTo,
          referencesJson: widget.initial.referencesJson,
          attachmentRefsJson: attachJson,
          signatureId: _signatureId,
          sendAfter: sendAfter,
          clearSendAfter: sendAfter == null,
        );
        await repo.updateOutboxState(outboxId, 'queued');
      } else {
        outboxId = await repo.enqueueOutbox(
          accountId: _accountId,
          to: _toController.text.trim(),
          subject: _subjectController.text.trim(),
          body: body,
          cc: _ccController.text.trim().isEmpty
              ? null
              : _ccController.text.trim(),
          bcc: _bccController.text.trim().isEmpty
              ? null
              : _bccController.text.trim(),
          composeMode: widget.initial.composeModeValue,
          inReplyTo: widget.initial.inReplyTo,
          referencesJson: widget.initial.referencesJson,
          attachmentRefsJson: attachJson,
          signatureId: _signatureId,
          sendAfter: sendAfter,
        );
      }
      await repo.enqueueSyncJob(
        accountId: _accountId,
        type: 'send_outbox',
      );
      await mailboxCubit.refresh();

      final bool delayed =
          sendAfter != null && sendAfter > DateTime.now().millisecondsSinceEpoch;
      if (delayed) {
        if (!mounted) {
          return;
        }
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(content: Text('Message scheduled')),
        );
        return;
      }

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
      setState(() {
        _sendError =
            'Send has not finished yet. Tap Sync in the mailbox, or try '
            'Send again. If it keeps failing, check SMTP settings for '
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

  Future<void> _pickSchedule() async {
    final DateTime now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) {
      return;
    }
    final TimeOfDay? time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (time == null || !mounted) {
      return;
    }
    final DateTime when = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() => _sendAfterMs = when.millisecondsSinceEpoch);
    _scheduleAutosave();
  }

  void _insertTemplate(MailTemplate template) {
    final String plain = _stripHtmlLite(template.bodyHtml);
    if (_subjectController.text.trim().isEmpty &&
        template.subject.trim().isNotEmpty) {
      _subjectController.text = template.subject;
    }
    final String existing = _bodyController.text;
    _bodyController.text = existing.isEmpty ? plain : '$plain\n\n$existing';
    _scheduleAutosave();
  }

  void _wrapSelection(String prefix, String suffix) {
    final TextSelection sel = _bodyController.selection;
    final String text = _bodyController.text;
    if (!sel.isValid) {
      _bodyController.text = '$prefix$text$suffix';
      return;
    }
    final String selected = sel.textInside(text);
    final String next =
        sel.textBefore(text) + prefix + selected + suffix + sel.textAfter(text);
    _bodyController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(
        offset: sel.start + prefix.length + selected.length + suffix.length,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            _composeTitle(widget.initial.mode),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _accountId,
            items: <DropdownMenuItem<String>>[
              for (final MailAccount a in widget.accounts)
                DropdownMenuItem<String>(value: a.id, child: Text(a.address)),
            ],
            onChanged: _lockAccount
                ? null
                : (String? value) {
                    if (value != null) {
                      setState(() => _accountId = value);
                      unawaited(_loadComposeAssets());
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
              suffixIcon: IconButton(
                tooltip: _showCcBcc ? 'Hide Cc/Bcc' : 'Show Cc/Bcc',
                onPressed: () => setState(() => _showCcBcc = !_showCcBcc),
                icon: Icon(
                  _showCcBcc ? Icons.expand_less : Icons.expand_more,
                  color: t.muted,
                ),
              ),
            ),
          ),
          if (_showCcBcc) ...<Widget>[
            TextField(
              controller: _ccController,
              style: TextStyle(color: t.text),
              decoration: _fieldDecoration(t, labelText: 'Cc'),
            ),
            TextField(
              controller: _bccController,
              style: TextStyle(color: t.text),
              decoration: _fieldDecoration(t, labelText: 'Bcc'),
            ),
          ],
          TextField(
            controller: _subjectController,
            style: TextStyle(color: t.text),
            decoration: _fieldDecoration(t, labelText: 'Subject'),
          ),
          Row(
            children: <Widget>[
              IconButton(
                tooltip: 'Bold',
                onPressed: () => _wrapSelection('**', '**'),
                icon: Icon(Icons.format_bold, color: t.muted),
              ),
              IconButton(
                tooltip: 'Italic',
                onPressed: () => _wrapSelection('_', '_'),
                icon: Icon(Icons.format_italic, color: t.muted),
              ),
              IconButton(
                tooltip: 'Link',
                onPressed: () => _wrapSelection('[', '](https://)'),
                icon: Icon(Icons.link, color: t.muted),
              ),
              IconButton(
                tooltip: 'Attach',
                onPressed: _attaching ? null : _pickAttachments,
                icon: Icon(
                  Icons.attach_file,
                  color: _attaching ? t.muted : t.teal,
                ),
              ),
              if (_templates.isNotEmpty)
                PopupMenuButton<MailTemplate>(
                  tooltip: 'Insert template',
                  icon: Icon(Icons.article_outlined, color: t.muted),
                  onSelected: _insertTemplate,
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<MailTemplate>>[
                    for (final MailTemplate tpl in _templates)
                      PopupMenuItem<MailTemplate>(
                        value: tpl,
                        child: Text(tpl.name),
                      ),
                  ],
                ),
              const Spacer(),
              TextButton.icon(
                onPressed: _pickSchedule,
                icon: Icon(Icons.schedule, size: 18, color: t.teal),
                label: Text(
                  _sendAfterMs == null
                      ? 'Schedule'
                      : _formatSendAfter(_sendAfterMs!),
                  style: TextStyle(color: t.teal),
                ),
              ),
              if (_sendAfterMs != null)
                IconButton(
                  tooltip: 'Clear schedule',
                  onPressed: () {
                    setState(() => _sendAfterMs = null);
                    _scheduleAutosave();
                  },
                  icon: Icon(Icons.clear, color: t.muted, size: 18),
                ),
            ],
          ),
          if (_signatures.isNotEmpty)
            DropdownButtonFormField<String?>(
              initialValue: _signatureId,
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('No signature'),
                ),
                for (final MailSignature s in _signatures)
                  DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text(s.name),
                  ),
              ],
              onChanged: (String? value) {
                setState(() => _signatureId = value);
                _scheduleAutosave();
              },
              decoration: _fieldDecoration(t, labelText: 'Signature'),
            ),
          if (_attachments.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: <Widget>[
                for (final LocalAttachmentRef a in _attachments)
                  InputChip(
                    label: Text(
                      '${a.fileName} (${_formatBytes(a.sizeBytes)})',
                    ),
                    onDeleted: () {
                      setState(() {
                        _attachments = _attachments
                            .where(
                              (LocalAttachmentRef x) => x.blobId != a.blobId,
                            )
                            .toList(growable: false);
                      });
                      unawaited(
                        context.read<MailRepository>().deleteAttachmentBlob(
                              a.blobId,
                            ),
                      );
                      _scheduleAutosave();
                    },
                  ),
              ],
            ),
          TextField(
            controller: _bodyController,
            minLines: 6,
            maxLines: 14,
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
          Row(
            children: <Widget>[
              OutlinedButton(
                onPressed: _busy
                    ? null
                    : () async {
                        await _autosaveDraft();
                        if (mounted) {
                          Navigator.pop(context);
                        }
                      },
                child: const Text('Save draft'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _busy ? null : () => _queueSend(),
                child: Text(
                  _busy
                      ? 'Sending…'
                      : (_sendAfterMs != null ? 'Schedule send' : 'Send'),
                ),
              ),
            ],
          ),
        ],
      ),
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
  Widget? suffixIcon,
}) {
  final Color secondaryText = Color.lerp(t.muted, t.text, 0.28)!;
  return InputDecoration(
    labelText: labelText,
    labelStyle: TextStyle(color: secondaryText),
    floatingLabelStyle: TextStyle(color: t.teal),
    errorText: errorText,
    suffixIcon: suffixIcon,
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

String _bodyHtmlFromPlain(String plain) {
  String html = plain
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
  html = html.replaceAllMapped(
    RegExp(r'\*\*(.+?)\*\*'),
    (Match m) => '<strong>${m[1]}</strong>',
  );
  html = html.replaceAllMapped(
    RegExp(r'_(.+?)_'),
    (Match m) => '<em>${m[1]}</em>',
  );
  html = html.replaceAllMapped(
    RegExp(r'\[(.+?)\]\((https?:\/\/[^\s)]+)\)'),
    (Match m) => '<a href="${m[2]}">${m[1]}</a>',
  );
  html = html.replaceAll('\n', '<br>');
  return '<div style="font-family:$kOutboundFontFamily;font-size:14px;">'
      '$html</div>';
}

String _stripHtmlLite(String raw) {
  return raw
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]*>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>');
}

String _formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  if (bytes < 1024 * 1024) {
    return '${(bytes / 1024).toStringAsFixed(1)} KB';
  }
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

String _formatSendAfter(int ms) {
  final DateTime when = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${when.month}/${when.day} ${when.hour.toString().padLeft(2, '0')}:'
      '${when.minute.toString().padLeft(2, '0')}';
}
