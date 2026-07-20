// ==============================================================================
// File: lib/mailbox/message_body_cache.dart
// Description: Fetches and caches message bodies/headers via mail providers
// Component: Data / Sync
// Version: 1.0 (Gold Master)
// Created: 2026-07-17
// Last Update: 2026-07-18
// ==============================================================================

import 'dart:async';

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/domain/sync_profile.dart';
import 'package:bytemail/focus/focus.dart';
import 'package:bytemail/mailbox/mailbox_mutation_result.dart';
import 'package:bytemail/mailbox/message_action_service.dart'
    show MailboxMutationApply;
import 'package:bytemail/protocol/mail_provider.dart';
import 'package:bytemail/repository/drift/drift_mappers.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:bytemail/sync/sync_engine.dart';
import 'package:bytemail/ui/mailbox/mailbox_state.dart';
import 'package:bytemail/ui/mailbox/message_body_normalizer.dart';

/// Loads message bodies and raw headers, updating local cache and focus scores.
class MessageBodyCache {
  MessageBodyCache({
    required MailRepository repository,
    required ProviderResolver resolveProvider,
    int Function()? deviceRetentionDays,
  }) : _repository = repository,
       _resolveProvider = resolveProvider,
       _deviceRetentionDays = deviceRetentionDays ?? (() => 180);

  final MailRepository _repository;
  final ProviderResolver _resolveProvider;
  final int Function() _deviceRetentionDays;

  int _bodyFetchGeneration = 0;
  int _headersFetchGeneration = 0;
  final Set<String> _fetchedBodyIds = <String>{};
  final Set<String> _fetchedHeaderIds = <String>{};
  final Set<String> _inFlightBodyIds = <String>{};
  final Set<String> _inFlightHeaderIds = <String>{};

  /// Fetches and caches the body for [id] when missing or snippet-only.
  ///
  /// Returns `null` when no work is needed. Progressive loading patches are
  /// delivered through [apply] when provided; the final patch is also returned.
  Future<MailboxMutationResult?> ensureBodyCached(
    MailboxState state,
    String id, {
    MailboxMutationApply? apply,
    required bool Function() isClosed,
    MailboxState Function()? currentState,
  }) async {
    if (_inFlightBodyIds.contains(id)) {
      return null;
    }
    final MailMessage? message = _messageById(state, id);
    if (message == null || !_needsBodyFetch(message)) {
      return null;
    }
    final ResolvedSyncPolicy policy = await _repository.resolvePolicy(
      message.accountId,
      fallbackRetentionDays: _deviceRetentionDays(),
    );
    // attachmentMaxMb is carried on the policy for future fetch/send gates.
    if (policy.bodyPolicy == BodyFetchPolicy.headersOnly) {
      return null;
    }
    final String? providerId = message.providerId;
    if (providerId == null || providerId.isEmpty) {
      return null;
    }

    final int generation = ++_bodyFetchGeneration;
    _inFlightBodyIds.add(id);
    final MailboxMutationResult loading = const MailboxMutationResult(
      isLoadingBody: true,
      clearBodyError: true,
    );
    await apply?.call(loading);

    MailProvider? provider;
    try {
      provider = await _resolveProvider(message.accountId);
      if (provider == null) {
        if (!_isCurrentBodyFetch(
          generation,
          id,
          isClosed: isClosed,
          currentState: currentState,
        )) {
          return null;
        }
        _fetchedBodyIds.add(id);
        final MailboxMutationResult done = const MailboxMutationResult(
          isLoadingBody: false,
        );
        await apply?.call(done);
        return done;
      }

      String? folderRemoteId;
      final String? folderId = message.folderId;
      if (folderId != null) {
        final MailFolder? folder = await _repository.getFolder(folderId);
        folderRemoteId = folder?.remoteId;
      }

      final String? rawBody = await provider.fetchBody(
        providerId,
        folderRemoteId: folderRemoteId,
      );
      if (!_isCurrentBodyFetch(
        generation,
        id,
        isClosed: isClosed,
        currentState: currentState,
      )) {
        return null;
      }
      final String? prepared = rawBody == null
          ? null
          : prepareMessageBody(rawBody);
      _fetchedBodyIds.add(id);
      if (prepared != null && prepared.isNotEmpty) {
        await _repository.updateMessageBody(id, prepared);
        if (!_isCurrentBodyFetch(
          generation,
          id,
          isClosed: isClosed,
          currentState: currentState,
        )) {
          return null;
        }
        final MailboxState latest = currentState?.call() ?? state;
        final List<MailMessage> updated = latest.messages
            .map((MailMessage m) => m.id == id ? m.copyWith(body: prepared) : m)
            .toList(growable: false);
        final MailboxMutationResult done = MailboxMutationResult(
          messages: updated,
          isLoadingBody: false,
          clearBodyError: true,
        );
        await apply?.call(done);
        return done;
      }
      final MailboxMutationResult empty = const MailboxMutationResult(
        isLoadingBody: false,
        bodyErrorMessage: 'Message body was empty on the server.',
      );
      await apply?.call(empty);
      return empty;
    } catch (e) {
      if (!_isCurrentBodyFetch(
        generation,
        id,
        isClosed: isClosed,
        currentState: currentState,
      )) {
        return null;
      }
      final MailboxMutationResult failed = MailboxMutationResult(
        isLoadingBody: false,
        bodyErrorMessage: e.toString(),
      );
      await apply?.call(failed);
      return failed;
    } finally {
      _inFlightBodyIds.remove(id);
      final MailProvider? toDispose = provider;
      if (toDispose != null) {
        await toDispose.dispose();
      }
    }
  }

