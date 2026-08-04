// ==============================================================================
// File: lib/ui/account/edit_account_sheet.dart
// Description: Edit account metadata and re-authenticate provider credentials
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-08-03
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synesis/account/account_service.dart';
import 'package:synesis/auth/oauth_identity_manager.dart';
import 'package:synesis/domain/models.dart';
import 'package:synesis/domain/sync_profile.dart';
import 'package:synesis/protocol/dav/dav_discovery.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/sync/sync_engine.dart';
import 'package:synesis/theme/app_theme.dart';
import 'package:synesis/ui/account/signatures_sheet.dart';
import 'package:synesis/ui/account/templates_sheet.dart';
import 'package:synesis/ui/mailbox/mailbox_cubit.dart';
import 'package:synesis/ui/settings/account_color_picker.dart';

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
      final MediaQueryData mq = MediaQuery.of(sheetContext);
      // Keyboard via viewInsets only. SafeArea owns system nav. Size to the
      // sheet's max constraint — never a fixed fraction of full screen that
      // can exceed SafeArea (yellow/black ribbon, DEF-063).
      return Padding(
        padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              // Tight height from SafeArea's max — never a fixed fraction of
              // the full screen (overshoots SafeArea + drag-handle inset).
              final double maxH = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : (mq.size.height -
                        mq.padding.vertical -
                        mq.viewInsets.vertical)
                      .clamp(240.0, mq.size.height);
              return SizedBox(
                height: maxH * 0.95,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: EditAccountForm(account: account),
                ),
              );
            },
          ),
        ),
      );
    },
  );
}

/// Edit-account form body (metadata, sync profile, re-auth, sticky Save).
///
/// Public for phone-size overflow widget tests (DEF-063).
class EditAccountForm extends StatefulWidget {
  const EditAccountForm({required this.account, super.key});

  final MailAccount account;

  @override
  State<EditAccountForm> createState() => _EditAccountFormState();
}

class _EditAccountFormState extends State<EditAccountForm> {
  late final TextEditingController _label;
  late Color _accent;
  final TextEditingController _graphToken = TextEditingController();
  final TextEditingController _imapHost = TextEditingController();
  final TextEditingController _imapPort = TextEditingController(text: '993');
  final TextEditingController _imapUser = TextEditingController();
  final TextEditingController _imapPassword = TextEditingController();
  final TextEditingController _davBaseUrl = TextEditingController();
  final TextEditingController _smtpHost = TextEditingController();
  final TextEditingController _smtpPort = TextEditingController(text: '465');
  final TextEditingController _retentionOverride = TextEditingController();
  bool _busy = false;
  String? _error;
  bool _reauthenticated = false;
  List<SyncProfile> _profiles = const <SyncProfile>[];
  String? _syncProfileId;
  bool _useProfileRetention = true;
  String? _initialDavBaseUrl;

  bool get _isGraph =>
      widget.account.providerType == 'graph' ||
      widget.account.providerType == 'microsoft';

  bool get _isGoogle =>
      (widget.account.credentialsRef ?? '').startsWith('google:');

  bool get _graphConfigured =>
      context.read<OAuthIdentityManager>().config.isConfigured;

  bool get _googleConfigured =>
      context.read<OAuthIdentityManager>().googleConfig.isConfigured;

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
    _loadDavBaseUrl();
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

