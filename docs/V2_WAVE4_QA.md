# Wave 4 / V2.0b P3–P4 — Renee QA notes

| Field | Value |
| --- | --- |
| Reviewed | 2026-07-27 |
| Checklist | [V2_WAVE4_CHECKLIST.md](V2_WAVE4_CHECKLIST.md) |
| Design input | [CARDDAV_DISCOVERY_SPIKE.md](CARDDAV_DISCOVERY_SPIKE.md) |
| Prior gate | [V2_WAVE3_QA.md](V2_WAVE3_QA.md) |
| Tests | **556/556 passed** (`flutter test`, verified by Steve after Tesla + Jules handoff) |
| Verdict | **GO** Wave 4 exit · **GO** Wave 5 handoff |

Wave 4 adds read-only CardDAV and CalDAV synchronization for Basic-auth IMAP
accounts through the existing local `DriftPimStore` boundary. The exit is
approved for the locked MVP: full collection pulls and missing-resource
soft-deletes, with incremental DAV collection sync and writes deferred.

---

## Verdict

| Gate | Decision | Notes |
| --- | --- | --- |
| DAV protocol and account-path review | **Pass** | Shared HTTPS-only discovery, Basic auth per request, Runbox hint, absolute href provider identities, and 90d/365d CalDAV query horizon are implemented. |
| Provider selection / Graph regression | **Pass** | Graph and Microsoft accounts retain `GraphPimProvider`; DAV resolves only for password-auth IMAP accounts. Google refs and `xoauth2` IMAP are explicitly excluded. |
| Local persistence / display preferences | **Pass** | Existing collection rows retain selection, sort, and calendar color overrides; provider hrefs map to deterministic local ids. |
| Full-pull reconciliation | **Pass — accepted MVP** | DAV pulls enumerate current resources and soft-delete locally missing contacts/events. This intentionally replaces incremental sync-token processing for this wave. |
| Secret handling | **Pass with low residual** | Credentials and DAV URLs flow through secure credential storage; no DAV logging or debug printing was found, and tests use fixtures only. See raw server-body residual below. |
| Runbox dogfood | **Operator-pending** | No live Runbox result was supplied or inferred. Validate with a Runbox 7 account and app password after land. |
| Wave 4 exit | **GO** | The supplied full suite result is green and the implementation matches the locked read-only MVP decisions. |
| Wave 5 handoff | **GO** | Picker and Calendar/People UI can consume local PIM data without adding DAV network access to UI code. |

---

## Scope checked

| Area | Result | Evidence |
| --- | --- | --- |
| Shared discovery | Pass | `DavDiscovery` uses one CardDAV/CalDAV switch, ordered configured/Runbox/well-known/root candidates, principal → home-set → Depth:1 collections, and 404 root retry. |
| Transport and credentials | Pass | `DavClient` uses Basic authorization on each request, a 45-second timeout, HTTPS-only configured base URL validation, and client disposal. No secret-bearing log call exists in `lib/protocol/dav/`. |
| Stable identity | Pass | Collection and resource `providerId` values are resolved absolute hrefs; `PimIds.stableLocalId(accountId, href)` gives repeatable local identities across re-sync. |
| CardDAV mapping | Pass | Resource listing + vCard GET maps display name, `N`, `UID`, `REV`, email, phone, ETag, and contact href; malformed/empty cards are ignored rather than crashing the job. |
| CalDAV mapping | Pass | `calendar-query` requests VEVENTs in the locked past-90-day/future-365-day window; events and attendees are persisted locally with href identity and ETag. |
| Preference preservation | Pass | `DriftPimStore` preserves `isSelectedForDisplay` and sort order for lists/calendars, plus calendar color overrides, on metadata refresh. |
| Soft-delete correctness | Pass — MVP | After a successful DAV full pull, only rows absent from the returned provider-id set are soft-deleted. Tests exercise contacts and events disappearing between pulls; normal reads exclude those rows. |
| Graph and mail isolation | Pass | DAV resolution is isolated to Basic-auth IMAP; mail provider resolution and Graph PIM paths remain separate. The supplied 556-test full suite is the regression gate. |
| Google XOAUTH exclusion | Pass | Both `google:` credential refs and `imap.auth=xoauth2` resolve no DAV PIM provider; Google IMAP continues through XOAUTH2 mail handling. |
| Account UI and storage | Pass | Add/Edit account sheets expose an optional shared DAV endpoint, normalize a trailing slash through `AccountService`, and surface the Runbox URL as a hint without embedding credentials. |
| Read-only boundary | Pass | No DAV `PUT`, `PROPPATCH`, push, or copy implementation was found; reserved SyncEngine jobs remain no-ops. |

