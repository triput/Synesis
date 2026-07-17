import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemail/account/account_service.dart';
import 'package:bytemail/app.dart';
import 'package:bytemail/auth/oauth_identity_manager.dart';
import 'package:bytemail/auth/secure_credential_store.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/query/message_query.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';

class _FakeRepo implements MailRepository {
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
  }) async =>
      ResolvedSyncPolicy(
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
  Future<List<MailAccount>> listAccounts() async => const [
    MailAccount(
      id: 'work',
      label: 'W',
      address: 'work@byte.io',
      accent: Color(0xFF2DD4BF),
    ),
  ];

  @override
  Future<List<MailFolder>> listFolders({String? accountId}) async => const [
    MailFolder(
      id: 'inbox-work',
      accountId: 'work',
      name: 'Inbox',
      remoteId: 'INBOX',
      role: 'inbox',
      unreadCount: 1,
    ),
  ];

  @override
  Future<MailFolder?> getFolder(String id) async {
    for (final MailFolder folder in await listFolders()) {
      if (folder.id == id) {
        return folder;
      }
    }
    return null;
  }

  @override
  Future<void> upsertFolders(List<MailFolder> folders) async {}

  @override
  Future<List<MailMessage>> listMessages(MessageQuery query) async => const [
    MailMessage(
      id: '1',
      accountId: 'work',
      fromName: 'Maya Chen',
      fromAddress: 'maya@byte.io',
      subject: 'Hello',
      snippet: 'Snippet',
      body: 'Body',
      whenLabel: '10:14',
      bucket: FocusBucket.focused,
      folderId: 'inbox-work',
    ),
  ];

  @override
  Future<List<OutboxItem>> listOutbox() async => const [];

  @override
  Future<List<MailMessage>> searchLocal(String query) async => const [];

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
  Future<void> upsertMessages(
    List<MailMessage> messages, {
    required String folderId,
  }) async {}

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
  Stream<void> watchChanges() => const Stream.empty();

  @override
  Future<void> wipeAccount(String accountId) async {}

  @override
  Future<List<FocusRule>> listFocusRules({String? accountId}) async =>
      const <FocusRule>[];

  @override
  Future<void> upsertFocusRule(FocusRule rule) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('ByteMail shell renders Unified Inbox', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final repo = _FakeRepo();
    final syncEngine = SyncEngine(
      repository: repo,
      resolveProvider: (_) async => null,
    );
    final SecureCredentialStore credentialStore = SecureCredentialStore();
    final OAuthIdentityManager identityManager = OAuthIdentityManager(
      credentialStore,
    );
    final accountService = AccountService(
      repo,
      credentialStore,
      identityManager,
    );

    final view = tester.view;
    view.physicalSize = const Size(1400, 900);
    view.devicePixelRatio = 1.0;
    addTearDown(view.resetPhysicalSize);
    addTearDown(view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ByteMailApp(
        prefs: prefs,
        repository: repo,
        syncEngine: syncEngine,
        accountService: accountService,
        identityManager: identityManager,
        resolveProvider: (_) async => null,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('ByteMail'), findsOneWidget);
    expect(find.textContaining('Unified'), findsWidgets);
    expect(find.text('Maya Chen'), findsOneWidget);
  });
}
