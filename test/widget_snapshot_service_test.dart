// ==============================================================================
// File: test/widget_snapshot_service_test.dart
// Description: Unit tests for Android widget snapshot JSON payloads (DEF-044).
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/query/message_query.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/widgets/widget_snapshot_service.dart';

class _RecordingRepo implements MailRepository {
  final List<MailAccount> accounts;
  final List<MailFolder> folders;
  final List<MailMessage> messages;
  final Map<String, String> snapshots = <String, String>{};

  _RecordingRepo({
    required this.accounts,
    required this.folders,
    required this.messages,
  });

  @override
  Future<List<MailAccount>> listAccounts() async => accounts;

  @override
  Future<List<MailFolder>> listFolders({String? accountId}) async {
    if (accountId == null) {
      return folders;
    }
    return folders
        .where((MailFolder folder) => folder.accountId == accountId)
        .toList(growable: false);
  }

  @override
  Future<List<MailMessage>> listMessages(MessageQuery query) async {
    return query.apply(messages);
  }

  @override
  Future<void> upsertWidgetSnapshot(
    String id,
    String kind,
    String payloadJson,
  ) async {
    snapshots[id] = payloadJson;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WidgetSnapshotService.encodeListPayload', () {
    test('includes message rows with unread and folder metadata', () {
      final String payload = WidgetSnapshotService.encodeListPayload(
        messages: const <MailMessage>[
          MailMessage(
            id: 'm1',
            accountId: 'work',
            fromName: 'Maya Chen',
            fromAddress: 'maya@byte.io',
            subject: 'Quarterly review',
            snippet: 'Please review attached deck.',
            body: 'Body',
            whenLabel: '10:14',
            bucket: FocusBucket.focused,
            unread: true,
            folderId: 'inbox-work',
          ),
        ],
        accountId: 'work',
        accountLabel: 'Work',
        folderId: 'inbox-work',
        folderName: 'Inbox',
      );

      final Map<String, dynamic> decoded =
          jsonDecode(payload) as Map<String, dynamic>;
      expect(decoded['accountId'], 'work');
      expect(decoded['accountLabel'], 'Work');
      expect(decoded['folderId'], 'inbox-work');
      expect(decoded['folderName'], 'Inbox');
      final List<Object?> rows = decoded['messages'] as List<Object?>;
      expect(rows, hasLength(1));
      final Map<String, dynamic> row = rows.first as Map<String, dynamic>;
      expect(row['id'], 'm1');
      expect(row['from'], 'Maya Chen');
      expect(row['subject'], 'Quarterly review');
      expect(row['snippet'], 'Please review attached deck.');
      expect(row['unread'], isTrue);
      expect(row['when'], '10:14');
      expect(row['folderId'], 'inbox-work');
    });
  });

  group('WidgetSnapshotService.refreshAccountLists', () {
    test('writes per-account inbox snapshots with newest rows first', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final _RecordingRepo repo = _RecordingRepo(
        accounts: const <MailAccount>[
          MailAccount(
            id: 'work',
            label: 'Work',
            address: 'work@byte.io',
            accent: Color(0xFF2DD4BF),
          ),
          MailAccount(
            id: 'home',
            label: 'Home',
            address: 'home@byte.io',
            accent: Color(0xFF6366F1),
          ),
        ],
        folders: const <MailFolder>[
          MailFolder(
            id: 'inbox-work',
            accountId: 'work',
            name: 'Inbox',
            remoteId: 'INBOX',
            role: 'inbox',
            unreadCount: 2,
          ),
          MailFolder(
            id: 'inbox-home',
            accountId: 'home',
            name: 'Inbox',
            remoteId: 'INBOX',
            role: 'inbox',
            unreadCount: 1,
          ),
        ],
        messages: <MailMessage>[
          MailMessage(
            id: 'w-old',
            accountId: 'work',
            fromName: 'Old',
            fromAddress: 'old@byte.io',
            subject: 'Older',
            snippet: 'Old mail',
            body: 'Body',
            whenLabel: 'Mon',
            bucket: FocusBucket.other,
            folderId: 'inbox-work',
            whenEpochMs: 1000,
          ),
          MailMessage(
            id: 'w-new',
            accountId: 'work',
            fromName: 'New',
            fromAddress: 'new@byte.io',
            subject: 'Newest',
            snippet: 'Fresh mail',
            body: 'Body',
            whenLabel: 'Tue',
            bucket: FocusBucket.focused,
            unread: true,
            folderId: 'inbox-work',
            whenEpochMs: 2000,
          ),
          MailMessage(
            id: 'h-1',
            accountId: 'home',
            fromName: 'Friend',
            fromAddress: 'friend@byte.io',
            subject: 'Hello',
            snippet: 'Ping',
            body: 'Body',
            whenLabel: 'Wed',
            bucket: FocusBucket.focused,
            folderId: 'inbox-home',
            whenEpochMs: 3000,
          ),
        ],
      );

      final WidgetSnapshotService service = WidgetSnapshotService(repo);
      await service.refreshAccountLists();

      final String workKey = WidgetSnapshotService.accountListSnapshotId(
        'work',
        folderId: 'inbox-work',
      );
      final String homeKey = WidgetSnapshotService.accountListSnapshotId(
        'home',
        folderId: 'inbox-home',
      );

      expect(repo.snapshots.containsKey(workKey), isTrue);
      expect(repo.snapshots.containsKey(homeKey), isTrue);

      final Map<String, dynamic> workPayload =
          jsonDecode(repo.snapshots[workKey]!) as Map<String, dynamic>;
      final List<Object?> workRows = workPayload['messages'] as List<Object?>;
      expect(workRows, hasLength(2));
      expect((workRows.first as Map<String, dynamic>)['id'], 'w-new');

      final Map<String, dynamic> homePayload =
          jsonDecode(repo.snapshots[homeKey]!) as Map<String, dynamic>;
      final List<Object?> homeRows = homePayload['messages'] as List<Object?>;
      expect(homeRows, hasLength(1));
      expect((homeRows.first as Map<String, dynamic>)['accountId'], 'home');
    });
  });

  group('WidgetSnapshotService key helpers', () {
    test('accountListBridgeKey includes account and folder ids', () {
      expect(
        WidgetSnapshotService.accountListBridgeKey(
          'work',
          folderId: 'inbox-work',
        ),
        'synesis_widget.list.work.inbox-work',
      );
      expect(
        WidgetSnapshotService.accountListSnapshotId('work'),
        'mail_list_work',
      );
      expect(
        WidgetSnapshotService.accountListSnapshotId(
          'work',
          folderId: 'inbox-work',
        ),
        'mail_list_work_inbox-work',
      );
    });
  });
}
