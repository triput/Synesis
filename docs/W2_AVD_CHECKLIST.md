# Wave 2 AVD Manual Checklist (M5)

Short Android Emulator smoke list for pull-to-refresh, list swipes, threads, and portrait reading navigation.

## Setup

- Launch an Android emulator (API 34+ preferred) and run ByteMail with at least one synced account and a few inbox messages.
- Confirm Appearance → **Android swipe actions** defaults: swipe right = Archive, swipe left = Delete.

## Pull-to-refresh

- [ ] Open Inbox (or Unified Inbox) and pull down on the message list; spinner appears and list refreshes.
- [ ] Empty folder still allows pull-to-refresh (`AlwaysScrollableScrollPhysics`).
- [ ] After refresh, sync status / local rows reflect any new server mail (when online).

## Swipe actions

- [ ] Swipe right on a row archives (default); row leaves the inbox.
- [ ] Swipe left on a row deletes (moves to trash); row leaves the inbox.
- [ ] With multi-select active (long-press / checkbox), swipes are disabled.
- [ ] In Trash, delete swipe is disabled (permanent delete needs the confirm button/dialog).
- [ ] Remap swipe right → Star and swipe left → Snooze in Appearance; gestures match.
- [ ] Thread summary row swipe acts on the latest message in that thread.

## Thread expand

- [ ] Conversation view ON: expand a thread; children appear under the header.
- [ ] Collapse restores the summary row; selection still works.

## Portrait reading navigation

- [ ] Rotate / use portrait: open a message; chevrons show “N of M”.
- [ ] Swipe horizontally between adjacent projected messages (or use chevrons); selection stays in sync with the list.
- [ ] Vertical body scroll still works inside a page (no stuck scroll).
- [ ] Landscape / wide desktop layout does not force the portrait pager chrome.
