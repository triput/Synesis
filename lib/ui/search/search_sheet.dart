// ==============================================================================
// File: lib/ui/search/search_sheet.dart
// Description: Local FTS search and remote-bridge trigger UI
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
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/sync/sync_engine.dart';

Future<void> showSearchSheet(
  BuildContext context, {
  bool preferRemote = false,
}) {
  final t = tokensOf(context);
  return showModalBottomSheet<void>(
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
        child: _SearchSheetBody(preferRemote: preferRemote),
      );
    },
  );
}

class _SearchSheetBody extends StatefulWidget {
  const _SearchSheetBody({required this.preferRemote});

  final bool preferRemote;

  @override
  State<_SearchSheetBody> createState() => _SearchSheetBodyState();
}

class _SearchSheetBodyState extends State<_SearchSheetBody> {
  late final TextEditingController _controller = TextEditingController();
  List<MailMessage> _results = <MailMessage>[];
  int _searchGeneration = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onQueryChanged(String query) async {
    final int generation = ++_searchGeneration;
    final MailRepository repo = context.read<MailRepository>();
    final List<MailMessage> next = query.trim().isEmpty
        ? <MailMessage>[]
        : await repo.searchLocal(query.trim());
    if (!mounted || generation != _searchGeneration) {
      return;
    }
    setState(() => _results = next);
  }

  Future<void> _queueRemoteSearch() async {
    final MailboxCubit mailboxCubit = context.read<MailboxCubit>();
    final MailRepository repo = context.read<MailRepository>();
    final SyncEngine syncEngine = context.read<SyncEngine>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final mailbox = mailboxCubit.state;
    final String? accountId = mailbox.accountId ??
        (mailbox.accounts.isEmpty ? null : mailbox.accounts.first.id);
    if (accountId == null) {
      return;
    }
    await repo.enqueueSyncJob(
      accountId: accountId,
      type: 'remote_search',
      payloadJson: '{"query":${_jsonString(_controller.text.trim())}}',
    );
    await syncEngine.kick();
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Remote search queued for background sync'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.7,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.preferRemote ? 'Server search' : 'Search',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Search local mail (FTS5)…',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: _onQueryChanged,
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _queueRemoteSearch,
            child: const Text('Search older emails on the server'),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _results.length,
              itemBuilder: (BuildContext context, int index) {
                final MailMessage msg = _results[index];
                return ListTile(
                  title: Text(msg.subject),
                  subtitle: Text('${msg.fromName} · ${msg.snippet}'),
                  onTap: () {
                    context.read<MailboxCubit>().selectMessage(msg.id);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

String _jsonString(String value) =>
    '"${value.replaceAll(r'\', r'\\').replaceAll('"', r'\"')}"';
