// ==============================================================================
// File: bin/synesis_digest.dart
// Description: Desktop CLI entry for mail hygiene digest (Wave MH slice 1 stub).
// Component: Digest / CLI
// Version: 1.0 (Gold Master)
// Created: 2026-08-25
// Last Update: 2026-08-25
// ==============================================================================

import 'dart:io';

import 'package:synesis/digest/digest_classifier.dart';
import 'package:synesis/digest/digest_classification.dart';
import 'package:synesis/digest/digest_message.dart';
import 'package:synesis/digest/digest_report.dart';

Future<void> main(List<String> args) async {
  if (args.contains('--help') || args.contains('-h')) {
    stdout.writeln(_usage);
    return;
  }
  if (args.contains('--demo')) {
    await _runDemo();
    return;
  }
  stderr.writeln('Wave MH slice 1: live account fetch not wired yet.');
  stderr.writeln('Use --demo to classify fixture headers.');
  stderr.writeln('');
  stdout.writeln(_usage);
  exitCode = 64;
}

Future<void> _runDemo() async {
  final DateTime runAt = DateTime.utc(2026, 8, 25, 12);
  final DigestClassifier classifier = DigestClassifier(now: () => runAt);
  final List<DigestMessage> fixtures = _demoFixtures();
  final Map<String, DigestClassification> classifications =
      <String, DigestClassification>{};
  for (final DigestMessage message in fixtures) {
    classifications[message.id] = classifier.classify(message);
  }
  final String markdown = DigestReportBuilder().build(
    runAt: runAt,
    messages: fixtures,
    classifications: classifications,
  );
  stdout.writeln(markdown);
}

const String _usage = '''
synesis digest — mail hygiene digest (Wave MH slice 1)

Usage:
  dart run bin/synesis_digest.dart --demo     Classify fixture headers
  dart run bin/synesis_digest.dart --help     Show this help

Live multi-account fetch lands in a later slice.
''';

List<DigestMessage> _demoFixtures() {
  return <DigestMessage>[
    DigestMessage(
      id: 'urgent-1',
      accountId: 'work',
      accountAddress: 'trish@byte.io',
      fromAddress: 'security@google.com',
      fromName: 'Google',
      subject: 'Security alert: new sign-in',
      snippet: 'We noticed a new sign-in to your account.',
      toAddresses: <String>['trish@byte.io'],
      receivedAt: DateTime.utc(2026, 8, 24),
    ),
    DigestMessage(
      id: 'personal-1',
      accountId: 'work',
      accountAddress: 'trish@byte.io',
      fromAddress: 'maya@byte.io',
      fromName: 'Maya Chen',
      subject: 'Coffee tomorrow?',
      snippet: 'Are you free around 10?',
      toAddresses: <String>['trish@byte.io'],
      receivedAt: DateTime.utc(2026, 8, 23),
    ),
    DigestMessage(
      id: 'newsletter-1',
      accountId: 'home',
      accountAddress: 'trish@gmail.com',
      fromAddress: 'news@example.com',
      fromName: 'Example Weekly',
      subject: 'This week in widgets',
      snippet: 'Ten links you did not ask for.',
      toAddresses: <String>['trish@gmail.com'],
      listUnsubscribe: '<mailto:unsub@example.com>',
      gmailCategory: 'promotions',
      receivedAt: DateTime.utc(2026, 8, 22),
    ),
  ];
}
