// ==============================================================================
// File: lib/desktop/detached_message_app.dart
// Description: Minimal secondary-window reader for one local message.
// Component: UI / Desktop
// Version: 1.2 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:async';

import 'package:bytemail/desktop/detached_message_window_controller.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/density.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/ui/shell/html_email_body.dart';
import 'package:bytemail/ui/shell/reading_pane.dart';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:window_manager/window_manager.dart';

const String showMainWindowMethod = 'show_main_window';

class DetachedMessageApp extends StatefulWidget {
  const DetachedMessageApp({
    super.key,
    required this.repository,
    required this.windowController,
    required this.initialMessageId,
  });

  final MailRepository repository;
  final WindowController windowController;
  final String initialMessageId;

  @override
  State<DetachedMessageApp> createState() => _DetachedMessageAppState();
}

class _DetachedMessageAppState extends State<DetachedMessageApp> {
  MailMessage? _message;
  List<MailAccount> _accounts = const <MailAccount>[];
  Object? _error;

  @override
  void initState() {
    super.initState();
    unawaited(
      widget.windowController.setWindowMethodHandler((MethodCall call) async {
        if (call.method != detachedMessageUpdateMethod) {
          return null;
        }
        final Object? arguments = call.arguments;
        if (arguments is Map && arguments['messageId'] is String) {
          await _load(arguments['messageId'] as String);
        }
        return null;
      }),
    );
    unawaited(_load(widget.initialMessageId));
  }

  Future<void> _load(String messageId) async {
    try {
      final List<MailAccount> accounts = await widget.repository.listAccounts();
      final MailMessage? message =
          await widget.repository.getMessage(messageId);
      if (!mounted) {
        return;
      }
      setState(() {
        _accounts = accounts;
        _message = message;
        _error = message == null ? StateError('Message not found.') : null;
      });
      final String title = (message?.subject.trim().isNotEmpty ?? false)
          ? message!.subject.trim()
          : 'ByteMail message';
      await windowManager.setTitle(title);
    } catch (error) {
      if (mounted) {
        setState(() => _error = error);
      }
    }
  }

  /// Applies a read/unread change locally and to the shared repository so
  /// DEF-034 / UI-P27 auto-mark-as-read behaves identically in the detached
  /// reader window.
  Future<void> _setUnread(String messageId, bool unread) async {
    try {
      await widget.repository.setUnread(messageId, unread);
    } catch (_) {
      // Best-effort: the detached window has no snackbar surface for this.
    }
    if (!mounted) {
      return;
    }
    final MailMessage? current = _message;
    if (current == null || current.id != messageId) {
      return;
    }
    setState(() {
      _message = current.copyWith(unread: unread);
    });
  }

  Future<void> _showMainWindow() async {
    final List<WindowController> windows = await WindowController.getAll();
    for (final WindowController controller in windows) {
      if (controller.windowId == widget.windowController.windowId) {
        continue;
      }
      try {
        await controller.invokeMethod<void>(showMainWindowMethod);
        return;
      } on PlatformException {
        continue;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final MailMessage? message = _message;
    return RepositoryProvider<DetachedMessageWindowController>.value(
      value: const NoopDetachedMessageWindowController(),
      child: MaterialApp(
        title: message?.subject ?? 'ByteMail message',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.materialThemeFor(ThemeId.dark),
        // Subject lives in the OS title + ReadingPane chrome — no AppBar title.
        home: Scaffold(
          appBar: AppBar(
            title: const Text('ByteMail'),
            actions: <Widget>[
              IconButton(
                tooltip: 'Show main window',
                onPressed: _showMainWindow,
                icon: const Icon(Icons.open_in_browser_rounded),
              ),
              IconButton(
                tooltip: 'Close',
                onPressed: windowManager.close,
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          body: _error != null
              ? Center(child: Text('Unable to open message: $_error'))
              : message == null
              ? const Center(child: CircularProgressIndicator())
              : PreferWidgetHtmlScope(
                  enabled: true,
                  child: ReadingPane(
                    message: message,
                    accounts: _accounts,
                    density: ViewDensity.calm,
                    allowOpenInNewWindow: false,
                    onMarkRead: () => unawaited(_setUnread(message.id, false)),
                    onMarkUnread: () => unawaited(_setUnread(message.id, true)),
                  ),
                ),
        ),
      ),
    );
  }
}
