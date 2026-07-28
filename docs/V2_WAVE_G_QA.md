# Wave G / V2.0d — Google PIM (People + Calendar API) — Renee QA notes

| Field | Value |
| --- | --- |
| Reviewed | 2026-07-27 |
| Commits | `f4c21b0` (wave land) |
| Checklist | [V2_WAVE_G_CHECKLIST.md](V2_WAVE_G_CHECKLIST.md) |
| Prior gate | [V2_WAVE5_QA.md](V2_WAVE5_QA.md) **GO** (585 tests) |
| Tests | **597/597 passed** (`flutter test`, verified independently by Renee) |
| Verdict | **GO** Wave G exit · **GO** Wave 6 handoff |

Wave G adds read-only **Google People + Calendar API** sync for Google XOAUTH
IMAP accounts into the existing provider-agnostic `DriftPimStore`. Exit is
approved for the locked MVP: API-only binding (no CardDAV/CalDAV for `google:` /
`xoauth2`), 90d/365d event window, soft-delete on full snapshots, re-auth for
scope expansion, and local-first UI consumption without new module chrome.

---

## Verdict

| Gate | Decision | Notes |
| --- | --- | --- |
| Contacts sync (lists + contacts) | **Pass** | `GooglePimProvider.listContactFolders` / `syncContacts` map contact groups + My Contacts connections into stable `ContactList`/`Contact` ids; SyncEngine `contact_lists_bootstrap` upserts and fans out `contacts_bootstrap`. Covered by `google_pim_provider_test` + `google_pim_sync_engine_test`. |
| Calendars + events (90d/365d) | **Pass** | Window aliases `kGoogleEventHorizonPast`/`Future` = Graph 90d/365d; `syncEvents` asserts `timeMin`/`timeMax`/`singleEvents`; calendars bootstrap preserves display prefs and soft-deletes missing window rows. |
| Provider registry (Google → API, no DAV) | **Pass** | `resolvePim` returns `GooglePimProvider` for `google:` refs and `imap.auth=xoauth2`; explicitly `isNot(DavPimProvider)`. Graph/password-DAV branches unchanged (`provider_registry.dart`). |
| Re-consent / scope expansion | **Pass** | Scopes `contacts.readonly` + `calendar` in `GoogleAuthConfig`; Edit account → Re-authenticate with Google → `updateGoogleCredentials` enqueues mail + PIM bootstrap; in-app hint + class doc; README + QUICK_START updated (Page 2026-07-27). |
| Local-first UI / picker | **Pass** | Wave 5 Calendar/People/compose picker already read `DriftPimStore` only; Google rows share the same schema. No UI chrome change required; suite includes Wave 5 module/picker regression coverage. |
| Graph / DAV / mail unaffected | **Pass** | Graph + DAV sync-engine suites green in the same 597 run; mail XOAUTH resolve tests still pass; Google path is additive (`resolvePim` early-return before DAV). |
| Full regression | **Pass** | **597/597** independently executed. Net **+12** vs Wave 5 (585). |
| Workspace dogfood | **Operator-pending** | Checklist script remains for Trish Workspace principal; not a code Pri-1. |
| Wave G exit | **GO** | No Pri-1 / data-safety blockers. |
| Wave 6 handoff | **GO** | Cross-account DnD copy unblocked; may build on local store surface (Wave 5 + G). |

No Pri-1 defects found. Nothing added to `DEFECTS.md` for this wave.

---

## Checklist matrix

