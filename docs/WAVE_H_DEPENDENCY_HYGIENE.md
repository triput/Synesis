# Wave H — Dependency Hygiene Checklist

> **Status:** In progress (2026-07-27). **Gate:** V2.0a PIM P0 held until Wave H exits. Parent plan: [V2_PLAN.md](V2_PLAN.md) §4.

Per-version hygiene after V1.5 freeze — toolchain, pub debt, native/plugin skew, docs SDK pins. **No pubspec changes in the planning/docs pass**; implementation batches land in code waves.

## Sequence

```text
Wave 0 (account identity) ✅ → Wave H (this checklist) → V2.0a P0 (local PIM schema)
```

## Batches

| Batch | Scope | Exit signal |
| --- | --- | --- |
| **H1 — SDK pin verify** | `flutter doctor`; `environment.sdk` in `pubspec.yaml`; README / ROADMAP / SPEC SDK strings | Docs and toolchain agree on Dart/Flutter floor |
| **H2 — Soft upgrades** | Patch/minor resolution via `flutter pub get` / conservative bumps | No regressions; lockfile updated |
| **H3 — Pub majors** | `pub outdated` major candidates (Drift, build_runner, bloc_test, connectivity, etc.) | Majors landed or deferred with written rationale in commit/plan |
| **H4 — Native / KGP / sqlite3mc** | Android Gradle + Kotlin KGP; plugin native debt; `hooks.user_defines.sqlite3.source: sqlite3mc`; Drift codegen skew | Windows + Android debug builds; `build_runner` if drift_dev moves; TC-3 cipher hook still valid ([W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md)) |
| **H5 — Verify exit** | Full regression | `flutter test` green; Windows + Android debug builds; test inventory refresh if count shifts |

## Wave H exit criteria

- [ ] SDK pins verified and documented (H1)
- [ ] Soft pub upgrades applied (H2)
- [ ] Major pub upgrades evaluated; landed or explicitly deferred (H3)
- [ ] Native/KGP/sqlite3mc path green; Drift codegen matches sources (H4)
- [ ] `flutter test` green; Windows + Android debug builds succeed (H5)
- [ ] [V2_PLAN.md](V2_PLAN.md) and [ROADMAP.md](ROADMAP.md) updated — Wave H marked complete; V2.0a unblocked

## Out of scope

- PIM schema / Graph PIM / CardDAV spikes (V2.0a+)
- Feature work from [UI_ENHANCEMENT_SWEEP.md](UI_ENHANCEMENT_SWEEP.md) unless required by a breaking upgrade

## Landed work — QA risk notes (Batches H1–H2 / Wave 0 carry-in)

Reviewed 2026-07-27 (Renee). Commits: `e5b4ee8` (plan/docs), `3d80af7` (soft upgrades + Flutter pin), `41d4aba` (DEF-049), `b739f52` (rail overflow).

| Item | Risk | Notes |
| --- | --- | --- |
| Flutter pin `.flutter-version` **3.44.6** | Low | Aligns with `webview_flutter_windows` 1.x floor (Dart 3.12+ / Flutter 3.44+). **Gap:** README / SPEC do not yet advertise the pin — finish under H1 before Wave H exit. |
| `uuid` 4.5.3 → **4.6.0** | Low | Patch within `^4`; no API surface change expected. Covered indirectly by any ID-generating unit tests. |
| `webview_flutter_windows` 1.0.0 → **1.1.1** | **Medium (Windows HTML)** | Minor within 1.x; 1.1.x adds native focus handoff. Smoke: open HTML message in reading pane, click into body then back to list/search `TextField`, confirm no gray title bar / dead shortcuts (DEF-030 fallback still triggers on `webview_creation_failed`). OAuth on Windows uses loopback/`app_links`, **not** this WebView — OAuth panes are low-risk from this bump. |
| DEF-049 Graph In-Reply-To | Closed | Unit tests + **operator verified** Graph reply send. No further Wave H gate. |
| Rail overflow (`b739f52`) | Closed | Widget test present; Wave 0 exit. |
| DEF-050 mark-read context menu | Out of scope | Enhancement backlog — does **not** block Wave H. |

