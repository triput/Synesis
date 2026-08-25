// ==============================================================================
// File: lib/ui/settings/settings_sections.dart
// Description: UI-P21 functional-area section bodies for the Settings shell
// Component: UI
// Version: 1.2 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-07-27
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synesis/desktop/keyboard_intents.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/settings/app_settings_cubit.dart';
import 'package:synesis/settings/app_settings_state.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/density.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/account/manage_accounts_sheet.dart';
import 'package:synesis/ui/mailbox/mailbox_cubit.dart';
import 'package:synesis/ui/mailbox/mailbox_state.dart';
import 'package:synesis/ui/settings/custom_theme_editor_sheet.dart';
import 'package:synesis/ui/settings/db_encryption_sheet.dart';
import 'package:synesis/ui/settings/focus_rules_sheet.dart';
import 'package:synesis/ui/settings/notifications_sheet.dart';
import 'package:synesis/ui/settings/settings_catalog.dart';
import 'package:synesis/ui/settings/settings_export_import_controls.dart';
import 'package:synesis/ui/settings/sync_storage_sheet.dart';
import 'package:synesis/ui/settings/ui_font_settings_section.dart';

/// Soft-coded product name/version shown on the Advanced / About section.
///
/// `package_info_plus` is not a project dependency, so per V1.5 Wave B scope
/// this stays a plain constant rather than introducing a new plugin just for
/// a version string. Bump alongside `pubspec.yaml`'s `version:` field.
const String kSynesisProductName = 'synesis';

/// Mirrors `pubspec.yaml` `version: 0.1.0+1` — update together.
const String kSynesisProductVersion = '0.1.0 (build 1) · V1.5';

/// Small section heading shared by every UI-P21 section body.
class SettingsSectionHeading extends StatelessWidget {
  const SettingsSectionHeading({
    super.key,
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final String? sub = subtitle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        if (sub != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(sub, style: TextStyle(color: t.muted, fontSize: 12)),
        ],
        const SizedBox(height: 18),
      ],
    );
  }
}

/// 1. Accounts — list/edit/remove mail accounts (UI-P21).
///
/// [ManageAccountsSheetBody] already renders its own "Manage accounts"
/// heading + subtitle, so this section embeds it directly rather than
/// duplicating a [SettingsSectionHeading] above it.
class AccountsSettingsSection extends StatelessWidget {
  const AccountsSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const ManageAccountsSheetBody();
  }
}

/// 2. Appearance — visual-only: themes, custom themes, fonts, density.
class AppearanceSettingsSection extends StatelessWidget {
  const AppearanceSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (BuildContext context, AppSettingsState settings) {
        final ThemeTokens t = tokensOf(context);
        final AppSettingsCubit cubit = context.read<AppSettingsCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SettingsSectionHeading(
              title: 'Appearance',
              subtitle: 'Themes, fonts, and layout density.',
            ),
            Text('Theme', style: TextStyle(color: t.muted, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final ThemeId id in ThemeId.values)
                  ChoiceChip(
                    label: Text(id.label),
                    selected:
                        settings.customThemeId == null &&
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
            Text('Density', style: TextStyle(color: t.muted, fontSize: 12)),
            const SizedBox(height: 8),
            SegmentedButton<ViewDensity>(
              segments: const <ButtonSegment<ViewDensity>>[
                ButtonSegment<ViewDensity>(
                  value: ViewDensity.calm,
                  label: Text('Calm'),
                ),
                ButtonSegment<ViewDensity>(
                  value: ViewDensity.compact,
                  label: Text('Compact'),
                ),
              ],
              selected: <ViewDensity>{settings.density},
              onSelectionChanged: (Set<ViewDensity> value) =>
                  cubit.setDensity(value.first),
            ),
            const SizedBox(height: 18),
            Text(
              'Calendar view',
              style: TextStyle(color: t.muted, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              'How events from multiple selected calendars are laid out '
              'in the Calendar module.',
              style: TextStyle(color: t.muted, fontSize: 11),
            ),
            const SizedBox(height: 8),
            SegmentedButton<CalendarViewMode>(
              key: const Key('settings_calendar_view_mode'),
              segments: const <ButtonSegment<CalendarViewMode>>[
                ButtonSegment<CalendarViewMode>(
                  value: CalendarViewMode.overlay,
                  label: Text('Overlay'),
                ),
                ButtonSegment<CalendarViewMode>(
                  value: CalendarViewMode.sideBySide,
                  label: Text('Side-by-side'),
                ),
              ],
              selected: <CalendarViewMode>{settings.calendarViewMode},
              onSelectionChanged: (Set<CalendarViewMode> value) =>
                  cubit.setCalendarViewMode(value.first),
            ),
          ],
        );
      },
    );
  }
}

