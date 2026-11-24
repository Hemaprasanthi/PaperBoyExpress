class VeggieOrder {
  final String id;
  final String customerUsername;
  final String? customerName;
  final Map<String, int> items; // veggie id -> quantity of bundles
  final double totalAmount;
  final String zipCode;
  final String address;
  final DateTime orderedAt;
  final DateTime expectedDeliveryBy; // orderedAt + 15 minutes
  final DateTime createdAt;

  const VeggieOrder({
    required this.id,
    required this.customerUsername,
    this.customerName,
    required this.items,
    required this.totalAmount,
    required this.zipCode,
    required this.address,
    required this.orderedAt,
    required this.expectedDeliveryBy,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerUsername': customerUsername,
      'customerName': customerName,
      'items': items,
      'totalAmount': totalAmount,
      'zipCode': zipCode,
      'address': address,
      'orderedAt': orderedAt.toIso8601String(),
      'expectedDeliveryBy': expectedDeliveryBy.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory VeggieOrder.fromMap(String id, Map<String, dynamic> map) {
    return VeggieOrder(
      id: id,
      customerUsername: map['customerUsername'] as String,
      customerName: map['customerName'] as String?,
      items: Map<String, int>.from(map['items'] as Map),
      totalAmount: (map['totalAmount'] as num).toDouble(),
      zipCode: map['zipCode'] as String,
      address: map['address'] as String,
      orderedAt: DateTime.parse(map['orderedAt'] as String),
      expectedDeliveryBy: DateTime.parse(map['expectedDeliveryBy'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