| Requirement | Status | Evidence |
| --- | --- | --- |
| Google XOAUTH: contact lists + contacts → local schema | Pass | Provider fixtures + SyncEngine bootstrap → Drift upsert + contacts job fan-out |
| Google XOAUTH: calendars + events (90d past / 365d future) | Pass | Window query-param test; calendars bootstrap + soft-delete missing on window |
| Registry: `GooglePimProvider`; no DAV for `google:` / xoauth2 | Pass | `provider_registry_google_test.dart` (2 PIM cases); registry source early Google branch |
| Re-consent documented; scope expansion on existing accounts | Pass | `GoogleAuthConfig` doc + Edit account UX + `updateGoogleCredentials` test; README + QUICK_START Google scopes (Page 2026-07-27) |
| People + Calendar UI + compose picker consume Google rows | Pass | Local-first store path (Wave 5 architecture); no Google HTTP in UI layers |
| Graph PIM, DAV PIM, mail unaffected; suite green | Pass | 597/597 incl. `graph_pim_*`, `dav_pim_*`, mail/XOAUTH registry |
| Workspace dogfood notes; inventory refresh | Partial | Dogfood operator-pending; inventory regenerated (Page 2026-07-27) |

---

## Scope checked

| Area | Result | Evidence |
| --- | --- | --- |
| `GooglePimProvider` | Pass | Extends `GraphPimProvider` for SyncEngine typing (same pattern as DAV); People + Calendar hosts only; RSVP/`fetchAssociatedEvent` unsupported (Wave G out-of-scope). |
| OAuth scopes | Pass | `contacts.readonly` + `calendar` (+ mail/openid/email/profile); asserted in `oauth_identity_manager_test.dart`. |
| AccountService bootstrap | Pass | `addGoogleImapAccount` + `updateGoogleCredentials` call `_enqueuePimBootstrap` (`contact_lists_bootstrap` + `calendars_bootstrap`); update path unit-tested for all three job types. |
| SyncEngine soft-delete | Pass | Full-snapshot soft-delete for `GooglePimProvider` when cursor empty (contacts + events); incremental People `syncToken` uses `removedProviderIds` and skips mass soft-delete. Engine test covers missing event soft-delete on window pull. |
| Display-pref preserve | Pass | Calendars bootstrap test asserts `isSelectedForDisplay` / `sortIndex` survive refresh (same store contract as Graph/DAV). |
| Stable ids | Pass | `PimIds.stableLocalId(accountId, providerId)` for lists, contacts, calendars, events, emails, phones, attendees. |
| 410 / expired sync token | Pass | Provider throws `ProtocolException(statusCode: 410)` on stale Calendar syncToken (SyncEngine Graph-style clear+rebootstrap path applies via shared handlers). |
| Secret / fixture hygiene | Pass | Tests use `MockClient` fixtures only; no live tokens or PII in tree. |

---

## Risks and accepted residuals

| Gap | Severity | Disposition |
| --- | --- | --- |
| README / QUICK_START Google OAuth section still lists mail-only consent scopes | Low | **Resolved (Page 2026-07-27):** README + QUICK_START now document People + Calendar scopes and Wave G re-consent (mirrors Graph re-consent paragraph). |
| Google Calendar events never persist a Calendar `syncToken` cursor | Info — accepted MVP | Windowed `singleEvents` pulls return `deltaLink: null` (API incompatibility documented on provider). Every events pull is a horizon full snapshot + missing soft-delete. Provider-level syncToken/cancelled tests remain for future incremental enablement. |
| Contact-group member pull capped (`maxMembers: 1000`, batchGet slices) | Low | Large custom groups may truncate until a follow-up paging wave. My Contacts connections path paginates with syncToken. |
| `addGoogleImapAccount` unit test does not assert PIM job type names | Low | Code enqueues PIM bootstrap; `updateGoogleCredentials` test asserts the three job types; engine tests cover job handlers. Optional tighten later. |
| Google Calendar 403 insufficient scopes after re-auth | Pri-2 | **DEF-061 revised fix (2026-07-27):** Root cause is stale pre-Wave-G **refresh token** minting mail-only ATs (Account UI can show Calendar while Synesis still holds old RT). Exact scope match + tokeninfo + require/replace RT + refresh scope guard. Dogfood needs **full restart** + preferably revoke Synesis in Google Account. |
| Workspace dogfood not executed in this gate | Info | Operator script in checklist; does not block code GO (parity with Wave 4/5). |
| Google write-back / RSVP out of scope | Accepted MVP | `respondToEvent` throws `UnsupportedError`; `events_push`/`contacts_push` remain no-ops. |

