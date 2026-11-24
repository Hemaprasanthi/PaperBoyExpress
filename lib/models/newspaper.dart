class Newspaper {
  final String id;
  final String name;
  final double pricePerCopy;

  const Newspaper({
    required this.id,
    required this.name,
    required this.pricePerCopy,
  });

  Map<String, dynamic> toMap() => {'name': name, 'pricePerCopy': pricePerCopy};

  factory Newspaper.fromMap(String id, Map<String, dynamic> map) {
    return Newspaper(
      id: id,
      name: map['name'] as String? ?? id,
      pricePerCopy: (map['pricePerCopy'] as num?)?.toDouble() ?? 0,
    );
  }
}
