// ==============================================================================
// File: test/mailbox_widget_launch_test.dart
// Description: Widget deep-link navigation via MailboxCubit.handleWidgetLaunch.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'dart:async';

import 'package:synesis/domain/models.dart';
import 'package:synesis/protocol/mail_provider.dart';
import 'package:synesis/mailbox/message_action_service.dart';
import 'package:synesis/mailbox/message_body_cache.dart';
import 'package:synesis/query/message_query.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/settings/app_settings_cubit.dart';
import 'package:synesis/sync/sync_engine.dart';
import 'package:synesis/ui/mailbox/mailbox_cubit.dart';
import 'package:synesis/widgets/widget_launch_request.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _WidgetLaunchRepo implements MailRepository {
  _WidgetLaunchRepo(this._messages);

  final List<MailMessage> _messages;

  static const MailAccount account = MailAccount(
    id: 'work',
    label: 'Work',
    address: 'work@byte.io',
    accent: Color(0xFF2DD4BF),
  );

  static const MailFolder inbox = MailFolder(
    id: 'inbox-work',
    accountId: 'work',
    name: 'Inbox',
    remoteId: 'INBOX',
    role: 'inbox',
    unreadCount: 1,
  );

  static MailMessage message({required String id}) {
    return MailMessage(
      id: id,
      accountId: 'work',
      folderId: 'inbox-work',
      fromName: 'Ada',
      fromAddress: 'ada@byte.io',
      subject: 'Hello',
      snippet: 'Snippet',
      body: 'Body',
      whenLabel: 'Now',
      bucket: FocusBucket.focused,
      unread: true,
    );
  }

  @override
  Future<List<MailAccount>> listAccounts() async => <MailAccount>[account];

  @override
  Future<List<MailFolder>> listFolders({String? accountId}) async =>
      <MailFolder>[inbox];

  @override
  Future<List<MailMessage>> listMessages(MessageQuery query) async {
    return List<MailMessage>.from(_messages);
  }

  @override
  Future<MailMessage?> getMessage(String id) async {
    for (final MailMessage message in _messages) {
      if (message.id == id) {
        return message;
      }
    }
    return null;
  }

  @override
  Stream<void> watchChanges() => const Stream<void>.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<MailboxCubit> buildCubit(_WidgetLaunchRepo repo) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderResolver resolver = (_) async => null;
    final MessageActionService actions = MessageActionService(
      repository: repo,
      resolveProvider: resolver,
    );
    final MessageBodyCache bodyCache = MessageBodyCache(
      repository: repo,
      resolveProvider: resolver,
    );
    final MailboxCubit cubit = MailboxCubit(
      repository: repo,
      settingsCubit: AppSettingsCubit(prefs),
      actions: actions,
      bodyCache: bodyCache,
    );
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    return cubit;
  }

  test('handleWidgetLaunch openInbox selects account folder', () async {
    final _WidgetLaunchRepo repo = _WidgetLaunchRepo(<MailMessage>[
      _WidgetLaunchRepo.message(id: 'm1'),
    ]);
    final MailboxCubit cubit = await buildCubit(repo);
    addTearDown(cubit.close);

    await cubit.handleWidgetLaunch(
      const WidgetLaunchRequest(
        action: WidgetLaunchAction.openInbox,
        accountId: 'work',
        folderId: 'inbox-work',
      ),
    );

    expect(cubit.state.accountId, 'work');
    expect(cubit.state.folderId, 'inbox-work');
    expect(cubit.state.selectedMessageId, isNull);
  });

  test('handleWidgetLaunch openMessage selects message on phone path', () async {
    final _WidgetLaunchRepo repo = _WidgetLaunchRepo(<MailMessage>[
      _WidgetLaunchRepo.message(id: 'm1'),
    ]);
    final MailboxCubit cubit = await buildCubit(repo);
    addTearDown(cubit.close);

    await cubit.handleWidgetLaunch(
      const WidgetLaunchRequest(
        action: WidgetLaunchAction.openMessage,
        accountId: 'work',
        folderId: 'inbox-work',
        messageId: 'm1',
      ),
    );

    expect(cubit.state.selectedMessageId, 'm1');
    expect(cubit.state.selectedMessage?.id, 'm1');
  });

  test('handleWidgetLaunch openMessage without id opens inbox only', () async {
    final _WidgetLaunchRepo repo = _WidgetLaunchRepo(<MailMessage>[
      _WidgetLaunchRepo.message(id: 'm1'),
    ]);
    final MailboxCubit cubit = await buildCubit(repo);
    addTearDown(cubit.close);

    await cubit.handleWidgetLaunch(
      const WidgetLaunchRequest(
        action: WidgetLaunchAction.openMessage,
        accountId: 'work',
        folderId: 'inbox-work',
      ),
    );

    expect(cubit.state.accountId, 'work');
    expect(cubit.state.selectedMessageId, isNull);
  });
}