  Future<void> _loadDavBaseUrl() async {
    try {
      final String? davBaseUrl = await context
          .read<AccountService>()
          .readDavBaseUrl(widget.account);
      if (!mounted) {
        return;
      }
      setState(() {
        _initialDavBaseUrl = davBaseUrl;
        _davBaseUrl.text = davBaseUrl ?? '';
      });
    } catch (_) {
      // Credential-store access is unavailable on some platforms. The field
      // remains empty and can still be configured with a new endpoint.
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _graphToken.dispose();
    _imapHost.dispose();
    _imapPort.dispose();
    _imapUser.dispose();
    _imapPassword.dispose();
    _davBaseUrl.dispose();
    _smtpHost.dispose();
    _smtpPort.dispose();
    _retentionOverride.dispose();
    super.dispose();
  }

  String _providerLabel() {
    if (_isGoogle) {
      return 'Google (IMAP / OAuth)';
    }
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

  Future<void> _reauthenticateGoogle() async {
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
      final GoogleSignInResult result = await identity.signInGoogle();
      await service.updateGoogleCredentials(
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
        const SnackBar(
          content: Text(
            'Google credentials updated (mail + People + Calendar)',
          ),
        ),
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
        final String davBaseUrl = _davBaseUrl.text.trim();
        final bool davChanged = davBaseUrl != (_initialDavBaseUrl ?? '');
        if (password.isNotEmpty || (davChanged && davBaseUrl.isNotEmpty)) {
          final String? host = password.isEmpty || _imapHost.text.trim().isEmpty
              ? null
              : _imapHost.text.trim();
          final int? port = password.isEmpty
              ? null
              : int.tryParse(_imapPort.text.trim());
          final String? user = password.isEmpty || _imapUser.text.trim().isEmpty
              ? null
              : _imapUser.text.trim();
          final String? smtpHost =
              password.isEmpty || _smtpHost.text.trim().isEmpty
              ? null
              : _smtpHost.text.trim();
          final int? smtpPort = password.isEmpty
              ? null
              : int.tryParse(_smtpPort.text.trim());
          await service.updateImapCredentials(
            account: current,
            password: password.isEmpty ? null : password,
            host: host,
            port: port,
            user: user,
            smtpHost: smtpHost,
            smtpPort: smtpPort,
            davBaseUrl: davChanged ? davBaseUrl : null,
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
    // Parent ConstrainedBox / Settings body supplies bounded height. Fill it
    // with Expanded ListView — do not invent a taller SizedBox than the parent
    // (that was the yellow/black ribbon).
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text('Edit account', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Expanded(
          child: ListView(
            children: <Widget>[
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
                  child: Text(
                    widget.account.address,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              TextField(
                controller: _label,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  hintText: 'Personal name for this account',
                  helperText: 'Address stays unchanged below the rail / chips',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Accent color',
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              AccountColorPicker(
                value: _accent,
                onChanged: (Color color) => setState(() => _accent = color),
              ),
              const SizedBox(height: 12),
              // Column layout — ListTile+trailing Dropdown overflows ~360dp.
              Text(
                'Sync profile',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                'Controls retention, folder scope, and body policy',
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              DropdownButtonFormField<String>(
                value: _syncProfileId,
                isExpanded: true,
                items: <DropdownMenuItem<String>>[
                  for (final SyncProfile profile in _profiles)
                    DropdownMenuItem<String>(
                      value: profile.id,
                      child: Text(
                        profile.isDefault
                            ? '${profile.name} (default)'
                            : profile.name,
                        overflow: TextOverflow.ellipsis,
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
                    : (bool value) =>
                          setState(() => _useProfileRetention = value),
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
                _isGraph || _isGoogle
                    ? 'Re-authenticate (optional)'
                    : 'Update credentials (optional)',
                style: TextStyle(color: t.muted, fontSize: 12),
              ),
              const SizedBox(height: 8),
              ...(_isGraph
                  ? _graphFields()
                  : _isGoogle
                  ? _googleFields()
                  : _imapFields()),
              // Secondary actions scroll with the form so short phones /
              // open keyboards do not blow the sticky footer budget (DEF-063).
              const SizedBox(height: 16),
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
              const SizedBox(height: 8),
            ],
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: t.coral, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _save,
          child: Text(_busy ? 'Saving…' : 'Save changes'),
        ),
      ],
    );
  }

  List<Widget> _googleFields() {
    if (!_googleConfigured) {
      return <Widget>[
        Text(
          'Google OAuth is not configured in this build. Configure '
          'SYNESIS_GOOGLE_CLIENT_ID (README) then re-auth to grant People + '
          'Calendar scopes for PIM sync.',
          style: TextStyle(color: tokensOf(context).muted, fontSize: 12),
        ),
      ];
    }
    return <Widget>[
      Text(
        'Re-auth refreshes mail XOAUTH and must store a new offline refresh '
        'token with People + Calendar scopes (DEF-061). Enable every '
        'Contacts/Calendar checkbox on consent. If Calendar still 403s after '
        're-auth, remove Synesis under Google Account → Third-party access, '
        'full-restart the app, then re-auth again.',
        style: TextStyle(color: tokensOf(context).muted, fontSize: 12),
      ),
      const SizedBox(height: 8),
      FilledButton.icon(
        onPressed: _busy ? null : _reauthenticateGoogle,
        icon: const Icon(Icons.login),
        label: Text(
          _busy ? 'Signing in…' : 'Re-authenticate with Google',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ];
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
    final bool isRunbox = DavDiscovery.isRunboxHint(
      widget.account.address,
      _imapHost.text,
    );
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
        controller: _davBaseUrl,
        decoration: InputDecoration(
          labelText: 'CardDAV / CalDAV URL (optional)',
          hintText: isRunbox
              ? DavDiscovery.runboxDavUrl
              : 'https://dav.example.com/',
          helperText: isRunbox
              ? 'Runbox detected — leave blank to use '
                  '${DavDiscovery.runboxDavUrl}. Use an app password if 2FA '
                  'is enabled.'
              : 'Shared endpoint for contacts and calendars. Use an app '
                  'password if 2FA is enabled.',
        ),
        keyboardType: TextInputType.url,
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
