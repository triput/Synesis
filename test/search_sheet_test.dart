// ==============================================================================
// File: test/search_sheet_test.dart
// Description: Widget coverage for search result datetime display (UI-P22).
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-23
// Last Update: 2026-07-23
// ==============================================================================

import 'package:synesis/compose/account_signature.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/sync_profile.dart';
import 'package:synesis/query/message_query.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/theme/custom_theme.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/search/search_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal [MailRepository] stub — only [searchLocal] returns real data;
/// every other member is an inert default so the widget under test can be
/// exercised without standing up the full repository stack.
class _SearchTestRepo implements MailRepository {
  _SearchTestRepo(this._results);

  final List<MailMessage> _results;

  @override
  Future<List<MailMessage>> searchLocal(String query) async => _results;

  @override
  Future<int> applyRetention({
    required int retentionDays,
    String? accountId,
  }) async => 0;

  @override
  Future<List<SyncProfile>> listSyncProfiles() async => const <SyncProfile>[];

  @override
  Future<SyncProfile?> getSyncProfile(String id) async => null;

  @override
  Future<SyncProfile?> getDefaultSyncProfile() async => null;

  @override
  Future<void> upsertSyncProfile(SyncProfile profile) async {}

  @override
  Future<ResolvedSyncPolicy> resolvePolicy(
    String accountId, {
    int fallbackRetentionDays = 180,
  }) async => ResolvedSyncPolicy(
    accountId: accountId,
    profileId: 'default',
    retentionDays: fallbackRetentionDays,
    bodyPolicy: BodyFetchPolicy.onOpen,
    attachmentMaxMb: 25,
  );

  @override
  Future<List<SyncJob>> listSyncJobs({int limit = 50}) async =>
      const <SyncJob>[];

  @override
  Future<void> retrySyncJob(String id) async {}

  @override
  Future<void> cancelSyncJob(String id) async {}

  @override
  Future<List<AccountSyncHealth>> listAccountSyncHealth() async =>
      const <AccountSyncHealth>[];

  @override
  Future<List<SyncJob>> claimPendingJobs({int limit = 10}) async => const [];

  @override
  Future<int> reclaimRunningJobs() async => 0;

  @override
  Future<int> reclaimSendingOutbox() async => 0;

  @override
  Future<int> cancelPendingSyncJobs({String? accountId}) async => 0;

  @override
  Future<int> abortRunningSyncJobs({String? accountId}) async => 0;

  @override
  Future<int> clearSyncCursors({String? accountId, String? folderId}) async =>
      0;

  @override
  Future<int> clearFailedSyncJobs({String? accountId}) async => 0;

  @override
  Future<void> completeJob(
    String id, {
    required bool success,
    String? cursorJson,
    String? error,
  }) async {}

  @override
  Future<int> countQueuedOutbox() async => 0;

  @override
  Future<int> countFailedOutbox() async => 0;

  @override
  Future<({int running, int pending})> countSyncJobActivity() async =>
      (running: 0, pending: 0);

  @override
  Future<int> reclassifyFocusBuckets(
    FocusBucket Function(MailMessage message) score,
  ) async => 0;

  @override
  Future<String> enqueueOutbox({
    required String accountId,
    required String to,
    required String subject,
    required String body,
    String? cc,
    String? bcc,
    String composeMode = 'new',
    String? inReplyTo,
    String? referencesJson,
    String? attachmentRefsJson,
    String? signatureId,
    int? sendAfter,
    String state = 'queued',
  }) async => 'out-1';

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {}

  @override
  Future<bool> hasIncompleteJobOfType(String type) async => false;

  @override
  Future<String> exportDiagnosticsRedacted() async => '{}';

  @override
  Future<String?> getCursor(
    String accountId,
    String folderId,
    String key,
  ) async => null;

  @override
  Future<MailMessage?> getMessage(String id) async => null;

  @override
  Future<String?> getWidgetSnapshot(String id) async => null;

  @override
  Future<List<MailAccount>> listAccounts() async => const <MailAccount>[];

