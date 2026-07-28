<p align="center">
  <img src="branding/branding_logo_lockup_google.png" alt="synesis" width="360" />
</p>

# Synesis Architecture: Under the Hood

Welcome to the Synesis project! This document is for tech enthusiasts, product thinkers, and engineers who want to understand how Synesis works without reading Dart code first.

Synesis is a **local-first email + PIM client** built on Flutter for **Windows** and **Android**. V2 adds **contacts and calendar** as first-class modules alongside mail. Beneath the UI lies a system designed for zero-lag performance and reliable background synchronization.

> **Want the Dart tour?** If you're reading code (or curious how Cubits, Drift, and SyncEngine connect), see **[DART_IN_SYNESIS.md](DART_IN_SYNESIS.md)** — a beginner-friendly walkthrough of this repo, not a language textbook.

> **V2 wave status:** [V2_PLAN.md](V2_PLAN.md) · **597** automated tests ([TEST_INVENTORY.md](TEST_INVENTORY.md)) · Toolchain: Flutter **3.44.6**, Dart **`^3.12.2`** (Wave H).

---

## 1. The Local-First Philosophy

Most modern email apps are "thin clients"—they constantly talk to the cloud. If you lose your internet connection, or if the server is slow, the app stalls, shows loading spinners, or fails to open emails.

Synesis flips this model using a **Local-First Architecture**.

* **The database is the source of truth:** Everything on screen — inbox, folders, messages, contact lists, contacts, calendars, events — is read from a local SQLite database on your device (Drift schema **v7**).
* **Zero UI lag:** Local reads take fractions of a millisecond, so the UI stays fluid at 60 FPS.
* **Offline resilience:** Compose mail offline → local Outbox; toggle calendar display prefs → local row update; sync catches up when the network returns.
* **Optimistic mutations:** Mark read, move mail, change display toggles — the UI updates immediately; SyncEngine queues remote work afterward.

The UI **never** calls Graph, Google, IMAP, or DAV directly. It reads what SyncEngine already wrote.

---

## 2. The Core Stack

| Layer | Technology | Role |
| --- | --- | --- |
| **UI** | Flutter / Dart | One codebase → Windows desktop + Android mobile |
| **State** | BLoC / Cubit (`flutter_bloc`) | `MailboxCubit`, `CalendarCubit`, `PeopleCubit`, `AppSettingsCubit` — widgets react to immutable state snapshots |
| **Data** | SQLite + Drift | Mail tables, PIM tables, FTS, sync jobs, outbox; optional encryption via sqlite3mc hook |
| **Background** | SyncEngine + providers | Sequential durable job processor; mail + PIM fetch/normalize/write |
| **Heavy CPU** | Dart Isolates | Outbound MIME assembly (`multipart_builder`) — keeps UI thread free |

---

## 3. Application Shell (V2 Modules)

V2 uses an **Outlook-style module switcher** (`ModuleShell`):

| Module | Default? | What it shows |
| --- | --- | --- |
| **Mail** | Yes (cold start) | Three-pane inbox — unchanged V1 behavior under the hood |
| **Calendar** | No | Multi-calendar month/week views; overlay or side-by-side layout |
| **People** | No | Contact lists + search; also feeds the compose contact picker |

All three modules share the same SQLite file and SyncEngine. Switching modules only swaps the body widget — providers and background sync keep running.

---

## 4. How Data Flows (The BLoC Pattern)

Synesis uses **Cubits** for predictable one-way flow:

```text
Remote server  →  Provider adapter  →  SyncEngine  →  SQLite  →  Cubit  →  Widget
User action    →  Cubit / service     →  SQLite (optimistic)  →  SyncEngine job  →  Provider (later)
```

**Mail path**

1. **SyncEngine** negotiates with Exchange (Graph) or IMAP/SMTP (Google, Runbox, …), writes messages to SQLite.
2. **Database streams** broadcast changes (`watchChanges` on mail repository).
3. **MailboxCubit** listens, builds `MailboxState`, emits to widgets.
4. **MailWorkspace** panes paint from state — they don't query the server.

**PIM path** (same philosophy)

1. **SyncEngine** runs PIM job types (`contact_lists_bootstrap`, `calendars_incremental`, `events_incremental`, …).
2. **PIM provider** fetches and normalizes remote contacts/calendars/events.
3. **DriftPimStore** writes SQLite rows.
4. **CalendarCubit** / **PeopleCubit** read the store and emit state to Calendar/People workspaces.

---

## 5. Multi-Protocol Engines

A **Provider Registry** picks the right adapter per account. Mail and PIM are separate resolve paths — same account can use Graph for mail and Graph for PIM, or IMAP for mail and Google API for PIM, etc.

### Mail

