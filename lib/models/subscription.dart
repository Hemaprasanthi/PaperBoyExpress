import 'newspaper.dart';

/// Maps DateTime.monday..DateTime.sunday (1-7) to a short label.
const Map<int, String> kWeekdayLabels = {
  DateTime.monday: 'Mon',
  DateTime.tuesday: 'Tue',
  DateTime.wednesday: 'Wed',
  DateTime.thursday: 'Thu',
  DateTime.friday: 'Fri',
  DateTime.saturday: 'Sat',
  DateTime.sunday: 'Sun',
};

class Subscription {
  final String id;
  final String customerUsername;
  final Newspaper newspaper;
  final List<int> selectedWeekdays; // values from DateTime.monday..sunday (1-7)
  final int copiesPerDelivery; // how many copies each delivery day
  final String address;
  final DateTime startDate;
  String? assignedDeliveryBoy; // null until admin assigns
  final DateTime createdAt;

  Subscription({
    required this.id,
    required this.customerUsername,
    required this.newspaper,
    required this.selectedWeekdays,
    required this.copiesPerDelivery,
    required this.address,
    required this.startDate,
    this.assignedDeliveryBoy,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  int get frequencyPerWeek => selectedWeekdays.length;

  /// e.g. "Mon, Wed, Fri"
  String get weekdaysLabel {
    final sorted = [...selectedWeekdays]..sort();
    return sorted.map((d) => kWeekdayLabels[d]).join(', ');
  }

  /// Rough monthly estimate: price * copies * deliveries/week * ~4.33 weeks/month
  double get monthlyPrice =>
      newspaper.pricePerCopy * copiesPerDelivery * frequencyPerWeek * 4.33;
}
