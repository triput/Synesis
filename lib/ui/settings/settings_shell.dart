// ==============================================================================
// File: lib/ui/settings/settings_shell.dart
// Description: UI-P21 sectioned Settings shell — adaptive NavigationRail/
//   drill-down navigation across all functional-area sections, with search
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-08-03
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/account/manage_accounts_sheet.dart';
import 'package:synesis/ui/settings/settings_catalog.dart';
import 'package:synesis/ui/settings/settings_sections.dart';

/// Narrow/mobile breakpoint shared with the rest of the shell (UI-P21):
/// below this, Settings uses a section-index list + drill-in page instead
/// of the desktop side-nav + content pane.
const double kSettingsNarrowBreakpoint = 600;

/// Opens the sectioned Settings shell (UI-P21).
///
/// Replaces the old single-scroll "Appearance & view" bottom sheet. Kept as
/// a full-screen [MaterialPageRoute] (rather than another bottom sheet) so
/// the desktop side-nav and mobile drill-down both have room to breathe.
Future<void> showSettingsSheet(
  BuildContext context, {
  SettingsSectionId initialSection = SettingsSectionId.accounts,
}) {
  return Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      builder: (BuildContext context) =>
          SettingsShell(initialSection: initialSection),
      settings: const RouteSettings(name: '/settings'),
    ),
  );
}

/// Thin backward-compatible alias — old call sites can keep using
/// `showAppearanceSheet` while the shell replaces the sheet body (UI-P21).
Future<void> showAppearanceSheet(BuildContext context) => showSettingsSheet(
  context,
);

/// Root widget for the sectioned Settings experience (UI-P21).
///
/// Desktop/wide screens show a persistent [NavigationRail] beside a single
/// content pane; narrow/mobile screens show a section index that drills
/// into a dedicated page per section. Both surfaces share the same search
/// box and [kSettingsCatalog] filtering logic.
class SettingsShell extends StatefulWidget {
  const SettingsShell({
    super.key,
    this.initialSection = SettingsSectionId.accounts,
  });

  final SettingsSectionId initialSection;

  @override
  State<SettingsShell> createState() => _SettingsShellState();
}

class _SettingsShellState extends State<SettingsShell> {
  late SettingsSectionId _selected = widget.initialSection;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectSection(SettingsSectionId id) {
    setState(() => _selected = id);
  }

  /// Navigates to a search hit's section. On narrow layouts this also pushes
  /// the drill-in page since the index list is the visible route there.
  void _onSearchHit(BuildContext context, SettingsCatalogEntry entry) {
    _selectSection(entry.sectionId);
    if (MediaQuery.sizeOf(context).shortestSide < kSettingsNarrowBreakpoint) {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (BuildContext context) =>
              _SettingsSectionPage(sectionId: entry.sectionId),
        ),
      );
    }
  }

  List<SettingsCatalogEntry> get _filteredCatalog {
    if (_query.trim().isEmpty) {
      return const <SettingsCatalogEntry>[];
    }
    return kSettingsCatalog
        .where((SettingsCatalogEntry entry) => entry.matches(_query))
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final bool narrow =
        MediaQuery.sizeOf(context).shortestSide < kSettingsNarrowBreakpoint;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: _SettingsSearchField(
                controller: _searchController,
                onChanged: (String value) => setState(() => _query = value),
              ),
            ),
            if (_query.trim().isNotEmpty)
              Expanded(
                child: _SettingsSearchResults(
                  entries: _filteredCatalog,
                  onTap: (SettingsCatalogEntry entry) =>
                      _onSearchHit(context, entry),
                ),
              )
            else
              Expanded(
                child: narrow
                    ? _SettingsSectionIndex(
                        onSelect: (SettingsSectionId id) {
                          _selectSection(id);
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  _SettingsSectionPage(sectionId: id),
                            ),
                          );
                        },
                      )
                    : _SettingsWideLayout(
                        selected: _selected,
                        onSelect: _selectSection,
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Desktop/wide: [NavigationRail] section list beside a single content pane.
class _SettingsWideLayout extends StatelessWidget {
  const _SettingsWideLayout({required this.selected, required this.onSelect});

  final SettingsSectionId selected;
  final ValueChanged<SettingsSectionId> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        NavigationRail(
          selectedIndex: SettingsSectionId.values.indexOf(selected),
          onDestinationSelected: (int index) =>
              onSelect(SettingsSectionId.values[index]),
          labelType: NavigationRailLabelType.all,
          backgroundColor: t.panel,
          destinations: <NavigationRailDestination>[
            for (final SettingsSectionId id in SettingsSectionId.values)
              NavigationRailDestination(
                icon: Icon(id.icon),
                label: Text(id.label, textAlign: TextAlign.center),
              ),
          ],
        ),
        VerticalDivider(width: 1, color: t.line),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                if (selected == SettingsSectionId.accounts &&
                    constraints.maxHeight.isFinite) {
                  // Tight height so primaryScroll Expanded has a real bound.
                  return SizedBox(
                    height: constraints.maxHeight,
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 640),
                        child: const ManageAccountsSheetBody(
                          primaryScroll: true,
                        ),
                      ),
                    ),
                  );
                }
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: _SettingsSectionBody(
                      sectionId: selected,
                      onNavigateToSection: onSelect,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Mobile/narrow: a plain section index that drills into [_SettingsSectionPage].
class _SettingsSectionIndex extends StatelessWidget {
  const _SettingsSectionIndex({required this.onSelect});

  final ValueChanged<SettingsSectionId> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: <Widget>[
        for (final SettingsSectionId id in SettingsSectionId.values)
          ListTile(
            leading: Icon(id.icon),
            title: Text(id.label),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => onSelect(id),
          ),
      ],
    );
  }
}

