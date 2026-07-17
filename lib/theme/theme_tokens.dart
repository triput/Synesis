// ==============================================================================
// File: lib/theme/theme_tokens.dart
// Description: Complete token packs for ByteMail's built-in appearances.
// Component: UI / Theme
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-16
// ==============================================================================

import 'package:bytemail/theme/theme_id.dart';
import 'package:flutter/material.dart';

/// Tokenized colors so themes stay data-driven (SPEC §7.7).
///
/// Each built-in pack ([light], [dark], [black], [solarizedLight],
/// [solarizedDark]) is the approved palette for its [ThemeId]. Shell chrome
/// uses [ink], [panel], and [panel2]; message surfaces use [content].
@immutable
class ThemeTokens extends ThemeExtension<ThemeTokens> {
  const ThemeTokens({
    required this.id,
    required this.brightness,
    required this.ink,
    required this.panel,
    required this.panel2,
    required this.content,
    required this.line,
    required this.text,
    required this.muted,
    required this.teal,
    required this.amethyst,
    required this.indigo,
    required this.emerald,
    required this.azure,
    required this.amber,
    required this.coral,
    required this.onAccent,
  });

  final ThemeId id;
  final Brightness brightness;
  final Color ink;
  final Color panel;
  final Color panel2;

  /// Reading-pane and compose-body fill — distinct from [panel] chrome and
  /// [ink] scaffold backdrop. Required on every built-in pack; custom themes
  /// (W7) fork via [copyWith].
  final Color content;
  final Color line;
  final Color text;
  final Color muted;
  final Color teal;
  final Color amethyst;
  final Color indigo;
  final Color emerald;
  final Color azure;
  final Color amber;
  final Color coral;
  final Color onAccent;

  static ThemeTokens forId(ThemeId id) => switch (id) {
    ThemeId.light => light,
    ThemeId.solarizedLight => solarizedLight,
    ThemeId.dark => dark,
    ThemeId.black => black,
    ThemeId.solarizedDark => solarizedDark,
  };

  static const light = ThemeTokens(
    id: ThemeId.light,
    brightness: Brightness.light,
    ink: Color(0xFFF5F4FA),
    panel: Color(0xFFFFFFFF),
    panel2: Color(0xFFEDECF5),
    content: Color(0xFFFFFFFF),
    line: Color(0x24242236),
    text: Color(0xFF1C1A28),
    muted: Color(0xFF635F75),
    teal: Color(0xFF0A7A6E),
    amethyst: Color(0xFF6D3FC9),
    indigo: Color(0xFF4556B8),
    emerald: Color(0xFF0A8558),
    azure: Color(0xFF1668C4),
    amber: Color(0xFF8F5500),
    coral: Color(0xFFC23144),
    onAccent: Color(0xFFFFFFFF),
  );

  static const solarizedLight = ThemeTokens(
    id: ThemeId.solarizedLight,
    brightness: Brightness.light,
    ink: Color(0xFFF0E6D2),
    panel: Color(0xFFFAF3E4),
    panel2: Color(0xFFE5D9C0),
    content: Color(0xFFFFF9EE),
    line: Color(0x2E3B3226),
    text: Color(0xFF3B3226),
    muted: Color(0xFF7A6E5C),
    teal: Color(0xFF1A6B62),
    amethyst: Color(0xFF7B4FA8),
    indigo: Color(0xFF3A5F9E),
    emerald: Color(0xFF2D7A55),
    azure: Color(0xFF2A7FA8),
    amber: Color(0xFFA87208),
    coral: Color(0xFFB84A42),
    onAccent: Color(0xFFFFFFFF),
  );

