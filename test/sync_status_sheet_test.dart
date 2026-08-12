// ==============================================================================
// File: test/sync_status_sheet_test.dart
// Description: Widget smoke coverage for the sync status / job viewer sheet.
// Component: Test
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-08-12
// ==============================================================================

import 'dart:async';

import 'package:synesis/compose/account_signature.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/sync_profile.dart';
import 'package:synesis/query/message_query.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/sync_activity.dart';
import 'package:synesis/sync/sync_engine.dart';
import 'package:synesis/theme/custom_theme.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/sync/sync_status_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

class _SheetRepo implements MailRepository {
  final StreamController<void> _changes = StreamController<void>.broadcast();
  final List<SyncJob> jobs = <SyncJob>[
    SyncJob(
      id: 'job-1',
      accountId: 'work',
      type: 'incremental',
      status: 'failed',
      updatedAt: 1,
      cursorJson: '{"error":"timeout"}',
    ),
    SyncJob(
      id: 'job-2',
      accountId: 'work',
      type: 'full_folder',
      status: 'pending',
      updatedAt: 2,
    ),
  ];

  String? lastRetryId;
  String? lastStopAccountId;
  int clearCursorsCalls = 0;

  @override
  Stream<void> watchChanges() => _changes.stream;

  @override
  Future<List<SyncJob>> listSyncJobs({int limit = 50}) async =>
      List<SyncJob>.from(jobs.take(limit));

  @override
  Future<void> retrySyncJob(String id) async {
    lastRetryId = id;
    final int index = jobs.indexWhere((SyncJob j) => j.id == id);
    if (index >= 0 && jobs[index].status == 'failed') {
      jobs[index] = SyncJob(
        id: jobs[index].id,
        accountId: jobs[index].accountId,
        type: jobs[index].type,
        status: 'pending',
        updatedAt: jobs[index].updatedAt + 1,
        payloadJson: jobs[index].payloadJson,
      );
    }
    _changes.add(null);
  }

  @override
  Future<void> cancelSyncJob(String id) async {
    jobs.removeWhere(
      (SyncJob j) => j.id == id && j.status == 'pending',
    );
    _changes.add(null);
  }

  @override
  Future<List<AccountSyncHealth>> listAccountSyncHealth() async =>
      const <AccountSyncHealth>[
        AccountSyncHealth(
          accountId: 'work',
          pendingCount: 1,
          failedCount: 1,
          syncing: false,
          lastError: 'timeout',
        ),
      ];

  @override
  Future<void> enqueueSyncJob({
    required String accountId,
    required String type,
    String? payloadJson,
  }) async {}

  @override
  Future<List<MailAccount>> listAccounts() async => const <MailAccount>[];

  @override
  Future<List<MailFolder>> listFolders({String? accountId}) async =>
      const <MailFolder>[];

  @override
  Future<List<FocusRule>> listFocusRules({String? accountId}) async =>
      const <FocusRule>[];

  @override
  Future<void> upsertFocusRule(FocusRule rule) async {}

  @override
  Future<void> deleteFocusRule(String id) async {}

  @override
  Future<void> recountUnreadCounts({String? accountId}) async {}

  @override
  Future<int> applyRetention({
    required int retentionDays,
    String? accountId,
  }) async =>
      0;

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
  }) async =>
      ResolvedSyncPolicy(
        accountId: accountId,
        profileId: 'default',
        retentionDays: fallbackRetentionDays,
        bodyPolicy: BodyFetchPolicy.onOpen,
        attachmentMaxMb: 25,
      );

  @override
  Future<List<SyncJob>> claimPendingJobs({int limit = 10}) async =>
      const <SyncJob>[];

  @override
  Future<int> reclaimRunningJobs() async => 0;

  @override
  Future<int> reclaimSendingOutbox() async => 0;

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
  Future<({int running, int pending})> countSyncJobActivity() async {
    int pending = 0;
    int running = 0;
    for (final SyncJob job in jobs) {
      if (job.status == 'pending') {
        pending += 1;
      } else if (job.status == 'running') {
        running += 1;
      }
    }
    return (running: running, pending: pending);
  }

  @override
  Future<int> cancelPendingSyncJobs({String? accountId}) async {
    lastStopAccountId = accountId;
    final int before = jobs.length;
    jobs.removeWhere((SyncJob job) {
      if (job.status != 'pending') {
        return false;
      }
      if (accountId != null && job.accountId != accountId) {
        return false;
      }
      return true;
    });
    final int removed = before - jobs.length;
    if (removed > 0) {
      _changes.add(null);
    }
    return removed;
  }

  @override
  Future<int> abortRunningSyncJobs({String? accountId}) async => 0;

  @override
  Future<int> clearSyncCursors({String? accountId, String? folderId}) async {
    clearCursorsCalls += 1;
    return 2;
  }

  @override
  Future<int> reclassifyFocusBuckets(
    FocusBucket Function(MailMessage message) score,
  ) async =>
      0;

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
  }) async =>
      'out-1';

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
  Future<List<CustomTheme>> listCustomThemes() async =>
      const <CustomTheme>[];

  @override
  Future<CustomTheme?> getCustomTheme(String id) async => null;

  @override
  Future<String> upsertCustomTheme(CustomTheme theme) async => theme.id;

  @override
  Future<void> deleteCustomTheme(String id) async {}

  @override
  Future<bool> hasIncompleteJobOfType(String type) async => false;

  @override
  Future<String> exportDiagnosticsRedacted() async => '{}';

  @override
  Future<String?> getCursor(
    String accountId,
    String folderId,
    String key,
  ) async =>
      null;

  @override
  Future<MailMessage?> getMessage(String id) async => null;

  @override
  Future<String?> getWidgetSnapshot(String id) async => null;

  @override
  Future<MailFolder?> getFolder(String id) async => null;

  @override
  Future<void> upsertFolders(List<MailFolder> folders) async {}

  @override
  Future<List<MailMessage>> listMessages(MessageQuery query) async =>
      const <MailMessage>[];

  @override
  Future<List<OutboxItem>> listOutbox() async => const <OutboxItem>[];

  @override
  Future<List<MailMessage>> searchLocal(String query) async =>
      const <MailMessage>[];

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
  Future<void> setUnread(String messageId, bool unread) async {}

  @override
  Future<void> setUnreadBulk(List<String> ids, bool unread) async {}

  @override
  Future<String> syncStatusLabel() async => 'Up to date';

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
  }) async =>
      const <MailMessage>[];

  @override
  Future<void> upsertWidgetSnapshot(
    String id,
    String kind,
    String payloadJson,
  ) async {}

  @override
  Future<void> wipeAccount(String accountId) async {}

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
  }) async =>
      const <MailMessage>[];

  @override
  Future<MailFolder?> resolveFolderByRole(String accountId, String role) async =>
      null;
}

