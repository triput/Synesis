<p align="center">
  <img src="docs/branding/branding_logo_lockup_google.png" alt="bytemail" width="360" />
</p>

# ByteMail

Local-first Flutter email client for **Windows** and **Android**.

See [docs/SPEC.md](docs/SPEC.md) for the technical specification and [mockups](mockups) for the visual direction.

**Web (LiveBytes mothership):** marketing + Privacy + Terms live at `https://livebytes.net/bytemail/` — source in sibling [`../LiveBytes`](../LiveBytes) (`website/`, strategy docs). Thin backlog stubs: [`docs/POST_V1_WEB_AND_LEGAL.md`](docs/POST_V1_WEB_AND_LEGAL.md), [`docs/POST_V1_LIVEBYTES_WEB_STRATEGY.md`](docs/POST_V1_LIVEBYTES_WEB_STRATEGY.md).

## Documentation

| Doc | Audience |
| --- | --- |
| [SPEC.md](docs/SPEC.md) | Product & technical requirements |
| [ARCHITECTURE_OVERVIEW.md](docs/ARCHITECTURE_OVERVIEW.md) | How ByteMail works under the hood (no code required) |
| [**USER_GUIDE.md**](docs/USER_GUIDE.md) | End-user manual — accounts, filters, Focus, settings |
| [**QUICK_START.md**](docs/QUICK_START.md) | Short path to first sync |
| [**DART_IN_BYTEMAIL.md**](docs/DART_IN_BYTEMAIL.md) | Curious engineer tour — Dart/Flutter patterns in *this* repo |
| [AGENTS.md](AGENTS.md) | Multi-agent delivery workflow |
| [TEST_INVENTORY.md](docs/TEST_INVENTORY.md) | Automated test catalog |
| [V1_TIER_INTEGRATION.md](docs/V1_TIER_INTEGRATION.md) | Wave integration plan |
| [ROADMAP.md](docs/ROADMAP.md) | Milestones and exit gates |
| [FINAL_WAVE_PLAN.md](docs/FINAL_WAVE_PLAN.md) | V1 exit / release readiness (in progress) |

## Run

```bash
flutter pub get
flutter run -d windows
# or
flutter run -d android
```

### Microsoft Graph (with Entra OAuth)

**Normal path:** ByteMail ships its own Entra **public** client ID ([`lib/auth/oauth_public_clients.dart`](lib/auth/oauth_public_clients.dart)). End users only click **Sign in with Microsoft** — no digging for IDs.

**Overrides (dev / CI):** `--dart-define=BYTEMAIL_GRAPH_CLIENT_ID=…` → OS env → gitignored `oauth_local.json` (see [`oauth_local.json.example`](oauth_local.json.example)) → shipped defaults.

```bash
flutter run -d windows --dart-define=BYTEMAIL_GRAPH_CLIENT_ID=YOUR_APP_CLIENT_ID
# optional tenant (defaults to common):
flutter run -d windows --dart-define=BYTEMAIL_GRAPH_CLIENT_ID=YOUR_APP_CLIENT_ID --dart-define=BYTEMAIL_GRAPH_TENANT=common
```

If no Graph client ID is available from any source, Add Account keeps a token-paste spike path (not the dogfood path).

### Google OAuth (Gmail IMAP/SMTP)

Same model — shipped Google public client ID in `oauth_public_clients.dart`, with the same override chain.

```bash
flutter run -d windows --dart-define=BYTEMAIL_GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID
# optional client secret (some Desktop OAuth clients require it):
flutter run -d windows --dart-define=BYTEMAIL_GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID --dart-define=BYTEMAIL_GOOGLE_CLIENT_SECRET=YOUR_SECRET
```

Without a Google client ID from any source, the Google tab shows setup guidance; Gmail still works via the **IMAP / Other** tab with an app password.

### IMAP / Other

