# Wave 6b — Renee QA (CalDAV/CardDAV Write)

> **Status:** **Not started** — open at E7. Checklist: [V2_WAVE_6B_CHECKLIST.md](V2_WAVE_6B_CHECKLIST.md).

## Verdict

| Field | Value |
| --- | --- |
| **Result** | — (pending) |
| **Test count** | — (baseline **659** at Wave 6 exit) |
| **Operator dogfood (E8)** | — |

## Scope under test

- CalDAV event create (PUT) for `events_copy` when target is DAV
- CardDAV contact create (PUT) for `contacts_copy`
- `local:*` soft-delete guard under full pull
- UI no longer labels DAV as local-only when push supported
- Runbox dogfood

## Test delta (Renee → Page)

*(Populate at E7.)*
