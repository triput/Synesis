# Wave 6b — Tesla Design (CalDAV/CardDAV Create-Only Copy Write)

> **Status:** Signed 2026-08-04 (Tesla) · Parent: [V2_WAVE_6B_CHECKLIST.md](V2_WAVE_6B_CHECKLIST.md) · Extends [V2_WAVE_6_TESLA_DESIGN.md](V2_WAVE_6_TESLA_DESIGN.md) (do **not** reopen Graph/Google create).

## Goals

Make **DAV accounts real copy targets**: local duplicate (unchanged Wave 6) → enqueue `events_copy` / `contacts_copy` → CalDAV/CardDAV **PUT create** → rewrite `providerId` + `etag` in place. UI never awaits network. **Create-only** — no update/delete push, no `events_push` / `contacts_push`, no Wave 6c series.

Dogfood: **Runbox** CardDAV/CalDAV.

---

## D1 — PUT path, UID / filename, Location / ETag

### Collection href

`targetCalendarProviderId` / `targetContactListProviderId` are already the **collection href** stored from discovery (trailing `/` expected, e.g. `https://dav.runbox.com/calendars/…/`).

### Resource URL

| Kind | Filename | Absolute href |
| --- | --- | --- |
| Event | `{uid}.ics` | `Uri.parse(collectionHref).resolve('{uid}.ics')` |
| Contact | `{uid}.vcf` | `Uri.parse(collectionHref).resolve('{uid}.vcf')` |

### UID generation

1. Prefer the uuid segment from the local row’s `providerId` when it matches `local:{uuid}` (same uuid used at duplicate time).
2. Otherwise generate a fresh UUID v4.
3. **ICS `UID:`** and **vCard `UID:`** both equal that uuid string (no `local:` prefix).
4. Filename stem equals the same uuid → stable identity between object and href for retry heuristics.

### HTTP create

```http
PUT {resourceHref}
Authorization: Basic …
Content-Type: text/calendar; charset=utf-8   # or text/vcard; charset=utf-8
If-None-Match: *
User-Agent: Synesis/2.0

{body}
```

`If-None-Match: *` enforces create-only (RFC 9110 / common CalDAV practice). Collision → **412**.

### Success response → `PimRemoteCreateResult`

| Source | Mapping |
| --- | --- |
| Status | **201** / **204** / **200** accepted as success |
| `ETag` / `etag` response header | `PimRemoteCreateResult.etag` (preserve quoting as returned) |
| `Location` header (absolute or relative) | Prefer as `providerId` when present; else request URI string |
| Body | Ignored (Runbox typically empty on 201/204) |

`providerId` for Drift rewrite is the **absolute resource href** (same identity space as DAV pull, which keys events/contacts by href).

### Retry / idempotency (unchanged Wave 6 D4)

| State | Behavior |
| --- | --- |
| `providerId` starts with `local:` | PUT create → rewrite → done |
| Already remote href | No-op success |
| PUT succeeded, rewrite crashed | Retry may 412 if same filename reused — prefer same uid from `local:{uuid}` so retry hits same URL; 412 then treated as failure (operator retry / investigate). Accepted MVP risk matches Wave 6 POST double-create note. |

Soft-delete guard for `local:*` on full-pull **remains** (Wave 6 mitigation).

---

## D2 — Minimal VEVENT / vCard writers

Only fields Wave 6 already duplicates / posts for Graph/Google. **No** ATTENDEE, **no** RRULE / RECURRENCE-ID (Wave 6c).

### VEVENT (`IcsCalendarWriter`)

Envelope:

```text
BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//Synesis//PIM//EN
CALSCALE:GREGORIAN
BEGIN:VEVENT
…properties…
END:VEVENT
END:VCALENDAR
```

