# Wave 4 — V2.0b Checklist (CardDAV / CalDAV)

> **Status:** **Complete** (2026-07-27, `f2bd29b`) — CardDAV/CalDAV adapter and account DAV configuration landed. Renee QA **GO** — [V2_WAVE4_QA.md](V2_WAVE4_QA.md). Parent plan: [V2_PLAN.md](V2_PLAN.md). Spike: [CARDDAV_DISCOVERY_SPIKE.md](CARDDAV_DISCOVERY_SPIKE.md). **Next:** Wave 5 (picker + Calendar UI).

Wave 4 delivers **P3–P4**: CardDAV address-book sync + CalDAV calendar sync into the Wave 1 local PIM schema for IMAP/Other accounts (Runbox dogfood). Graph accounts remain on `GraphPimProvider`. No Calendar/People chrome (Wave 5), no DnD copy (Wave 6), no push/PROPPATCH writes.

## Sequence

```text
Wave 0 ✅ → Wave H ✅ → Wave 1 (P0) ✅
                         → Wave 2: Graph PIM (P1) ✅
                         → Wave 3: meeting-mail bridge (P2) ✅
                         → Wave 4: CardDAV/CalDAV (P3–P4) ✅
                         → ★ Wave 5: picker + Calendar UI (P5–P6) ← next
                         → Wave 6: cross-account DnD copy
```

## Locked product decisions (Wave 4 — 2026-07-27)

| # | Decision |
| --- | --- |
| W4-1 | **Shared `DavDiscovery`** module with `DavService.carddav \| caldav` (spike §8) — not separate one-off classes |
| W4-2 | **Auth:** HTTP Basic; username = full email; password = IMAP password / app password (same `credentialsRef` as IMAP) |
| W4-3 | **Which accounts:** `providerType == imap` with Basic auth (password), **not** Graph, **not** Google XOAUTH for Wave 4. Graph stays Graph PIM only |
| W4-4 | **Enablement:** DAV sync when `dav.baseUrl` (or carddav/caldav override) is set **or** Runbox domain/host auto-hints `https://dav.runbox.com/` |
| W4-5 | **Base URL storage:** secure secrets `dav.baseUrl` (shared default); optional `carddav.baseUrl` / `caldav.baseUrl` overrides. Trailing slash normalized |
| W4-6 | **Identity:** collection/resource `providerId` = absolute href (stable). Local ids via `PimIds.stableLocalId` |
| W4-7 | **CalDAV window:** past **90d** / future **365d** (same spirit as Graph horizons) |
| W4-8 | **Cursors:** prefer sync-token / ctag in `sync_cursors`; fall back to full collection REPORT/PROPFIND on miss |
| W4-9 | **MVP = read sync only** — no CardDAV PUT / CalDAV write / push jobs |
| W4-10 | **Display prefs:** preserve `isSelectedForDisplay` / sort / color overrides on upsert (Wave 2 Renee constraint) |
| W4-11 | **First address book / calendar:** `isSelectedForDisplay` default true for first discovered collection per account; others true unless product later narrows |

## Discovery & protocol

- [x] `DavDiscovery` — candidate base URLs (Runbox hint → well-known → root); PROPFIND principal → home-set → Depth:1 collections
- [x] CardDAV: enumerate address books; Depth:1 resource discovery + vCard GET
- [x] CalDAV: enumerate calendars; calendar-query for event window
- [x] HTTP Basic on every request; follow redirects on well-known
- [x] Isolate-safe: network and parsing execute through the sync path, outside declarative UI reads

## Sync deliverables

### Contact lists & contacts (P3)

- [x] `contact_lists_bootstrap` / incremental — CardDAV books → `contact_lists`
- [x] `contacts_bootstrap` / incremental — vCards → `contacts` + emails/phones + FTS triggers
- [x] Per-list cursor keys: `pim:contact_list:{id}`, `pim:contacts:{listId}`
- [x] Minimal vCard parse (FN, N, EMAIL, TEL, UID/href, REV/etag) — no CATEGORIES groups as separate lists

### Calendars & events (P4)

- [x] `calendars_bootstrap` / incremental — CalDAV calendars → `calendars`
- [x] `events_bootstrap` / incremental — VEVENT → `events` + attendees where present
- [x] Reuse `IcsCalendarParser` for VEVENT bodies
- [x] Event window past 90d / future 365d
- [x] Per-calendar cursor keys: `pim:calendar:{id}`, `pim:events:{calId}`

