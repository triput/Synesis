// ==============================================================================
// File: lib/domain/sync_profile.dart
// Description: Sync profile domain types, body policy, and resolved account policy
// Component: Domain
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'dart:convert';

/// Controls when message bodies are fetched from the provider.
enum BodyFetchPolicy {
  /// Fetch body when the user opens a message (default).
  onOpen,

  /// Never fetch bodies; headers/snippets only.
  headersOnly,

  /// Fetch bodies eagerly when listing/refreshing (same gate as onOpen for now).
  fullAlways,
}

/// Maps [BodyFetchPolicy] to/from `sync_profiles.body_policy` DB strings.
extension BodyFetchPolicyDb on BodyFetchPolicy {
  String get dbValue => switch (this) {
    BodyFetchPolicy.onOpen => 'on_open',
    BodyFetchPolicy.headersOnly => 'headers_only',
    BodyFetchPolicy.fullAlways => 'full_always',
  };

  static BodyFetchPolicy fromDb(String value) {
    switch (value.trim().toLowerCase()) {
      case 'headers_only':
        return BodyFetchPolicy.headersOnly;
      case 'full_always':
        return BodyFetchPolicy.fullAlways;
      case 'on_open':
      default:
        return BodyFetchPolicy.onOpen;
    }
  }
}

/// Named sync/storage profile stored in `sync_profiles`.
class SyncProfile {
  const SyncProfile({
    required this.id,
    required this.name,
    required this.retentionDays,
    required this.bodyPolicy,
    required this.attachmentMaxMb,
    required this.isDefault,
    this.folderScope,
  });

  final String id;
  final String name;
  final int retentionDays;

  /// Folder roles and/or remote ids allowed for message sync.
  ///
  /// `null` means all folders. Non-null lists are matched case-insensitively
  /// against [MailFolder.role], [MailFolder.remoteId], or [MailFolder.id].
  final List<String>? folderScope;
  final BodyFetchPolicy bodyPolicy;
  final int attachmentMaxMb;
  final bool isDefault;

  SyncProfile copyWith({
    String? id,
    String? name,
    int? retentionDays,
    List<String>? folderScope,
    bool clearFolderScope = false,
    BodyFetchPolicy? bodyPolicy,
    int? attachmentMaxMb,
    bool? isDefault,
  }) {
    return SyncProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      retentionDays: retentionDays ?? this.retentionDays,
      folderScope: clearFolderScope ? null : (folderScope ?? this.folderScope),
      bodyPolicy: bodyPolicy ?? this.bodyPolicy,
      attachmentMaxMb: attachmentMaxMb ?? this.attachmentMaxMb,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  /// Encodes [folderScope] for `folder_scope_json` (null → null column).
  String? encodeFolderScopeJson() {
    final List<String>? scope = folderScope;
    if (scope == null) {
      return null;
    }
    return jsonEncode(scope);
  }

  /// Parses `folder_scope_json`.
  ///
  /// Accepted forms:
  /// - `null` / empty / `"all"` → all folders (`null` scope)
  /// - JSON array of strings → role names (e.g. `inbox`, `sent`) and/or
  ///   provider remote ids (and local folder ids as a fallback match)
  static List<String>? parseFolderScopeJson(String? raw) {
    if (raw == null) {
      return null;
    }
    final String trimmed = raw.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'all') {
      return null;
    }
    if (trimmed.toLowerCase() == 'null') {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(trimmed);
      if (decoded == null) {
        return null;
      }
      if (decoded is String) {
        final String token = decoded.trim().toLowerCase();
        if (token.isEmpty || token == 'all') {
          return null;
        }
        return <String>[decoded.trim()];
      }
      if (decoded is List) {
        final List<String> items = decoded
            .map((Object? e) => e?.toString().trim() ?? '')
            .where((String s) => s.isNotEmpty)
            .toList(growable: false);
        return items.isEmpty ? null : items;
      }
    } on FormatException {
      return null;
    }
    return null;
  }
}

/// Effective sync/storage policy for one account after override merge.
class ResolvedSyncPolicy {
  const ResolvedSyncPolicy({
    required this.accountId,
    required this.profileId,
    required this.retentionDays,
    required this.bodyPolicy,
    required this.attachmentMaxMb,
    this.folderScope,
  });

  final String accountId;
  final String profileId;
  final int retentionDays;
  final List<String>? folderScope;
  final BodyFetchPolicy bodyPolicy;
  final int attachmentMaxMb;

  /// Whether a folder should be message-synced under this policy.
  ///
  /// [folderScope] interpretation:
  /// - `null` → all folders allowed
  /// - non-null → allow when any entry matches (case-insensitive) the folder
  ///   [role], [remoteId], or local [folderId]
  bool allowsFolder({
    String? role,
    String? remoteId,
    String? folderId,
  }) {
    final List<String>? scope = folderScope;
    if (scope == null) {
      return true;
    }
    final Set<String> tokens = scope
        .map((String s) => s.trim().toLowerCase())
        .where((String s) => s.isNotEmpty)
        .toSet();
    if (tokens.isEmpty) {
      return true;
    }
    final String? normalizedRole = role?.trim().toLowerCase();
    if (normalizedRole != null &&
        normalizedRole.isNotEmpty &&
        tokens.contains(normalizedRole)) {
      return true;
    }
    final String? normalizedRemote = remoteId?.trim().toLowerCase();
    if (normalizedRemote != null &&
        normalizedRemote.isNotEmpty &&
        tokens.contains(normalizedRemote)) {
      return true;
    }
    final String? normalizedId = folderId?.trim().toLowerCase();
    if (normalizedId != null &&
        normalizedId.isNotEmpty &&
        tokens.contains(normalizedId)) {
      return true;
    }
    return false;
  }
}
