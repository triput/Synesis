# CardDAV Discovery Spike — Wave 2 (Parallel)

| Field | Value |
| --- | --- |
| Status | **Spike doc** — discovery design only; no adapter code |
| Wave | **2** (parallel with Tesla Graph PIM); feeds **Wave 4 / P3** |
| Owner | Jules (implementation) · Page (this doc) |
| Dogfood host | **Runbox** — [`https://dav.runbox.com/`](https://dav.runbox.com/) |
| Parent plan | [V2_PLAN.md](V2_PLAN.md) §6 (parallelism), §2 (IMAP/Runbox binding) |
| Last updated | 2026-07-27 |

## 1. Purpose

Wave 1 (P0) landed multi-contact-list schema, sync job type hooks, and no-op handlers. Wave 4 (P3) needs a **CardDAV contacts adapter** that is not Graph-shaped. This spike documents **how Synesis discovers CardDAV base URLs and address books** before any sync or CRUD code ships.

**In scope:** URL discovery algorithm, Runbox dogfood specifics, integration seams, manual verification steps, P3 exit criteria for discovery.

**Out of scope:** vCard parse/sync, PROPPATCH/PUT contact writes, CalDAV (separate P4 spike), UI, background isolate wiring, automated tests (land with P3 adapter).

## 2. Why discovery first

[V2_PLAN.md](V2_PLAN.md) locks provider order **A**: Graph PIM first (Wave 2), CardDAV adapter later (Wave 4). Tesla can dogfood on existing OAuth tokens while Jules proves the **provider registry is not Graph-only** by nailing discovery against Runbox.

Synesis already has a precedent for “find the server before you talk to it”:

| Mail (landed) | PIM (this spike) |
| --- | --- |
| [ImapAutoconfig](../lib/account/imap_autoconfig.dart) — ISPDB + `/.well-known/autoconfig/mail/` | CardDAV — RFC 6764 `/.well-known/carddav` + PROPFIND bootstrap |
| Thunderbird XML → IMAP/SMTP host/port | PROPFIND chain → principal → address-book home → collections |
| Domain derived from email | Same email → principal; Runbox also accepts known base URL |

Hardcoding address-book URLs (e.g. `/addressbooks/123456/`) is fragile. Clients must discover collections and treat server paths as opaque.

## 3. Standards reference

| RFC | Role |
| --- | --- |
| [RFC 6764](https://www.rfc-editor.org/rfc/rfc6764.html) | Service location — `.well-known/carddav`, DNS SRV (`_carddav._tcp` / `_carddavs._tcp`) |
| [RFC 6352](https://www.rfc-editor.org/rfc/rfc6352.html) | CardDAV — address books, `addressbook-query`, vCard resources |
| [RFC 4918](https://www.rfc-editor.org/rfc/rfc4918.html) | WebDAV — PROPFIND, Depth, multistatus |
| [RFC 5397](https://www.rfc-editor.org/rfc/rfc5397.html) | `DAV:current-user-principal` |

CardDAV and CalDAV share the same **bootstrap shape** (RFC 6764 §6). CalDAV uses `/.well-known/caldav` and `calendar-home-set`; this doc focuses on CardDAV only. Reuse the same discovery helper with a `DavService.carddav | caldav` switch for P4.

## 4. Discovery algorithm (proposed)

Synesis should implement a small **`CardDavDiscovery`** (or generic **`DavDiscovery`**) class in a background isolate, mirroring the timeout and candidate-URL pattern of `ImapAutoconfig`.

### 4.1 Input

| Input | Notes |
| --- | --- |
| `emailAddress` | Full address (e.g. `user@runbox.com`) — username for Basic auth |
| `password` | Account password or **app password** when 2FA is on |
| `knownBaseUrl` (optional) | Operator override; Runbox dogfood default below |

### 4.2 Candidate base URLs (ordered)

Try each until a successful bootstrap PROPFIND returns `current-user-principal` or `addressbook-home-set`:

1. **Provider hint** — if mail account domain is `runbox.com` (or IMAP host is `mail.runbox.com`), prepend `https://dav.runbox.com/` per [V2_PLAN.md](V2_PLAN.md).
2. **RFC 6764 well-known** — `https://{domain}/.well-known/carddav` (follow 301/303/307; do not permanently cache redirect target — revalidate every 2–4 weeks per Google’s CardDAV guidance).
3. **RFC 6764 root fallback** — `https://{domain}/` when well-known returns 404.
4. **DNS SRV** (optional, later) — `_carddavs._tcp.{domain}` then `_carddav._tcp.{domain}`; TLS + cert check per RFC 6764 §6. Deferred unless well-known fails on a target provider.

For Runbox, step 1 alone is expected to succeed; steps 2–3 prove generic IMAP/Other accounts.

### 4.3 PROPFIND bootstrap chain

After choosing a **context path** (post-redirect URL):

```text
PROPFIND {contextPath}
  Depth: 0
  Body: request DAV:current-user-principal (+ DAV:principal-URL if needed)

→ principalUrl

PROPFIND {principalUrl}
  Depth: 0
  Body: request CARDDAV:addressbook-home-set

→ addressBookHomeSet (href)

PROPFIND {addressBookHomeSet}
  Depth: 1
  Body: request DAV:resourcetype, DAV:displayname, CARDDAV:addressbook-description

→ list of address book collection hrefs + display names
```

**Auth:** HTTP Basic on every request (`emailAddress` + password). Runbox requires app passwords when 2FA is enabled ([Runbox community](https://community.runbox.com/t/thunderbird-caldav-carddav-configuration-issues/2546)).

**Redirects:** Follow redirects on PROPFIND; some servers redirect well-known to the real context path.

**404 on context path:** Retry PROPFIND on `/` (RFC 6764).

### 4.4 Output (discovery result)

Map to local **`contact_lists`** rows (Wave 1 schema) without syncing vCards yet:

| Discovery field | Local mapping |
| --- | --- |
| `collectionHref` (absolute URL) | Stable remote id → `contact_lists.providerCollectionId` (or equivalent column added in P3) |
| `displayName` | `contact_lists.displayName` |
| `addressBookHomeSet` | Stored on account PIM config for re-discovery |
| `principalUrl` | Diagnostic / re-bootstrap only |
| `contextPath` | Cached with TTL (2–4 weeks), not permanent |

Each discovered address book becomes one **`contact_lists`** row per account, with `isSelectedForDisplay` defaulting true for the first book (product default TBD in P3).

Sync cursors ([`PimSyncJobs`](../lib/sync/pim_sync_jobs.dart)) remain unused until P3 incremental sync:

- `pim:contact_list:{contactListId}` — list metadata / sync-token
- `pim:contacts:{contactListId}` — contact etag / CTag per collection

## 5. Runbox dogfood specifics

Locked in [V2_PLAN.md](V2_PLAN.md) decision **#11**:

| Setting | Value |
| --- | --- |
| Base URL | **`https://dav.runbox.com/`** (include trailing slash) |
| Username | Full Runbox email address |
| Password | Account password, or **app password** if 2FA enabled |
| Contacts product | **Runbox 7** — legacy Runbox 6 webmail contacts do not sync |
| Groups | Categories on contacts (`CATEGORIES` in vCard), not separate CardDAV groups |

**Known client behavior (third-party):**

- [DAVx⁵ tested-with](https://www.davx5.com/tested-with/runbox) — base URL `https://dav.runbox.com/`, app passwords recommended.
- [Runbox CalDAV help](https://help.runbox.com/using-a-calendar-client-with-caldav/) — same host for CalDAV; Thunderbird “Find Calendars” after entering `dav.runbox.com`.
- Community reports show address books under paths like `https://dav.runbox.com/addressbooks/{id}` after discovery ([GNOME Online Accounts thread](https://community.runbox.com/t/does-runbox-work-with-caldav-carddav-in-gnome-online-accounts/2382)) — **do not hardcode**; always PROPFIND the home set.
- Thunderbird Account Hub autodiscovery for Runbox CardDAV/CalDAV has been reported flaky with 2FA; manual base URL + app password works.

**Synesis implication:** When adding a Runbox IMAP account, PIM binding should auto-suggest `https://dav.runbox.com/` (same credential ref as IMAP). Discovery still runs the PROPFIND chain to enumerate books.

## 6. Integration seams (no code in this spike)

| Component | P3 touchpoint |
| --- | --- |
| [`ProviderRegistry`](../lib/sync/provider_registry.dart) | Extend or sibling **`PimProviderRegistry`** — resolve `CardDavContactsProvider` for `imap` accounts with CardDAV enabled |
| [`PimSyncJobs`](../lib/sync/pim_sync_jobs.dart) | Wire `contact_lists_bootstrap` / `contacts_bootstrap` to adapter after discovery |
| [`SyncEngine`](../lib/sync/sync_engine.dart) | Replace no-op handlers for PIM job types |
| Credentials | Reuse `SecureCredentialStore` + same `credentialsRef` as IMAP; optional `carddav.baseUrl` override secret |
| Isolate | Discovery + PROPFIND in sync isolate (same pattern as MIME/network heavy work) |

Graph accounts use Graph People API in Wave 2 — **no CardDAV discovery**. Google accounts prefer People API with CardDAV fallback ([V2_PLAN.md](V2_PLAN.md) §2); discovery path applies only to that fallback.

## 7. Manual verification (operator)

Use a Runbox 7 account with app password. Replace placeholders before running.

**7.1 Well-known probe (generic domain)**

```bash
curl -sS -o /dev/null -w "%{http_code} %{redirect_url}\n" \
  -X PROPFIND "https://dav.runbox.com/.well-known/carddav" \
  -u "USER@runbox.com:APP_PASSWORD" \
  -H "Depth: 0" \
  -H "Content-Type: application/xml; charset=utf-8" \
  --data '<?xml version="1.0"?><d:propfind xmlns:d="DAV:"><d:prop><d:current-user-principal/></d:prop></d:propfind>'
```

Expect redirect or 207 multistatus with principal href.

**7.2 Bootstrap on known Runbox base**

```bash
curl -sS -X PROPFIND "https://dav.runbox.com/" \
  -u "USER@runbox.com:APP_PASSWORD" \
  -H "Depth: 0" \
  -H "Content-Type: application/xml; charset=utf-8" \
  --data '<?xml version="1.0"?><d:propfind xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav"><d:prop><d:current-user-principal/></d:prop></d:propfind>'
```

**7.3 Address book home set** — PROPFIND the principal URL from step 7.2:

```bash
# Replace PRINCIPAL_URL from multistatus response
curl -sS -X PROPFIND "PRINCIPAL_URL" \
  -u "USER@runbox.com:APP_PASSWORD" \
  -H "Depth: 0" \
  -H "Content-Type: application/xml; charset=utf-8" \
  --data '<?xml version="1.0"?><d:propfind xmlns:d="DAV:" xmlns:card="urn:ietf:params:xml:ns:carddav"><d:prop><card:addressbook-home-set/></d:prop></d:propfind>'
```

**7.4 List address books** — PROPFIND home set with `Depth: 1`; confirm at least one `resourcetype` contains `addressbook`.

Record observed hrefs and display names in P3 implementation notes. Do not commit credentials or raw multistatus dumps with PII.

## 8. Spike exit criteria (feeds P3)

- [ ] Algorithm above reviewed by Jules / Tesla (no Graph-only assumptions).
- [ ] Manual curl chain succeeds against Runbox dogfood account (app password).
- [ ] Decision: single `DavDiscovery` module shared with CalDAV (P4) vs CardDAV-only class.
- [ ] Decision: where `providerCollectionId` / remote href lives on `contact_lists` (migration if needed).
- [ ] Decision: cache TTL for context path / principal (recommend 14 days, force refresh on 404).
- [ ] **Not required for spike:** unit tests, sync, vCard parse, UI.

## 9. Risks and mitigations

| Risk | Mitigation |
| --- | --- |
| 2FA blocks primary password | Document app passwords; store same secret as IMAP when user generates app password for “Synesis”. |
| Thunderbird-style autodiscovery fails | Always offer manual base URL; Runbox hint from domain. |
| Multiple address books | Wave 1 schema already multi-list; discovery enumerates all, user selects display in P5/P6. |
| Redirect caching stale | TTL + re-run discovery on auth OK but collection 404. |
| Runbox 6 vs 7 contacts | UI copy: migrate contacts in Runbox 7 before expecting sync. |

## 10. Related docs

| Doc | Role |
| --- | --- |
| [V2_PLAN.md](V2_PLAN.md) | Locked Runbox URL, parallelism, P3 owner |
| [V2_0A_P0_CHECKLIST.md](V2_0A_P0_CHECKLIST.md) | Schema + job hooks discovery builds on |
| [V2_0A_P0_QA.md](V2_0A_P0_QA.md) | Wave 2 handoff — Jules spike may run parallel |
| [lib/account/imap_autoconfig.dart](../lib/account/imap_autoconfig.dart) | Pattern reference for candidate URL ordering |

---

*Discovery spike doc only — adapter implementation is Wave 4 / P3.*
