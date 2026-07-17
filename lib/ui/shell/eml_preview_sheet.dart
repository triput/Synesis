// ==============================================================================
// File: lib/ui/shell/eml_preview_sheet.dart
// Description: Local-only preview sheet for opened RFC 822 message files.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/mime/eml_codec.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/ui/shell/reading_pane.dart';
import 'package:flutter/material.dart';

Future<void> showEmlPreviewSheet(
  BuildContext context, {
  required EmlPreview preview,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (BuildContext context) => FractionallySizedBox(
      heightFactor: 0.92,
      child: _EmlPreviewContent(preview: preview),
    ),
  );
}

class _EmlPreviewContent extends StatelessWidget {
  const _EmlPreviewContent({required this.preview});

  final EmlPreview preview;

  @override
  Widget build(BuildContext context) {
    final MailAccount localAccount = MailAccount(
      id: 'local-eml',
      label: 'Local EML',
      address: preview.fromAddress,
      accent: tokensOf(context).indigo,
    );
    final MailMessage message = MailMessage(
      id: 'local-eml-preview',
      accountId: localAccount.id,
      fromName: preview.fromName,
      fromAddress: preview.fromAddress,
      subject: preview.subject,
      snippet: preview.body,
      body: preview.body,
      whenLabel: preview.sentAt?.toLocal().toString() ?? 'Local file',
      rawHeaders: preview.rawHeaders,
      bucket: FocusBucket.other,
    );
    return Scaffold(
      appBar: AppBar(
        title: const Text('EML preview'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
      body: ReadingPane(
        message: message,
        accounts: <MailAccount>[localAccount],
        density: ViewDensity.calm,
      ),
    );
  }
}
