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

enum SubscriptionStatus { pendingApproval, active, cancelled }

/// What the customer/admin sees, taking dates and pauses into account.
enum SubscriptionDisplayStatus { pending, active, paused, completed, cancelled }

extension SubscriptionDisplayStatusLabel on SubscriptionDisplayStatus {
  String get label {
    switch (this) {
      case SubscriptionDisplayStatus.pending:
        return 'Pending Approval';
      case SubscriptionDisplayStatus.active:
        return 'Active';
      case SubscriptionDisplayStatus.paused:
        return 'Paused';
      case SubscriptionDisplayStatus.completed:
        return 'Completed';
      case SubscriptionDisplayStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// Longest pause a customer can schedule, counting both the first and last day.
const int kMaxPauseDays = 30;

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Number of days in [start]..[end] (inclusive) that fall on one of [weekdays].
int countDeliveries(DateTime start, DateTime end, Iterable<int> weekdays) {
  final days = weekdays.toSet();
  final last = dateOnly(end);
  var count = 0;
  for (var d = dateOnly(start); !d.isAfter(last); d = DateTime(d.year, d.month, d.day + 1)) {
    if (days.contains(d.weekday)) count++;
  }
  return count;
}

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
  final DateTime? endDate; // null only for older open-ended subscriptions
  String? assignedDeliveryBoy; // null until admin assigns
  final DateTime createdAt;
  final SubscriptionStatus status;
  final String? zipCode; // customer's zip at signup, used to look up pricing
  final double pricePerCopyOverride; // price locked in at signup time; -1 means "use newspaper.pricePerCopy" (legacy docs)
  final double? pendingNewPrice; // legacy: awaiting customer accept/decline
  final DateTime? pausedFrom; // first day with no delivery (date only)
  final DateTime? pausedUntil; // last day with no delivery (date only); delivery resumes the day after

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
    this.endDate,
    this.assignedDeliveryBoy,
    DateTime? createdAt,
    this.status = SubscriptionStatus.pendingApproval,
    this.zipCode,
    double? pricePerCopyAtSignup,
    this.pendingNewPrice,
    this.pausedFrom,
    this.pausedUntil,
  })  : createdAt = createdAt ?? DateTime.now(),
        pricePerCopyOverride = pricePerCopyAtSignup ?? -1;

  int get frequencyPerWeek => selectedWeekdays.length;

  /// Whether deliveries are skipped on [day] because of a pause.
  bool isPausedOn(DateTime day) {
    if (pausedFrom == null || pausedUntil == null) return false;
    final d = dateOnly(day);
    return !d.isBefore(dateOnly(pausedFrom!)) && !d.isAfter(dateOnly(pausedUntil!));
  }

  bool get isPausedNow => isPausedOn(DateTime.now());

  /// True while a pause is running or still scheduled to start; false once it has ended.
  bool get hasPauseScheduledOrActive =>
      pausedUntil != null && !dateOnly(DateTime.now()).isAfter(dateOnly(pausedUntil!));

  bool get isExpired => endDate != null && dateOnly(DateTime.now()).isAfter(dateOnly(endDate!));

  /// Whether a paper should be delivered on [day].
  bool isDeliveryDay(DateTime day) {
    if (status != SubscriptionStatus.active) return false;
    if (!selectedWeekdays.contains(day.weekday)) return false;
    final d = dateOnly(day);
    if (d.isBefore(dateOnly(startDate))) return false;
    if (endDate != null && d.isAfter(dateOnly(endDate!))) return false;
    return !isPausedOn(day);
  }

  SubscriptionDisplayStatus get displayStatus {
    switch (status) {
      case SubscriptionStatus.pendingApproval:
        return SubscriptionDisplayStatus.pending;
      case SubscriptionStatus.cancelled:
        return SubscriptionDisplayStatus.cancelled;
      case SubscriptionStatus.active:
        if (isExpired) return SubscriptionDisplayStatus.completed;
        if (isPausedNow) return SubscriptionDisplayStatus.paused;
        return SubscriptionDisplayStatus.active;
    }
  }

  /// "Mon, Wed, Fri"
  String get weekdaysLabel {
    final sorted = [...selectedWeekdays]..sort();
    return sorted.map((d) => kWeekdayLabels[d]).join(', ');
  }

  /// The price per copy actually charged for this subscription - locked in
  /// at signup time so later admin price changes don't affect it. Falls back to
  /// the newspaper's catalog price for older subscriptions.
  double get effectivePricePerCopy =>
      pricePerCopyOverride >= 0 ? pricePerCopyOverride : newspaper.pricePerCopy;

  int get totalDeliveries =>
      endDate == null ? 0 : countDeliveries(startDate, endDate!, selectedWeekdays);

  /// Rough monthly estimate for paper charges, used for open-ended (older) subscriptions.
  double get monthlyPrice => effectivePricePerCopy * copiesPerDelivery * frequencyPerWeek * 4.33;

  /// Paper charges for the whole prepaid period (or a monthly estimate for older subscriptions).
  double get periodPrice => endDate == null
      ? monthlyPrice
      : effectivePricePerCopy * copiesPerDelivery * totalDeliveries;

  String get periodPriceSuffix => endDate == null ? '/mo' : ' total';

  Map<String, dynamic> toMap() {
    return {
      'customerUsername': customerUsername,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'newspaperId': newspaper.id,
      'newspaperName': newspaper.name,
      'selectedWeekdays': selectedWeekdays,
      'copiesPerDelivery': copiesPerDelivery,
      'address': address,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'assignedDeliveryBoy': assignedDeliveryBoy,
      'createdAt': createdAt.toIso8601String(),
      'status': status.name,
      'zipCode': zipCode,
      'pricePerCopyAtSignup': pricePerCopyOverride >= 0 ? pricePerCopyOverride : null,
      'pendingNewPrice': pendingNewPrice,
      'pausedFrom': pausedFrom?.toIso8601String(),
      'pausedUntil': pausedUntil?.toIso8601String(),
    };
  }

  /// [newspaperLookup] resolves a newspaperId (and the name stored with the
  /// subscription) back to a Newspaper from the live catalog.
  factory Subscription.fromMap(
    String id,
    Map<String, dynamic> map,
    Newspaper Function(String newspaperId, String? storedName) newspaperLookup,
  ) {
    return Subscription(
      id: id,
      customerUsername: map['customerUsername'] as String,
      customerName: map['customerName'] as String?,
      customerPhone: map['customerPhone'] as String?,
      newspaper: newspaperLookup(map['newspaperId'] as String, map['newspaperName'] as String?),
      selectedWeekdays: List<int>.from(map['selectedWeekdays'] as List),
      copiesPerDelivery: map['copiesPerDelivery'] as int,
      address: map['address'] as String,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null ? DateTime.parse(map['endDate'] as String) : null,
      assignedDeliveryBoy: map['assignedDeliveryBoy'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      status: SubscriptionStatus.values.firstWhere(
        (s) => s.name == (map['status'] as String? ?? 'active'),
        orElse: () => SubscriptionStatus.active,
      ),
      zipCode: map['zipCode'] as String?,
      pricePerCopyAtSignup: (map['pricePerCopyAtSignup'] as num?)?.toDouble(),
      pendingNewPrice: (map['pendingNewPrice'] as num?)?.toDouble(),
      pausedFrom: map['pausedFrom'] != null ? DateTime.parse(map['pausedFrom'] as String) : null,
      pausedUntil: map['pausedUntil'] != null ? DateTime.parse(map['pausedUntil'] as String) : null,
    );
  }
}
