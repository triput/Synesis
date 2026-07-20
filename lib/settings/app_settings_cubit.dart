// ==============================================================================
// File: lib/settings/app_settings_cubit.dart
// Description: Persisted appearance, Focus, retention, and desktop prefs
// Component: Bloc / Settings
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemail/domain/saved_message_filter.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:uuid/uuid.dart';

class AppSettingsCubit extends Cubit<AppSettingsState> {
  AppSettingsCubit(this._prefs) : super(const AppSettingsState()) {
    _hydrate();
  }

  static const _key = 'bytemail.app_settings.v1';

  final SharedPreferences _prefs;
  final Uuid _uuid = const Uuid();

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
      final Map<String, bool> notificationsMap = <String, bool>{};
      final Object? rawNotifications = map['accountNotificationsEnabled'];
      if (rawNotifications is Map) {
        rawNotifications.forEach((Object? k, Object? v) {
          notificationsMap[k.toString()] = v == true;
        });
      }
      final List<SavedMessageFilter> savedFilters = <SavedMessageFilter>[];
      final Object? rawSavedFilters = map['savedFilters'];
      if (rawSavedFilters is List) {
        for (final Object? entry in rawSavedFilters) {
          if (entry is Map) {
            try {
              savedFilters.add(
                SavedMessageFilter.fromJson(
                  Map<String, dynamic>.from(entry),
                ),
              );
            } catch (_) {
              // Skip corrupt entries.
            }
          }
        }
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
          uiFontSizeScale:
              (map['uiFontSizeScale'] as num?)?.toDouble() ?? 1.0,
          uiTextColorArgb: map['uiTextColorArgb'] as int?,
          savedFilters: savedFilters,
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
        'notificationsEnabled': state.notificationsEnabled,
        'notifyStarredOnly': state.notifyStarredOnly,
        'notificationQuietHoursEnabled': state.notificationQuietHoursEnabled,
        'quietHoursStartMinutes': state.quietHoursStartMinutes,
        'quietHoursEndMinutes': state.quietHoursEndMinutes,
        'accountNotificationsEnabled': state.accountNotificationsEnabled,
        'customThemeId': state.customThemeId,
        'uiFontFamily': state.uiFontFamily,
        'uiFontSizeScale': state.uiFontSizeScale,
        'uiTextColorArgb': state.uiTextColorArgb,
        'savedFilters': state.savedFilters
            .map((SavedMessageFilter filter) => filter.toJson())
            .toList(growable: false),
      }),
    );
  }

  /// Replaces the entire state (UI-P17 settings import) and persists it.
  Future<void> replaceState(AppSettingsState next) async {
    emit(next);
    await _persist();
  }

  /// Selects a built-in theme pack, clearing any custom theme override
  /// (UI-P16: built-in selection always wins over a stale custom pick).
  Future<void> setTheme(ThemeId id) async {
    if (state.themeId == id && state.customThemeId == null) return;
    emit(state.copyWith(themeId: id, clearCustomThemeId: true));
    await _persist();
  }

  /// Selects a user-defined custom theme by id, or clears it to revert to
  /// the built-in [AppSettingsState.themeId] pack when [id] is null.
  Future<void> setCustomThemeId(String? id) async {
    if (state.customThemeId == id) return;
    emit(
      id == null
          ? state.copyWith(clearCustomThemeId: true)
          : state.copyWith(customThemeId: id),
    );
    await _persist();
  }

  /// Sets the UI font family override, or clears it to use the theme default
  /// font pairing when [family] is null.
  Future<void> setUiFontFamily(String? family) async {
    if (state.uiFontFamily == family) return;
    emit(
      family == null
          ? state.copyWith(clearUiFontFamily: true)
          : state.copyWith(uiFontFamily: family),
    );
    await _persist();
  }

  /// Sets the UI text scale, clamped to
  /// [kUiFontSizeScaleMin]–[kUiFontSizeScaleMax].
  Future<void> setUiFontSizeScale(double scale) async {
    final double clamped = scale.clamp(
      kUiFontSizeScaleMin,
      kUiFontSizeScaleMax,
    );
    if (state.uiFontSizeScale == clamped) return;
    emit(state.copyWith(uiFontSizeScale: clamped));
    await _persist();
  }

  /// Sets an ARGB body text color override, or clears it to use the active
  /// theme's default text color when [argb] is null.
  Future<void> setUiTextColorArgb(int? argb) async {
    if (state.uiTextColorArgb == argb) return;
    emit(
      argb == null
          ? state.copyWith(clearUiTextColorArgb: true)
          : state.copyWith(uiTextColorArgb: argb),
    );
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

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (state.notificationsEnabled == enabled) return;
    emit(state.copyWith(notificationsEnabled: enabled));
    await _persist();
  }

  Future<void> setNotifyStarredOnly(bool enabled) async {
    if (state.notifyStarredOnly == enabled) return;
    emit(state.copyWith(notifyStarredOnly: enabled));
    await _persist();
  }

  Future<void> setNotificationQuietHoursEnabled(bool enabled) async {
    if (state.notificationQuietHoursEnabled == enabled) return;
    emit(state.copyWith(notificationQuietHoursEnabled: enabled));
    await _persist();
  }

  Future<void> setQuietHoursStartMinutes(int minutes) async {
    final int clamped = minutes.clamp(0, 1439);
    if (state.quietHoursStartMinutes == clamped) return;
    emit(state.copyWith(quietHoursStartMinutes: clamped));
    await _persist();
  }

  Future<void> setQuietHoursEndMinutes(int minutes) async {
    final int clamped = minutes.clamp(0, 1439);
    if (state.quietHoursEndMinutes == clamped) return;
    emit(state.copyWith(quietHoursEndMinutes: clamped));
    await _persist();
  }

  Future<void> setAccountNotificationsEnabled(
    String accountId,
    bool enabled,
  ) async {
    if (state.isAccountNotificationsEnabled(accountId) == enabled) return;
    final Map<String, bool> next =
        Map<String, bool>.from(state.accountNotificationsEnabled)
          ..[accountId] = enabled;
    emit(state.copyWith(accountNotificationsEnabled: next));
    await _persist();
  }

  /// Saves [filter] under [name]. Returns false when the soft cap is reached.
  Future<bool> saveSavedFilter(String name, MessageViewFilter filter) async {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) {
      return false;
    }
    if (state.savedFilters.length >= kMaxSavedMessageFilters) {
      return false;
    }
    final int now = DateTime.now().millisecondsSinceEpoch;
    final SavedMessageFilter saved = SavedMessageFilter(
      id: _uuid.v4(),
      name: trimmed,
      filter: filter,
      createdAt: now,
      updatedAt: now,
    );
    emit(
      state.copyWith(
        savedFilters: <SavedMessageFilter>[...state.savedFilters, saved],
      ),
    );
    await _persist();
    return true;
  }

  Future<void> renameSavedFilter(String id, String newName) async {
    final String trimmed = newName.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final int index = state.savedFilters.indexWhere(
      (SavedMessageFilter filter) => filter.id == id,
    );
    if (index < 0) {
      return;
    }
    final SavedMessageFilter existing = state.savedFilters[index];
    if (existing.name == trimmed) {
      return;
    }
    final List<SavedMessageFilter> next =
        List<SavedMessageFilter>.from(state.savedFilters);
    next[index] = existing.copyWith(
      name: trimmed,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );
    emit(state.copyWith(savedFilters: next));
    await _persist();
  }

  Future<void> deleteSavedFilter(String id) async {
    if (!state.savedFilters.any((SavedMessageFilter filter) => filter.id == id)) {
      return;
    }
    emit(
      state.copyWith(
        savedFilters: state.savedFilters
            .where((SavedMessageFilter filter) => filter.id != id)
            .toList(growable: false),
      ),
    );
    await _persist();
  }

  Future<void> replaceSavedFilters(List<SavedMessageFilter> filters) async {
    final List<SavedMessageFilter> capped = filters.length > kMaxSavedMessageFilters
        ? filters.take(kMaxSavedMessageFilters).toList(growable: false)
        : List<SavedMessageFilter>.from(filters);
    emit(state.copyWith(savedFilters: capped));
    await _persist();
  }
}
