# Wave WEB — Personal operator web client

**Date:** 2026-08-25  
**Status:** **locked** (operator kickoff) — implementation follows checklist; **not** V2.0 release-blocking  
**Updated:** 2026-08-25 — operator: **compose/write in scope**; calendar deferred to V.MaybeNext  
**Roadmap:** [V2_PLAN.md](../../V2_PLAN.md) § Wave WEB · [ROADMAP.md](../../ROADMAP.md) operator queue #1  
**Repo:** Synesis (`v2.0`)  
**Intent:** Trish-only anywhere-access **mail** (read + compose/send) in a browser via **Cloudflare tunnel**. Local-first: the desktop Synesis machine remains SQLite + sync source of truth. Motivation: *because I want it* — personal dogfood, not a hosted product or LiveBytes marketing site.

## Problem

Desktop + phone Synesis cover daily use, but sometimes the operator wants mail in **any browser** (travel laptop, tablet, odd device) — including **replying and composing** — without shipping a public SaaS or moving data off-device.

## Goals

- **Mail read:** unified/folder message list + reading pane from **local Drift** (not live provider round-trips on every click).
- **Mail write:** compose, reply, forward, and **send via existing outbox** paths (`OutgoingMessageBuilder`, outbox queue, `SyncEngine` send jobs) — same semantics as desktop, thinner web UI.
- **Local API on operator machine:** a small HTTP server bound to `127.0.0.1` (desktop Synesis host), reusing `MailRepository` + `MessageActionService` (or equivalent façade) already used by the Flutter UI.
- **Cloudflare tunnel:** expose the local port through `cloudflared` with operator-controlled access (Cloudflare Access or bearer token — TBD in runbook).
- **Trish-only:** single-operator auth model; no multi-tenant accounts, no sign-up flow.
- **Self-hostable seam:** REST JSON shapes documented so a future self-hoster could replicate (optional later).

## Non-goals

- Full Flutter web port of Synesis (`flutter run -d chrome` on the whole app) — **rejected** due to `dart:io`, native `sqlite3`, OAuth redirect servers, and platform plugins across the tree.
- Hosted multi-tenant SaaS, billing, or LiveBytes public site ([POST_V1_WEB_AND_LEGAL.md](../../POST_V1_WEB_AND_LEGAL.md) stays separate).
- **Calendar / People** in Wave WEB — **V.MaybeNext** (operator confirmed 2026-08-25). Mail only for this wave.
- Phone/tablet layout polish beyond responsive basics.
- Replacing Android/desktop apps.
- OAuth login flow **in the browser** — tokens stay on the host; browser uses bridge bearer only.

## Architecture decision

```text
┌─────────────────────────────────────────────────────────────┐
│ Operator desktop (Windows) — existing Synesis process       │
│  ┌──────────────┐    ┌─────────────────────────────────┐   │
│  │ Flutter UI   │    │ WebBridgeServer (new, optional) │   │
│  │ MailWorkspace│    │ shelf / dart:io HttpServer        │   │
│  │ Compose…     │    │ 127.0.0.1:PORT → repository +   │   │
│  └──────┬───────┘    │   message actions / outbox      │   │
│         │            └──────────────┬──────────────────┘   │
│         └───────────┬───────────────┘                       │
│                     ▼                                       │
│              DriftMailRepository → SQLite (WAL)             │
│              SyncEngine + outbox send (background)          │
└─────────────────────────────┬───────────────────────────────┘
                              │ cloudflared tunnel
                              ▼
                    Browser — static web shell
                    GET/POST JSON /api/v1/*
```

| Layer | Choice | Rationale |
| --- | --- | --- |
| **Data** | Existing `DriftMailRepository` on host | Local-first invariant preserved |
| **Writes** | Same outbox + action paths as desktop | No second send pipeline |
| **API** | Dart `shelf` (+ `shelf_router`) in-process | Shared DI with Flutter app |
| **Web UI** | Minimal static HTML/JS shell talking to API | Avoid porting entire app to web |
| **Bind** | `127.0.0.1` only | Never wide-open LAN without tunnel ACL |
| **Tunnel** | Cloudflare Tunnel (`cloudflared`) | Operator-controlled access |

**Why not full Flutter web:** `pubspec.yaml` targets Windows + Android; `lib/` imports `dart:io` widely; Drift uses `drift/native.dart` + `sqlite3` hook.

## Single-user concurrency (SQLite)

Wave WEB **does** introduce a second write surface (browser + desktop). Operator model is **one human**, one host, low probability of simultaneous edits.

