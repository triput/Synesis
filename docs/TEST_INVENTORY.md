# Automated Test Inventory

ByteMail tracks **automated** unit, widget, and BLoC tests in a versionable inventory so coverage can be evaluated by wave, tier, and component without duplicating file lists in every checklist. Manual smoke and E2E runs stay in wave checklists and (future) the manual E2E matrix — not here.

## Artifacts

| Artifact | Role |
| --- | --- |
| [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) | **Canonical** git-tracked source (~389 cases / 56 files). Diff-friendly; edit or regenerate. |
| [`V1_AUTOMATED_TEST_INVENTORY.xlsx`](V1_AUTOMATED_TEST_INVENTORY.xlsx) | Operator workbook (Automated, By_File, Wave_Summary, Coverage_Gaps, Readme sheets). Regenerated from CSV. |
| [`../tool/generate_test_inventory.py`](../tool/generate_test_inventory.py) | Scanner/regenerator for both artifacts. |

**Not in scope:** [`V1_MANUAL_E2E_MATRIX.csv`](V1_MANUAL_E2E_MATRIX.csv) (ROADMAP **FW-5**) — planned manual E2E matrix; separate from this automated catalog.

Suite/case wave and kind overrides (from Renee inventory handoffs) live in `tool/generate_test_inventory.py` (`GROUP_WAVE`, `CASE_WAVE`, `GROUP_KIND`, `CASE_KIND`).

## Regenerate

From repo root (requires Python 3 + `openpyxl`):

```bash
py tool/generate_test_inventory.py
```

Use full regeneration when many `test/*_test.dart` files change or Renee’s wave-close delta is large. For one-off additions, patch CSV rows and rerun the tool to refresh the workbook.

## Column definitions (CSV)

| Column | Meaning |
| --- | --- |
| `test_id` | Stable ID (`AT-{wave}-{nnn}`). Link target for checklists and tier docs. |
| `wave` | Integration wave (W0–W7, Foundation, X, …). |
| `tier_refs` | Tier plan refs (TA-*, TB-*, TC-*, DEF-*, M*). |
| `test_file` | Path under `test/`. |
| `test_group` / `test_name` | Dart `group()` / `test()` / `testWidgets()` label. |
| `kind` | `unit`, `widget`, `bloc`, `integration`, `contract`, or `smoke`. |
| `component` | Subsystem label (Sync, Compose, UI / Shell, …). |
| `platform` | `All`, or platform-specific when scoped. |
| `asserts` | Short assertion summary from the test body. |
| `status` | Row lifecycle (`active`, …). |
| `evaluation_status` | **Cataloged** = listed in inventory only. **Not** Pass/Fail until an explicit `flutter test` run records otherwise. |
| `added_date` | Date row entered catalog. |
| `last_verified_wave` | Last wave when runtime verification was recorded (if any). |
| `manual_companion` | Optional link to manual checklist section. |
| `notes` | Source line or operator notes. |

Filter examples: `wave=W5` for Windows desktop wave; `wave=W6` for notifications wave; `tier_refs` contains `TA-0`; `kind=bloc`.

## Wave-close ritual

1. **Renee** — On wave land or material test changes, emit a delta: new/changed `test/*_test.dart` paths, `test('…')` names (or `*`), deliverable/tier/DEF refs, and kind.
2. **Page** — Update `V1_AUTOMATED_TEST_INVENTORY.csv` (regenerate or patch), refresh `.xlsx`, keep this doc accurate.
3. **Steve** — Gate wave “landed” only after inventory includes every automated test touched in that wave.

## Manual companions

Wave checklists are the operator runbooks; they **link** the inventory instead of duplicating full file lists:

- [W5 Windows checklist](W5_WINDOWS_CHECKLIST.md) — filter inventory `wave=W5`
- [W6 Notifications checklist](W6_NOTIFICATIONS_CHECKLIST.md) — filter `wave=W6`
- [W2 AVD checklist](W2_AVD_CHECKLIST.md) — filter `wave=W2`

See also [V1 tier integration](V1_TIER_INTEGRATION.md) §5 for wave exit criteria.
