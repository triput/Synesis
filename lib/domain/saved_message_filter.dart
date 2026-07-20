// ==============================================================================
// File: lib/domain/saved_message_filter.dart
// Description: Named device-local message list filter presets.
// Component: Domain
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/query/message_query.dart';
import 'package:equatable/equatable.dart';

/// Maximum named saved filters stored on device (soft cap).
const int kMaxSavedMessageFilters = 20;

/// A user-named snapshot of [MessageViewFilter] for quick re-apply.
class SavedMessageFilter extends Equatable {
  const SavedMessageFilter({
    required this.id,
    required this.name,
    required this.filter,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final MessageViewFilter filter;
  final int createdAt;
  final int updatedAt;

  SavedMessageFilter copyWith({
    String? id,
    String? name,
    MessageViewFilter? filter,
    int? createdAt,
    int? updatedAt,
  }) {
    return SavedMessageFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      filter: filter ?? this.filter,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'name': name,
        'filter': filter.toJson(),
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  static SavedMessageFilter fromJson(Map<String, dynamic> json) {
    return SavedMessageFilter(
      id: json['id'] as String,
      name: json['name'] as String,
      filter: MessageViewFilter.fromJson(
        json['filter'] as Map<String, dynamic>,
      ),
      createdAt: json['createdAt'] as int,
      updatedAt: json['updatedAt'] as int,
    );
  }

  @override
  List<Object?> get props => <Object?>[id, name, filter, createdAt, updatedAt];
}