### Engine & registry

- [x] `ProviderRegistry.resolveDavPim` (or equivalent) for IMAP+DAV-enabled accounts
- [x] SyncEngine: enqueue PIM bootstrap for DAV-capable IMAP accounts; branch handlers Graph vs DAV without regressing Graph
- [x] AccountService: persist `dav.baseUrl` on add/edit; enqueue DAV PIM bootstrap when enabled
- [x] Reserved push/copy jobs remain no-op

## Account UI (minimal)

- [x] Add / Edit IMAP: optional CardDAV/CalDAV base URL field (prefill Runbox hint when domain matches)
- [x] Persist via secure credential store; no Calendar/People chrome

## Verification

- [x] Unit tests: discovery XML fixtures (multistatus), vCard parse, CalDAV REPORT fixtures — **no live Runbox secrets**
- [x] Sync engine / store integration with fake HTTP client
- [x] Display-pref preserve + stable-id re-sync tests
- [x] `flutter analyze` — 0 errors on touched code
- [x] Full `flutter test` green — **556 tests**
- [x] Graph PIM + mail regression unchanged

## Docs

- [x] This checklist exit marked complete
- [x] [V2_PLAN.md](V2_PLAN.md) / [ROADMAP.md](ROADMAP.md) — Wave 4 complete; Wave 5 next
- [x] [V2_WAVE4_QA.md](V2_WAVE4_QA.md) — Renee **GO**
- [x] Runbox dogfood notes (operator)
- [x] Gold Master headers on new core Dart files (Created/Last Update: 2026-07-27)
- [x] Automated-test inventory regeneration — `tool/generate_test_inventory.py` (556 cases)

## Out of Wave 4 MVP

- Calendar module UI / People UI / compose picker (Wave 5)
- Cross-account DnD copy (Wave 6)
- CardDAV/CalDAV write (PUT/PROPPATCH), free/busy, shared ACLs
- Google People API / Google CardDAV fallback
- Graph dual-bind optional CardDAV book
- DNS SRV discovery (deferred unless well-known fails on a target)

## Wave 4 exit criteria (gate)

- [x] CardDAV sync into local schema for IMAP+DAV accounts (Runbox-shaped)
- [x] CalDAV sync into local schema with 90d/365d window
- [x] Graph PIM + mail unaffected
- [x] Display prefs + stable provider identity preserved
- [x] Tests + analyze + full suite green; no live secrets in repo
- [x] Docs + Renee QA GO; inventory refresh; Wave 5 unblocked

## Team routing

| Role | Wave 4 work |
| --- | --- |
| Steve | Orchestrate; lock decisions; exit gate; commit |
| Tesla | DavDiscovery, CardDAV/CalDAV providers, SyncEngine/registry/AccountService |
| Jules | Minimal Add/Edit DAV URL fields + Runbox hint |
| Andi | UI glue assist if Jules needs it |
| Renee | QA — fixtures, regression, GO/NO-GO |
| Page | Checklist / plan / roadmap / dogfood notes / headers |

## Runbox dogfood (operator — post-land)

1. Runbox 7 account; create **app password** if 2FA enabled.
2. Add IMAP account (mail.runbox.com) with app password **or** Edit existing IMAP → set DAV base `https://dav.runbox.com/`.
3. Trigger sync; confirm `contact_lists`, `calendars`, contacts, and events appear in the local DB. There is no Calendar/People chrome until Wave 5; inspect through diagnostics, tests, or the local DB.
4. Contacts must live in **Runbox 7** (legacy Runbox 6 webmail contacts do not sync). Add a dated calendar event inside the 90-day past / 365-day future window.
5. Verify the same account re-syncs without duplicate collections or records. Record any auth, redirect, or collection-href issue without credentials or raw PII-bearing DAV responses.

## Residuals carried forward

- **Full-pull reconciliation (accepted MVP):** DAV always re-pulls the collection and soft-deletes local contacts/events missing from the remote set. Sync-token/CTag values may be stored but are not used to skip pulls; `sync-collection` REPORT incremental is deferred.
- **Clear DAV URL:** Edit account does not clear a previously saved `dav.baseUrl` when the field is blanked — explicit clear semantics are a polish follow-up.
- **DAV error body sanitization:** Non-2xx responses may include server bodies in SyncEngine job errors; truncate/sanitize in a hardening follow-up.