Widget _wrapSheet({
  required _SheetRepo repo,
  required SyncActivity syncActivity,
  required SyncEngine syncEngine,
  required ThemeTokens tokens,
}) {
  return MultiRepositoryProvider(
    providers: <RepositoryProvider<dynamic>>[
      RepositoryProvider<MailRepository>.value(value: repo),
      RepositoryProvider<SyncActivity>.value(value: syncActivity),
      RepositoryProvider<SyncEngine>.value(value: syncEngine),
    ],
    child: MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        brightness: tokens.brightness,
        extensions: <ThemeExtension<dynamic>>[tokens],
      ),
      home: const Scaffold(
        body: SizedBox(
          height: 720,
          child: SyncStatusSheetBody(),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('SyncJob.errorSnippet reads failed cursorJson', () {
    const SyncJob job = SyncJob(
      id: 'j',
      accountId: 'a',
      type: 'incremental',
      status: 'failed',
      updatedAt: 1,
      cursorJson: '{"error":"boom"}',
    );
    expect(job.errorSnippet, 'boom');
  });

  testWidgets('SyncStatusSheetBody shows jobs and retry', (
    WidgetTester tester,
  ) async {
    final _SheetRepo repo = _SheetRepo();
    final SyncActivity syncActivity = SyncActivity(repository: repo);
    syncActivity.start();
    addTearDown(() async {
      await syncActivity.dispose();
    });
    final SyncEngine syncEngine = SyncEngine(
      repository: repo,
      resolveProvider: (_) async => null,
    );
    final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);

    await tester.pumpWidget(
      _wrapSheet(
        repo: repo,
        syncActivity: syncActivity,
        syncEngine: syncEngine,
        tokens: tokens,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Sync status'), findsOneWidget);
    expect(find.text('incremental'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(repo.lastRetryId, 'job-1');

    await tester.tap(find.text('Accounts'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.text('Sync now'), findsOneWidget);
    expect(find.text('Clear cursors'), findsOneWidget);
    expect(find.text('Stop sync'), findsOneWidget);
  });

  testWidgets('Stop all sync cancels pending jobs', (WidgetTester tester) async {
    final _SheetRepo repo = _SheetRepo();
    final SyncActivity syncActivity = SyncActivity(repository: repo);
    syncActivity.start();
    addTearDown(() async {
      await syncActivity.dispose();
    });
    final SyncEngine syncEngine = SyncEngine(
      repository: repo,
      resolveProvider: (_) async => null,
    );
    final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);

    await tester.pumpWidget(
      _wrapSheet(
        repo: repo,
        syncActivity: syncActivity,
        syncEngine: syncEngine,
        tokens: tokens,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Stop all sync'), findsOneWidget);

    await tester.tap(find.text('Stop all sync'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(repo.lastStopAccountId, isNull);
    expect(
      repo.jobs.where((SyncJob j) => j.status == 'pending'),
      isEmpty,
    );
    expect(
      find.textContaining('Local mail was not deleted'),
      findsOneWidget,
    );
  });

  testWidgets('Clear cursors requires confirmation', (
    WidgetTester tester,
  ) async {
    final _SheetRepo repo = _SheetRepo();
    final SyncActivity syncActivity = SyncActivity(repository: repo);
    syncActivity.start();
    addTearDown(() async {
      await syncActivity.dispose();
    });
    final SyncEngine syncEngine = SyncEngine(
      repository: repo,
      resolveProvider: (_) async => null,
    );
    final ThemeTokens tokens = ThemeTokens.forId(ThemeId.dark);

    await tester.pumpWidget(
      _wrapSheet(
        repo: repo,
        syncActivity: syncActivity,
        syncEngine: syncEngine,
        tokens: tokens,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    await tester.tap(find.text('Accounts'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    final Finder clearCursors = find.text('Clear cursors');
    await tester.ensureVisible(clearCursors);
    await tester.pump();
    await tester.tap(clearCursors);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.text('Clear sync cursors?'), findsOneWidget);
    expect(
      find.textContaining(
        'Downloaded mail and folders on this device are not deleted',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Clear cursors').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(repo.clearCursorsCalls, 1);
    expect(
      find.textContaining('Downloaded mail was not deleted'),
      findsOneWidget,
    );
  });
}
