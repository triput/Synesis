import 'package:bytemail/domain/models.dart';
import 'package:bytemail/focus/focus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const RuleBasedFocusScorer scorer = RuleBasedFocusScorer();

  MailMessageDraft draft({
    String fromAddress = 'maya@example.com',
    String subject = 'Hello',
    Map<String, String> headers = const <String, String>{},
  }) {
    return MailMessageDraft(
      fromAddress: fromAddress,
      subject: subject,
      headers: headers,
    );
  }

  group('RuleBasedFocusScorer', () {
    test('focuses ordinary person-to-person messages', () {
      expect(scorer.score(draft()), FocusBucket.focused);
    });

    test('places list and automated mail in Other', () {
      final List<MailMessageDraft> automated = <MailMessageDraft>[
        draft(headers: const <String, String>{'List-Id': 'news.example.com'}),
        draft(
          headers: const <String, String>{
            'List-Unsubscribe': '<mailto:unsub@example.com>',
          },
        ),
        draft(headers: const <String, String>{'Precedence': 'bulk'}),
        draft(headers: const <String, String>{'Precedence': 'list'}),
        draft(
          headers: const <String, String>{'Auto-Submitted': 'auto-generated'},
        ),
        draft(headers: const <String, String>{'Feedback-ID': '1:campaign'}),
        draft(headers: const <String, String>{'X-Mailer': 'Mailchimp'}),
        draft(fromAddress: 'no-reply@example.com'),
        draft(fromAddress: 'newsletter@brand.com'),
        draft(fromAddress: 'mailer-daemon@example.com'),
        draft(subject: 'Your weekly newsletter is here'),
      ];

      for (final MailMessageDraft message in automated) {
        expect(scorer.score(message), FocusBucket.other);
      }
    });

    test('keeps ordinary support-style senders focused without bulk headers', () {
      expect(
        scorer.score(draft(fromAddress: 'support@example.com')),
        FocusBucket.focused,
      );
      expect(
        scorer.score(draft(fromAddress: 'hello@startup.dev')),
        FocusBucket.focused,
      );
    });

    test('matches headers without regard to casing', () {
      expect(
        scorer.score(
          draft(headers: const <String, String>{'lIsT-Id': 'weekly'}),
        ),
        FocusBucket.other,
      );
    });

    test('sender override wins over algorithmic classification', () {
      final FocusOverrideRegistry registry = FocusOverrideRegistry(
        rules: const <FocusRule>[
          FocusRule(
            id: 'sender-focused',
            pattern: 'no-reply@billing.example',
            matchType: FocusRuleMatchType.sender,
            bucket: FocusBucket.focused,
          ),
        ],
      );
      final RuleBasedFocusScorer overridden = RuleBasedFocusScorer(
        overrides: registry,
      );

      expect(
        overridden.score(draft(fromAddress: 'No-Reply@Billing.Example')),
        FocusBucket.focused,
      );
    });

    test('exact sender override outranks a matching domain override', () {
      final FocusOverrideRegistry registry = FocusOverrideRegistry(
        rules: const <FocusRule>[
          FocusRule(
            id: 'domain-other',
            pattern: 'example.com',
            matchType: FocusRuleMatchType.domain,
            bucket: FocusBucket.other,
          ),
          FocusRule(
            id: 'sender-focused',
            pattern: 'maya@example.com',
            matchType: FocusRuleMatchType.sender,
            bucket: FocusBucket.focused,
          ),
        ],
      );

      expect(registry.match(draft()), FocusBucket.focused);
    });

    test('applies account-specific and global rules appropriately', () {
      final FocusOverrideRegistry registry = FocusOverrideRegistry(
        rules: const <FocusRule>[
          FocusRule(
            id: 'global',
            pattern: 'news.example',
            matchType: FocusRuleMatchType.domain,
            bucket: FocusBucket.other,
          ),
          FocusRule(
            id: 'work',
            accountId: 'work',
            pattern: 'news.example',
            matchType: FocusRuleMatchType.domain,
            bucket: FocusBucket.focused,
          ),
        ],
      );

      expect(
        registry.match(
          draft(fromAddress: 'updates@news.example'),
          accountId: 'work',
        ),
        FocusBucket.focused,
      );
      expect(
        registry.match(
          draft(fromAddress: 'updates@news.example'),
          accountId: 'personal',
        ),
        FocusBucket.other,
      );
    });
  });
}