/// 3. Reading & message list — reading pane, Focus, swipe, auto-mark, etc.
class ReadingMessageListSettingsSection extends StatelessWidget {
  const ReadingMessageListSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (BuildContext context, AppSettingsState settings) {
        final ThemeTokens t = tokensOf(context);
        final AppSettingsCubit cubit = context.read<AppSettingsCubit>();
        final List<MailAccount> accounts = context
            .watch<MailboxCubit>()
            .state
            .accounts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SettingsSectionHeading(title: 'Reading & message list'),
            Text(
              'Reading pane',
              style: TextStyle(color: t.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            SegmentedButton<ReadingPanePosition>(
              segments: const <ButtonSegment<ReadingPanePosition>>[
                ButtonSegment<ReadingPanePosition>(
                  value: ReadingPanePosition.right,
                  label: Text('Right'),
                  icon: Icon(Icons.view_sidebar_outlined, size: 16),
                ),
                ButtonSegment<ReadingPanePosition>(
                  value: ReadingPanePosition.bottom,
                  label: Text('Bottom'),
                  icon: Icon(Icons.vertical_split_outlined, size: 16),
                ),
                ButtonSegment<ReadingPanePosition>(
                  value: ReadingPanePosition.top,
                  label: Text('Top'),
                  icon: Icon(Icons.horizontal_split_outlined, size: 16),
                ),
              ],
              selected: <ReadingPanePosition>{settings.readingPanePosition},
              onSelectionChanged: (Set<ReadingPanePosition> value) =>
                  cubit.setReadingPanePosition(value.first),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show Quick Reply'),
              subtitle: Text(
                'Reply strip at the bottom of the reading pane. Turn off '
                'on phone to maximize body height.',
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              value: settings.showQuickReplyEnabled,
              onChanged: cubit.setShowQuickReplyEnabled,
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Auto-mark as read'),
              subtitle: Text(
                settings.autoMarkAsReadEnabled
                    ? 'Marks an open unread message read after it has '
                          'been on screen for '
                          '${settings.autoMarkAsReadSeconds}s.'
                    : 'Off — messages stay unread until you mark them.',
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              value: settings.autoMarkAsReadEnabled,
              onChanged: (bool enabled) => cubit.setAutoMarkAsReadSeconds(
                enabled ? kAutoMarkAsReadSecondsDefault : 0,
              ),
            ),
            if (settings.autoMarkAsReadEnabled) ...<Widget>[
              Text(
                'Auto-mark delay: ${settings.autoMarkAsReadSeconds}s',
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              Slider(
                value: settings.autoMarkAsReadSeconds.toDouble(),
                min: (kAutoMarkAsReadSecondsMin + 1).toDouble(),
                max: kAutoMarkAsReadSecondsMax.toDouble(),
                divisions: kAutoMarkAsReadSecondsMax - 1,
                label: '${settings.autoMarkAsReadSeconds}s',
                onChanged: (double v) =>
                    cubit.setAutoMarkAsReadSeconds(v.round()),
              ),
            ],
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Conversation view'),
              subtitle: Text(
                'Group replies into expandable threads',
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              value: settings.threadDisplayMode == ThreadDisplayMode.threaded,
              onChanged: (bool enabled) => cubit.setThreadDisplayMode(
                enabled ? ThreadDisplayMode.threaded : ThreadDisplayMode.flat,
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Oldest messages first'),
              subtitle: Text(
                settings.messageListSortDirection ==
                        MessageListSortDirection.oldestFirst
                    ? 'Lists and expanded threads start at the oldest message.'
                    : 'Default: newest messages at the top.',
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              value: settings.messageListSortDirection ==
                  MessageListSortDirection.oldestFirst,
              onChanged: (bool oldestFirst) =>
                  cubit.setMessageListSortDirection(
                oldestFirst
                    ? MessageListSortDirection.oldestFirst
                    : MessageListSortDirection.newestFirst,
              ),
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
                onChanged: (bool v) =>
                    cubit.setAccountFocusEnabled(account.id, v),
              ),
          ],
        );
      },
    );
  }
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

/// 4. Compose — short pointer to Manage accounts for signatures/templates.
///
/// No standalone compose preferences exist yet, so this section deliberately
/// avoids inventing fake toggles (per V1.5 Wave B scope) and instead routes
/// the user to the per-account signature/template editors.
class ComposeSettingsSection extends StatelessWidget {
  const ComposeSettingsSection({super.key, required this.onNavigateToSection});

  /// Switches the shell to another section (used for the Accounts shortcut).
  final ValueChanged<SettingsSectionId> onNavigateToSection;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SettingsSectionHeading(title: 'Compose'),
        Text(
          'Per-account signatures and reusable templates live with each '
          'mail account, not as a global Compose preference.',
          style: TextStyle(color: t.muted, fontSize: 13),
        ),
        const SizedBox(height: 4),
        Text(
          'Open Manage accounts → Edit account → Signatures / Templates.',
          style: TextStyle(color: t.muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () =>
              onNavigateToSection(SettingsSectionId.accounts),
          icon: const Icon(Icons.alternate_email_rounded),
          label: const Text('Manage accounts'),
        ),
      ],
    );
  }
}

/// 5. Sync & storage — reuses [SyncStorageSheetBody] (retention, trash,
/// attachment max, body policy, push-on-cellular).
class SyncStorageSettingsSection extends StatelessWidget {
  const SyncStorageSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const SyncStorageSheetBody();
  }
}

/// 6. Notifications — reuses [NotificationsSheetBody].
class NotificationsSettingsSection extends StatelessWidget {
  const NotificationsSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotificationsSheetBody();
  }
}

