// ==============================================================================
// File: test/settings_export_service_test.dart
// Description: Roundtrip, secret-rejection, and version-validation coverage (UI-P17).
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/settings/settings_export_service.dart';
import 'package:bytemail/theme/custom_theme.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const SettingsExportService service = SettingsExportService();

  group('SettingsExportService encode/decode roundtrip', () {
    test('roundtrips default settings with no custom themes', () {
      const AppSettingsState settings = AppSettingsState();
      final Map<String, dynamic> json = service.encode(settings: settings);

      expect(json['formatVersion'], kSettingsExportFormatVersion);
      expect(json['exportedAt'], isA<String>());
      expect(json['customThemes'], isEmpty);

      final SettingsExportBundle bundle = service.decode(json);
      expect(bundle.settings, settings);
      expect(bundle.customThemes, isEmpty);
    });

    test('roundtrips customized settings and custom themes', () {
      final AppSettingsState settings = const AppSettingsState().copyWith(
        themeId: ThemeId.black,
        density: ViewDensity.compact,
        unifiedFocusEnabled: false,
        retentionDays: 90,
        trashRetentionDays: 45,
        threadDisplayMode: ThreadDisplayMode.flat,
        swipeRightAction: SwipeListAction.star,
        swipeLeftAction: SwipeListAction.snooze,
        blockRemoteImages: false,
        readingPanePosition: ReadingPanePosition.bottom,
        customThemeId: 'custom_1',
        uiFontFamily: 'openSans',
        uiFontSizeScale: 1.15,
        uiTextColorArgb: 0xFFAABBCC,
        accountFocusEnabled: const <String, bool>{'work': false},
        accountNotificationsEnabled: const <String, bool>{'work': false},
      );
      const List<CustomTheme> customThemes = <CustomTheme>[
        CustomTheme(
          id: 'custom_1',
          name: 'Sunset',
          baseThemeId: ThemeId.dark,
          tokenOverrides: <String, int>{'teal': 0xFFFF7043},
        ),
      ];

      final String encoded = service.encodeToString(
        settings: settings,
        customThemes: customThemes,
      );
      final SettingsExportBundle bundle = service.decodeString(encoded);

      expect(bundle.settings, settings);
      expect(bundle.customThemes, hasLength(1));
      expect(bundle.customThemes.single.id, 'custom_1');
      expect(bundle.customThemes.single.name, 'Sunset');
      expect(
        bundle.customThemes.single.tokenOverrides['teal'],
        0xFFFF7043,
      );
    });

    test('decode falls back to defaults for missing settings keys', () {
      final SettingsExportBundle bundle = service.decode(<String, dynamic>{
        'formatVersion': 1,
        'exportedAt': DateTime(2026, 1, 1).toIso8601String(),
        'settings': <String, dynamic>{},
      });

      expect(bundle.settings, const AppSettingsState());
      expect(bundle.exportedAt, DateTime(2026, 1, 1));
    });
  });

  group('SettingsExportService.validate', () {
    test('rejects a non-map payload', () {
      expect(() => service.validate('not a map'), throwsFormatException);
      expect(() => service.validate(null), throwsFormatException);
    });

    test('rejects a missing formatVersion', () {
      expect(
        () => service.validate(<String, dynamic>{'settings': <String, dynamic>{}}),
        throwsFormatException,
      );
    });

    test('rejects a formatVersion newer than supported', () {
      expect(
        () => service.validate(<String, dynamic>{
          'formatVersion': kSettingsExportFormatVersion + 1,
          'settings': <String, dynamic>{},
        }),
        throwsFormatException,
      );
    });

    test('rejects a formatVersion below 1', () {
      expect(
        () => service.validate(<String, dynamic>{
          'formatVersion': 0,
          'settings': <String, dynamic>{},
        }),
        throwsFormatException,
      );
    });

    test('rejects a payload missing "settings"', () {
      expect(
        () => service.validate(<String, dynamic>{'formatVersion': 1}),
        throwsFormatException,
      );
    });

    test('accepts a well-formed payload', () {
      final Map<String, dynamic> json = service.encode(
        settings: const AppSettingsState(),
      );
      expect(() => service.validate(json), returnsNormally);
    });

    test('rejects a top-level key that looks like a secret', () {
      final Map<String, dynamic> json = service.encode(
        settings: const AppSettingsState(),
      );
      json['authToken'] = 'sk-live-secret';
      expect(() => service.validate(json), throwsFormatException);
    });

    test('rejects a nested key that looks like a credential', () {
      final Map<String, dynamic> json = service.encode(
        settings: const AppSettingsState(),
      );
      (json['settings'] as Map<String, dynamic>)['accountCredentials'] =
          'super-secret';
      expect(() => service.validate(json), throwsFormatException);
    });

    test('rejects a secret key inside a custom theme entry', () {
      final Map<String, dynamic> json = service.encode(
        settings: const AppSettingsState(),
        customThemes: const <CustomTheme>[
          CustomTheme(id: 'x', name: 'X', baseThemeId: ThemeId.dark),
        ],
      );
      (json['customThemes'] as List<dynamic>).add(<String, dynamic>{
        'password': 'nope',
      });
      expect(() => service.validate(json), throwsFormatException);
    });

    test('decode also rejects payloads with secret-like keys', () {
      expect(
        () => service.decode(<String, dynamic>{
          'formatVersion': 1,
          'settings': <String, dynamic>{'refreshToken': 'nope'},
        }),
        throwsFormatException,
      );
    });
  });
}
