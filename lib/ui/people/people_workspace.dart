// ==============================================================================
// File: lib/ui/people/people_workspace.dart
// Description: People module UI — contact list/search/detail from local PIM.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-08-03
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/branding/synesis_wordmark.dart';
import 'package:synesis/ui/people/people_cubit.dart';
import 'package:synesis/ui/people/people_state.dart';
import 'package:synesis/ui/shell/mail_split_layout.dart';

/// People module UI (Wave 5 / V2.0c): lists contacts from
/// `isSelectedForDisplay` contact lists, local FTS search, and a read-only
/// detail pane. No CardDAV/Graph writes originate here in this wave.
class PeopleWorkspace extends StatefulWidget {
  const PeopleWorkspace({super.key});

  @override
  State<PeopleWorkspace> createState() => _PeopleWorkspaceState();
}

class _PeopleWorkspaceState extends State<PeopleWorkspace> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PeopleCubit, PeopleState>(
      builder: (BuildContext context, PeopleState state) {
        final ThemeTokens t = tokensOf(context);
        final PeopleCubit cubit = context.read<PeopleCubit>();
        final bool portraitMobile = isPortraitMobileLayout(context);
        final Contact? selected = state.selectedContact;
        return Scaffold(
          backgroundColor: t.ink,
          body: SafeArea(
            child: Column(
              children: <Widget>[
                _PeopleHeader(
                  searchController: _searchController,
                  state: state,
                  cubit: cubit,
                ),
                Expanded(
                  child: state.isLoading && state.contactLists.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : state.contactLists.isEmpty
                      ? _EmptyPeopleState(state: state)
                      : (portraitMobile
                            ? _PeopleListOnly(state: state, cubit: cubit)
                            : Row(
                                children: <Widget>[
                                  SizedBox(
                                    width: 320,
                                    child: _PeopleList(
                                      state: state,
                                      cubit: cubit,
                                    ),
                                  ),
                                  VerticalDivider(width: 1, color: t.line),
                                  Expanded(
                                    child: _ContactDetailPane(
                                      contact: selected,
                                      state: state,
                                    ),
                                  ),
                                ],
                              )),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _PeopleHeader extends StatelessWidget {
  const _PeopleHeader({
    required this.searchController,
    required this.state,
    required this.cubit,
  });

  final TextEditingController searchController;
  final PeopleState state;
  final PeopleCubit cubit;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            t.indigo.withValues(alpha: 0.18),
            t.teal.withValues(alpha: 0.08),
          ],
        ),
        border: Border(bottom: BorderSide(color: t.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const SynesisWordmark(fontSize: 15),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('/', style: TextStyle(color: t.muted)),
              ),
              Text('People', style: TextStyle(color: t.muted, fontSize: 13)),
              const Spacer(),
              IconButton(
                key: const Key('people_lists_button'),
                tooltip: 'Choose contact lists',
                onPressed: () => showContactListPickerSheet(
                  context,
                  cubit: cubit,
                ),
                icon: Icon(Icons.tune, color: t.muted, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            key: const Key('people_search_field'),
            controller: searchController,
            onChanged: cubit.setSearchQuery,
            decoration: InputDecoration(
              hintText: 'Search contacts…',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: state.searchQuery.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        searchController.clear();
                        cubit.setSearchQuery('');
                      },
                    ),
              isDense: true,
              filled: true,
              fillColor: t.panel2.withValues(alpha: 0.55),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: t.line),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPeopleState extends StatelessWidget {
  const _EmptyPeopleState({required this.state});

  final PeopleState state;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.people_outline_rounded, size: 40, color: t.muted),
            const SizedBox(height: 12),
            Text(
              'No contact lists yet. Sync a Graph or DAV account to get '
              'contacts here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: t.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _PeopleListOnly extends StatelessWidget {
  const _PeopleListOnly({required this.state, required this.cubit});

  final PeopleState state;
  final PeopleCubit cubit;

  @override
  Widget build(BuildContext context) {
    final Contact? selected = state.selectedContact;
    final ThemeTokens t = tokensOf(context);
    // Declarative nested stack: Back must pop a page. Swapping widgets via
    // selectedContact alone left the detail screen stuck (DEF-072).
    return Navigator(
      key: const Key('people_mobile_navigator'),
      pages: <Page<void>>[
        MaterialPage<void>(
          key: const ValueKey<String>('people-list'),
          child: Material(
            color: t.ink,
            child: _PeopleList(state: state, cubit: cubit),
          ),
        ),
        if (selected != null)
          MaterialPage<void>(
            key: ValueKey<String>('people-detail-${selected.id}'),
            child: _ContactDetailPage(
              contact: selected,
              state: state,
              cubit: cubit,
            ),
          ),
      ],
      onDidRemovePage: (Page<Object?> page) {
        if (page.key == const ValueKey<String>('people-list')) {
          return;
        }
        if (cubit.state.selectedContactId != null) {
          unawaited(cubit.selectContact(null));
        }
      },
    );
  }
}

class _ContactDetailPage extends StatelessWidget {
  const _ContactDetailPage({
    required this.contact,
    required this.state,
    required this.cubit,
  });

  final Contact contact;
  final PeopleState state;
  final PeopleCubit cubit;

  void _goBack() {
    // Pages are driven by selectedContactId — clearing rebuilds the nested
    // Navigator without the detail page (DEF-072).
    unawaited(cubit.selectContact(null));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return PopScope(
      canPop: cubit.state.selectedContactId == null,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          unawaited(cubit.selectContact(null));
        }
      },
      child: Material(
        color: t.ink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  key: const Key('people_back_to_contacts'),
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text('Back to contacts'),
                ),
              ),
            ),
            Expanded(child: _ContactDetailPane(contact: contact, state: state)),
          ],
        ),
      ),
    );
  }
}

