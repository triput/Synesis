// ==============================================================================
// File: test/thread_sent_enrichment_test.dart
// Description: Unit tests for DEF-055 sent-in-threads enrichment helpers
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'package:synesis/domain/models.dart';
import 'package:synesis/mailbox/thread_sent_enrichment.dart';
import 'package:synesis/settings/app_settings_state.dart';
import 'package:flutter_test/flutter_test.dart';

MailMessage _msg({
  required String id,
  required String accountId,
  String? threadId,
  String folderId = 'inbox-work',
  int? whenEpochMs,
}) {
  return MailMessage(
    id: id,
    accountId: accountId,
    fromName: 'Alice',
    fromAddress: 'alice@byte.io',
    subject: id,
    snippet: 's',
    body: 'b',
    whenLabel: '10:00',
    bucket: FocusBucket.focused,
    folderId: folderId,
    threadId: threadId,
    whenEpochMs: whenEpochMs,
  );
}

void main() {
  group('ThreadSentEnrichment.shouldEnrich', () {
    test('disabled when toggle off, flat mode, or Sent folder', () {
      const MailFolder sent = MailFolder(
        id: 'sent-work',
        accountId: 'work',
        name: 'Sent',
        remoteId: 'Sent',
        role: 'sentitems',
      );

      expect(
        ThreadSentEnrichment.shouldEnrich(
          includeSentInThreads: false,
          threadDisplayMode: ThreadDisplayMode.threaded,
          selectedFolder: null,
        ),
        isFalse,
      );
      expect(
        ThreadSentEnrichment.shouldEnrich(
          includeSentInThreads: true,
          threadDisplayMode: ThreadDisplayMode.flat,
          selectedFolder: null,
        ),
        isFalse,
      );
      expect(
        ThreadSentEnrichment.shouldEnrich(
          includeSentInThreads: true,
          threadDisplayMode: ThreadDisplayMode.threaded,
          selectedFolder: sent,
        ),
        isFalse,
      );
      expect(
        ThreadSentEnrichment.shouldEnrich(
          includeSentInThreads: true,
          threadDisplayMode: ThreadDisplayMode.threaded,
          selectedFolder: null,
        ),
        isTrue,
      );
    });
  });

  group('ThreadSentEnrichment.merge and filter', () {
    test('mergeSentThreadMembers dedupes by message id', () {
      final MailMessage inbox = _msg(id: 'in', accountId: 'work', threadId: 't1');
      final MailMessage sent = _msg(
        id: 'out',
        accountId: 'work',
        threadId: 't1',
        folderId: 'sent-work',
      );

      final List<MailMessage> merged = ThreadSentEnrichment.mergeSentThreadMembers(
        primary: <MailMessage>[inbox],
        sentMembers: <MailMessage>[sent, inbox],
      );

      expect(merged, hasLength(2));
      expect(merged.map((MailMessage m) => m.id).toList(), <String>['in', 'out']);
    });

    test('filterSentThreadMembers skips unmatched and duplicate ids', () {
      final Set<String> existing = <String>{'in'};
      final List<MailMessage> matched =
          ThreadSentEnrichment.filterSentThreadMembers(
        sentCandidates: <MailMessage>[
          _msg(id: 'in', accountId: 'work', threadId: 't1', folderId: 'sent-work'),
          _msg(id: 'out', accountId: 'work', threadId: 't1', folderId: 'sent-work'),
          _msg(id: 'solo', accountId: 'work', threadId: 't2', folderId: 'sent-work'),
        ],
        threadIds: <String>{'t1'},
        existingMessageIds: existing,
      );

      expect(matched.map((MailMessage m) => m.id).toList(), <String>['out']);
      expect(existing, <String>{'in', 'out'});
    });

    test('collectThreadKeysByAccount scopes by account', () {
      final Map<String, Set<String>> keys =
          ThreadSentEnrichment.collectThreadKeysByAccount(<MailMessage>[
        _msg(id: 'a', accountId: 'work', threadId: 'shared'),
        _msg(id: 'b', accountId: 'personal', threadId: 'shared'),
        _msg(id: 'solo', accountId: 'work'),
      ]);

      expect(keys['work'], <String>{'shared', 'solo'});
      expect(keys['personal'], <String>{'shared'});
    });
  });

  group('ThreadSentEnrichment.sentFolderForAccount', () {
    test('prefers role sentitems over name heuristic', () {
      const List<MailFolder> folders = <MailFolder>[
        MailFolder(
          id: 'custom-work',
          accountId: 'work',
          name: 'Sent',
          remoteId: 'custom',
        ),
        MailFolder(
          id: 'sent-work',
          accountId: 'work',
          name: 'Sent Items',
          remoteId: 'SentItems',
          role: 'sentitems',
        ),
      ];

      expect(
        ThreadSentEnrichment.sentFolderForAccount(folders, 'work')?.id,
        'sent-work',
      );
    });
  });
}
