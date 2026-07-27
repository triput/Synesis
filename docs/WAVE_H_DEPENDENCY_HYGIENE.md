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

- [x] SDK pins verified and documented (H1) — `.flutter-version` **3.44.6**, `environment.sdk: ^3.12.2`, README + QUICK_START advertise the pin (2026-07-27 Batch 2). SPEC/ROADMAP narrative polish can wait for H5 close.
- [x] Soft pub upgrades applied (H2) — Batch 1 (`uuid` 4.6.0, `webview_flutter_windows` 1.1.1); Windows HTML smoke still recommended before H5 GO.
- [x] Major pub upgrades evaluated; landed or explicitly deferred (H3) — Batch 2 majors + Batch 3 sqlite/`file_picker` disposition; H5-T\*/H5-M\* smoke still required for Wave H GO.
- [x] Native/KGP/sqlite3mc path green for Batch 3 scope (H4) — Android debug APK green; sqlite3mc hook + encryption tests green; KGP residuals documented (escape hatches kept); `drift_dev` still deferred (no codegen regen). Windows debug build noted in Batch 3 log.
- [ ] `flutter test` green; Windows + Android debug builds succeed (H5)
- [ ] [V2_PLAN.md](V2_PLAN.md) and [ROADMAP.md](ROADMAP.md) updated — Wave H marked complete; V2.0a unblocked

## Out of scope

- PIM schema / Graph PIM / CardDAV spikes (V2.0a+)
- Feature work from [UI_ENHANCEMENT_SWEEP.md](UI_ENHANCEMENT_SWEEP.md) unless required by a breaking upgrade

## Landed work — QA risk notes (Batches H1–H2 / Wave 0 carry-in)

Reviewed 2026-07-27 (Renee). Commits: `e5b4ee8` (plan/docs), `3d80af7` (soft upgrades + Flutter pin), `41d4aba` (DEF-049), `b739f52` (rail overflow).

| Item | Risk | Notes |
| --- | --- | --- |
| Flutter pin `.flutter-version` **3.44.6** | Low | Aligns with `webview_flutter_windows` 1.x floor (Dart 3.12+ / Flutter 3.44+). **H1 docs:** README + QUICK_START advertise the pin (Batch 2). |
| `uuid` 4.5.3 → **4.6.0** | Low | Patch within `^4`; no API surface change expected. Covered indirectly by any ID-generating unit tests. |
| `webview_flutter_windows` 1.0.0 → **1.1.1** | **Medium (Windows HTML)** | Minor within 1.x; 1.1.x adds native focus handoff. Smoke: open HTML message in reading pane, click into body then back to list/search `TextField`, confirm no gray title bar / dead shortcuts (DEF-030 fallback still triggers on `webview_creation_failed`). OAuth on Windows uses loopback/`app_links`, **not** this WebView — OAuth panes are low-risk from this bump. |
| DEF-049 Graph In-Reply-To | Closed | Unit tests + **operator verified** Graph reply send. No further Wave H gate. |
| Rail overflow (`b739f52`) | Closed | Widget test present; Wave 0 exit. |
| DEF-050 mark-read context menu | Out of scope | Enhancement backlog — does **not** block Wave H. |

**H2 soft-upgrade verdict:** Soft upgrades landed. Treat H2 exit as complete for checklist purposes; still run Windows HTML reading-pane smoke (H5-M5) before Wave H GO.

## Batch 2 / H3 — pub majors (2026-07-27)