/// 7. Privacy & security — block remote images + Encryption link.
class PrivacySecuritySettingsSection extends StatelessWidget {
  const PrivacySecuritySettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (BuildContext context, AppSettingsState settings) {
        final ThemeTokens t = tokensOf(context);
        final AppSettingsCubit cubit = context.read<AppSettingsCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SettingsSectionHeading(title: 'Privacy & security'),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Block remote images'),
              subtitle: Text(
                'Privacy-first: hide http(s) images in HTML mail until '
                'you load them for a message. Inline cid/data images '
                'still show.',
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              value: settings.blockRemoteImages,
              onChanged: cubit.setBlockRemoteImages,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Block tracking pixels'),
              subtitle: Text(
                'Strip known ESP/analytics open-tracking pixels and inject '
                'a no-referrer policy — independent of "Block remote images".',
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              value: settings.blockTrackers,
              onChanged: cubit.setBlockTrackers,
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
            const SizedBox(height: 16),
            Text(
              'Per-account image privacy',
              style: TextStyle(color: t.muted, fontSize: 12),
            ),
            const SizedBox(height: 8),
            if (_accountsForSettings(context).isEmpty)
              Text(
                'Add an account to set a per-mailbox image override or '
                'allowlist.',
                style: TextStyle(color: t.muted, fontSize: 13),
              )
            else
              for (final MailAccount account in _accountsForSettings(context))
                _AccountImagePrivacyTile(account: account),
          ],
        );
      },
    );
  }
}

List<MailAccount> _accountsForSettings(BuildContext context) {
  try {
    final MailboxState mailbox = context.watch<MailboxCubit>().state;
    return mailbox.accounts;
  } catch (_) {
    return const <MailAccount>[];
  }
}

/// D6-2: per-account "Block remote images" override (inherit/block/allow)
/// plus an editable image-host allowlist domain list.
class _AccountImagePrivacyTile extends StatefulWidget {
  const _AccountImagePrivacyTile({required this.account});

  final MailAccount account;

  @override
  State<_AccountImagePrivacyTile> createState() =>
      _AccountImagePrivacyTileState();
}

