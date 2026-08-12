# Wave H2 — Dependency Hygiene (Quick Scan Preview)

> **Status:** **Quick scan only** (2026-08-12). Full H2 **not opened**. **No upgrades this pass** (Trish locked **(b)**). Parent: [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md) (Wave H complete); schedule stub in [V2_PLAN.md](V2_PLAN.md) / [ROADMAP.md](ROADMAP.md).

Per-version hygiene after V2.0 freeze — toolchain pins, pub debt snapshot, native/plugin residuals, docs alignment. **This pass is document-only:** no `pub upgrade`, no pubspec bumps, no Gradle escape-hatch flips.

**Scan date:** 2026-08-12 · **Branch:** `v2.0` @ `b722b22` (schedule commit pushed)

---

## Sequence (when full H2 opens)

```text
V2.0 exit → V2.0 freeze/tag → Wave H2 (full batches) → Wave R → V2.1 features
```

This preview covers scan steps **H2-S1–S4** only; full H2 will expand to soft/major upgrade batches mirroring Wave H (H1–H5).

---

## H2-S1 — SDK pin verify

| Check | Value / result |
| --- | --- |
| `.flutter-version` | **3.44.6** |
| `pubspec.yaml` `environment.sdk` | **^3.12.2** |
| Live `flutter --version` | Flutter **3.44.6** stable, Dart **3.12.2**, DevTools **2.57.0**, framework revision `ee80f08bbf` (2026-07-08) |
| Docs pins | README, QUICK_START, DART_IN_SYNESIS, ARCHITECTURE_OVERVIEW advertise **3.44.6** / **^3.12.2** — **aligned** |

**Verdict: PASS** — pins match toolchain; no doc drift.

---

## H2-S2 — pub outdated (summary only; no upgrades)

From `flutter pub outdated` (2026-08-12). **Do not run `pub upgrade` this pass.**

### Direct deps of interest

| Package | Current | Upgradable | Resolvable | Latest | Notes |
| --- | --- | --- | --- | --- | --- |
| `drift` | 2.34.2 | 2.34.3 | 2.34.3 | 2.34.3 | Soft patch available |
| `file_picker` | 11.0.2 | 11.0.2 | 12.0.0-beta.7 | 11.0.3 | Wave H residual; latest stable now **11.0.3** (was 11.0.2); 12.x still beta |
| `flutter_local_notifications` | 22.2.0 | 22.3.0 | 22.3.0 | 22.3.0 | Soft minor |
| `flutter_secure_storage` | 10.3.1 | 10.3.1 | 11.0.0 | 11.0.0 | Major candidate |
| `google_fonts` | 8.2.0 | 8.2.1 | 8.2.1 | 8.2.1 | Soft patch |
| `pdf` | 3.12.0 | 3.12.0 | 3.12.0 | 3.13.0 | Still deferred with `xml` |
| `printing` | 5.14.3 | 5.14.3 | 5.14.3 | 5.15.0 | Deferred with pdf/xml |
| `sqlite3` | 3.5.0 | 3.5.1 | 3.5.1 | 3.5.1 | Soft patch; keep sqlite3mc hook |
| `xml` | 6.6.1 | 6.6.1 | 6.6.1 | 7.0.1 | Blocked by `enough_mail` ^6 |

### Dev deps

| Package | Current | Latest | Notes |
| --- | --- | --- | --- |
| `drift_dev` | 2.34.0 | 2.34.5 | Still deferred (analyzer conflict with `bloc_test` / `flutter_test`) |
| `build_runner` | 2.15.1 | 2.16.0 | Constrained; skew vs latest |

**Lockfile note:** 23 upgradable locked older; 9 constrained below resolvable major path. **Do not run pub upgrade.**

---

## H2-S3 — Wave H residuals still open

Carried forward from [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md) known residuals (confirmed 2026-08-12):

| Residual | Status / notes |
| --- | --- |
| **KGP escape hatches** | `android.builtInKotlin=false`, `android.newDsl=false` in `gradle.properties`; `file_picker` force-apply in `android/build.gradle.kts` — **still present**. AGP **9.0.1**, Kotlin plugin **2.3.20** in `settings.gradle.kts`. |
| **Deferred majors** | `xml` / `pdf` / `printing` / `file_picker` 12 / `drift_dev` 2.34.5 |
| **Transitive KGP debt** | `package_info_plus` 9.0.1 (Built-in Kotlin in 10.2+); `wakelock_plus` 1.5.2 (1.7.0 has Built-in Kotlin but compile gaps with escape hatches) |
| **Operator dogfood smokes** | H5-M1–M5, M7, M9 still residual |
| **Pri-3 test debt** | `AppLinksOAuthRedirectCapture` unit test; thin fln adapter mock |

---

## H2-S4 — Drift codegen skew

| Item | Value |
| --- | --- |
| `drift` resolved | **2.34.2** |
| `drift_dev` resolved | **2.34.0** (constraint `^2.34.0`) |
| Latest `drift_dev` | **2.34.5** — still blocked |

Mild skew within 2.34.x. **No `build_runner` regen this pass**; no codegen change recommended until full H2 unlocks an analyzer-compatible path.

---

## Explicit policy

**No upgrades this pass.** No `pub upgrade`, no pubspec version bumps, no Gradle flip of `builtInKotlin`.

---

## Recommended next actions (when full H2 opens)

1. **Soft patch batch (optional):** `drift` 2.34.3, `sqlite3` 3.5.1, `google_fonts` 8.2.1, `flutter_local_notifications` 22.3.0, `file_picker` 11.0.3 if safe.
2. **Re-evaluate majors:** `flutter_secure_storage` 11; `xml` ^7 / `pdf` / `printing` unlock vs `enough_mail`; `file_picker` 12 stable when available.
3. **Revisit `drift_dev` 2.34.5 + analyzer vs `bloc_test`**; regen Drift codegen if unlocked.
4. **Reassess KGP escape hatches / `builtInKotlin`** after upstream clears (`file_picker`, `package_info_plus`, `wakelock_plus`).
5. **Full H5-style verify:** `flutter test` + Windows/Android debug builds + refresh test inventory if needed.
6. **Promote this checklist** to full-batch status; then Wave R.

---

## Out of scope

- Feature work, Wave R, pub upgrades, `builtInKotlin` flip.

---

## References

| Doc | Role |
| --- | --- |
| [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md) | Wave H complete checklist + original residuals |
| [V2_PLAN.md](V2_PLAN.md) | Post–V2.0 sequence (H2 → R → V2.1) |
| [ROADMAP.md](ROADMAP.md) | Living wave index |
| [TEST_INVENTORY.md](TEST_INVENTORY.md) | Post-upgrade test catalog refresh (full H2 only) |