| Package | Constraint | Resolved | Status |
| --- | --- | --- | --- |
| `flutter_local_notifications` | `^22.0.0` | **22.2.0** | Landed. Named `initialize`/`show` fixed in `android_notification_adapter.dart`. |
| `app_links` | `^7.0.0` | **7.2.1** | Landed. Dart API compatible (`uriLinkStream` / `getInitialLink`). |
| `connectivity_plus` | `^7.0.0` | **7.3.1** | Landed. Dart `ConnectivityResult` usage unchanged. |
| `google_fonts` | `^8.0.0` | **8.2.0** | Landed. |
| `xml` | `^6.5.0` (unchanged) | 6.6.1 | **Deferred** — `enough_mail` ^2.1.7 requires `xml` ^6; do not bump `enough_mail` casually. |
| `pdf` | `3.12.0` (pin) | 3.12.0 | **Deferred** — would need 3.13+ for `xml` ^7; blocked with xml. |
| `printing` | `^5.14.3` | 5.14.3 | **Deferred** — leave pin; revisit with pdf/xml unlock. |
| `file_picker` | `11.0.2` (pin) | 11.0.2 | **Deferred** — pub.dev stable latest still **11.0.2** (12.x prerelease only). Keep pin + AGP escape hatches (Batch 3). |
| `drift_dev` | `^2.34.0` | 2.34.0 | **Deferred latest 2.34.5** — `drift_dev` ≥2.34.1+1 needs `analyzer` ^13, incompatible with `bloc_test`/`flutter_test` matcher pins. Constraint already covers 2.34.x when resolvable. Batch 3: leave deferred (no trivial align). |
| `build_runner` | `^2.15.1` | 2.15.1 | Unchanged (no resolve force). |

**DEF-037 note:** `flutter_local_notifications_windows` **3.1.1** now defines `_SILENCE_EXPERIMENTAL_COROUTINE_DEPRECATION_WARNINGS` in its own CMakeLists. Repo `windows/CMakeLists.txt` keep-alive remains harmless insurance; reopen DEF-037 only if STL1011 returns on Windows debug.

### Batch 2 QA verdict (Renee, 2026-07-27) — commit `fa86d7e`

| Check | Result |
| --- | --- |
| Diff vs H5 matrix | **PASS** — landed majors + named fln adapter match matrix; deferrals (`xml`/`pdf`/`printing`/`file_picker`/`drift_dev` 2.34.5) have written rationale. |
| `android_notification_adapter.dart` | **PASS** — `initialize(settings:)` / `show(id:, title:, body:, notificationDetails:)` only call site; channel + permission APIs unchanged. |
| Dart API consumers | **PASS** — `AppLinks` still `uriLinkStream` / `getInitialLink`; `NetworkSyncPolicy` empty-list-as-online + `ConnectivityResult` enum usage intact; `google_fonts` theme factory unchanged. |
| DEF-037 | **Watch kept** — silence define retained in repo CMakeLists; fln Windows transitive **3.1.1**. |
| Jules analyze / focused tests | **Accepted as reported** — analyze 0 errors; ~100 focused green. Does **not** substitute H5-T1 full suite or H5-M\*. |
| New transitive | `flutter_local_notifications_web` **1.0.0** pulled in — no Synesis web target; ignore unless someone enables web. |

**Batch 2 code gate:** Conditional **GO** for Batch 3/4 (H4 native / remaining deferrals) **only after** the soft pre-Batch-3 hold below. H3 checklist box stays open until relevant H5-T\*/H5-M\* land.

**Soft hold before Batch 3/4 (not Wave H final NO-GO, but do not stack native work blind):**

1. **H5-M8 (or equivalent)** — Android Gradle configure / `flutter build apk --debug` once with Batch 2 plugins (`app_links` 7 + fln 22 + pinned `file_picker` 11.0.2 + `builtInKotlin=false`). Analyze does not prove AGP/KGP.
2. **Windows debug compile** — confirm no STL1011 / DEF-037 reopen with `flutter_local_notifications_windows` 3.1.1 (even though runtime toast is still `local_notifier`).

**Hard NO-GO for Wave H / V2.0a (unchanged):** H5-T1 red, Android fln/KGP compile fail, Windows STL1011 or OAuth hang, connectivity empty/`none` crash, sqlite3mc hook fail, or majors without deferral rationale.

