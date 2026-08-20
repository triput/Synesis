# Mail hygiene digest (desktop CLI probe)

**Date:** 2026-08-19  
**Status:** **locked** (operator approved 2026-08-19). Implementation plan next session — do not start code until that plan exists.  
**Roadmap:** **Wave MH** — parallel to Android Pri-2 / Wave 7; not V2.0 critical path; does not skip Wave H2 before V2.1 product features.  
**Repo:** Synesis (`v2.0` at time of writing)  
**Intent:** Exploratory, read-only, multi-account digest so Trish can manage busy Gmail + Microsoft inboxes without staring at them. Same engine is a candidate public **desktop** differentiator later. Not on phone.

## Problem

Four or more accounts. Inboxes too busy to eyeball. Need: volume since last look, unread now, categories, “this actually needs me” vs “I’m on the thread but FYI,” plus a subscription/receipt landscape.

## Goals

- Manual trigger from this desktop (Cursor or terminal). No scheduler in v1.
- Cover **every mail account already configured in Synesis** (Gmail API + Microsoft Graph).
- Read-only. No labels, archive, send, or unsubscribe clicks.
- Markdown digest on disk (gitignored). Google Sheet is the money ledger.
- Classifier is a **library**. CLI is the first consumer. Later: desktop Synesis UI and optional actions. Phone does not ship this.

## Non-goals (this probe)

- Phone UI or extra mobile work.
- LLM classification.
- Notion persistence of digests.
- Emailing the digest to yourself.
- Applying mailbox writes even with confirmation.
- A public marketing “AI inbox” story. v1 is headers, categories, To/Cc, and receipt heuristics.
- Designing the Synesis **web client** (parked — see below).

## Architecture

Desktop-only CLI in this repo (e.g. `synesis digest` / `dart run` entrypoint that does **not** start the Flutter UI). Uses the same OAuth tokens Synesis already stores. Cursor is the trigger and a place to read output, not the mail protocol.

Flow:

1. Load all configured accounts. Refresh tokens the same way desktop Synesis does. If refresh fails for an account, record failure and continue.
2. For each account, read **Inbox + provider Focused/Important** (Graph focused inbox; Gmail Important when present). Ignore spam and trash for inbox hygiene.
3. Classify messages in the **inbox window**. Overlay money tags. Upsert money hits into the Sheet (money search may use All Mail minus spam/trash).
4. Write a timestamped markdown file plus a small local state file (`last_inbox_run`, `last_money_run` per account). State lives in the existing app-support / local data area, not in git.

Failed accounts do not abort the run.

## Time windows

| Pass | First run | Later runs |
| --- | --- | --- |
| Inbox received-in-window + exclusive buckets + urgent/personal lists | Last **30 days** | `min(since last successful inbox run, 30 days)` |
| Current unread | Now, Inbox + Focused/Important | Same |
| Money overlay + Sheet | Last **12 months** (All Mail minus spam/trash, receipt/sub heuristics) | Since last successful money run; **upsert** |

If a week is skipped, inbox classify still does not exceed 30 days. Unread is never windowed.

## Digest (markdown)

One file per run, timestamped, gitignored (path decided at implementation; never commit contents).

Header: run timestamp, accounts attempted, per-account failures with reason.

**Per account:**

- Received in window (Inbox + Focused/Important).
- Current unread (those folders).
- Exclusive bucket **counts** over the window.
- **Urgent** list: from, subject, date, stable message id (for a later jump-to in Synesis).
- **Personal, non-urgent** list: same shape.
- Money teaser: count of new/updated Sheet rows this run; top merchants. Ledger is the Sheet, not the markdown.

## Classification

### Exclusive bucket (first match wins)

1. **Urgent** — account’s addresses appear on To or Cc **and** any of: security/account-alert patterns; payment-failure / cutoff / dunning; legal-ish demand; explicit action ask (“please review”, “action required”, RSVP, signature); a parseable deadline in the near term **without** heroic NLP. A normal receipt/invoice is **not** urgent unless it looks like dunning/cutoff.
2. **Personal, non-urgent** — on To or Cc, not urgent, not treated as list mail.
3. **Newsletters** — `List-Unsubscribe` / `List-Id`, Gmail Promotions, mailing-list precedence.
4. **Social** — Gmail Social and/or known social sender domains (LinkedIn, Facebook, Instagram, Nextdoor, etc.).
5. **Other** — remainder.

Bcc-only: if the provider does not show the user on To/Cc, the message is **not** Personal or Urgent via this rule.

### Parallel overlay: `money`

Not a sixth exclusive bucket. A message may be Personal + money, Other + money, Urgent + money.

Signals: subject/snippet heuristics (receipt, invoice, order, billed, subscription, trial ends, upcoming charge), Gmail Purchases when present, known merchant patterns.

Confidence: `high` vs `maybe`. `maybe` still upserts with a Sheet column so it can be ignored.

Inbox-window money tags still occupy their exclusive bucket for counts; they also feed the Sheet. The 12-month money search can include mail that never sat in inbox.

## Google Sheet

One tab. Upsert key: normalized merchant + cadence guess + account email.

Columns: merchant, last_amount, currency, cadence (`monthly` / `annual` / `unknown`), last_seen, next_expected (from cadence when guess is not unknown), account, example_subject, message_date, confidence, source_account.

No full bodies in the Sheet.

Cadence guessing is in scope (loved). OAuth: add Sheets scope to the desktop Google client if required. If scope/consent is a mess, implementation may ship CSV upsert you paste into Sheets; product intent remains the Sheet.

## Privacy and secrets

- Mail APIs: read-only.
- Do not commit digests, state, Sheet IDs, or tokens.
- Follow existing `oauth_local.json` / `.secrets-backup/` rules if any file must be sanitized.
- No third-party “connect your IMAP to our cloud” product in this path.

## Testing (CI: fixtures only)

- Golden headers+snippets: exclusive buckets, money overlay, To/Cc, List-Unsubscribe, dunning vs receipt, social domains.
- Window math: first 30d inbox; cap 30d; money 12m then incremental.
- Sheet upsert: same merchant updates last_seen/amount; no duplicate rows.
- Gmail vs Graph fixtures stay isolated.
- One failed account does not drop others.
- No live mailboxes in CI.

## Public product (later, not this probe)

Local multi-account client + read-only hygiene + To/Cc urgency + subscription sheet is uncommon vs SaneBox (third-party digest of *hidden* mail), Hey Paper Trail (Hey-only receipts), Gmail tabs/subscription hub (Google-only), Spark/Shortwave/Forage (usually Gmail/cloud, often mutates), Rocket Money (not a mail client).

Ship later as a **desktop** report (then actions) on this library. Do not put it on the phone app.

## Parked: Synesis on the web

Operator is starting to want a **web version of the Synesis client**, without dropping local-first preferences. Out of scope here. Keeping the classifier as a library (no Flutter UI dependency) is the only accommodation in this design. Distinct from LiveBytes marketing/legal site (`docs/POST_V1_WEB_AND_LEGAL.md`).

## Success

On this desktop, running the desktop CLI (`digest`) produces a markdown file that matches how the inboxes feel, and a Sheet that starts looking like the subscription landscape. Wrong buckets are fixture bugs, not “add GPT.”

## Implementation notes (for the plan, not extra product)

- Confirm token storage and Gmail vs Graph list APIs already used by desktop sync; reuse, don’t fork a fourth mail stack.
- Add digest output + run-state globs to `.gitignore`.
- Phone flavor / Android / iOS targets must not compile or ship this CLI.
- Confirm before mutating pubspec, OAuth scopes, or terminal build commands (operator rule).