**H2 soft-upgrade verdict:** Acceptable to proceed to H3 majors. Do not treat H2 as fully exited until H1 docs pin strings match `.flutter-version` and a Windows HTML reading-pane smoke passes after the webview bump.

## Batch 2 / 3 — validation matrix (H3 majors + H4 native)

Jules in-flight majors (working tree as of review): `flutter_local_notifications` 19→22, `app_links` 6→7, `connectivity_plus` 6→7, `google_fonts` 6→8; `xml` ^7 / `pdf` unpin **deferred** (`enough_mail` ^2.1.7 pins `xml` ^6). `drift_dev` align + KGP/sqlite3mc remain H3/H4.

### Compile / API must-fix before smoke

| Package | Gate | Detail |
| --- | --- | --- |
| `flutter_local_notifications` **20+** | **Blocker if unfixed** | `show()` / `initialize()` positional args → **named**. `lib/notifications/android_notification_adapter.dart` still calls positional `show(id, title, body, details)` — must migrate before Android analyze/build. Windows runtime still uses `local_notifier` (DEF-037); confirm Windows still builds with transitive `flutter_local_notifications_windows` + existing `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS`. |
| `app_links` **7** | Analyze + deep-link smoke | Dart API (`uriLinkStream` / `getInitialLink`) stays compatible with v6 setups; Android native moves toward AGP 9 — re-verify Gradle configure with `android.builtInKotlin=false`. |
| `connectivity_plus` **7** | Unit + offline smoke | `ConnectivityResult` enum usage in `NetworkSyncPolicy` — re-run `test/network_sync_policy_test.dart`. |
| `google_fonts` **8** | Theme smoke | Cold start + Settings/Appearance; no network-font hang / fallback crash. |
| `xml` / `pdf` | Deferred OK | Document deferral rationale at H3 exit; keep `test/imap_autoconfig_test.dart` green on `xml` ^6. |
| `drift_dev` / Drift codegen | H4 | If bumped: `build_runner` + schema/repo tests; no drift/source skew. |

### Automated suite (required)

| ID | Command / scope | Pass criteria |
| --- | --- | --- |
| H5-T1 | `flutter test` (full) | Green; note count delta for inventory refresh |
| H5-T2 | Focused: `notification_service_test`, `sync_engine_new_mail_notify_test`, `app_settings_cubit_test` (notifications group) | Green (logic layer; does not prove OS toast) |
| H5-T3 | `network_sync_policy_test`, `sync_engine_push_wake_test` | Green after connectivity_plus 7 |
| H5-T4 | `oauth_redirect_capture_test`, `oauth_config_resolver_test`, `oauth_identity_manager_test` | Green (loopback path) |
| H5-T5 | `imap_autoconfig_test` | Green (direct `package:xml` consumer) |
| H5-T6 | `html_email_fallback_test` | Green (DEF-030 classification unchanged) |
| H5-T7 | Encryption / Drift: `db_encryption_migrator_test`, `schema_v5_test`, `drift_mail_repository_test` (and peers from W7 spike list) | Green with `sqlite3mc` hook |

### Manual / platform smoke (required for H5)

