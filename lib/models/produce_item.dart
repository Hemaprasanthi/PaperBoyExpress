enum ProduceCategory { greens, vegetables }

extension ProduceCategoryLabel on ProduceCategory {
  String get label => this == ProduceCategory.greens ? 'Greens' : 'Vegetables';
}

/// An item in the greens & vegetables catalog.
class ProduceItem {
  final String id;
  final String name;
  final ProduceCategory category;
  final String unit; // e.g. "bundle", "kg"
  final double price; // per unit
  final bool available;

  const ProduceItem({
    required this.id,
    required this.name,
    required this.category,
    required this.unit,
    required this.price,
    this.available = true,
  });

  Map<String, dynamic> toMap() => {
        'name': name,
        'category': category.name,
        'unit': unit,
        'price': price,
        'available': available,
      };

  factory ProduceItem.fromMap(String id, Map<String, dynamic> map) {
    return ProduceItem(
      id: id,
      name: map['name'] as String? ?? id,
      category: ProduceCategory.values.firstWhere(
        (c) => c.name == map['category'],
        orElse: () => ProduceCategory.vegetables,
      ),
      unit: map['unit'] as String? ?? 'kg',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      available: map['available'] as bool? ?? true,
    );
  }
}
