// ==============================================================================
// File: lib/mailbox/thread_sent_enrichment.dart
// Description: Merge Sent-folder replies into conversation thread groups (DEF-055)
// Component: Mailbox / Domain
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'package:synesis/domain/models.dart';
import 'package:synesis/settings/app_settings_state.dart';

/// Pure helpers for DEF-055 sent-in-threads enrichment.
class ThreadSentEnrichment {
  const ThreadSentEnrichment._();

  /// Whether [folder] is a Sent / Sent Items mailbox (by role or name heuristic).
  static bool isSentFolder(MailFolder? folder) {
    if (folder == null) {
      return false;
    }
    final String role = (folder.role ?? '').trim().toLowerCase();
    if (role == 'sentitems' || role == 'sent') {
      return true;
    }
    if (role.isNotEmpty) {
      return false;
    }
    final String name = folder.name.trim().toLowerCase();
    return name == 'sent' ||
        name == 'sent items' ||
        name == 'sent mail' ||
        name == '[gmail]/sent mail';
  }

  /// Resolves the Sent folder for [accountId] from [folders], if present.
  static MailFolder? sentFolderForAccount(
    List<MailFolder> folders,
    String accountId,
  ) {
    MailFolder? roleMatch;
    MailFolder? nameMatch;
    for (final MailFolder folder in folders) {
      if (folder.accountId != accountId) {
        continue;
      }
      final String role = (folder.role ?? '').trim().toLowerCase();
      if (role == 'sentitems' || role == 'sent') {
        roleMatch = folder;
        break;
      }
      if (role.isEmpty && nameMatch == null) {
        final String name = folder.name.trim().toLowerCase();
        if (name == 'sent' ||
            name == 'sent items' ||
            name == 'sent mail' ||
            name == '[gmail]/sent mail') {
          nameMatch = folder;
        }
      }
    }
    return roleMatch ?? nameMatch;
  }

  /// True when Sent replies should be merged before thread projection.
  static bool shouldEnrich({
    required bool includeSentInThreads,
    required ThreadDisplayMode threadDisplayMode,
    required MailFolder? selectedFolder,
  }) {
    if (!includeSentInThreads) {
      return false;
    }
    if (threadDisplayMode != ThreadDisplayMode.threaded) {
      return false;
    }
    if (isSentFolder(selectedFolder)) {
      return false;
    }
    return true;
  }

  /// Collects effective thread ids per account from [messages].
  ///
  /// Keys are [MailMessage.accountId]; values are `(threadId ?? message.id)`.
  static Map<String, Set<String>> collectThreadKeysByAccount(
    List<MailMessage> messages,
  ) {
    final Map<String, Set<String>> byAccount = <String, Set<String>>{};
    for (final MailMessage message in messages) {
      final String threadKey = message.threadId ?? message.id;
      byAccount
          .putIfAbsent(message.accountId, () => <String>{})
          .add(threadKey);
    }
    return byAccount;
  }

  /// Filters [sentCandidates] to rows whose thread key is in [threadIds].
  static List<MailMessage> filterSentThreadMembers({
    required Iterable<MailMessage> sentCandidates,
    required Set<String> threadIds,
    required Set<String> existingMessageIds,
  }) {
    if (threadIds.isEmpty) {
      return const <MailMessage>[];
    }
    final List<MailMessage> matched = <MailMessage>[];
    for (final MailMessage message in sentCandidates) {
      if (existingMessageIds.contains(message.id)) {
        continue;
      }
      final String threadKey = message.threadId ?? message.id;
      if (threadIds.contains(threadKey)) {
        matched.add(message);
        existingMessageIds.add(message.id);
      }
    }
    return matched;
  }

  /// Appends [sentMembers] after [primary] without duplicating ids.
  static List<MailMessage> mergeSentThreadMembers({
    required List<MailMessage> primary,
    required Iterable<MailMessage> sentMembers,
  }) {
    if (sentMembers.isEmpty) {
      return primary;
    }
    final Set<String> seen = primary.map((MailMessage m) => m.id).toSet();
    final List<MailMessage> merged = List<MailMessage>.from(primary);
    for (final MailMessage message in sentMembers) {
      if (seen.add(message.id)) {
        merged.add(message);
      }
    }
    return merged;
  }
}
