// ==============================================================================
// File: lib/ui/pim/pim_copy_target_sheet.dart
// Description: Wave 6 mobile "Copy to…" target picker for events and contacts.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-08-04
// Last Update: 2026-08-04
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/sync/pim_copy_service.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/calendar/calendar_cubit.dart';
import 'package:synesis/ui/calendar/calendar_state.dart';
import 'package:synesis/ui/people/people_cubit.dart';
import 'package:synesis/ui/people/people_state.dart';
import 'package:synesis/ui/pim/pim_copy_ui.dart';

/// Subtitle when the target account cannot enqueue remote create on copy.
const String kPimCopyLocalOnlySubtitle = 'Local only — not synced yet';

String _accountLabelFor(List<MailAccount> accounts, String accountId) {
  for (final MailAccount account in accounts) {
    if (account.id == accountId) {
      return account.label.isNotEmpty ? account.label : account.address;
    }
  }
  return accountId;
}

/// Opens the bottom sheet listing copy targets for [sourceEvent].
Future<void> showEventCopyTargetSheet(
  BuildContext context, {
  required CalendarEvent sourceEvent,
  required CalendarCubit cubit,
  required CalendarState state,
  required PimCopyService copyService,
}) async {
  final ThemeTokens t = tokensOf(context);
  final List<Calendar> targets = state.calendars
      .where((Calendar calendar) => calendar.id != sourceEvent.calendarId)
      .toList(growable: false);
  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No other calendars to copy to.')),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return _EventCopyTargetSheetBody(
        sourceEvent: sourceEvent,
        cubit: cubit,
        state: state,
        copyService: copyService,
        targets: targets,
      );
    },
  );
}

/// Mobile long-press fallback: pick account + contact list, then copy via cubit.
Future<void> showContactCopyTargetSheet(
  BuildContext context, {
  required Contact sourceContact,
  required PeopleCubit cubit,
  required PeopleState state,
  required PimCopyService copyService,
}) async {
  final ThemeTokens t = tokensOf(context);
  final List<ContactList> targets = state.contactLists
      .where((ContactList list) => list.id != sourceContact.contactListId)
      .toList(growable: false);
  if (targets.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No other contact lists to copy to.')),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (BuildContext sheetContext) {
      return _ContactCopyTargetSheetBody(
        sourceContact: sourceContact,
        cubit: cubit,
        state: state,
        copyService: copyService,
        targets: targets,
      );
    },
  );
}

class _EventCopyTargetSheetBody extends StatefulWidget {
  const _EventCopyTargetSheetBody({
    required this.sourceEvent,
    required this.cubit,
    required this.state,
    required this.copyService,
    required this.targets,
  });

  final CalendarEvent sourceEvent;
  final CalendarCubit cubit;
  final CalendarState state;
  final PimCopyService copyService;
  final List<Calendar> targets;

  @override
  State<_EventCopyTargetSheetBody> createState() =>
      _EventCopyTargetSheetBodyState();
}

