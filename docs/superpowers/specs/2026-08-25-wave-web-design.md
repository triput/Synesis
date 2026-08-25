# Wave WEB — Personal operator web client

**Date:** 2026-08-25  
**Status:** **locked** (operator kickoff) — implementation follows checklist; **not** V2.0 release-blocking  
**Roadmap:** [V2_PLAN.md](../../V2_PLAN.md) § Wave WEB · [ROADMAP.md](../../ROADMAP.md) operator queue #1  
**Repo:** Synesis (`v2.0`)  
**Intent:** Trish-only anywhere-access mail reading in a browser via **Cloudflare tunnel**. Local-first: the desktop Synesis machine remains SQLite + sync source of truth. Motivation: *because I want it* — personal dogfood, not a hosted product or LiveBytes marketing site.

## Problem

Desktop + phone Synesis cover daily use, but sometimes the operator wants mail/PIM in **any browser** (travel laptop, tablet, odd device) without shipping a public SaaS or moving data off-device.

## Goals

- **Read-only MVP:** unified/folder message list + reading pane (subject, from, HTML/plain body) from **local Drift**, not live provider round-trips on every click.
- **Local API on operator machine:** a small HTTP server bound to `127.0.0.1` (desktop Synesis host), reusing `MailRepository` queries already used by the Flutter UI.
- **Cloudflare tunnel:** expose the local port through `cloudflared` with operator-controlled access (Cloudflare Access or tunnel token — TBD in runbook).
- **Trish-only:** single-operator auth model; no multi-tenant accounts, no sign-up flow.
- **Self-hostable seam:** REST JSON shapes documented so a future self-hoster could replicate (optional later).

## Non-goals (MVP)

- Full Flutter web port of Synesis (`flutter run -d chrome` on the whole app) — **rejected for MVP** due to `dart:io`, native `sqlite3`, OAuth redirect servers, and platform plugins across the tree.
- Hosted multi-tenant SaaS, billing, or LiveBytes public site ([POST_V1_WEB_AND_LEGAL.md](../../POST_V1_WEB_AND_LEGAL.md) stays separate).
- Compose, send, mark read/unread, move, delete, or sync kick from the web UI in v1.
- Calendar / People modules in v1 (mail only).
- Phone/tablet-optimized layout polish beyond responsive basics.
- Replacing Android/desktop apps.

## Architecture decision (MVP)

```text
┌─────────────────────────────────────────────────────────────┐
│ Operator desktop (Windows) — existing Synesis process       │
│  ┌──────────────┐    ┌─────────────────────────────────┐   │
│  │ Flutter UI   │    │ WebBridgeServer (new, optional) │   │
│  │ MailWorkspace│    │ shelf / dart:io HttpServer        │   │
│  │ …            │    │ 127.0.0.1:PORT → MailRepository │   │
│  └──────┬───────┘    └──────────────┬──────────────────┘   │
│         │                           │                       │
│         └───────────┬───────────────┘                       │
│                     ▼                                       │
│              DriftMailRepository → SQLite                   │
│              SyncEngine (unchanged; UI thread not blocked)    │
└─────────────────────────────┬───────────────────────────────┘
                              │ cloudflared tunnel
                              ▼
                    Browser (anywhere) — static web shell
                    fetches JSON from tunneled /api/*
```

| Layer | Choice | Rationale |
| --- | --- | --- |
| **Data** | Existing `DriftMailRepository` on host | Local-first invariant preserved |
| **API** | Dart `shelf` (+ `shelf_router`) in-process or sidecar isolate | Same language/repo; no new runtime |
| **Web UI** | Phase 1: minimal static HTML/JS **or** tiny Flutter web **viewer only** talking to API | Avoid porting entire app to web |
| **Bind** | `127.0.0.1` only | Never wide-open LAN without tunnel ACL |
| **Tunnel** | Cloudflare Tunnel (`cloudflared`) | Operator already familiar; no port-forward drama |

**Why not full Flutter web:** `pubspec.yaml` targets Windows + Android; `lib/` imports `dart:io` widely; Drift uses `drift/native.dart` + `sqlite3` hook. A full web target is a multi-week platform matrix, not a personal MVP.

## MVP API sketch (read-only)

Prefix: `/api/v1/` — JSON, UTF-8, no secrets in responses.

