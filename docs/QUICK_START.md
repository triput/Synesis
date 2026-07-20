<p align="center">
  <img src="branding/branding_logo_lockup_google.png" alt="bytemail" width="360" />
</p>

# ByteMail Quick Start

Get from install to reading mail in a few minutes. For full feature detail see [USER_GUIDE.md](USER_GUIDE.md).

---

## 1. Install & run

```bash
flutter pub get
flutter run -d windows
# or
flutter run -d android
```

**Microsoft Graph:** pass your Entra app client ID:

```bash
flutter run -d windows --dart-define=BYTEMAIL_GRAPH_CLIENT_ID=YOUR_CLIENT_ID
```

**Google Gmail:** pass your OAuth client ID (optional secret if required):

```bash
flutter run -d windows --dart-define=BYTEMAIL_GOOGLE_CLIENT_ID=YOUR_CLIENT_ID
```

Setup steps for Entra and Google: [README.md](../README.md).

---

## 2. Add your first account

1. Launch ByteMail — you should see the **bytemail** wordmark and Data Envelope icon (not the Flutter logo).
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
| How the code is organized | [DART_IN_BYTEMAIL.md](DART_IN_BYTEMAIL.md) |
| Product requirements | [SPEC.md](SPEC.md) |
| Release / wave status | [ROADMAP.md](ROADMAP.md) |

*Maintained by Page. Last updated: 2026-07-18.*
