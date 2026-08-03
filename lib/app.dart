// ==============================================================================
// File: lib/app.dart
// Description: Root MaterialApp with BLoC providers and theme binding
// Component: UI
// Version: 1.3 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-27
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:synesis/account/account_service.dart';
import 'package:synesis/auth/oauth_identity_manager.dart';
import 'package:synesis/desktop/detached_message_window_controller.dart';
import 'package:synesis/desktop/message_file_service.dart';
import 'package:synesis/desktop/windows_desktop_controller.dart';
import 'package:synesis/mailbox/message_action_service.dart';
import 'package:synesis/mailbox/message_body_cache.dart';
import 'package:synesis/mime/eml_codec.dart';
import 'package:synesis/notifications/app_foreground_tracker.dart';
import 'package:synesis/pim/meeting_invite_service.dart';
import 'package:synesis/repository/drift/drift_pim_store.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/settings/app_settings_cubit.dart';
import 'package:synesis/settings/app_settings_state.dart';
import 'package:synesis/sync/retention_service.dart';
import 'package:synesis/sync/sync_activity.dart';
import 'package:synesis/sync/sync_engine.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/theme/custom_theme.dart';
import 'package:synesis/theme/theme_tokens.dart';
import 'package:synesis/ui/calendar/calendar_cubit.dart';
import 'package:synesis/ui/mailbox/mailbox_cubit.dart';
import 'package:synesis/ui/people/people_cubit.dart';
import 'package:synesis/ui/shell/eml_preview_sheet.dart';
import 'package:synesis/ui/shell/module_shell.dart';

class SynesisApp extends StatelessWidget {
  const SynesisApp({
    super.key,
    required this.prefs,
    required this.repository,
    required this.syncEngine,
    required this.syncActivity,
    required this.accountService,
    required this.identityManager,
    required this.resolveProvider,
    required this.pimStore,
    this.meetingInviteService,
    this.retentionService,
    this.settingsCubit,
    this.desktopController = const NoopDesktopController(),
    this.detachedMessageWindowController =
        const NoopDetachedMessageWindowController(),
    this.foregroundTracker,
    this.launchEmlPath,
  });

  final SharedPreferences prefs;
  final MailRepository repository;
  final SyncEngine syncEngine;
  final SyncActivity syncActivity;
  final AccountService accountService;
  final OAuthIdentityManager identityManager;
  final ProviderResolver resolveProvider;
  final MeetingInviteService? meetingInviteService;
  final RetentionService? retentionService;
  final AppSettingsCubit? settingsCubit;
  final DesktopController desktopController;
  final DetachedMessageWindowController detachedMessageWindowController;
  final AppForegroundTracker? foregroundTracker;
  final String? launchEmlPath;
  final DriftPimStore pimStore;

  @override
  Widget build(BuildContext context) {
    final RetentionService retention =
        retentionService ?? RetentionService(repository);
    final Widget tree = MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MailRepository>.value(value: repository),
        RepositoryProvider<SyncEngine>.value(value: syncEngine),
        RepositoryProvider<SyncActivity>.value(value: syncActivity),
        RepositoryProvider<RetentionService>.value(value: retention),
        RepositoryProvider<AccountService>.value(value: accountService),
        RepositoryProvider<OAuthIdentityManager>.value(value: identityManager),
        RepositoryProvider<DriftPimStore>.value(value: pimStore),
        if (meetingInviteService != null)
          RepositoryProvider<MeetingInviteService>.value(
            value: meetingInviteService!,
          ),
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
            BlocProvider(create: (_) => AppSettingsCubit(prefs)),
          BlocProvider(
            create: (context) {
              final AppSettingsCubit settings = context
                  .read<AppSettingsCubit>();
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
          BlocProvider<CalendarCubit>(
            create: (context) => CalendarCubit(
              pimStore: pimStore,
              repository: repository,
              settingsCubit: context.read<AppSettingsCubit>(),
            ),
          ),
          BlocProvider<PeopleCubit>(
            create: (context) =>
                PeopleCubit(pimStore: pimStore, repository: repository),
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
              return _ThemedMailApp(
                settings: settings,
                repository: repository,
                launchEmlPath: launchEmlPath,
              );
            },
          ),
        ),
      ),
    );
    final AppForegroundTracker? tracker = foregroundTracker;
    if (tracker == null) {
      return tree;
    }
    return _ForegroundLifecycleBinder(tracker: tracker, child: tree);
  }
}

