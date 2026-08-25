# V2 Wave WEB — Personal operator web client checklist

| Field | Value |
| --- | --- |
| Status | **W0 complete** (design locked 2026-08-25) — **W1 next** |
| Owner | Jules (UI/shell) + Tesla (API/auth boundaries) |
| Design | [superpowers/specs/2026-08-25-wave-web-design.md](superpowers/specs/2026-08-25-wave-web-design.md) |
| Release gate | **None** — personal operator track; not V2.0 freeze-blocking |

## W0 — Design & kickoff

- [x] Operator intent captured (*personal, not release*)
- [x] Architecture: local read-only API + tunnel (not full Flutter web port)
- [x] MVP API sketch + threat model
- [x] Phased delivery table
- [ ] Steve operator sign-off on open questions (in-process server, Cloudflare Access vs bearer)

## W1 — Read-only API (`WebBridgeServer`)

- [ ] Add `shelf` + `shelf_router` dependencies
- [ ] `lib/web/web_bridge_server.dart` — loopback bind, graceful shutdown
- [ ] Settings: `webBridgeEnabled`, `webBridgePort` (default TBD), `webBridgeToken` (generated)
- [ ] Settings UI toggle + “copy token” + port display (desktop only)
- [ ] Endpoints: `/health`, `/accounts`, `/folders`, `/messages`, `/messages/{id}`
- [ ] Bearer auth middleware (401 without token)
- [ ] Wire start/stop from desktop app lifecycle (enable toggle → start server)
- [ ] Unit tests: auth rejection, list messages, get message body
- [ ] Renee: concurrent read during sync (no DB lock regressions)

## W2 — Browser shell (read-only UI)

- [ ] Static web assets under `web/` **or** `tool/web_reader/` consuming `/api/v1/*`
- [ ] Account/folder/message list + reading pane layout
- [ ] HTML body rendering with sanitizer / remote-image policy parity (document gaps)
- [ ] Manual dogfood: browser on same machine via `localhost`

## W3 — Cloudflare tunnel + runbook

- [ ] `docs/WAVE_WEB_RUNBOOK.md` — enable, tunnel, rotate token, disable
- [ ] `tool/start_web_tunnel.ps1` (or documented `cloudflared` one-liner)
- [ ] Operator smoke: read mail from non-host device via tunnel URL
- [ ] DEFECTS note if any tunnel/auth friction

## W4 — Optional polish (post-MVP)

- [ ] Mark read/unread from web
- [ ] Compose / reply (likely never on web — product call)
- [ ] Calendar / People read surfaces

## Exit (Wave WEB MVP)

Operator can enable web bridge on desktop Synesis, open a Cloudflare tunnel URL on another device, authenticate, and **read** mail from local SQLite — without shipping a public SaaS or blocking V2.0 tag.

---

*Page — checklist created 2026-08-25. Update as W1–W3 land.*
