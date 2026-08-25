// ==============================================================================
// File: lib/widgets/widget_snapshot_service.dart
// Description: Builds repository-backed Android widget snapshots and bridge data.
// Component: Platform Integration
// Version: 1.2 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-08-25
// ==============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:synesis/domain/models.dart';
import 'package:synesis/query/message_query.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:home_widget/home_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Exports compact data for native widgets; they read it without waking Flutter.
class WidgetSnapshotService {
  WidgetSnapshotService(
    this._repository, {
    SharedPreferences? preferences,
  }) : _preferences = preferences;

  static const String listSnapshotId = 'mail_list';
  static const String counterSnapshotId = 'mail_counter';
  static const String actionSnapshotId = 'mail_actions';
  static const String listBridgeKey = 'synesis_widget.list';
  static const String counterBridgeKey = 'synesis_widget.counter';
  static const String actionBridgeKey = 'synesis_widget.actions';
  static const String accountsBridgeKey = 'synesis_widget.accounts';

  static const int listRowLimit = 10;

  final MailRepository _repository;
  final SharedPreferences? _preferences;

  /// Stable Drift snapshot id for an account (+ optional folder) list widget.
  static String accountListSnapshotId(
    String accountId, {
    String? folderId,
  }) {
    if (folderId == null || folderId.isEmpty) {
      return 'mail_list_$accountId';
    }
    return 'mail_list_${accountId}_$folderId';
  }

  /// SharedPreferences / HomeWidget bridge key for a scoped list payload.
  static String accountListBridgeKey(
    String accountId, {
    String? folderId,
  }) {
    if (folderId == null || folderId.isEmpty) {
      return 'synesis_widget.list.$accountId';
    }
    return 'synesis_widget.list.$accountId.$folderId';
  }

  /// Refreshes list/counter/action snapshots for the Android home-screen widget.
  Future<void> refreshAll({ThemeId themeId = ThemeId.dark}) async {
    final List<MailMessage> messages =
        await _repository.listMessages(MessageQuery.defaults);
    final List<MailMessage> visibleMessages = messages.take(5).toList(
      growable: false,
    );
    final int unreadCount = messages.where((MailMessage message) {
      return message.unread;
    }).length;
    final int focusedUnread = messages.where((MailMessage message) {
      return message.unread && message.bucket == FocusBucket.focused;
    }).length;
    final int otherUnread = messages.where((MailMessage message) {
      return message.unread && message.bucket == FocusBucket.other;
    }).length;

    final ThemeTokens tokens = ThemeTokens.forId(themeId);
    final String listPayload = encodeListPayload(messages: visibleMessages);
    final String counterPayload = jsonEncode(<String, Object>{
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'unreadCount': unreadCount,
      'focusedUnread': focusedUnread,
      'otherUnread': otherUnread,
      'totalCount': messages.length,
      'themeId': themeId.name,
      'theme': <String, int>{
        'ink': tokens.ink.toARGB32(),
        'panel': tokens.panel.toARGB32(),
        'panel2': tokens.panel2.toARGB32(),
        'text': tokens.text.toARGB32(),
        'muted': tokens.muted.toARGB32(),
        'teal': tokens.teal.toARGB32(),
        'indigo': tokens.indigo.toARGB32(),
        'onAccent': tokens.onAccent.toARGB32(),
      },
    });
    final String actionPayload = jsonEncode(<String, Object>{
      'actions': <String>[
        'open_inbox',
        'compose',
        'search',
      ],
    });

    await Future.wait(<Future<void>>[
      _repository.upsertWidgetSnapshot(
        listSnapshotId,
        'list',
        listPayload,
      ),
      _repository.upsertWidgetSnapshot(
        counterSnapshotId,
        'counter',
        counterPayload,
      ),
      _repository.upsertWidgetSnapshot(
        actionSnapshotId,
        'actions',
        actionPayload,
      ),
    ]);
    await refreshAccountLists();
    await _writeAndroidBridge(
      listPayload: listPayload,
      counterPayload: counterPayload,
      actionPayload: actionPayload,
    );
  }

