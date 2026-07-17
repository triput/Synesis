// ==============================================================================
// File: lib/mailbox/mailbox_mutation_result.dart
// Description: Patch object for mailbox mutations applied by MailboxCubit
// Component: Data / Bloc
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-17
// ==============================================================================

import 'package:bytemail/domain/models.dart';

/// Result patch from [MessageActionService] / [MessageBodyCache] for cubit emit.
class MailboxMutationResult {
  const MailboxMutationResult({
    this.messages,
    this.folders,
    this.selectedMessageId,
    this.clearSelectedMessageId = false,
    this.selectedMessageIds,
    this.clearSelectedMessageIds = false,
    this.errorMessage,
    this.clearError = false,
    this.shouldRefresh = false,
    this.isLoadingBody,
    this.isLoadingHeaders,
    this.bodyErrorMessage,
    this.clearBodyError = false,
    this.headersErrorMessage,
    this.clearHeadersError = false,
    this.fetchBodyMessageId,
  });

  final List<MailMessage>? messages;
  final List<MailFolder>? folders;
  final String? selectedMessageId;
  final bool clearSelectedMessageId;
  final Set<String>? selectedMessageIds;
  final bool clearSelectedMessageIds;
  final String? errorMessage;
  final bool clearError;
  final bool shouldRefresh;

  /// Body/header cache progressive UI fields.
  final bool? isLoadingBody;
  final bool? isLoadingHeaders;
  final String? bodyErrorMessage;
  final bool clearBodyError;
  final String? headersErrorMessage;
  final bool clearHeadersError;

  /// When set, cubit should ensure the body is cached for this message id.
  final String? fetchBodyMessageId;
}