**Missing tests (not Batch 3 blockers; waive or close at H5):**

| Gap | Severity | Gate |
| --- | --- | --- |
| No `AppLinksOAuthRedirectCapture` unit test (H5-T4 covers loopback only) | Pri-3 | **H5-M2 mandatory** on Android (+ Windows loopback still covered by existing tests) |
| No thin mock test for `AndroidNotificationAdapter` ↔ fln named APIs | Pri-3 | Nice-to-have; Android build + H5-M1 cover risk |
| No automated `google_fonts` 8 guard | Pri-3 | **H5-M4** theme smoke |
| H5-T1 full suite not yet recorded post-Batch 2 | Required for H5 | Run before Wave H GO; refresh inventory only if count shifts |
| H5-T7 / H5-M7 | H4/H5 | Deferred with Drift/sqlite3mc batch — not Batch 2 scope |

### Compile / API must-fix before smoke

| Package | Gate | Detail |
| --- | --- | --- |
| `flutter_local_notifications` **20+** | **Fixed in Batch 2** | Named `settings:` / `id:` / `notificationDetails:` in `android_notification_adapter.dart`. Windows runtime still uses `local_notifier`; transitive Windows plugin + DEF-037 silence flag remain. |
| `app_links` **7** | Analyze + deep-link smoke | Dart API stays compatible with v6 setups; Android native moves toward AGP 9 — re-verify Gradle configure with `android.builtInKotlin=false` (**pre-Batch-3 soft hold**). |
| `connectivity_plus` **7** | Unit + offline smoke | `ConnectivityResult` enum usage in `NetworkSyncPolicy` — Jules: focused green; still need H5-M3. |
| `google_fonts` **8** | Theme smoke | Cold start + Settings/Appearance; no network-font hang / fallback crash (**H5-M4**). |
| `xml` / `pdf` | Deferred OK | Documented above; keep `test/imap_autoconfig_test.dart` green on `xml` ^6. |
| `drift_dev` / Drift codegen | H4 | Not bumped this batch; no `build_runner` regen required. |

### Automated suite (required)

| ID | Command / scope | Pass criteria | Batch 2 status |
| --- | --- | --- | --- |
| H5-T1 | `flutter test` (full) | Green; note count delta for inventory refresh | **Open** — not claimed |
| H5-T2 | Focused: `notification_service_test`, `sync_engine_new_mail_notify_test`, `app_settings_cubit_test` (notifications group) | Green (logic layer; does not prove OS toast) | **Jules: green** (focused set) |
| H5-T3 | `network_sync_policy_test`, `sync_engine_push_wake_test` | Green after connectivity_plus 7 | **Jules: green** (focused set) |
| H5-T4 | `oauth_redirect_capture_test`, `oauth_config_resolver_test`, `oauth_identity_manager_test` | Green (loopback path) | **Jules: green**; AppLinks path still untested |
| H5-T5 | `imap_autoconfig_test` | Green (direct `package:xml` consumer) | **Jules: green** (focused set) |
| H5-T6 | `html_email_fallback_test` | Green (DEF-030 classification unchanged) | **Jules: green** (focused set) |
| H5-T7 | Encryption / Drift: `db_encryption_migrator_test`, `schema_v5_test`, `drift_mail_repository_test` (and peers from W7 spike list) | Green with `sqlite3mc` hook | **Batch 3: green** (`db_encryption_*` + `schema_v5` + `drift_mail_repository`; 43 passed) |


### Manual / platform smoke (required for H5)

