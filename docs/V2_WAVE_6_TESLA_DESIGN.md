# Wave 6 — Tesla Integration Design (D2–D4)

> **Status:** Signed 2026-08-04 (Tesla) · Parent: [V2_WAVE_6_CHECKLIST.md](V2_WAVE_6_CHECKLIST.md) · D1 locked (Graph↔Graph / Graph↔Google / Google↔Google push; DAV target = local-only until Wave 6b).

## Goals

Local-first cross-account / cross-list **copy**: duplicate in Drift under the target collection, then async `events_copy` / `contacts_copy` for Graph/Google remote create. UI never awaits network. Wave **6c** series semantics out of scope — copies are **single independent events** (no RRULE / series expansion).

---

## D2 — Job payload schema

Jobs reuse the existing durable row shape from [`DriftSyncJobStore.enqueueSyncJob`](../lib/repository/drift/drift_sync_job_store.dart):

| Column | Role for copy |
| --- | --- |
| `accountId` | **Target** account (same convention as contacts/events bootstrap fan-out) |
| `type` | `events_copy` \| `contacts_copy` ([`PimSyncJobs`](../lib/sync/pim_sync_jobs.dart)) |
| `payloadJson` | JSON object (see below) |
| `status` | `pending` → `running` → `done` / `failed` |

### `events_copy` payload

```json
{
  "localEventId": "<Drift events.id on target>",
  "targetCalendarId": "<Drift calendars.id>",
  "targetCalendarProviderId": "<remote calendar id / href>",
  "sourceEventId": "<optional diagnostics>",
  "sourceAccountId": "<optional diagnostics>"
}
```

### `contacts_copy` payload

```json
{
  "localContactId": "<Drift contacts.id on target>",
  "targetContactListId": "<Drift contact_lists.id>",
  "targetContactListProviderId": "<remote folder / group id / href>",
  "sourceContactId": "<optional diagnostics>",
  "sourceAccountId": "<optional diagnostics>"
}
```

**Encoding:** `jsonEncode(<String, String>{...})` — same pattern as contacts/events bootstrap payloads in [`SyncEngine`](../lib/sync/sync_engine.dart).

**Ownership:** The job points at the **already-duplicated local row** (`local:{uuid}` `providerId`). The handler does not re-read the source account.

### DAV target choice (locked for Wave 6)

**Do not enqueue** `events_copy` / `contacts_copy` when the target PIM adapter is DAV ([`DavPimProvider`](../lib/protocol/dav_pim_provider.dart)).

- Local duplicate still runs (immediate UI).
- Row keeps `providerId = local:{uuid}` → honest “not synced yet” signal for Jules UI.
- Avoids phantom sync-sheet activity for a no-op push.
- Wave **6b** will enqueue (or re-use the same job types) once CalDAV/CardDAV create exists.

---

## D3 — Provider create APIs

### Surface (add on [`GraphPimProvider`](../lib/protocol/graph_pim_provider.dart); override on Google; DAV throws)

| Method | Graph | Google | DAV (Wave 6) |
| --- | --- | --- | --- |
| `createEvent({calendarProviderId, event, attendees?})` | `POST /me/calendars/{id}/events` | `POST /calendars/{id}/events` | `UnsupportedError` (not called) |
| `createContact({folderProviderId, contact, emails, phones})` | `POST /me/contacts` or `/me/contactFolders/{id}/contacts` | `POST /v1/people:createContact` (+ membership) | `UnsupportedError` |

**Return type:** `PimRemoteCreateResult { providerId, etag? }` parsed from the create response (`id` / `resourceName`, etag).

### Event body (create)

| Field | Graph | Google |
| --- | --- | --- |
| Title | `subject` | `summary` |
| Body | `body.content` (text) | `description` |
| Start/end | `start`/`end` dateTime or date + `isAllDay` | `start`/`end` `dateTime` or `date` |
| Location | `location.displayName` | `location` |
| Reminder | `reminderMinutesBeforeStart` | `reminders.overrides` (optional) |
| RRULE | **omitted** (Wave 6c) | **omitted** |
| Attendees | **omitted on POST** (avoid invite fan-out; W6-5) | **omitted on POST** |

Local Drift may still hold copied attendee rows for display; remote create is a standalone personal event.