  @override
  Future<List<MailFolder>> listFolders({String? accountId}) async =>
      const <MailFolder>[];

  @override
  Future<MailFolder?> getFolder(String id) async => null;

  @override
  Future<void> upsertFolders(List<MailFolder> folders) async {}

  @override
  Future<List<MailMessage>> listMessages(MessageQuery query) async =>
      const <MailMessage>[];

  @override
  Future<List<OutboxItem>> listOutbox() async => const [];

  @override
  Future<void> seedDemoDataIfEmpty() async {}

  @override
  Future<void> setCursor(
    String accountId,
    String folderId,
    String key,
    String value,
  ) async {}

  @override
  Future<void> setPinned(String messageId, bool pinned) async {}

  @override
  Future<void> setPinnedBulk(List<String> ids, bool pinned) async {}

  @override
  Future<void> setSnoozed(String messageId, int? snoozedUntil) async {}

  @override
  Future<void> setSnoozedBulk(List<String> ids, int? snoozedUntil) async {}

  @override
  Future<int?> nextSnoozeExpiryMs({int? nowMs}) async => null;

  @override
  Future<int> clearExpiredSnoozes({int? nowMs}) async => 0;

  @override
  Future<void> setStarred(String messageId, bool starred) async {}

  @override
  Future<MailFolder?> resolveFolderByRole(
    String accountId,
    String role,
  ) async => null;

  @override
  Future<void> moveMessageLocal(
    String messageId,
    String folderId, {
    int? trashedAt,
    bool clearTrashedAt = false,
  }) async {}

  @override
  Future<void> moveMessagesLocal(
    List<String> messageIds,
    String folderId, {
    int? trashedAt,
    bool clearTrashedAt = false,
  }) async {}

  @override
  Future<void> hardDeleteLocal(String messageId) async {}

  @override
  Future<void> hardDeleteLocalBulk(List<String> ids) async {}

  @override
  Future<List<MailMessage>> listTrashedPastRetention({
    required int retentionDays,
    DateTime? now,
  }) async => const <MailMessage>[];

  @override
  Future<void> setUnread(String messageId, bool unread) async {}

  @override
  Future<void> setUnreadBulk(List<String> ids, bool unread) async {}

  @override
  Future<void> recountUnreadCounts({String? accountId}) async {}

  @override
  Future<String> syncStatusLabel() async => 'Synced · test';

  @override
  Future<void> updateOutboxState(
    String id,
    String state, {
    String? error,
  }) async {}

  @override
  Future<void> deleteOutbox(String id) async {}

  @override
  Future<int> deleteOutboxInStates(Iterable<String> states) async => 0;

  @override
  Future<void> upsertAccount(
    MailAccount account, {
    required String providerType,
    bool focusEnabled = true,
  }) async {}

  @override
  Future<List<MailMessage>> upsertMessages(
    List<MailMessage> messages, {
    required String folderId,
  }) async => const <MailMessage>[];

  @override
  Future<void> updateMessageBody(String messageId, String body) async {}

  @override
  Future<void> updateMessageRawHeaders(
    String messageId,
    String rawHeaders,
  ) async {}

  @override
  Future<void> updateMessageFocusBucket(
    String messageId,
    FocusBucket bucket,
  ) async {}

  @override
  Future<void> upsertWidgetSnapshot(
    String id,
    String kind,
    String payloadJson,
  ) async {}

  @override
  Stream<void> watchChanges() => const Stream<void>.empty();

  @override
  Future<void> wipeAccount(String accountId) async {}

  @override
  Future<List<FocusRule>> listFocusRules({String? accountId}) async =>
      const <FocusRule>[];

  @override
  Future<void> upsertFocusRule(FocusRule rule) async {}

  @override
  Future<void> deleteFocusRule(String id) async {}

  @override
  Future<void> updateOutboxContent(
    String id, {
    String? to,
    String? subject,
    String? body,
    String? cc,
    String? bcc,
    String? composeMode,
    String? inReplyTo,
    String? referencesJson,
    String? attachmentRefsJson,
    String? signatureId,
    int? sendAfter,
    bool clearSendAfter = false,
  }) async {}

