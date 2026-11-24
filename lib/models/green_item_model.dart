class GreenItem {
  final String id;
  final String name;
  final Map<String, ZipcodePricing> zipcodePricing;

  GreenItem({
    required this.id,
    required this.name,
    required this.zipcodePricing,
  });

  factory GreenItem.fromFirestore(String id, Map<String, dynamic> data) {
    var rawPricing = data['zipcode_pricing'] as Map<String, dynamic>? ?? {};
    Map<String, ZipcodePricing> pricingMap = {};

    rawPricing.forEach((key, value) {
      pricingMap[key] = ZipcodePricing.fromMap(value as Map<String, dynamic>);
    });

    return GreenItem(
      id: id,
      name: data['name'] ?? '',
      zipcodePricing: pricingMap,
    );
  }
}

class ZipcodePricing {
  final double price;
  final bool available;

  ZipcodePricing({required this.price, required this.available});

  factory ZipcodePricing.fromMap(Map<String, dynamic> map) {
    return ZipcodePricing(
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      available: map['available'] ?? false,
    );
  }
}