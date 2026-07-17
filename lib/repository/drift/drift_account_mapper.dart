// ==============================================================================
// File: lib/repository/drift/drift_account_mapper.dart
// Description: Account row ↔ MailAccount mapping (Color boundary for accent).
// Component: Repository / Data
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/database.dart';
import 'package:flutter/material.dart';

/// Maps a Drift [Account] row to domain [MailAccount], converting stored
/// `accentArgb` int → Flutter [Color] at this repository boundary only.
MailAccount accountFromRow(Account row) => MailAccount(
  id: row.id,
  label: row.label,
  address: row.address,
  accent: Color(row.accentArgb),
  providerType: row.providerType,
  storageType: row.storageType,
  focusEnabled: row.focusEnabled,
  credentialsRef: row.credentialsRef,
  syncProfileId: row.syncProfileId,
  retentionDaysOverride: row.retentionDaysOverride,
);

/// Extracts ARGB int from domain [MailAccount.accent] for SQLite storage.
int accentArgbFromAccount(MailAccount account) => account.accent.toARGB32();
