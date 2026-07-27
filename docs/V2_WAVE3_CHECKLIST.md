# Wave 3 — V2.0a P2 Checklist (meeting-mail bridge)

> **Status:** **Complete** (2026-07-27, `7cbfdaa`, 551 tests) — Tesla (OAuth/ICS/Graph RSVP/service); Jules (reading-pane + attachments UI); Renee QA **GO** — [V2_WAVE3_QA.md](V2_WAVE3_QA.md). Parent plan: [V2_PLAN.md](V2_PLAN.md). Wave 2 exit: [V2_WAVE2_CHECKLIST.md](V2_WAVE2_CHECKLIST.md).

Wave 3 delivers the **meeting-mail bridge MVP**: recognize meeting invitations in mail, resolve ICS → local event drafts (`ics:{uid}`), RSVP via Microsoft Graph when an event id is known, and Add to calendar for `.ics` / `text/calendar` attachments. Mail-first UI; Calendar chrome deferred.

## Sequence

```text
Wave 0 ✅ → Wave H ✅ → Wave 1 (P0) ✅
                         → Wave 2: Graph PIM (P1) ✅
                         → Wave 3: meeting-mail bridge (P2) ✅
                         → Wave 4: CardDAV/CalDAV (P3–P4) ✅
                         → ★ Wave 5: picker + Calendar UI (P5–P6) ← next
                         → Wave 5: picker + Calendar UI (P5–P6)
                         → Wave 6: cross-account DnD copy
```

## OAuth scopes & re-consent

- [x] Wave 3 plan approved, including delegated **`Calendars.ReadWrite`** and operator re-consent
- [x] Upgrade Graph OAuth scope from `Calendars.Read` to **`Calendars.ReadWrite`**; retain `Contacts.Read` and mail scopes — `GraphAuthConfig.scopes`
- [x] Document permission in Entra registration instructions (README + QUICK_START)
- [x] Existing Graph accounts re-consent via **Edit account → re-auth** (same path as Wave 2)
- [x] New Graph accounts request `Calendars.ReadWrite` on first consent

## Meeting invitation resolution

- [x] ICS parser (`lib/pim/ics_calendar_parser.dart`) — VCALENDAR/VEVENT/METHOD, UID, DTSTART/DTEND, SUMMARY, LOCATION, ORGANIZER, ATTENDEE
- [x] `MeetingInviteResolver` — Graph meeting message / text/calendar / `.ics` / body VCALENDAR detection; map to `CalendarEvent` + `EventAttendee`
- [x] Resolvable invitation state without Calendar module UI
- [x] Malformed / absent ICS treated as non-fatal non-invite

## RSVP & local draft deliverables

- [x] Graph RSVP accept / decline / tentativelyAccept on `GraphPimProvider`
- [x] Graph failure rethrows without flipping local `responseStatus` (draft may remain)
- [x] `.ics` → local draft with provider ID **`ics:{uid}`**
- [x] Idempotent upsert by `(accountId, providerId)`
- [x] Local-first via `MeetingInviteService` + `DriftPimStore`

## Reading-pane UI

- [x] Accept / Decline / Tentative before Reply when invite detected
- [x] Add to calendar for `.ics` / `text/calendar` attachments
- [x] Busy disable + SnackBar success/failure (Graph vs local-only copy)
- [x] Wide + narrow reading-pane layouts

## Verification

- [x] ICS parser unit tests
- [x] MeetingInviteResolver unit tests
- [x] Graph accept/decline/tentative + error mapping tests
- [x] Service/store idempotency + ordering tests
- [x] Widget tests: RSVP actions + Add to calendar import feedback
- [x] `flutter analyze` — no errors on touched code (infos only)
- [x] Full `flutter test` green — **551/551**

## Docs

- [x] [V2_PLAN.md](V2_PLAN.md) / [ROADMAP.md](ROADMAP.md) / this checklist
- [x] README + QUICK_START — `Calendars.ReadWrite` re-consent
- [x] [V2_WAVE3_QA.md](V2_WAVE3_QA.md) — Renee **GO**

## Out of Wave 3 MVP

- Calendar module chrome / full CRUD UI
- CalDAV push / CardDAV/CalDAV (Wave 4)
- SMTP iTIP
- Free/busy, Teams deep links
- Cross-account DnD / Wave 7 polish

## Wave 3 exit criteria (gate)

- [x] `Calendars.ReadWrite` + re-consent path
- [x] ICS parser + MeetingInviteResolver
- [x] Graph accept/decline/tentative with safe failures
- [x] `.ics` → one local draft per `ics:{uid}`
- [x] Reading pane RSVP + Add to calendar
- [x] Tests + analyze + full suite green; no mail/PIM regression
- [x] Docs + Renee QA GO; Wave 4 unblocked

## Team routing

| Role | Wave 3 work |
| --- | --- |
| Steve | Orchestrate; exit gate; commit |
| Tesla | OAuth, ICS, Graph RSVP, MeetingInviteService |
| Jules | Reading-pane RSVP + attachments UI |
| Renee | QA — GO ([V2_WAVE3_QA.md](V2_WAVE3_QA.md)) |
| Page | Plan / roadmap / checklist / operator docs |
