// ==============================================================================
// File: test/digest_classifier_test.dart
// Description: Fixture tests for mail hygiene digest classifier (Wave MH slice 1).
// Component: Test
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'package:flutter_test/flutter_test.dart';
import 'package:synesis/digest/digest_bucket.dart';
import 'package:synesis/digest/digest_classifier.dart';
import 'package:synesis/digest/digest_classification.dart';
import 'package:synesis/digest/digest_message.dart';
import 'package:synesis/digest/digest_report.dart';

void main() {
  final DateTime fixedNow = DateTime.utc(2026, 8, 25);
  final DigestClassifier classifier = DigestClassifier(now: () => fixedNow);

  DigestMessage baseMessage({
    required String id,
    String accountId = 'work',
    String accountAddress = 'trish@byte.io',
    List<String> toAddresses = const <String>['trish@byte.io'],
    List<String> ccAddresses = const <String>[],
    String subject = 'Hello',
    String snippet = 'Body',
    String fromAddress = 'sender@example.com',
    String? listUnsubscribe,
    String? listId,
    String? gmailCategory,
    String? precedence,
  }) {
    return DigestMessage(
      id: id,
      accountId: accountId,
      accountAddress: accountAddress,
      fromAddress: fromAddress,
      fromName: 'Sender',
      subject: subject,
      snippet: snippet,
      toAddresses: toAddresses,
      ccAddresses: ccAddresses,
      listUnsubscribe: listUnsubscribe,
      listId: listId,
      gmailCategory: gmailCategory,
      precedence: precedence,
      receivedAt: DateTime.utc(2026, 8, 24),
    );
  }

  group('DigestClassifier exclusive buckets', () {
    test('security alert on To/Cc is urgent', () {
      final result = classifier.classify(
        baseMessage(
          id: 'u1',
          subject: 'Security alert: new sign-in',
          snippet: 'Unusual sign-in detected.',
        ),
      );
      expect(result.bucket, DigestBucket.urgent);
    });

    test('plain receipt on To/Cc is not urgent', () {
      final result = classifier.classify(
        baseMessage(
          id: 'r1',
          subject: 'Your receipt from Coffee Shop',
          snippet: 'Thanks for your purchase.',
        ),
      );
      expect(result.bucket, DigestBucket.personalNonUrgent);
    });

    test('dunning receipt language is urgent', () {
      final result = classifier.classify(
        baseMessage(
          id: 'd1',
          subject: 'Invoice past due',
          snippet: 'Payment failed — service will be suspended.',
        ),
      );
      expect(result.bucket, DigestBucket.urgent);
    });

    test('personal mail on To/Cc lands in personalNonUrgent', () {
      final result = classifier.classify(
        baseMessage(
          id: 'p1',
          subject: 'Lunch?',
          snippet: 'Free tomorrow?',
        ),
      );
      expect(result.bucket, DigestBucket.personalNonUrgent);
    });

    test('bcc-only mail is not personal or urgent', () {
      final result = classifier.classify(
        baseMessage(
          id: 'b1',
          toAddresses: const <String>['other@byte.io'],
          subject: 'Action required immediately',
          snippet: 'Please review this today.',
        ),
      );
      expect(result.bucket, isNot(DigestBucket.urgent));
      expect(result.bucket, isNot(DigestBucket.personalNonUrgent));
    });

    test('List-Unsubscribe routes to newsletters', () {
      final result = classifier.classify(
        baseMessage(
          id: 'n1',
          toAddresses: const <String>['other@byte.io'],
          listUnsubscribe: '<https://example.com/unsub>',
          subject: 'Weekly deals',
        ),
      );
      expect(result.bucket, DigestBucket.newsletters);
    });

    test('LinkedIn sender routes to social', () {
      final result = classifier.classify(
        baseMessage(
          id: 's1',
          fromAddress: 'notifications@linkedin.com',
          toAddresses: const <String>['other@byte.io'],
          subject: 'Someone viewed your profile',
        ),
      );
      expect(result.bucket, DigestBucket.social);
    });
  });

  group('DigestClassifier money overlay', () {
    test('receipt subject tags high money confidence', () {
      final result = classifier.classify(
        baseMessage(
          id: 'm1',
          subject: 'Your receipt from Acme',
          snippet: 'Order confirmation #123',
        ),
      );
      expect(result.moneyConfidence, DigestMoneyConfidence.high);
    });

    test('money overlay does not change exclusive bucket', () {
      final result = classifier.classify(
        baseMessage(
          id: 'm2',
          subject: 'Your receipt from Acme',
          snippet: 'Thanks for subscribing.',
        ),
      );
      expect(result.bucket, DigestBucket.personalNonUrgent);
      expect(result.moneyConfidence, DigestMoneyConfidence.high);
    });
  });

  group('DigestReportBuilder', () {
    test('renders per-account bucket counts and urgent list', () {
      final List<DigestMessage> messages = <DigestMessage>[
        baseMessage(
          id: 'u1',
          subject: 'Security alert',
          snippet: 'Verify your account.',
        ),
        baseMessage(
          id: 'p1',
          subject: 'Coffee?',
          snippet: 'Tomorrow?',
        ),
      ];
      final Map<String, DigestClassification> classifications =
          <String, DigestClassification>{
            for (final DigestMessage message in messages)
              message.id: classifier.classify(message),
          };
      final String markdown = DigestReportBuilder().build(
        runAt: fixedNow,
        messages: messages,
        classifications: classifications,
      );
      expect(markdown, contains('# Synesis mail hygiene digest'));
      expect(markdown, contains('urgent: 1'));
      expect(markdown, contains('Security alert'));
    });
  });
}
