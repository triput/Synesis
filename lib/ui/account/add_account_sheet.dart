// ==============================================================================
// File: lib/ui/account/add_account_sheet.dart
// Description: Onboarding UI to add Microsoft, Google, or IMAP/SMTP accounts
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:bytemail/account/account_service.dart';
import 'package:bytemail/account/imap_autoconfig.dart';
import 'package:bytemail/auth/oauth_identity_manager.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/ui/settings/account_color_picker.dart';

Future<void> showAddAccountSheet(BuildContext context) {
  final t = tokensOf(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: t.panel,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: const _AddAccountForm(),
      );
    },
  );
}

class _AddAccountForm extends StatefulWidget {
  const _AddAccountForm();

  @override
  State<_AddAccountForm> createState() => _AddAccountFormState();
}

class _AddAccountFormState extends State<_AddAccountForm>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 3, vsync: this);
  final TextEditingController _address = TextEditingController();
  final TextEditingController _display = TextEditingController();
  final TextEditingController _graphToken = TextEditingController();
  final TextEditingController _imapHost = TextEditingController();
  final TextEditingController _imapPort = TextEditingController(text: '993');
  final TextEditingController _imapUser = TextEditingController();
  final TextEditingController _imapPassword = TextEditingController();
  final TextEditingController _smtpHost = TextEditingController();
  final TextEditingController _smtpPort = TextEditingController(text: '465');
  Color _accent = AccountColorPicker.curatedSwatches.first;
  bool _busy = false;
  bool _lookupBusy = false;
  String? _error;
  String? _lookupMessage;
  final ImapAutoconfig _imapAutoconfig = const ImapAutoconfig();

  bool get _graphConfigured =>
      context.read<OAuthIdentityManager>().config.isConfigured;

  bool get _googleConfigured =>
      context.read<OAuthIdentityManager>().googleConfig.isConfigured;

  bool get _showPasteToken => !_graphConfigured || kDebugMode;

  @override
  void initState() {
    super.initState();
    _tabs.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _address.dispose();
    _display.dispose();
    _graphToken.dispose();
    _imapHost.dispose();
    _imapPort.dispose();
    _imapUser.dispose();
    _imapPassword.dispose();
    _smtpHost.dispose();
    _smtpPort.dispose();
    super.dispose();
  }

  String _labelFromAddress(String address) {
    final String local = address.split('@').first.trim();
    if (local.isEmpty) {
      return 'A';
    }
    return local.substring(0, 1).toUpperCase();
  }

  String _railLabel([String? addressOverride]) {
    final String custom = _display.text.trim();
    if (custom.isNotEmpty) {
      return custom.substring(0, 1).toUpperCase();
    }
    return _labelFromAddress(addressOverride ?? _address.text.trim());
  }

  Future<void> _signInMicrosoft() async {
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
      final String id = const Uuid().v4();
      final String address = result.email;
      await service.addGraphAccount(
        id: id,
        label: _railLabel(address),
        address: address,
        accent: _accent,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        expiresAt: result.expiresAt,
      );
      await syncEngine.kick();
      await mailbox.refresh();
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Added $address — sync started')),
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

  Future<void> _signInGoogle() async {
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
      final String id = const Uuid().v4();
      final String address = result.email;
      await service.addGoogleImapAccount(
        id: id,
        label: _railLabel(address),
        address: address,
        accent: _accent,
        accessToken: result.accessToken,
        refreshToken: result.refreshToken,
        expiresAt: result.expiresAt,
      );
      await syncEngine.kick();
      await mailbox.refresh();
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Added $address — sync started')),
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

  Future<void> _submitGraphPaste() async {
    final String address = _address.text.trim();
    final String token = _graphToken.text.trim();
    if (address.isEmpty || token.isEmpty) {
      setState(() => _error = 'Address and access token are required.');
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
      final String id = const Uuid().v4();
      await service.addGraphAccount(
        id: id,
        label: _railLabel(),
        address: address,
        accent: _accent,
        accessToken: token,
      );
      await syncEngine.kick();
      await mailbox.refresh();
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Added $address — sync started')),
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

  Future<void> _lookupImapSettings() async {
    final String address = _resolvedImapAddress();
    if (address.isEmpty) {
      setState(() {
        _lookupMessage =
            'Enter an email address first (or your full address in IMAP username).';
      });
      return;
    }
    if (_address.text.trim().isEmpty) {
      _address.text = address;
    }
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() {
      _lookupBusy = true;
      _lookupMessage = null;
    });
    try {
      final AutoconfigResult? result = await _imapAutoconfig.discover(address);
      if (!mounted) {
        return;
      }
      if (result == null) {
        setState(() {
          _lookupBusy = false;
          _lookupMessage = "Couldn't find settings — enter them manually";
        });
        return;
      }
      setState(() {
        _imapHost.text = result.imapHost;
        _imapPort.text = '${result.imapPort}';
        _smtpHost.text = result.smtpHost;
        _smtpPort.text = '${result.smtpPort}';
        _imapUser.text = result.username;
        _lookupBusy = false;
        _lookupMessage =
            'Found ${result.imapHost}:${result.imapPort} / '
            '${result.smtpHost}:${result.smtpPort} '
            '(${_socketLabel(result.imapSocketType)} / '
            '${_socketLabel(result.smtpSocketType)}). '
            'You can override any field.';
      });
      messenger.showSnackBar(
        const SnackBar(
          content: Text('IMAP/SMTP settings filled from autoconfig'),
        ),
      );
    } on AutoconfigInvalidEmailException {
      if (mounted) {
        setState(() {
          _lookupBusy = false;
          _lookupMessage = 'Enter a valid email address (you@domain.com).';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _lookupBusy = false;
          _lookupMessage = "Couldn't find settings — enter them manually";
        });
      }
    }
  }

  String _socketLabel(AutoconfigSocketType type) {
    switch (type) {
      case AutoconfigSocketType.ssl:
        return 'SSL';
      case AutoconfigSocketType.startTls:
        return 'STARTTLS';
      case AutoconfigSocketType.plain:
        return 'plain';
    }
  }

  /// Prefer explicit email address; fall back to IMAP username when it is an
  /// address (common when users skip the top Email field).
  String _resolvedImapAddress() {
    final String address = _address.text.trim();
    if (address.isNotEmpty) {
      return address;
    }
    final String user = _imapUser.text.trim();
    if (user.contains('@')) {
      return user;
    }
    return '';
  }

  /// Prefer explicit SMTP host; derive from IMAP host when blank (imap.X → smtp.X).
  String _resolvedSmtpHost(String imapHost) {
    final String smtp = _smtpHost.text.trim();
    if (smtp.isNotEmpty) {
      return smtp;
    }
    if (imapHost.toLowerCase().startsWith('imap.')) {
      return 'smtp.${imapHost.substring(5)}';
    }
    return imapHost;
  }

  Future<void> _submitImap() async {
    final String address = _resolvedImapAddress();
    final String host = _imapHost.text.trim();
    final String user = _imapUser.text.trim().isEmpty
        ? address
        : _imapUser.text.trim();
    final String password = _imapPassword.text;
    if (address.isEmpty || host.isEmpty || password.isEmpty) {
      setState(() {
        if (address.isEmpty) {
          _error =
              'Email address is required (top of form), or put your '
              'full address in IMAP username.';
        } else if (host.isEmpty) {
          _error = 'IMAP host is required.';
        } else {
          _error = 'Password / app password is required.';
        }
      });
      return;
    }
    // Keep the visible address field in sync when we inferred it from username.
    if (_address.text.trim().isEmpty) {
      _address.text = address;
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
      final String id = const Uuid().v4();
      final String smtpHost = _resolvedSmtpHost(host);
      await service.addImapAccount(
        id: id,
        label: _railLabel(address),
        address: address,
        accent: _accent,
        host: host,
        port: int.tryParse(_imapPort.text.trim()) ?? 993,
        user: user,
        password: password,
        smtpHost: smtpHost,
        smtpPort: int.tryParse(_smtpPort.text.trim()) ?? 465,
      );
      await syncEngine.kick();
      await mailbox.refresh();
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text('Added $address — sync started')),
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
    final bool graphConfigured = _graphConfigured;
    final bool googleConfigured = _googleConfigured;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.85,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Add account', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Microsoft Graph, Google (Gmail IMAP/SMTP via OAuth), or any '
            'IMAP / SMTP server. App passwords remain available on the IMAP tab.',
            style: TextStyle(color: t.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            tabs: const [
              Tab(text: 'Microsoft'),
              Tab(text: 'Google'),
              Tab(text: 'IMAP / Other'),
            ],
          ),
          const SizedBox(height: 12),
          if (!graphConfigured || _tabs.index != 0 || _showPasteToken) ...[
            if (_tabs.index == 2 ||
                (_tabs.index == 0 &&
                    (!graphConfigured || _showPasteToken))) ...[
              TextField(
                controller: _address,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  hintText: 'you@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
                onChanged: (_) => setState(() {}),
              ),
            ],
          ],
          TextField(
            controller: _display,
            decoration: const InputDecoration(
              labelText: 'Short label (optional)',
              hintText: 'Letter shown on the account rail',
            ),
          ),
          const SizedBox(height: 8),
          Text('Accent color', style: TextStyle(color: t.muted, fontSize: 12)),
          const SizedBox(height: 6),
          AccountColorPicker(
            value: _accent,
            onChanged: (c) => setState(() => _accent = c),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: [
                ListView(
                  children: [
                    if (graphConfigured) ...[
                      FilledButton.icon(
                        onPressed: _busy ? null : _signInMicrosoft,
                        icon: const Icon(Icons.login),
                        label: Text(
                          _busy ? 'Signing in…' : 'Sign in with Microsoft',
                        ),
                      ),
                      if (_showPasteToken) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Debug: paste token',
                          style: TextStyle(color: t.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _address,
                          decoration: const InputDecoration(
                            labelText: 'Email address',
                            hintText: 'you@example.com',
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        TextField(
                          controller: _graphToken,
                          decoration: const InputDecoration(
                            labelText: 'Graph access token',
                            helperText:
                                'Debug-only paste; prefer Sign in with Microsoft',
                          ),
                          minLines: 3,
                          maxLines: 6,
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _busy ? null : _submitGraphPaste,
                          child: Text(
                            _busy ? 'Adding…' : 'Add with pasted token',
                          ),
                        ),
                      ],
                    ] else ...[
                      Text(
                        'Microsoft browser sign-in is not configured yet.\n\n'
                        'Add your Entra Application (client) ID to '
                        'oauth_local.json in the project root (see '
                        'oauth_local.json.example), set BYTEMAIL_GRAPH_CLIENT_ID '
                        'in the environment, or pass '
                        '--dart-define=BYTEMAIL_GRAPH_CLIENT_ID=… then restart.\n\n'
                        'Until then you can paste a Graph access token below, '
                        'or use IMAP / Other.',
                        style: TextStyle(color: t.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _address,
                        decoration: const InputDecoration(
                          labelText: 'Email address',
                          hintText: 'you@example.com',
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      TextField(
                        controller: _graphToken,
                        decoration: const InputDecoration(
                          labelText: 'Graph access token',
                          helperText:
                              'Paste a Graph token with Mail.ReadWrite + Mail.Send.',
                        ),
                        minLines: 3,
                        maxLines: 6,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: _busy ? null : _submitGraphPaste,
                        child: Text(
                          _busy ? 'Adding…' : 'Add Microsoft account',
                        ),
                      ),
                    ],
                  ],
                ),
                ListView(
                  children: [
                    if (googleConfigured) ...[
                      Text(
                        'Sign in with Google to connect Gmail over IMAP/SMTP '
                        'using OAuth (XOAUTH2). No app password required.',
                        style: TextStyle(color: t.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _busy ? null : _signInGoogle,
                        icon: const Icon(Icons.login),
                        label: Text(
                          _busy ? 'Signing in…' : 'Sign in with Google',
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Google browser sign-in is not configured yet.\n\n'
                        'Add BYTEMAIL_GOOGLE_CLIENT_ID to oauth_local.json '
                        '(see oauth_local.json.example), set it in the '
                        'environment, or pass --dart-define, then restart.\n\n'
                        'You can still add Gmail on the IMAP / Other tab with an '
                        'app password from Google Account → Security.',
                        style: TextStyle(color: t.muted, fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: _busy
                            ? null
                            : () {
                                _tabs.animateTo(2);
                                if (_imapHost.text.trim().isEmpty) {
                                  _imapHost.text = 'imap.gmail.com';
                                }
                                if (_smtpHost.text.trim().isEmpty) {
                                  _smtpHost.text = 'smtp.gmail.com';
                                }
                              },
                        child: const Text('Use IMAP tab with app password'),
                      ),
                    ],
                  ],
                ),
                ListView(
                  children: [
                    Text(
                      'Password or app-password IMAP (including Gmail app '
                      'passwords). Use Look up settings to fill hosts from '
                      'Thunderbird ISPDB, or enter them manually.',
                      style: TextStyle(color: t.muted, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: (_busy || _lookupBusy)
                          ? null
                          : _lookupImapSettings,
                      icon: _lookupBusy
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.travel_explore),
                      label: Text(
                        _lookupBusy ? 'Looking up…' : 'Look up settings',
                      ),
                    ),
                    if (_lookupMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _lookupMessage!,
                        style: TextStyle(color: t.muted, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 8),
                    TextField(
                      controller: _imapHost,
                      decoration: const InputDecoration(
                        labelText: 'IMAP host',
                        hintText: 'imap.gmail.com',
                      ),
                      onChanged: (v) {
                        if (_smtpHost.text.isEmpty) {
                          setState(() => _smtpHost.text = v);
                        }
                      },
                    ),
                    TextField(
                      controller: _imapPort,
                      decoration: const InputDecoration(labelText: 'IMAP port'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: _imapUser,
                      decoration: InputDecoration(
                        labelText: 'IMAP username',
                        hintText: _address.text.isEmpty
                            ? 'Usually your email'
                            : _address.text,
                      ),
                    ),
                    TextField(
                      controller: _imapPassword,
                      decoration: const InputDecoration(
                        labelText: 'Password / app password',
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
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: (_busy || _lookupBusy) ? null : _submitImap,
                      child: Text(_busy ? 'Adding…' : 'Add IMAP account'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: t.coral, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}
