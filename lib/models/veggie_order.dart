class VeggieOrderLine {
  final String id;
  final String name;
  final String unit;
  final double unitPrice;
  final int quantity;

  const VeggieOrderLine({
    required this.id,
    required this.name,
    required this.unit,
    required this.unitPrice,
    required this.quantity,
  });

  double get total => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'unit': unit,
        'unitPrice': unitPrice,
        'quantity': quantity,
      };

  factory VeggieOrderLine.fromMap(Map<String, dynamic> map) {
    return VeggieOrderLine(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      unit: map['unit'] as String? ?? '',
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
    );
  }
}

/// A greens & vegetables order. It is only created once the UPI payment succeeds,
/// so it also serves as the receipt.
class VeggieOrder {
  final String id;
  final String customerUsername;
  final String? customerName;
  final List<VeggieOrderLine> lines;
  final double totalAmount;
  final String zipCode;
  final String address;
  final DateTime orderedAt;
  final DateTime expectedDeliveryBy; // orderedAt + 15 minutes
  final DateTime createdAt;
  final String? assignedDeliveryBoy;
  final DateTime? paidAt;
  final String? paymentMethod;
  final String? receiptNo;
  final String? transactionRef;

  const VeggieOrder({
    required this.id,
    required this.customerUsername,
    this.customerName,
    required this.lines,
    required this.totalAmount,
    required this.zipCode,
    required this.address,
    required this.orderedAt,
    required this.expectedDeliveryBy,
    required this.createdAt,
    this.assignedDeliveryBoy,
    this.paidAt,
    this.paymentMethod,
    this.receiptNo,
    this.transactionRef,
  });

  String get itemsSummary => lines.map((l) => '${l.name} x${l.quantity}').join(', ');

  Map<String, dynamic> toMap() {
    return {
      'customerUsername': customerUsername,
      'customerName': customerName,
      'items': lines.map((l) => l.toMap()).toList(),
      'totalAmount': totalAmount,
      'zipCode': zipCode,
      'address': address,
      'orderedAt': orderedAt.toIso8601String(),
      'expectedDeliveryBy': expectedDeliveryBy.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'assignedDeliveryBoy': assignedDeliveryBoy,
      'paidAt': paidAt?.toIso8601String(),
      'paymentMethod': paymentMethod,
      'receiptNo': receiptNo,
      'transactionRef': transactionRef,
    };
  }

  factory VeggieOrder.fromMap(String id, Map<String, dynamic> map) {
    final rawItems = map['items'];
    final List<VeggieOrderLine> lines;
    if (rawItems is List) {
      lines = rawItems
          .map((e) => VeggieOrderLine.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } else if (rawItems is Map) {
      // Older orders stored only {itemId: quantity}.
      lines = rawItems.entries
          .map((e) => VeggieOrderLine(
                id: e.key as String,
                name: (e.key as String).replaceAll('_', ' '),
                unit: '',
                unitPrice: 0,
                quantity: (e.value as num).toInt(),
              ))
          .toList();
    } else {
      lines = const [];
    }

    return VeggieOrder(
      id: id,
      customerUsername: map['customerUsername'] as String,
      customerName: map['customerName'] as String?,
      lines: lines,
      totalAmount: (map['totalAmount'] as num).toDouble(),
      zipCode: map['zipCode'] as String,
      address: map['address'] as String,
      orderedAt: DateTime.parse(map['orderedAt'] as String),
      expectedDeliveryBy: DateTime.parse(map['expectedDeliveryBy'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      assignedDeliveryBoy: map['assignedDeliveryBoy'] as String?,
      paidAt: map['paidAt'] != null ? DateTime.parse(map['paidAt'] as String) : null,
      paymentMethod: map['paymentMethod'] as String?,
      receiptNo: map['receiptNo'] as String?,
      transactionRef: map['transactionRef'] as String?,
    );
  }
}
