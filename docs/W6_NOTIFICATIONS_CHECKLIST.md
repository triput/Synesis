# Wave 6 Notifications Manual Checklist (M5)

Manual smoke list for W6 new-mail OS notifications on **Windows release builds** and **Android AVD** (`flutter run -d windows` / `-d <emulator-id>`). **Automated coverage:** filter `[V1_AUTOMATED_TEST_INVENTORY.csv](V1_AUTOMATED_TEST_INVENTORY.csv)` with `wave=W6` (or see [TEST_INVENTORY.md](TEST_INVENTORY.md)); do not treat `evaluation_status=Cataloged` as Pass without a `flutter test` run.

**Wave status (2026-07-17):** **W6 landed** — operator accepted Windows + Android AVD checklist sections. Notification code (`NotificationService`, settings sheet, Android/Windows adapters, `SyncEngine.onNewUnread`) verified. **W4 Compose unlocked.**

## Setup

- **Windows:** release or profile build with at least one synced account and inbox mail waiting on the server (or a second client to inject unread).
- **Android AVD:** API 34+ emulator; grant **Post notifications** when prompted (Android 13+). Confirm title bar → **Notifications** icon opens the settings sheet.
- Appearance / title bar → **Notifications** sheet reachable on both platforms.
- Use a test account you can mark unread from another client or send mail into while ByteMail is backgrounded.



## Global off → no toasts

**Code:** `NotificationService.onNewMail` returns early when `notificationsEnabled` is false.

- [x] Notifications sheet → **Enable notifications** OFF.
- [x] Background/minimize app; trigger new unread inbox mail via incremental sync.
- [x] No OS toast on Windows or Android.
- [x] Re-enable global switch; confirm path still works (see background section).



## Account mute

**Code:** `AppSettingsState.isAccountNotificationsEnabled`; per-account toggles in notifications sheet.

- [x] With global notifications ON, mute **Account A** in the sheet.
- [x] Background app; new unread for Account A only → **no** toast.
- [x] New unread for unmuted **Account B** → toast **does** appear (when other filters allow).
- [x] Unmute Account A; next new unread for A notifies again.



## Quiet hours

**Code:** `NotificationService._isInQuietHours`; default window 22:00–07:00 when enabled.

- [x] Enable **Quiet hours**; set a window that includes **now** (or adjust device/emulator clock into the window).
- [x] Background app; trigger new unread inbox mail → **no** toast.
- [x] Disable quiet hours (or move clock outside window); same trigger → toast appears.
- [x] Optional: overnight wrap (e.g. 22:00–07:00) suppresses across midnight boundary.



## Starred only

**Code:** `notifyStarredOnly` filter in `NotificationService.onNewMail`.

- [x] Enable **Starred messages only**.
- [x] Background app; new **unstarred** unread inbox mail → no toast.
- [x] Star an unread message on server (or locally before sync); new starred unread → toast appears.
- [x] Disable starred-only; unstarred unread notifies again.



## Background / minimized → toast on new inbox unread after sync

**Code:** `SyncEngine` `_maybeNotifyNewUnread` on incremental inbox sync; `isAppForeground` must be false.

- [x] Minimize or background ByteMail (Windows: tray/minimize; Android: Home / recent apps).
- [x] From another client, deliver new unread mail to inbox (or mark existing unread).
- [x] Wait for push/IDLE or manual sync-now; OS toast shows sender + subject (or aggregate title for batch).
- [x] Tap toast (if platform supports) → app focuses; message readable after sync.



## Foreground focused → suppress

**Code:** Windows uses `DesktopController.isWindowFocused`; Android uses `AppForegroundTracker`.

- [x] With ByteMail **focused and visible**, trigger new unread inbox mail.
- [x] **No** OS toast while foreground; inbox list updates normally after sync.
- [x] Background app → same mail event **does** toast (regression pair with section above).



## Bootstrap / first add account should not spam

**Code:** `bootstrap` job calls `_syncInbox(..., notifyNewMail: false)`; only `incremental` / push-wake path notifies.

- [x] Fresh install or wipe → add account; initial inbox hydration completes.
- [x] **No** notification burst for historical unread pulled during bootstrap.
- [x] After bootstrap, send **one** new unread while backgrounded → single toast (not replay of entire inbox).



## Remote search should not notify

**Code:** `remote_search` job type does not invoke `_maybeNotifyNewUnread`.

- [x] Run mailbox **remote/server search** that returns messages not already in local inbox view.
- [x] No OS toast from search results ingestion alone.
- [x] Separate incremental inbox sync for genuinely new mail still toasts when backgrounded.



## W6 exit gate

**W6 landed** (2026-07-17) — checklist sections above operator-accepted on **Windows + Android AVD**. **W4 Compose** is the next feature wave per [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md).


| Area                                                           | Automated                                                         | Manual                                                       |
| -------------------------------------------------------------- | ----------------------------------------------------------------- | ------------------------------------------------------------ |
| Filter rules (global, mute, quiet, starred, dedupe, aggregate) | `notification_service_test.dart`                                  | Global off, account mute, quiet hours, starred only          |
| Settings persistence                                           | `app_settings_cubit_test.dart` (`AppSettingsCubit notifications`) | Sheet toggles survive restart                                |
| Sync hook (inbox incremental only)                             | — (integration manual)                                            | Bootstrap no-spam, remote search no-notify, background toast |
| Foreground suppress                                            | `notification_service_test.dart`                                  | Windows focus + Android lifecycle                            |
| Platform adapters                                              | —                                                                 | Windows toast + Android AVD permission + channel             |


