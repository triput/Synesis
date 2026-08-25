// ==============================================================================
// File: lib/ui/shell/module_shell.dart
// Description: Outlook-style Mail/Calendar/People module switcher shell.
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-08-25
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/calendar/calendar_workspace.dart';
import 'package:synesis/ui/people/people_workspace.dart';
import 'package:synesis/ui/shell/mail_split_layout.dart';
import 'package:synesis/ui/shell/mail_workspace.dart';

/// Top-level Synesis modules reachable from [ModuleShell] (Wave 5 / V2.0c).
enum AppModule {
  /// Default launch surface (W5-3) — never changed by module switching.
  mail,
  calendar,
  people,
}

extension AppModuleX on AppModule {
  String get label => switch (this) {
    AppModule.mail => 'Mail',
    AppModule.calendar => 'Calendar',
    AppModule.people => 'People',
  };

  IconData get icon => switch (this) {
    AppModule.mail => Icons.mail_outline_rounded,
    AppModule.calendar => Icons.calendar_month_outlined,
    AppModule.people => Icons.people_outline_rounded,
  };

  IconData get selectedIcon => switch (this) {
    AppModule.mail => Icons.mail_rounded,
    AppModule.calendar => Icons.calendar_month_rounded,
    AppModule.people => Icons.people_rounded,
  };
}

/// Root shell hosting the Outlook-style module switcher.
///
/// Mail is always the cold-start default ([AppModule.mail], per W5-3) —
/// [MailWorkspace] itself is untouched by this wrapper, so existing mail
/// navigation, account rail, and reading-pane behavior are unaffected.
/// Switching modules only swaps the body; settings/sync entry points stay
/// reachable from within each module's own chrome.
class ModuleShell extends StatefulWidget {
  const ModuleShell({super.key, this.initialModule = AppModule.mail});

  final AppModule initialModule;

  @override
  State<ModuleShell> createState() => _ModuleShellState();
}

class _ModuleShellState extends State<ModuleShell> {
  late AppModule _module = widget.initialModule;

  void _select(AppModule module) {
    if (_module == module) {
      return;
    }
    setState(() => _module = module);
  }

  Widget _bodyFor(AppModule module) {
    return switch (module) {
      AppModule.mail => const MailWorkspace(),
      AppModule.calendar => const CalendarWorkspace(),
      AppModule.people => const PeopleWorkspace(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final bool portraitMobile = isPortraitMobileLayout(context);
    // IndexedStack keeps each module's Cubit-backed widget tree alive across
    // switches (no reload flicker returning to Mail), matching the "return
    // to Mail without state loss" Wave 5 dogfood expectation.
    final Widget body = IndexedStack(
      index: _module.index,
      // DEF-078: loose (default) lets module bodies shrink-wrap; Mail reading
      // left a teal void above the bottom nav on Android dogfood.
      sizing: StackFit.expand,
      children: <Widget>[
        for (final AppModule module in AppModule.values)
          SizedBox.expand(child: _bodyFor(module)),
      ],
    );
    if (portraitMobile) {
      return Scaffold(
        body: body,
        bottomNavigationBar: ModuleNavigationBar(
          selected: _module,
          onSelect: _select,
        ),
      );
    }
    return Scaffold(
      body: Row(
        children: <Widget>[
          ModuleRail(selected: _module, onSelect: _select),
          Expanded(child: body),
        ],
      ),
    );
  }
}

/// Desktop/wide: slim persistent icon rail, leftmost in the shell.
class ModuleRail extends StatelessWidget {
  const ModuleRail({super.key, required this.selected, required this.onSelect});

  final AppModule selected;
  final ValueChanged<AppModule> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Container(
      key: const Key('module_rail'),
      width: 56,
      decoration: BoxDecoration(
        color: t.ink,
        border: Border(right: BorderSide(color: t.line)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: <Widget>[
          for (final AppModule module in AppModule.values) ...<Widget>[
            _ModuleRailButton(
              module: module,
              selected: module == selected,
              onTap: () => onSelect(module),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _ModuleRailButton extends StatelessWidget {
  const _ModuleRailButton({
    required this.module,
    required this.selected,
    required this.onTap,
  });

  final AppModule module;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Tooltip(
      message: module.label,
      waitDuration: const Duration(milliseconds: 400),
      child: Material(
        key: Key('module_rail_${module.name}'),
        color: selected ? t.indigo.withValues(alpha: 0.28) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(
              selected ? module.selectedIcon : module.icon,
              color: selected ? t.teal : t.muted,
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}

/// Mobile/narrow: bottom navigation bar with the same three destinations.
class ModuleNavigationBar extends StatelessWidget {
  const ModuleNavigationBar({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final AppModule selected;
  final ValueChanged<AppModule> onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return NavigationBar(
      key: const Key('module_nav_bar'),
      selectedIndex: selected.index,
      backgroundColor: t.panel,
      onDestinationSelected: (int index) => onSelect(AppModule.values[index]),
      destinations: <NavigationDestination>[
        for (final AppModule module in AppModule.values)
          NavigationDestination(
            key: Key('module_nav_${module.name}'),
            icon: Icon(module.icon),
            selectedIcon: Icon(module.selectedIcon),
            label: module.label,
          ),
      ],
    );
  }
}
