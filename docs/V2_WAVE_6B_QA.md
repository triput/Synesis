# Wave 6b — Renee QA (CalDAV/CardDAV Write)

> **Status:** **E7 engineering GO** (2026-08-04). E8 Runbox dogfood open for Trish. Checklist: [V2_WAVE_6B_CHECKLIST.md](V2_WAVE_6B_CHECKLIST.md). Design: [V2_WAVE_6B_TESLA_DESIGN.md](V2_WAVE_6B_TESLA_DESIGN.md).

| Field | Value |
| --- | --- |
| Reviewed | 2026-08-04 |
| Commits under review | `69ce462` (Tesla P0–P3 create path + UI honesty flip) |
| Prior gate | Wave 6 exit (**659** tests) |
| Tests | **668/668 passed** (`flutter test`, Renee E7) |
| Verdict | **GO** — engineering exit (E7); wave complete after E8 |
| Operator dogfood (E8) | **Pending** — Trish Runbox |

---

## Verdict

| Gate | Decision | Notes |
| --- | --- | --- |
| CalDAV PUT create (`createEvent`) | **Pass** | Collection href + `{uid}.ics`; `If-None-Match: *`; Location/ETag → `PimRemoteCreateResult`. |
| CardDAV PUT create (`createContact`) | **Pass** | Same pattern with `.vcf` + `text/vcard`. |
| SyncEngine copy handlers (DAV) | **Pass** | Early-return on `DavPimProvider` removed; rewrite via `rewrite*ProviderId`. |
| `PimCopyService` enqueue for DAV | **Pass** | `_shouldEnqueueRemotePush` true for any resolved PIM provider (Graph/Google/DAV). |
| Soft-delete guard for `local:*` | **Pass** | Full-snapshot missing soft-delete still skips `PimIds.isLocalProviderId` (events + contacts). |
| Undo / soft-deleted skip before PUT | **Pass** | Wave 6 E10 retained — `deletedAt != null` → no create. |
| UI honesty (E6) | **Pass** | Sheet subtitle + snackbars branch on push support / enqueue; DAV no longer “Local only”. |
| Graph / Google copy regression | **Pass** | Existing Graph POST + rewrite tests green in same suite. |
| Full regression | **Pass** | **668/668**. Net **+9** vs Wave 6 (659). |
| Wave 6b engineering exit (E7) | **GO** | No Pri-1 / data-safety blockers. |
| E8 dogfood handoff | **Ready** | Trish Runbox matrix below. |

No Pri-1 defects from Wave 6b create-only write. Accepted MVP risks match Tesla D1 (412 on retry after rewrite crash).

---

## Scope under test

| Area | Result | Evidence |
| --- | --- | --- |
| ICS / vCard minimal writers | Pass | `dav_pim_create_test` — field map, escaping, all-day DATE, round-trip parse |
| `DavClient.put` headers + errors | Pass | `If-None-Match: *`; 412 → `ProtocolException` |
| `DavPimProvider.createEvent/Contact` | Pass | PUT URL under collection; uid from `local:{uuid}` |
| SyncEngine DAV `events_copy` / `contacts_copy` | Pass | PUT + rewrite + job `done` |
| Enqueue for DAV target | Pass | `enqueues events_copy for DAV target` (replaces Wave 6 no-enqueue) |
| Soft-delete preserves unpushed copies | Pass | Google-style filter test + SyncEngine source still guards `local:*` |
| UI labels for DAV targets | Pass | Code review: `remotePushSupportedForAccount` / `remotePushEnqueued` |
| Update/delete push / series | Out of scope | Trail / Wave 6c |

---

## Defensive review findings