| ID | Area | Windows | Android | Pass criteria |
| --- | --- | --- | --- | --- |
| H5-M1 | Notifications | Background → new unread → **local_notifier** toast; foreground suppress | Grant Post notifications; channel `synesis_new_mail`; background toast; tap resumes | Re-smoke W6 global-off / quiet-hours / starred-only lightly if adapter init changed |
| H5-M2 | OAuth deep links | Graph + Google add-account (loopback and/or `synesis://` as configured) | Google reverse-client / app link redirect | Completes with code; no hang on `getInitialLink` / stream |
| H5-M3 | Connectivity offline | Airplane / disconnect → sync policy stops poll kicks; reconnect resumes | Same | No crash on empty/`none` results (historical DEF around empty connectivity) |
| H5-M4 | Fonts | App theme renders; no blank TextTheme | Same | `google_fonts` 8 loads or fails soft |
| H5-M5 | HTML WebView | HTML body + focus return to Flutter chrome | Android `webview_flutter` HTML body | No new hard error; widget fallback still OK |
| H5-M6 | Autoconfig XML | — | — | Add-account ISPDB / well-known path still parses (or unit suite suffices if offline) |
| H5-M7 | sqlite3mc | Debug run; optional encrypt-on settings path | Debug run | Hook resolves; unencrypted default unaffected ([W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md) TC-3) |
| H5-M8 | KGP residual | — | `flutter build apk --debug` (or `flutter run`) | Configure succeeds with `builtInKotlin=false` + file_picker KGP force-apply; no FilePickerPlugin symbol errors |
| H5-M9 | Dogfood APK | — | Install APK built **with** production dart-defines / shipped public clients as used for daily dogfood | Cold start, account list, sync, open mail, notification permission path |

### Test gaps / DEFs (do not block H2; address or waive at H3/H5)

| Gap | Severity | Action |
| --- | --- | --- |
| No unit test for `AppLinksOAuthRedirectCapture` (only loopback covered) | Pri-3 test debt | Prefer fake-`AppLinks` unit test after API settles; until then H5-M2 is mandatory |
| No compile/unit guard on `AndroidNotificationAdapter` ↔ fln `show`/`initialize` signatures | Pri-2 hygiene | Jules must fix named args; optional thin test with mocked plugin later |
| H1 docs omit Flutter **3.44.6** pin in README/SPEC | Pri-3 docs | Close under H1 before Wave H exit checkbox |
| `xml` ^7 blocked by `enough_mail` | Informational | Explicit H3 deferral — **not** a DEF |
| DEF-037 silence flag vs fln Windows transitive | Watch | Re-confirm Windows debug build after fln 22; reopen DEF only if STL1011 returns |
| DEF-050 | Out of scope | Leave open; not Wave H |

## Wave H go / no-go

**GO** only when all are true:

1. H1 — `.flutter-version`, `environment.sdk`, and README/SPEC/ROADMAP SDK strings agree.
2. H2 — Soft upgrades landed; Windows HTML pane smoke OK after webview 1.1.1.
3. H3 — Each major either merged with green H5-T\* / relevant H5-M\* **or** deferred in this doc / commit message with rationale (`xml`/`pdf`/`file_picker` already deferred).
4. H4 — Android debug build green under current KGP escape hatches; Drift codegen matches if `drift_dev` moved; sqlite3mc hook still loads.
5. H5 — Full `flutter test` green; Windows + Android debug builds succeed; dogfood APK with dart-defines exercised (H5-M9).
6. Docs — [V2_PLAN.md](V2_PLAN.md) / [ROADMAP.md](ROADMAP.md) mark Wave H complete and unblock V2.0a; refresh [TEST_INVENTORY.md](TEST_INVENTORY.md) / CSV if test count shifts.

**NO-GO** (hold V2.0a) if any of:

- Android fails to compile on fln named-parameter migration or AGP/KGP/`file_picker` conflict.
- Windows debug regresses (STL1011, WebView focus/creation hard-fail without fallback, OAuth redirect hang).
- Connectivity major breaks offline gating or throws on empty results.
- `flutter test` red, or sqlite3mc hook fails to resolve on either desktop target.
- Majors landed without written deferral for skipped candidates.

## References

| Doc | Role |
| --- | --- |
| [V2_PLAN.md](V2_PLAN.md) §4 | Wave H summary + hold on V2.0a |
| [W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md) | sqlite3mc hook + encryption boundary |
| [W6_NOTIFICATIONS_CHECKLIST.md](W6_NOTIFICATIONS_CHECKLIST.md) | Prior notification manual smoke (reuse lightly for H5-M1) |
| [TEST_INVENTORY.md](TEST_INVENTORY.md) | Post-upgrade test catalog refresh |
