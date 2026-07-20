// ==============================================================================
// File: lib/ui/account/templates_sheet.dart
// Description: CRUD UI for canned response templates (TB-13).
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
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

Future<void> showTemplatesSheet(
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
        child: _TemplatesBody(account: account),
      );
    },
  );
}

class _TemplatesBody extends StatefulWidget {
  const _TemplatesBody({required this.account});

  final MailAccount account;

  @override
  State<_TemplatesBody> createState() => _TemplatesBodyState();
}

class _TemplatesBodyState extends State<_TemplatesBody> {
  List<MailTemplate> _items = const <MailTemplate>[];
  bool _loading = true;
  final Uuid _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final List<MailTemplate> items = await context
        .read<MailRepository>()
        .listTemplates(accountId: widget.account.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  Future<void> _edit([MailTemplate? existing]) async {
    final TextEditingController name =
        TextEditingController(text: existing?.name ?? '');
    final TextEditingController subject =
        TextEditingController(text: existing?.subject ?? '');
    final TextEditingController body =
        TextEditingController(text: existing?.bodyHtml ?? '');
    final bool? saved = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(existing == null ? 'New template' : 'Edit template'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                TextField(
                  controller: subject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
                TextField(
                  controller: body,
                  minLines: 3,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'Body (HTML/text)'),
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
    if (saved != true || !mounted) {
      return;
    }
    await context.read<MailRepository>().upsertTemplate(
          MailTemplate(
            id: existing?.id ?? _uuid.v4(),
            accountId: widget.account.id,
            name: name.text.trim().isEmpty ? 'Template' : name.text.trim(),
            subject: subject.text.trim(),
            bodyHtml: body.text,
            sortOrder: existing?.sortOrder ?? _items.length,
          ),
        );
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Templates — ${widget.account.address}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.icon(
              onPressed: () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('Add template'),
            ),
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_items.isEmpty)
            Expanded(
              child: Text(
                'No templates yet. Add canned responses for compose.',
                style: TextStyle(color: t.muted),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => Divider(color: t.line),
                itemBuilder: (BuildContext context, int index) {
                  final MailTemplate tpl = _items[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(tpl.name, style: TextStyle(color: t.text)),
                    subtitle: Text(
                      tpl.subject,
                      style: TextStyle(color: t.muted),
                    ),
                    trailing: Wrap(
                      children: <Widget>[
                        IconButton(
                          onPressed: () => _edit(tpl),
                          icon: Icon(Icons.edit, color: t.muted),
                        ),
                        IconButton(
                          onPressed: () async {
                            await context
                                .read<MailRepository>()
                                .deleteTemplate(tpl.id);
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