| Drift / Wave 6 field | ICS |
| --- | --- |
| uid (from D1) | `UID` |
| (now UTC) | `DTSTAMP` (UTC `…Z`) |
| `title` | `SUMMARY` |
| `body` | `DESCRIPTION` (omit if empty) |
| `location` | `LOCATION` (omit if empty) |
| `startEpochMs` / `endEpochMs` + `allDay` | `DTSTART` / `DTEND` — all-day `VALUE=DATE:YYYYMMDD`; timed UTC `YYYYMMDDTHHMMSSZ` |
| `reminderMinutes` | Optional `VALARM` with `TRIGGER:-PT{n}M`, `ACTION:DISPLAY` |
| attendees / rrule | **omitted** |

TEXT escaping: `\`, `;`, `,`, newline → `\n`. CRLF line endings. Fold long lines at 75 octets when needed.

### vCard 3.0 (`VCardWriter`)

```text
BEGIN:VCARD
VERSION:3.0
UID:…
FN:…
N:family;given;;;
ORG:…          # company
NOTE:…         # notes
EMAIL;TYPE=…:…
TEL;TYPE=…:…
END:VCARD
```

| Drift / Wave 6 field | vCard |
| --- | --- |
| uid | `UID` |
| `displayName` | `FN` (required; fallback `(No name)`) |
| `familyName` / `givenName` | `N` |
| `company` | `ORG` |
| `notes` | `NOTE` |
| emails | `EMAIL` + `TYPE` (`home` / `work` / `other` → HOME / WORK / omit or INTERNET) |
| phones | `TEL` + `TYPE` (`mobile`/`cell` → CELL; `home` → HOME; `work`/`business` → WORK) |

Same TEXT escaping / CRLF rules as ICS.

---

## D3 — Failure modes → job failed

| Failure | Mapping |
| --- | --- |
| HTTP **412** (If-None-Match) | `ProtocolException(statusCode: 412)` → `_processJobSafely` → job **failed** |
| HTTP **401** / **403** | `ProtocolException` → job **failed** (auth / ACL; no Graph refresh path on DAV Basic) |
| HTTP **404** / **405** / other 4xx/5xx | `ProtocolException(statusCode: …)` → job **failed** |
| Timeout / `ClientException` | Existing `DavClient` → `ProtocolException` → job **failed** / retry policy as today |
| Missing payload / missing local row | Same as Wave 6: soft no-op if ids empty; **fail** if ids present but row gone |
| Soft-deleted local row | Soft success (skip PUT) — Wave 6 E10 |
| Empty collection href | `ArgumentError` / `ProtocolException` → job **failed** |

Widgets never catch these — Sync sheet surfaces failed jobs. No BLoC-specific DAV error type in 6b.

---

## Engine & enqueue changes (E4–E5)

| Component | Wave 6 | Wave 6b |
| --- | --- | --- |
| [`PimCopyService._shouldEnqueueRemotePush`](../lib/sync/pim_copy_service.dart) | `provider is! DavPimProvider` | **`true` for any resolved PIM provider** (Graph, Google, **DAV**) |
| [`SyncEngine._copyEvent` / `_copyContact`](../lib/sync/sync_engine.dart) | Early return on `DavPimProvider` | **Remove early return** — call `createEvent` / `createContact` |
| [`DavPimProvider.create*`](../lib/protocol/dav_pim_provider.dart) | `UnsupportedError` | PUT + serializers → `PimRemoteCreateResult` |

Job payload schema **unchanged** (Wave 6 D2).

---

## UI honesty (E6 — minimal)

Once enqueue is true for DAV:

- Snackbars already branch on `remotePushEnqueued` → “Syncing to your provider…”
- Sheet subtitle `kPimCopyLocalOnlySubtitle` only when `remotePushSupportedForAccount` is false

Tesla: flip helper + soften leftover “future update” snackbar fallback strings. Large UX redesign → Jules.

---

## Out of scope

- Update / delete remote push; full CRUD enqueue from calendar create UI
- Wave 6c series / RRULE
- Free/busy, ACLs, PROPPATCH, sync-collection REPORT polish
- Live Runbox in CI (operator dogfood E8)

---

*Tesla design signed 2026-08-04.*
