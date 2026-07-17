// ==============================================================================
// File: lib/app.dart
// Description: Root MaterialApp with BLoC providers and theme binding
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:bytemail/account/account_service.dart';
import 'package:bytemail/auth/oauth_identity_manager.dart';
import 'package:bytemail/desktop/detached_message_window_controller.dart';
import 'package:bytemail/desktop/message_file_service.dart';
import 'package:bytemail/desktop/windows_desktop_controller.dart';
import 'package:bytemail/mailbox/message_action_service.dart';
import 'package:bytemail/mailbox/message_body_cache.dart';
import 'package:bytemail/mime/eml_codec.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/sync/retention_service.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/ui/shell/eml_preview_sheet.dart';
import 'package:bytemail/ui/shell/mail_workspace.dart';

class ByteMailApp extends StatelessWidget {
  const ByteMailApp({
    super.key,
    required this.prefs,
    required this.repository,
    required this.syncEngine,
    required this.accountService,
    required this.identityManager,
    required this.resolveProvider,
    this.retentionService,
    this.settingsCubit,
    this.desktopController = const NoopDesktopController(),
    this.detachedMessageWindowController =
        const NoopDetachedMessageWindowController(),
    this.launchEmlPath,
  });

  final SharedPreferences prefs;
  final MailRepository repository;
  final SyncEngine syncEngine;
  final AccountService accountService;
  final OAuthIdentityManager identityManager;
  final ProviderResolver resolveProvider;
  final RetentionService? retentionService;
  final AppSettingsCubit? settingsCubit;
  final DesktopController desktopController;
  final DetachedMessageWindowController detachedMessageWindowController;
  final String? launchEmlPath;

  @override
  Widget build(BuildContext context) {
    final RetentionService retention =
        retentionService ?? RetentionService(repository);
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MailRepository>.value(value: repository),
        RepositoryProvider<SyncEngine>.value(value: syncEngine),
        RepositoryProvider<RetentionService>.value(value: retention),
        RepositoryProvider<AccountService>.value(value: accountService),
        RepositoryProvider<OAuthIdentityManager>.value(value: identityManager),
        RepositoryProvider<DesktopController>.value(value: desktopController),
        RepositoryProvider<DetachedMessageWindowController>.value(
          value: detachedMessageWindowController,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          if (settingsCubit != null)
            BlocProvider<AppSettingsCubit>.value(value: settingsCubit!)
          else
            BlocProvider(
              create: (_) => AppSettingsCubit(prefs),
            ),
          BlocProvider(
            create: (context) {
              final AppSettingsCubit settings =
                  context.read<AppSettingsCubit>();
              final MessageActionService actions = MessageActionService(
                repository: repository,
                resolveProvider: resolveProvider,
                syncEngine: syncEngine,
              );
              final MessageBodyCache bodyCache = MessageBodyCache(
                repository: repository,
                resolveProvider: resolveProvider,
                deviceRetentionDays: () => settings.state.retentionDays,
              );
              final cubit = MailboxCubit(
                repository: repository,
                settingsCubit: settings,
                actions: actions,
                bodyCache: bodyCache,
                syncEngine: syncEngine,
              );
              cubit.attachDbWatch();
              return cubit;
            },
          ),
        ],
        child: BlocListener<AppSettingsCubit, AppSettingsState>(
          listenWhen: (AppSettingsState previous, AppSettingsState next) =>
              previous.minimizeToTray != next.minimizeToTray,
          listener: (BuildContext context, AppSettingsState settings) {
            unawaited(
              desktopController.setMinimizeToTrayEnabled(
                settings.minimizeToTray,
              ),
            );
          },
          child: BlocBuilder<AppSettingsCubit, AppSettingsState>(
            builder: (context, settings) {
              return MaterialApp(
                title: 'ByteMail',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.materialThemeFor(settings.themeId),
                home: _LaunchHome(launchEmlPath: launchEmlPath),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LaunchHome extends StatefulWidget {
  const _LaunchHome({this.launchEmlPath});

  final String? launchEmlPath;

  @override
  State<_LaunchHome> createState() => _LaunchHomeState();
}

class _LaunchHomeState extends State<_LaunchHome> {
  @override
  void initState() {
    super.initState();
    final String? path = widget.launchEmlPath;
    if (path == null || path.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        return;
      }
      try {
        final EmlPreview preview = await openEmlPreviewFromPath(path);
        if (!mounted) {
          return;
        }
        await showEmlPreviewSheet(context, preview: preview);
      } catch (error) {
        if (!mounted) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to open EML: $error')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => const MailWorkspace();
}