  @override
  Future<List<MailSignature>> listSignatures(String accountId) async =>
      const <MailSignature>[];

  @override
  Future<MailSignature?> getSignature(String id) async => null;

  @override
  Future<String> upsertSignature(MailSignature signature) async =>
      signature.id;

  @override
  Future<void> deleteSignature(String id) async {}

  @override
  Future<List<MailSignatureAsset>> listSignatureAssets(
    String signatureId,
  ) async => const <MailSignatureAsset>[];

  @override
  Future<String> addSignatureAsset({
    required String signatureId,
    required String sourcePath,
    required String mimeType,
    String? contentId,
  }) async => '';

  @override
  Future<List<MailTemplate>> listTemplates({String? accountId}) async =>
      const <MailTemplate>[];

  @override
  Future<String> upsertTemplate(MailTemplate template) async => template.id;

  @override
  Future<void> deleteTemplate(String id) async {}

  @override
  Future<OutboundBlobRef> stageAttachmentBlob({
    required String accountId,
    required String sourcePath,
    String? fileName,
  }) {
    throw UnsupportedError('Attachment staging is not implemented.');
  }

  @override
  Future<OutboundBlobRef?> getAttachmentBlob(String id) async => null;

  @override
  Future<void> deleteAttachmentBlob(String id) async {}

  @override
  Future<List<CustomTheme>> listCustomThemes() async => const <CustomTheme>[];

  @override
  Future<CustomTheme?> getCustomTheme(String id) async => null;

  @override
  Future<String> upsertCustomTheme(CustomTheme theme) async => theme.id;

  @override
  Future<void> deleteCustomTheme(String id) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MailMessage recent = MailMessage(
    id: 'msg-recent',
    accountId: 'work',
    fromName: 'Maya',
    fromAddress: 'maya@byte.io',
    subject: 'Budget draft',
    snippet: 'Here is the draft',
    body: 'Body',
    whenLabel: '10:14',
    bucket: FocusBucket.focused,
  );

  const MailMessage older = MailMessage(
    id: 'msg-older',
    accountId: 'work',
    fromName: 'Maya',
    fromAddress: 'maya@byte.io',
    subject: 'Budget draft',
    snippet: 'An older near-duplicate subject',
    body: 'Body',
    // Simulates DriftMappers.formatWhen's absolute-date output for
    // anything older than yesterday (UI-P22 acceptance).
    whenLabel: '3/1/2026',
    bucket: FocusBucket.focused,
  );

  Future<void> pumpSearchSheet(
    WidgetTester tester,
    _SearchTestRepo repo,
  ) async {
    final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);
    await tester.pumpWidget(
      RepositoryProvider<MailRepository>.value(
        value: repo,
        child: MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            brightness: tokens.brightness,
            extensions: <ThemeExtension<dynamic>>[tokens],
          ),
          home: const Scaffold(
            body: SizedBox(height: 640, child: SearchSheetBody()),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'search results show whenLabel so near-duplicate subjects are '
    'distinguishable (UI-P22)',
    (WidgetTester tester) async {
      final _SearchTestRepo repo = _SearchTestRepo(<MailMessage>[
        recent,
        older,
      ]);
      await pumpSearchSheet(tester, repo);

      await tester.enterText(find.byType(TextField), 'budget');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      expect(find.text('Budget draft'), findsNWidgets(2));
      // Recent result shows a time-of-day label…
      expect(find.text('10:14'), findsOneWidget);
      // …while the older near-duplicate shows an absolute M/D/Y date so the
      // two rows are distinguishable at a glance.
      expect(find.text('3/1/2026'), findsOneWidget);
    },
  );

  testWidgets('empty query shows the initial empty state, not results', (
    WidgetTester tester,
  ) async {
    final _SearchTestRepo repo = _SearchTestRepo(<MailMessage>[recent]);
    await pumpSearchSheet(tester, repo);

    expect(find.text('Search your mail'), findsOneWidget);
    expect(find.text('10:14'), findsNothing);
  });
}
