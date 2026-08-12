// ==============================================================================
// File: lib/sync/graph_sync_recovery.dart
// Description: Graph delta/PIM cursor invalidation helpers (expired sync token).
// Component: Sync
// Version: 1.0 (Gold Master)
// Created: 2026-08-12
// Last Update: 2026-08-12
// ==============================================================================

import 'package:synesis/protocol/mail_provider.dart';

/// True when [error] indicates the Graph delta/sync token is no longer valid.
///
/// Microsoft Graph returns **410 Gone** or **400** with a *Sync token is expired*
/// message. Callers should clear the stored cursor and re-bootstrap (DEF-083).
bool isGraphExpiredSyncToken(ProtocolException error) {
  if (error.statusCode == 410) {
    return true;
  }
  if (error.statusCode == 400) {
    return error.message.toLowerCase().contains('sync token is expired');
  }
  return false;
}
