// ==============================================================================
// File: lib/sync/pim_sync_jobs.dart
// Description: PIM sync job type constants and per-collection cursor key helpers.
// Component: Sync
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

/// String job types for contacts / calendars sync.
///
/// Bootstrap and incremental types are handled by [SyncEngine] for Graph
/// accounts (Wave 2). Push/copy remain no-ops until CRUD / Wave 6.
///
/// **Naming scheme:** `{collection}_{action}` where action is
/// `bootstrap` | `incremental` | `push` | `copy`.
/// Reserved push/copy names (`contacts_push`, `contacts_copy`, `events_push`,
/// `events_copy`) are also no-ops until CRUD / cross-collection copy waves.
///
/// ## Per-collection sync cursor keys
///
/// Stored in `sync_cursors.cursor_key` (reuse existing table; no new column):
///
/// | Collection | Cursor key |
/// | --- | --- |
/// | Contact list metadata | `pim:contact_list:{contactListId}` |
/// | Contacts within a list | `pim:contacts:{contactListId}` |
/// | Calendar metadata | `pim:calendar:{calendarId}` |
/// | Events within a calendar | `pim:events:{calendarId}` |
///
/// Use [folderId] = collection id (list/calendar id) when writing cursors so
/// account wipe and diagnostics stay aligned with mail folder cursors.
abstract final class PimSyncJobs {
  // Collection discovery / bootstrap
  static const String contactListsBootstrap = 'contact_lists_bootstrap';
  static const String contactListsIncremental = 'contact_lists_incremental';
  static const String contactsBootstrap = 'contacts_bootstrap';
  static const String contactsIncremental = 'contacts_incremental';
  static const String calendarsBootstrap = 'calendars_bootstrap';
  static const String calendarsIncremental = 'calendars_incremental';
  static const String eventsBootstrap = 'events_bootstrap';
  static const String eventsIncremental = 'events_incremental';

  /// Reserved: push local contact creates/updates (Wave 2+ / CRUD).
  static const String contactsPush = 'contacts_push';

  /// Reserved: cross-list / cross-account contact copy (Wave 6 DnD).
  static const String contactsCopy = 'contacts_copy';

  /// Reserved: push local event creates/updates (Wave 2+ / CRUD).
  static const String eventsPush = 'events_push';

  /// Reserved: cross-calendar / cross-account event copy (Wave 6 DnD).
  static const String eventsCopy = 'events_copy';

  /// All job types that [SyncEngine] must accept without throwing.
  static const Set<String> allRegistered = <String>{
    contactListsBootstrap,
    contactListsIncremental,
    contactsBootstrap,
    contactsIncremental,
    calendarsBootstrap,
    calendarsIncremental,
    eventsBootstrap,
    eventsIncremental,
    contactsPush,
    contactsCopy,
    eventsPush,
    eventsCopy,
  };

  /// Cursor key for contact-list metadata delta on [contactListId].
  static String contactListCursorKey(String contactListId) =>
      'pim:contact_list:$contactListId';

  /// Cursor key for contacts delta within [contactListId].
  static String contactsCursorKey(String contactListId) =>
      'pim:contacts:$contactListId';

  /// Cursor key for calendar metadata delta on [calendarId].
  static String calendarCursorKey(String calendarId) =>
      'pim:calendar:$calendarId';

  /// Cursor key for events delta within [calendarId].
  static String eventsCursorKey(String calendarId) => 'pim:events:$calendarId';
}
