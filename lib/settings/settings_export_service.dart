// ==============================================================================
// File: lib/settings/settings_export_service.dart
// Description: Versioned JSON export/import for appearance prefs (UI-P17)
// Component: Domain / Settings
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/theme/custom_theme.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_id.dart';

/// Current [SettingsExportService] JSON schema version.
const int kSettingsExportFormatVersion = 1;

/// Decoded, validated settings export payload (UI-P17).
class SettingsExportBundle {
  const SettingsExportBundle({
    required this.settings,
    required this.customThemes,
    required this.exportedAt,
  });

  final AppSettingsState settings;
  final List<CustomTheme> customThemes;
  final DateTime exportedAt;
}

/// Encodes and decodes a versioned, secret-free JSON snapshot of
/// user-visible ByteMail appearance preferences plus custom themes.
///
/// Account credentials, OAuth tokens, and other secrets are never part of
/// [AppSettingsState] or [CustomTheme], but [validate] defensively rejects
/// any key that looks like a credential/secret so a hand-edited or corrupted
/// import file cannot smuggle sensitive data through this path.
class SettingsExportService {
  const SettingsExportService();

  /// Lower-cased substrings that must never appear anywhere in an
  /// export/import key. These are unambiguous enough that no legitimate
  /// ByteMail preference key contains them.
  static const Set<String> secretKeySubstrings = <String>{
    'credential',
    'password',
    'passwd',
    'secret',
    'apikey',
    'authorization',
  };

  /// Lower-cased exact key names denylisted for looking like bearer/OAuth
  /// tokens. Matched by full key equality (not substring) so legitimate
  /// keys such as `tokenOverrides` are never mistaken for a secret.
  static const Set<String> secretExactKeyNames = <String>{
    'token',
    'accesstoken',
    'refreshtoken',
    'authtoken',
    'idtoken',
    'bearertoken',
    'sessiontoken',
    'oauthtoken',
  };

  /// Builds the exportable JSON map for [settings] and [customThemes].
  Map<String, dynamic> encode({
    required AppSettingsState settings,
    List<CustomTheme> customThemes = const <CustomTheme>[],
    DateTime? exportedAt,
  }) {
    return <String, dynamic>{
      'formatVersion': kSettingsExportFormatVersion,
      'exportedAt': (exportedAt ?? DateTime.now()).toIso8601String(),
      'settings': _settingsToJson(settings),
      'customThemes': <Map<String, dynamic>>[
        for (final CustomTheme theme in customThemes)
          _customThemeToJson(theme),
      ],
    };
  }

  /// Convenience: [encode] then pretty-printed `jsonEncode`.
  String encodeToString({
    required AppSettingsState settings,
    List<CustomTheme> customThemes = const <CustomTheme>[],
    DateTime? exportedAt,
  }) {
    final Map<String, dynamic> json = encode(
      settings: settings,
      customThemes: customThemes,
      exportedAt: exportedAt,
    );
    return const JsonEncoder.withIndent('  ').convert(json);
  }

  /// Validates [json]'s shape, format version, and absence of secret-like
  /// keys. Throws [FormatException] when invalid.
  void validate(Object? json) {
    if (json is! Map) {
      throw const FormatException('Settings export must be a JSON object.');
    }
    final Object? version = json['formatVersion'];
    if (version is! int ||
        version < 1 ||
        version > kSettingsExportFormatVersion) {
      throw FormatException('Unsupported settings export version: $version');
    }
    if (json['settings'] is! Map) {
      throw const FormatException('Settings export is missing "settings".');
    }
    _assertNoSecretKeys(json);
  }

  /// Parses and validates [json] into a [SettingsExportBundle].
  SettingsExportBundle decode(Object? json) {
    validate(json);
    final Map<Object?, Object?> root = json! as Map<Object?, Object?>;
    final Map<Object?, Object?> settingsJson =
        root['settings']! as Map<Object?, Object?>;
    final Object? rawThemes = root['customThemes'];
    final List<CustomTheme> customThemes = <CustomTheme>[
      if (rawThemes is List)
        for (final Object? entry in rawThemes)
          if (entry is Map) _customThemeFromJson(entry),
    ];
    final Object? exportedAtRaw = root['exportedAt'];
    final DateTime exportedAt = exportedAtRaw is String
        ? DateTime.tryParse(exportedAtRaw) ?? DateTime.now()
        : DateTime.now();

    return SettingsExportBundle(
      settings: _settingsFromJson(settingsJson),
      customThemes: customThemes,
      exportedAt: exportedAt,
    );
  }

  /// Parses a raw JSON string previously produced by [encodeToString].
  SettingsExportBundle decodeString(String raw) => decode(jsonDecode(raw));

  void _assertNoSecretKeys(Object? node) {
    if (node is Map) {
      node.forEach((Object? key, Object? value) {
        final String normalized = key.toString().toLowerCase();
        final bool isSecretLike =
            secretKeySubstrings.any(normalized.contains) ||
                secretExactKeyNames.contains(normalized);
        if (isSecretLike) {
          throw FormatException(
            'Settings export contains a disallowed key: $key',
          );
        }
        _assertNoSecretKeys(value);
      });
    } else if (node is List) {
      for (final Object? item in node) {
        _assertNoSecretKeys(item);
      }
    }
  }

