// ==============================================================================
// File: lib/settings/app_settings_state.dart
// Description: Immutable appearance and Focus preference snapshot
// Component: Bloc / Settings
// Version: 1.3 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-23
// ==============================================================================

import 'package:equatable/equatable.dart';
import 'package:synesis/domain/saved_message_filter.dart';
import 'package:synesis/theme/density.dart';
import 'package:synesis/theme/theme_id.dart';

/// Desktop / landscape reading-pane split relative to the message list.
enum ReadingPanePosition {
  /// Sidebar | list | reading (default).
  right,

  /// List above, reading below.
  bottom,

  /// Reading above, list below.
  top,
}

/// How the message list renders conversations.
enum ThreadDisplayMode {
  /// Group replies into expandable conversation rows.
  threaded,

  /// One row per message (classic flat inbox).
  flat,
}

/// Minimum allowed [AppSettingsState.uiFontSizeScale] (UI-P18).
const double kUiFontSizeScaleMin = 0.85;

/// Maximum allowed [AppSettingsState.uiFontSizeScale] (UI-P18).
const double kUiFontSizeScaleMax = 1.3;

/// Default [AppSettingsState.autoMarkAsReadSeconds] dwell (UI-P28/UI-P27).
const int kAutoMarkAsReadSecondsDefault = 5;

/// Minimum allowed [AppSettingsState.autoMarkAsReadSeconds]. `0` means Off.
const int kAutoMarkAsReadSecondsMin = 0;

/// Maximum allowed [AppSettingsState.autoMarkAsReadSeconds] (UI-P28).
const int kAutoMarkAsReadSecondsMax = 60;

/// Android message-list swipe action (left or right).
enum SwipeListAction {
  /// Move to archive.
  archive,

  /// Move to trash (or permanent delete when already in trash — swipe disabled).
  delete,

  /// Toggle starred.
  star,

  /// Open snooze picker for the swiped row.
  snooze,

  /// Swipe side disabled.
  none,
}

class AppSettingsState extends Equatable {
  const AppSettingsState({
    this.themeId = ThemeId.dark,
    this.density = ViewDensity.calm,
    this.unifiedFocusEnabled = true,
    this.accountFocusEnabled = const {
      'work': true,
      'personal': true,
      'side': false,
    },
    this.retentionDays = 180,
    this.trashRetentionDays = 30,
    this.minimizeToTray = true,
    this.keyboardShortcutsEnabled = true,
    this.threadDisplayMode = ThreadDisplayMode.threaded,
    this.swipeRightAction = SwipeListAction.archive,
    this.swipeLeftAction = SwipeListAction.delete,
    this.blockRemoteImages = true,
    this.accountBlockRemoteImages = const <String, bool>{},
    this.accountImageAllowlistDomains = const <String, List<String>>{},
    this.blockTrackers = true,
    this.pushOnCellular = false,
    this.readingPanePosition = ReadingPanePosition.right,
    this.visualFocusEnabled = false,
    this.notificationsEnabled = true,
    this.notifyStarredOnly = false,
    this.notificationQuietHoursEnabled = false,
    this.quietHoursStartMinutes = 22 * 60,
    this.quietHoursEndMinutes = 7 * 60,
    this.accountNotificationsEnabled = const <String, bool>{},
    this.customThemeId,
    this.uiFontFamily,
    this.uiFontSizeScale = 1.0,
    this.uiTextColorArgb,
    this.savedFilters = const <SavedMessageFilter>[],
    this.autoMarkAsReadSeconds = kAutoMarkAsReadSecondsDefault,
  });

  final ThemeId themeId;
  final ViewDensity density;
  final bool unifiedFocusEnabled;
  final Map<String, bool> accountFocusEnabled;
  final int retentionDays;
  final int trashRetentionDays;
  final bool minimizeToTray;
  final bool keyboardShortcutsEnabled;
  final ThreadDisplayMode threadDisplayMode;

  /// Swipe right (LTR [DismissDirection.startToEnd]). Default: archive.
  final SwipeListAction swipeRightAction;

  /// Swipe left (LTR [DismissDirection.endToStart]). Default: delete.
  final SwipeListAction swipeLeftAction;

  /// When true, HTML mail blocks remote http(s) images until the user allows
  /// them for the current reading session. Default true (privacy-first).
  final bool blockRemoteImages;

  /// Per-account override of [blockRemoteImages] (D6-2). A missing key
  /// inherits the global [blockRemoteImages] value for that account.
  final Map<String, bool> accountBlockRemoteImages;

