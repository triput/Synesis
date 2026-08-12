// ==============================================================================
// File: test/account_sheets_overflow_test.dart
// Description: Phone-size RenderFlex overflow guards for account sheets (DEF-063)
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-03
// Last Update: 2026-08-03
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synesis/account/account_service.dart';
import 'package:synesis/auth/oauth_identity_manager.dart';
import 'package:synesis/auth/secure_credential_store.dart';
import 'package:synesis/compose/account_signature.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/sync_profile.dart';
import 'package:synesis/query/message_query.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/custom_theme.dart';
import 'package:synesis/theme/theme_id.dart';
import 'package:synesis/ui/account/edit_account_sheet.dart';
import 'package:synesis/ui/account/manage_accounts_sheet.dart';
import 'package:synesis/ui/account/remove_account_dialog.dart';
import 'package:synesis/ui/mailbox/mailbox_cubit.dart';
import 'package:synesis/ui/mailbox/mailbox_state.dart';
import 'package:synesis/ui/settings/account_color_picker.dart';

/// Phone viewport used in DEF-063 dogfood (narrow Android).
const Size kPhoneSize = Size(360, 640);

/// Gesture-nav + status bar insets typical of Android gestural navigation.
const EdgeInsets kPhoneViewPadding = EdgeInsets.only(top: 24, bottom: 48);

List<MailAccount> _threeAccounts() {
  return const <MailAccount>[
    MailAccount(
      id: 'acc-graph',
      label: 'Work Microsoft Account With A Long Label',
      address: 'very.long.work.address@contoso.example.com',
      accent: Color(0xFF2563EB),
      providerType: 'graph',
      credentialsRef: 'graph:acc-graph',
      syncProfileId: 'default',
    ),
    MailAccount(
      id: 'acc-google',
      label: 'Personal Gmail',
      address: 'personal.user.name@gmail.com',
      accent: Color(0xFFBE185D),
      providerType: 'imap',
      credentialsRef: 'google:acc-google',
      syncProfileId: 'default',
    ),
    MailAccount(
      id: 'acc-imap',
      label: 'Runbox',
      address: 'trish@runbox.com',
      accent: Color(0xFF0F766E),
      providerType: 'imap',
      credentialsRef: 'imap:acc-imap',
      syncProfileId: 'default',
    ),
  ];
}

/// [MailboxCubit] stand-in that only supplies [state]/[stream] for sheet bodies.
class _FakeMailboxCubit extends Fake implements MailboxCubit {
  _FakeMailboxCubit(List<MailAccount> accounts)
      : state = MailboxState(accounts: accounts);

  @override
  final MailboxState state;

  @override
  Stream<MailboxState> get stream => Stream<MailboxState>.value(state);

  @override
  bool get isClosed => false;
}

class _MemCredentials extends SecureCredentialStore {
  _MemCredentials() : super();

  final Map<String, Map<String, String>> _secrets =
      <String, Map<String, String>>{};

  @override
  Future<void> writeSecret({
    required String credentialsRef,
    required String name,
    required String value,
  }) async {
    _secrets.putIfAbsent(credentialsRef, () => <String, String>{})[name] =
        value;
  }

  @override
  Future<String?> readSecret({
    required String credentialsRef,
    required String name,
  }) async {
    return _secrets[credentialsRef]?[name];
  }

  @override
  Future<void> deleteSecret({
    required String credentialsRef,
    required String name,
  }) async {
    _secrets[credentialsRef]?.remove(name);
  }

  @override
  Future<void> deleteCredentials(String credentialsRef) async {
    _secrets.remove(credentialsRef);
  }
}

class _OverflowRepo implements MailRepository {
  @override
  Future<List<MailMessage>> searchLocal(String query) async => const <MailMessage>[];

  @override
  Future<int> applyRetention({
    required int retentionDays,
    String? accountId,
  }) async => 0;

