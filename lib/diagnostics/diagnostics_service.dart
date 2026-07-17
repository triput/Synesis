// ==============================================================================
// File: lib/diagnostics/diagnostics_service.dart
// Description: Redacted diagnostic export and explicit local account wipe gate.
// Component: Diagnostics
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

import 'dart:io';

import 'package:bytemail/repository/mail_repository.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class DiagnosticsExport {
  const DiagnosticsExport({
    required this.contents,
    this.file,
  });

  final String contents;
  final File? file;
}

class DiagnosticsService {
  DiagnosticsService(this._repository);

  final MailRepository _repository;

  Future<DiagnosticsExport> export({
    bool writeToFile = false,
  }) async {
    final String contents = await _repository.exportDiagnosticsRedacted();
    if (!writeToFile) {
      return DiagnosticsExport(contents: contents);
    }

    final Directory directory = await getApplicationSupportDirectory();
    final File file = File(
      path.join(
        directory.path,
        'bytemail-diagnostics-${DateTime.now().toUtc().millisecondsSinceEpoch}.json',
      ),
    );
    await file.writeAsString(contents, flush: true);
    return DiagnosticsExport(
      contents: contents,
      file: file,
    );
  }

  /// Requires an account-specific confirmation to prevent accidental data loss.
  Future<void> wipeAccount({
    required String accountId,
    required String confirmation,
  }) {
    final String requiredConfirmation = confirmationFor(accountId);
    if (confirmation != requiredConfirmation) {
      throw ArgumentError.value(
        confirmation,
        'confirmation',
        'Enter "$requiredConfirmation" to wipe the local account cache.',
      );
    }
    return _repository.wipeAccount(accountId);
  }

  static String confirmationFor(String accountId) => 'WIPE $accountId';
}