  Map<String, dynamic> _settingsToJson(AppSettingsState s) {
    return <String, dynamic>{
      'themeId': s.themeId.name,
      'density': s.density.name,
      'unifiedFocusEnabled': s.unifiedFocusEnabled,
      'accountFocusEnabled': s.accountFocusEnabled,
      'retentionDays': s.retentionDays,
      'trashRetentionDays': s.trashRetentionDays,
      'minimizeToTray': s.minimizeToTray,
      'keyboardShortcutsEnabled': s.keyboardShortcutsEnabled,
      'threadDisplayMode': s.threadDisplayMode.name,
      'swipeRightAction': s.swipeRightAction.name,
      'swipeLeftAction': s.swipeLeftAction.name,
      'blockRemoteImages': s.blockRemoteImages,
      'pushOnCellular': s.pushOnCellular,
      'readingPanePosition': s.readingPanePosition.name,
      'visualFocusEnabled': s.visualFocusEnabled,
      'notificationsEnabled': s.notificationsEnabled,
      'notifyStarredOnly': s.notifyStarredOnly,
      'notificationQuietHoursEnabled': s.notificationQuietHoursEnabled,
      'quietHoursStartMinutes': s.quietHoursStartMinutes,
      'quietHoursEndMinutes': s.quietHoursEndMinutes,
      'accountNotificationsEnabled': s.accountNotificationsEnabled,
      'customThemeId': s.customThemeId,
      'uiFontFamily': s.uiFontFamily,
      'uiFontSizeScale': s.uiFontSizeScale,
      'uiTextColorArgb': s.uiTextColorArgb,
    };
  }

  AppSettingsState _settingsFromJson(Map<Object?, Object?> map) {
    final Map<String, bool> focusMap = <String, bool>{};
    final Object? rawFocus = map['accountFocusEnabled'];
    if (rawFocus is Map) {
      rawFocus.forEach(
        (Object? k, Object? v) => focusMap[k.toString()] = v == true,
      );
    }
    final Map<String, bool> notificationsMap = <String, bool>{};
    final Object? rawNotifications = map['accountNotificationsEnabled'];
    if (rawNotifications is Map) {
      rawNotifications.forEach(
        (Object? k, Object? v) => notificationsMap[k.toString()] = v == true,
      );
    }
    return AppSettingsState(
      themeId: ThemeId.values.firstWhere(
        (ThemeId e) => e.name == map['themeId'],
        orElse: () => ThemeId.dark,
      ),
      density: ViewDensity.values.firstWhere(
        (ViewDensity e) => e.name == map['density'],
        orElse: () => ViewDensity.calm,
      ),
      unifiedFocusEnabled: map['unifiedFocusEnabled'] as bool? ?? true,
      accountFocusEnabled: focusMap.isEmpty
          ? const <String, bool>{
              'work': true,
              'personal': true,
              'side': false,
            }
          : focusMap,
      retentionDays: map['retentionDays'] as int? ?? 180,
      trashRetentionDays: map['trashRetentionDays'] as int? ?? 30,
      minimizeToTray: map['minimizeToTray'] as bool? ?? true,
      keyboardShortcutsEnabled:
          map['keyboardShortcutsEnabled'] as bool? ?? true,
      threadDisplayMode: ThreadDisplayMode.values.firstWhere(
        (ThreadDisplayMode e) => e.name == map['threadDisplayMode'],
        orElse: () => ThreadDisplayMode.threaded,
      ),
      swipeRightAction: SwipeListAction.values.firstWhere(
        (SwipeListAction e) => e.name == map['swipeRightAction'],
        orElse: () => SwipeListAction.archive,
      ),
      swipeLeftAction: SwipeListAction.values.firstWhere(
        (SwipeListAction e) => e.name == map['swipeLeftAction'],
        orElse: () => SwipeListAction.delete,
      ),
      blockRemoteImages: map['blockRemoteImages'] as bool? ?? true,
      pushOnCellular: map['pushOnCellular'] as bool? ?? false,
      readingPanePosition: ReadingPanePosition.values.firstWhere(
        (ReadingPanePosition e) => e.name == map['readingPanePosition'],
        orElse: () => ReadingPanePosition.right,
      ),
      visualFocusEnabled: map['visualFocusEnabled'] as bool? ?? false,
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      notifyStarredOnly: map['notifyStarredOnly'] as bool? ?? false,
      notificationQuietHoursEnabled:
          map['notificationQuietHoursEnabled'] as bool? ?? false,
      quietHoursStartMinutes:
          map['quietHoursStartMinutes'] as int? ?? 22 * 60,
      quietHoursEndMinutes: map['quietHoursEndMinutes'] as int? ?? 7 * 60,
      accountNotificationsEnabled: notificationsMap,
      customThemeId: map['customThemeId'] as String?,
      uiFontFamily: map['uiFontFamily'] as String?,
      uiFontSizeScale: (map['uiFontSizeScale'] as num?)?.toDouble() ?? 1.0,
      uiTextColorArgb: map['uiTextColorArgb'] as int?,
    );
  }

  Map<String, dynamic> _customThemeToJson(CustomTheme theme) {
    return <String, dynamic>{
      'id': theme.id,
      'name': theme.name,
      'baseThemeId': theme.baseThemeId.name,
      'tokenOverrides': theme.tokenOverrides,
    };
  }

  CustomTheme _customThemeFromJson(Map<Object?, Object?> map) {
    final Map<String, int> overrides = <String, int>{};
    final Object? raw = map['tokenOverrides'];
    if (raw is Map) {
      raw.forEach((Object? k, Object? v) {
        if (k is String && v is int) {
          overrides[k] = v;
        }
      });
    }
    return CustomTheme(
      id: map['id'] as String? ??
          'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: map['name'] as String? ?? 'Imported theme',
      baseThemeId: ThemeId.values.firstWhere(
        (ThemeId e) => e.name == map['baseThemeId'],
        orElse: () => ThemeId.dark,
      ),
      tokenOverrides: overrides,
    );
  }
}
