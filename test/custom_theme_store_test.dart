// ==============================================================================
// File: test/custom_theme_store_test.dart
// Description: Custom theme CRUD and token-override resolution coverage (UI-P16).
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/repository/database.dart' hide CustomTheme;
import 'package:bytemail/repository/drift_mail_repository.dart';
import 'package:bytemail/theme/custom_theme.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<DriftMailRepository> _openTestRepo() async {
  final ByteMailDatabase database = ByteMailDatabase(NativeDatabase.memory());
  return DriftMailRepository(database);
}

void main() {
  group('DriftMailRepository custom theme CRUD', () {
    test('listCustomThemes is empty on a fresh database', () async {
      final DriftMailRepository repo = await _openTestRepo();
      addTearDown(repo.close);

      expect(await repo.listCustomThemes(), isEmpty);
    });

    test('upsertCustomTheme then listCustomThemes round-trips fields', () async {
      final DriftMailRepository repo = await _openTestRepo();
      addTearDown(repo.close);

      await repo.upsertCustomTheme(
        const CustomTheme(
          id: 'theme-1',
          name: 'Midnight Coral',
          baseThemeId: ThemeId.dark,
          tokenOverrides: <String, int>{
            'teal': 0xFFFF5566,
            'text': 0xFFEEEEEE,
          },
        ),
      );

      final List<CustomTheme> themes = await repo.listCustomThemes();
      expect(themes, hasLength(1));
      expect(themes.single.id, 'theme-1');
      expect(themes.single.name, 'Midnight Coral');
      expect(themes.single.baseThemeId, ThemeId.dark);
      expect(themes.single.tokenOverrides['teal'], 0xFFFF5566);
      expect(themes.single.tokenOverrides['text'], 0xFFEEEEEE);
    });

    test('upsertCustomTheme with the same id updates in place', () async {
      final DriftMailRepository repo = await _openTestRepo();
      addTearDown(repo.close);

      await repo.upsertCustomTheme(
        const CustomTheme(
          id: 'theme-1',
          name: 'First name',
          baseThemeId: ThemeId.dark,
        ),
      );
      await repo.upsertCustomTheme(
        const CustomTheme(
          id: 'theme-1',
          name: 'Renamed',
          baseThemeId: ThemeId.light,
          tokenOverrides: <String, int>{'ink': 0xFF000000},
        ),
      );

      final List<CustomTheme> themes = await repo.listCustomThemes();
      expect(themes, hasLength(1));
      expect(themes.single.name, 'Renamed');
      expect(themes.single.baseThemeId, ThemeId.light);
      expect(themes.single.tokenOverrides['ink'], 0xFF000000);
    });

    test('getCustomTheme returns null for a missing id', () async {
      final DriftMailRepository repo = await _openTestRepo();
      addTearDown(repo.close);

      expect(await repo.getCustomTheme('nope'), isNull);
    });

    test('deleteCustomTheme removes exactly the matching row', () async {
      final DriftMailRepository repo = await _openTestRepo();
      addTearDown(repo.close);

      await repo.upsertCustomTheme(
        const CustomTheme(id: 'theme-1', name: 'A', baseThemeId: ThemeId.dark),
      );
      await repo.upsertCustomTheme(
        const CustomTheme(id: 'theme-2', name: 'B', baseThemeId: ThemeId.black),
      );

      await repo.deleteCustomTheme('theme-1');

      final List<CustomTheme> themes = await repo.listCustomThemes();
      expect(themes, hasLength(1));
      expect(themes.single.id, 'theme-2');
    });

    test('corrupt tokenOverridesJson falls back to an empty override map', () async {
      final ByteMailDatabase database =
          ByteMailDatabase(NativeDatabase.memory());
      final DriftMailRepository repo = DriftMailRepository(database);
      addTearDown(repo.close);

      await database.into(database.customThemes).insert(
            CustomThemesCompanion.insert(
              id: 'theme-1',
              name: 'Corrupt',
              baseThemeId: 'dark',
              tokenOverridesJson: 'not-json',
            ),
          );

      final CustomTheme? theme = await repo.getCustomTheme('theme-1');
      expect(theme, isNotNull);
      expect(theme!.tokenOverrides, isEmpty);
    });
  });

  group('CustomTheme.resolveTokens', () {
    test('with no overrides resolves exactly the base pack', () {
      const CustomTheme theme = CustomTheme(
        id: 'theme-1',
        name: 'Plain dark',
        baseThemeId: ThemeId.dark,
      );

      final ThemeTokens resolved = theme.resolveTokens();
      expect(resolved.ink, ThemeTokens.dark.ink);
      expect(resolved.text, ThemeTokens.dark.text);
      expect(resolved.teal, ThemeTokens.dark.teal);
    });

    test('applies sparse overrides on top of the base pack', () {
      const CustomTheme theme = CustomTheme(
        id: 'theme-1',
        name: 'Coral accent',
        baseThemeId: ThemeId.dark,
        tokenOverrides: <String, int>{'teal': 0xFFFF0000},
      );

      final ThemeTokens resolved = theme.resolveTokens();
      expect(resolved.teal, const Color(0xFFFF0000));
      // Untouched tokens fall through to the base pack unchanged.
      expect(resolved.ink, ThemeTokens.dark.ink);
      expect(resolved.panel, ThemeTokens.dark.panel);
      expect(resolved.brightness, ThemeTokens.dark.brightness);
    });

    test('overrides every editable token when all are provided', () {
      const CustomTheme theme = CustomTheme(
        id: 'theme-1',
        name: 'Full override',
        baseThemeId: ThemeId.light,
        tokenOverrides: <String, int>{
          'ink': 0xFF010101,
          'panel': 0xFF020202,
          'panel2': 0xFF030303,
          'content': 0xFF040404,
          'line': 0xFF050505,
          'text': 0xFF060606,
          'muted': 0xFF070707,
          'teal': 0xFF080808,
          'amethyst': 0xFF090909,
          'indigo': 0xFF0A0A0A,
          'emerald': 0xFF0B0B0B,
          'azure': 0xFF0C0C0C,
          'amber': 0xFF0D0D0D,
          'coral': 0xFF0E0E0E,
          'onAccent': 0xFF0F0F0F,
        },
      );

      final ThemeTokens resolved = theme.resolveTokens();
      expect(resolved.ink, const Color(0xFF010101));
      expect(resolved.onAccent, const Color(0xFF0F0F0F));
      expect(resolved.id, ThemeId.light);
    });
  });
}
