# Wave G — Google PIM Checklist (People + Calendar API)

> **Status:** **Complete** (2026-07-27, `f4c21b0`, **597 tests**) — Renee [V2_WAVE_G_QA.md](V2_WAVE_G_QA.md) **GO**; inventory + README Google scopes landed (Page). Parent plan: [V2_PLAN.md](V2_PLAN.md). Prior: [V2_WAVE5_QA.md](V2_WAVE5_QA.md) **GO**. **Next:** Wave 6 (cross-account DnD copy).

Wave G delivers **Google People + Calendar API** sync for **Google XOAUTH IMAP** accounts into the existing provider-agnostic `DriftPimStore`. Per [V2_PLAN.md §2](V2_PLAN.md#2-account--pim-binding) and Wave 4 W4-3, Google accounts **do not** use CardDAV/CalDAV — API-only binding. Operator dogfood target: **Google Workspace** (Trish principal calendar).

**Scheduling note:** Wave G exit cleared 2026-07-27. Any in-flight Calendar/People **visibility polish** (empty-state / display-pref UX) may continue in parallel — it does **not** block Wave 6.

## Sequence

```text
Wave 0 ✅ → Wave H ✅ → Wave 1 (P0) ✅
                         → Wave 2: Graph PIM (P1) ✅
                         → Wave 3: meeting-mail bridge (P2) ✅
                         → Wave 4: CardDAV/CalDAV (P3–P4) ✅
                         → Wave 5: picker + Calendar UI (P5–P6) ✅
                         → Wave G: Google People + Calendar API ✅
                         → ★ Wave 6: cross-account DnD copy ← next
                         → Wave 7: Trish extras (last)
```

## Scope (locked for kickoff)

| Item | Scope | Notes |
| --- | --- | --- |
| **OAuth scopes** | Extend `GoogleAuthConfig.scopes` | Add People + Calendar API scopes (read for bootstrap; calendar write if local CRUD push is in scope — mirror Graph `Calendars.ReadWrite` posture). **Re-consent:** existing Google accounts → Edit account → re-auth |
| **`GooglePimProvider`** | People API + Calendar API → `DriftPimStore` | Contact lists / contacts / calendars / events; stable provider identity; 90d/365d event window (parity with Graph/DAV); display prefs preserved on upsert |
| **Provider registry** | Route `google:` / `xoauth2` IMAP refs to `GooglePimProvider` | **No DAV** for Google XOAUTH (Wave 4 W4-3 exclusion holds). Graph and password-auth IMAP+DAV unchanged |
| **SyncEngine** | Bootstrap + incremental job handlers | Per-list / per-calendar cursor keys; account-add enqueue; mail sync regression guard |
| **Tests** | Unit + fake HTTP fixtures | Provider resolution, stable id mapping, re-sync dedupe, registry regression (`provider_registry_google_test.dart` extended) |
| **Dogfood** | Google Workspace account | Contacts + calendars visible in People/Calendar modules; compose picker FTS includes Google-sourced contacts |

## Out of Wave G MVP

- Cross-account DnD copy (**Wave 6**)
- Google Calendar/People **write-back** on local CRUD (`events_push` / `contacts_push` — may remain no-op like Wave 5 unless explicitly scoped)
- Google CardDAV/CalDAV fallback (binding matrix prefers API; avoid double-sync)
- Meeting-mail RSVP over Google Calendar API (stretch; Graph path already landed Wave 3)
- Wave 7 polish bucket

## Wave G exit criteria (gate)

- [x] Google XOAUTH account: contact lists + contacts sync into local schema
- [x] Google XOAUTH account: calendars + events sync (90d past / 365d future)
- [x] Provider registry: Google resolves `GooglePimProvider`; no DAV PIM for `google:` refs
- [x] Re-consent path documented; scope expansion tested on existing account *(README + QUICK_START Google scopes + Edit account → re-auth — Page 2026-07-27)*
- [x] People + Calendar UI + compose picker consume Google-sourced local rows
- [x] Graph PIM, DAV PIM, and mail unaffected; full suite green *(597/597)*
- [x] Renee QA **GO**; inventory refresh *(Page 2026-07-27)*; docs + plan/roadmap updated
- [x] Workspace dogfood *(Trish GO 2026-07-27 — requires Calendar + People APIs enabled on OAuth client GCP project; see DEF-061)*

## Team routing

| Role | Wave G work |
| --- | --- |
| Steve | Orchestrate; lock scope; exit gate; commit |
| Tesla | `GooglePimProvider`, OAuth scopes, SyncEngine/registry/AccountService |
| Jules | Re-auth UX copy; any AccountService/UI glue |
| Renee | QA — fixtures, regression, GO/NO-GO |
| Page | Checklist / plan / roadmap / dogfood notes / headers |

## Workspace dogfood (operator — post-land)

**Status:** **GO** (Trish, 2026-07-27). **Prerequisite:** enable **Google Calendar API** + **People API** on the GCP project that owns the Synesis OAuth client — dogfood fails with scope-flavored 403s if either API is disabled or stale (DEF-061).

1. Google Cloud → **APIs & Services → Library** — enable **Google Calendar API** (`calendar-json.googleapis.com`) and **People API** (`people.googleapis.com`) on the OAuth client project.
2. Google Cloud → OAuth consent screen: add People + Calendar scopes to the existing Synesis client.
3. Add or re-auth Google Workspace account (Edit account → re-auth after scope expansion).
4. Trigger sync; confirm `contact_lists`, `calendars`, contacts, and events in People + Calendar modules.
5. Verify compose picker finds Google-sourced contacts via FTS.
6. Re-sync without duplicate collections or records. Log issues without credentials or raw PII.
