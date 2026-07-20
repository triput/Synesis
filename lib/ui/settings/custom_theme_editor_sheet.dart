// ==============================================================================
// File: lib/ui/settings/custom_theme_editor_sheet.dart
// Description: Custom theme list/select/delete section and creation editor (UI-P16)
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/app_settings_state.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/custom_theme.dart';
import 'package:bytemail/theme/theme_id.dart';
import 'package:bytemail/theme/theme_tokens.dart';
import 'package:bytemail/ui/settings/account_color_picker.dart';

/// Token names editable in the compact creation editor (UI-P16 minimum set).
const List<String> _kEditableCustomThemeTokens = <String>[
  'ink',
  'panel',
  'content',
  'text',
  'teal',
];

String _customThemeTokenLabel(String token) {
  switch (token) {
    case 'ink':
      return 'Background (ink)';
    case 'panel':
      return 'Panel';
    case 'content':
      return 'Reading pane';
    case 'text':
      return 'Text';
    case 'teal':
      return 'Accent';
    default:
      return token;
  }
}

/// Inline appearance-sheet section listing custom themes with select/delete,
/// plus an entry point to create a new one.
class CustomThemesSection extends StatefulWidget {
  const CustomThemesSection({super.key});

  @override
  State<CustomThemesSection> createState() => _CustomThemesSectionState();
}

class _CustomThemesSectionState extends State<CustomThemesSection> {
  List<CustomTheme> _themes = const <CustomTheme>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final MailRepository repository = context.read<MailRepository>();
    final List<CustomTheme> themes = await repository.listCustomThemes();
    if (!mounted) {
      return;
    }
    setState(() {
      _themes = themes;
      _loading = false;
    });
  }

  Future<void> _createTheme() async {
    final CustomTheme? created = await showCustomThemeEditorSheet(context);
    if (created == null || !mounted) {
      return;
    }
    final MailRepository repository = context.read<MailRepository>();
    await repository.upsertCustomTheme(created);
    if (!mounted) {
      return;
    }
    await context.read<AppSettingsCubit>().setCustomThemeId(created.id);
    await _load();
  }

  Future<void> _deleteTheme(CustomTheme theme) async {
    final MailRepository repository = context.read<MailRepository>();
    final AppSettingsCubit cubit = context.read<AppSettingsCubit>();
    await repository.deleteCustomTheme(theme.id);
    if (cubit.state.customThemeId == theme.id) {
      await cubit.setCustomThemeId(null);
    }
    if (!mounted) {
      return;
    }
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final AppSettingsState settings = context.watch<AppSettingsCubit>().state;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Custom themes',
          style: TextStyle(color: t.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: LinearProgressIndicator(),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              for (final CustomTheme theme in _themes)
                InputChip(
                  label: Text(theme.name),
                  selected: settings.customThemeId == theme.id,
                  onSelected: (_) => unawaited(
                    context.read<AppSettingsCubit>().setCustomThemeId(
                          theme.id,
                        ),
                  ),
                  onDeleted: () => unawaited(_deleteTheme(theme)),
                ),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Create custom theme'),
                onPressed: _createTheme,
              ),
            ],
          ),
      ],
    );
  }
}

/// Opens the custom theme creation editor and resolves with the new
/// [CustomTheme], or null if the user cancelled.
Future<CustomTheme?> showCustomThemeEditorSheet(BuildContext context) {
  return showModalBottomSheet<CustomTheme>(
    context: context,
    backgroundColor: tokensOf(context).panel,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (BuildContext sheetContext) => const _CustomThemeEditorSheet(),
  );
}

class _CustomThemeEditorSheet extends StatefulWidget {
  const _CustomThemeEditorSheet();

  @override
  State<_CustomThemeEditorSheet> createState() =>
      _CustomThemeEditorSheetState();
}

class _CustomThemeEditorSheetState extends State<_CustomThemeEditorSheet> {
  final TextEditingController _nameController = TextEditingController();
  ThemeId _baseThemeId = ThemeId.dark;
  final Map<String, int> _overrides = <String, int>{};
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Color _colorFor(String token, ThemeTokens base) {
    final int? argb = _overrides[token];
    if (argb != null) {
      return Color(argb);
    }
    switch (token) {
      case 'ink':
        return base.ink;
      case 'panel':
        return base.panel;
      case 'content':
        return base.content;
      case 'text':
        return base.text;
      case 'teal':
        return base.teal;
      default:
        return base.text;
    }
  }

  Future<void> _pickColor(String token, ThemeTokens base) async {
    final Color? picked = await showAccountColorPickerDialog(
      context,
      initialColor: _colorFor(token, base),
    );
    if (picked == null) {
      return;
    }
    setState(() => _overrides[token] = picked.toARGB32());
  }

  void _save() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Enter a name for this theme.');
      return;
    }
    final String id = 'custom_${DateTime.now().microsecondsSinceEpoch}';
    Navigator.of(context).pop(
      CustomTheme(
        id: id,
        name: name,
        baseThemeId: _baseThemeId,
        tokenOverrides: Map<String, int>.unmodifiable(_overrides),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    final ThemeTokens previewBase = ThemeTokens.forId(_baseThemeId);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              'Create custom theme',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Text('Base theme', style: TextStyle(color: t.muted, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final ThemeId id in ThemeId.values)
                  ChoiceChip(
                    label: Text(id.label),
                    selected: _baseThemeId == id,
                    onSelected: (_) => setState(() => _baseThemeId = id),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Colors', style: TextStyle(color: t.muted, fontSize: 12)),
            const SizedBox(height: 4),
            for (final String token in _kEditableCustomThemeTokens)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(_customThemeTokenLabel(token)),
                trailing: InkWell(
                  onTap: () => _pickColor(token, previewBase),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _colorFor(token, previewBase),
                      shape: BoxShape.circle,
                      border: Border.all(color: t.line),
                    ),
                  ),
                ),
              ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(_error!, style: TextStyle(color: t.coral, fontSize: 12)),
            ],
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _save,
              child: const Text('Save theme'),
            ),
          ],
        ),
      ),
    );
  }
}
