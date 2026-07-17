# ByteMail

Local-first Flutter email client for **Windows** and **Android**.

See [docs/SPEC.md](docs/SPEC.md) for the technical specification and [mockups](mockups) for the visual direction.

## Run

```bash
flutter pub get
flutter run -d windows
# or
flutter run -d android
```

### Microsoft Graph (with Entra OAuth)

```bash
flutter run -d windows --dart-define=BYTEMAIL_GRAPH_CLIENT_ID=YOUR_APP_CLIENT_ID
# optional tenant (defaults to common):
flutter run -d windows --dart-define=BYTEMAIL_GRAPH_CLIENT_ID=YOUR_APP_CLIENT_ID --dart-define=BYTEMAIL_GRAPH_TENANT=common
```

Without `BYTEMAIL_GRAPH_CLIENT_ID`, Add Account keeps the local Graph token-paste path for spike testing.

### Google OAuth (Gmail IMAP/SMTP)

```bash
flutter run -d windows --dart-define=BYTEMAIL_GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID
# optional client secret (some Desktop OAuth clients require it):
flutter run -d windows --dart-define=BYTEMAIL_GOOGLE_CLIENT_ID=YOUR_GOOGLE_CLIENT_ID --dart-define=BYTEMAIL_GOOGLE_CLIENT_SECRET=YOUR_SECRET
```

Without `BYTEMAIL_GOOGLE_CLIENT_ID`, the Google tab shows setup guidance; Gmail still works via the **IMAP / Other** tab with an app password.

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
- App passwords remain supported on the **IMAP / Other** tab for Gmail users who prefer that path.
- **Look up settings** on the IMAP tab uses Thunderbird ISPDB autoconfig; manual host/port entry still works when discovery fails.
- Do not commit client secrets; pass them only via `--dart-define` or local launch configs.

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

**Next wave (W5):** desktop shell — reading-pane layout, keymap, tray, `.eml`, Ctrl+F, detached message window. W4 compose remains the last feature wave after W5 and W6.

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