---

## Explicitly out of scope (confirmed)

- Cross-account DnD copy (**Wave 6**)
- Google Calendar/People write-back / push handlers
- Google CardDAV/CalDAV fallback (would double-sync; binding matrix forbids)
- Meeting-mail RSVP over Google Calendar API (Graph path remains Wave 3)
- Wave 7 polish bucket

---

## Inventory delta (for Page)

| Path | Cases (names / theme) | Kind | Maps to | Change |
| --- | --- | --- | --- | --- |
| `test/google_pim_provider_test.dart` | `listContactFolders maps My Contacts to stable ContactList ids`; `listCalendars parses backgroundColor and primary flag`; `syncContacts maps connections and returns syncToken`; `syncEvents uses 90d/365d window query params`; `syncEvents with syncToken maps cancelled and throws on 410`; `syncEvents syncToken path returns cancelled as removed` | unit | Wave G provider | **New** (6) |
| `test/google_pim_sync_engine_test.dart` | `Google contact_lists_bootstrap upserts lists and enqueues contacts jobs`; `Google calendars_bootstrap enqueues events; soft-deletes missing on window` | unit/integration | Wave G SyncEngine | **New** (2) |
| `test/provider_registry_google_test.dart` | `resolvePim returns GooglePimProvider for google: refs`; `resolvePim returns GooglePimProvider for xoauth2 auth mode` (+ existing mail resolve / gmail recovery) | unit | Wave G registry W4-3 hold | **+2** |
| `test/account_service_test.dart` | `AccountService.updateGoogleCredentials` → `saves token and enqueues mail + PIM bootstrap` | unit | Wave G re-consent | **+1** |
| `test/oauth_identity_manager_test.dart` | `exposes Gmail XOAUTH2 redirect and scopes` now asserts `contacts.readonly` + `calendar` | unit | Wave G OAuth | **Changed** (0 new cases) |

**Approx case count added:** **+11** Wave G-authored cases; suite total **597** (**+12** vs Wave 5’s 585 — one net case may predate this wave’s file set or come from non-Wave-G churn on the branch).

Existing regression coverage relied on for this gate:

| Path | Theme | Maps to |
| --- | --- | --- |
| `test/graph_pim_provider_test.dart` / `graph_pim_sync_engine_test.dart` | Graph PIM unchanged | Graph regression |
| `test/dav_pim_sync_engine_test.dart` / `dav_protocol_test.dart` | DAV full-pull/soft-delete unchanged | DAV regression |
| `test/pim_sync_jobs_noop_test.dart` | push/copy remain no-op | Wave G write boundary |
| Wave 5 UI/store suites (`pim_store_test`, `calendar_cubit_test`, `contact_picker_test`, `module_shell_test`) | Local-first consumers | UI consumption without chrome change |

Patch or regenerate `docs/V1_AUTOMATED_TEST_INVENTORY.csv` via `tool/generate_test_inventory.py` when convenient.

**Page update (2026-07-27):** Inventory regenerated; Wave G cases tagged `V2-WG` where applicable.

---

## Handoff to Wave 6

- **Wave 6:** **GO.** Cross-account/cross-list DnD copy can proceed on the shared local `DriftPimStore` surface (Graph + DAV + Google rows).
- **Page:** Inventory refresh from this delta ✅; README/QUICK_START Google consent scopes + re-auth note ✅; checklist status finalized (operator dogfood remains post-land).
- **Operators:** Existing Google XOAUTH accounts must **Edit account → Re-authenticate with Google** after Wave G so tokens include People + Calendar scopes; enable APIs on the Google Cloud project.
- **Polish (non-blocking):** Persist Calendar incremental sync when a non-`singleEvents` strategy is product-approved; page large contact groups beyond 1000 members; optional missing-scope CTA.

*Renee — Quality Engineering · 2026-07-27*
