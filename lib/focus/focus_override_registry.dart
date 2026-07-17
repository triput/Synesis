// ==============================================================================
// File: lib/focus/focus_override_registry.dart
// Description: In-memory Focus override rules backed by local persistence.
// Component: Domain / Focus
// Version: 1.0 (Gold Master)
// Created: 2026-07-14
// Last Update: 2026-07-14
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/focus/mail_message_draft.dart';
import 'package:bytemail/repository/mail_repository.dart';

class FocusOverrideRegistry {
  FocusOverrideRegistry({
    MailRepository? repository,
    List<FocusRule> rules = const <FocusRule>[],
  })  : _repository = repository,
        _rules = List<FocusRule>.unmodifiable(rules);

  final MailRepository? _repository;
  List<FocusRule> _rules;

  List<FocusRule> get rules => _rules;

  /// Refreshes locally cached rules when a repository is available.
  Future<void> load({String? accountId}) async {
    final MailRepository? repository = _repository;
    if (repository == null) {
      return;
    }
    _rules = List<FocusRule>.unmodifiable(
      await repository.listFocusRules(accountId: accountId),
    );
  }

  /// Replaces the in-memory rules, useful for immediate UI feedback and tests.
  void replaceRules(List<FocusRule> rules) {
    _rules = List<FocusRule>.unmodifiable(rules);
  }

  /// Returns an override when present. Exact sender rules outrank domain rules.
  FocusBucket? match(MailMessageDraft draft, {String? accountId}) {
    final String sender = _normaliseSender(draft.fromAddress);
    final String? domain = _domainFor(sender);
    if (sender.isEmpty) {
      return null;
    }

    final FocusRule? senderRule = _firstMatchingRule(
      FocusRuleMatchType.sender,
      sender,
      accountId,
    );
    if (senderRule != null) {
      return senderRule.bucket;
    }
    if (domain == null) {
      return null;
    }

    return _firstMatchingRule(FocusRuleMatchType.domain, domain, accountId)
        ?.bucket;
  }

  FocusRule? _firstMatchingRule(
    FocusRuleMatchType matchType,
    String value,
    String? accountId,
  ) {
    final FocusRule? accountRule = _matchingRule(
      matchType,
      value,
      accountId,
      requireAccountMatch: true,
    );
    return accountRule ??
        _matchingRule(
          matchType,
          value,
          accountId,
          requireAccountMatch: false,
        );
  }

  FocusRule? _matchingRule(
    FocusRuleMatchType matchType,
    String value,
    String? accountId, {
    required bool requireAccountMatch,
  }) {
    for (final FocusRule rule in _rules) {
      if (rule.matchType == matchType &&
          (requireAccountMatch
              ? accountId != null && rule.accountId == accountId
              : rule.accountId == null) &&
          _normalisePattern(rule.pattern, matchType) == value) {
        return rule;
      }
    }
    return null;
  }

  String _normalisePattern(String pattern, FocusRuleMatchType matchType) {
    final String trimmed = pattern.trim().toLowerCase();
    return matchType == FocusRuleMatchType.domain
        ? trimmed.replaceFirst(RegExp(r'^@'), '')
        : trimmed;
  }

  String _normaliseSender(String address) {
    final Match? bracketedAddress =
        RegExp(r'<\s*([^>\s]+@[^>\s]+)\s*>').firstMatch(address);
    return (bracketedAddress?.group(1) ?? address).trim().toLowerCase();
  }

  String? _domainFor(String sender) {
    final int atIndex = sender.lastIndexOf('@');
    if (atIndex <= 0 || atIndex == sender.length - 1) {
      return null;
    }
    return sender.substring(atIndex + 1);
  }
}