### Contact body (create)

| Field | Graph | Google |
| --- | --- | --- |
| Names | `displayName`, `givenName`, `surname` | `names[]` |
| Company | `companyName` | `organizations[].name` |
| Notes | `personalNotes` | `biographies[].value` |
| Emails | `emailAddresses[]` | `emailAddresses[].value` |
| Phones | `businessPhones` / `homePhones` / `mobilePhone` | `phoneNumbers[]` |
| List membership | folder path | `memberships[].contactGroupMembership` |

### Error / failure mapping

| Failure | Mapping |
| --- | --- |
| HTTP 401 after refresh | `GraphAuthException` → job `failed` via `_processJobSafely` |
| HTTP 4xx/5xx | `ProtocolException(statusCode: …)` → job `failed`; UI reads sync status / failed job detail |
| Missing payload / missing local row | Handler returns `null` (soft success) **or** fails with clear `FormatException` if ids present but row gone — prefer **fail** when payload ids are non-empty but row missing (operator-visible) |
| DAV target | Never called (no enqueue) |
| Network offline | Job stays pending / fails per existing engine kick policy |

Widgets never catch these — cubits only enqueue; Sync sheet surfaces failure.

---

## D4 — Idempotency

### Local identity

1. `duplicate*` / `createLocal*` assign `providerId = local:{uuid}` (same as [`createLocalEvent`](../lib/repository/drift/drift_pim_store.dart)).
2. Local primary key `id = PimIds.stableLocalId(accountId, localProviderId)` — **stable for UI** for the life of the row.
3. On successful remote create: **`rewrite*ProviderId`** updates `providerId` + `etag` **in place** (same `id`). Do **not** recreate the row under `stableLocalId(account, remoteId)`.

### Retry safety

| State | Handler behavior |
| --- | --- |
| `providerId` starts with `local:` | POST create → rewrite → done |
| `providerId` already remote | **No-op success** (prior attempt finished) |
| Create succeeded, rewrite crashed | Retry may POST a second remote object — accepted MVP risk; mitigate by rewrite immediately in the same try after response parse |
| Job re-delivered after `done` | Engine does not re-claim done jobs |

### DAV target

No job. `local:*` remains until Wave 6b write-back rewrites to href.

---

## Soft-delete / full-pull race

### Threat

DAV (always) and Google **full** pulls (no syncToken) soft-delete local rows whose `providerId` is absent from the remote snapshot ([`SyncEngine._syncContacts` / `_syncEvents`](../lib/sync/sync_engine.dart)). Unpushed `local:*` copies would vanish.

Graph delta / removedProviderIds never lists `local:*`, so Graph incremental is safe. Graph `calendarView` fallback does **not** run missing soft-delete today.

### Mitigation (Wave 6 — required with P1)

When applying full-snapshot soft-delete, **skip** rows where `PimIds.isLocalProviderId(providerId)` (`local:` prefix).

Same guard applies if a later Graph full-snapshot path is added.

DAV as **source** of a copy is allowed: read local Drift event/contact (synced earlier), duplicate onto Graph/Google target, push target. No DAV write in Wave 6.

---

## Store API (P1)

| Method | Behavior |
| --- | --- |
| `createLocalContact` | Insert contact + optional emails/phones; `local:{uuid}` |
| `duplicateEventToCalendar` | Clone fields to target calendar; **strip `rrule`**; copy attendees with `isOrganizer: false`; new `local:*` |
| `duplicateContactToList` | Clone contact + emails/phones to target list; new `local:*` |
| `rewriteEventProviderId` / `rewriteContactProviderId` | In-place providerId + etag |
| `getEvent` / `getContact` | Lookup by local id |

## Enqueue helper

[`PimCopyService`](../lib/sync/pim_copy_service.dart): duplicate → if target resolver is Graph/Google → enqueue job → return local entity. Jules wires cubits / DnD in P2–P3.

---

## Out of scope (reminders)

- CalDAV/CardDAV create → Wave **6b**
- Series / occurrence UX → Wave **6c**
- `events_push` / `contacts_push` for ordinary local CRUD
- Organizer re-invite / attachment copy
- Corporate Graph research → post–Wave 6

---

*Tesla design signed 2026-08-04.*
