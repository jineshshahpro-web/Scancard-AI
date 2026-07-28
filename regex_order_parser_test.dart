import 'package:flutter_test/flutter_test.dart';
import 'package:scancard_ai/features/orders/data/services/regex_order_parser.dart';

void main() {
  group('RegexOrderParser', () {
    test('extracts vendor, line items (qty x name price), and tax', () {
      const raw = '''
Corner Bakery Cafe
2x Cappuccino 8.50
Croissant 4.25
Tax 1.10
Total 22.15
''';
      final result = RegexOrderParser.parse(raw);

      expect(result.vendor, 'Corner Bakery Cafe');
      expect(result.items.length, 2);
      expect(result.items[0].name, 'Cappuccino');
      expect(result.items[0].quantity, 2);
      expect(result.items[0].unitPrice, 8.50);
      expect(result.items[1].quantity, 1); // no explicit "1x" prefix
      expect(result.tax, 1.10);
    });

    test('ignores the totals line itself as an item', () {
      const raw = '''
Shop
Widget 5.00
Total 5.00
''';
      final result = RegexOrderParser.parse(raw);
      expect(result.items.length, 1);
      expect(result.items.first.name, 'Widget');
    });

    test('returns an empty item list without throwing on unparseable text', () {
      const raw = 'just some garbled text with no prices';
      expect(() => RegexOrderParser.parse(raw), returnsNormally);
      expect(RegexOrderParser.parse(raw).items, isEmpty);
    });

    test('stress: parses 1,000 synthetic receipts quickly', () {
      final receipts = List.generate(1000, (i) {
        return 'Store $i\n2x Item A ${(i % 20) + 1}.99\nItem B ${(i % 5) + 2}.50\nTax 0.75\nTotal 10.00';
      });
      final stopwatch = Stopwatch()..start();
      for (final r in receipts) {
        expect(RegexOrderParser.parse(r).items.length, 2);
      }
      stopwatch.stop();
      expect(stopwatch.elapsedMilliseconds, lessThan(2000));
    });
  });
}
