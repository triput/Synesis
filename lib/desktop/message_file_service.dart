// ==============================================================================
// File: lib/desktop/message_file_service.dart
// Description: Native open/save dialogs for RFC 822 message files.
// Component: Platform Integration
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/mime/eml_codec.dart';
import 'package:file_picker/file_picker.dart';

Future<String?> saveMessageAsEml(MailMessage message) {
  return FilePicker.saveFile(
    dialogTitle: 'Save message as EML',
    fileName: '${safeEmlFileName(message.subject)}.eml',
    type: FileType.custom,
    allowedExtensions: const <String>['eml'],
    bytes: Uint8List.fromList(utf8.encode(exportMessageToEml(message))),
    lockParentWindow: true,
  );
}

Future<EmlPreview?> openEmlPreview() async {
  final FilePickerResult? result = await FilePicker.pickFiles(
    dialogTitle: 'Open EML message',
    type: FileType.custom,
    allowedExtensions: const <String>['eml'],
    withData: true,
    lockParentWindow: true,
  );
  if (result == null || result.files.isEmpty) {
    return null;
  }
  final PlatformFile file = result.files.single;
  final Uint8List? bytes = file.bytes;
  if (bytes == null) {
    throw StateError('The selected EML file could not be read.');
  }
  return parseEmlPreview(utf8.decode(bytes, allowMalformed: true));
}

Future<EmlPreview> openEmlPreviewFromPath(String path) async {
  if (!path.toLowerCase().endsWith('.eml')) {
    throw ArgumentError.value(path, 'path', 'Expected an .eml file.');
  }
  final Uint8List bytes = await File(path).readAsBytes();
  return parseEmlPreview(utf8.decode(bytes, allowMalformed: true));
}

String safeEmlFileName(String value) {
  final String sanitized = value
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_')
      .trim();
  return sanitized.isEmpty ? 'ByteMail message' : sanitized;
}
