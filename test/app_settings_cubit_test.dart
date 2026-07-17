// ==============================================================================
// File: test/app_settings_cubit_test.dart
// Description: Persistence tests for AppSettingsCubit including trash retention.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/app_settings_state.dart';
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
}