  /// Per-account list of image-host domains that are always loaded even when
  /// remote images are blocked (D6-2). Matching is a case-insensitive suffix
  /// match (see `isHostAllowlisted`), so `example.com` also covers
  /// `img.example.com`.
  final Map<String, List<String>> accountImageAllowlistDomains;

  /// When true, strips known ESP/analytics tracking pixels and open-tracking
  /// beacons from HTML bodies, independent of [blockRemoteImages] (D6-7).
  /// Default true (privacy-first).
  final bool blockTrackers;

  /// When true, Android may run IMAP IDLE / near-push on cellular data.
  /// Default false (opt-in). Desktop ignores this and always allows push online.
  final bool pushOnCellular;

  /// Where the reading pane sits relative to the message list on wide layouts.
  /// Portrait mobile ignores this and keeps the horizontal list|reading split.
  final ReadingPanePosition readingPanePosition;

  /// When true, collapses folder sidebar and list chrome so reading is maximized
  /// (while a message is selected). Distinct from Focused/Other mail filter.
  final bool visualFocusEnabled;

  /// Global OS new-mail notifications master switch. Default on.
  final bool notificationsEnabled;

  /// When true, only starred unread messages trigger OS notifications.
  final bool notifyStarredOnly;

  /// When true, suppress notifications during [quietHoursStartMinutes, end).
  final bool notificationQuietHoursEnabled;

  /// Quiet-hours window start as minutes since midnight (default 22:00).
  final int quietHoursStartMinutes;

  /// Quiet-hours window end as minutes since midnight (default 07:00).
  final int quietHoursEndMinutes;

  /// Per-account notification mute map. Missing keys mean enabled (on).
  final Map<String, bool> accountNotificationsEnabled;

  /// Id of a user-defined `custom_themes` row to apply instead of [themeId]
  /// (UI-P16). Null means use the built-in [themeId] pack unmodified.
  final String? customThemeId;

  /// Body/UI font family override (UI-P18). Null uses the default IBM Plex
  /// Sans body / Fraunces display pairing.
  final String? uiFontFamily;

  /// UI text scale multiplier, clamped to
  /// [kUiFontSizeScaleMin]–[kUiFontSizeScaleMax] (UI-P18).
  final double uiFontSizeScale;

  /// Optional ARGB override for body text color (UI-P18). Null uses the
  /// active theme's default text color.
  final int? uiTextColorArgb;

  /// Device-local named message list filter presets.
  final List<SavedMessageFilter> savedFilters;

  /// Dwell in seconds before an open unread message is auto-marked read
  /// (UI-P28). Clamped to [kAutoMarkAsReadSecondsMin]–
  /// [kAutoMarkAsReadSecondsMax]. `0` disables auto-mark-as-read entirely.
  final int autoMarkAsReadSeconds;

  /// True when auto-mark-as-read is enabled (non-zero dwell).
  bool get autoMarkAsReadEnabled => autoMarkAsReadSeconds > 0;

  bool isAccountFocusEnabled(String accountId) =>
      accountFocusEnabled[accountId] ?? true;

  bool isAccountNotificationsEnabled(String accountId) =>
      accountNotificationsEnabled[accountId] ?? true;

  /// Effective remote-image-blocking policy for [accountId] (D6-2): a
  /// per-account override takes precedence over the global [blockRemoteImages].
  bool isBlockRemoteImagesForAccount(String accountId) =>
      accountBlockRemoteImages[accountId] ?? blockRemoteImages;

  /// Image-host allowlist for [accountId] (D6-2); empty when unset.
  List<String> imageAllowlistDomainsForAccount(String accountId) =>
      accountImageAllowlistDomains[accountId] ?? const <String>[];

  bool focusEnabledForContext({required bool isUnified, String? accountId}) {
    if (isUnified) return unifiedFocusEnabled;
    if (accountId == null) return false;
    return isAccountFocusEnabled(accountId);
  }

