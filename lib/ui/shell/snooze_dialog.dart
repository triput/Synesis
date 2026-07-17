// ==============================================================================
// File: lib/ui/shell/snooze_dialog.dart
// Description: Snooze preset and custom datetime picker for local snooze
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:flutter/material.dart';
import 'package:bytemail/theme/app_theme.dart';

/// Shows snooze presets / custom picker. Returns epoch ms, or null if cancelled.
Future<int?> showSnoozeDialog(BuildContext context) async {
  if (!context.mounted) {
    return null;
  }
  final DateTime now = DateTime.now();
  return showDialog<int>(
    context: context,
    builder: (BuildContext dialogContext) {
      final t = tokensOf(dialogContext);
      return AlertDialog(
        backgroundColor: t.panel,
        title: const Text('Snooze until'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _SnoozeOption(
              label: 'Later today',
              subtitle: _formatPreset(laterToday(now)),
              onPressed: () => Navigator.of(dialogContext).pop(
                laterToday(now).millisecondsSinceEpoch,
              ),
            ),
            _SnoozeOption(
              label: 'Tomorrow morning',
              subtitle: _formatPreset(tomorrowMorning(now)),
              onPressed: () => Navigator.of(dialogContext).pop(
                tomorrowMorning(now).millisecondsSinceEpoch,
              ),
            ),
            _SnoozeOption(
              label: 'Next week',
              subtitle: _formatPreset(nextWeek(now)),
              onPressed: () => Navigator.of(dialogContext).pop(
                nextWeek(now).millisecondsSinceEpoch,
              ),
            ),
            _SnoozeOption(
              label: 'Custom…',
              subtitle: 'Pick a date and time',
              onPressed: () async {
                final int? custom = await _pickCustomDateTime(
                  dialogContext,
                  now,
                );
                if (!dialogContext.mounted) {
                  return;
                }
                if (custom != null) {
                  Navigator.of(dialogContext).pop(custom);
                }
              },
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
        ],
      );
    },
  );
}

/// 6pm today when still ahead; otherwise now + 3 hours.
@visibleForTesting
DateTime laterToday(DateTime now) {
  final DateTime sixPm = DateTime(now.year, now.month, now.day, 18);
  if (sixPm.isAfter(now)) {
    return sixPm;
  }
  return now.add(const Duration(hours: 3));
}

@visibleForTesting
DateTime tomorrowMorning(DateTime now) {
  final DateTime tomorrow = now.add(const Duration(days: 1));
  return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 8);
}

@visibleForTesting
DateTime nextWeek(DateTime now) {
  final DateTime next = now.add(const Duration(days: 7));
  return DateTime(next.year, next.month, next.day, 8);
}

String _formatPreset(DateTime when) {
  final String weekday = _weekdayShort(when.weekday);
  final int hour12 = when.hour % 12 == 0 ? 12 : when.hour % 12;
  final String meridiem = when.hour >= 12 ? 'PM' : 'AM';
  final String minute = when.minute.toString().padLeft(2, '0');
  return '$weekday ${when.month}/${when.day} · $hour12:$minute $meridiem';
}

String _weekdayShort(int weekday) {
  const List<String> names = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];
  return names[(weekday - 1).clamp(0, 6)];
}

Future<int?> _pickCustomDateTime(BuildContext context, DateTime now) async {
  final DateTime? date = await showDatePicker(
    context: context,
    initialDate: now.add(const Duration(hours: 1)),
    firstDate: now,
    lastDate: now.add(const Duration(days: 365 * 2)),
  );
  if (date == null || !context.mounted) {
    return null;
  }
  final TimeOfDay? time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
  );
  if (time == null) {
    return null;
  }
  final DateTime combined = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  if (!combined.isAfter(now)) {
    return now.add(const Duration(minutes: 5)).millisecondsSinceEpoch;
  }
  return combined.millisecondsSinceEpoch;
}

class _SnoozeOption extends StatelessWidget {
  const _SnoozeOption({
    required this.label,
    required this.subtitle,
    required this.onPressed,
  });

  final String label;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = tokensOf(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(subtitle, style: TextStyle(color: t.muted, fontSize: 12)),
      onTap: onPressed,
    );
  }
}
