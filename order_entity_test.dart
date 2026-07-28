import 'package:flutter_test/flutter_test.dart';
import 'package:scancard_ai/features/orders/domain/entities/order_entity.dart';
import 'package:scancard_ai/features/orders/domain/entities/order_item.dart';

void main() {
  group('OrderEntity computed totals', () {
    final now = DateTime(2026, 1, 1);
    final order = OrderEntity(
      id: 'o1',
      ownerId: 'owner-1',
      createdAt: now,
      updatedAt: now,
      items: const [
        OrderItem(name: 'Widget', quantity: 2, unitPrice: 5.00),
        OrderItem(name: 'Gadget', quantity: 1, unitPrice: 12.50),
      ],
      taxAmount: 1.75,
      discountAmount: 2.00,
    );

    test('subtotal sums quantity * unitPrice across items', () {
      expect(order.subtotal, 22.50);
    });

    test('total adds tax and subtracts discount from subtotal', () {
      expect(order.total, 22.25); // 22.50 + 1.75 - 2.00
    });

    test('itemCount sums quantities, not distinct item rows', () {
      expect(order.itemCount, 3);
    });

    test('an order with no items has zero subtotal/total/count', () {
      final empty = OrderEntity(id: 'o2', ownerId: 'owner-1', createdAt: now, updatedAt: now);
      expect(empty.subtotal, 0);
      expect(empty.total, 0);
      expect(empty.itemCount, 0);
    });
  });
}
