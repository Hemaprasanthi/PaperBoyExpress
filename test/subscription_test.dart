import 'package:flutter_test/flutter_test.dart';
import 'package:paperboy/models/newspaper.dart';
import 'package:paperboy/models/subscription.dart';
import 'package:paperboy/models/veggie_order.dart';

Subscription _sub({
  required DateTime start,
  required DateTime end,
  List<int> days = const [DateTime.monday, DateTime.wednesday],
  SubscriptionStatus status = SubscriptionStatus.active,
  DateTime? pausedFrom,
  DateTime? pausedUntil,
}) {
  return Subscription(
    id: 's1',
    customerUsername: 'u1',
    newspaper: const Newspaper(id: 'n1', name: 'Paper', pricePerCopy: 2),
    selectedWeekdays: days,
    copiesPerDelivery: 2,
    address: 'addr',
    startDate: start,
    endDate: end,
    status: status,
    pricePerCopyAtSignup: 3,
    pausedFrom: pausedFrom,
    pausedUntil: pausedUntil,
  );
}

void main() {
  group('countDeliveries', () {
    test('counts only the selected weekdays, inclusive of both ends', () {
      // Mon 2 Mar 2026 .. Sun 15 Mar 2026 has two Mondays and two Wednesdays.
      final n = countDeliveries(
        DateTime(2026, 3, 2),
        DateTime(2026, 3, 15),
        [DateTime.monday, DateTime.wednesday],
      );
      expect(n, 4);
    });

    test('is zero when no selected weekday falls in the range', () {
      expect(countDeliveries(DateTime(2026, 3, 2), DateTime(2026, 3, 2), [DateTime.tuesday]), 0);
    });
  });

  group('Subscription', () {
    test('prepaid price = locked price x copies x deliveries', () {
      final s = _sub(start: DateTime(2026, 3, 2), end: DateTime(2026, 3, 15));
      expect(s.totalDeliveries, 4);
      expect(s.periodPrice, 3 * 2 * 4);
    });

    test('delivers only inside the date range, on selected days', () {
      final s = _sub(start: DateTime(2026, 3, 2), end: DateTime(2026, 3, 15));
      expect(s.isDeliveryDay(DateTime(2026, 3, 2)), isTrue); // Monday, start day
      expect(s.isDeliveryDay(DateTime(2026, 3, 3)), isFalse); // Tuesday
      expect(s.isDeliveryDay(DateTime(2026, 3, 16)), isFalse); // after the end date
      expect(s.isDeliveryDay(DateTime(2026, 2, 23)), isFalse); // before the start date
    });

    test('skips paused days but resumes the day after the pause ends', () {
      final s = _sub(
        start: DateTime(2026, 3, 2),
        end: DateTime(2026, 3, 30),
        pausedFrom: DateTime(2026, 3, 9),
        pausedUntil: DateTime(2026, 3, 11),
      );
      expect(s.isDeliveryDay(DateTime(2026, 3, 9)), isFalse); // Monday, paused
      expect(s.isDeliveryDay(DateTime(2026, 3, 11)), isFalse); // Wednesday, paused
      expect(s.isDeliveryDay(DateTime(2026, 3, 16)), isTrue); // Monday after the pause
    });

    test('cancelled subscriptions never deliver', () {
      final s = _sub(
        start: DateTime(2026, 3, 2),
        end: DateTime(2026, 3, 30),
        status: SubscriptionStatus.cancelled,
      );
      expect(s.isDeliveryDay(DateTime(2026, 3, 2)), isFalse);
    });
  });

  group('VeggieOrder', () {
    VeggieOrder fromItems(Object items) => VeggieOrder.fromMap('o1', {
          'customerUsername': 'u1',
          'items': items,
          'totalAmount': 50,
          'zipCode': '560102',
          'address': 'addr',
          'orderedAt': '2026-03-02T10:00:00.000',
          'expectedDeliveryBy': '2026-03-02T10:15:00.000',
          'createdAt': '2026-03-02T10:00:00.000',
        });

    test('reads line items', () {
      final o = fromItems([
        {'id': 'tomato', 'name': 'Tomato', 'unit': 'kg', 'unitPrice': 40, 'quantity': 2},
      ]);
      expect(o.lines.single.total, 80);
      expect(o.itemsSummary, 'Tomato x2');
    });

    test('still reads older orders that stored {id: quantity}', () {
      final o = fromItems({'curry_leaves': 3});
      expect(o.lines.single.quantity, 3);
      expect(o.lines.single.name, 'curry leaves');
    });
  });
}