| Account type | Engine | Protocol |
| --- | --- | --- |
| Microsoft / Exchange | Graph mail provider | Microsoft Graph API (HTTPS + OAuth) |
| Google XOAUTH, IMAP/other | IMAP/SMTP provider | Classic IMAP receive + SMTP send (XOAUTH2 for Google) |

Regardless of protocol, mail is normalized into the same SQLite message shape. The UI never knows which engine fetched a message.

### PIM (V2)

| Account type | Engine | Protocol |
| --- | --- | --- |
| Microsoft / Exchange | Graph PIM provider | Graph Contacts + Calendar API |
| Google XOAUTH | Google PIM provider | Google People + Calendar API (Wave G — **not** CardDAV) |
| IMAP + DAV credentials | DAV PIM provider | CardDAV contacts + CalDAV calendars (Wave 4; Runbox dogfood) |

Local PIM storage is provider-agnostic: `contact_lists`, `contacts`, `calendars`, `events`, FTS, and per-collection sync cursors. Provider-specific IDs live in sync metadata, not in the UI layer.

**Google Calendar honesty:** Wave G shipped the Google PIM adapter and automated tests are green. Operator dogfood for Google Calendar is **not** treated as production-proven: existing Google accounts need **full app restart + re-auth** after the DEF-061 refresh-token fix, and event sync is an MVP windowed snapshot (no persistent Google `syncToken` yet). See [V2_WAVE_G_QA.md](V2_WAVE_G_QA.md).

**Not yet shipped:** Cross-account drag-and-drop copy for events/contacts (Wave 6); PIM push/write-back handlers beyond local CRUD scaffolding; Google Calendar meeting RSVP (Graph RSVP path exists from Wave 3 meeting-mail bridge).

---

## 6. Meeting-Mail Bridge (V2.0a)

When a message contains a calendar invite (`.ics`), Synesis can parse it and offer accept/decline/tentative actions. Accepted invites can draft a local calendar event. This bridges mail and calendar without requiring the user to leave the reading pane. Graph accounts use the Graph RSVP path; Google Calendar RSVP over the Calendar API is **out of scope for V2.0**.

---

## 7. Focus and Search

* **Mail FTS:** SQLite FTS5 indexes message bodies for instant local search.
* **Contact FTS:** `contact_fts` indexes names and emails across selected contact lists — powers People search and the compose contact picker.
* **Focus Scorer:** Evaluates incoming mail against rules; routes to Focused vs Other inbox tabs.

Remote search (server-side) is queued through SyncEngine when local cache isn't enough — same job-queue pattern as mail mutations.

---

## 8. Sync Job Model

SyncEngine processes a **sequential durable queue** of typed jobs. Examples:

| Domain | Job examples | Status (V2) |
| --- | --- | --- |
| Mail | incremental fetch, send outbox, move/star/delete | Shipped (V1+) |
| PIM discovery | `contact_lists_bootstrap`, `calendars_bootstrap` | Shipped (Waves 2, 4, G) |
| PIM incremental | `contacts_incremental`, `events_incremental` | Shipped (provider-dependent) |
| PIM push/copy | `contacts_push`, `events_push`, `contacts_copy`, `events_copy` | Reserved — Wave 6+ |

Job failures are retryable and visible in sync status UI. Network I/O runs off the UI critical path (async job loop, not on the paint thread).

---

## 9. Engineered for Quality

Synesis delivery follows a **phase-gate multi-agent workflow** (Steve orchestrates; Jules/Andi implement UI; Tesla owns sync/protocol; Renee QA; Page docs). See [AGENTS.md](../AGENTS.md).

* **Zero placeholders:** Core paths are complete and typed — no half-finished stubs in production modules.
* **Defensive coding:** Specific exception handling, safe fallbacks, BLoC error states instead of silent crashes.
* **Gold Master headers:** Core Dart files document layer, purpose, and version at the top of each file.
* **Test inventory:** **597** automated cases catalogued in [V1_AUTOMATED_TEST_INVENTORY.csv](V1_AUTOMATED_TEST_INVENTORY.csv); wave checklists link test IDs rather than duplicating file lists.

This keeps Synesis stable as mail and PIM data grow from hundreds to tens of thousands of rows.

---

## Related docs

| Doc | Purpose |
| --- | --- |
| [DART_IN_SYNESIS.md](DART_IN_SYNESIS.md) | Code-level tour with file paths and step-throughs |
| [V2_PLAN.md](V2_PLAN.md) | V2 waves, PIM scope, exit criteria |
| [WAVE_H_DEPENDENCY_HYGIENE.md](WAVE_H_DEPENDENCY_HYGIENE.md) | Toolchain and dependency upgrade log |
| [SPEC.md](SPEC.md) | Product requirements |

---

*Maintained by Page (documentation). Last updated: 2026-07-27 (V2 Waves 0–G refresh).*
