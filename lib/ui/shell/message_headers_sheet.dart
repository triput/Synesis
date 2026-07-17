// ==============================================================================
// File: lib/ui/shell/message_headers_sheet.dart
// Description: Message details sheet with parsed fields and raw header block
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/ui/mailbox/mailbox_state.dart';

Future<void> showMessageHeadersSheet(
  BuildContext context, {
  required MailMessage message,
}) async {
  final MailboxCubit cubit = context.read<MailboxCubit>();
  unawaited(cubit.ensureHeadersCached(message.id));

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: tokensOf(context).panel,
    showDragHandle: true,
    builder: (sheetContext) {
      return BlocBuilder<MailboxCubit, MailboxState>(
        builder: (context, mailbox) {
          MailMessage current = message;
          for (final MailMessage m in mailbox.messages) {
            if (m.id == message.id) {
              current = m;
              break;
            }
          }
          MailAccount? account;
          for (final MailAccount a in mailbox.accounts) {
            if (a.id == current.accountId) {
              account = a;
              break;
            }
          }
          MailFolder? folder;
          if (current.folderId != null) {
            for (final MailFolder f in mailbox.folders) {
              if (f.id == current.folderId) {
                folder = f;
                break;
              }
            }
          }
          final t = tokensOf(context);
          final String? to = parseRawHeaderValue(current.rawHeaders, 'to');
          final String? cc = parseRawHeaderValue(current.rawHeaders, 'cc');
          final String dateLabel = _formatDate(current);

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 8,
              bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(sheetContext).height * 0.72,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Message details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _DetailRow(
                            label: 'From',
                            value:
                                '${current.fromName} <${current.fromAddress}>',
                            muted: t.muted,
                          ),
                          if (to != null)
                            _DetailRow(label: 'To', value: to, muted: t.muted),
                          if (cc != null)
                            _DetailRow(label: 'Cc', value: cc, muted: t.muted),
                          _DetailRow(
                            label: 'Subject',
                            value: current.subject,
                            muted: t.muted,
                          ),
                          _DetailRow(
                            label: 'Date',
                            value: dateLabel,
                            muted: t.muted,
                          ),
                          if (current.messageIdHeader != null &&
                              current.messageIdHeader!.isNotEmpty)
                            _DetailRow(
                              label: 'Message-ID',
                              value: current.messageIdHeader!,
                              muted: t.muted,
                              monospace: true,
                            ),
                          if (account != null)
                            _DetailRow(
                              label: 'Account',
                              value: account.address,
                              muted: t.muted,
                            ),
                          if (folder != null)
                            _DetailRow(
                              label: 'Folder',
                              value: folder.name,
                              muted: t.muted,
                            ),
                          const SizedBox(height: 18),
                          Text(
                            'Raw headers',
                            style: TextStyle(
                              color: t.muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (mailbox.isLoadingHeaders &&
                              (current.rawHeaders == null ||
                                  current.rawHeaders!.trim().isEmpty))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: t.teal,
                                  ),
                                ),
                              ),
                            )
                          else if (mailbox.headersErrorMessage != null &&
                              (current.rawHeaders == null ||
                                  current.rawHeaders!.trim().isEmpty))
                            Text(
                              mailbox.headersErrorMessage!,
                              style: TextStyle(color: t.coral, fontSize: 13),
                            )
                          else if (current.rawHeaders != null &&
                              current.rawHeaders!.trim().isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: t.ink.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: t.line),
                              ),
                              child: SelectableText(
                                current.rawHeaders!,
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  height: 1.45,
                                  color: t.text,
                                ),
                              ),
                            )
                          else
                            Text(
                              'Raw headers are not cached locally. Connect a '
                              'linked account to fetch them on demand.',
                              style: TextStyle(color: t.muted, fontSize: 13),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.muted,
    this.monospace = false,
  });

  final String label;
  final String value;
  final Color muted;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            value,
            style: TextStyle(
              color: t.text,
              fontSize: 13,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ],
      ),
    );
  }
}

String? parseRawHeaderValue(String? rawHeaders, String name) {
  if (rawHeaders == null || rawHeaders.trim().isEmpty) {
    return null;
  }
  final String target = name.toLowerCase();
  final StringBuffer value = StringBuffer();
  var collecting = false;
  for (final String line in rawHeaders.split('\n')) {
    if (line.isEmpty) {
      continue;
    }
    if (line.startsWith(' ') || line.startsWith('\t')) {
      if (collecting) {
        value.write(' ${line.trim()}');
      }
      continue;
    }
    final int colon = line.indexOf(':');
    if (colon <= 0) {
      collecting = false;
      continue;
    }
    final String headerName = line.substring(0, colon).trim().toLowerCase();
    if (headerName == target) {
      collecting = true;
      value
        ..clear()
        ..write(line.substring(colon + 1).trim());
      continue;
    }
    if (collecting) {
      break;
    }
  }
  final String text = value.toString().trim();
  return text.isEmpty ? null : text;
}

String _formatDate(MailMessage message) {
  final int? epochMs = message.whenEpochMs;
  if (epochMs != null) {
    final DateTime time = DateTime.fromMillisecondsSinceEpoch(epochMs);
    return time.toLocal().toString();
  }
  return message.whenLabel;
}