  @override
  Future<List<SyncProfile>> listSyncProfiles() async => const <SyncProfile>[
        SyncProfile(
          id: 'default',
          name: 'Default',
          retentionDays: 180,
          bodyPolicy: BodyFetchPolicy.onOpen,
          attachmentMaxMb: 25,
          isDefault: true,
        ),
        SyncProfile(
          id: 'light',
          name: 'Light / headers-only with a long name',
          retentionDays: 30,
          bodyPolicy: BodyFetchPolicy.headersOnly,
          attachmentMaxMb: 10,
          isDefault: false,
        ),
      ];

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
  Future<List<MailAccount>> listAccounts() async => _threeAccounts();

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


class _OverflowCapture {
  _OverflowCapture() {
    _previous = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final String message = details.exceptionAsString();
      if (message.contains('overflowed') ||
          message.contains('A RenderFlex overflowed') ||
          message.contains('OVERFLOWING')) {
        overflow ??= details;
      }
      _previous?.call(details);
    };
  }

  void Function(FlutterErrorDetails)? _previous;
  FlutterErrorDetails? overflow;

  void restore() {
    FlutterError.onError = _previous;
  }

  void expectClean(WidgetTester tester) {
    expect(tester.takeException(), isNull);
    expect(
      overflow,
      isNull,
      reason: overflow?.exceptionAsString(),
    );
  }
}

Widget _phoneShell({
  required Widget child,
  EdgeInsets viewPadding = kPhoneViewPadding,
  EdgeInsets viewInsets = EdgeInsets.zero,
  List<MailAccount>? accounts,
  OAuthIdentityManager? identity,
  AccountService? accountService,
  MailRepository? repository,
}) {
  final _MemCredentials creds = _MemCredentials();
  final OAuthIdentityManager oauth =
      identity ?? OAuthIdentityManager(creds);
  final MailRepository repo = repository ?? _OverflowRepo();
  final AccountService accountsSvc =
      accountService ?? AccountService(repo, creds, oauth);

  // Providers wrap [MaterialApp] so modal bottom sheets (new routes) can
  // still read MailboxCubit / AccountService / OAuthIdentityManager.
  return MultiRepositoryProvider(
    providers: <RepositoryProvider<dynamic>>[
      RepositoryProvider<MailRepository>.value(value: repo),
      RepositoryProvider<AccountService>.value(value: accountsSvc),
      RepositoryProvider<OAuthIdentityManager>.value(value: oauth),
    ],
    child: BlocProvider<MailboxCubit>.value(
      value: _FakeMailboxCubit(accounts ?? _threeAccounts()),
      child: MaterialApp(
        theme: AppTheme.materialThemeFor(ThemeId.dark),
        builder: (BuildContext context, Widget? appChild) {
          final MediaQueryData base = MediaQuery.of(context);
          return MediaQuery(
            data: base.copyWith(
              size: kPhoneSize,
              viewPadding: viewPadding,
              padding: viewPadding,
              viewInsets: viewInsets,
              devicePixelRatio: 1,
            ),
            child: appChild ?? const SizedBox.shrink(),
          );
        },
        home: Scaffold(body: child),
      ),
    ),
  );
}

