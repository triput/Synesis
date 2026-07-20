// ==============================================================================
// File: lib/repository/drift/drift_focus_store.dart
// Description: Drift persistence for focus rules and bucket reclassification.
// Component: Repository / Data
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/database.dart' hide FocusRule;
import 'package:bytemail/repository/drift/drift_mappers.dart';
import 'package:drift/drift.dart';

class DriftFocusStore {
  DriftFocusStore(
    this._database, {
    required void Function() notify,
  }) : _notify = notify;

  final ByteMailDatabase _database;
  final void Function() _notify;

  Future<List<FocusRule>> listFocusRules({String? accountId}) async {
    final query = _database.select(_database.focusRules);
    if (accountId != null) {
      query.where(
        (FocusRules table) =>
            table.accountId.equals(accountId) | table.accountId.isNull(),
      );
    }
    final rows = await query.get();
    return rows
        .map(
          (row) => FocusRule(
            id: row.id,
            accountId: row.accountId,
            pattern: row.pattern,
            matchType: FocusRuleMatchType.values.byName(row.matchType),
            bucket: FocusBucket.values.byName(row.bucket),
          ),
        )
        .toList(growable: false);
  }

  Future<void> upsertFocusRule(FocusRule rule) async {
    await _database
        .into(_database.focusRules)
        .insertOnConflictUpdate(
          FocusRulesCompanion.insert(
            id: rule.id,
            accountId: Value<String?>(rule.accountId),
            pattern: rule.pattern.trim(),
            matchType: rule.matchType.name,
            bucket: rule.bucket.name,
          ),
        );
    _notify();
  }

  Future<void> deleteFocusRule(String id) async {
    await (_database.delete(
      _database.focusRules,
    )..where((FocusRules table) => table.id.equals(id))).go();
    _notify();
  }

  Future<int> reclassifyFocusBuckets(
    FocusBucket Function(MailMessage message) score,
  ) async {
    final List<Message> rows = await _database.select(_database.messages).get();
    if (rows.isEmpty) {
      return 0;
    }
    int changed = 0;
    await _database.transaction(() async {
      for (final Message row in rows) {
        final MailMessage message = messageFromRow(row);
        final FocusBucket next = score(message);
        if (next.name == row.focusBucket) {
          continue;
        }
        await (_database.update(_database.messages)
              ..where((Messages table) => table.id.equals(row.id)))
            .write(MessagesCompanion(focusBucket: Value<String>(next.name)));
        changed += 1;
      }
    });
    if (changed > 0) {
      _notify();
    }
    return changed;
  }
}
