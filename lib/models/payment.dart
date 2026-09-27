enum PaymentStatus { pending, paid }

class Payment {
  final String id;
  final String subscriptionId;
  final String customerUsername;
  final String newspaperName;
  final int copiesPerDelivery;
  final DateTime periodStart;
  final DateTime periodEnd;
  final double amount;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String method; // e.g. "PhonePe" or "Skipped (Test Mode)"

  const Payment({
    required this.id,
    required this.subscriptionId,
    required this.customerUsername,
    required this.newspaperName,
    required this.copiesPerDelivery,
    required this.periodStart,
    required this.periodEnd,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.paidAt,
    required this.method,
  });

  Map<String, dynamic> toMap() {
    return {
      'subscriptionId': subscriptionId,
      'customerUsername': customerUsername,
      'newspaperName': newspaperName,
      'copiesPerDelivery': copiesPerDelivery,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'amount': amount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'method': method,
    };
  }

  factory Payment.fromMap(String id, Map<String, dynamic> map) {
    return Payment(
      id: id,
      subscriptionId: map['subscriptionId'] as String,
      customerUsername: map['customerUsername'] as String,
      newspaperName: map['newspaperName'] as String,
      copiesPerDelivery: map['copiesPerDelivery'] as int,
      periodStart: DateTime.parse(map['periodStart'] as String),
      periodEnd: DateTime.parse(map['periodEnd'] as String),
      amount: (map['amount'] as num).toDouble(),
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt'] as String) : null,
      method: map['method'] as String? ?? 'PhonePe',
    );
  }
}