/// Resolves the active [ThemeData] — including an optional custom theme
/// fork (UI-P16) loaded from [MailRepository] — and hosts the [MaterialApp].
///
/// Custom theme tokens live in the database rather than
/// [SharedPreferences]-backed settings, so they are loaded asynchronously and
/// cached locally; [AppTheme.materialThemeFor] runs synchronously in `build`
/// using the most recently resolved tokens (falling back to the built-in
/// pack while a newly selected custom theme loads).
class _ThemedMailApp extends StatefulWidget {
  const _ThemedMailApp({
    required this.settings,
    required this.repository,
    this.launchEmlPath,
  });

  final AppSettingsState settings;
  final MailRepository repository;
  final String? launchEmlPath;

  @override
  State<_ThemedMailApp> createState() => _ThemedMailAppState();
}

class _ThemedMailAppState extends State<_ThemedMailApp> {
  String? _loadedCustomThemeId;
  ThemeTokens? _loadedTokens;

  @override
  void initState() {
    super.initState();
    _syncCustomTheme();
  }

  @override
  void didUpdateWidget(covariant _ThemedMailApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncCustomTheme();
  }

  void _syncCustomTheme() {
    final String? id = widget.settings.customThemeId;
    if (id == null) {
      if (_loadedCustomThemeId != null || _loadedTokens != null) {
        setState(() {
          _loadedCustomThemeId = null;
          _loadedTokens = null;
        });
      }
      return;
    }
    if (id == _loadedCustomThemeId) {
      return;
    }
    unawaited(_loadCustomTheme(id));
  }

  Future<void> _loadCustomTheme(String id) async {
    try {
      final CustomTheme? theme = await widget.repository.getCustomTheme(id);
      if (!mounted || widget.settings.customThemeId != id) {
        return;
      }
      setState(() {
        _loadedCustomThemeId = id;
        _loadedTokens = theme?.resolveTokens();
      });
    } catch (_) {
      if (!mounted || widget.settings.customThemeId != id) {
        return;
      }
      setState(() {
        _loadedCustomThemeId = id;
        _loadedTokens = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppSettingsState settings = widget.settings;
    final ThemeTokens? tokensOverride =
        settings.customThemeId != null &&
            settings.customThemeId == _loadedCustomThemeId
        ? _loadedTokens
        : null;
    return MaterialApp(
      title: 'Synesis',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.materialThemeFor(
        settings.themeId,
        tokensOverride: tokensOverride,
        uiFontFamily: settings.uiFontFamily,
        uiFontSizeScale: settings.uiFontSizeScale,
        uiTextColorOverride: settings.uiTextColorArgb == null
            ? null
            : Color(settings.uiTextColorArgb!),
      ),
      home: _LaunchHome(launchEmlPath: widget.launchEmlPath),
    );
  }
}

/// Binds [AppForegroundTracker] to the Flutter app lifecycle.
class _ForegroundLifecycleBinder extends StatefulWidget {
  const _ForegroundLifecycleBinder({
    required this.tracker,
    required this.child,
  });

  final AppForegroundTracker tracker;
  final Widget child;

  @override
  State<_ForegroundLifecycleBinder> createState() =>
      _ForegroundLifecycleBinderState();
}

class _ForegroundLifecycleBinderState
    extends State<_ForegroundLifecycleBinder> {
  @override
  void initState() {
    super.initState();
    widget.tracker.attach();
  }

  @override
  void dispose() {
    widget.tracker.detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Unable to open EML: $error')));
      }
    });
  }

  @override
  Widget build(BuildContext context) => const ModuleShell();
}