class _AccountImagePrivacyTileState extends State<_AccountImagePrivacyTile> {
  final TextEditingController _domainController = TextEditingController();

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  void _addDomain(AppSettingsCubit cubit, AppSettingsState settings) {
    final String domain = _domainController.text.trim();
    if (domain.isEmpty) {
      return;
    }
    final List<String> current =
        settings.imageAllowlistDomainsForAccount(widget.account.id);
    cubit.setAccountImageAllowlistDomains(widget.account.id, <String>[
      ...current,
      domain,
    ]);
    _domainController.clear();
  }

  void _removeDomain(
    AppSettingsCubit cubit,
    AppSettingsState settings,
    String domain,
  ) {
    final List<String> current =
        settings.imageAllowlistDomainsForAccount(widget.account.id);
    cubit.setAccountImageAllowlistDomains(
      widget.account.id,
      current.where((String d) => d != domain).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (BuildContext context, AppSettingsState settings) {
        final AppSettingsCubit cubit = context.read<AppSettingsCubit>();
        final bool? override =
            settings.accountBlockRemoteImages[widget.account.id];
        final List<String> allowlist =
            settings.imageAllowlistDomainsForAccount(widget.account.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: t.line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(widget.account.label),
                          Text(
                            widget.account.address,
                            style: TextStyle(color: t.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    DropdownButton<bool?>(
                      value: override,
                      underline: const SizedBox.shrink(),
                      onChanged: (bool? next) {
                        if (next == null) {
                          cubit.clearAccountBlockRemoteImages(
                            widget.account.id,
                          );
                        } else {
                          cubit.setAccountBlockRemoteImages(
                            widget.account.id,
                            next,
                          );
                        }
                      },
                      items: <DropdownMenuItem<bool?>>[
                        const DropdownMenuItem<bool?>(
                          value: null,
                          child: Text('Inherit global'),
                        ),
                        const DropdownMenuItem<bool?>(
                          value: true,
                          child: Text('Block images'),
                        ),
                        const DropdownMenuItem<bool?>(
                          value: false,
                          child: Text('Always allow'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Always-allowed image domains',
                  style: TextStyle(color: t.muted, fontSize: 12),
                ),
                const SizedBox(height: 6),
                if (allowlist.isEmpty)
                  Text(
                    'No allowlisted domains yet.',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  )
                else
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: <Widget>[
                      for (final String domain in allowlist)
                        Chip(
                          label: Text(domain),
                          onDeleted: () =>
                              _removeDomain(cubit, settings, domain),
                        ),
                    ],
                  ),
                const SizedBox(height: 8),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextField(
                        controller: _domainController,
                        decoration: const InputDecoration(
                          isDense: true,
                          hintText: 'example.com',
                        ),
                        onSubmitted: (_) => _addDomain(cubit, settings),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _addDomain(cubit, settings),
                      child: const Text('Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 8. Shortcuts & accessibility — keyboard shortcuts, minimize to tray.
class ShortcutsAccessibilitySettingsSection extends StatelessWidget {
  const ShortcutsAccessibilitySettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppSettingsCubit, AppSettingsState>(
      builder: (BuildContext context, AppSettingsState settings) {
        final AppSettingsCubit cubit = context.read<AppSettingsCubit>();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const SettingsSectionHeading(
              title: 'Shortcuts & accessibility',
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Keyboard shortcuts'),
              subtitle: Text(
                SynesisKeyboardShortcuts.helpLabel,
                style: TextStyle(
                  color: tokensOf(context).muted,
                  fontSize: 12,
                ),
              ),
              value: settings.keyboardShortcutsEnabled,
              onChanged: cubit.setKeyboardShortcutsEnabled,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Minimize to tray (Windows)'),
              value: settings.minimizeToTray,
              onChanged: cubit.setMinimizeToTray,
            ),
          ],
        );
      },
    );
  }
}

/// 9. Advanced / About — settings export/import + a simple About block.
class AdvancedAboutSettingsSection extends StatelessWidget {
  const AdvancedAboutSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SettingsSectionHeading(title: 'Advanced / About'),
        const SettingsExportImportControls(),
        const SizedBox(height: 24),
        Divider(color: t.line),
        const SizedBox(height: 12),
        Text(kSynesisProductName, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          kSynesisProductVersion,
          style: TextStyle(color: t.muted, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'Local-first Flutter email client for Windows and Android.',
          style: TextStyle(color: t.muted, fontSize: 12),
        ),
      ],
    );
  }
}
