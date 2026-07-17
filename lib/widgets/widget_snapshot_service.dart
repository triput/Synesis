// ==============================================================================
// File: lib/widgets/widget_snapshot_service.dart
// Description: Builds repository-backed Android widget snapshots and bridge data.
// Component: Platform Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-16
// ==============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/mail_repository.dart';
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
  static const String listBridgeKey = 'byte_mail_widget.list';
  static const String counterBridgeKey = 'byte_mail_widget.counter';
  static const String actionBridgeKey = 'byte_mail_widget.actions';

  final MailRepository _repository;
  final SharedPreferences? _preferences;

  Future<void> refreshAll() async {
    final List<MailMessage> messages =
        await _repository.listMessages(MessageQuery.defaults);
    final List<MailMessage> visibleMessages = messages.take(5).toList(
      growable: false,
    );
    final int unreadCount = messages.where((MailMessage message) {
      return message.unread;
    }).length;

    final String listPayload = jsonEncode(<String, Object>{
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'messages': visibleMessages
          .map(
            (MailMessage message) => <String, Object?>{
              'id': message.id,
              'accountId': message.accountId,
              'from': message.fromName,
              'subject': message.subject,
              'snippet': message.snippet,
              'unread': message.unread,
              'when': message.whenLabel,
            },
          )
          .toList(growable: false),
    });
    final String counterPayload = jsonEncode(<String, Object>{
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'unreadCount': unreadCount,
      'totalCount': messages.length,
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
    await _writeAndroidBridge(
      listPayload: listPayload,
      counterPayload: counterPayload,
      actionPayload: actionPayload,
    );
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
      qualifiedAndroidName: 'com.bytemail.bytemail.ByteMailWidgetProvider',
    );
  }
}
