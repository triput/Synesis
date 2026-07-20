// ==============================================================================
// File: lib/ui/settings/settings_export_import_controls.dart
// Description: Export/import buttons for the versioned settings backup (UI-P17)
// Component: UI
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/settings/app_settings_cubit.dart';
import 'package:bytemail/settings/settings_export_service.dart';
import 'package:bytemail/theme/app_theme.dart';
import 'package:bytemail/theme/custom_theme.dart';
import 'package:bytemail/theme/theme_tokens.dart';

/// Appearance-sheet section with Export/Import buttons for the UI-P17
/// versioned settings backup (excludes account credentials/secrets).
class SettingsExportImportControls extends StatefulWidget {
  const SettingsExportImportControls({super.key});

  @override
  State<SettingsExportImportControls> createState() =>
      _SettingsExportImportControlsState();
}

class _SettingsExportImportControlsState
    extends State<SettingsExportImportControls> {
  static const SettingsExportService _service = SettingsExportService();

  bool _busy = false;
  String? _message;

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final AppSettingsCubit cubit = context.read<AppSettingsCubit>();
      final MailRepository repository = context.read<MailRepository>();
      final List<CustomTheme> themes = await repository.listCustomThemes();
      final String json = _service.encodeToString(
        settings: cubit.state,
        customThemes: themes,
      );
      final String? path = await FilePicker.saveFile(
        dialogTitle: 'Export ByteMail settings',
        fileName: 'bytemail_settings.json',
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
        lockParentWindow: true,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _message = path == null ? 'Export cancelled.' : 'Exported to $path';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _message = 'Export failed: $error';
      });
    }
  }

  Future<void> _import() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        dialogTitle: 'Import ByteMail settings',
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
        withData: true,
        lockParentWindow: true,
      );
      if (result == null || result.files.isEmpty) {
        if (!mounted) {
          return;
        }
        setState(() {
          _busy = false;
          _message = 'Import cancelled.';
        });
        return;
      }
      final Uint8List? bytes = result.files.single.bytes;
      if (bytes == null) {
        throw StateError('The selected file could not be read.');
      }
      final SettingsExportBundle bundle = _service.decodeString(
        utf8.decode(bytes, allowMalformed: true),
      );
      if (!mounted) {
        return;
      }
      final AppSettingsCubit cubit = context.read<AppSettingsCubit>();
      final MailRepository repository = context.read<MailRepository>();
      await cubit.replaceState(bundle.settings);
      for (final CustomTheme theme in bundle.customThemes) {
        await repository.upsertCustomTheme(theme);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _message = bundle.customThemes.isEmpty
            ? 'Settings imported.'
            : 'Settings and ${bundle.customThemes.length} custom '
                'theme(s) imported.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _message = 'Import failed: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeTokens t = tokensOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Settings backup',
          style: TextStyle(color: t.muted, fontSize: 12),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            OutlinedButton.icon(
              onPressed: _busy ? null : _export,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Export settings'),
            ),
            OutlinedButton.icon(
              onPressed: _busy ? null : _import,
              icon: const Icon(Icons.download_outlined),
              label: const Text('Import settings'),
            ),
          ],
        ),
        if (_message != null) ...<Widget>[
          const SizedBox(height: 6),
          Text(_message!, style: TextStyle(color: t.muted, fontSize: 12)),
        ],
      ],
    );
  }
}