| Method | Path | Description |
| --- | --- | --- |
| `GET` | `/health` | `{ "ok": true, "version": "…" }` — unauthenticated liveness for tunnel |
| `GET` | `/accounts` | List accounts (id, label, address) |
| `GET` | `/folders?accountId=` | Folders for account |
| `GET` | `/messages?accountId=&folderId=&limit=&cursor=` | Message list projection (same fields as list UI) |
| `GET` | `/messages/{id}` | Single message metadata + body (cached body from Drift) |

Auth header (MVP): `Authorization: Bearer <operator-token>` stored in secure settings / env on server; static token in Cloudflare Access or tunnel config on client. **No OAuth in the browser for MVP.**

CORS: allow tunneled origin only when UI is static on same host; otherwise same-origin via tunnel path routing.

## Web UI MVP (Phase 1b)

- Single-page **mail reader**: account/folder picker, scrollable list, reading pane.
- Reuse HTML rendering approach from mobile: sanitized HTML body or plain text fallback (server returns `contentType` + `body`).
- No WebView in browser — native browser HTML rendering (`iframe srcdoc` or trusted innerHTML with DOMPurify-style policy — pick at implement).

## Operator runbook (Phase 2)

Document in `docs/WAVE_WEB_RUNBOOK.md` (create at implement):

1. Enable **Web access** in Synesis Settings (toggle + generated bearer token + port).
2. Start / restart Synesis desktop — server binds loopback.
3. Run `cloudflared tunnel …` (named tunnel or quick tunnel) to local port.
4. Open tunnel URL on travel device; paste token or complete Cloudflare Access login.
5. **Disable** toggle when not needed.

## Threat model (MVP)

| Risk | Mitigation |
| --- | --- |
| Token leak via tunnel URL logs | Short-lived tokens; rotate in Settings; Cloudflare Access SSO |
| CSRF / random internet scans | Loopback bind + tunnel ACL; no `0.0.0.0` in MVP |
| XSS in rendered mail HTML | Same remote-image / sanitizer policies as desktop reader; CSP on web shell |
| Write actions | **None** in MVP API |
| SQLite corruption from concurrent writers | API read-only; writes stay in desktop UI / sync isolate |
| Tunnel exposes entire machine | Tunnel routes **only** Synesis port; not RDP/SSH |

## Phased delivery

| Phase | Scope | Exit |
| --- | --- | --- |
| **W0 — Design** | This doc + checklist | Operator sign-off |
| **W1 — API** | `WebBridgeServer`, bearer auth, read endpoints, unit tests | `curl localhost` list + open message |
| **W2 — UI** | Static or minimal web shell consuming API | Browser on LAN reads mail |
| **W3 — Tunnel** | Runbook + `tool/start_web_tunnel.ps1` stub | Trish reads mail via Cloudflare URL |
| **W4 — Polish** (optional) | Mark read, compose — **only if wanted** | Out of MVP |

## Dependencies

- Add `shelf`, `shelf_router` (and `shelf_cors_headers` if needed) to `pubspec.yaml` at W1.
- Settings flag: `webBridgeEnabled`, `webBridgePort`, `webBridgeToken` (generated UUID; stored via secure preferences pattern — not in git).

## Testing

- Unit: API handlers with in-memory / test Drift DB (mirror `mailbox_widget_launch_test` patterns).
- Manual: tunnel smoke on operator Windows host.
- **No** CI tunnel requirement.

## Relationship to other work

| Work | Interaction |
| --- | --- |
| **Wave MH** digest CLI | Orthogonal — same repo, different entrypoint |
| **V2.0 tag** | WEB does **not** block freeze |
| **Wave H2 / R** | May add shelf deps; full hygiene before V2.1 |
| **LiveBytes site** | Unrelated — legal URLs stay external |

## Open questions (resolve in W1 planning)

1. **In-process vs sidecar:** Server inside Flutter process (easier DI) vs `dart run bin/synesis_web.dart` attaching to same DB file (cleaner separation). *Lean in-process for MVP with shared repository instance.*
2. **DB lock:** Verify Drift WAL + read-only API concurrent with sync isolate (Renee gate).
3. **Cloudflare Access vs bearer-only:** Operator preference at tunnel setup.

---

*Steve / Page — Wave WEB W0. Next: [V2_WAVE_WEB_CHECKLIST.md](../../V2_WAVE_WEB_CHECKLIST.md).*
