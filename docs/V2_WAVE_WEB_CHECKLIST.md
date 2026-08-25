# V2 Wave WEB — Personal operator web client checklist

| Field | Value |
| --- | --- |
| Status | **W0 complete** (design locked 2026-08-25) — **W1 next** |
| Owner | Jules (UI/shell) + Tesla (API/outbox boundaries) |
| Design | [superpowers/specs/2026-08-25-wave-web-design.md](superpowers/specs/2026-08-25-wave-web-design.md) |
| Release gate | **None** — personal operator track; not V2.0 freeze-blocking |
| Operator scope | **Read + compose/send**; calendar **V.MaybeNext** |

## W0 — Design & kickoff

- [x] Operator intent captured (*personal, not release*)
- [x] Architecture: local API + tunnel (not full Flutter web port)
- [x] Read + **write** (compose/outbox) in scope; calendar out
- [x] Single-user SQLite concurrency model documented
- [x] MVP API sketch + threat model
- [x] Phased delivery table
- [ ] Steve operator sign-off on open questions (in-process server, Cloudflare Access vs bearer)
- [x] Web compose: **plain-text MVP** in W3; DEF-087 HTML quote panel W3 (parity target, not MVP blocker)

## W1 — Read API (`WebBridgeServer`)

- [ ] Add `shelf` + `shelf_router` dependencies
- [ ] `lib/web/web_bridge_server.dart` — loopback bind, graceful shutdown
- [ ] Settings: `webBridgeEnabled`, `webBridgePort` (default TBD), `webBridgeToken` (generated)
- [ ] Settings UI toggle + “copy token” + port display (desktop only)
- [ ] Read endpoints: `/health`, `/accounts`, `/folders`, `/messages`, `/messages/{id}`
- [ ] Bearer auth middleware (401 without token)
- [ ] Wire start/stop from desktop app lifecycle (enable toggle → start server)
- [ ] Unit tests: auth rejection, list messages, get message body
- [ ] Renee: concurrent **read** during sync (no DB lock regressions)

## W2 — Browser shell (read UI)

- [ ] Static web assets under `web/` **or** `tool/web_reader/` consuming `/api/v1/*`
- [ ] Account/folder/message list + reading pane layout
- [ ] HTML body rendering with sanitizer / remote-image policy parity (document gaps)
- [ ] Manual dogfood: browser on same machine via `localhost`

## W3 — Write API + compose UI

- [ ] Write routes: `POST /compose`, `POST /outbox`, `GET /outbox` (status); optional mark-read
- [ ] Route writes through existing repository / `MessageActionService` / outbox — **no parallel send pipeline**
- [ ] Browser compose panel — **plain-text MVP** (reply/forward/new); send → outbox feedback
- [ ] DEF-087 HTML quoted-original panel on web (W3 parity; after plain-text MVP lands)
- [ ] Unit tests: enqueue outbox, auth on write routes
- [ ] Renee: concurrent web write + desktop UI + sync (single-user stress)

## W4 — Cloudflare tunnel + runbook

- [ ] `docs/WAVE_WEB_RUNBOOK.md` — enable, tunnel, rotate token, disable
- [ ] `tool/start_web_tunnel.ps1` (or documented `cloudflared` one-liner)
- [ ] Operator smoke: **read + compose/send** from non-host device via tunnel URL
- [ ] DEFECTS note if any tunnel/auth friction

## Explicitly out of Wave WEB

- [ ] Calendar module — **V.MaybeNext**
- [ ] People / contacts module — **V.MaybeNext**
- [ ] Full Flutter web app port

## Exit (Wave WEB done)

Operator can enable web bridge on desktop Synesis, open a Cloudflare tunnel URL on another device, authenticate, **read and compose/send mail** from local SQLite/outbox — without shipping a public SaaS or blocking V2.0 tag.

---

*Page — checklist created 2026-08-25; updated for compose/write scope.*
