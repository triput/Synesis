<p align="center">
  <img src="branding/branding_logo_lockup_google.png" alt="synesis" width="360" />
</p>

# Synesis Quick Start

Get from install to reading mail in a few minutes. For full feature detail see [USER_GUIDE.md](USER_GUIDE.md).

---

## 1. Install & run

**Prerequisites:** Flutter **3.44.6** / Dart **3.12.2** (repo pin: `.flutter-version`; `pubspec.yaml` `environment.sdk: ^3.12.2`).

```bash
flutter pub get
flutter run -d windows
# or
flutter run -d android
```

**Microsoft Graph:** pass your Entra app client ID. Wave 3+ PIM and RSVP/write require **`Contacts.Read`** and **`Calendars.ReadWrite`** on your Entra app; `Calendars.ReadWrite` supersedes the prior read-only calendar scope. Existing accounts must **re-sign in** through **Edit account → re-auth** after upgrade. See [README](../README.md#microsoft-graph-entra-setup).

```bash
flutter run -d windows --dart-define=SYNESIS_GRAPH_CLIENT_ID=YOUR_CLIENT_ID
```

**Google Gmail:** pass your OAuth client ID (optional secret if required). Wave G+ PIM requires **`contacts.readonly`** and **`calendar`** on your Google Cloud OAuth consent screen (plus enabled People + Calendar APIs). Existing accounts must **re-sign in** through **Edit account → Re-authenticate with Google** after upgrade. See [README](../README.md#google-oauth-setup).

```bash
flutter run -d windows --dart-define=SYNESIS_GOOGLE_CLIENT_ID=YOUR_CLIENT_ID
```

Setup steps for Entra and Google: [README.md](../README.md).

---

## 2. Add your first account

1. Launch Synesis — you should see the **synesis** wordmark and Data Envelope icon (not the Flutter logo).
2. Tap **Add account** in the title bar.
3. Pick **Microsoft**, **Google**, or **IMAP / Other** and complete sign-in or server details.
4. Wait for the first sync — the list fills from the local database; network sync continues in the background.

**Tip:** On IMAP / Other, try **Look up settings** before typing hostnames manually.

---

## 3. Read & send

- Select a folder or **Unified Inbox** in the sidebar.
- Click a message to read; use the reading-pane actions for reply, archive, star, etc.
- **Compose** from the title bar — add recipients, body, optional signature, send (queues offline if needed).

---

## 4. One settings tip

Open **Appearance** (palette icon):

- Pick **theme** and **density** (Calm vs Compact)
- Toggle **Focus** per account if you want Focused/Other triage
- Set **retention** and **sync profile** before adding many accounts

More settings (notifications, encryption, swipes, filters): [USER_GUIDE.md](USER_GUIDE.md).

---

## 5. Filters in 30 seconds

Above the message list: tap **Unread**, **Starred**, or **More** for sender/recipient/date/keyword. Tap **Saved** to apply or save a named preset. **Clear** removes the active filter without deleting saved presets.

---

## Next steps

| Goal | Read |
| --- | --- |
| Full user manual | [USER_GUIDE.md](USER_GUIDE.md) |
| How the code is organized | [DART_IN_SYNESIS.md](DART_IN_SYNESIS.md) |
| Product requirements | [SPEC.md](SPEC.md) |
| Release / wave status | [ROADMAP.md](ROADMAP.md) |

*Maintained by Page. Last updated: 2026-07-18.*
