// ==============================================================================
// File: lib/ui/search/search_sheet.dart
// Description: Local FTS search and remote-bridge trigger UI
// Component: UI
// Version: 1.2 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-23
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/density.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/common/empty_state.dart';
import 'package:synesis/ui/mailbox/mailbox_cubit.dart';
import 'package:synesis/sync/sync_engine.dart';

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
        child: SearchSheetBody(preferRemote: preferRemote),
      );
    },
  );
}

/// Local FTS + remote-bridge search body (UI-P22: results show [MailMessage.whenLabel]).
///
/// Public so it can be embedded or exercised directly in widget tests without
/// going through [showSearchSheet]'s modal route.
class SearchSheetBody extends StatefulWidget {
  const SearchSheetBody({super.key, this.preferRemote = false});

  final bool preferRemote;

  @override
  State<SearchSheetBody> createState() => _SearchSheetBodyState();
}

class _SearchSheetBodyState extends State<SearchSheetBody> {
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
            child: _results.isEmpty
                ? EmptyState(
                    title: _controller.text.trim().isEmpty
                        ? 'Search your mail'
                        : 'No matches',
                    subtitle: _controller.text.trim().isEmpty
                        ? 'Type to search locally, or queue a server search.'
                        : 'Try different words or search older mail on the server.',
                    icon: Icons.search_off_outlined,
                    density: ViewDensity.calm,
                  )
                : ListView.builder(
                    itemCount: _results.length,
                    itemBuilder: (BuildContext context, int index) {
                      final MailMessage msg = _results[index];
                      final ThemeTokens t = tokensOf(context);
                      return ListTile(
                        title: Text(
                          msg.subject,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${msg.fromName} · ${msg.snippet}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Text(
                          msg.whenLabel,
                          style: TextStyle(color: t.muted, fontSize: 12),
                        ),
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
