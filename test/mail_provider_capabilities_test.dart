// ==============================================================================
// File: test/mail_provider_capabilities_test.dart
// Description: Capability flags and default UnsupportedError for MailProvider.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-16
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/protocol/graph_mail_provider.dart';
import 'package:bytemail/protocol/imap_smtp_mail_provider.dart';
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:flutter_test/flutter_test.dart';

class _BareProvider extends MailProvider {
  @override
  MailCapabilities get capabilities => const MailCapabilities(
    supportsServerSearch: false,
    supportsPush: false,
    supportsPartialBody: false,
    supportsSend: false,
  );

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> fetchBody(
    String providerId, {
    String? folderRemoteId,
  }) async => null;

  @override
  Future<String?> fetchHeaders(
    String providerId, {
    String? folderRemoteId,
  }) async => null;

  @override
  Future<List<RemoteFolder>> listFolders() async => const <RemoteFolder>[];

  @override
  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50}) async =>
      const <RemoteMessageHeader>[];

  @override
  Future<List<RemoteMessageHeader>> listRecentInFolder(
    String folderRemoteId, {
    int limit = 50,
  }) async => const <RemoteMessageHeader>[];

  @override
  Future<List<RemoteMessageHeader>> searchRemote(String query) async =>
      const <RemoteMessageHeader>[];

  @override
  Future<void> send({
    required List<String> to,
    List<String> cc = const <String>[],
    List<String> bcc = const <String>[],
    required String subject,
    required String body,
  }) async {}

  @override
  Future<void> setRead(
    String providerId, {
    required bool isRead,
    String? folderRemoteId,
  }) async {}
}

void main() {
  test('Graph advertises mutation and attachment capabilities', () {
    final GraphMailProvider provider = GraphMailProvider(() async => 'token');
    addTearDown(provider.dispose);
    expect(provider.capabilities.supportsStar, isTrue);
    expect(provider.capabilities.supportsMove, isTrue);
    expect(provider.capabilities.supportsDelete, isTrue);
    expect(provider.capabilities.supportsAttachments, isTrue);
    expect(provider.capabilities.supportsPush, isTrue);
  });

  test('IMAP advertises mutation and attachment capabilities', () {
    final ImapSmtpMailProvider provider = ImapSmtpMailProvider(
      host: 'imap.example',
      port: 993,
      user: 'u@example.com',
      password: 'secret',
      smtpHost: 'smtp.example',
      smtpPort: 465,
    );
    addTearDown(provider.dispose);
    expect(provider.capabilities.supportsStar, isTrue);
    expect(provider.capabilities.supportsMove, isTrue);
    expect(provider.capabilities.supportsDelete, isTrue);
    expect(provider.capabilities.supportsAttachments, isTrue);
    expect(provider.capabilities.supportsPush, isTrue);
  });

  test('default MailProvider mutation methods throw UnsupportedError', () {
    final _BareProvider provider = _BareProvider();
    expect(
      () => provider.setStarred('1', true),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => provider.moveMessage('1', 'Archive'),
      throwsA(isA<UnsupportedError>()),
    );
    expect(() => provider.deleteMessage('1'), throwsA(isA<UnsupportedError>()));
    expect(
      () => provider.listAttachments('1'),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => provider.fetchAttachment('1', '1'),
      throwsA(isA<UnsupportedError>()),
    );
    expect(
      () => provider.createFolder(displayName: 'Trash', role: 'trash'),
      throwsA(isA<UnsupportedError>()),
    );
  });
}
