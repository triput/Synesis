// ==============================================================================
// File: lib/settings/app_settings_state.dart
// Description: Immutable appearance and Focus preference snapshot
// Component: Bloc / Settings
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'package:equatable/equatable.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_id.dart';

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
    this.pushOnCellular = false,
    this.readingPanePosition = ReadingPanePosition.right,
    this.visualFocusEnabled = false,
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

  /// When true, Android may run IMAP IDLE / near-push on cellular data.
  /// Default false (opt-in). Desktop ignores this and always allows push online.
  final bool pushOnCellular;

  /// Where the reading pane sits relative to the message list on wide layouts.
  /// Portrait mobile ignores this and keeps the horizontal list|reading split.
  final ReadingPanePosition readingPanePosition;

  /// When true, collapses folder sidebar and list chrome so reading is maximized
  /// (while a message is selected). Distinct from Focused/Other mail filter.
  final bool visualFocusEnabled;

  bool isAccountFocusEnabled(String accountId) =>
      accountFocusEnabled[accountId] ?? true;

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
    bool? pushOnCellular,
    ReadingPanePosition? readingPanePosition,
    bool? visualFocusEnabled,
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
      pushOnCellular: pushOnCellular ?? this.pushOnCellular,
      readingPanePosition: readingPanePosition ?? this.readingPanePosition,
      visualFocusEnabled: visualFocusEnabled ?? this.visualFocusEnabled,
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
        pushOnCellular,
        readingPanePosition,
        visualFocusEnabled,
      ];
}
