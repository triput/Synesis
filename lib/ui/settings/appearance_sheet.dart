// ==============================================================================
// File: lib/ui/settings/appearance_sheet.dart
// Description: Appearance, density, Focus, retention, and desktop settings sheet
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-18
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/desktop/keyboard_intents.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/sync/retention_service.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/ui/account/manage_accounts_sheet.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/ui/settings/custom_theme_editor_sheet.dart';
import 'package:bytemail/ui/settings/db_encryption_sheet.dart';
import 'package:bytemail/ui/settings/focus_rules_sheet.dart';
import 'package:bytemail/ui/settings/settings_export_import_controls.dart';
import 'package:bytemail/ui/settings/sync_storage_sheet.dart';
import 'package:bytemail/ui/settings/ui_font_settings_section.dart';

Future<void> showAppearanceSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: tokensOf(context).panel,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) {
      return BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (context, settings) {
          final t = tokensOf(context);
          final accounts = context.watch<MailboxCubit>().state.accounts;
          final cubit = context.read<AppSettingsCubit>();
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Appearance & view',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 18),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Manage accounts'),
                    subtitle: Text(
                      'Edit labels, re-authenticate, or remove accounts',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showManageAccountsSheet(context),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Sync & storage'),
                    subtitle: Text(
                      'Default retention, body policy, attachment max',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showSyncStorageSheet(context),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Encryption'),
                    subtitle: Text(
                      'Opt-in passphrase encryption for the local mailbox',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showDbEncryptionSheet(context),
                  ),
                  const SizedBox(height: 8),
                  Text('Theme', style: TextStyle(color: t.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final id in ThemeId.values)
                        ChoiceChip(
                          label: Text(id.label),
                          selected: settings.customThemeId == null &&
                              settings.themeId == id,
                          onSelected: (_) => cubit.setTheme(id),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const CustomThemesSection(),
                  const SizedBox(height: 18),
                  const UiFontSettingsSection(),
                  const SizedBox(height: 18),
                  const SettingsExportImportControls(),
                  const SizedBox(height: 18),
                  Text('Density', style: TextStyle(color: t.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  SegmentedButton<ViewDensity>(
                    segments: const [
                      ButtonSegment(
                        value: ViewDensity.calm,
                        label: Text('Calm'),
                      ),
                      ButtonSegment(
                        value: ViewDensity.compact,
                        label: Text('Compact'),
                      ),
                    ],
                    selected: {settings.density},
                    onSelectionChanged: (value) =>
                        cubit.setDensity(value.first),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Reading pane',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<ReadingPanePosition>(
                    segments: const [
                      ButtonSegment(
                        value: ReadingPanePosition.right,
                        label: Text('Right'),
                        icon: Icon(Icons.view_sidebar_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: ReadingPanePosition.bottom,
                        label: Text('Bottom'),
                        icon: Icon(Icons.vertical_split_outlined, size: 16),
                      ),
                      ButtonSegment(
                        value: ReadingPanePosition.top,
                        label: Text('Top'),
                        icon: Icon(Icons.horizontal_split_outlined, size: 16),
                      ),
                    ],
                    selected: {settings.readingPanePosition},
                    onSelectionChanged: (Set<ReadingPanePosition> value) =>
                        cubit.setReadingPanePosition(value.first),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Visual Focus'),
                    subtitle: Text(
                      'Collapse sidebar and list to maximize reading '
                      '(Ctrl+Shift+M). Distinct from Focused/Other filter.',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    value: settings.visualFocusEnabled,
                    onChanged: cubit.setVisualFocusEnabled,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Retention (days)',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  Slider(
                    value: settings.retentionDays.toDouble(),
                    min: 14,
                    max: 365,
                    divisions: 26,
                    label: '${settings.retentionDays}',
                    onChanged: (v) => cubit.setRetentionDays(v.round()),
                    onChangeEnd: (v) async {
                      final int days = v.round();
                      await cubit.setRetentionDays(days);
                      if (!context.mounted) {
                        return;
                      }
                      final RetentionService retention =
                          context.read<RetentionService>();
                      await retention.applyDeviceRetentionDial(days: days);
                      if (!context.mounted) {
                        return;
                      }
                      await context.read<SyncEngine>().kick();
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Empty trash after (days)',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  Slider(
                    value: settings.trashRetentionDays
                        .clamp(7, 90)
                        .toDouble(),
                    min: 7,
                    max: 90,
                    divisions: 83,
                    label: '${settings.trashRetentionDays}',
                    onChanged: (v) => cubit.setTrashRetentionDays(v.round()),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Conversation view'),
                    subtitle: Text(
                      'Group replies into expandable threads',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    value:
                        settings.threadDisplayMode == ThreadDisplayMode.threaded,
                    onChanged: (bool enabled) => cubit.setThreadDisplayMode(
                      enabled
                          ? ThreadDisplayMode.threaded
                          : ThreadDisplayMode.flat,
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Block remote images'),
                    subtitle: Text(
                      'Privacy-first: hide http(s) images in HTML mail until '
                      'you load them for a message. Inline cid/data images still show.',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    value: settings.blockRemoteImages,
                    onChanged: cubit.setBlockRemoteImages,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Android swipe actions',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  _SwipeActionDropdown(
                    label: 'Swipe right',
                    value: settings.swipeRightAction,
                    onChanged: cubit.setSwipeRightAction,
                    muted: t.muted,
                  ),
                  _SwipeActionDropdown(
                    label: 'Swipe left',
                    value: settings.swipeLeftAction,
                    onChanged: cubit.setSwipeLeftAction,
                    muted: t.muted,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Unified Inbox · Focused/Other'),
                    subtitle: Text(
                      'Independent of per-account Focus settings',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    value: settings.unifiedFocusEnabled,
                    onChanged: cubit.setUnifiedFocusEnabled,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Focus override rules'),
                    subtitle: Text(
                      'Always classify a sender or domain as Focused or Other',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => showFocusRulesSheet(context),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Minimize to tray (Windows)'),
                    value: settings.minimizeToTray,
                    onChanged: cubit.setMinimizeToTray,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Keyboard shortcuts'),
                    subtitle: Text(
                      ByteMailKeyboardShortcuts.helpLabel,
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    value: settings.keyboardShortcutsEnabled,
                    onChanged: cubit.setKeyboardShortcutsEnabled,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Per-account Focus',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  for (final MailAccount account in accounts)
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(account.address),
                      value: settings.isAccountFocusEnabled(account.id),
                      onChanged: (v) =>
                          cubit.setAccountFocusEnabled(account.id, v),
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

class _SwipeActionDropdown extends StatelessWidget {
  const _SwipeActionDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.muted,
  });

  final String label;
  final SwipeListAction value;
  final Future<void> Function(SwipeListAction) onChanged;
  final Color muted;

  static String _labelFor(SwipeListAction action) {
    return switch (action) {
      SwipeListAction.archive => 'Archive',
      SwipeListAction.delete => 'Delete',
      SwipeListAction.star => 'Star',
      SwipeListAction.snooze => 'Snooze',
      SwipeListAction.none => 'None',
    };
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(
        'Message list gesture',
        style: TextStyle(color: muted, fontSize: 12),
      ),
      trailing: DropdownButton<SwipeListAction>(
        value: value,
        underline: const SizedBox.shrink(),
        items: <DropdownMenuItem<SwipeListAction>>[
          for (final SwipeListAction action in SwipeListAction.values)
            DropdownMenuItem<SwipeListAction>(
              value: action,
              child: Text(_labelFor(action)),
            ),
        ],
        onChanged: (SwipeListAction? next) {
          if (next != null) {
            onChanged(next);
          }
        },
      ),
    );
  }
}