| ID | Area | Windows | Android | Pass criteria | Batch 2 status |
| --- | --- | --- | --- | --- | --- |
| H5-M1 | Notifications | Background → new unread → **local_notifier** toast; foreground suppress | Grant Post notifications; channel `synesis_new_mail`; background toast; tap resumes | Re-smoke W6 global-off / quiet-hours / starred-only lightly if adapter init changed | **Open** |
| H5-M2 | OAuth deep links | Graph + Google add-account (loopback and/or `synesis://` as configured) | Google reverse-client / app link redirect | Completes with code; no hang on `getInitialLink` / stream | **Open** (mandatory — no AppLinks unit test) |
| H5-M3 | Connectivity offline | Airplane / disconnect → sync policy stops poll kicks; reconnect resumes | Same | No crash on empty/`none` results (historical DEF around empty connectivity) | **Open** |
| H5-M4 | Fonts | App theme renders; no blank TextTheme | Same | `google_fonts` 8 loads or fails soft | **Open** |
| H5-M5 | HTML WebView | HTML body + focus return to Flutter chrome | Android `webview_flutter` HTML body | No new hard error; widget fallback still OK | **Open** (also covers H2 webview 1.1.1) |
| H5-M6 | Autoconfig XML | — | — | Add-account ISPDB / well-known path still parses (or unit suite suffices if offline) | Unit suite may suffice |
| H5-M7 | sqlite3mc | Debug run; optional encrypt-on settings path | Debug run | Hook resolves; unencrypted default unaffected ([W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md) TC-3) | **Batch 3: unit/hook green**; manual encrypt-on still H5 |
| H5-M8 | KGP residual | — | `flutter build apk --debug` (or `flutter run`) | Configure succeeds with `builtInKotlin=false` + file_picker KGP force-apply; no FilePickerPlugin symbol errors | **Batch 3: PASS** (warning residual documented) |
| H5-M9 | Dogfood APK | — | Install APK built **with** production dart-defines / shipped public clients as used for daily dogfood | Cold start, account list, sync, open mail, notification permission path | **Open** — H5 close; release APK dart-define footgun remains |

### Test gaps / DEFs (address or waive at H5; do not block Batch 3 after soft hold)

| Gap | Severity | Action |
| --- | --- | --- |
| No unit test for `AppLinksOAuthRedirectCapture` (only loopback covered) | Pri-3 test debt | Prefer fake-`AppLinks` unit test after API settles; until then H5-M2 is mandatory |
| No compile/unit guard on `AndroidNotificationAdapter` ↔ fln `show`/`initialize` signatures | Pri-3 residual | Named-arg migration landed Batch 2; optional thin mock test still nice-to-have |
| H1 docs omit Flutter **3.44.6** pin in README/SPEC | Closed (Batch 2) | README + QUICK_START advertise pin; SPEC polish optional at H5 |
| `xml` ^7 blocked by `enough_mail` | Informational | Explicit H3 deferral — **not** a DEF |
| DEF-037 silence flag vs fln Windows transitive | Watch | Re-confirm Windows debug build after fln 22; reopen DEF only if STL1011 returns |
| DEF-050 | Out of scope | Leave open; not Wave H |

## Batch 3 / H4 — sqlite3mc + KGP (2026-07-27)

### sqlite3 / sqlite3mc disposition

| Item | Decision | Evidence |
| --- | --- | --- |
| `sqlite3` | Soft bump **3.4.0 → 3.5.0** (`^3.5.0`) | `flutter pub get` resolved cleanly; hooks still use `hooks.user_defines.sqlite3.source: sqlite3mc` |
| `sqlite3_flutter_libs` | **Removed** | Confirmed inert EOL no-op for sqlite3 3.x ([W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md), [UPGRADING_TO_V3](https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md)); not referenced in Dart sources |
| Encryption-at-rest path | **Unbroken** | `lib/repository/db_encryption_config.dart` untouched; H5-T7 focused suite green (43) |
| `drift_dev` | **Still deferred** | Analyzer conflict with `bloc_test`/`flutter_test`; no `build_runner` regen |

### KGP / Built-in Kotlin residual

`flutter build apk --debug` **succeeded** with escape hatches intact:

- `android/gradle.properties`: `android.builtInKotlin=false`, `android.newDsl=false`
- `android/build.gradle.kts`: `file_picker` force-apply of `org.jetbrains.kotlin.android` + JVM 17

