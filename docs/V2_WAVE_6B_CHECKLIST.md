# Wave 6b — CalDAV/CardDAV Write (Copy Targets) Checklist

> **Status:** **In progress** (2026-08-04) — E7 Renee **GO** (**668 tests**); E8 Runbox dogfood + Page inventory open. Parent: [V2_PLAN.md](V2_PLAN.md). Prior: [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md) (**complete**, **659 tests**). Design: [V2_WAVE_6B_TESLA_DESIGN.md](V2_WAVE_6B_TESLA_DESIGN.md). QA: [V2_WAVE_6B_QA.md](V2_WAVE_6B_QA.md).

Wave 6b makes **DAV accounts real copy targets**: when the user copies an event/contact onto a CalDAV calendar or CardDAV list, Synesis still duplicates locally first, then **PUT**s create and rewrites `providerId`/etag — same job types (`events_copy` / `contacts_copy`) as Graph/Google.

**Owners:** Tesla (protocol + SyncEngine) · Jules/Andi (drop “Local only” UX when DAV push supported) · Renee (QA) · Page (docs).

## Sequence

```text
Wave 6 ✅ → ★ Wave 6b: CalDAV/CardDAV create write ← active
         → Wave 6c: calendar series copy
         → Wave 7: Trish extras
```

## Locked decisions

| # | Decision |
| --- | --- |
| W6b-1 | **Create-only** for copy targets — not full local CRUD push (`events_push` / `contacts_push` stay out unless trivial) |
| W6b-2 | Reuse Wave 6 job payloads + `PimCopyService`; **enqueue for DAV** (Wave 6 skipped enqueue) |
| W6b-3 | Dogfood against **Runbox** CardDAV/CalDAV |
| W6b-4 | Soft-delete / full-pull must continue to **skip** unpushed `local:*` until rewrite |
| W6b-5 | **Out:** free/busy, ACLs, PROPPATCH polish, update/delete push (may trail), Wave 6c series |

## Slices

| Slice | Goal | Owner | Gate |
| --- | --- | --- | --- |
| **P0** | Tesla design note — PUT path, UID/filename, ICS/vCard minimal serializers, error map | Tesla | D1–D3 |
| **P1** | `DavClient` PUT (+ If-None-Match); `DavPimProvider.createEvent` / `createContact` | Tesla | E1–E3 |
| **P2** | SyncEngine + `PimCopyService` enqueue DAV; rewrite providerId/etag | Tesla | E4–E5 |
| **P3** | UI honesty — remove DAV “Local only” when push supported; snackbars | Jules / Andi | E6 |
| **P4** | Renee QA + Page inventory + Trish Runbox dogfood | Renee + Page | E7–E8 |

## Work breakdown

| ID | Task | Exit |
| --- | --- | --- |
| **D1** | Design: collection href + `{uuid}.ics` / `.vcf` naming; UID generation; Location/ETag capture | **Done** — [V2_WAVE_6B_TESLA_DESIGN.md](V2_WAVE_6B_TESLA_DESIGN.md) § D1 (`Uri.resolve`, `local:{uuid}` stem, `If-None-Match: *`, ETag/Location → `PimRemoteCreateResult`) |
| **D2** | Minimal VEVENT / vCard writers (fields Wave 6 already copies) | **Done** — design § D2 (`IcsCalendarWriter` / `VCardWriter`; no ATTENDEE/RRULE) |
| **D3** | Failure modes — 412, 403, auth; map to job failed | **Done** — design § D3 (`ProtocolException` → job failed; soft-delete / idempotent no-ops retained) |
| **E1** | `DavClient.put` (and headers) | **Done** — `DavClient.put` + `If-None-Match: *`; tests in `test/dav_pim_create_test.dart` |
| **E2** | CalDAV createEvent PUT | **Done** — `DavPimProvider.createEvent` + `IcsCalendarWriter` |
| **E3** | CardDAV createContact PUT | **Done** — `DavPimProvider.createContact` + `VCardWriter` |
| **E4** | SyncEngine copy handlers call DAV create; rewrite id | **Done** — DAV early-return removed; rewrite via `PimRemoteCreateResult` |
| **E5** | `PimCopyService.remotePushSupportedForAccount` true for DAV; enqueue | **Done** — enqueue for any resolved PIM provider |
| **E6** | UI: sheet/snackbar no longer claim local-only for DAV | **Done** (minimal) — flip helper + snackbar fallback copy; sheet uses same flag |
| **E7** | Renee **GO** + inventory | **Done** — engineering **GO** (**668/668**); QA [V2_WAVE_6B_QA.md](V2_WAVE_6B_QA.md); Page inventory handoff open |
| **E8** | Trish Runbox dogfood **GO** | Open — matrix in QA |

## Exit criteria

- [ ] Copy event → Runbox CalDAV calendar: local immediate + remote appears after sync job *(E8)*
- [ ] Copy contact → Runbox CardDAV list: same *(E8)*
- [ ] Graph/Google → DAV and DAV → Graph/Google paths work (DAV side write) *(auto Pass; E8 live)*
- [x] Unpushed `local:*` not wiped by full-pull soft-delete *(E7 auto)*
- [x] Renee **GO** *(E7)* — Page inventory pending
- [ ] Trish operator **GO** on Runbox *(E8)*

## Explicitly out

| Item | Disposition |
| --- | --- |
| Update/delete remote push for local CRUD | Trail / later |
| Calendar series copy | **Wave 6c** |
| Free/busy, ACLs, sync-collection REPORT | Later |

---

*Opened 2026-08-04 after Wave 6 close (`6b1fcaf`).*
