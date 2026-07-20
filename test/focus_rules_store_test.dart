// ==============================================================================
// File: test/focus_rules_store_test.dart
// Description: Focus override rule CRUD coverage, including deleteFocusRule (TC-4).
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-07-18
// Last Update: 2026-07-18
// ==============================================================================

import 'package:bytemail/domain/models.dart';
import 'package:bytemail/repository/database.dart' hide FocusRule;
import 'package:bytemail/repository/drift_mail_repository.dart';
import 'package:bytemail/repository/mail_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<DriftMailRepository> _openTestRepo() async {
  final ByteMailDatabase database = ByteMailDatabase(NativeDatabase.memory());
  return DriftMailRepository(database);
}

void main() {
  group('DriftFocusStore / DriftMailRepository focus rule CRUD', () {
    test('upsertFocusRule then listFocusRules round-trips a rule', () async {
      final DriftMailRepository repo = await _openTestRepo();
      addTearDown(repo.close);

      await repo.upsertFocusRule(
        const FocusRule(
          id: 'sender:global:a@byte.io',
          pattern: 'a@byte.io',
          matchType: FocusRuleMatchType.sender,
          bucket: FocusBucket.focused,
        ),
      );

      final List<FocusRule> rules = await repo.listFocusRules();
      expect(rules, hasLength(1));
      expect(rules.single.id, 'sender:global:a@byte.io');
      expect(rules.single.bucket, FocusBucket.focused);
    });

    test('deleteFocusRule removes exactly the matching rule', () async {
      final DriftMailRepository repo = await _openTestRepo();
      addTearDown(repo.close);

      await repo.upsertFocusRule(
        const FocusRule(
          id: 'sender:global:a@byte.io',
          pattern: 'a@byte.io',
          matchType: FocusRuleMatchType.sender,
          bucket: FocusBucket.focused,
        ),
      );
      await repo.upsertFocusRule(
        const FocusRule(
          id: 'domain:global:brand.com',
          pattern: 'brand.com',
          matchType: FocusRuleMatchType.domain,
          bucket: FocusBucket.other,
        ),
      );

      await repo.deleteFocusRule('sender:global:a@byte.io');

      final List<FocusRule> rules = await repo.listFocusRules();
      expect(rules, hasLength(1));
      expect(rules.single.id, 'domain:global:brand.com');
    });

    test('deleteFocusRule on a missing id is a no-op', () async {
      final DriftMailRepository repo = await _openTestRepo();
      addTearDown(repo.close);

      await repo.upsertFocusRule(
        const FocusRule(
          id: 'sender:global:a@byte.io',
          pattern: 'a@byte.io',
          matchType: FocusRuleMatchType.sender,
          bucket: FocusBucket.focused,
        ),
      );

      await repo.deleteFocusRule('does-not-exist');

      final List<FocusRule> rules = await repo.listFocusRules();
      expect(rules, hasLength(1));
    });

    test(
      'account-scoped rule persists accountId and survives listFocusRules',
      () async {
        final DriftMailRepository repo = await _openTestRepo();
        addTearDown(repo.close);

        await repo.upsertFocusRule(
          const FocusRule(
            id: 'sender:work:a@byte.io',
            accountId: 'work',
            pattern: 'a@byte.io',
            matchType: FocusRuleMatchType.sender,
            bucket: FocusBucket.other,
          ),
        );

        final List<FocusRule> rules = await repo.listFocusRules(
          accountId: 'work',
        );
        expect(rules, hasLength(1));
        expect(rules.single.accountId, 'work');

        await repo.deleteFocusRule('sender:work:a@byte.io');
        expect(await repo.listFocusRules(accountId: 'work'), isEmpty);
      },
    );
  });

  group('MailRepository default focus rule behavior', () {
    test(
      'base MailRepository.deleteFocusRule throws UnsupportedError',
      () async {
        final _StubMailRepository stub = _StubMailRepository();
        await expectLater(
          () => stub.deleteFocusRule('anything'),
          throwsUnsupportedError,
        );
      },
    );

    test('base MailRepository.upsertFocusRule throws UnsupportedError', () async {
      final _StubMailRepository stub = _StubMailRepository();
      await expectLater(
        () => stub.upsertFocusRule(
          const FocusRule(
            id: 'sender:global:a@byte.io',
            pattern: 'a@byte.io',
            matchType: FocusRuleMatchType.sender,
            bucket: FocusBucket.focused,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}

/// Extends (not `implements`) [MailRepository] so its concrete default
/// method bodies (e.g. [MailRepository.deleteFocusRule]) are inherited
/// normally, while every other abstract member routes through
/// [noSuchMethod] — avoiding ~50 lines of unrelated stub overrides for this
/// narrowly scoped default-behavior test.
class _StubMailRepository extends MailRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}
