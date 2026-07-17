// ==============================================================================
// File: lib/theme/theme_id.dart
// Description: Identifiers and user-facing names for built-in appearance packs.
// Component: UI / Theme
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

/// Built-in appearance themes (SPEC §7.7).
enum ThemeId {
  light,
  solarizedLight,
  dark,
  black,
  solarizedDark,
}

extension ThemeIdLabel on ThemeId {
  String get label => switch (this) {
        ThemeId.light => 'Light',
        ThemeId.solarizedLight => 'Solarized Light',
        ThemeId.dark => 'Dark',
        ThemeId.black => 'Black',
        ThemeId.solarizedDark => 'Solarized Dark',
      };
}