  AppSettingsState copyWith({
    ThemeId? themeId,
    ViewDensity? density,
    bool? unifiedFocusEnabled,
    Map<String, bool>? accountFocusEnabled,
    int? retentionDays,
    int? trashRetentionDays,
    bool? minimizeToTray,
    bool? keyboardShortcutsEnabled,
    ThreadDisplayMode? threadDisplayMode,
    SwipeListAction? swipeRightAction,
    SwipeListAction? swipeLeftAction,
    bool? blockRemoteImages,
    Map<String, bool>? accountBlockRemoteImages,
    Map<String, List<String>>? accountImageAllowlistDomains,
    bool? blockTrackers,
    bool? pushOnCellular,
    ReadingPanePosition? readingPanePosition,
    bool? visualFocusEnabled,
    bool? notificationsEnabled,
    bool? notifyStarredOnly,
    bool? notificationQuietHoursEnabled,
    int? quietHoursStartMinutes,
    int? quietHoursEndMinutes,
    Map<String, bool>? accountNotificationsEnabled,
    String? customThemeId,
    bool clearCustomThemeId = false,
    String? uiFontFamily,
    bool clearUiFontFamily = false,
    double? uiFontSizeScale,
    int? uiTextColorArgb,
    bool clearUiTextColorArgb = false,
    List<SavedMessageFilter>? savedFilters,
    int? autoMarkAsReadSeconds,
  }) {
    return AppSettingsState(
      themeId: themeId ?? this.themeId,
      density: density ?? this.density,
      unifiedFocusEnabled: unifiedFocusEnabled ?? this.unifiedFocusEnabled,
      accountFocusEnabled: accountFocusEnabled ?? this.accountFocusEnabled,
      retentionDays: retentionDays ?? this.retentionDays,
      trashRetentionDays: trashRetentionDays ?? this.trashRetentionDays,
      minimizeToTray: minimizeToTray ?? this.minimizeToTray,
      keyboardShortcutsEnabled:
          keyboardShortcutsEnabled ?? this.keyboardShortcutsEnabled,
      threadDisplayMode: threadDisplayMode ?? this.threadDisplayMode,
      swipeRightAction: swipeRightAction ?? this.swipeRightAction,
      swipeLeftAction: swipeLeftAction ?? this.swipeLeftAction,
      blockRemoteImages: blockRemoteImages ?? this.blockRemoteImages,
      accountBlockRemoteImages:
          accountBlockRemoteImages ?? this.accountBlockRemoteImages,
      accountImageAllowlistDomains:
          accountImageAllowlistDomains ?? this.accountImageAllowlistDomains,
      blockTrackers: blockTrackers ?? this.blockTrackers,
      pushOnCellular: pushOnCellular ?? this.pushOnCellular,
      readingPanePosition: readingPanePosition ?? this.readingPanePosition,
      visualFocusEnabled: visualFocusEnabled ?? this.visualFocusEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyStarredOnly: notifyStarredOnly ?? this.notifyStarredOnly,
      notificationQuietHoursEnabled: notificationQuietHoursEnabled ??
          this.notificationQuietHoursEnabled,
      quietHoursStartMinutes:
          quietHoursStartMinutes ?? this.quietHoursStartMinutes,
      quietHoursEndMinutes: quietHoursEndMinutes ?? this.quietHoursEndMinutes,
      accountNotificationsEnabled:
          accountNotificationsEnabled ?? this.accountNotificationsEnabled,
      customThemeId: clearCustomThemeId
          ? null
          : (customThemeId ?? this.customThemeId),
      uiFontFamily:
          clearUiFontFamily ? null : (uiFontFamily ?? this.uiFontFamily),
      uiFontSizeScale: (uiFontSizeScale ?? this.uiFontSizeScale).clamp(
        kUiFontSizeScaleMin,
        kUiFontSizeScaleMax,
      ),
      uiTextColorArgb: clearUiTextColorArgb
          ? null
          : (uiTextColorArgb ?? this.uiTextColorArgb),
      savedFilters: savedFilters ?? this.savedFilters,
      autoMarkAsReadSeconds: (autoMarkAsReadSeconds ?? this.autoMarkAsReadSeconds)
          .clamp(kAutoMarkAsReadSecondsMin, kAutoMarkAsReadSecondsMax),
    );
  }

  @override
  List<Object?> get props => [
        themeId,
        density,
        unifiedFocusEnabled,
        accountFocusEnabled,
        retentionDays,
        trashRetentionDays,
        minimizeToTray,
        keyboardShortcutsEnabled,
        threadDisplayMode,
        swipeRightAction,
        swipeLeftAction,
        blockRemoteImages,
        accountBlockRemoteImages,
        accountImageAllowlistDomains,
        blockTrackers,
        pushOnCellular,
        readingPanePosition,
        visualFocusEnabled,
        notificationsEnabled,
        notifyStarredOnly,
        notificationQuietHoursEnabled,
        quietHoursStartMinutes,
        quietHoursEndMinutes,
        accountNotificationsEnabled,
        customThemeId,
        uiFontFamily,
        uiFontSizeScale,
        uiTextColorArgb,
        savedFilters,
        autoMarkAsReadSeconds,
      ];
}