class _PeopleList extends StatelessWidget {
  const _PeopleList({required this.state, required this.cubit});

  final PeopleState state;
  final PeopleCubit cubit;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final List<Contact> contacts = state.visibleContacts;
    if (contacts.isEmpty) {
      return Center(
        child: Text(
          state.isSearching ? 'No matching contacts.' : 'No contacts yet.',
          style: TextStyle(color: t.muted),
        ),
      );
    }
    return ListView.builder(
      key: const Key('people_contact_list'),
      itemCount: contacts.length,
      itemBuilder: (BuildContext context, int index) {
        final Contact contact = contacts[index];
        final bool selected = contact.id == state.selectedContactId;
        return ListTile(
          key: ValueKey<String>('people_contact_row_${contact.id}'),
          selected: selected,
          selectedTileColor: t.indigo.withValues(alpha: 0.14),
          leading: CircleAvatar(
            backgroundColor: t.indigo.withValues(alpha: 0.3),
            child: Text(
              contact.displayName.isEmpty
                  ? '?'
                  : contact.displayName[0].toUpperCase(),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(contact.displayName, overflow: TextOverflow.ellipsis),
          subtitle: contact.company == null
              ? null
              : Text(
                  contact.company!,
                  style: TextStyle(color: t.muted, fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
          onTap: () => cubit.selectContact(contact.id),
        );
      },
    );
  }
}

class _ContactDetailPane extends StatelessWidget {
  const _ContactDetailPane({required this.contact, required this.state});

  final Contact? contact;
  final PeopleState state;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final Contact? c = contact;
    if (c == null) {
      return Center(
        child: Text(
          'Select a contact to see details.',
          style: TextStyle(color: t.muted),
        ),
      );
    }
    return SingleChildScrollView(
      key: const Key('people_contact_detail'),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 28,
                backgroundColor: t.indigo.withValues(alpha: 0.3),
                child: Text(
                  c.displayName.isEmpty ? '?' : c.displayName[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontSize: 20),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      c.displayName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (c.company != null)
                      Text(c.company!, style: TextStyle(color: t.muted)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (state.selectedEmails.isNotEmpty) ...<Widget>[
            Text(
              'Email',
              style: TextStyle(
                color: t.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            for (final ContactEmail email in state.selectedEmails)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.email_outlined, size: 16, color: t.muted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(email.address)),
                    if (email.isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: t.teal.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Primary',
                          style: TextStyle(color: t.teal, fontSize: 10),
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
          ],
          if (state.selectedPhones.isNotEmpty) ...<Widget>[
            Text(
              'Phone',
              style: TextStyle(
                color: t.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            for (final ContactPhone phone in state.selectedPhones)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.phone_outlined, size: 16, color: t.muted),
                    const SizedBox(width: 8),
                    Text(phone.number),
                    const SizedBox(width: 6),
                    Text(
                      '(${phone.type})',
                      style: TextStyle(color: t.muted, fontSize: 11),
                    ),
                  ],
                ),
              ),
          ],
          if (c.notes != null && c.notes!.trim().isNotEmpty) ...<Widget>[
            const SizedBox(height: 12),
            Text(
              'Notes',
              style: TextStyle(
                color: t.muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(c.notes!),
          ],
        ],
      ),
    );
  }
}

/// Opens the checkbox picker sheet for contact-list display selection
/// ([DriftPimStore.setContactListDisplayPrefs]).
///
/// Listens to [PeopleCubit] so toggles rebuild after
/// [PeopleCubit.setContactListSelected] persists + refreshes (DEF-060).
Future<void> showContactListPickerSheet(
  BuildContext context, {
  required PeopleCubit cubit,
}) {
  final ThemeTokens t = tokensOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return BlocBuilder<PeopleCubit, PeopleState>(
        bloc: cubit,
        builder: (BuildContext context, PeopleState state) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Contact lists',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose which address books show contacts here and in the '
                  'compose picker.',
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      for (final ContactList list in state.contactLists)
                        SwitchListTile(
                          key: ValueKey<String>(
                            'contact_list_toggle_${list.id}',
                          ),
                          contentPadding: EdgeInsets.zero,
                          title: Text(list.name),
                          value: list.isSelectedForDisplay,
                          onChanged: (bool value) =>
                              cubit.setContactListSelected(list.id, value),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
