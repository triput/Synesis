// ==============================================================================
// File: lib/ui/settings/ui_font_settings_section.dart
// Description: UI font family, size scale, and text color controls (UI-P18)
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/settings/account_color_picker.dart';

/// Appearance-sheet section for the UI-P18 UI font family, size, and optional
/// body text color override.
class UiFontSettingsSection extends StatelessWidget {
  const UiFontSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final AppSettingsCubit cubit = context.read<AppSettingsCubit>();
    final AppSettingsState settings = context.watch<AppSettingsCubit>().state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('UI font', style: TextStyle(color: t.muted, fontSize: 12)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String?>(
          initialValue: settings.uiFontFamily,
          decoration: const InputDecoration(
            labelText: 'Font family',
            border: OutlineInputBorder(),
          ),
          items: <DropdownMenuItem<String?>>[
            const DropdownMenuItem<String?>(
              value: null,
              child: Text('System default'),
            ),
            for (final String family in kUiFontFamilyOptions)
              DropdownMenuItem<String?>(
                value: family,
                child: Text(uiFontFamilyLabel(family)),
              ),
          ],
          onChanged: (String? family) =>
              unawaited(cubit.setUiFontFamily(family)),
        ),
        const SizedBox(height: 12),
        Text(
          'Text size · ${(settings.uiFontSizeScale * 100).round()}%',
          style: TextStyle(color: t.muted, fontSize: 12),
        ),
        Slider(
          value: settings.uiFontSizeScale,
          min: kUiFontSizeScaleMin,
          max: kUiFontSizeScaleMax,
          divisions: 18,
          label: '${(settings.uiFontSizeScale * 100).round()}%',
          onChanged: (double value) =>
              unawaited(cubit.setUiFontSizeScale(value)),
        ),
        const SizedBox(height: 8),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Body text color'),
          subtitle: Text(
            settings.uiTextColorArgb == null
                ? 'Theme default'
                : 'Custom override',
            style: TextStyle(color: t.muted, fontSize: 12),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () async {
                  final Color? picked = await showAccountColorPickerDialog(
                    context,
                    initialColor: settings.uiTextColorArgb == null
                        ? t.text
                        : Color(settings.uiTextColorArgb!),
                  );
                  if (picked != null) {
                    await cubit.setUiTextColorArgb(picked.toARGB32());
                  }
                },
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: settings.uiTextColorArgb == null
                        ? t.text
                        : Color(settings.uiTextColorArgb!),
                    shape: BoxShape.circle,
                    border: Border.all(color: t.line),
                  ),
                ),
              ),
              if (settings.uiTextColorArgb != null)
                IconButton(
                  tooltip: 'Reset to theme default',
                  onPressed: () =>
                      unawaited(cubit.setUiTextColorArgb(null)),
                  icon: Icon(Icons.restore_rounded, color: t.muted, size: 18),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
