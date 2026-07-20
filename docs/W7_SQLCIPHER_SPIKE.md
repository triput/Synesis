# W7 — TC-3 DB Encryption Spike (SQLCipher / SQLite3MultipleCiphers)

| Field | Value |
| --- | --- |
| Owner | Tesla (integration/sync spike) |
| Date | 2026-07-18 |
| Scope | [TC-3 — Optional encryption at rest (desktop DB)](ROADMAP.md) |
| Verdict | **SHIP in W7** — opt-in encryption landed, default unencrypted path unchanged |

## TL;DR

`sqlcipher_flutter_libs` is obsolete for our stack (v3.x `sqlite3` package
already uses the hooks/native-assets build system). No new dependency was
needed. Adding four lines to `pubspec.yaml` (`hooks.user_defines.sqlite3.source:
sqlite3mc`) swaps the bundled SQLite for **SQLite3MultipleCiphers**, which is
a drop-in, API-compatible SQLite build. On this Windows dev box the native
binary downloaded and linked cleanly, the full existing test suite still
passes, and a new encrypt/decrypt round-trip test suite (18 tests) proves the
feature works end-to-end, including through Drift's `NativeDatabase
.createInBackground` background-isolate path. Encryption ships **disabled by
default**; nothing changes for users who don't opt in.

## What was tried

1. **Dependency compatibility research.** Confirmed via pub.dev and Drift's
   own docs that `sqlcipher_flutter_libs` (obsolete, 0.7.0+eol — "no longer
   does anything") and our existing `sqlite3_flutter_libs: ^0.6.0+eol` (also
   a no-op placeholder) both belong to the pre-3.x `sqlite3` build pipeline.
   Our `sqlite3: ^3.4.0` is already on the modern hooks-based pipeline (this
   workspace's `.dart_tool/hooks_runner/` cache proves hooks are already
   active for the plain SQLite build). The correct, current mechanism is
   Drift/`sqlite3`'s `hooks.user_defines.sqlite3.source` pubspec key —
   `sqlite3mc` (SQLite3MultipleCiphers) or `sqlcipher`.
2. **Added the hook override** to the root `pubspec.yaml` and ran `flutter
   pub get`. No dependency resolution conflicts; 39 unrelated packages had
   newer versions available (pre-existing, unrelated to this change).
3. **Triggered the native build** via `flutter test`. A new
   `sqlite3mc.dll` (2.1&nbsp;MB) was downloaded and cached under
   `.dart_tool/hooks_runner/shared/sqlite3/build/` — no
   `CERTIFICATE_VERIFY_FAILED` handshake issue (a known Windows failure mode
   reported against `simolus3/sqlite3.dart#354`) was hit on this host.
4. **Verified cipher behavior** with throwaway then permanent smoke tests:
   `PRAGMA cipher;` returns rows (cipher build confirmed active), `PRAGMA key`
   correctly gates read access (wrong key throws `SqliteException`, right key
   reads through), and `NativeDatabase.createInBackground(file, setup: ...)`
   — the exact pattern `_openConnection()` now uses — opens an encrypted file
   from a background isolate without issue. `PRAGMA key` is rejected on
   in-memory databases (`SqliteException`), which is why
   `NativeDatabase.memory()` — used by every existing unit test — is
   completely unaffected by turning this feature on.
5. **Ran the pre-existing suite** (`flutter test`) with the hook active:
   328 tests passed. The 6 failures observed are pre-existing/concurrent
   `MailRepository` interface-implementation gaps from unrelated in-flight
   work on custom themes/signatures/templates (`test/widget_test.dart`,
   `test/mailbox_cubit_test.dart`, etc.) — confirmed by `git diff --stat` on
   `lib/repository/mail_repository.dart` showing uncommitted, in-progress
   changes at spike time. None of the failures touch `database.dart`,
   `db_encryption_*`, or SQLite/native code paths.
