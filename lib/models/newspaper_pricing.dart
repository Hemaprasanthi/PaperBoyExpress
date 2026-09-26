class NewspaperPricing {
  final String newspaperId;
  final double basePrice;
  final Map<String, double> zipOverrides; // zip code -> price per copy

  const NewspaperPricing({
    required this.newspaperId,
    required this.basePrice,
    this.zipOverrides = const {},
  });

  /// The price that actually applies for a given zip code: the zip-specific
  /// override if one's been set, otherwise the base price.
  double priceForZip(String? zip) {
    if (zip != null && zipOverrides.containsKey(zip)) {
      return zipOverrides[zip]!;
    }
    return basePrice;
  }

  Map<String, dynamic> toMap() {
    return {
      'basePrice': basePrice,
      'zipOverrides': zipOverrides,
    };
  }

  factory NewspaperPricing.fromMap(String newspaperId, Map<String, dynamic> map) {
    final rawOverrides = map['zipOverrides'] as Map<String, dynamic>? ?? {};
    return NewspaperPricing(
      newspaperId: newspaperId,
      basePrice: (map['basePrice'] as num).toDouble(),
      zipOverrides: rawOverrides.map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }
}
