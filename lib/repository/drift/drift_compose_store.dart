// ==============================================================================
// File: lib/repository/drift/drift_compose_store.dart
// Description: Drift CRUD for signatures, templates, and outbound attachment blobs.
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:io';

import 'package:bytemail/compose/account_signature.dart';
import 'package:bytemail/repository/database.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class DriftComposeStore {
  DriftComposeStore(
    this._database, {
    required void Function() notify,
  }) : _notify = notify;

  final ByteMailDatabase _database;
  final void Function() _notify;
  final Uuid _uuid = const Uuid();

  Future<List<MailSignature>> listSignatures(String accountId) async {
    final List<AccountSignature> rows =
        await (_database.select(_database.accountSignatures)
              ..where(
                (AccountSignatures t) => t.accountId.equals(accountId),
              )
              ..orderBy(<OrderingTerm Function(AccountSignatures)>[
                (AccountSignatures t) => OrderingTerm.asc(t.sortOrder),
                (AccountSignatures t) => OrderingTerm.asc(t.name),
              ]))
            .get();
    return rows
        .map(
          (AccountSignature r) => MailSignature(
            id: r.id,
            accountId: r.accountId,
            name: r.name,
            bodyPlain: r.bodyPlain,
            bodyHtml: r.bodyHtml,
            isDefault: r.isDefault,
            sortOrder: r.sortOrder,
          ),
        )
        .toList(growable: false);
  }

  Future<MailSignature?> getSignature(String id) async {
    final AccountSignature? row = await (_database.select(
      _database.accountSignatures,
    )..where((AccountSignatures t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return MailSignature(
      id: row.id,
      accountId: row.accountId,
      name: row.name,
      bodyPlain: row.bodyPlain,
      bodyHtml: row.bodyHtml,
      isDefault: row.isDefault,
      sortOrder: row.sortOrder,
    );
  }

  Future<String> upsertSignature(MailSignature signature) async {
    if (signature.isDefault) {
      await (_database.update(_database.accountSignatures)..where(
            (AccountSignatures t) =>
                t.accountId.equals(signature.accountId) &
                t.isDefault.equals(true),
          ))
          .write(
            const AccountSignaturesCompanion(isDefault: Value<bool>(false)),
          );
    }
    await _database.into(_database.accountSignatures).insertOnConflictUpdate(
          AccountSignaturesCompanion.insert(
            id: signature.id,
            accountId: signature.accountId,
            name: signature.name,
            bodyPlain: signature.bodyPlain,
            bodyHtml: Value<String?>(signature.bodyHtml),
            isDefault: Value<bool>(signature.isDefault),
            sortOrder: Value<int>(signature.sortOrder),
          ),
        );
    _notify();
    return signature.id;
  }

  Future<void> deleteSignature(String id) async {
    await (_database.delete(
      _database.accountSignatureAssets,
    )..where((AccountSignatureAssets t) => t.signatureId.equals(id))).go();
    await (_database.delete(
      _database.accountSignatures,
    )..where((AccountSignatures t) => t.id.equals(id))).go();
    _notify();
  }

  Future<List<MailSignatureAsset>> listSignatureAssets(
    String signatureId,
  ) async {
    final List<AccountSignatureAsset> rows = await (_database.select(
      _database.accountSignatureAssets,
    )..where(
            (AccountSignatureAssets t) => t.signatureId.equals(signatureId),
          ))
        .get();
    return rows
        .map(
          (AccountSignatureAsset r) => MailSignatureAsset(
            id: r.id,
            signatureId: r.signatureId,
            localPath: r.localPath,
            contentId: r.contentId,
            mimeType: r.mimeType,
          ),
        )
        .toList(growable: false);
  }

  Future<String> addSignatureAsset({
    required String signatureId,
    required String sourcePath,
    required String mimeType,
    String? contentId,
  }) async {
    final String id = _uuid.v4();
    final String cid = contentId ?? 'sig-$id';
    final Directory base = await getApplicationSupportDirectory();
    final Directory dir = Directory(
      p.join(base.path, 'signature_assets', signatureId),
    );
    await dir.create(recursive: true);
    final String dest = p.join(dir.path, '$id${p.extension(sourcePath)}');
    await File(sourcePath).copy(dest);
    await _database.into(_database.accountSignatureAssets).insert(
          AccountSignatureAssetsCompanion.insert(
            id: id,
            signatureId: signatureId,
            localPath: dest,
            contentId: cid,
            mimeType: mimeType,
          ),
        );
    _notify();
    return id;
  }

  Future<List<MailTemplate>> listTemplates({String? accountId}) async {
    final SimpleSelectStatement<$MessageTemplatesTable, MessageTemplate> query =
        _database.select(_database.messageTemplates);
    if (accountId != null) {
      query.where(
        (MessageTemplates t) =>
            t.accountId.isNull() | t.accountId.equals(accountId),
      );
    }
    query.orderBy(<OrderingTerm Function(MessageTemplates)>[
      (MessageTemplates t) => OrderingTerm.asc(t.sortOrder),
      (MessageTemplates t) => OrderingTerm.asc(t.name),
    ]);
    final List<MessageTemplate> rows = await query.get();
    return rows
        .map(
          (MessageTemplate r) => MailTemplate(
            id: r.id,
            accountId: r.accountId,
            name: r.name,
            subject: r.subject,
            bodyHtml: r.bodyHtml,
            sortOrder: r.sortOrder,
          ),
        )
        .toList(growable: false);
  }

  Future<String> upsertTemplate(MailTemplate template) async {
    await _database.into(_database.messageTemplates).insertOnConflictUpdate(
          MessageTemplatesCompanion.insert(
            id: template.id,
            accountId: Value<String?>(template.accountId),
            name: template.name,
            subject: template.subject,
            bodyHtml: template.bodyHtml,
            sortOrder: Value<int>(template.sortOrder),
          ),
        );
    _notify();
    return template.id;
  }

  Future<void> deleteTemplate(String id) async {
    await (_database.delete(
      _database.messageTemplates,
    )..where((MessageTemplates t) => t.id.equals(id))).go();
    _notify();
  }

  Future<OutboundBlobRef> stageAttachmentBlob({
    required String accountId,
    required String sourcePath,
    String? fileName,
  }) async {
    final File source = File(sourcePath);
    if (!await source.exists()) {
      throw StateError('Attachment file not found: $sourcePath');
    }
    final int size = await source.length();
    final String id = _uuid.v4();
    final Directory base = await getApplicationSupportDirectory();
    final Directory dir = Directory(
      p.join(base.path, 'outbox_attachments', accountId),
    );
    await dir.create(recursive: true);
    final String name = fileName ?? p.basename(sourcePath);
    final String dest = p.join(dir.path, '${id}_$name');
    await source.copy(dest);
    final int createdAt = DateTime.now().millisecondsSinceEpoch;
    await _database.into(_database.attachmentBlobs).insert(
          AttachmentBlobsCompanion.insert(
            id: id,
            accountId: accountId,
            path: dest,
            sizeBytes: size,
            createdAt: createdAt,
          ),
        );
    _notify();
    return OutboundBlobRef(
      id: id,
      accountId: accountId,
      path: dest,
      sizeBytes: size,
      createdAt: createdAt,
    );
  }

  Future<OutboundBlobRef?> getAttachmentBlob(String id) async {
    final AttachmentBlob? row = await (_database.select(
      _database.attachmentBlobs,
    )..where((AttachmentBlobs t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) {
      return null;
    }
    return OutboundBlobRef(
      id: row.id,
      accountId: row.accountId,
      path: row.path,
      sizeBytes: row.sizeBytes,
      createdAt: row.createdAt,
    );
  }

  Future<void> deleteAttachmentBlob(String id) async {
    final OutboundBlobRef? blob = await getAttachmentBlob(id);
    if (blob != null) {
      try {
        final File file = File(blob.path);
        if (await file.exists()) {
          await file.delete();
        }
      } on FileSystemException {
        // Best-effort cleanup.
      }
    }
    await (_database.delete(
      _database.attachmentBlobs,
    )..where((AttachmentBlobs t) => t.id.equals(id))).go();
    _notify();
  }
}
