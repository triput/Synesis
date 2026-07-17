# ByteMail V1 Exit Checklist

Use this checklist to verify the SPEC milestone exits before the v1 release.

**Work order to reach sign-off:** feature waves W2–W7, remaining [Planned backlog](ROADMAP.md#planned-backlog-post-foundation) items, then the [Final wave (V1 exit / release readiness)](ROADMAP.md#final-wave-v1-exit--release-readiness) in [ROADMAP.md](ROADMAP.md) (refactor → coverage → user docs + doc sweep → manual E2E matrix → reusable multi-agent system prompt playbook, **FW-6**).

## M0 — Planning + BLoC foundation
- [ ] Application shell uses BLoC/Cubit state only.
- [ ] Settings persist across restart.
- [ ] `flutter analyze` and tests pass.

## M1 — Local data plane
- [ ] Cold start renders mailbox data from SQLite.
- [ ] Mailbox state restores offline after restart.

## M2 — Dual protocol thin spike
- [ ] Graph account imports message headers into SQLite.
- [ ] IMAP account imports message headers into SQLite.

## M3 — Sync engine deepen
- [ ] Sync jobs and cursors survive restart.
- [ ] Incremental catch-up works for both providers.

## M4 — Compose / outbox / send
- [ ] Offline compose is durable.
- [ ] Reconnect sends queued messages or reports actionable failure.

## M5 — Search
- [ ] FTS search works offline.
- [ ] Remote search results are ingested under the documented contract.

## M6 — Optional Focus
- [ ] Focused/Other behavior meets SPEC §8.3.
- [ ] Focus rules and overrides have automated tests.

## M7 — Retention & sync profiles
- [ ] Retention job uses `retention_cleanup` and a configured day count.
- [ ] Cleanup removes only cached, unpinned messages.
- [ ] Pins survive all supported retention windows.

## M8 — Appearance completeness
- [ ] All five theme selectors are usable.
- [ ] Account color selection is available.

## M9 — Android widgets
- [ ] List, unread counter, and actions have fresh JSON snapshots.
- [ ] Kotlin widget renders the shared snapshot without starting Flutter.
- [ ] Widget refresh is validated after a successful sync commit.

## M10 — Windows desktop polish
- [ ] Minimize-to-tray preference is persisted and wired to a Windows adapter.
- [ ] New-mail toast provider is wired and exercised on Windows.
- [ ] Ctrl+J/K/N/F keyboard shortcuts work when enabled; letter keys type normally in compose/search fields.

## M11 — Hardening & v1 gate
- [ ] Diagnostics exports contain no credentials, cursors, recipients, or message content.
- [ ] Account wipe requires account-specific confirmation.
- [ ] Performance targets are measured against representative mailboxes.
- [ ] Full SPEC acceptance review is complete.
