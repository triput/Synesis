// ==============================================================================
// File: lib/theme/custom_theme.dart
// Description: User-defined theme forked from a built-in pack (UI-P16).
// Component: Domain / Theme
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:flutter/material.dart';

/// Token names accepted in [CustomTheme.tokenOverrides], matching the public
/// fields on [ThemeTokens] (excluding [ThemeTokens.id]/[ThemeTokens.brightness]
/// which are structural, not colors).
const List<String> kCustomThemeTokenNames = <String>[
  'ink',
  'panel',
  'panel2',
  'content',
  'line',
  'text',
  'muted',
  'teal',
  'amethyst',
  'indigo',
  'emerald',
  'azure',
  'amber',
  'coral',
  'onAccent',
];

/// A named fork of a built-in [ThemeId] pack with a sparse set of token
/// color overrides (UI-P16). Persisted in the `custom_themes` table.
@immutable
class CustomTheme {
  const CustomTheme({
    required this.id,
    required this.name,
    required this.baseThemeId,
    this.tokenOverrides = const <String, int>{},
  });

  final String id;
  final String name;
  final ThemeId baseThemeId;

  /// Token name (see [kCustomThemeTokenNames]) → ARGB32 color override.
  final Map<String, int> tokenOverrides;

  /// Applies [tokenOverrides] on top of the base pack's [ThemeTokens].
  ThemeTokens resolveTokens() {
    final ThemeTokens base = ThemeTokens.forId(baseThemeId);
    Color? colorFor(String token) {
      final int? argb = tokenOverrides[token];
      return argb == null ? null : Color(argb);
    }

    return base.copyWith(
      ink: colorFor('ink'),
      panel: colorFor('panel'),
      panel2: colorFor('panel2'),
      content: colorFor('content'),
      line: colorFor('line'),
      text: colorFor('text'),
      muted: colorFor('muted'),
      teal: colorFor('teal'),
      amethyst: colorFor('amethyst'),
      indigo: colorFor('indigo'),
      emerald: colorFor('emerald'),
      azure: colorFor('azure'),
      amber: colorFor('amber'),
      coral: colorFor('coral'),
      onAccent: colorFor('onAccent'),
    );
  }

  CustomTheme copyWith({
    String? id,
    String? name,
    ThemeId? baseThemeId,
    Map<String, int>? tokenOverrides,
  }) {
    return CustomTheme(
      id: id ?? this.id,
      name: name ?? this.name,
      baseThemeId: baseThemeId ?? this.baseThemeId,
      tokenOverrides: tokenOverrides ?? this.tokenOverrides,
    );
  }
}
