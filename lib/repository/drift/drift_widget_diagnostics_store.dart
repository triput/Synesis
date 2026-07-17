// ==============================================================================
// File: lib/repository/drift/drift_widget_diagnostics_store.dart
// Description: Widget snapshots, redacted diagnostics export, and demo seeding.
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sample_mailbox.dart';
import 'package:bytemail/repository/database.dart';
import 'package:bytemail/repository/drift/drift_account_folder_store.dart';
import 'package:bytemail/repository/drift/drift_message_store.dart';
import 'package:drift/drift.dart';

class DriftWidgetDiagnosticsStore {
  DriftWidgetDiagnosticsStore(
    this._database, {
    required void Function() notify,
    required DriftAccountFolderStore accounts,
    required DriftMessageStore messages,
  }) : _notify = notify,
       _accounts = accounts,
       _messages = messages;

  final ByteMailDatabase _database;
  final void Function() _notify;
  final DriftAccountFolderStore _accounts;
  final DriftMessageStore _messages;

  Future<void> upsertWidgetSnapshot(
    String id,
    String kind,
    String payloadJson,
  ) async {
    await _database
        .into(_database.widgetSnapshots)
        .insertOnConflictUpdate(
          WidgetSnapshotsCompanion.insert(
            id: id,
            kind: kind,
            payloadJson: payloadJson,
            updatedAt: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    _notify();
  }

  Future<String?> getWidgetSnapshot(String id) async {
    final WidgetSnapshot? row = await (_database.select(
      _database.widgetSnapshots,
    )..where((WidgetSnapshots table) => table.id.equals(id))).getSingleOrNull();
    return row?.payloadJson;
  }

  Future<String> exportDiagnosticsRedacted() async {
    final List<Account> accounts = await _database
        .select(_database.accounts)
        .get();
    final List<Job> jobs = await _database.select(_database.jobs).get();
    final List<OutboxData> outboxRows = await _database
        .select(_database.outbox)
        .get();
    return const JsonEncoder.withIndent('  ').convert(<String, Object>{
      'generatedAt': DateTime.now().toUtc().toIso8601String(),
      'accounts': accounts
          .map(
            (Account account) => <String, Object>{
              'id': account.id,
              'providerType': account.providerType,
              'storageType': account.storageType,
              'focusEnabled': account.focusEnabled,
            },
          )
          .toList(growable: false),
      'syncJobs': jobs
          .map(
            (Job job) => <String, Object>{
              'id': job.id,
              'accountId': job.accountId,
              'type': job.type,
              'status': job.status,
              'updatedAt': job.updatedAt,
              'hasCursor': job.cursorJson != null,
            },
          )
          .toList(growable: false),
      'outbox': outboxRows
          .map(
            (OutboxData item) => <String, Object>{
              'id': item.id,
              'accountId': item.accountId,
              'state': item.state,
              'attempts': item.attempts,
              'hasLastError': item.lastError != null,
              'createdAt': item.createdAt,
            },
          )
          .toList(growable: false),
    });
  }

  Future<void> seedDemoDataIfEmpty() async {
    final Expression<int> accountCountExpression = _database.accounts.id
        .count();
    final TypedResult accountCountResult = await (_database.selectOnly(
      _database.accounts,
    )..addColumns(<Expression<Object>>[accountCountExpression])).getSingle();
    final int accountCount =
        accountCountResult.read(accountCountExpression) ?? 0;
    if (accountCount != 0) {
      return;
    }
    await _database.transaction(() async {
      for (final MailAccount account in SampleMailbox.accounts) {
        await _accounts.upsertAccount(
          account,
          providerType: account.id == 'work' ? 'graph' : 'imap',
        );
        await _accounts.ensureFolder(account.id, '${account.id}-inbox');
      }
      final int now = DateTime.now().millisecondsSinceEpoch;
      for (int index = 0; index < SampleMailbox.messages.length; index++) {
        final MailMessage message = SampleMailbox.messages[index];
        final MailMessage timestamped = MailMessage(
          id: message.id,
          accountId: message.accountId,
          fromName: message.fromName,
          fromAddress: message.fromAddress,
          subject: message.subject,
          snippet: message.snippet,
          body: message.body,
          whenLabel: message.whenLabel,
          bucket: message.bucket,
          unread: message.unread,
          whenEpochMs: now - Duration(hours: index * 8).inMilliseconds,
          starred: false,
          isDraft: false,
        );
        await _messages.upsertMessages(<MailMessage>[
          timestamped,
        ], folderId: MailFolder.inboxId(message.accountId));
      }
    });
    _notify();
  }
}