  /// Loads raw RFC822 headers for [messageId], preferring local cache.
  Future<MailboxMutationResult?> ensureHeadersCached(
    MailboxState state,
    String messageId, {
    MailboxMutationApply? apply,
    required bool Function() isClosed,
    MailboxState Function()? currentState,
  }) async {
    final MailboxMutationResult clearErr = const MailboxMutationResult(
      clearHeadersError: true,
    );
    await apply?.call(clearErr);

    if (_inFlightHeaderIds.contains(messageId)) {
      return null;
    }
    final MailMessage? message = _messageById(state, messageId);
    if (message == null) {
      return null;
    }
    final String? cached = message.rawHeaders?.trim();
    if (cached != null && cached.isNotEmpty) {
      return null;
    }
    if (_fetchedHeaderIds.contains(messageId)) {
      return null;
    }
    final String? providerId = message.providerId;
    if (providerId == null || providerId.isEmpty) {
      return null;
    }

    final int generation = ++_headersFetchGeneration;
    _inFlightHeaderIds.add(messageId);
    final MailboxMutationResult loading = const MailboxMutationResult(
      isLoadingHeaders: true,
      clearHeadersError: true,
    );
    await apply?.call(loading);

    MailProvider? provider;
    try {
      provider = await _resolveProvider(message.accountId);
      if (provider == null) {
        if (!_isCurrentHeadersFetch(generation, isClosed: isClosed)) {
          return null;
        }
        _fetchedHeaderIds.add(messageId);
        final MailboxMutationResult done = const MailboxMutationResult(
          isLoadingHeaders: false,
        );
        await apply?.call(done);
        return done;
      }

      String? folderRemoteId;
      final String? folderId = message.folderId;
      if (folderId != null) {
        final MailFolder? folder = await _repository.getFolder(folderId);
        folderRemoteId = folder?.remoteId;
      }

      final String? rawHeaders = await provider.fetchHeaders(
        providerId,
        folderRemoteId: folderRemoteId,
      );
      if (!_isCurrentHeadersFetch(generation, isClosed: isClosed)) {
        return null;
      }
      _fetchedHeaderIds.add(messageId);
      if (rawHeaders != null && rawHeaders.trim().isNotEmpty) {
        await _repository.updateMessageRawHeaders(messageId, rawHeaders);
        final ({String to, String cc}) parsed =
            recipientsFromRawHeaders(rawHeaders);
        final FocusOverrideRegistry overrides = FocusOverrideRegistry(
          rules: await _repository.listFocusRules(
            accountId: message.accountId,
          ),
        );
        final FocusBucket scored = RuleBasedFocusScorer(
          overrides: overrides,
          accountId: message.accountId,
        ).score(
          MailMessageDraft(
            fromAddress: message.fromAddress,
            subject: message.subject,
            headers: focusHeadersFromRaw(rawHeaders),
          ),
        );
        if (scored != message.bucket) {
          await _repository.updateMessageFocusBucket(messageId, scored);
        }
        if (!_isCurrentHeadersFetch(generation, isClosed: isClosed)) {
          return null;
        }
        final MailboxState latest = currentState?.call() ?? state;
        final List<MailMessage> updated = latest.messages
            .map(
              (MailMessage m) => m.id == messageId
                  ? m.copyWith(
                      rawHeaders: rawHeaders,
                      toRecipients: parsed.to,
                      ccRecipients: parsed.cc,
                      bucket: scored,
                    )
                  : m,
            )
            .toList(growable: false);
        final MailboxMutationResult done = MailboxMutationResult(
          messages: updated,
          isLoadingHeaders: false,
          clearHeadersError: true,
        );
        await apply?.call(done);
        return done;
      }
      final MailboxMutationResult empty = const MailboxMutationResult(
        isLoadingHeaders: false,
        headersErrorMessage: 'No raw headers were returned by the server.',
      );
      await apply?.call(empty);
      return empty;
    } catch (e) {
      if (!_isCurrentHeadersFetch(generation, isClosed: isClosed)) {
        return null;
      }
      final MailboxMutationResult failed = MailboxMutationResult(
        isLoadingHeaders: false,
        headersErrorMessage: e.toString(),
      );
      await apply?.call(failed);
      return failed;
    } finally {
      _inFlightHeaderIds.remove(messageId);
      final MailProvider? toDispose = provider;
      if (toDispose != null) {
        await toDispose.dispose();
      }
    }
  }

  bool _isCurrentHeadersFetch(
    int generation, {
    required bool Function() isClosed,
  }) {
    return !isClosed() && _headersFetchGeneration == generation;
  }

  bool _isCurrentBodyFetch(
    int generation,
    String id, {
    required bool Function() isClosed,
    MailboxState Function()? currentState,
  }) {
    if (isClosed() || _bodyFetchGeneration != generation) {
      return false;
    }
    final MailboxState latest = currentState?.call() ?? const MailboxState();
    return latest.selectedMessageId == id ||
        (latest.selectedMessageId == null &&
            latest.selectedMessage?.id == id);
  }

  MailMessage? _messageById(MailboxState state, String id) {
    for (final MailMessage message in state.messages) {
      if (message.id == id) {
        return message;
      }
    }
    return null;
  }

  bool _needsBodyFetch(MailMessage message) {
    if (_fetchedBodyIds.contains(message.id)) {
      return false;
    }
    final String? providerId = message.providerId;
    if (providerId == null || providerId.isEmpty) {
      return false;
    }
    final String body = message.body.trim();
    if (body.isEmpty) {
      return true;
    }
    final String snippet = message.snippet.trim();
    if (snippet.isEmpty) {
      return false;
    }
    return body == snippet;
  }
}
