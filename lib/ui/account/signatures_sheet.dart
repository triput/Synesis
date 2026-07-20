// ==============================================================================
// File: lib/ui/account/signatures_sheet.dart
// Description: CRUD UI for per-account HTML/plain signatures and image assets.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/compose/account_signature.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

Future<void> showSignaturesSheet(
  BuildContext context,
  MailAccount account,
) async {
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
        child: _SignaturesBody(account: account),
      );
    },
  );
}

class _SignaturesBody extends StatefulWidget {
  const _SignaturesBody({required this.account});

  final MailAccount account;

  @override
  State<_SignaturesBody> createState() => _SignaturesBodyState();
}

class _SignaturesBodyState extends State<_SignaturesBody> {
  List<MailSignature> _items = const <MailSignature>[];
  bool _loading = true;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final List<MailSignature> items =
        await context.read<MailRepository>().listSignatures(widget.account.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _edit([MailSignature? existing]) async {
    final TextEditingController name = TextEditingController(
      text: existing?.name ?? '',
    );
    final TextEditingController plain = TextEditingController(
      text: existing?.bodyPlain ?? '',
    );
    final TextEditingController html = TextEditingController(
      text: existing?.bodyHtml ?? '',
    );
    bool isDefault = existing?.isDefault ?? _items.isEmpty;
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, void Function(void Function()) setLocal) {
            return AlertDialog(
              title: Text(existing == null ? 'New signature' : 'Edit signature'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    TextField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: plain,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Plain text'),
                    ),
                    TextField(
                      controller: html,
                      minLines: 2,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        labelText: 'HTML (optional)',
                      ),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Default for this account'),
                      value: isDefault,
                      onChanged: (bool v) => setLocal(() => isDefault = v),
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    if (saved != true || !mounted) {
      return;
    }
    final MailSignature next = MailSignature(
      id: existing?.id ?? _uuid.v4(),
      accountId: widget.account.id,
      name: name.text.trim().isEmpty ? 'Signature' : name.text.trim(),
      bodyPlain: plain.text,
      bodyHtml: html.text.trim().isEmpty ? null : html.text.trim(),
      isDefault: isDefault,
      sortOrder: existing?.sortOrder ?? _items.length,
    );
    await context.read<MailRepository>().upsertSignature(next);
    await _reload();
  }

  Future<void> _addImage(MailSignature signature) async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: false,
    );
    final String? path = result?.files.single.path;
    if (path == null) {
      return;
    }
    final String name = result!.files.single.name.toLowerCase();
    final String mime = name.endsWith('.png')
        ? 'image/png'
        : name.endsWith('.gif')
            ? 'image/gif'
            : 'image/jpeg';
    await context.read<MailRepository>().addSignatureAsset(
          signatureId: signature.id,
          sourcePath: path,
          mimeType: mime,
        );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Signature image added (embedded on send)'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Signatures — ${widget.account.address}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Add signature'),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_items.isEmpty)
            Expanded(
              child: Text(
                'No signatures yet. Add one to append on compose/send.',
                style: TextStyle(color: t.muted),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => Divider(color: t.line),
                itemBuilder: (BuildContext context, int index) {
                  final MailSignature s = _items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      s.name + (s.isDefault ? ' (default)' : ''),
                      style: TextStyle(color: t.text),
                    ),
                    subtitle: Text(
                      s.bodyPlain,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: t.muted),
                    ),
                    trailing: Wrap(
                      children: <Widget>[
                        IconButton(
                          tooltip: 'Add image',
                          onPressed: () => _addImage(s),
                          icon: Icon(Icons.image, color: t.teal),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => _edit(s),
                          icon: Icon(Icons.edit, color: t.muted),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () async {
                            await context
                                .read<MailRepository>()
                                .deleteSignature(s.id);
                            await _reload();
                          },
                          icon: Icon(Icons.delete_outline, color: t.coral),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
