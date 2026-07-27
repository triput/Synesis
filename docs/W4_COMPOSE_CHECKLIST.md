# Wave 4 Compose Manual Checklist

> **Operator signed off (2026-07-22).** Validation completed earlier (2026-07-18); formal checkbox tick-off recorded here.

Manual smoke list for W4 unified compose on **Windows** and **Android AVD**. **Automated coverage:** filter [`V1_AUTOMATED_TEST_INVENTORY.csv`](V1_AUTOMATED_TEST_INVENTORY.csv) with `wave=W4` (or see [TEST_INVENTORY.md](TEST_INVENTORY.md)).

**Wave status (2026-07-22):** **W4 landed** — compose system **code landed** (`ComposeDraft`, `sendEnvelope`, attachments, signatures/templates, drafts, schedule send). **Operator inspection/validation complete**; checkboxes below **signed off**.

## Setup

- At least one IMAP/SMTP and/or Graph account that can send.
- Title bar / compose affordance opens the compose sheet.
- Account edit → **Manage signatures** / **Manage templates** reachable.

## Envelope (TA-2)

- [x] New message: To / Cc / Bcc (expand Cc/Bcc), Subject, body.
- [x] Reply / Reply all / Forward open with quote + `Re:` / `Fw:` subject.
- [x] Reply-all recipients exclude own address when headers present.
- [x] Signature dropdown applies default; **No signature** works.
- [x] Send delivers to real mailbox (Graph and/or IMAP).

## Attachments (TA-3)

- [x] Paperclip stages files; chips show name/size; remove works.
- [x] Over-cap attach blocked with clear error (sync profile attachment MB).
- [x] Sent message arrives with image/PDF attachment.
- [x] Reading pane lists inbound attachments; download saves a file.

## Rich text / templates / quick reply (TB-12/13)

- [x] Bold / italic / link toolbar markers survive as HTML on send (or readable plain).
- [x] Insert template from compose menu.
- [x] Quick reply strip queues a reply and shows snackbar.

## Drafts + schedule (TB-6 / TC-10)

- [x] Save draft / autosave → Outbox shows **Draft**; Edit restores fields.
- [x] Schedule send → Outbox shows **Scheduled**; message does not send early.
- [x] After due time + Sync, scheduled message sends.

## Signatures / images (UI-P20)

- [x] Create HTML signature with optional image asset.
- [x] Sent mail includes signature text/HTML (image embedded when added).

## W4 exit gate

Operator validation **complete (2026-07-18)**; formal checkbox tick-off **signed off (2026-07-22)**. W4 marked **landed**. See [V1_TIER_INTEGRATION.md](V1_TIER_INTEGRATION.md).