| Assumption | Implication |
| --- | --- |
| Single operator | No multi-tenant locking, session tables, or conflict UI |
| Typical use | Read on travel device **or** use desktop — not both composing at once |
| SQLite WAL | Reads (web list/open) concurrent with sync/outbox as today |
| Write path | All mutations go through existing repository/action services inside **Drift transactions** — same as desktop BLoC paths |
| Residual risk | Rare `database is locked` if web send overlaps heavy sync; accept for personal MVP; log + retry; Renee stress gate |

**Not in scope:** CRDT merge, optimistic UI conflict resolution, or a separate web-only DB.

## API sketch

Prefix: `/api/v1/` — JSON, UTF-8, no secrets in responses.

### Read (W1)

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/health` | `{ "ok": true, "version": "…" }` — liveness |
| `GET` | `/accounts` | List accounts (id, label, address) |
| `GET` | `/folders?accountId=` | Folders for account |
| `GET` | `/messages?accountId=&folderId=&limit=&cursor=` | Message list projection |
| `GET` | `/messages/{id}` | Single message metadata + body |

### Write (W3 — required for “done”)

| Method | Path | Description |
| --- | --- | --- |
| `POST` | `/messages/{id}/mark-read` | `{ "unread": false }` — optional W3 if trivial |
| `POST` | `/compose` | Create draft / reply / forward prefill (mirror compose sheet inputs) |
| `POST` | `/outbox` | Enqueue composed message for send (same as desktop compose send) |
| `GET` | `/outbox` | Queue status for web UI feedback (counts / recent failures) |

Auth: `Authorization: Bearer <operator-token>` on all routes except optional `/health`. Token in Settings; rotatable. **No OAuth in the browser.**

CORS: same-origin via tunnel path routing preferred.

## Web UI

| Phase | Scope |
| --- | --- |
| **W2** | Account/folder/list + reading pane; HTML/plain body render |
| **W3** | Compose panel — **plain-text MVP**; reply/forward prefill; send → outbox; DEF-087 HTML quote panel when ready | Send mail from browser on LAN |

Reuse sanitizer / remote-image policy from desktop where practical; document gaps.

## Operator runbook (W4)

Document in `docs/WAVE_WEB_RUNBOOK.md` (create at implement):

1. Enable **Web access** in Settings (toggle + bearer token + port).
2. Start Synesis desktop — server binds loopback.
3. Run `cloudflared tunnel …` to local port.
4. Open tunnel URL; authenticate.
5. Disable toggle when not needed.

## Threat model

| Risk | Mitigation |
| --- | --- |
| Token leak | Rotate in Settings; Cloudflare Access SSO optional |
| CSRF / internet scans | Loopback bind + tunnel ACL |
| XSS in rendered mail | Sanitizer + CSP on web shell |
| **Unauthorized send** | Bearer required on all write routes; tunnel ACL |
| SQLite corruption / lock | WAL + shared write façade; single-user acceptance; Renee concurrent test |
| Tunnel exposes host | Route **only** Synesis port |

## Phased delivery

| Phase | Scope | Exit |
| --- | --- | --- |
| **W0 — Design** | This doc + checklist | ✅ Locked |
| **W1 — Read API** | `WebBridgeServer`, bearer auth, read endpoints, tests | `curl` list + open message |
| **W2 — Read UI** | Browser shell: list + reading pane | localhost dogfood read |
| **W3 — Write API + compose UI** | Outbox enqueue/send, compose/reply; mark read if cheap | Send mail from browser on LAN |
| **W4 — Tunnel + runbook** | `cloudflared` docs/script; travel-device smoke | Trish reads **and writes** via tunnel URL |

## Dependencies

- Add `shelf`, `shelf_router` (and `shelf_cors_headers` if needed) at W1.
- Settings: `webBridgeEnabled`, `webBridgePort`, `webBridgeToken`.

## Testing

- Unit: API handlers with test Drift DB; auth; read; outbox enqueue (mock send).
- Renee: concurrent read + web write + sync loop (single-user stress).
- Manual: tunnel smoke with compose/send.

## Relationship to other work

| Work | Interaction |
| --- | --- |
| **Calendar / People** | **V.MaybeNext** — not Wave WEB |
| **Wave MH** | Orthogonal CLI |
| **V2.0 tag** | WEB does **not** block freeze |

## Open questions (W1)

1. **In-process server** vs sidecar — *lean in-process* for shared repository/actions.
2. **Cloudflare Access vs bearer-only** — operator choice at tunnel setup.
3. **HTML compose on web** — **Locked (2026-08-25):** W3 MVP = **plain-text** compose/reply/forward; DEF-087 HTML quoted-original panel is **W3 target** (same parity as desktop) but plain-text ships first if HTML slips.

---

*Steve / Page — Wave WEB W0. Next: [V2_WAVE_WEB_CHECKLIST.md](../../V2_WAVE_WEB_CHECKLIST.md).*