| Gap | Severity | Disposition |
| --- | --- | --- |
| PUT succeeded, rewrite crashed → retry may 412 on same uid/filename | Medium — accepted MVP | Documented Tesla D1; same class as Wave 6 POST double-create note. |
| Collection href without trailing `/` mis-resolves `{uid}.ics` via `Uri.resolve` | Low | Discovery/store expect trailing `/` (design D1); watch on Runbox E8. |
| Calendar workspace “Local only — not yet pushed” banner for **local CRUD** | Info / intentional | `events_push` still no-op; copy path honesty is separate and correct. |
| Contact copy snackbar lacks Undo | Low | Wave 6 carryover; events keep Undo + soft-delete skip. |
| Sheet honesty not covered by a dedicated widget assert for DAV | Low | Service enqueue + flag flip covered; optional Page/And follow-up. |
| Sync status sheet still shows raw `events_copy` / `contacts_copy` type strings | Low | Wave 6 polish carryover. |

---

## Checklist matrix (engineering)

| Requirement | Status | Evidence |
| --- | --- | --- |
| Copy event → DAV calendar: local + remote PUT job | Pass (auto) | `dav_pim_create_test` SyncEngine group; E8 live |
| Copy contact → DAV list: same | Pass (auto) | Same |
| Graph/Google ↔ DAV paths (DAV write side) | Pass (auto) / E8 live | Enqueue + PUT path; Graph regression green |
| Unpushed `local:*` not wiped by full-pull soft-delete | Pass | SyncEngine filter + unit test |
| Renee GO + Page inventory | **GO** / handoff | This doc + delta below |
| Trish E8 Runbox dogfood | Pending | Matrix below |

---

## Operator dogfood matrix (E8 — Trish)

| # | Scenario | Expect |
| --- | --- | --- |
| 1 | Graph/Google → Runbox CalDAV: copy event | Local chip immediately; snackbar “Syncing to your provider…”; Sync sheet `events_copy` → done; event appears in Runbox web/other client |
| 2 | Any → Runbox CardDAV: copy contact | Same pattern with `contacts_copy`; contact visible remotely |
| 3 | Runbox → Graph/Google: copy event or contact | Local + remote create on Graph/Google (regression) |
| 4 | Sheet / DnD target list for Runbox calendar/list | **No** “Local only — not synced yet” subtitle |
| 5 | Undo event copy quickly after DAV drop | Local row gone; **no** orphan remote object |
| 6 | Full pull / refresh while copy still `local:*` | Unpushed copy remains until rewrite |
| 7 | Recurring source event | Still single independent copy (no RRULE) — Wave 6c |

**Ready for Trish E8?** **Yes** — engineering GO; dogfood unblocks wave close.

---

## Test delta (Renee → Page)

Baseline Wave 6: **659**. E7 suite: **668** (+9).

| Path | Cases (names) | Kind | Maps to | Change |
| --- | --- | --- | --- | --- |
| `test/dav_pim_create_test.dart` | `writes minimal VEVENT fields Wave 6 copies`; `writes all-day VALUE=DATE`; `writes minimal vCard fields Wave 6 copies`; `sends If-None-Match and returns Location/ETag`; `maps 412 to ProtocolException`; `createEvent PUTs .ics under collection href`; `createContact PUTs .vcf under collection href`; `events_copy PUTs CalDAV create and rewrites providerId`; `contacts_copy PUTs CardDAV create and rewrites providerId` | unit/integration | Wave 6b P1–P2 / E1–E4 | **New** (9) |
| `test/pim_copy_sync_engine_test.dart` | `enqueues events_copy for DAV target` (replaces Wave 6 `does not enqueue for DAV target`); remaining Graph/idempotent/soft-delete/local:* cases unchanged | unit/integration | Wave 6b E5 | **Touched** (0 net cases; 1 rename/behavior flip) |

Regenerate or patch `docs/V1_AUTOMATED_TEST_INVENTORY.csv` via `tool/generate_test_inventory.py` (Page). Expected catalog total after refresh: **668**.

---

## Explicitly out of scope (confirmed)

- Update/delete remote push for local CRUD
- Calendar series / RRULE copy (**Wave 6c**)
- Free/busy, ACLs, PROPPATCH, sync-collection REPORT polish
- Live Runbox in CI (operator E8 only)

---

*Renee E7 signed 2026-08-04. Wave close after Trish E8 + Page inventory.*