/// Mobile/narrow drill-in page for a single [SettingsSectionId].
class _SettingsSectionPage extends StatelessWidget {
  const _SettingsSectionPage({required this.sectionId});

  final SettingsSectionId sectionId;

  @override
  Widget build(BuildContext context) {
    if (sectionId == SettingsSectionId.accounts) {
      // Bounded body + internal ListView scroll (DEF-063). Parent
      // SingleChildScrollView + shrink-wrap ListView still overflowed on
      // Android when account cards + footer exceeded the viewport.
      return Scaffold(
        appBar: AppBar(title: Text(sectionId.label)),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: const ManageAccountsSheetBody(primaryScroll: true),
          ),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(sectionId.label)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: _SettingsSectionBody(
            sectionId: sectionId,
            onNavigateToSection: (SettingsSectionId next) {
              Navigator.of(context).pushReplacement<void, void>(
                MaterialPageRoute<void>(
                  builder: (BuildContext context) =>
                      _SettingsSectionPage(sectionId: next),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Dispatches to the concrete section widget for [sectionId] (UI-P21).
class _SettingsSectionBody extends StatelessWidget {
  const _SettingsSectionBody({
    required this.sectionId,
    required this.onNavigateToSection,
  });

  final SettingsSectionId sectionId;
  final ValueChanged<SettingsSectionId> onNavigateToSection;

  @override
  Widget build(BuildContext context) {
    return switch (sectionId) {
      SettingsSectionId.accounts => const AccountsSettingsSection(),
      SettingsSectionId.appearance => const AppearanceSettingsSection(),
      SettingsSectionId.readingAndMessageList =>
        const ReadingMessageListSettingsSection(),
      SettingsSectionId.compose => ComposeSettingsSection(
        onNavigateToSection: onNavigateToSection,
      ),
      SettingsSectionId.syncAndStorage => const SyncStorageSettingsSection(),
      SettingsSectionId.notifications => const NotificationsSettingsSection(),
      SettingsSectionId.privacyAndSecurity =>
        const PrivacySecuritySettingsSection(),
      SettingsSectionId.shortcutsAndAccessibility =>
        const ShortcutsAccessibilitySettingsSection(),
      SettingsSectionId.advancedAndAbout =>
        const AdvancedAboutSettingsSection(),
    };
  }
}

class _SettingsSearchField extends StatelessWidget {
  const _SettingsSearchField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: const InputDecoration(
        hintText: 'Search settings…',
        prefixIcon: Icon(Icons.search),
        isDense: true,
      ),
    );
  }
}

class _SettingsSearchResults extends StatelessWidget {
  const _SettingsSearchResults({required this.entries, required this.onTap});

  final List<SettingsCatalogEntry> entries;
  final ValueChanged<SettingsCatalogEntry> onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    if (entries.isEmpty) {
      return Center(
        child: Text('No matching settings', style: TextStyle(color: t.muted)),
      );
    }
    return ListView.builder(
      itemCount: entries.length,
      itemBuilder: (BuildContext context, int index) {
        final SettingsCatalogEntry entry = entries[index];
        return ListTile(
          leading: Icon(entry.sectionId.icon),
          title: Text(entry.label),
          subtitle: Text(
            entry.sectionId.label,
            style: TextStyle(color: t.muted, fontSize: 12),
          ),
          onTap: () => onTap(entry),
        );
      },
    );
  }
}
