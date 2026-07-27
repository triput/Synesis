// ==============================================================================
// File: lib/ui/settings/settings_catalog.dart
// Description: Section identifiers and searchable {label, keywords, sectionId}
//   catalog backing the UI-P21 Settings shell search box
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-07-23
// ==============================================================================

import 'package:flutter/material.dart';

/// The nine functional-area sections of the UI-P21 Settings shell.
///
/// Order here drives the desktop side-nav and mobile section-index order.
enum SettingsSectionId {
  accounts,
  appearance,
  readingAndMessageList,
  compose,
  syncAndStorage,
  notifications,
  privacyAndSecurity,
  shortcutsAndAccessibility,
  advancedAndAbout,
}

/// Display metadata for a [SettingsSectionId].
extension SettingsSectionIdX on SettingsSectionId {
  String get label => switch (this) {
    SettingsSectionId.accounts => 'Accounts',
    SettingsSectionId.appearance => 'Appearance',
    SettingsSectionId.readingAndMessageList => 'Reading & message list',
    SettingsSectionId.compose => 'Compose',
    SettingsSectionId.syncAndStorage => 'Sync & storage',
    SettingsSectionId.notifications => 'Notifications',
    SettingsSectionId.privacyAndSecurity => 'Privacy & security',
    SettingsSectionId.shortcutsAndAccessibility =>
      'Shortcuts & accessibility',
    SettingsSectionId.advancedAndAbout => 'Advanced / About',
  };

  IconData get icon => switch (this) {
    SettingsSectionId.accounts => Icons.alternate_email_rounded,
    SettingsSectionId.appearance => Icons.palette_outlined,
    SettingsSectionId.readingAndMessageList => Icons.view_sidebar_outlined,
    SettingsSectionId.compose => Icons.edit_outlined,
    SettingsSectionId.syncAndStorage => Icons.sync_outlined,
    SettingsSectionId.notifications => Icons.notifications_outlined,
    SettingsSectionId.privacyAndSecurity => Icons.shield_outlined,
    SettingsSectionId.shortcutsAndAccessibility =>
      Icons.keyboard_alt_outlined,
    SettingsSectionId.advancedAndAbout => Icons.info_outline_rounded,
  };
}

/// One searchable row in the static Settings catalog: a section plus a
/// human label and keyword synonyms used only for the search filter.
///
/// This is intentionally a flat, static list (not derived from live widget
/// trees) so search stays instant and independent of which section is
/// currently mounted.
@immutable
class SettingsCatalogEntry {
  const SettingsCatalogEntry({
    required this.sectionId,
    required this.label,
    this.keywords = const <String>[],
  });

  final SettingsSectionId sectionId;
  final String label;
  final List<String> keywords;

  /// Case-insensitive match against [label], [keywords], or the owning
  /// section's own label (so typing "notifications" surfaces the section
  /// entry even without a dedicated row).
  bool matches(String query) {
    final String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    if (label.toLowerCase().contains(needle)) {
      return true;
    }
    if (sectionId.label.toLowerCase().contains(needle)) {
      return true;
    }
    for (final String keyword in keywords) {
      if (keyword.toLowerCase().contains(needle)) {
        return true;
      }
    }
    return false;
  }
}

/// Static {label, keywords, sectionId} catalog powering the Settings shell
/// search box. One entry per section header plus one per notable control so
/// searching a setting name (e.g. "swipe", "retention", "quiet hours")
/// jumps straight to the owning section.
const List<SettingsCatalogEntry> kSettingsCatalog = <SettingsCatalogEntry>[
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.accounts,
    label: 'Accounts',
    keywords: <String>['manage accounts', 'add account', 'remove account'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.accounts,
    label: 'Edit account',
    keywords: <String>['credentials', 're-authenticate', 'label'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.appearance,
    label: 'Theme',
    keywords: <String>['dark mode', 'light mode', 'black', 'solarized'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.appearance,
    label: 'Custom themes',
    keywords: <String>['color', 'palette', 'create theme'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.appearance,
    label: 'UI font',
    keywords: <String>['font family', 'font size', 'text size', 'text color'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.appearance,
    label: 'Density',
    keywords: <String>['calm', 'compact', 'spacing'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.readingAndMessageList,
    label: 'Reading pane',
    keywords: <String>['right', 'bottom', 'top', 'split position'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.readingAndMessageList,
    label: 'Visual Focus',
    keywords: <String>['distraction free', 'maximize reading', 'fullscreen'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.readingAndMessageList,
    label: 'Auto-mark as read',
    keywords: <String>['dwell', 'delay', 'seconds', 'auto mark'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.readingAndMessageList,
    label: 'Conversation view',
    keywords: <String>['threading', 'threaded', 'flat'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.readingAndMessageList,
    label: 'Swipe actions',
    keywords: <String>['archive', 'delete', 'star', 'snooze', 'android'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.readingAndMessageList,
    label: 'Focused/Other',
    keywords: <String>['unified inbox', 'focus filter'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.readingAndMessageList,
    label: 'Focus override rules',
    keywords: <String>['sender', 'domain', 'always focused'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.readingAndMessageList,
    label: 'Per-account Focus',
    keywords: <String>['focus enabled'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.compose,
    label: 'Signatures',
    keywords: <String>['signature', 'manage accounts'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.compose,
    label: 'Templates',
    keywords: <String>['template', 'manage accounts', 'reusable text'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.syncAndStorage,
    label: 'Retention',
    keywords: <String>['days', 'device retention dial'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.syncAndStorage,
    label: 'Empty trash after',
    keywords: <String>['trash retention', 'days'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.syncAndStorage,
    label: 'Attachment max size',
    keywords: <String>['mb', 'attachment'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.syncAndStorage,
    label: 'Body fetch policy',
    keywords: <String>['on open', 'headers only', 'full always'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.syncAndStorage,
    label: 'Push on cellular',
    keywords: <String>['mobile data', 'idle', 'push sync'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.notifications,
    label: 'Notifications',
    keywords: <String>['toast', 'alerts', 'quiet hours', 'starred only'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.privacyAndSecurity,
    label: 'Block remote images',
    keywords: <String>['tracking', 'privacy', 'html images'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.privacyAndSecurity,
    label: 'Block tracking pixels',
    keywords: <String>['trackers', 'analytics', 'esp', 'referrer', 'privacy'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.privacyAndSecurity,
    label: 'Per-account image privacy',
    keywords: <String>['allowlist', 'whitelist', 'domain', 'per-account'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.privacyAndSecurity,
    label: 'Encryption',
    keywords: <String>['passphrase', 'database', 'encrypt'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.shortcutsAndAccessibility,
    label: 'Keyboard shortcuts',
    keywords: <String>['hotkeys'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.shortcutsAndAccessibility,
    label: 'Minimize to tray',
    keywords: <String>['windows', 'tray', 'close button'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.advancedAndAbout,
    label: 'Export settings',
    keywords: <String>['backup', 'import', 'json'],
  ),
  SettingsCatalogEntry(
    sectionId: SettingsSectionId.advancedAndAbout,
    label: 'About',
    keywords: <String>['version', 'synesis', 'product'],
  ),
];
