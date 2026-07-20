// ==============================================================================
// File: lib/ui/settings/notifications_sheet.dart
// Description: Global, quiet-hours, and per-account notification settings sheet
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/domain/models.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/ui/mailbox/mailbox_cubit.dart';
import 'package:bytemail/ui/mailbox/mailbox_state.dart';

Future<void> showNotificationsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: tokensOf(context).panel,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext context) {
      return BlocBuilder<AppSettingsCubit, AppSettingsState>(
        builder: (BuildContext context, AppSettingsState settings) {
          final t = tokensOf(context);
          final AppSettingsCubit cubit = context.read<AppSettingsCubit>();
          final List<MailAccount> accounts = _accountsFromContext(context);
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'OS alerts for new unread inbox mail when ByteMail is '
                    'in the background.',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Enable notifications'),
                    subtitle: Text(
                      'Master switch for new-mail toasts',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    value: settings.notificationsEnabled,
                    onChanged: (bool value) {
                      cubit.setNotificationsEnabled(value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Starred only'),
                    subtitle: Text(
                      'Notify only when the new message is starred',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    value: settings.notifyStarredOnly,
                    onChanged: settings.notificationsEnabled
                        ? (bool value) {
                            cubit.setNotifyStarredOnly(value);
                          }
                        : null,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Quiet hours'),
                    subtitle: Text(
                      'Suppress notifications during a daily window',
                      style: TextStyle(color: t.muted, fontSize: 12),
                    ),
                    value: settings.notificationQuietHoursEnabled,
                    onChanged: settings.notificationsEnabled
                        ? (bool value) {
                            cubit.setNotificationQuietHoursEnabled(value);
                          }
                        : null,
                  ),
                  if (settings.notificationQuietHoursEnabled) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Quiet hours start'),
                      trailing: Text(
                        _formatMinutes(settings.quietHoursStartMinutes),
                        style: TextStyle(color: t.teal),
                      ),
                      onTap: settings.notificationsEnabled
                          ? () => _pickTime(
                                context,
                                initialMinutes: settings.quietHoursStartMinutes,
                                onPicked: cubit.setQuietHoursStartMinutes,
                              )
                          : null,
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Quiet hours end'),
                      trailing: Text(
                        _formatMinutes(settings.quietHoursEndMinutes),
                        style: TextStyle(color: t.teal),
                      ),
                      onTap: settings.notificationsEnabled
                          ? () => _pickTime(
                                context,
                                initialMinutes: settings.quietHoursEndMinutes,
                                onPicked: cubit.setQuietHoursEndMinutes,
                              )
                          : null,
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Accounts',
                    style: TextStyle(color: t.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  if (accounts.isEmpty)
                    Text(
                      'Add an account to mute notifications per mailbox.',
                      style: TextStyle(color: t.muted, fontSize: 13),
                    )
                  else
                    for (final MailAccount account in accounts)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(account.label),
                        subtitle: Text(
                          account.address,
                          style: TextStyle(color: t.muted, fontSize: 12),
                        ),
                        value: settings.isAccountNotificationsEnabled(
                          account.id,
                        ),
                        onChanged: settings.notificationsEnabled
                            ? (bool value) {
                                cubit.setAccountNotificationsEnabled(
                                  account.id,
                                  value,
                                );
                              }
                            : null,
                      ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

List<MailAccount> _accountsFromContext(BuildContext context) {
  try {
    final MailboxState mailbox = context.watch<MailboxCubit>().state;
    return mailbox.accounts;
  } catch (_) {
    return const <MailAccount>[];
  }
}

TimeOfDay _timeFromMinuteOfDay(int minutes) {
  final int clamped = minutes.clamp(0, 1439);
  return TimeOfDay(hour: clamped ~/ 60, minute: clamped % 60);
}

int _minuteOfDay(TimeOfDay time) => time.hour * 60 + time.minute;

String _formatMinutes(int minutes) {
  final TimeOfDay time = _timeFromMinuteOfDay(minutes);
  final String hour = time.hour.toString().padLeft(2, '0');
  final String minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

Future<void> _pickTime(
  BuildContext context, {
  required int initialMinutes,
  required Future<void> Function(int minutes) onPicked,
}) async {
  final TimeOfDay? picked = await showTimePicker(
    context: context,
    initialTime: _timeFromMinuteOfDay(initialMinutes),
  );
  if (picked == null) {
    return;
  }
  await onPicked(_minuteOfDay(picked));
}