Flutter still warns that these plugins apply legacy KGP:

| Plugin | Resolved | Why not cleared | Upstream |
| --- | --- | --- | --- |
| `file_picker` | **11.0.2** (pinned) | Stable latest is still 11.0.2; **12.x is prerelease only** on pub.dev. Keep pin + force-apply until a stable Built-in Kotlin release. | [Issue #2031](https://github.com/miguelpruivo/flutter_file_picker/issues/2031), [PR #2026](https://github.com/miguelpruivo/flutter_file_picker/pull/2026) (migration in 12.x line) |
| `home_widget` | **0.9.3** (latest) | 0.9.2+ supports AGP 9 / applies Kotlin when `builtInKotlin=false`; still listed in Flutter KGP warning under escape hatch. | [Changelog 0.9.2 / 0.9.2+1](https://pub.dev/packages/home_widget/changelog) |
| `package_info_plus` | **9.0.1** (transitive via `wakelock_plus`) | Built-in Kotlin lands in **10.2.0+**; not forced — would require major override through `fwfh_chewie`/`wakelock_plus` tree. | [CHANGELOG 10.2.0](https://github.com/fluttercommunity/plus_plugins/blob/main/packages/package_info_plus/package_info_plus/CHANGELOG.md) |
| `wakelock_plus` | **1.5.2** (transitive via `fwfh_chewie`) | **1.7.0** claims Built-in Kotlin, but reports compile gaps with legacy/`builtInKotlin=false` setups — do not force while escape hatches remain. | [Issue #135](https://github.com/fluttercommunity/wakelock_plus/issues/135), [PR #136](https://github.com/fluttercommunity/wakelock_plus/pull/136), [Bug after 1.7.0](https://github.com/fluttercommunity/wakelock_plus/issues/141) |

**Escape hatches: keep.** Do not flip `builtInKotlin=true` or remove the `file_picker` force-apply until all four clear (or `file_picker` ships a stable 12.x Compatible with our AGP 9 stack).

Flutter migration guide: [Built-in Kotlin for app developers](https://docs.flutter.dev/release/breaking-changes/migrate-to-built-in-kotlin/for-app-developers).

### Builds (Batch 3)

| Target | Result | Notes |
| --- | --- | --- |
| `flutter analyze` | 0 errors (pre-existing infos/warnings only) | Post sqlite bump |
| H5-T7 encryption/schema | **43/43 passed** | `sqlite3mc` hook active |
| `flutter build apk --debug` | **PASS** | KGP warning residual only; `app-debug.apk` produced |
| `flutter build windows --debug` | **FAIL this run** — `LNK1168` cannot open `build\windows\x64\runner\Debug\synesis.exe` for writing (file lock; app likely running). Not a sqlite/plugin regression. Re-run when exe unlocked; H5 still owns green Windows debug. |
| Release APK + OAuth dart-defines | **Not required this batch** | Dogfood footgun remains: release APK must be built **with** production dart-defines / public clients (H5-M9) |

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

**Batch sequencing:** Batch 3 cleared H5-M8 (Android debug APK) and H5-T7 (encryption/schema). H5 still owns full `flutter test`, Windows HTML/OAuth smokes, and dogfood APK with dart-defines (H5-M9). Missing AppLinks/Android-adapter unit tests are **not** NO-GO if H5-M1/M2 run.

## References

| Doc | Role |
| --- | --- |
| [V2_PLAN.md](V2_PLAN.md) §4 | Wave H summary + hold on V2.0a |
| [W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md) | sqlite3mc hook + encryption boundary |
| [W6_NOTIFICATIONS_CHECKLIST.md](W6_NOTIFICATIONS_CHECKLIST.md) | Prior notification manual smoke (reuse lightly for H5-M1) |
| [TEST_INVENTORY.md](TEST_INVENTORY.md) | Post-upgrade test catalog refresh |
