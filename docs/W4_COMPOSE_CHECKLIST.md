# Wave 4 Compose Manual Checklist

> **Operator validation complete (2026-07-18); checkbox detail pending.** Gate satisfied per operator — individual checkboxes below may remain unticked until formal tick-off.

Manual smoke list for W4 unified compose on **Windows** and **Android AVD**. **Automated coverage:** filter [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) with `wave=W4` (or see [TEST_INVENTORY.md](TEST_INVENTORY.md)).

**Wave status (2026-07-18):** **W4 landed** — compose system **code landed** (`ComposeDraft`, `sendEnvelope`, attachments, signatures/templates, drafts, schedule send). **Operator inspection/validation complete**; checkbox tick-off in this file remains operator-owned.

## Setup

- At least one IMAP/SMTP and/or Graph account that can send.
- Title bar / compose affordance opens the compose sheet.
- Account edit → **Manage signatures** / **Manage templates** reachable.

## Envelope (TA-2)

- [ ] New message: To / Cc / Bcc (expand Cc/Bcc), Subject, body.
- [ ] Reply / Reply all / Forward open with quote + `Re:` / `Fw:` subject.
- [ ] Reply-all recipients exclude own address when headers present.
- [ ] Signature dropdown applies default; **No signature** works.
- [ ] Send delivers to real mailbox (Graph and/or IMAP).

## Attachments (TA-3)

- [ ] Paperclip stages files; chips show name/size; remove works.
- [ ] Over-cap attach blocked with clear error (sync profile attachment MB).
- [ ] Sent message arrives with image/PDF attachment.
- [ ] Reading pane lists inbound attachments; download saves a file.

## Rich text / templates / quick reply (TB-12/13)

- [ ] Bold / italic / link toolbar markers survive as HTML on send (or readable plain).
- [ ] Insert template from compose menu.
- [ ] Quick reply strip queues a reply and shows snackbar.

## Drafts + schedule (TB-6 / TC-10)

- [ ] Save draft / autosave → Outbox shows **Draft**; Edit restores fields.
- [ ] Schedule send → Outbox shows **Scheduled**; message does not send early.
- [ ] After due time + Sync, scheduled message sends.

## Signatures / images (UI-P20)

- [ ] Create HTML signature with optional image asset.
- [ ] Sent mail includes signature text/HTML (image embedded when added).

## W4 exit gate

Operator validation **complete (2026-07-18)** — W4 marked **landed** in status docs/plans. Formal checkbox tick-off in this file is **pending** (operator-owned). See [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md).