  static const dark = ThemeTokens(
    id: ThemeId.dark,
    brightness: Brightness.dark,
    ink: Color(0xFF0A0E1A),
    panel: Color(0xFF111829),
    panel2: Color(0xFF1A2238),
    content: Color(0xFF0F1526),
    line: Color(0x29A78BFA),
    text: Color(0xFFE6EAF5),
    muted: Color(0xFF8B94B5),
    teal: Color(0xFF3DD9C4),
    amethyst: Color(0xFFB794F6),
    indigo: Color(0xFF7C83F0),
    emerald: Color(0xFF4ADE98),
    azure: Color(0xFF6CB4FA),
    amber: Color(0xFFF5C842),
    coral: Color(0xFFFA8294),
    onAccent: Color(0xFF061018),
  );

  static const black = ThemeTokens(
    id: ThemeId.black,
    brightness: Brightness.dark,
    ink: Color(0xFF0A0A0C),
    panel: Color(0xFF121214),
    panel2: Color(0xFF1A1A1E),
    content: Color(0xFF0E0E10),
    line: Color(0x33C084FC),
    text: Color(0xFFE8E8EC),
    muted: Color(0xFF888890),
    teal: Color(0xFF22D3EE),
    amethyst: Color(0xFFC084FC),
    indigo: Color(0xFFA78BFA),
    emerald: Color(0xFF4ADE80),
    azure: Color(0xFF38BDF8),
    amber: Color(0xFFFACC15),
    coral: Color(0xFFFB7185),
    onAccent: Color(0xFF061018),
  );

  static const solarizedDark = ThemeTokens(
    id: ThemeId.solarizedDark,
    brightness: Brightness.dark,
    ink: Color(0xFF001E26),
    panel: Color(0xFF00303C),
    panel2: Color(0xFF004452),
    content: Color(0xFF002A34),
    line: Color(0x596B9098),
    text: Color(0xFFEDE4D4),
    muted: Color(0xFF6B9098),
    teal: Color(0xFF2DD4BF),
    amethyst: Color(0xFFBD93F9),
    indigo: Color(0xFF6C9FD4),
    emerald: Color(0xFF5FD992),
    azure: Color(0xFF54C8F0),
    amber: Color(0xFFE9B949),
    coral: Color(0xFFF07068),
    onAccent: Color(0xFF001E26),
  );

  @override
  ThemeTokens copyWith({
    ThemeId? id,
    Brightness? brightness,
    Color? ink,
    Color? panel,
    Color? panel2,
    Color? content,
    Color? line,
    Color? text,
    Color? muted,
    Color? teal,
    Color? amethyst,
    Color? indigo,
    Color? emerald,
    Color? azure,
    Color? amber,
    Color? coral,
    Color? onAccent,
  }) {
    return ThemeTokens(
      id: id ?? this.id,
      brightness: brightness ?? this.brightness,
      ink: ink ?? this.ink,
      panel: panel ?? this.panel,
      panel2: panel2 ?? this.panel2,
      content: content ?? this.content,
      line: line ?? this.line,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      teal: teal ?? this.teal,
      amethyst: amethyst ?? this.amethyst,
      indigo: indigo ?? this.indigo,
      emerald: emerald ?? this.emerald,
      azure: azure ?? this.azure,
      amber: amber ?? this.amber,
      coral: coral ?? this.coral,
      onAccent: onAccent ?? this.onAccent,
    );
  }

  @override
  ThemeTokens lerp(ThemeExtension<ThemeTokens>? other, double t) {
    if (other is! ThemeTokens) return this;
    return ThemeTokens(
      id: t < 0.5 ? id : other.id,
      brightness: t < 0.5 ? brightness : other.brightness,
      ink: Color.lerp(ink, other.ink, t)!,
      panel: Color.lerp(panel, other.panel, t)!,
      panel2: Color.lerp(panel2, other.panel2, t)!,
      content: Color.lerp(content, other.content, t)!,
      line: Color.lerp(line, other.line, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      teal: Color.lerp(teal, other.teal, t)!,
      amethyst: Color.lerp(amethyst, other.amethyst, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
      emerald: Color.lerp(emerald, other.emerald, t)!,
      azure: Color.lerp(azure, other.azure, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      onAccent: Color.lerp(onAccent, other.onAccent, t)!,
    );
  }
}
