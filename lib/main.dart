// ==============================================================================
// File: lib/main.dart
// Description: Application entrypoint; opens database and seeds demo mail
// Component: UI
// Version: 1.4 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-27
// ==============================================================================

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:synesis/account/account_service.dart';
import 'package:synesis/app.dart';
import 'package:synesis/auth/oauth_config_resolver.dart';
import 'package:synesis/auth/oauth_identity_manager.dart';
import 'package:synesis/auth/secure_credential_store.dart';
import 'package:synesis/desktop/detached_message_app.dart';
import 'package:synesis/desktop/detached_message_window_controller.dart';
import 'package:synesis/desktop/windows_desktop_controller.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/mailbox/message_action_service.dart';
import 'package:synesis/notifications/android_notification_adapter.dart';
import 'package:synesis/notifications/app_foreground_tracker.dart';
import 'package:synesis/notifications/notification_platform.dart';
import 'package:synesis/notifications/notification_service.dart';
import 'package:synesis/notifications/windows_notification_adapter.dart';
import 'package:synesis/pim/meeting_invite_service.dart';
import 'package:synesis/repository/database.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/drift_mail_repository.dart';
import 'package:synesis/settings/app_settings_cubit.dart';
import 'package:synesis/sync/pim_copy_service.dart';
import 'package:synesis/sync/provider_registry.dart';
import 'package:synesis/sync/retention_service.dart';
import 'package:synesis/sync/sync_activity.dart';
import 'package:synesis/sync/sync_engine.dart';
import 'package:synesis/widgets/widget_snapshot_service.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  if (!kIsWeb && Platform.isWindows) {
    final WindowController windowController =
        await WindowController.fromCurrentEngine();
    final String windowArgs = windowController.arguments.trim();
    if (windowArgs.isNotEmpty) {
      try {
        final Object? decoded = jsonDecode(windowArgs);
        if (decoded is Map &&
            decoded['type'] == detachedMessageWindowType &&
            decoded['messageId'] is String) {
          await windowManager.ensureInitialized();
          windowManager.waitUntilReadyToShow(
            const WindowOptions(
              size: Size(720, 900),
              center: true,
              title: 'Synesis message',
            ),
            () async {
              await windowManager.show();
              await windowManager.focus();
            },
          );
          final SynesisDatabase database = SynesisDatabase.open();
          final DriftMailRepository repository = DriftMailRepository(database);
          final AppSettingsCubit detachedSettingsCubit = AppSettingsCubit(
            prefs,
          );
          final int detachedAutoMarkAsReadSeconds =
              detachedSettingsCubit.state.autoMarkAsReadSeconds;
          unawaited(detachedSettingsCubit.close());
          runApp(
            DetachedMessageApp(
              repository: repository,
              windowController: windowController,
              initialMessageId: decoded['messageId'] as String,
              autoMarkAsReadSeconds: detachedAutoMarkAsReadSeconds,
            ),
          );
          return;
        }
      } on FormatException {
        // Fall through to the main shell for unrecognized args.
      }
    }
  }

  final SynesisDatabase database = SynesisDatabase.open();
  final DriftMailRepository repository = DriftMailRepository(database);
  final SecureCredentialStore credentialStore = SecureCredentialStore();
  // dart-define → OS env → oauth_local.json (see OAuthConfigResolver / README).
  final ({GraphAuthConfig graph, GoogleAuthConfig google}) oauthConfigs =
      await OAuthConfigResolver.loadForStartup();
  final OAuthIdentityManager identityManager = OAuthIdentityManager(
    credentialStore,
    config: oauthConfigs.graph,
    googleConfig: oauthConfigs.google,
  );
  final WidgetSnapshotService widgetSnapshots = WidgetSnapshotService(
    repository,
  );
  final AccountService accountService = AccountService(
    repository,
    credentialStore,
    identityManager,
    widgetSnapshots: widgetSnapshots,
  );
  final ProviderRegistry providerRegistry = ProviderRegistry(
    repository: repository,
    credentialStore: credentialStore,
    identityManager: identityManager,
  );
  final AppSettingsCubit settingsCubit = AppSettingsCubit(prefs);
  final RetentionService retentionService = RetentionService(repository);

  final DesktopController desktopController = (!kIsWeb && Platform.isWindows)
      ? WindowsDesktopController(
          minimizeToTrayEnabled: settingsCubit.state.minimizeToTray,
        )
      : const NoopDesktopController();
  await desktopController.initialize();

  final AppForegroundTracker foregroundTracker = AppForegroundTracker();
  final NotificationPlatform notificationPlatform = _buildNotificationPlatform(
    desktopController: desktopController,
  );

  // `notificationService` is referenced by `syncEngine.onNewUnread` below
  // before it exists — declared `late final` and assigned once
  // `toastActionService` (which needs `syncEngine` itself) is ready. Safe:
  // the closure only runs once real sync activity occurs, well after both
  // are assigned.
  late final NotificationService notificationService;

  // Wave 5: share `repository`'s broadcast change stream so Calendar/People/
  // compose-picker cubits (which watch `repository.watchChanges()`) refresh
  // whenever a PIM row is written, without a second stream to keep in sync.
  final DriftPimStore pimStore = DriftPimStore(
    database,
    notify: repository.notifyChanges,
  );

  final SyncActivity syncActivity = SyncActivity(repository: repository);
  syncActivity.start();

  final SyncEngine syncEngine = SyncEngine(
    repository: repository,
    resolveProvider: providerRegistry.resolve,
    pimStore: pimStore,
    resolvePim: providerRegistry.resolvePim,
    trashRetentionDays: () => settingsCubit.state.trashRetentionDays,
    deviceRetentionDays: () => settingsCubit.state.retentionDays,
    pushOnCellular: () => settingsCubit.state.pushOnCellular,
    onNewUnread: (List<MailMessage> messages) =>
        notificationService.onNewMail(messages),
  );
  syncEngine.attachSyncActivity(syncActivity);
  final MeetingInviteService meetingInviteService = MeetingInviteService(
    pimStore: pimStore,
    repository: repository,
    resolvePim: providerRegistry.resolvePim,
    resolveMail: providerRegistry.resolve,
  );
  final PimCopyService pimCopyService = PimCopyService(
    pimStore: pimStore,
    repository: repository,
    resolvePim: providerRegistry.resolvePim,
  );
  syncEngine.startNetworkWatcher();

  // D6-8: dedicated service for Windows toast Archive/Delete actions. These
  // fire outside the widget tree, so they cannot reach the live
  // MailboxCubit-bound MessageActionService created in `app.dart`. Mutating
  // the shared `repository` here is safe — the mailbox UI's
  // `attachDbWatch()` (see `app.dart`) already refreshes whenever the
  // repository's change stream fires, exactly as it does for any in-app
  // archive/delete action.
  final MessageActionService toastActionService = MessageActionService(
    repository: repository,
    resolveProvider: providerRegistry.resolve,
    syncEngine: syncEngine,
  );

  notificationService = NotificationService(
    settings: AppSettingsNotificationSource(settingsCubit),
    platform: notificationPlatform,
    isAppForeground: () {
      if (!kIsWeb && Platform.isWindows) {
        return desktopController.isWindowFocused;
      }
      return foregroundTracker.isForeground;
    },
    onArchiveMessage: (String messageId) {
      unawaited(toastActionService.archiveMessageById(messageId));
    },
    onDeleteMessage: (String messageId) {
      unawaited(toastActionService.deleteMessageById(messageId));
    },
  );
  await notificationService.initialize();
  await repository.seedDemoDataIfEmpty();
  await widgetSnapshots.refreshAll(themeId: settingsCubit.state.themeId);

  if (!kIsWeb && Platform.isWindows) {
    final WindowController mainWindowController =
        await WindowController.fromCurrentEngine();
    await mainWindowController.setWindowMethodHandler((MethodCall call) async {
      if (call.method == showMainWindowMethod) {
        await desktopController.show();
      }
      return null;
    });
  }

  final DetachedMessageWindowController detachedWindowController =
      (!kIsWeb && Platform.isWindows)
      ? WindowsDetachedMessageWindowController()
      : const NoopDetachedMessageWindowController();

  final String? launchEmlPath = args.cast<String?>().firstWhere(
    (String? value) => value != null && value.toLowerCase().endsWith('.eml'),
    orElse: () => null,
  );

  runApp(
    SynesisApp(
      prefs: prefs,
      repository: repository,
      syncEngine: syncEngine,
      syncActivity: syncActivity,
      retentionService: retentionService,
      accountService: accountService,
      identityManager: identityManager,
      meetingInviteService: meetingInviteService,
      pimCopyService: pimCopyService,
      resolveProvider: providerRegistry.resolve,
      pimStore: pimStore,
      settingsCubit: settingsCubit,
      desktopController: desktopController,
      detachedMessageWindowController: detachedWindowController,
      foregroundTracker: foregroundTracker,
      launchEmlPath: launchEmlPath,
    ),
  );
}

NotificationPlatform _buildNotificationPlatform({
  required DesktopController desktopController,
}) {
  if (kIsWeb) {
    return const NoopNotificationPlatform();
  }
  if (Platform.isAndroid) {
    return AndroidNotificationAdapter();
  }
  if (Platform.isWindows) {
    return WindowsNotificationAdapter(
      onNotificationClick: () {
        unawaited(desktopController.show());
      },
    );
  }
  return const NoopNotificationPlatform();
}
