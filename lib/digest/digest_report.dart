// ==============================================================================
// File: lib/digest/digest_report.dart
// Description: Markdown digest report builder skeleton (Wave MH slice 1).
// Component: Digest / Output
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'package:synesis/digest/digest_bucket.dart';
import 'package:synesis/digest/digest_classification.dart';
import 'package:synesis/digest/digest_message.dart';

/// Builds a read-only markdown summary from classified header rows.
class DigestReportBuilder {
  const DigestReportBuilder();

  String build({
    required DateTime runAt,
    required List<DigestMessage> messages,
    required Map<String, DigestClassification> classifications,
    List<String> failedAccounts = const <String>[],
  }) {
    final StringBuffer buffer = StringBuffer()
      ..writeln('# Synesis mail hygiene digest')
      ..writeln()
      ..writeln('- Run: ${runAt.toUtc().toIso8601String()}')
      ..writeln('- Accounts attempted: ${_accountIds(messages).length}')
      ..writeln('- Messages classified: ${messages.length}');
    if (failedAccounts.isNotEmpty) {
      buffer.writeln('- Failures: ${failedAccounts.join(', ')}');
    }
    buffer.writeln();

    for (final String accountId in _accountIds(messages)) {
      final List<DigestMessage> accountMessages = messages
          .where((DigestMessage message) => message.accountId == accountId)
          .toList(growable: false);
      buffer
        ..writeln('## Account $accountId')
        ..writeln()
        ..writeln(
          '- Received in window: ${accountMessages.length}',
        );
      for (final DigestBucket bucket in DigestBucket.values) {
        final int count = accountMessages.where((DigestMessage message) {
          return classifications[message.id]?.bucket == bucket;
        }).length;
        buffer.writeln('- ${bucket.name}: $count');
      }
      buffer.writeln();
      _writeList(
        buffer,
        title: 'Urgent',
        accountMessages: accountMessages,
        classifications: classifications,
        bucket: DigestBucket.urgent,
      );
      _writeList(
        buffer,
        title: 'Personal, non-urgent',
        accountMessages: accountMessages,
        classifications: classifications,
        bucket: DigestBucket.personalNonUrgent,
      );
    }
    return buffer.toString();
  }

  List<String> _accountIds(List<DigestMessage> messages) {
    final Set<String> ids = <String>{};
    for (final DigestMessage message in messages) {
      ids.add(message.accountId);
    }
    final List<String> sorted = ids.toList(growable: false)..sort();
    return sorted;
  }

  void _writeList(
    StringBuffer buffer, {
    required String title,
    required List<DigestMessage> accountMessages,
    required Map<String, DigestClassification> classifications,
    required DigestBucket bucket,
  }) {
    buffer.writeln('### $title');
    final List<DigestMessage> rows = accountMessages
        .where((DigestMessage message) {
          return classifications[message.id]?.bucket == bucket;
        })
        .toList(growable: false);
    if (rows.isEmpty) {
      buffer.writeln('_None_');
      buffer.writeln();
      return;
    }
    for (final DigestMessage message in rows) {
      final String when = message.receivedAt?.toIso8601String() ?? 'unknown-date';
      buffer.writeln(
        '- ${message.fromName} — ${message.subject} ($when, id=${message.id})',
      );
    }
    buffer.writeln();
  }
}