On the **IMAP / Other** tab, **Look up settings** queries the [Thunderbird Mozilla ISPDB](https://autoconfig.thunderbird.net/) (and the domain’s `/.well-known/autoconfig/mail/config-v1.1.xml` as a fallback) to autofill IMAP/SMTP host, port, and security hints. You can override every field; if lookup fails, enter settings manually and submit as usual.

## Microsoft Graph (Entra) setup

Register a **public client** (no client secret) in Microsoft Entra ID so ByteMail can run authorization code + PKCE in the system browser.

1. **Azure Portal → Microsoft Entra ID → App registrations → New registration**
   - Name: e.g. `ByteMail`
   - Supported account types: personal Microsoft accounts and/or work/school (match your needs; `common` tenant works for multi-tenant + personal)
   - Redirect URI: add later (or skip in the wizard and add both below)

2. **Authentication → Add platform**
   - **Mobile and desktop** (or custom):
     - `http://127.0.0.1:8765/callback` (Windows / desktop loopback)
     - `bytemail://auth` (Android deep link)
   - Enable **Allow public client flows** (device code / public client)

3. **API permissions → Microsoft Graph → Delegated**
   - `Mail.ReadWrite`
   - `Mail.Send`
   - `offline_access`
   - `openid`
   - `profile`
   - `User.Read`
   - Grant admin consent if your tenant requires it

4. **Copy the Application (client) ID** and run with dart-defines (never commit the ID into source if you treat the registration as private; public-client IDs are not secrets, but keep tenant policy in mind):

```bash
flutter run --dart-define=BYTEMAIL_GRAPH_CLIENT_ID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
# optional:
flutter run --dart-define=BYTEMAIL_GRAPH_CLIENT_ID=... --dart-define=BYTEMAIL_GRAPH_TENANT=common
```

Do **not** put client secrets in README, source, or dart-defines — this app is a public PKCE client only.

## Google OAuth setup

Register OAuth clients in Google Cloud Console so ByteMail can run authorization code + PKCE and use Gmail over IMAP/SMTP with XOAUTH2.

1. **Google Cloud Console → APIs & Services → OAuth consent screen**
   - Configure an External (or Internal) consent screen
   - Add scopes: `openid`, `email`, `profile`, `https://mail.google.com/`
   - Add test users while the app is in Testing

2. **Credentials → Create credentials → OAuth client ID**
   - **Desktop app** (Windows):
     - Authorized redirect URI: `http://127.0.0.1:8766/callback`
     - Copy the Client ID (and Client Secret if Google issues one for Desktop)
   - **Android** (optional, for device builds):
     - Package name and SHA-1 from your debug/release keystore
     - Redirect / custom scheme used by ByteMail: `bytemail://google-auth`
     - Ensure the Android intent filter for `bytemail` / `google-auth` is present (shipped in `AndroidManifest.xml`)

3. **Run with dart-defines**

```bash
flutter run -d windows \
  --dart-define=BYTEMAIL_GOOGLE_CLIENT_ID=xxxxxxxx.apps.googleusercontent.com \
  --dart-define=BYTEMAIL_GOOGLE_CLIENT_SECRET=optional-if-required
```

Both Graph and Google can be set together:

```bash
flutter run -d windows \
  --dart-define=BYTEMAIL_GRAPH_CLIENT_ID=... \
  --dart-define=BYTEMAIL_GOOGLE_CLIENT_ID=...
```

**Notes**

- Redirect ports/schemes are intentionally separate from Microsoft Graph (`8765` / `bytemail://auth`).
- **IMAP XOAUTH2** requires the consent-screen scope `https://mail.google.com/` (restricted). If sync fails with `AUTHENTICATIONFAILED` after Sign in with Google, add that scope on the consent screen, enable the Gmail API, turn on IMAP in the Gmail account, then remove the account in ByteMail and sign in again so consent is re-granted.
- App passwords remain supported on the **IMAP / Other** tab for Gmail users who prefer that path.
- **Look up settings** on the IMAP tab uses Thunderbird ISPDB autoconfig; manual host/port entry still works when discovery fails.
- Product builds ship public client IDs (and the Google Desktop client secret, which Google treats as non-confidential) via `lib/auth/oauth_public_clients.dart`. Overrides: dart-define / env / `oauth_local.json`.

## Current status (v0 shell + W0 platform base + W1 message actions + W2 list UX + W3 sync & privacy)

**W0 landed (2026-07-16)** — platform foundations and onboarding code paths:

| Capability | Status |
| --- | --- |
| Schema v5 | Drift migration with query/action columns and outbox/attachment/signature tables |
| `MessageQuery` | Composable list filters; default preserves pre-W0 inbox behavior |
| `MailProvider` mutations | Graph + IMAP star, move, delete, attachment list/fetch |
| MIME | `OutgoingEnvelope` + multipart builder in isolate |
| Microsoft Graph OAuth | PKCE browser flow when `BYTEMAIL_GRAPH_CLIENT_ID` is set |
| Google OAuth | PKCE + XOAUTH2 when `BYTEMAIL_GOOGLE_CLIENT_ID` is set |
| IMAP autoconfig | Thunderbird ISPDB + domain well-known lookup on Add Account |

**W1 landed (2026-07-17)** — reading-pane message actions and trash:

| Capability | Status |
| --- | --- |
| Reply / forward | Opens compose with `ComposePrefill` (thin envelope; full quote in W4) |
| Delete / archive / move / star | Optimistic local + provider sync; keyboard shortcuts on desktop |
| Trash + recover | Delete moves to trash; recover restores; trash folder view |
| Trash auto-purge | Configurable retention (default 30 days) in Appearance settings |
| Junk / not junk | Report junk and not-junk via role-folder move |

**W2 landed (2026-07-17)** — list & navigation UX:

| Capability | Status |
| --- | --- |
| Threading | Default threaded; flat toggle in Appearance; Graph `conversationId` + IMAP `References` |
| Filters + date groups | `MessageViewFilter` chip bar; Today/Yesterday/… section headers |
| Snooze + pin | **Local-only**; query exclusion; virtual sidebar views |
| Mobile gestures | Swipe right=archive / left=delete (configurable); pull-to-refresh |
| Reading-pane toolbar | Adaptive icon+label at ≥520px width |
| Unread recount | Folder badges from local SQLite |

**W3 landed (2026-07-17)** — sync, storage & privacy:

| Capability | Status |
| --- | --- |
| Sync profiles | `SyncProfile` with folder scope (roles/remoteIds), body policy, attachment max MB |
| Per-account retention | Override in Edit Account; retention dial updates default profile + enqueues cleanup |
| Sync status sheet | Jobs \| Accounts tabs; retry/cancel; title-bar sync chip + sync-now icon |
| Push / near-push | Graph delta + cursor; IMAP IDLE; network policy via `connectivity_plus`; `pushOnCellular` default off |
| Remote images | Block by default; per-message “Load images”; toggle in Appearance |

**Final wave (in progress, 2026-07-18):** Phases A–F **landed** (branding, saved list filters, FW-1…FW-6 docs cluster, W4/W7 operator validation). Phase G (FW-5 E2E finalize) + V1 exit **open**. See [FINAL_WAVE_PLAN.md](docs/FINAL_WAVE_PLAN.md) and [USER_GUIDE.md](docs/USER_GUIDE.md).

**Next:** Final wave Phase G (FW-5 E2E finalize) → [V1_EXIT_CHECKLIST.md](docs/V1_EXIT_CHECKLIST.md) sign-off. W4/W7 checkbox tick-off in checklist files remains operator-owned.

- Flutter project scaffolded for Android + Windows
- Module placeholders matching SPEC architecture (`account`, `auth`, `sync`, `repository`, …)
- Calm Dark jewel-tone UI shell with sample mail
- Microsoft Graph: Entra OAuth (PKCE) when `BYTEMAIL_GRAPH_CLIENT_ID` is set; token paste dev fallback otherwise
- Google: browser OAuth → Gmail IMAP/SMTP XOAUTH2 when `BYTEMAIL_GOOGLE_CLIENT_ID` is set; app passwords on IMAP tab otherwise
- Appearance sheet: theme id, Calm/Compact density, Unified + per-account Focus toggles

## Spec defaults

- Theme: Dark (jewel-tone)
- Density: Calm (Compact available in Appearance)
- Focused/Other: optional per account; Unified has its own setting