/// Mirrors production [showManageAccountsSheet] / [showEditAccountSheet] chrome.
Widget _sheetChrome({required Widget child}) {
  return Builder(
    builder: (BuildContext context) {
      final MediaQueryData mq = MediaQuery.of(context);
      return Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double maxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : mq.size.height * 0.9;
              return SizedBox(
                height: maxH * 0.95,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: child,
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets(
    'showManageAccountsSheet modal no RenderFlex overflow at 360x640 with viewPadding',
    (WidgetTester tester) async {
      final _OverflowCapture capture = _OverflowCapture();
      addTearDown(capture.restore);

      await tester.binding.setSurfaceSize(kPhoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _phoneShell(
          child: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () => showManageAccountsSheet(context),
                child: const Text('Open manage'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open manage'));
      await tester.pumpAndSettle();

      expect(find.text('Manage accounts'), findsOneWidget);
      expect(find.text('Add another account'), findsOneWidget);
      capture.expectClean(tester);
    },
  );

  testWidgets(
    'Settings Accounts primaryScroll no overflow at 360x640 with viewPadding',
    (WidgetTester tester) async {
      final _OverflowCapture capture = _OverflowCapture();
      addTearDown(capture.restore);

      await tester.binding.setSurfaceSize(kPhoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _phoneShell(
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 12),
              child: ManageAccountsSheetBody(primaryScroll: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      capture.expectClean(tester);
    },
  );

  testWidgets(
    'showEditAccountSheet Google no overflow at 360x640 with viewPadding',
    (WidgetTester tester) async {
      final _OverflowCapture capture = _OverflowCapture();
      addTearDown(capture.restore);
      final MailAccount google = _threeAccounts()[1];
      final _MemCredentials creds = _MemCredentials();
      final OAuthIdentityManager identity = OAuthIdentityManager(
        creds,
        googleConfig: const GoogleAuthConfig(
          clientId: 'test-google-client.apps.googleusercontent.com',
          androidClientId:
              'test-google-android-client.apps.googleusercontent.com',
        ),
      );

      await tester.binding.setSurfaceSize(kPhoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _phoneShell(
          identity: identity,
          child: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () => showEditAccountSheet(context, google),
                child: const Text('Open edit'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open edit'));
      await tester.pumpAndSettle();

      expect(find.text('Edit account'), findsOneWidget);
      expect(find.text('Google (IMAP / OAuth)'), findsOneWidget);
      // Exercise the long Google help / re-auth CTA extent inside the sheet.
      for (int i = 0; i < 4; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -300));
        await tester.pump();
      }
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Re-authenticate').evaluate().isNotEmpty ||
            find.textContaining('Google OAuth').evaluate().isNotEmpty,
        isTrue,
        reason: 'Expected Google re-auth CTA or OAuth config help text',
      );
      capture.expectClean(tester);
    },
  );

  testWidgets(
    'EditAccountForm no overflow when keyboard viewInsets shrink height',
    (WidgetTester tester) async {
      final _OverflowCapture capture = _OverflowCapture();
      addTearDown(capture.restore);
      final MailAccount graph = _threeAccounts().first;
      final _MemCredentials creds = _MemCredentials();
      final OAuthIdentityManager identity = OAuthIdentityManager(
        creds,
        config: const GraphAuthConfig(clientId: 'test-graph-client'),
      );

      await tester.binding.setSurfaceSize(kPhoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      // Short phone + large keyboard + text scale — sticky Save-only footer
      // must still fit (signatures/templates scroll inside the form).
      await tester.pumpWidget(
        _phoneShell(
          identity: identity,
          viewInsets: const EdgeInsets.only(bottom: 320),
          child: MediaQuery(
            data: const MediaQueryData(
              size: kPhoneSize,
              viewPadding: kPhoneViewPadding,
              padding: EdgeInsets.only(top: 24),
              viewInsets: EdgeInsets.only(bottom: 320),
              devicePixelRatio: 1,
              textScaler: TextScaler.linear(1.2),
            ),
            child: _sheetChrome(child: EditAccountForm(account: graph)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Save changes'), findsOneWidget);
      capture.expectClean(tester);
    },
  );

  testWidgets(
    'RemoveAccountDialog no overflow at 360x640 with viewPadding',
    (WidgetTester tester) async {
      final _OverflowCapture capture = _OverflowCapture();
      addTearDown(capture.restore);
      final MailAccount account = _threeAccounts().first;

      await tester.binding.setSurfaceSize(kPhoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _phoneShell(
          child: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () => showRemoveAccountDialog(context, account),
                child: const Text('Open remove'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open remove'));
      await tester.pumpAndSettle();

      expect(find.text('Remove account'), findsWidgets);
      capture.expectClean(tester);
    },
  );

  testWidgets(
    'AccountColorPicker custom dialog no overflow at 360x640',
    (WidgetTester tester) async {
      final _OverflowCapture capture = _OverflowCapture();
      addTearDown(capture.restore);

      await tester.binding.setSurfaceSize(kPhoneSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _phoneShell(
          child: AccountColorPicker(
            value: const Color(0xFF2563EB),
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Custom'));
      await tester.pumpAndSettle();

      expect(find.text('Custom account color'), findsOneWidget);
      capture.expectClean(tester);
    },
  );
}
