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

enum SubscriptionStatus { active, cancelled }

class Subscription {
  final String id;
  final String customerUsername;
  final String? customerName;
  final String? customerPhone;
  final Newspaper newspaper;
  final List<int> selectedWeekdays; // values from DateTime.monday..sunday (1-7)
  final int copiesPerDelivery; // how many copies each delivery day
  final String address;
  final DateTime startDate;
  String? assignedDeliveryBoy; // null until admin assigns
  final DateTime createdAt;
  final SubscriptionStatus status;
  final String? zipCode; // customer's zip at signup, used to look up pricing
  final double pricePerCopyOverride; // price locked in at signup time; -1 means "use newspaper.pricePerCopy" (legacy docs)

  Subscription({
    required this.id,
    required this.customerUsername,
    this.customerName,
    this.customerPhone,
    required this.newspaper,
    required this.selectedWeekdays,
    required this.copiesPerDelivery,
    required this.address,
    required this.startDate,
    this.assignedDeliveryBoy,
    DateTime? createdAt,
    this.status = SubscriptionStatus.active,
    this.zipCode,
    double? pricePerCopyAtSignup,
  })  : createdAt = createdAt ?? DateTime.now(),
        pricePerCopyOverride = pricePerCopyAtSignup ?? -1;

  int get frequencyPerWeek => selectedWeekdays.length;

  /// e.g. "Mon, Wed, Fri"
  String get weekdaysLabel {
    final sorted = [...selectedWeekdays]..sort();
    return sorted.map((d) => kWeekdayLabels[d]).join(', ');
  }

  /// The price per copy actually charged for this subscription - locked in
  /// at signup time so later admin price changes don't retroactively affect
  /// existing subscriptions. Falls back to the newspaper's catalog price for
  /// older subscriptions created before pricing was tracked per-subscription.
  double get effectivePricePerCopy =>
      pricePerCopyOverride >= 0 ? pricePerCopyOverride : newspaper.pricePerCopy;

  /// Rough monthly estimate: price * copies * deliveries/week * ~4.33 weeks/month
  double get monthlyPrice => effectivePricePerCopy * copiesPerDelivery * frequencyPerWeek * 4.33;

  /// Converts this subscription into a Firestore-friendly map.
  /// The newspaper is stored by id and looked back up from the catalog
  /// on read, since the catalog itself isn't stored per-subscription.
  Map<String, dynamic> toMap() {
    return {
      'customerUsername': customerUsername,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'newspaperId': newspaper.id,
      'selectedWeekdays': selectedWeekdays,
      'copiesPerDelivery': copiesPerDelivery,
      'address': address,
      'startDate': startDate.toIso8601String(),
      'assignedDeliveryBoy': assignedDeliveryBoy,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'zipCode': zipCode,
      'pricePerCopyAtSignup': pricePerCopyOverride >= 0 ? pricePerCopyOverride : null,
    };
  }

  /// Rebuilds a Subscription from a Firestore document.
  /// [newspaperLookup] resolves a newspaperId back to a Newspaper object
  /// (pass in the app's newspaper catalog).
  factory Subscription.fromMap(
    String id,
    Map<String, dynamic> map,
    Newspaper Function(String newspaperId) newspaperLookup,
  ) {
    return Subscription(
      id: id,
      customerUsername: map['customerUsername'] as String,
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      newspaper: newspaperLookup(map['newspaperId'] as String),
      selectedWeekdays: List<int>.from(map['selectedWeekdays'] as List),
      copiesPerDelivery: map['copiesPerDelivery'] as int,
      address: map['address'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      assignedDeliveryBoy: map['assignedDeliveryBoy'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: SubscriptionStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'active'),
        orElse: () => SubscriptionStatus.active,
      ),
      zipCode: map['zipCode'] as String?,
      pricePerCopyAtSignup: (map['pricePerCopyAtSignup'] as num?)?.toDouble(),
    );
  }
}

