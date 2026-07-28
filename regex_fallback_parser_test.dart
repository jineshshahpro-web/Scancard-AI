import 'package:flutter_test/flutter_test.dart';
import 'package:scancard_ai/features/ai_parsing/data/services/regex_fallback_parser.dart';

void main() {
  group('RegexFallbackParser', () {
    test('extracts emails, phones, and a website from a typical card', () {
      const raw = '''
Jane Doe
Senior Product Manager
Acme Corp
jane.doe@acme.com
+1 (415) 555-0132
www.acme.com
''';
      final result = RegexFallbackParser.parse(raw);

      expect(result.emails, contains('jane.doe@acme.com'));
      expect(result.phones, isNotEmpty);
      expect(result.phones.first.replaceAll(RegExp(r'\D'), ''), contains('4155550132'));
      expect(result.website, isNotNull);
      expect(result.website, contains('acme.com'));
      expect(result.jobTitle, contains('Product Manager'));
      expect(result.company, contains('Acme Corp'));
      expect(result.fullName, isNotEmpty);
      expect(result.confidence, lessThan(1.0)); // always marked lower-confidence than AI parsing
    });

    test('does not crash and returns empty fields on blank input', () {
      final result = RegexFallbackParser.parse('');
      expect(result.fullName, isEmpty);
      expect(result.emails, isEmpty);
      expect(result.phones, isEmpty);
    });

    test('deduplicates repeated emails/phones across lines', () {
      const raw = '''
John Smith
john@company.com
Call: john@company.com
415-555-0100
415-555-0100
''';
      final result = RegexFallbackParser.parse(raw);
      expect(result.emails.length, 1);
      expect(result.phones.length, 1);
    });

    test('handles a messy, noisy OCR block without throwing', () {
      const raw = '''
##!! garbled >>>
J4NE  D0E
info@ex-ample.co.uk ; sales@ex-ample.co.uk
Tel : +44 20 7946 0958 / +44 20 7946 0959
https://sub.ex-ample.co.uk/team?ref=card
Suite 400, Some Street, Some City
''';
      expect(() => RegexFallbackParser.parse(raw), returnsNormally);
      final result = RegexFallbackParser.parse(raw);
      expect(result.emails.length, 2);
      expect(result.phones.length, greaterThanOrEqualTo(1));
    });

    test('stress: parses a large batch of synthetic OCR blocks quickly', () {
      final blocks = List.generate(2000, (i) {
        return 'Person Number $i\nRole $i\nCompany $i Inc\n'
            'person$i@example.com\n+1 415 555 ${(1000 + i).toString().padLeft(4, '0')}\n'
            'www.example$i.com';
      });

      final stopwatch = Stopwatch()..start();
      for (final block in blocks) {
        final result = RegexFallbackParser.parse(block);
        expect(result.emails, isNotEmpty);
      }
      stopwatch.stop();

      // Purely regex-based and synchronous — 2,000 cards should parse
      // well under a second on any reasonable test machine.
      expect(stopwatch.elapsedMilliseconds, lessThan(3000));
    });
  });
}
