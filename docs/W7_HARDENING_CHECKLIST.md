# Wave 7 Hardening Manual Checklist

> **Operator validation complete (2026-07-18); checkbox detail pending.** Gate satisfied per operator — individual checkboxes below may remain unticked until formal tick-off.

Manual smoke list for W7 hardening (Focus rules, auto-mark, appearance, encryption, widgets). **Automated coverage:** filter [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) with `wave=W7` (or see [TEST_INVENTORY.md](TEST_INVENTORY.md)); do not treat `evaluation_status=Cataloged` as Pass without a `flutter test` run.

**Wave status (2026-07-18):** **W7 landed** — core musts + TC-3 encryption shipped in code. **Operator inspection/validation complete**; checkbox tick-off in this file remains operator-owned.

## Setup

- Windows and/or Android AVD with at least one account (or demo data).
- Appearance sheet reachable from the shell.
- Encryption toggle requires restart after migrate — use a **throwaway** profile/passphrase for smoke.

## DEF-034 / UI-P27 — Auto-mark as read (5s)

**Code:** `AutoMarkAsReadController`, `reading_pane.dart`

- [ ] Open an **unread** message; wait ≥5s without changing selection → message marks read (list dim / unread badge).
- [ ] Open unread; change selection before 5s → stays unread.
- [ ] Already-read message → no mark-read churn.

## TC-4 — Focus override rules

**Code:** `focus_rules_sheet.dart`, `deleteFocusRule`

- [ ] Appearance → **Focus override rules** lists existing rules.
- [ ] Add sender rule → Always Focused; matching mail reclassifies.
- [ ] Add domain rule → Always Other.
- [ ] Delete a rule; list updates.

## UI-P16 / P17 / P18 — Themes, export, font

- [ ] Create a custom theme from a built-in base; select it; chrome colors change.
- [ ] Change UI font family / size scale; text updates app-wide.
- [ ] Export settings JSON (no credentials in file); import on a clean prefs state restores prefs + custom themes.

## UI-P6 / P8 — Density + empty states

- [ ] Toggle Calm / Compact; list padding and empty-state sizing change.
- [ ] Empty list / no selection / empty search / no accounts show shared empty-state copy (+ Add account CTA).

## TC-3 — DB encryption (opt-in)

**Code:** [W7_SQLCIPHER_SPIKE.md](W7_SQLCIPHER_SPIKE.md)

- [ ] Appearance → Encryption → enable with passphrase + acknowledge warning.
- [ ] Restart app; mailbox still opens with passphrase path.
- [ ] Wrong passphrase fails open (or app prompts) — document observed UX.
- [ ] Disable / decrypt path restores plaintext open (if exercised).

## TC-11 — Widget depth (Android, timeboxed)

- [ ] Home-screen widget shows unread count including Focused/Other split when both > 0.
- [ ] Widget colors follow active built-in theme tokens after sync refresh.

## Out of scope (do not fail W7)

- W4 compose checklist / marking W4 landed
- UI-P28 auto-mark delay/off settings
- Filter system / FW-* Final wave
- Graph large-attachment upload session (stretch)
- Folder-scoped widget configuration (deferred beyond timebox)
