// ==============================================================================
// File: lib/focus/focus_scorer.dart
// Description: Contract for assigning incoming mail to a Focus bucket.
// Component: Domain / Focus
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/focus/mail_message_draft.dart';

abstract interface class FocusScorer {
  FocusBucket score(MailMessageDraft draft);
}
