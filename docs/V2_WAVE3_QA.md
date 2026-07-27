# Wave 3 / V2.0a P2 — Renee QA notes

| Field | Value |
| --- | --- |
| Reviewed | 2026-07-27 |
| Commits | `7cbfdaa` (+ docs SHA pin follow-up if any) |
| Checklist | [V2_WAVE3_CHECKLIST.md](V2_WAVE3_CHECKLIST.md) |
| Prior gate | [V2_WAVE2_QA.md](V2_WAVE2_QA.md) |
| Tests | **551** passed (`flutter test`) |
| Verdict | **GO** Wave 3 exit · **GO** Wave 4 handoff |

Final close-out after tentative RSVP endpoint coverage and Add-to-calendar widget
action landed on top of the earlier RSVP-ordering and service/store suite.

---

## Verdict

| Gate | Decision | Notes |
| --- | --- | --- |
| Wave 3 implementation review | **Pass** | OAuth `Calendars.ReadWrite`, ICS parse/resolve, Graph RSVP, local `ics:{uid}` drafts, reading-pane RSVP, and attachment Add to calendar are present. |
| Wave 3 exit | **GO** | Focused service/store/provider/widget coverage green; full suite 551; analyze infos only (`prefer_initializing_formals`). |
| Wave 4 (CardDAV/CalDAV) handoff | **GO** | Unblocked. Preserve local-first `DriftPimStore` boundary; do not couple CalDAV iTIP to this mail RSVP MVP. |

Graph RSVP ordering: draft upsert first → remote `respondToEvent` → local
`responseStatus` only after success. Graph failure rethrows without flipping
attendee status (covered by service tests).

---

## Checklist matrix

| Requirement | Status | Evidence |
| --- | --- | --- |
| `Calendars.ReadWrite` replaces `Calendars.Read` | Pass | `GraphAuthConfig.scopes`; OAuth tests |
| Re-consent/operator docs | Pass | README Entra + QUICK_START |
| ICS parse null-safe | Pass | `test/ics_calendar_parser_test.dart` |
| UID draft identity stable | Pass | `test/meeting_invite_service_test.dart` idempotent upsert |
| Missing default calendar safe | Pass | Service test — no write |
| Graph accept/decline/tentative | Pass | Provider test posts all three endpoints + non-2xx |
| Message/event association 404 | Pass | Provider returns null; service falls back to iCalUId |
| Non-Graph RSVP path | Pass | Local-only `serverResponseSent: false` |
| RSVP + Add-to-calendar UI | Pass | Reading-pane RSVP widget; attachment panel tap → `Added to calendar` |
| Mail/Wave 2 PIM regression | Pass | 551/551 |
| `flutter analyze` touched code | Pass | No errors/warnings; existing `prefer_initializing_formals` infos only |

---

## Residuals (non-blocking)

| Gap | Severity | Notes |
| --- | --- | --- |
| No typed user-facing RSVP failure mapping | Low | SnackBar shows raw exception; polish later with re-consent CTA on 403 |
| No automatic UI when token lacks ReadWrite | Low | Same Wave 2 residual; Edit account → re-auth remains the operator path |

---

## Explicitly out of scope (confirmed)

- Calendar module chrome / full CRUD UI
- CardDAV/CalDAV push (Wave 4)
- SMTP iTIP
- Free/busy, Teams deep links
- Cross-account DnD / Wave 7 polish

---

## Inventory delta (for Page)

| Path | Cases / theme | Kind | Maps to |
| --- | --- | --- | --- |
| `test/ics_calendar_parser_test.dart` | REQUEST; all-day; fold/TZID; malformed | unit | Wave 3 ICS |
| `test/meeting_invite_resolver_test.dart` | detect; multi-event; `ics:{uid}` map | unit | Wave 3 resolver |
| `test/meeting_invite_service_test.dart` | calendar missing; idempotent; Graph order; non-Graph | unit | Wave 3 service |
| `test/graph_pim_provider_test.dart` | accept/decline/tentative; errors; message event | unit | Wave 3 Graph |
| `test/reading_pane_actions_test.dart` | RSVP before Reply | widget | Wave 3 UI |
| `test/message_attachments_panel_test.dart` | eligibility + Add to calendar tap/import | widget | Wave 3 UI |
| `test/oauth_identity_manager_test.dart` | `Calendars.ReadWrite` | unit | Wave 3 OAuth |

---

## Handoff one-liners

- **Wave 4 (CardDAV/CalDAV):** Unblocked. Keep reads/writes through `DriftPimStore`; do not regress mail or Graph PIM sync.
- **Dogfood:** Graph accounts signed in before Wave 3 need Edit account → re-auth for `Calendars.ReadWrite` before RSVP succeeds remotely.

*Renee — Quality Engineering · 2026-07-27 (Steve close-out after final gap tests)*
