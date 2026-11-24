enum PaymentStatus { pending, paid }

/// A newspaper subscription payment. Once paid it doubles as the receipt.
class Payment {
  final String id;
  final String subscriptionId;
  final String customerUsername;
  final String newspaperName;
  final int copiesPerDelivery;
  final DateTime periodStart;
  final DateTime periodEnd;
  final int? totalDeliveries;
  final double paperCharge;
  final double deliveryCharge;
  final double gstAmount;
  final double totalAmount;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? paidAt;
  final String? method; // "UPI" once paid
  final String? receiptNo;
  final String? transactionRef;

  const Payment({
    required this.id,
    required this.subscriptionId,
    required this.customerUsername,
    required this.newspaperName,
    required this.copiesPerDelivery,
    required this.periodStart,
    required this.periodEnd,
    this.totalDeliveries,
    required this.paperCharge,
    required this.deliveryCharge,
    required this.gstAmount,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    this.paidAt,
    this.method,
    this.receiptNo,
    this.transactionRef,
  });

  Map<String, dynamic> toMap() {
    return {
      'subscriptionId': subscriptionId,
      'customerUsername': customerUsername,
      'newspaperName': newspaperName,
      'copiesPerDelivery': copiesPerDelivery,
      'periodStart': periodStart.toIso8601String(),
      'periodEnd': periodEnd.toIso8601String(),
      'totalDeliveries': totalDeliveries,
      'paperCharge': paperCharge,
      'deliveryCharge': deliveryCharge,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'method': method,
      'receiptNo': receiptNo,
      'transactionRef': transactionRef,
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
      totalDeliveries: map['totalDeliveries'] as int?,
      paperCharge: (map['paperCharge'] as num?)?.toDouble() ?? 0,
      deliveryCharge: (map['deliveryCharge'] as num?)?.toDouble() ?? 0,
      gstAmount: (map['gstAmount'] as num?)?.toDouble() ?? 0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ??
          (map['amount'] as num?)?.toDouble() ?? // fallback for older docs
          0,
      status: PaymentStatus.values.firstWhere(
        (s) => s.name == map['status'],
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: DateTime.parse(map['createdAt'] as String),
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt'] as String) : null,
      method: map['method'] as String?,
      receiptNo: map['receiptNo'] as String?,
      transactionRef: map['transactionRef'] as String?,
    );
  }
}
