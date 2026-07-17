// ==============================================================================
// File: lib/main.dart
// Description: Application entrypoint; opens database and seeds demo mail
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:bytemail/account/account_service.dart';
import 'package:bytemail/app.dart';
import 'package:bytemail/auth/oauth_identity_manager.dart';
import 'package:bytemail/auth/secure_credential_store.dart';
import 'package:bytemail/desktop/detached_message_app.dart';
import 'package:bytemail/desktop/detached_message_window_controller.dart';
import 'package:bytemail/desktop/windows_desktop_controller.dart';
import 'package:bytemail/repository/database.dart';
import 'package:bytemail/repository/drift_mail_repository.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/sync/provider_registry.dart';
import 'package:bytemail/sync/retention_service.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/widgets/widget_snapshot_service.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

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
              title: 'ByteMail message',
            ),
            () async {
              await windowManager.show();
              await windowManager.focus();
            },
          );
          final ByteMailDatabase database = ByteMailDatabase.open();
          final DriftMailRepository repository = DriftMailRepository(database);
          runApp(
            DetachedMessageApp(
              repository: repository,
              windowController: windowController,
              initialMessageId: decoded['messageId'] as String,
            ),
          );
          return;
        }
      } on FormatException {
        // Fall through to the main shell for unrecognized args.
      }
    }
  }

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final ByteMailDatabase database = ByteMailDatabase.open();
  final DriftMailRepository repository = DriftMailRepository(database);
  final SecureCredentialStore credentialStore = SecureCredentialStore();
  final OAuthIdentityManager identityManager = OAuthIdentityManager(
    credentialStore,
    config: GraphAuthConfig.fromEnvironment(),
    googleConfig: GoogleAuthConfig.fromEnvironment(),
  );
  final WidgetSnapshotService widgetSnapshots =
      WidgetSnapshotService(repository);
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
  final SyncEngine syncEngine = SyncEngine(
    repository: repository,
    resolveProvider: providerRegistry.resolve,
    trashRetentionDays: () => settingsCubit.state.trashRetentionDays,
    deviceRetentionDays: () => settingsCubit.state.retentionDays,
    pushOnCellular: () => settingsCubit.state.pushOnCellular,
  );
  syncEngine.startNetworkWatcher();
  await repository.seedDemoDataIfEmpty();
  await widgetSnapshots.refreshAll();

  final DesktopController desktopController =
      (!kIsWeb && Platform.isWindows)
      ? WindowsDesktopController(
          minimizeToTrayEnabled: settingsCubit.state.minimizeToTray,
        )
      : const NoopDesktopController();
  await desktopController.initialize();

  if (!kIsWeb && Platform.isWindows) {
    final WindowController mainWindowController =
        await WindowController.fromCurrentEngine();
    await mainWindowController.setWindowMethodHandler((
      MethodCall call,
    ) async {
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
    ByteMailApp(
      prefs: prefs,
      repository: repository,
      syncEngine: syncEngine,
      retentionService: retentionService,
      accountService: accountService,
      identityManager: identityManager,
      resolveProvider: providerRegistry.resolve,
      settingsCubit: settingsCubit,
      desktopController: desktopController,
      detachedMessageWindowController: detachedWindowController,
      launchEmlPath: launchEmlPath,
    ),
  );
}
