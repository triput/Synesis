// ==============================================================================
// File: lib/ui/account/edit_account_sheet.dart
// Description: Edit account metadata and re-authenticate provider credentials
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-16
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/account/account_service.dart';
import 'package:bytemail/auth/oauth_identity_manager.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/ui/account/signatures_sheet.dart';
import 'package:bytemail/ui/account/templates_sheet.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/ui/settings/account_color_picker.dart';

Future<void> showEditAccountSheet(
  BuildContext context,
  MailAccount account,
) {
  final t = tokensOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
        ),
        child: _EditAccountForm(account: account),
      );
    },
  );
}

class _EditAccountForm extends StatefulWidget {
  const _EditAccountForm({required this.account});

  final MailAccount account;

  @override
  State<_EditAccountForm> createState() => _EditAccountFormState();
}

class _EditAccountFormState extends State<_EditAccountForm> {
  late final TextEditingController _label;
  late Color _accent;
  final TextEditingController _graphToken = TextEditingController();
  final TextEditingController _imapHost = TextEditingController();
  final TextEditingController _imapPort = TextEditingController(text: '993');
  final TextEditingController _imapUser = TextEditingController();
  final TextEditingController _imapPassword = TextEditingController();
  final TextEditingController _smtpHost = TextEditingController();
  final TextEditingController _smtpPort = TextEditingController(text: '465');
  final TextEditingController _retentionOverride = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _reauthenticated = false;
  List<SyncProfile> _profiles = const <SyncProfile>[];
  String? _syncProfileId;
  bool _useProfileRetention = true;

  bool get _isGraph =>
      widget.account.providerType == 'graph' ||
      widget.account.providerType == 'microsoft';

  bool get _graphConfigured =>
      context.read<OAuthIdentityManager>().config.isConfigured;

