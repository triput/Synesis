// ==============================================================================
// File: lib/repository/drift/drift_outbox_store.dart
// Description: Drift persistence for outbox CRUD and queue counts.
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/repository/database.dart';
import 'package:bytemail/repository/drift/drift_mappers.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/outbox/outbox_recipients.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

class DriftOutboxStore {
  DriftOutboxStore(
    this._database, {
    required void Function() notify,
  }) : _notify = notify;

  final ByteMailDatabase _database;
  final void Function() _notify;
  final Uuid _uuid = const Uuid();

  Future<int> countQueuedOutbox() async {
    final Expression<int> count = _database.outbox.id.count();
    final TypedResult result =
        await (_database.selectOnly(_database.outbox)
              ..addColumns(<Expression<Object>>[count])
              ..where(
                _database.outbox.state.isIn(<String>['queued', 'sending']),
              ))
            .getSingle();
    return result.read(count) ?? 0;
  }

  Future<int> countFailedOutbox() async {
    final Expression<int> count = _database.outbox.id.count();
    final TypedResult result =
        await (_database.selectOnly(_database.outbox)
              ..addColumns(<Expression<Object>>[count])
              ..where(_database.outbox.state.equals('failed')))
            .getSingle();
    return result.read(count) ?? 0;
  }

  Future<String> enqueueOutbox({
    required String accountId,
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
    String composeMode = 'new',
    String? inReplyTo,
    String? referencesJson,
    String? attachmentRefsJson,
    String? signatureId,
    int? sendAfter,
    String state = 'queued',
  }) async {
    final String id = _uuid.v4();
    final List<String> toList = _recipientListForStorage(to);
    final List<String> ccList = _recipientListForStorage(cc);
    final List<String> bccList = _recipientListForStorage(bcc);
    _validateOutboxState(state);
    await _database
        .into(_database.outbox)
        .insert(
          OutboxCompanion.insert(
            id: id,
            accountId: accountId,
            recipientsJson: jsonEncode(toList),
            subject: subject,
            body: body,
            state: state,
            createdAt: DateTime.now().millisecondsSinceEpoch,
            ccJson: Value<String?>(
              ccList.isEmpty ? null : jsonEncode(ccList),
            ),
            bccJson: Value<String?>(
              bccList.isEmpty ? null : jsonEncode(bccList),
            ),
            composeMode: Value<String>(composeMode),
            inReplyTo: Value<String?>(inReplyTo),
            referencesJson: Value<String?>(referencesJson),
            attachmentRefsJson: Value<String?>(attachmentRefsJson),
            signatureId: Value<String?>(signatureId),
            sendAfter: Value<int?>(sendAfter),
          ),
        );
    _notify();
    return id;
  }

  Future<void> updateOutboxContent(
    String id, {
    String? to,
    String? subject,
    String? body,
    String? cc,
    String? bcc,
    String? composeMode,
    String? inReplyTo,
    String? referencesJson,
    String? attachmentRefsJson,
    String? signatureId,
    int? sendAfter,
    bool clearSendAfter = false,
  }) async {
    await (_database.update(
      _database.outbox,
    )..where((Outbox table) => table.id.equals(id))).write(
      OutboxCompanion(
        recipientsJson: to == null
            ? const Value<String>.absent()
            : Value<String>(jsonEncode(_recipientListForStorage(to))),
        subject: subject == null
            ? const Value<String>.absent()
            : Value<String>(subject),
        body: body == null ? const Value<String>.absent() : Value<String>(body),
        ccJson: cc == null
            ? const Value<String?>.absent()
            : Value<String?>(
                () {
                  final List<String> list = _recipientListForStorage(cc);
                  return list.isEmpty ? null : jsonEncode(list);
                }(),
              ),
        bccJson: bcc == null
            ? const Value<String?>.absent()
            : Value<String?>(
                () {
                  final List<String> list = _recipientListForStorage(bcc);
                  return list.isEmpty ? null : jsonEncode(list);
                }(),
              ),
        composeMode: composeMode == null
            ? const Value<String>.absent()
            : Value<String>(composeMode),
        inReplyTo: inReplyTo == null
            ? const Value<String?>.absent()
            : Value<String?>(inReplyTo),
        referencesJson: referencesJson == null
            ? const Value<String?>.absent()
            : Value<String?>(referencesJson),
        attachmentRefsJson: attachmentRefsJson == null
            ? const Value<String?>.absent()
            : Value<String?>(attachmentRefsJson),
        signatureId: signatureId == null
            ? const Value<String?>.absent()
            : Value<String?>(signatureId),
        sendAfter: clearSendAfter
            ? const Value<int?>(null)
            : (sendAfter == null
                ? const Value<int?>.absent()
                : Value<int?>(sendAfter)),
      ),
    );
    _notify();
  }

  Future<List<OutboxItem>> listOutbox() async {
    final List<OutboxData> rows =
        await (_database.select(_database.outbox)
              ..orderBy(<OrderingTerm Function(Outbox)>[
                (Outbox table) => OrderingTerm.desc(table.createdAt),
              ]))
            .get();
    return rows.map(outboxFromRow).toList(growable: false);
  }

  Future<void> updateOutboxState(
    String id,
    String state, {
    String? error,
  }) async {
    _validateOutboxState(state);
    await (_database.update(
      _database.outbox,
    )..where((Outbox table) => table.id.equals(id))).write(
      OutboxCompanion(
        state: Value<String>(state),
        attempts: state == 'sending'
            ? const Value<int>.absent()
            : const Value<int>.absent(),
        lastError: Value<String?>(error),
      ),
    );
    if (state == 'sending') {
      await _database.customStatement(
        'UPDATE outbox SET attempts = attempts + 1 WHERE id = ?',
        <Object>[id],
      );
    }
    _notify();
  }

  Future<void> deleteOutbox(String id) async {
    await (_database.delete(
      _database.outbox,
    )..where((Outbox table) => table.id.equals(id))).go();
    _notify();
  }

  Future<int> deleteOutboxInStates(Iterable<String> states) async {
    final List<String> allowed = states
        .map((String state) => state.trim())
        .where((String state) => state.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (allowed.isEmpty) {
      return 0;
    }
    for (final String state in allowed) {
      _validateOutboxState(state);
    }
    final int deleted =
        await (_database.delete(
          _database.outbox,
        )..where((Outbox table) => table.state.isIn(allowed))).go();
    if (deleted > 0) {
      _notify();
    }
    return deleted;
  }

  Future<int> reclaimSendingOutbox() async {
    final int changed =
        await (_database.update(
          _database.outbox,
        )..where((Outbox table) => table.state.equals('sending'))).write(
          const OutboxCompanion(
            state: Value<String>('queued'),
          ),
        );
    if (changed > 0) {
      _notify();
    }
    return changed;
  }

  List<String> _recipientListForStorage(String? raw) {
    if (raw == null) {
      return const <String>[];
    }
    final String trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return const <String>[];
    }
    final List<String> parsed = splitOutboxRecipients(trimmed);
    if (parsed.isNotEmpty) {
      return parsed;
    }
    return <String>[trimmed];
  }

  void _validateOutboxState(String state) {
    const Set<String> valid = <String>{
      'queued',
      'sending',
      'sent',
      'failed',
      'draft',
    };
    if (!valid.contains(state)) {
      throw ArgumentError.value(state, 'state', 'Unsupported outbox state.');
    }
  }
}
