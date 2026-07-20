// ==============================================================================
// File: test/app_settings_cubit_test.dart
// Description: Persistence tests for AppSettingsCubit including trash retention.
// Component: Test
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSettingsCubit trashRetentionDays', () {
    test('defaults to 30 days', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.trashRetentionDays, 30);
      await cubit.close();
    });

    test('persists and rehydrates trashRetentionDays', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setTrashRetentionDays(45);
      expect(cubit.state.trashRetentionDays, 45);
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.trashRetentionDays, 45);
      await reloaded.close();
    });

    test('clamps trashRetentionDays to 7–90', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setTrashRetentionDays(3);
      expect(cubit.state.trashRetentionDays, 7);

      await cubit.setTrashRetentionDays(120);
      expect(cubit.state.trashRetentionDays, 90);
      await cubit.close();
    });
  });

  group('AppSettingsCubit threadDisplayMode', () {
    test('defaults to threaded', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.threadDisplayMode, ThreadDisplayMode.threaded);
      await cubit.close();
    });

    test('persists and rehydrates threadDisplayMode', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setThreadDisplayMode(ThreadDisplayMode.flat);
      expect(cubit.state.threadDisplayMode, ThreadDisplayMode.flat);
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.threadDisplayMode, ThreadDisplayMode.flat);
      await reloaded.close();
    });

    test('missing prefs key falls back to threaded', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'bytemail.app_settings.v1':
            '{"themeId":"dark","density":"calm","unifiedFocusEnabled":true,'
            '"accountFocusEnabled":{},"retentionDays":180,'
            '"trashRetentionDays":30,"minimizeToTray":true,'
            '"keyboardShortcutsEnabled":true}',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.threadDisplayMode, ThreadDisplayMode.threaded);
      await cubit.close();
    });
  });

  group('AppSettingsCubit swipe actions', () {
    test('defaults to swipe right archive and left delete', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.swipeRightAction, SwipeListAction.archive);
      expect(cubit.state.swipeLeftAction, SwipeListAction.delete);
      await cubit.close();
    });

    test('persists and rehydrates swipe actions', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setSwipeRightAction(SwipeListAction.star);
      await cubit.setSwipeLeftAction(SwipeListAction.snooze);
      expect(cubit.state.swipeRightAction, SwipeListAction.star);
      expect(cubit.state.swipeLeftAction, SwipeListAction.snooze);
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.swipeRightAction, SwipeListAction.star);
      expect(reloaded.state.swipeLeftAction, SwipeListAction.snooze);
      await reloaded.close();
    });

    test('missing swipe prefs fall back to archive / delete', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'bytemail.app_settings.v1':
            '{"themeId":"dark","density":"calm","unifiedFocusEnabled":true,'
            '"accountFocusEnabled":{},"retentionDays":180,'
            '"trashRetentionDays":30,"minimizeToTray":true,'
            '"keyboardShortcutsEnabled":true,"threadDisplayMode":"flat"}',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.swipeRightAction, SwipeListAction.archive);
      expect(cubit.state.swipeLeftAction, SwipeListAction.delete);
      await cubit.close();
    });
  });

  group('AppSettingsCubit blockRemoteImages', () {
    test('defaults to true (privacy-first)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.blockRemoteImages, isTrue);
      await cubit.close();
    });

    test('persists and rehydrates blockRemoteImages', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setBlockRemoteImages(false);
      expect(cubit.state.blockRemoteImages, isFalse);
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.blockRemoteImages, isFalse);
      await reloaded.close();
    });

    test('missing prefs key falls back to true', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'bytemail.app_settings.v1':
            '{"themeId":"dark","density":"calm","unifiedFocusEnabled":true,'
            '"accountFocusEnabled":{},"retentionDays":180,'
            '"trashRetentionDays":30,"minimizeToTray":true,'
            '"keyboardShortcutsEnabled":true}',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.blockRemoteImages, isTrue);
      await cubit.close();
    });
  });

  group('AppSettingsCubit pushOnCellular', () {
    test('defaults to false (opt-in cellular push)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.pushOnCellular, isFalse);
      await cubit.close();
    });

    test('persists and rehydrates pushOnCellular', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setPushOnCellular(true);
      expect(cubit.state.pushOnCellular, isTrue);
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.pushOnCellular, isTrue);
      await reloaded.close();
    });

    test('missing prefs key falls back to false', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'bytemail.app_settings.v1':
            '{"themeId":"dark","density":"calm","unifiedFocusEnabled":true,'
            '"accountFocusEnabled":{},"retentionDays":180,'
            '"trashRetentionDays":30,"minimizeToTray":true,'
            '"keyboardShortcutsEnabled":true}',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.pushOnCellular, isFalse);
      await cubit.close();
    });
  });

  group('AppSettingsCubit readingPanePosition', () {
    test('defaults to right', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.readingPanePosition, ReadingPanePosition.right);
      await cubit.close();
    });

    test('persists and rehydrates readingPanePosition', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setReadingPanePosition(ReadingPanePosition.bottom);
      expect(cubit.state.readingPanePosition, ReadingPanePosition.bottom);
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.readingPanePosition, ReadingPanePosition.bottom);

      await reloaded.setReadingPanePosition(ReadingPanePosition.top);
      expect(reloaded.state.readingPanePosition, ReadingPanePosition.top);
      await reloaded.close();

      final AppSettingsCubit again = AppSettingsCubit(prefs);
      expect(again.state.readingPanePosition, ReadingPanePosition.top);
      await again.close();
    });

    test('missing prefs key falls back to right', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'bytemail.app_settings.v1':
            '{"themeId":"dark","density":"calm","unifiedFocusEnabled":true,'
            '"accountFocusEnabled":{},"retentionDays":180,'
            '"trashRetentionDays":30,"minimizeToTray":true,'
            '"keyboardShortcutsEnabled":true}',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.readingPanePosition, ReadingPanePosition.right);
      await cubit.close();
    });
  });

  group('AppSettingsCubit visualFocusEnabled', () {
    test('defaults to false', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.visualFocusEnabled, isFalse);
      await cubit.close();
    });

    test('persists and rehydrates visualFocusEnabled', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setVisualFocusEnabled(true);
      expect(cubit.state.visualFocusEnabled, isTrue);
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.visualFocusEnabled, isTrue);
      await reloaded.close();
    });

    test('missing prefs key falls back to false', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'bytemail.app_settings.v1':
            '{"themeId":"dark","density":"calm","unifiedFocusEnabled":true,'
            '"accountFocusEnabled":{},"retentionDays":180,'
            '"trashRetentionDays":30,"minimizeToTray":true,'
            '"keyboardShortcutsEnabled":true}',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.visualFocusEnabled, isFalse);
      await cubit.close();
    });
  });

  group('AppSettingsCubit notifications', () {
    test('defaults: global on, quiet hours off, starred-only off', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.notificationsEnabled, isTrue);
      expect(cubit.state.notifyStarredOnly, isFalse);
      expect(cubit.state.notificationQuietHoursEnabled, isFalse);
      expect(cubit.state.quietHoursStartMinutes, 22 * 60);
      expect(cubit.state.quietHoursEndMinutes, 7 * 60);
      expect(cubit.state.isAccountNotificationsEnabled('any'), isTrue);
      await cubit.close();
    });

    test('persists and rehydrates notification prefs', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setNotificationsEnabled(false);
      await cubit.setNotifyStarredOnly(true);
      await cubit.setNotificationQuietHoursEnabled(true);
      await cubit.setQuietHoursStartMinutes(21 * 60);
      await cubit.setQuietHoursEndMinutes(6 * 60);
      await cubit.setAccountNotificationsEnabled('work', false);
      expect(cubit.state.notificationsEnabled, isFalse);
      expect(cubit.state.notifyStarredOnly, isTrue);
      expect(cubit.state.notificationQuietHoursEnabled, isTrue);
      expect(cubit.state.quietHoursStartMinutes, 21 * 60);
      expect(cubit.state.quietHoursEndMinutes, 6 * 60);
      expect(cubit.state.isAccountNotificationsEnabled('work'), isFalse);
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.notificationsEnabled, isFalse);
      expect(reloaded.state.notifyStarredOnly, isTrue);
      expect(reloaded.state.notificationQuietHoursEnabled, isTrue);
      expect(reloaded.state.quietHoursStartMinutes, 21 * 60);
      expect(reloaded.state.quietHoursEndMinutes, 6 * 60);
      expect(reloaded.state.isAccountNotificationsEnabled('work'), isFalse);
      expect(reloaded.state.isAccountNotificationsEnabled('other'), isTrue);
      await reloaded.close();
    });

    test('missing notification prefs fall back to defaults', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'bytemail.app_settings.v1':
            '{"themeId":"dark","density":"calm","unifiedFocusEnabled":true,'
            '"accountFocusEnabled":{},"retentionDays":180,'
            '"trashRetentionDays":30,"minimizeToTray":true,'
            '"keyboardShortcutsEnabled":true}',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.notificationsEnabled, isTrue);
      expect(cubit.state.notifyStarredOnly, isFalse);
      expect(cubit.state.notificationQuietHoursEnabled, isFalse);
      expect(cubit.state.quietHoursStartMinutes, 22 * 60);
      expect(cubit.state.quietHoursEndMinutes, 7 * 60);
      await cubit.close();
    });
  });

  group('AppSettingsCubit custom theme id (UI-P16)', () {
    test('defaults to null (built-in theme)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.customThemeId, isNull);
      await cubit.close();
    });

    test('persists and rehydrates a custom theme id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setCustomThemeId('custom_123');
      expect(cubit.state.customThemeId, 'custom_123');
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.customThemeId, 'custom_123');
      await reloaded.close();
    });

    test('setCustomThemeId(null) clears a previously selected custom theme', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setCustomThemeId('custom_123');
      await cubit.setCustomThemeId(null);
      expect(cubit.state.customThemeId, isNull);
      await cubit.close();
    });

    test('setTheme(builtIn) clears a previously selected custom theme', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setCustomThemeId('custom_123');
      expect(cubit.state.customThemeId, 'custom_123');

      await cubit.setTheme(ThemeId.light);
      expect(cubit.state.themeId, ThemeId.light);
      expect(cubit.state.customThemeId, isNull);
      await cubit.close();
    });
  });

  group('AppSettingsCubit UI font settings (UI-P18)', () {
    test('defaults: no family override, 1.0 scale, no color override', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.uiFontFamily, isNull);
      expect(cubit.state.uiFontSizeScale, 1.0);
      expect(cubit.state.uiTextColorArgb, isNull);
      await cubit.close();
    });

    test('persists and rehydrates uiFontFamily', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setUiFontFamily('openSans');
      expect(cubit.state.uiFontFamily, 'openSans');
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.uiFontFamily, 'openSans');

      await reloaded.setUiFontFamily(null);
      expect(reloaded.state.uiFontFamily, isNull);
      await reloaded.close();
    });

    test('clamps uiFontSizeScale to 0.85–1.3', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setUiFontSizeScale(0.5);
      expect(cubit.state.uiFontSizeScale, kUiFontSizeScaleMin);

      await cubit.setUiFontSizeScale(2.0);
      expect(cubit.state.uiFontSizeScale, kUiFontSizeScaleMax);

      await cubit.setUiFontSizeScale(1.1);
      expect(cubit.state.uiFontSizeScale, 1.1);
      await cubit.close();
    });

    test('persists and rehydrates uiTextColorArgb, then clears it', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      await cubit.setUiTextColorArgb(0xFFAABBCC);
      expect(cubit.state.uiTextColorArgb, 0xFFAABBCC);
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.uiTextColorArgb, 0xFFAABBCC);

      await reloaded.setUiTextColorArgb(null);
      expect(reloaded.state.uiTextColorArgb, isNull);
      await reloaded.close();
    });

    test('missing prefs keys fall back to UI font defaults', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'bytemail.app_settings.v1':
            '{"themeId":"dark","density":"calm","unifiedFocusEnabled":true,'
            '"accountFocusEnabled":{},"retentionDays":180,'
            '"trashRetentionDays":30,"minimizeToTray":true,'
            '"keyboardShortcutsEnabled":true}',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);
      expect(cubit.state.uiFontFamily, isNull);
      expect(cubit.state.uiFontSizeScale, 1.0);
      expect(cubit.state.uiTextColorArgb, isNull);
      await cubit.close();
    });
  });

  group('AppSettingsCubit.replaceState (UI-P17 settings import)', () {
    test('replaces the entire state and persists it', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final AppSettingsCubit cubit = AppSettingsCubit(prefs);

      final AppSettingsState imported = const AppSettingsState().copyWith(
        themeId: ThemeId.black,
        uiFontFamily: 'roboto',
        uiFontSizeScale: 1.2,
        retentionDays: 60,
      );
      await cubit.replaceState(imported);

      expect(cubit.state.themeId, ThemeId.black);
      expect(cubit.state.uiFontFamily, 'roboto');
      expect(cubit.state.uiFontSizeScale, 1.2);
      expect(cubit.state.retentionDays, 60);
      await cubit.close();

      final AppSettingsCubit reloaded = AppSettingsCubit(prefs);
      expect(reloaded.state.themeId, ThemeId.black);
      expect(reloaded.state.uiFontFamily, 'roboto');
      expect(reloaded.state.retentionDays, 60);
      await reloaded.close();
    });
  });
}
