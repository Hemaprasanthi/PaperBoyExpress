class VeggieItem {
  final String id;
  final String name;
  final double pricePerBundle;

  const VeggieItem({required this.id, required this.name, required this.pricePerBundle});
}

/// Target delivery time for a greens order, counted from the moment it is placed.
const Duration kVeggieDeliveryWindow = Duration(minutes: 15);

/// Placeholder catalog of fresh greens - delivered within
/// [kVeggieDeliveryWindow] of ordering. Available only in the pilot zip code for now.
const List<VeggieItem> kVeggies = [
  VeggieItem(id: 'coriander', name: 'Coriander', pricePerBundle: 15),
  VeggieItem(id: 'spinach', name: 'Spinach', pricePerBundle: 20),
  VeggieItem(id: 'fenugreek', name: 'Fenugreek (Methi)', pricePerBundle: 18),
  VeggieItem(id: 'lettuce', name: 'Lettuce', pricePerBundle: 35),
  VeggieItem(id: 'curry_leaves', name: 'Curry Leaves', pricePerBundle: 10),
  VeggieItem(id: 'mint', name: 'Mint', pricePerBundle: 12),
];

/// Fresh greens delivery is piloted in this zip code only, for now.
const String kVeggiePilotZip = '560102';
