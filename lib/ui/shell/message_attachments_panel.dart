// ==============================================================================
// File: lib/ui/shell/message_attachments_panel.dart
// Description: Inbound attachment list/download + quick-reply strip for reading pane.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';
import 'dart:io';

import 'package:bytemail/compose/outgoing_message_builder.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/compose/compose_prefill.dart';
import 'package:bytemail/ui/compose/compose_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Lists remote attachments for [message] and offers save-to-downloads.
class MessageAttachmentsPanel extends StatefulWidget {
  const MessageAttachmentsPanel({super.key, required this.message});

  final MailMessage message;

  @override
  State<MessageAttachmentsPanel> createState() =>
      _MessageAttachmentsPanelState();
}

class _MessageAttachmentsPanelState extends State<MessageAttachmentsPanel> {
  List<MailAttachmentMeta>? _items;
  String? _error;
  bool _loading = false;
  String? _busyPartId;

  @override
  void initState() {
    super.initState();
    if (widget.message.hasAttachments) {
      unawaited(_load());
    }
  }

  @override
  void didUpdateWidget(covariant MessageAttachmentsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message.id != widget.message.id) {
      _items = null;
      _error = null;
      if (widget.message.hasAttachments) {
        unawaited(_load());
      }
    }
  }

  Future<void> _load() async {
    final String? providerId = widget.message.providerId;
    if (providerId == null || providerId.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final MailProvider? provider = await context
          .read<SyncEngine>()
          .resolveMailProvider(widget.message.accountId);
      if (provider == null) {
        throw const ProtocolException('Mail provider unavailable.');
      }
      final List<MailAttachmentMeta> items =
          await provider.listAttachments(providerId);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
        _loading = false;
      });
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _download(MailAttachmentMeta meta) async {
    final String? providerId = widget.message.providerId;
    if (providerId == null) {
      return;
    }
    setState(() => _busyPartId = meta.partId);
    try {
      final MailProvider? provider = await context
          .read<SyncEngine>()
          .resolveMailProvider(widget.message.accountId);
      if (provider == null) {
        throw const ProtocolException('Mail provider unavailable.');
      }
      final MailAttachmentBytes bytes =
          await provider.fetchAttachment(providerId, meta.partId);
      final Directory dir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
      final String name = meta.name.trim().isEmpty ? 'attachment' : meta.name;
      final File out = File(p.join(dir.path, name));
      await out.writeAsBytes(bytes.bytes, flush: true);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${out.path}')),
      );
    } on Object catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() => _busyPartId = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.message.hasAttachments) {
      return const SizedBox.shrink();
    }
    final ThemeTokens t = tokensOf(context);
    if (_loading && _items == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text('Loading attachments…', style: TextStyle(color: t.muted)),
      );
    }
    if (_error != null && (_items == null || _items!.isEmpty)) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(_error!, style: TextStyle(color: t.coral)),
      );
    }
    final List<MailAttachmentMeta> items = _items ?? const <MailAttachmentMeta>[];
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Attachments',
            style: TextStyle(
              color: t.muted,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: <Widget>[
              for (final MailAttachmentMeta meta in items)
                ActionChip(
                  avatar: _busyPartId == meta.partId
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.attach_file, size: 16, color: t.teal),
                  label: Text(meta.name.isEmpty ? meta.partId : meta.name),
                  onPressed:
                      _busyPartId == null ? () => unawaited(_download(meta)) : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Minimal quick-reply strip that queues a plain reply via outbox.
class QuickReplyBar extends StatefulWidget {
  const QuickReplyBar({super.key, required this.message});

  final MailMessage message;

  @override
  State<QuickReplyBar> createState() => _QuickReplyBarState();
}

class _QuickReplyBarState extends State<QuickReplyBar> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final String text = _controller.text.trim();
    if (text.isEmpty || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final MailRepository repo = context.read<MailRepository>();
      final SyncEngine sync = context.read<SyncEngine>();
      final ComposePrefill prefill = ComposePrefill.reply(widget.message);
      final String body = OutgoingMessageBuilder.packBody(plain: text);
      await repo.enqueueOutbox(
        accountId: widget.message.accountId,
        to: prefill.to.join(', '),
        subject: prefill.subject,
        body: body,
        composeMode: 'reply',
        inReplyTo: prefill.inReplyTo,
        referencesJson: prefill.referencesJson,
      );
      await repo.enqueueSyncJob(
        accountId: widget.message.accountId,
        type: 'send_outbox',
      );
      unawaited(sync.kick());
      _controller.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply queued')),
        );
      }
    } on Object catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Quick reply failed: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: _controller,
              minLines: 1,
              maxLines: 3,
              style: TextStyle(color: t.text),
              decoration: InputDecoration(
                hintText: 'Quick reply…',
                hintStyle: TextStyle(color: t.muted),
                isDense: true,
                filled: true,
                fillColor: t.panel2.withValues(alpha: 0.55),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: t.line),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Open full compose',
            onPressed: () {
              unawaited(
                showComposeSheet(
                  context,
                  prefill: ComposePrefill.reply(widget.message),
                ),
              );
            },
            icon: Icon(Icons.open_in_full, color: t.muted),
          ),
          FilledButton(
            onPressed: _busy ? null : () => unawaited(_send()),
            child: Text(_busy ? '…' : 'Send'),
          ),
        ],
      ),
    );
  }
}
