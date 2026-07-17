# Wave 5 Windows Manual Checklist (M5)

Manual smoke list for the W5 desktop shell on **Windows release builds** (`flutter run -d windows` or packaged exe). **Automated coverage:** filter [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) with `wave=W5` (or see [TEST_INVENTORY.md](TEST_INVENTORY.md)); do not treat `evaluation_status=Cataloged` as Pass without a `flutter test` run.

**Wave status (2026-07-17):** **W5 landed** — operator accepted non-deferred checklist sections on Windows release builds. Layout, Visual Focus, keymap (DEF-001), tray DI, Ctrl+F, print/save EML/detach wiring verified. **Deferred (packaging follow-up, not a land blocker):** Windows `.eml` Explorer association / installer ProgId and launch-with-`.eml`-arg smoke (no installer yet). Print fix ([DEF-033](DEFECTS.md)) operator-accepted 2026-07-17. **W6 Notifications unlocked.**

## Setup

- Build or run on Windows with at least one synced account and several inbox messages (HTML + plain bodies).
- Appearance → **Keyboard shortcuts** ON (default).
- Appearance → **Minimize to tray (Windows)** ON for tray sections (default).
- Use a wide window (≥1200×800) unless testing layout edge cases.



## Reading pane positions

Settings: Appearance → **Reading pane** (Right / Bottom / Top). Persisted in `AppSettings.readingPanePosition`.

- [x] **Right** — account rail | folder sidebar | list | reading (horizontal split).
- [x] **Bottom** — list above reading (vertical split); sidebar still left of list.
- [x] **Top** — reading above list (vertical split).
- [x] Restart app; position survives relaunch.
- [x] Narrow portrait phone layout (if testing Android) still uses horizontal list|reading and ignores top/bottom — not required on Windows.



## Visual Focus

Distinct from Focused/Other mail filter. Toggle: title bar icon, Appearance switch, or **Ctrl+Shift+M**.

- [x] With a message selected, enable Visual Focus — folder sidebar and list hide; reading pane maximizes.
- [x] Disable Visual Focus — sidebar and list return.
- [x] Setting persists across restart (`visualFocusEnabled` in AppSettings).
- [x] Visual Focus does not fire when typing in compose/search text fields (shortcuts skipped while editing).



## Shortcuts without text focus (DEF-001)

Regression for [DEF-001](DEFECTS.md): workspace chords must work when focus is on list, sidebar, or title bar — not only in a text field.

- [x] Click message list (no text field focused); **Ctrl+J** / **Ctrl+K** move selection.
- [x] **Ctrl+N** opens compose.
- [x] **Ctrl+U** toggles read/unread on selection.
- [x] **E** archives, **R** / **Shift+R** reply / reply-all, **F** forward, **S** stars, **Del** trashes.
- [x] Open compose; shortcuts are **skipped** while cursor is in To/Subject/Body fields.
- [x] Open mailbox search sheet; shortcuts skipped while query field focused.



## Keymap help (`?`)

- [x] Press `?` (or Shift+/ on US layout) — bottom sheet lists bindings. *(Operator-accepted 2026-07-17 —* `isKeymapHelpKey` *accepts Shift+question.)*
- [x] Sheet includes Ctrl+F, Ctrl+Shift+F, Ctrl+Shift+M, navigation, and action keys.



## Ctrl+F — find in message

**Code:** `mail_workspace.dart` sets `_findInMessageRequested`; `ReadingPane` opens find bar with plain/HTML match navigation (`message_body_find.dart`). Manual pass validates UX on release builds.

- [x] Select a message with a long body; **Ctrl+F** — find bar appears with match navigation.
- [x] Typing a query highlights matches in plain and HTML bodies.
- [x] **Esc** or close dismisses find mode; body scroll unchanged.



## Ctrl+Shift+F — mailbox search

- [x] **Ctrl+Shift+F** opens mailbox search sheet (same as search icon).
- [x] `/` (bare, no modifiers) also opens search when not editing text.



## System tray (`minimizeToTray`)

Wiring: Appearance → `AppSettingsCubit.setMinimizeToTray` → `app.dart` `BlocListener` → `DesktopController.setMinimizeToTrayEnabled` (`WindowsDesktopController`).

- [x] With **Minimize to tray** ON: minimize button hides window to tray (not taskbar-only minimize).
- [x] Close (X) hides to tray instead of quitting.
- [x] Tray icon context menu → **Show ByteMail** restores and focuses window.
- [x] Tray context menu → **Quit** exits process.
- [x] Toggle **Minimize to tray** OFF in Appearance; close (X) quits app; minimize uses normal taskbar behavior.
- [x] Tray icon visible on **release** build (debug may log `MissingPluginException` if tray plugin unavailable).



## Print

**Code:** `printMessage` / `buildMessagePdf` (`message_print_service.dart`); **Print** in reading-pane overflow menu. *(2026-07-17, [DEF-033](DEFECTS.md): pre-build PDF; delay + retry once after menu close; on failure fall back to share/save PDF when available; cancel shows "Print cancelled." — operator-accepted on release build.)*

- [x] Reading pane → Print (overflow menu) opens system print dialog for selected message.
- [x] Plain and HTML bodies render readable output (subject, from, date, body).



## Save / open `.eml`

**Code:** title-bar **Open EML…** (`message_file_service.dart` → `eml_preview_sheet`); reading-pane overflow **Save as EML**; launch-with-path arg in `main.dart`.

- [x] Reading pane → **Save as EML** writes a valid `.eml` file (RFC 822).
- [x] Title bar → **Open EML…** picks a file and shows preview sheet.



### Deferred — installer ProgId (not blocking W5)

Windows **file type association** and Explorer double-click require an installer ProgId that is **not in repo yet**. Manual testing of these items is **deferred** until the installer ships:

- [ ] ~~Double-click~~ `.eml` ~~in Explorer opens ByteMail~~ — **deferred (no ProgId)**
- [ ] `ByteMail.exe "C:\path\to\message.eml"` ~~opens main shell and shows EML preview~~ — **deferred with installer packaging**
- [ ] ~~Invalid path / non-~~`.eml` ~~launch-arg behavior~~ — **deferred with installer packaging**



## Detached message window

**Code:** `WindowsDetachedMessageWindowController` + `DetachedMessageApp`; reading-pane overflow **Open in new window**. Secondary engines cannot host WebView2 Graphics Capture; HTML falls back to `flutter_widget_from_html` ([DEF-029](DEFECTS.md)).

- [x] Reading pane → **Open in new window** opens **one** secondary window with the current message.
- [x] Selecting another message and invoking again **retargets** the same window (V1 single-window policy).
- [x] Detached window shows subject and a **readable HTML layout** (widget viewer if WebView unavailable), and closes independently of main shell.



## W5 exit gate

**W5 landed** (2026-07-17) — non-deferred sections above operator-accepted on Windows release builds. **Explorer** `.eml` **ProgId remains deferred** — track association as a follow-up packaging task (not a land blocker). **W6 Notifications unlocked.**


| Area                          | Automated                                                                | Manual               |
| ----------------------------- | ------------------------------------------------------------------------ | -------------------- |
| Layout + Visual Focus         | `mail_split_layout_test.dart`                                            | Positions + collapse |
| Keymap / DEF-001              | `mailbox_shortcuts_test.dart`                                            | Focus regression     |
| Tray DI                       | `app_settings_cubit_test.dart`                                           | Release tray smoke   |
| Print / EML / detach / Ctrl+F | `message_print_service_test`, `message_body_find_test`, `eml_codec_test` | This checklist       |
| `.eml` ProgId / Explorer      | —                                                                        | **Deferred**         |


