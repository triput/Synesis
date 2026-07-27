// ==============================================================================
// File: test/message_attachments_panel_test.dart
// Description: Calendar attachment detection and Add-to-calendar action coverage.
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-27
// Last Update: 2026-07-27
// ==============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/pim.dart';
import 'package:synesis/pim/meeting_invite_service.dart';
import 'package:synesis/protocol/mail_provider.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/sync/sync_engine.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/shell/message_attachments_panel.dart';

const String _ics = '''
BEGIN:VCALENDAR
METHOD:REQUEST
BEGIN:VEVENT
UID:attach-invite@example.com
DTSTART:20260727T150000Z
DTEND:20260727T160000Z
SUMMARY:Attachment invite
END:VEVENT
END:VCALENDAR
''';

class _AttachmentProvider extends MailProvider {
  @override
  MailCapabilities get capabilities => const MailCapabilities(
        supportsServerSearch: false,
        supportsPush: false,
        supportsPartialBody: false,
        supportsSend: false,
        supportsAttachments: true,
      );

  @override
  Future<void> dispose() async {}

  @override
  Future<String?> fetchBody(
    String providerId, {
    String? folderRemoteId,
  }) async =>
      null;

  @override
  Future<String?> fetchHeaders(
    String providerId, {
    String? folderRemoteId,
  }) async =>
      null;

  @override
  Future<List<RemoteFolder>> listFolders() async => const <RemoteFolder>[];

  @override
  Future<List<RemoteMessageHeader>> listRecentInbox({int limit = 50}) async =>
      const <RemoteMessageHeader>[];

  @override
  Future<List<RemoteMessageHeader>> listRecentInFolder(
    String folderRemoteId, {
    int limit = 50,
  }) async =>
      const <RemoteMessageHeader>[];

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

  @override
  Future<List<MailAttachmentMeta>> listAttachments(
    String providerMessageId,
  ) async {
    return const <MailAttachmentMeta>[
      MailAttachmentMeta(
        partId: 'ics-1',
        name: 'invite.ics',
        contentType: 'text/calendar',
      ),
    ];
  }

  @override
  Future<MailAttachmentBytes> fetchAttachment(
    String providerMessageId,
    String partId,
  ) async {
    return MailAttachmentBytes(
      partId: partId,
      bytes: Uint8List.fromList(utf8.encode(_ics)),
      contentType: 'text/calendar',
      name: 'invite.ics',
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('recognizes calendar invite attachment names and content types', () {
    expect(
      isCalendarInviteAttachment(
        const MailAttachmentMeta(
          partId: 'ics-name',
          name: 'meeting.ICS',
          contentType: 'application/octet-stream',
        ),
      ),
      isTrue,
    );
    expect(
      isCalendarInviteAttachment(
        const MailAttachmentMeta(
          partId: 'calendar-type',
          name: 'invite',
          contentType: 'text/calendar; charset=utf-8',
        ),
      ),
      isTrue,
    );
    expect(
      isCalendarInviteAttachment(
        const MailAttachmentMeta(
          partId: 'ordinary-file',
          name: 'notes.txt',
          contentType: 'text/plain',
        ),
      ),
      isFalse,
    );
  });

  testWidgets('Add to calendar imports ICS and shows success feedback', (
    WidgetTester tester,
  ) async {
    final SynesisDatabase database = SynesisDatabase(NativeDatabase.memory());
    await database.customSelect('SELECT 1').get();
    addTearDown(database.close);

    final DriftMailRepository repository = DriftMailRepository(database);
    await repository.upsertAccount(
      const MailAccount(
        id: 'work',
        label: 'Work',
        address: 'alex@example.com',
        accent: Color(0xFF2DD4BF),
        providerType: 'imap',
      ),
      providerType: 'imap',
    );
    final DriftPimStore pimStore = DriftPimStore(database, notify: () {});
    await pimStore.upsertCalendars(const <Calendar>[
      Calendar(
        id: 'ignored',
        accountId: 'work',
        providerId: 'primary',
        name: 'Calendar',
        colorArgb: 0xFF0078D4,
        isDefault: true,
      ),
    ]);

    final MeetingInviteService inviteService = MeetingInviteService(
      pimStore: pimStore,
      repository: repository,
      resolvePim: (_) async => null,
    );
    final SyncEngine syncEngine = SyncEngine(
      repository: repository,
      resolveProvider: (_) async => _AttachmentProvider(),
    );
    addTearDown(syncEngine.dispose);

    final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          useMaterial3: true,
          brightness: tokens.brightness,
          extensions: <ThemeExtension<dynamic>>[tokens],
        ),
        home: MultiRepositoryProvider(
          providers: <RepositoryProvider<dynamic>>[
            RepositoryProvider<SyncEngine>.value(value: syncEngine),
            RepositoryProvider<MeetingInviteService>.value(
              value: inviteService,
            ),
          ],
          child: const Scaffold(
            body: MessageAttachmentsPanel(
              message: MailMessage(
                id: 'm1',
                accountId: 'work',
                fromName: 'Casey',
                fromAddress: 'casey@example.com',
                subject: 'Invite',
                snippet: '',
                body: '',
                whenLabel: 'now',
                bucket: FocusBucket.focused,
                hasAttachments: true,
                providerId: 'remote-1',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Add to calendar'), findsOneWidget);
    await tester.tap(find.text('Add to calendar'));
    await tester.pumpAndSettle();

    expect(find.text('Added to calendar'), findsOneWidget);
    final List<CalendarEvent> events = await pimStore.listEvents(
      accountId: 'work',
    );
    expect(events, hasLength(1));
    expect(events.single.providerId, 'ics:attach-invite@example.com');
    expect(events.single.title, 'Attachment invite');
  });
}