  bool get _showPasteToken => !_graphConfigured || kDebugMode;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.account.label);
    _accent = widget.account.accent;
    _imapUser.text = widget.account.address;
    _syncProfileId = widget.account.syncProfileId ?? 'default';
    final int? overrideDays = widget.account.retentionDaysOverride;
    _useProfileRetention = overrideDays == null;
    if (overrideDays != null) {
      _retentionOverride.text = '$overrideDays';
    }
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    final List<SyncProfile> profiles =
        await context.read<MailRepository>().listSyncProfiles();
    if (!mounted) {
      return;
    }
    setState(() {
      _profiles = profiles;
      if (_syncProfileId != null &&
          profiles.every((SyncProfile p) => p.id != _syncProfileId)) {
        final Iterable<SyncProfile> defaults =
            profiles.where((SyncProfile p) => p.isDefault);
        _syncProfileId = defaults.isNotEmpty
            ? defaults.first.id
            : (profiles.isEmpty ? 'default' : profiles.first.id);
      }
    });
  }

  @override
  void dispose() {
    _label.dispose();
    _graphToken.dispose();
    _imapHost.dispose();
    _imapPort.dispose();
    _imapUser.dispose();
    _imapPassword.dispose();
    _smtpHost.dispose();
    _smtpPort.dispose();
    _retentionOverride.dispose();
    super.dispose();
  }

  String _providerLabel() {
    switch (widget.account.providerType) {
      case 'graph':
      case 'microsoft':
        return 'Microsoft Graph';
      case 'imap':
        return 'IMAP / SMTP';
      default:
        return widget.account.providerType;
    }
  }

  Future<void> _reauthenticateMicrosoft() async {
    final OAuthIdentityManager identity = context.read<OAuthIdentityManager>();
    final AccountService service = context.read<AccountService>();
    final SyncEngine syncEngine = context.read<SyncEngine>();
    final MailboxCubit mailbox = context.read<MailboxCubit>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final MicrosoftSignInResult result = await identity.signInMicrosoft();
      await service.updateGraphCredentials(
        account: widget.account,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        expiresAt: result.expiresAt,
      );
      _reauthenticated = true;
      await syncEngine.kick();
      await mailbox.refresh();
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
      });
      messenger.showSnackBar(
        const SnackBar(content: Text('Microsoft credentials updated')),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _busy = false;
        });
      }
    }
  }

  Future<void> _save() async {
    final String label = _label.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'Label is required.');
      return;
    }
    final AccountService service = context.read<AccountService>();
    final SyncEngine syncEngine = context.read<SyncEngine>();
    final MailboxCubit mailbox = context.read<MailboxCubit>();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      MailAccount current = widget.account;
      int? retentionOverride;
      bool clearRetentionOverride = false;
      if (_useProfileRetention) {
        clearRetentionOverride = true;
      } else {
        final int? parsed = int.tryParse(_retentionOverride.text.trim());
        if (parsed == null || parsed < 0) {
          setState(() {
            _error = 'Retention override must be a non-negative number of days.';
            _busy = false;
          });
          return;
        }
        retentionOverride = parsed;
      }
      current = await service.updateAccountMetadata(
        account: current,
        label: label,
        accent: _accent,
        syncProfileId: _syncProfileId,
        retentionDaysOverride: retentionOverride,
        clearRetentionOverride: clearRetentionOverride,
      );
      bool credentialsUpdated = _reauthenticated;
      if (_isGraph) {
        final String token = _graphToken.text.trim();
        if (token.isNotEmpty) {
          await service.updateGraphCredentials(
            account: current,
            accessToken: token,
          );
          credentialsUpdated = true;
        }
      } else {
        final String password = _imapPassword.text;
        if (password.isNotEmpty) {
          final String? host = _imapHost.text.trim().isEmpty
              ? null
              : _imapHost.text.trim();
          final int? port = int.tryParse(_imapPort.text.trim());
          final String? user = _imapUser.text.trim().isEmpty
              ? null
              : _imapUser.text.trim();
          final String? smtpHost = _smtpHost.text.trim().isEmpty
              ? null
              : _smtpHost.text.trim();
          final int? smtpPort = int.tryParse(_smtpPort.text.trim());
          await service.updateImapCredentials(
            account: current,
            password: password,
            host: host,
            port: port,
            user: user,
            smtpHost: smtpHost,
            smtpPort: smtpPort,
          );
          credentialsUpdated = true;
        }
      }
      if (credentialsUpdated && !_reauthenticated) {
        await syncEngine.kick();
      }
      await mailbox.refresh();
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Saved ${widget.account.address}')),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _busy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Edit account', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(_providerLabel()),
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(height: 8),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Email address',
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(widget.account.address),
            ),
          ),
          TextField(
            controller: _label,
            decoration: const InputDecoration(
              labelText: 'Short label',
              hintText: 'Letter shown on the account rail',
            ),
          ),
          const SizedBox(height: 8),
          Text('Accent color', style: TextStyle(color: t.muted, fontSize: 12)),
          const SizedBox(height: 6),
          AccountColorPicker(
            value: _accent,
            onChanged: (Color color) => setState(() => _accent = color),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sync profile'),
            subtitle: Text(
              'Controls retention, folder scope, and body policy',
              style: TextStyle(color: t.muted, fontSize: 12),
            ),
            trailing: DropdownButton<String>(
              value: _syncProfileId,
              underline: const SizedBox.shrink(),
              items: <DropdownMenuItem<String>>[
                for (final SyncProfile profile in _profiles)
                  DropdownMenuItem<String>(
                    value: profile.id,
                    child: Text(
                      profile.isDefault
                          ? '${profile.name} (default)'
                          : profile.name,
                    ),
                  ),
                if (_profiles.isEmpty)
                  const DropdownMenuItem<String>(
                    value: 'default',
                    child: Text('Default'),
                  ),
              ],
              onChanged: _busy
                  ? null
                  : (String? next) {
                      if (next != null) {
                        setState(() => _syncProfileId = next);
                      }
                    },
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use profile retention'),
            subtitle: Text(
              'Off to set a per-account day override',
              style: TextStyle(color: t.muted, fontSize: 12),
            ),
            value: _useProfileRetention,
            onChanged: _busy
                ? null
                : (bool value) => setState(() => _useProfileRetention = value),
          ),
          if (!_useProfileRetention)
            TextField(
              controller: _retentionOverride,
              decoration: const InputDecoration(
                labelText: 'Retention override (days)',
              ),
              keyboardType: TextInputType.number,
              enabled: !_busy,
            ),
          const SizedBox(height: 12),
          Text(
            _isGraph
                ? 'Re-authenticate (optional)'
                : 'Update credentials (optional)',
            style: TextStyle(color: t.muted, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              children: _isGraph ? _graphFields() : _imapFields(),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: t.coral, fontSize: 13)),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => showSignaturesSheet(context, widget.account),
            icon: const Icon(Icons.draw_outlined),
            label: const Text('Manage signatures'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy
                ? null
                : () => showTemplatesSheet(context, widget.account),
            icon: const Icon(Icons.article_outlined),
            label: const Text('Manage templates'),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: Text(_busy ? 'Saving…' : 'Save changes'),
          ),
        ],
      ),
    );
  }

  List<Widget> _graphFields() {
    final List<Widget> children = <Widget>[];
    if (_graphConfigured) {
      children.add(
        FilledButton.icon(
          onPressed: _busy ? null : _reauthenticateMicrosoft,
          icon: const Icon(Icons.login),
          label: Text(
            _busy ? 'Signing in…' : 'Re-authenticate with Microsoft',
          ),
        ),
      );
    }
    if (_showPasteToken) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: 16));
      }
      children.add(
        TextField(
          controller: _graphToken,
          decoration: InputDecoration(
            labelText: 'New Graph access token',
            helperText: _graphConfigured
                ? 'Debug-only paste; leave blank to keep the current token'
                : 'Leave blank to keep the current token. Configure Entra '
                    '(README) for browser re-auth.',
          ),
          minLines: 3,
          maxLines: 6,
        ),
      );
    }
    return children;
  }

  List<Widget> _imapFields() {
    return <Widget>[
      TextField(
        controller: _imapHost,
        decoration: const InputDecoration(
          labelText: 'IMAP host',
          hintText: 'Leave blank to keep current host',
        ),
      ),
      TextField(
        controller: _imapPort,
        decoration: const InputDecoration(labelText: 'IMAP port'),
        keyboardType: TextInputType.number,
      ),
      TextField(
        controller: _imapUser,
        decoration: const InputDecoration(
          labelText: 'IMAP username',
        ),
      ),
      TextField(
        controller: _imapPassword,
        decoration: const InputDecoration(
          labelText: 'New password / app password',
          helperText: 'Leave blank to keep the current password',
        ),
        obscureText: true,
      ),
      TextField(
        controller: _smtpHost,
        decoration: const InputDecoration(labelText: 'SMTP host'),
      ),
      TextField(
        controller: _smtpPort,
        decoration: const InputDecoration(labelText: 'SMTP port'),
        keyboardType: TextInputType.number,
      ),
    ];
  }
}
