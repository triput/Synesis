// ==============================================================================
// File: lib/settings/app_settings_cubit.dart
// Description: Persisted appearance, Focus, retention, and desktop prefs
// Component: Bloc / Settings
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_id.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._prefs) : super(const AppSettingsState()) {
    _hydrate();
  }

  static const _key = 'bytemail.app_settings.v1';

  final SharedPreferences _prefs;

  void _hydrate() {
    final raw = _prefs.getString(_key);
    if (raw == null) return;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final focusMap = <String, bool>{};
      final rawFocus = map['accountFocusEnabled'];
      if (rawFocus is Map) {
        rawFocus.forEach((k, v) {
          focusMap[k.toString()] = v == true;
        });
      }
      emit(
        AppSettingsState(
          themeId: ThemeId.values.firstWhere(
            (e) => e.name == map['themeId'],
            orElse: () => ThemeId.dark,
          ),
          density: ViewDensity.values.firstWhere(
            (e) => e.name == map['density'],
            orElse: () => ViewDensity.calm,
          ),
          unifiedFocusEnabled: map['unifiedFocusEnabled'] as bool? ?? true,
          accountFocusEnabled: focusMap.isEmpty
              ? const {
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
        ),
      );
    } catch (_) {
      // Keep defaults on corrupt prefs.
    }
  }

  Future<void> _persist() async {
    await _prefs.setString(
      _key,
      jsonEncode({
        'themeId': state.themeId.name,
        'density': state.density.name,
        'unifiedFocusEnabled': state.unifiedFocusEnabled,
        'accountFocusEnabled': state.accountFocusEnabled,
        'retentionDays': state.retentionDays,
        'trashRetentionDays': state.trashRetentionDays,
        'minimizeToTray': state.minimizeToTray,
        'keyboardShortcutsEnabled': state.keyboardShortcutsEnabled,
        'threadDisplayMode': state.threadDisplayMode.name,
        'swipeRightAction': state.swipeRightAction.name,
        'swipeLeftAction': state.swipeLeftAction.name,
        'blockRemoteImages': state.blockRemoteImages,
        'pushOnCellular': state.pushOnCellular,
        'readingPanePosition': state.readingPanePosition.name,
        'visualFocusEnabled': state.visualFocusEnabled,
      }),
    );
  }

  Future<void> setTheme(ThemeId id) async {
    if (state.themeId == id) return;
    emit(state.copyWith(themeId: id));
    await _persist();
  }

  Future<void> setDensity(ViewDensity density) async {
    if (state.density == density) return;
    emit(state.copyWith(density: density));
    await _persist();
  }

  Future<void> setUnifiedFocusEnabled(bool enabled) async {
    if (state.unifiedFocusEnabled == enabled) return;
    emit(state.copyWith(unifiedFocusEnabled: enabled));
    await _persist();
  }

  Future<void> setAccountFocusEnabled(String accountId, bool enabled) async {
    if (state.isAccountFocusEnabled(accountId) == enabled) return;
    final next = Map<String, bool>.from(state.accountFocusEnabled)
      ..[accountId] = enabled;
    emit(state.copyWith(accountFocusEnabled: next));
    await _persist();
  }

  Future<void> removeAccountFocus(String accountId) async {
    if (!state.accountFocusEnabled.containsKey(accountId)) {
      return;
    }
    final Map<String, bool> next =
        Map<String, bool>.from(state.accountFocusEnabled)..remove(accountId);
    emit(state.copyWith(accountFocusEnabled: next));
    await _persist();
  }

  Future<void> setRetentionDays(int days) async {
    if (state.retentionDays == days) return;
    emit(state.copyWith(retentionDays: days));
    await _persist();
  }

  Future<void> setTrashRetentionDays(int days) async {
    final int clamped = days.clamp(7, 90);
    if (state.trashRetentionDays == clamped) return;
    emit(state.copyWith(trashRetentionDays: clamped));
    await _persist();
  }

  Future<void> setMinimizeToTray(bool enabled) async {
    if (state.minimizeToTray == enabled) return;
    emit(state.copyWith(minimizeToTray: enabled));
    await _persist();
  }

  Future<void> setKeyboardShortcutsEnabled(bool enabled) async {
    if (state.keyboardShortcutsEnabled == enabled) return;
    emit(state.copyWith(keyboardShortcutsEnabled: enabled));
    await _persist();
  }

  Future<void> setThreadDisplayMode(ThreadDisplayMode mode) async {
    if (state.threadDisplayMode == mode) return;
    emit(state.copyWith(threadDisplayMode: mode));
    await _persist();
  }

  Future<void> setSwipeRightAction(SwipeListAction action) async {
    if (state.swipeRightAction == action) return;
    emit(state.copyWith(swipeRightAction: action));
    await _persist();
  }

  Future<void> setSwipeLeftAction(SwipeListAction action) async {
    if (state.swipeLeftAction == action) return;
    emit(state.copyWith(swipeLeftAction: action));
    await _persist();
  }

  Future<void> setBlockRemoteImages(bool enabled) async {
    if (state.blockRemoteImages == enabled) return;
    emit(state.copyWith(blockRemoteImages: enabled));
    await _persist();
  }

  Future<void> setPushOnCellular(bool enabled) async {
    if (state.pushOnCellular == enabled) return;
    emit(state.copyWith(pushOnCellular: enabled));
    await _persist();
  }

  Future<void> setReadingPanePosition(ReadingPanePosition position) async {
    if (state.readingPanePosition == position) return;
    emit(state.copyWith(readingPanePosition: position));
    await _persist();
  }

  Future<void> setVisualFocusEnabled(bool enabled) async {
    if (state.visualFocusEnabled == enabled) return;
    emit(state.copyWith(visualFocusEnabled: enabled));
    await _persist();
  }
}