class _EventCopyTargetSheetBodyState extends State<_EventCopyTargetSheetBody> {
  Map<String, bool>? _remotePushByAccount;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRemotePushFlags());
  }

  Future<void> _loadRemotePushFlags() async {
    final Set<String> accountIds = widget.targets
        .map((Calendar calendar) => calendar.accountId)
        .toSet();
    final Map<String, bool> flags = <String, bool>{};
    for (final String accountId in accountIds) {
      flags[accountId] = await widget.copyService.remotePushSupportedForAccount(
        accountId,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() => _remotePushByAccount = flags);
  }

  Future<void> _copyTo(Calendar calendar) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final PimCopyResult<CalendarEvent> result = await widget.cubit
          .copyEventToCalendar(
            sourceEventId: widget.sourceEvent.id,
            targetAccountId: calendar.accountId,
            targetCalendarId: calendar.id,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      showEventCopyResultSnackBar(
        context: context,
        calendarName: calendar.name,
        result: result,
        onUndo: widget.cubit.deleteEvent,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copy failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final Map<String, List<Calendar>> byAccount = <String, List<Calendar>>{};
    for (final Calendar calendar in widget.targets) {
      byAccount
          .putIfAbsent(calendar.accountId, () => <Calendar>[])
          .add(calendar);
    }
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Copy to calendar…',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                widget.sourceEvent.title,
                style: TextStyle(color: t.muted, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (_remotePushByAccount == null)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      for (final MapEntry<String, List<Calendar>> entry
                          in byAccount.entries) ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 2),
                          child: Text(
                            _accountLabelFor(widget.state.accounts, entry.key),
                            style: TextStyle(
                              color: t.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        for (final Calendar calendar in entry.value)
                          ListTile(
                            key: ValueKey<String>(
                              'event_copy_target_${calendar.id}',
                            ),
                            contentPadding: EdgeInsets.zero,
                            enabled: !_busy,
                            leading: Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(calendar.effectiveColorArgb),
                                shape: BoxShape.circle,
                              ),
                            ),
                            title: Text(calendar.name),
                            subtitle:
                                _remotePushByAccount![calendar.accountId] ==
                                    true
                                ? null
                                : Text(
                                    kPimCopyLocalOnlySubtitle,
                                    style: TextStyle(
                                      color: t.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                            onTap: () => unawaited(_copyTo(calendar)),
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ContactCopyTargetSheetBody extends StatefulWidget {
  const _ContactCopyTargetSheetBody({
    required this.sourceContact,
    required this.cubit,
    required this.state,
    required this.copyService,
    required this.targets,
  });

  final Contact sourceContact;
  final PeopleCubit cubit;
  final PeopleState state;
  final PimCopyService copyService;
  final List<ContactList> targets;

  @override
  State<_ContactCopyTargetSheetBody> createState() =>
      _ContactCopyTargetSheetBodyState();
}

class _ContactCopyTargetSheetBodyState
    extends State<_ContactCopyTargetSheetBody> {
  Map<String, bool>? _remotePushByAccount;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadRemotePushFlags());
  }

  Future<void> _loadRemotePushFlags() async {
    final Set<String> accountIds = widget.targets
        .map((ContactList list) => list.accountId)
        .toSet();
    final Map<String, bool> flags = <String, bool>{};
    for (final String accountId in accountIds) {
      flags[accountId] = await widget.copyService.remotePushSupportedForAccount(
        accountId,
      );
    }
    if (!mounted) {
      return;
    }
    setState(() => _remotePushByAccount = flags);
  }

  Future<void> _copyTo(ContactList list) async {
    if (_busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final PimCopyResult<Contact> result = await widget.cubit.copyContactToList(
        sourceContactId: widget.sourceContact.id,
        targetAccountId: list.accountId,
        targetContactListId: list.id,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      showContactCopyResultSnackBar(
        context: context,
        listName: list.name,
        result: result,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Copy failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final Map<String, List<ContactList>> byAccount =
        <String, List<ContactList>>{};
    for (final ContactList list in widget.targets) {
      byAccount.putIfAbsent(list.accountId, () => <ContactList>[]).add(list);
    }
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: SizedBox(
        height: maxHeight,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Copy to list…',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                widget.sourceContact.displayName,
                style: TextStyle(color: t.muted, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              if (_remotePushByAccount == null)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: ListView(
                    children: <Widget>[
                      for (final MapEntry<String, List<ContactList>> entry
                          in byAccount.entries) ...<Widget>[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 2),
                          child: Text(
                            _accountLabelFor(widget.state.accounts, entry.key),
                            style: TextStyle(
                              color: t.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        for (final ContactList list in entry.value)
                          ListTile(
                            key: ValueKey<String>(
                              'contact_copy_target_${list.id}',
                            ),
                            contentPadding: EdgeInsets.zero,
                            enabled: !_busy,
                            leading: Icon(
                              Icons.contacts_outlined,
                              color: t.muted,
                              size: 20,
                            ),
                            title: Text(list.name),
                            subtitle:
                                _remotePushByAccount![list.accountId] == true
                                ? null
                                : Text(
                                    kPimCopyLocalOnlySubtitle,
                                    style: TextStyle(
                                      color: t.muted,
                                      fontSize: 11,
                                    ),
                                  ),
                            onTap: () => unawaited(_copyTo(list)),
                          ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
