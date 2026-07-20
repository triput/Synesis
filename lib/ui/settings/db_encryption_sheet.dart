// ==============================================================================
// File: lib/ui/settings/db_encryption_sheet.dart
// Description: Opt-in local database encryption toggle, passphrase, warning UX
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bytemail/desktop/windows_desktop_controller.dart';
import 'package:bytemail/repository/db_encryption_config.dart';
import 'package:bytemail/repository/db_encryption_migrator.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';

/// Shows the "Encrypt local database" settings sheet.
Future<void> showDbEncryptionSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: tokensOf(context).panel,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => const _DbEncryptionSheet(),
  );
}

class _DbEncryptionSheet extends StatefulWidget {
  const _DbEncryptionSheet();

  @override
  State<_DbEncryptionSheet> createState() => _DbEncryptionSheetState();
}

class _DbEncryptionSheetState extends State<_DbEncryptionSheet> {
  final DbEncryptionConfig _config = DbEncryptionConfig();
  bool _loading = true;
  bool _enabled = false;
  bool _busy = false;
  String? _busyMessage;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bool enabled = await _config.isEnabled();
    if (!mounted) {
      return;
    }
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<String> _resolveDatabasePath() async {
    final Directory directory = await getApplicationSupportDirectory();
    return DbEncryptionPaths.databasePath(directory.path);
  }

  Future<void> _onToggle(bool next) {
    return next ? _startEnableFlow() : _startDisableFlow();
  }

  Future<void> _startEnableFlow() async {
    final String? passphrase = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => const _EnableEncryptionDialog(),
    );
    if (passphrase == null || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _busyMessage = 'Encrypting local mailbox…';
    });
    try {
      final String dbPath = await _resolveDatabasePath();
      await const DbEncryptionMigrator().encryptInPlace(
        databasePath: dbPath,
        passphrase: passphrase,
      );
      await _config.setPassphrase(passphrase);
      await _config.setEnabled(true);
      if (!mounted) {
        return;
      }
      setState(() {
        _enabled = true;
        _busy = false;
        _busyMessage = null;
      });
      await _promptRestart();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = null;
          _error = 'Could not enable encryption: $error';
        });
      }
    }
  }

  Future<void> _startDisableFlow() async {
    final bool confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext dialogContext) => AlertDialog(
            title: const Text('Turn off encryption?'),
            content: const Text(
              'ByteMail will decrypt the local mailbox back to plain '
              'SQLite. This does not affect your mail on the server.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Decrypt'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _busyMessage = 'Decrypting local mailbox…';
    });
    try {
      final String? passphrase = await _config.readPassphrase();
      if (passphrase == null) {
        throw StateError(
          'No stored passphrase was found, so the database cannot be '
          'safely decrypted. Encryption remains enabled.',
        );
      }
      final String dbPath = await _resolveDatabasePath();
      await const DbEncryptionMigrator().decryptInPlace(
        databasePath: dbPath,
        passphrase: passphrase,
      );
      await _config.setEnabled(false);
      await _config.clearPassphrase();
      if (!mounted) {
        return;
      }
      setState(() {
        _enabled = false;
        _busy = false;
        _busyMessage = null;
      });
      await _promptRestart();
    } catch (error) {
      if (mounted) {
        setState(() {
          _busy = false;
          _busyMessage = null;
          _error = 'Could not disable encryption: $error';
        });
      }
    }
  }

  Future<void> _promptRestart() async {
    if (!mounted) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('Restart required'),
        content: const Text(
          'ByteMail must restart to reopen the mailbox with this change '
          'applied.',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (!mounted) {
                return;
              }
              if (Platform.isWindows) {
                await context.read<DesktopController>().quit();
              } else {
                await SystemNavigator.pop();
              }
            },
            child: const Text('Restart now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: _loading
          ? const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Encryption',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Encrypt the local mailbox database at rest with a '
                    'passphrase you choose. This is separate from TLS, '
                    'which already protects sync in transit.',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Encrypt local database'),
                    subtitle: Text(
                      _enabled
                          ? 'Enabled — local mail is encrypted at rest.'
                          : 'Disabled — local mail is stored as plain '
                                'SQLite.',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    value: _enabled,
                    onChanged: _busy ? null : _onToggle,
                  ),
                  if (_busy) ...<Widget>[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                    const SizedBox(height: 8),
                    Text(
                      _busyMessage ?? 'Working…',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                  ],
                  if (_error != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: t.coral, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _EnableEncryptionDialog extends StatefulWidget {
  const _EnableEncryptionDialog();

  @override
  State<_EnableEncryptionDialog> createState() =>
      _EnableEncryptionDialogState();
}

class _EnableEncryptionDialogState extends State<_EnableEncryptionDialog> {
  final TextEditingController _passphrase = TextEditingController();
  final TextEditingController _confirmPassphrase = TextEditingController();
  bool _acknowledged = false;
  String? _validationError;

  @override
  void dispose() {
    _passphrase.dispose();
    _confirmPassphrase.dispose();
    super.dispose();
  }

  bool get _canConfirm =>
      _acknowledged &&
      _passphrase.text.trim().length >= dbEncryptionMinPassphraseLength &&
      _passphrase.text == _confirmPassphrase.text;

  void _confirm() {
    if (_passphrase.text.trim().length < dbEncryptionMinPassphraseLength) {
      setState(() {
        _validationError =
            'Passphrase must be at least $dbEncryptionMinPassphraseLength '
            'characters.';
      });
      return;
    }
    if (_passphrase.text != _confirmPassphrase.text) {
      setState(() => _validationError = 'Passphrases do not match.');
      return;
    }
    if (!_acknowledged) {
      setState(
        () => _validationError = 'Please acknowledge the warning above.',
      );
      return;
    }
    Navigator.pop(context, _passphrase.text);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return AlertDialog(
      title: const Text('Encrypt local mailbox'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'ByteMail will re-encrypt the mailbox database on this '
              'device with the passphrase below. There is no recovery '
              'mechanism: if you forget it, the local mailbox cannot be '
              'unlocked and you will need to remove and re-add your '
              'accounts to start fresh.',
              style: TextStyle(color: t.coral, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passphrase,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Passphrase'),
              onChanged: (_) => setState(() => _validationError = null),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _confirmPassphrase,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Confirm passphrase',
              ),
              onChanged: (_) => setState(() => _validationError = null),
              onSubmitted: (_) => _confirm(),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _acknowledged,
              onChanged: (bool? value) => setState(() {
                _acknowledged = value ?? false;
                _validationError = null;
              }),
              title: const Text(
                'I understand there is no way to recover my mail if I '
                'forget this passphrase.',
              ),
            ),
            if (_validationError != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                _validationError!,
                style: TextStyle(color: t.coral, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canConfirm ? _confirm : null,
          child: const Text('Encrypt'),
        ),
      ],
    );
  }
}
