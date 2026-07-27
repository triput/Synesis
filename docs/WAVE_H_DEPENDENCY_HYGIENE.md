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

## References

| Doc | Role |
| --- | --- |
| [V2_PLAN.md](V2_PLAN.md) §4 | Wave H summary + hold on V2.0a |
| [W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md) | sqlite3mc hook + encryption boundary |
| [TEST_INVENTORY.md](TEST_INVENTORY.md) | Post-upgrade test catalog refresh |
