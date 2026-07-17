// ==============================================================================
// File: test/theme_tokens_test.dart
// Description: Regression coverage for ByteMail's built-in theme token packs.
// Component: Test / UI Theme
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-16
// ==============================================================================

import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeTokens built-ins', () {
    test('all five approved palettes remain exact', () {
      _expectPalette(
        ThemeTokens.light,
        id: ThemeId.light,
        brightness: Brightness.light,
        colors: const <Color>[
          Color(0xFFF5F4FA),
          Color(0xFFFFFFFF),
          Color(0xFFEDECF5),
          Color(0xFFFFFFFF),
          Color(0x24242236),
          Color(0xFF1C1A28),
          Color(0xFF635F75),
          Color(0xFF0A7A6E),
          Color(0xFF6D3FC9),
          Color(0xFF4556B8),
          Color(0xFF0A8558),
          Color(0xFF1668C4),
          Color(0xFF8F5500),
          Color(0xFFC23144),
          Color(0xFFFFFFFF),
        ],
      );
      _expectPalette(
        ThemeTokens.solarizedLight,
        id: ThemeId.solarizedLight,
        brightness: Brightness.light,
        colors: const <Color>[
          Color(0xFFF0E6D2),
          Color(0xFFFAF3E4),
          Color(0xFFE5D9C0),
          Color(0xFFFFF9EE),
          Color(0x2E3B3226),
          Color(0xFF3B3226),
          Color(0xFF7A6E5C),
          Color(0xFF1A6B62),
          Color(0xFF7B4FA8),
          Color(0xFF3A5F9E),
          Color(0xFF2D7A55),
          Color(0xFF2A7FA8),
          Color(0xFFA87208),
          Color(0xFFB84A42),
          Color(0xFFFFFFFF),
        ],
      );
      _expectPalette(
        ThemeTokens.dark,
        id: ThemeId.dark,
        brightness: Brightness.dark,
        colors: const <Color>[
          Color(0xFF0A0E1A),
          Color(0xFF111829),
          Color(0xFF1A2238),
          Color(0xFF0F1526),
          Color(0x29A78BFA),
          Color(0xFFE6EAF5),
          Color(0xFF8B94B5),
          Color(0xFF3DD9C4),
          Color(0xFFB794F6),
          Color(0xFF7C83F0),
          Color(0xFF4ADE98),
          Color(0xFF6CB4FA),
          Color(0xFFF5C842),
          Color(0xFFFA8294),
          Color(0xFF061018),
        ],
      );
      _expectPalette(
        ThemeTokens.black,
        id: ThemeId.black,
        brightness: Brightness.dark,
        colors: const <Color>[
          Color(0xFF0A0A0C),
          Color(0xFF121214),
          Color(0xFF1A1A1E),
          Color(0xFF0E0E10),
          Color(0x33C084FC),
          Color(0xFFE8E8EC),
          Color(0xFF888890),
          Color(0xFF22D3EE),
          Color(0xFFC084FC),
          Color(0xFFA78BFA),
          Color(0xFF4ADE80),
          Color(0xFF38BDF8),
          Color(0xFFFACC15),
          Color(0xFFFB7185),
          Color(0xFF061018),
        ],
      );
      _expectPalette(
        ThemeTokens.solarizedDark,
        id: ThemeId.solarizedDark,
        brightness: Brightness.dark,
        colors: const <Color>[
          Color(0xFF001E26),
          Color(0xFF00303C),
          Color(0xFF004452),
          Color(0xFF002A34),
          Color(0x596B9098),
          Color(0xFFEDE4D4),
          Color(0xFF6B9098),
          Color(0xFF2DD4BF),
          Color(0xFFBD93F9),
          Color(0xFF6C9FD4),
          Color(0xFF5FD992),
          Color(0xFF54C8F0),
          Color(0xFFE9B949),
          Color(0xFFF07068),
          Color(0xFF001E26),
        ],
      );
    });

    test('forId resolves every ThemeId to its matching built-in pack', () {
      for (final ThemeId id in ThemeId.values) {
        final ThemeTokens tokens = ThemeTokens.forId(id);
        expect(tokens.id, id);
        expect(tokens, same(_tokensFor(id)));
      }
    });

    test('copyWith replaces content while preserving other fields', () {
      const Color replacement = Color(0xFF112233);
      final ThemeTokens updated = ThemeTokens.dark.copyWith(
        content: replacement,
      );

      expect(updated.content, replacement);
      expect(updated.panel, ThemeTokens.dark.panel);
      expect(updated.ink, ThemeTokens.dark.ink);
      expect(updated.id, ThemeId.dark);
    });

    test('lerp interpolates content between packs', () {
      final ThemeTokens mid = ThemeTokens.light.lerp(ThemeTokens.dark, 0.5);

      expect(
        mid.content,
        Color.lerp(ThemeTokens.light.content, ThemeTokens.dark.content, 0.5),
      );
      expect(mid.content, isNot(ThemeTokens.light.content));
      expect(mid.content, isNot(ThemeTokens.dark.content));
    });
  });
}

ThemeTokens _tokensFor(ThemeId id) => switch (id) {
  ThemeId.light => ThemeTokens.light,
  ThemeId.solarizedLight => ThemeTokens.solarizedLight,
  ThemeId.dark => ThemeTokens.dark,
  ThemeId.black => ThemeTokens.black,
  ThemeId.solarizedDark => ThemeTokens.solarizedDark,
};

void _expectPalette(
  ThemeTokens tokens, {
  required ThemeId id,
  required Brightness brightness,
  required List<Color> colors,
}) {
  expect(tokens.id, id);
  expect(tokens.brightness, brightness);
  expect(
    <Color>[
      tokens.ink,
      tokens.panel,
      tokens.panel2,
      tokens.content,
      tokens.line,
      tokens.text,
      tokens.muted,
      tokens.teal,
      tokens.amethyst,
      tokens.indigo,
      tokens.emerald,
      tokens.azure,
      tokens.amber,
      tokens.coral,
      tokens.onAccent,
    ],
    colors,
    reason: '${id.name} must match the approved built-in palette',
  );
}
