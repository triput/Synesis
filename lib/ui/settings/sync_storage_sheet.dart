// ==============================================================================
// File: lib/ui/settings/sync_storage_sheet.dart
// Description: Default sync profile retention, trash retention, body policy,
//   attachment max, and push-on-cellular controls (UI-P21 Sync & storage)
// Component: UI
// Version: 1.1 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-23
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:synesis/domain/sync_profile.dart';
import 'package:synesis/repository/mail_repository.dart';
import 'package:synesis/settings/app_settings_cubit.dart';
import 'package:synesis/settings/app_settings_state.dart';
import 'package:synesis/sync/retention_service.dart';
import 'package:synesis/sync/sync_engine.dart';
import 'package:synesis/theme/app_theme.dart';

Future<void> showSyncStorageSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: tokensOf(context).panel,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) {
      return const SyncStorageSheetBody();
    },
  );
}

/// Default sync profile + trash retention controls (UI-P21 Sync & storage).
///
/// Public so `settings_shell.dart` can embed the identical body inside the
/// sectioned Settings shell instead of duplicating this logic.
class SyncStorageSheetBody extends StatefulWidget {
  const SyncStorageSheetBody({super.key});

  @override
  State<SyncStorageSheetBody> createState() => _SyncStorageSheetBodyState();
}

class _SyncStorageSheetBodyState extends State<SyncStorageSheetBody> {
  SyncProfile? _profile;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final MailRepository repo = context.read<MailRepository>();
    final SyncProfile? profile = await repo.getDefaultSyncProfile();
    if (!mounted) {
      return;
    }
    setState(() {
      _profile = profile ??
          const SyncProfile(
            id: 'default',
            name: 'Default',
            retentionDays: 180,
            bodyPolicy: BodyFetchPolicy.onOpen,
            attachmentMaxMb: 25,
            isDefault: true,
          );
      _loading = false;
    });
  }

  Future<void> _persist(SyncProfile next) async {
    setState(() {
      _saving = true;
      _error = null;
      _profile = next;
    });
    try {
      await context.read<MailRepository>().upsertSyncProfile(next);
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _saving = false;
        });
      }
    }
  }

  Future<void> _onRetentionChanged(int days) async {
    final SyncProfile? current = _profile;
    if (current == null) {
      return;
    }
    final AppSettingsCubit settings = context.read<AppSettingsCubit>();
    final RetentionService retention = context.read<RetentionService>();
    final SyncEngine syncEngine = context.read<SyncEngine>();
    await settings.setRetentionDays(days);
    await _persist(current.copyWith(retentionDays: days));
    await retention.applyDeviceRetentionDial(days: days);
    if (!mounted) {
      return;
    }
    await syncEngine.kick();
  }

  static String _bodyPolicyLabel(BodyFetchPolicy policy) {
    return switch (policy) {
      BodyFetchPolicy.onOpen => 'On open',
      BodyFetchPolicy.headersOnly => 'Headers only',
      BodyFetchPolicy.fullAlways => 'Full always',
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    final SyncProfile? profile = _profile;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 0,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 28,
      ),
      child: _loading || profile == null
          ? const SizedBox(
              height: 160,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    'Sync & storage',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Default profile · ${profile.name}',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Retention (days)',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  Slider(
                    value: profile.retentionDays.clamp(14, 365).toDouble(),
                    min: 14,
                    max: 365,
                    divisions: 26,
                    label: '${profile.retentionDays}',
                    onChanged: _saving
                        ? null
                        : (double v) {
                            setState(() {
                              _profile = profile.copyWith(
                                retentionDays: v.round(),
                              );
                            });
                          },
                    onChangeEnd: _saving
                        ? null
                        : (double v) => _onRetentionChanged(v.round()),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Attachment max (MB)',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  Slider(
                    value: profile.attachmentMaxMb.clamp(1, 100).toDouble(),
                    min: 1,
                    max: 100,
                    divisions: 99,
                    label: '${profile.attachmentMaxMb}',
                    onChanged: _saving
                        ? null
                        : (double v) {
                            setState(() {
                              _profile = profile.copyWith(
                                attachmentMaxMb: v.round(),
                              );
                            });
                          },
                    onChangeEnd: _saving
                        ? null
                        : (double v) => _persist(
                              profile.copyWith(attachmentMaxMb: v.round()),
                            ),
                  ),
                  Text(
                    'Larger attachments slow send and may fail on some '
                    'servers. Microsoft 365/Outlook accounts upload files '
                    'over 3 MB in the background, so raising this cap is '
                    'safe for those accounts.',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Body fetch policy'),
                    subtitle: Text(
                      'Controls when message bodies are downloaded',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    trailing: DropdownButton<BodyFetchPolicy>(
                      value: profile.bodyPolicy,
                      underline: const SizedBox.shrink(),
                      items: <DropdownMenuItem<BodyFetchPolicy>>[
                        for (final BodyFetchPolicy policy
                            in BodyFetchPolicy.values)
                          DropdownMenuItem<BodyFetchPolicy>(
                            value: policy,
                            child: Text(_bodyPolicyLabel(policy)),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (BodyFetchPolicy? next) {
                              if (next == null) {
                                return;
                              }
                              _persist(profile.copyWith(bodyPolicy: next));
                            },
                    ),
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<AppSettingsCubit, AppSettingsState>(
                    buildWhen: (AppSettingsState prev, AppSettingsState next) =>
                        prev.pushOnCellular != next.pushOnCellular,
                    builder: (BuildContext context, AppSettingsState settings) {
                      return SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Allow push sync on mobile data'),
                        subtitle: Text(
                          'IMAP IDLE and near-push on cellular. '
                          'Off by default to save data; Wi‑Fi always allowed. '
                          'Desktop ignores this setting.',
                          style: TextStyle(color: t.muted, fontSize: 12),
                        ),
                        value: settings.pushOnCellular,
                        onChanged: _saving
                            ? null
                            : (bool value) {
                                context
                                    .read<AppSettingsCubit>()
                                    .setPushOnCellular(value);
                              },
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  BlocBuilder<AppSettingsCubit, AppSettingsState>(
                    buildWhen: (AppSettingsState prev, AppSettingsState next) =>
                        prev.trashRetentionDays != next.trashRetentionDays,
                    builder: (BuildContext context, AppSettingsState settings) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Empty trash after (days)',
                            style: TextStyle(color: t.muted, fontSize: 12),
                          ),
                          Slider(
                            value: settings.trashRetentionDays
                                .clamp(7, 90)
                                .toDouble(),
                            min: 7,
                            max: 90,
                            divisions: 83,
                            label: '${settings.trashRetentionDays}',
                            onChanged: (double v) => context
                                .read<AppSettingsCubit>()
                                .setTrashRetentionDays(v.round()),
                          ),
                        ],
                      );
                    },
                  ),
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