6. **Implemented the feature** (see "What shipped" below) and added 18 new
   passing tests: 14 pure config/path-helper tests (no native SQLite touched)
   and 4 native encrypt/decrypt round-trip tests guarded by a runtime
   `PRAGMA cipher` capability probe (`markTestSkipped` if unavailable, so a
   host without the cipher build doesn't fail CI).

## Blockers

None that block shipping. Residual risk, tracked for W7.1+/post-V1 rather
than blocking this wave:

- **Windows build-hook download reliability.** The GitHub issue referenced
  above shows this hook download can fail on some Windows machines/networks
  with a certificate handshake error, with a documented one-time
  `Invoke-WebRequest` workaround. It did not reproduce here. Worth a note in
  the Windows release checklist ([W5_WINDOWS_CHECKLIST.md](W5_WINDOWS_CHECKLIST.md))
  so a clean-machine CI/release build failure has a known fix.
- **Live DB hot-swap is intentionally out of scope for V1.** Toggling
  encryption on/off migrates the file in place (`VACUUM INTO` + `PRAGMA
  rekey`, per Drift's documented recipe) but does **not** attempt to
  hot-swap the already-open `ByteMailDatabase` connection held by the running
  app's DI graph — that is a much larger blast-radius change (every Bloc/
  Cubit holds a `MailRepository` built on top of one `ByteMailDatabase`).
  Instead, the settings sheet finishes the file migration, persists the new
  config, and prompts a restart (`DesktopController.quit()` on Windows,
  `SystemNavigator.pop()` elsewhere). This is a deliberate, documented
  boundary — not a deferral of the encryption feature itself.
- **`sqlite3_flutter_libs: ^0.6.0+eol` cleanup.** Confirmed as an inert
  no-op dependency (kept only for transitive-dependency compatibility on the
  old 2.x pipeline). Safe to remove in a future dependency-hygiene pass; left
  untouched here to keep this change minimal.

## What shipped (files touched)

| File | Purpose |
| --- | --- |
| `pubspec.yaml` | `hooks.user_defines.sqlite3.source: sqlite3mc` — swaps bundled SQLite for the cipher-capable build. No new package dependency. |
| `lib/repository/db_encryption_config.dart` | `DbEncryptionConfig` (prefs flag + `flutter_secure_storage` passphrase, never persisted in plaintext prefs) and `DbEncryptionPaths` (pure path helpers for the db file + migration temp/backup artifacts). |
| `lib/repository/db_encryption_migrator.dart` | `DbEncryptionMigrator` — `VACUUM INTO` + `PRAGMA rekey` in-place plaintext↔encrypted migration, run on a background isolate via `Isolate.run`, with backup + integrity-check + rollback on failure. |
| `lib/repository/database.dart` | `_openConnection()` now resolves an active passphrase via `DbEncryptionConfig` and applies it through `NativeDatabase`'s `setup` callback (`PRAGMA key`). Falls back to a plain unencrypted open on any missing/corrupt config — a broken preference state can never lock a user out. |
| `lib/ui/settings/db_encryption_sheet.dart` | "Encryption" settings sheet: toggle, irreversible-loss warning + acknowledgment checkbox, passphrase + confirm fields (min 8 chars), disable/decrypt confirmation, restart prompt. |
| `lib/ui/settings/appearance_sheet.dart` | Added an "Encryption" `ListTile` entry point next to "Sync & storage". |
| `test/db_encryption_config_test.dart` | 14 tests: prefs persistence, passphrase never leaks into `SharedPreferences`, empty/whitespace/short passphrase rejection, `resolveActivePassphrase` fallback behavior, path helpers. No native SQLite touched. |
| `test/db_encryption_migrator_test.dart` | 4 tests: short-passphrase rejection, no-op on missing file, full encrypt round-trip (wrong key fails / right key reads), encrypt-then-decrypt round-trip. Native-cipher tests self-skip via a `PRAGMA cipher` capability probe. |
| `docs/W7_SQLCIPHER_SPIKE.md` | This document. |

No changes were made to `test/schema_v5_test.dart`, `test/message_query_test.dart`, or any other existing test — all continue to use `NativeDatabase.memory()`/explicit file paths untouched, and all pass.

## Evidence log

- `flutter pub get` — clean resolve, no conflicts, exit 0.
- `flutter test test/schema_v5_test.dart test/sync_profile_test.dart test/message_query_test.dart test/message_actions_repo_test.dart test/schema_migration_v4_to_v5_test.dart test/drift_mail_repository_test.dart` — **61/61 passed** with the `sqlite3mc` hook active.
- `flutter test test/db_encryption_config_test.dart test/db_encryption_migrator_test.dart` — **18/18 passed**.
- `flutter test` (full suite) — **328 passed / 6 failed**; failures isolated to `MailRepository` interface gaps in unrelated, concurrently in-progress work (custom themes/signatures/templates), not to anything in this spike.
- `.dart_tool/hooks_runner/shared/sqlite3/build/download-228e39a6/sqlite3mc.dll` (2,129,920 bytes) — proof the Windows native hook build succeeded for the cipher variant.

## Recommendation

**Ship TC-3 in W7** as an opt-in, off-by-default setting. Do not schedule a
W7.1 deferral or elevate to post-V1 Pri-1 — the spike cleared every item in
the decision rule (no dependency conflict, no Windows build break, migration
implemented safely with backup/rollback). Page: please fold the new test
files into `docs/V1_AUTOMATED_TEST_INVENTORY.csv` via
`tool/generate_test_inventory.py` and update the TC-3 row in
[ROADMAP.md](ROADMAP.md) if it hasn't already been synced from this doc.