---

## Risks and accepted residuals

| Risk | Severity | Disposition |
| --- | --- | --- |
| DAV sync-token / CTag values are not used to avoid full pulls | Low | Accepted MVP residual. Cursor values may be stored when exposed, but DAV sync always performs a full collection pull. Defer incremental `sync-collection` / CTag optimization. |
| Removed collections are not independently reconciled | Low | Current reconciliation soft-deletes missing contacts/events within discovered collections; collection removal is not separately tombstoned. Revisit with collection delta support. |
| DAV non-2xx exceptions can include the raw server response body | Low | No credentials are logged by the DAV client, but a server-provided body can be persisted as a job error by the generic SyncEngine failure path. Sanitize/truncate DAV error detail before user-visible or diagnostic persistence in a hardening follow-up. |
| A blank DAV field in Edit does not clear a previously saved endpoint | Low | Edit submits a DAV update only when the changed field is non-empty. This does not affect add/sync behavior, but endpoint removal needs explicit clear semantics before configuration polish. |
| One CalDAV resource can theoretically contain multiple VEVENTs | Low | Event identity is the resource href, as locked for Wave 4. A server returning multiple independently represented VEVENTs in one `.ics` resource could collide locally; revisit UID/RECURRENCE-ID identity if encountered in dogfood. |

---

## Explicitly out of scope (confirmed)

- Calendar module, People module, and compose picker UI (Wave 5)
- Cross-account drag-and-drop copy (Wave 6)
- CardDAV/CalDAV writes (`PUT` / `PROPPATCH`), push, free/busy, ACLs, and iTIP
- Google People API / Google CardDAV fallback and Graph dual-bind
- DNS SRV discovery
- Live Runbox testing or credentials in source control

---

## Inventory delta (for Page)

| Path | Cases / theme | Kind | Maps to |
| --- | --- | --- | --- |
| `test/dav_protocol_test.dart` | Discovery principal/home-set/collection fixtures; Basic auth header; absolute href identities; CardDAV contact pull; CalDAV event pull and 90d/365d query window | unit | Wave 4 W4-1, W4-2, W4-6, W4-7 |
| `test/dav_vcard_parser_test.dart` | vCard FN/N/UID/REV, email and phone mapping | unit | Wave 4 P3 CardDAV mapping |
| `test/dav_pim_sync_engine_test.dart` | DAV bootstrap, stable local persistence, preserved collection preference, and missing contact/event soft-delete | integration | Wave 4 W4-6, W4-8, W4-10 |
| `test/account_service_test.dart` | DAV URL normalization/persistence while retaining IMAP password | unit | Wave 4 W4-4, W4-5 |

Existing regression coverage relied on for this gate:

| Path | Cases / theme | Kind | Maps to |
| --- | --- | --- | --- |
| `test/provider_registry_google_test.dart` | Google IMAP XOAUTH2 provider resolution and host fallbacks | unit | Wave 4 W4-3 regression guard |
| `test/graph_pim_sync_engine_test.dart` | Existing Graph PIM sync behavior | integration | Wave 4 Graph regression guard |

---

## Handoff to Wave 5

- **Wave 5:** **GO.** Build Calendar/People and picker UI as declarative readers of
  local Drift-backed PIM state. Do not put DAV discovery, network calls, or
  credentials into widgets.
- **Dogfood:** Operator-pending. Use Runbox 7 contacts/calendar and an app
  password when 2FA is enabled; verify discovery, local contact/event rows,
  full-pull deletion behavior, and that legacy Runbox 6 contacts are not
  expected to appear.
- **Hardening backlog:** Address DAV error-body sanitization and explicit endpoint
  clearing before broader provider rollout; introduce sync-collection/CTag only
  when the MVP full-pull behavior is measured as insufficient.

*Renee — Quality Engineering · 2026-07-27*
