// ==============================================================================
// File: lib/repository/drift/drift_custom_theme_store.dart
// Description: Drift CRUD for user-defined theme forks (UI-P16).
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/repository/database.dart' hide CustomTheme;
import 'package:bytemail/theme/custom_theme.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:drift/drift.dart';

class DriftCustomThemeStore {
  DriftCustomThemeStore(
    this._database, {
    required void Function() notify,
  }) : _notify = notify;

  final ByteMailDatabase _database;
  final void Function() _notify;

  Future<List<CustomTheme>> listCustomThemes() async {
    final query = _database.select(_database.customThemes)
      ..orderBy(<OrderingTerm Function($CustomThemesTable)>[
        (t) => OrderingTerm.asc(t.name),
      ]);
    final rows = await query.get();
    return <CustomTheme>[
      for (final row in rows)
        CustomTheme(
          id: row.id,
          name: row.name,
          baseThemeId: _baseThemeIdFrom(row.baseThemeId),
          tokenOverrides: _decodeOverrides(row.tokenOverridesJson),
        ),
    ];
  }

  Future<CustomTheme?> getCustomTheme(String id) async {
    final row = await (_database.select(
      _database.customThemes,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return CustomTheme(
      id: row.id,
      name: row.name,
      baseThemeId: _baseThemeIdFrom(row.baseThemeId),
      tokenOverrides: _decodeOverrides(row.tokenOverridesJson),
    );
  }

  Future<String> upsertCustomTheme(CustomTheme theme) async {
    await _database.into(_database.customThemes).insertOnConflictUpdate(
          CustomThemesCompanion.insert(
            id: theme.id,
            name: theme.name,
            baseThemeId: theme.baseThemeId.name,
            tokenOverridesJson: jsonEncode(theme.tokenOverrides),
          ),
        );
    _notify();
    return theme.id;
  }

  Future<void> deleteCustomTheme(String id) async {
    await (_database.delete(
      _database.customThemes,
    )..where((t) => t.id.equals(id))).go();
    _notify();
  }

  ThemeId _baseThemeIdFrom(String name) {
    return ThemeId.values.firstWhere(
      (ThemeId id) => id.name == name,
      orElse: () => ThemeId.dark,
    );
  }

  Map<String, int> _decodeOverrides(String json) {
    final Map<String, int> overrides = <String, int>{};
    try {
      final Object? decoded = jsonDecode(json);
      if (decoded is Map) {
        decoded.forEach((Object? key, Object? value) {
          if (key is String && value is int) {
            overrides[key] = value;
          }
        });
      }
    } on FormatException {
      // Corrupt overrides fall back to the unmodified base pack.
    }
    return overrides;
  }
}
