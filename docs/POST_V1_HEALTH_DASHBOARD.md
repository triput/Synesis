# Post-V1 / Adjacent — Project Health Dashboard

| Field | Value |
| --- | --- |
| Status | **Idea / stub only** — no implementation |
| Priority | Pri-3 · **Adjacent tooling** (not a product feature) |
| Roadmap | [ROADMAP.md Planned backlog](ROADMAP.md#planned-backlog-post-foundation) |
| Final wave | Explicitly **out of scope** — [FINAL_WAVE_PLAN.md §7](FINAL_WAVE_PLAN.md#7-out-of-scope--post-v1) |
| Last updated | 2026-07-18 |

## Vision

A lightweight **project health dashboard** spun up **after V1 ship**, while the operator dogfoods ByteMail. It aggregates development and quality signals into one place so progress and risk are visible without digging through markdown and CSVs by hand.

This is **meta / adjacent tooling** — intended to be **reusable across ByteMail and future projects**, not a ByteMail mail-client feature.

## Intended surfaces

| Area | What it would show |
| --- | --- |
| **Development progress** | Wave / milestone status, open todos, backlog Pri rows |
| **Testing results** | Links and rollups patterned on [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) / [TEST_INVENTORY.md](TEST_INVENTORY.md) |
| **Performance metrics** | When a perf suite / catalog exists (Post-V1 Pri-2 in ROADMAP) |
| **Related health** | Checklist pass/fail, DEFECTS open counts, coverage floors, other operator-defined signals |

## Likely inputs (read-only consumers)

- Wave / status docs (`ROADMAP.md`, wave checklists, `FINAL_WAVE_PLAN.md`)
- Automated test inventory CSV (+ generate script patterns in `tool/`)
- Manual E2E matrix CSV when present
- Future performance catalog (same spreadsheet style as test inventory)
- Optional: CI summaries, DEFECTS.md tallies

Exact stack (static site, local app, Notion, etc.) is **undecided** — pick when spinning up post-V1.

## Reuse goal

Design adapters so another repo can point at its own:

- milestone / wave status docs
- test-inventory CSV schema
- (later) perf catalog

ByteMail is the first consumer, not the only one.

## Non-goals

- **Not** a V1 deliverable or Final-wave phase
- **Not** a mail product feature (no in-app ByteMail UI requirement)
- **Does not** block V1 exit, FW-1…FW-6, or dogfood start
- **No implementation** in this stub — docs only until post-V1 kickoff

## When to start

After V1 sign-off / while dogfooding. Prefer after FW-5 inventory + FW-6 playbook exist so input formats are stable.