  /// Writes per-account (and per-folder) list snapshots for list widgets.
  Future<void> refreshAccountLists() async {
    final List<MailAccount> accounts = await _repository.listAccounts();
    final List<MailFolder> folders = await _repository.listFolders();
    final String accountsPayload = jsonEncode(<String, Object>{
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'accounts': accounts
          .map(
            (MailAccount account) => <String, Object>{
              'id': account.id,
              'label': account.label,
              'address': account.address,
            },
          )
          .toList(growable: false),
    });

    final Map<String, String> scopedListPayloads = <String, String>{};
    final List<Future<void>> writes = <Future<void>>[];

    for (final MailAccount account in accounts) {
      final String inboxId = MailFolder.inboxId(account.id);
      MailFolder? inboxFolder;
      for (final MailFolder folder in folders) {
        if (folder.id == inboxId) {
          inboxFolder = folder;
          break;
        }
      }
      writes.add(
        _refreshScopedList(
          account: account,
          folderId: inboxId,
          folderName: inboxFolder?.name ?? 'Inbox',
          scopedListPayloads: scopedListPayloads,
        ),
      );

      for (final MailFolder folder in folders) {
        if (folder.accountId != account.id || folder.id == inboxId) {
          continue;
        }
        if (folder.role != 'inbox' && (folder.unreadCount ?? 0) <= 0) {
          continue;
        }
        writes.add(
          _refreshScopedList(
            account: account,
            folderId: folder.id,
            folderName: folder.name,
            scopedListPayloads: scopedListPayloads,
          ),
        );
      }
    }

    await Future.wait(writes);
    if (Platform.isAndroid) {
      await _writeScopedListBridge(scopedListPayloads);
      await _writeAccountsBridge(accountsPayload);
    }
  }

  Future<void> _refreshScopedList({
    required MailAccount account,
    required String folderId,
    required String folderName,
    required Map<String, String> scopedListPayloads,
  }) async {
    final List<MailMessage> messages = await _repository.listMessages(
      MessageQuery(
        accountId: account.id,
        folderId: folderId,
        limit: listRowLimit,
      ),
    );
    final String payload = encodeListPayload(
      messages: messages,
      accountId: account.id,
      accountLabel: account.label,
      folderId: folderId,
      folderName: folderName,
    );
    scopedListPayloads[accountListBridgeKey(
      account.id,
      folderId: folderId,
    )] = payload;
    await _repository.upsertWidgetSnapshot(
      accountListSnapshotId(account.id, folderId: folderId),
      'list',
      payload,
    );
  }

  /// JSON encoder shared by aggregate and scoped list widget snapshots.
  static String encodeListPayload({
    required List<MailMessage> messages,
    String? accountId,
    String? accountLabel,
    String? folderId,
    String? folderName,
  }) {
    return jsonEncode(<String, Object?>{
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      if (accountId != null) 'accountId': accountId,
      if (accountLabel != null) 'accountLabel': accountLabel,
      if (folderId != null) 'folderId': folderId,
      if (folderName != null) 'folderName': folderName,
      'messages': messages
          .map(
            (MailMessage message) => <String, Object?>{
              'id': message.id,
              'accountId': message.accountId,
              'folderId': message.folderId,
              'from': message.fromName,
              'subject': message.subject,
              'snippet': message.snippet,
              'unread': message.unread,
              'when': message.whenLabel,
              'bucket': message.bucket.name,
            },
          )
          .toList(growable: false),
    });
  }

  Future<void> _writeAndroidBridge({
    required String listPayload,
    required String counterPayload,
    required String actionPayload,
  }) async {
    if (!Platform.isAndroid) {
      return;
    }
    final SharedPreferences preferences =
        _preferences ?? await SharedPreferences.getInstance();
    await Future.wait<Object?>(<Future<Object?>>[
      preferences.setString(listBridgeKey, listPayload),
      preferences.setString(counterBridgeKey, counterPayload),
      preferences.setString(actionBridgeKey, actionPayload),
      HomeWidget.saveWidgetData<String>(listBridgeKey, listPayload),
      HomeWidget.saveWidgetData<String>(counterBridgeKey, counterPayload),
      HomeWidget.saveWidgetData<String>(actionBridgeKey, actionPayload),
    ]);
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'net.livebytes.synesis.SynesisWidgetProvider',
    );
    await HomeWidget.updateWidget(
      qualifiedAndroidName: 'net.livebytes.synesis.SynesisListWidgetProvider',
    );
  }

  Future<void> _writeScopedListBridge(Map<String, String> payloads) async {
    if (!Platform.isAndroid || payloads.isEmpty) {
      return;
    }
    final SharedPreferences preferences =
        _preferences ?? await SharedPreferences.getInstance();
    final List<Future<Object?>> writes = <Future<Object?>>[];
    for (final MapEntry<String, String> entry in payloads.entries) {
      writes.add(preferences.setString(entry.key, entry.value));
      writes.add(HomeWidget.saveWidgetData<String>(entry.key, entry.value));
    }
    await Future.wait<Object?>(writes);
  }

  Future<void> _writeAccountsBridge(String accountsPayload) async {
    if (!Platform.isAndroid) {
      return;
    }
    final SharedPreferences preferences =
        _preferences ?? await SharedPreferences.getInstance();
    await Future.wait<Object?>(<Future<Object?>>[
      preferences.setString(accountsBridgeKey, accountsPayload),
      HomeWidget.saveWidgetData<String>(accountsBridgeKey, accountsPayload),
    ]);
  }
}
