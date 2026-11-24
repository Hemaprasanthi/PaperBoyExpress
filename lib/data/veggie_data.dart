import '../models/produce_item.dart';

/// Target delivery time for a greens order, counted from the moment it is placed.
const Duration kVeggieDeliveryWindow = Duration(minutes: 15);

/// Fresh greens & vegetable delivery is piloted in this zip code only, for now.
const String kVeggiePilotZip = '560102';

/// Starting catalog, written to Firestore the first time the app runs.
/// After that the admin manages the catalog from the Catalog tab.
const List<ProduceItem> kDefaultProduce = [
  // Greens
  ProduceItem(id: 'coriander', name: 'Coriander', category: ProduceCategory.greens, unit: 'bundle', price: 15),
  ProduceItem(id: 'spinach', name: 'Spinach', category: ProduceCategory.greens, unit: 'bundle', price: 20),
  ProduceItem(id: 'fenugreek', name: 'Fenugreek (Methi)', category: ProduceCategory.greens, unit: 'bundle', price: 18),
  ProduceItem(id: 'lettuce', name: 'Lettuce', category: ProduceCategory.greens, unit: 'bundle', price: 35),
  ProduceItem(id: 'curry_leaves', name: 'Curry Leaves', category: ProduceCategory.greens, unit: 'bundle', price: 10),
  ProduceItem(id: 'mint', name: 'Mint', category: ProduceCategory.greens, unit: 'bundle', price: 12),
  ProduceItem(id: 'amaranth', name: 'Amaranth (Thotakura)', category: ProduceCategory.greens, unit: 'bundle', price: 22),
  ProduceItem(id: 'dill', name: 'Dill (Sabbasige)', category: ProduceCategory.greens, unit: 'bundle', price: 16),
  ProduceItem(id: 'kale', name: 'Kale', category: ProduceCategory.greens, unit: 'bundle', price: 45),
  ProduceItem(id: 'spring_onion', name: 'Spring Onion', category: ProduceCategory.greens, unit: 'bundle', price: 20),
  ProduceItem(id: 'mustard_greens', name: 'Mustard Greens', category: ProduceCategory.greens, unit: 'bundle', price: 25),
  ProduceItem(id: 'sorrel', name: 'Sorrel (Gongura)', category: ProduceCategory.greens, unit: 'bundle', price: 18),
  // Vegetables
  ProduceItem(id: 'tomato', name: 'Tomato', category: ProduceCategory.vegetables, unit: 'kg', price: 40),
  ProduceItem(id: 'onion', name: 'Onion', category: ProduceCategory.vegetables, unit: 'kg', price: 35),
  ProduceItem(id: 'potato', name: 'Potato', category: ProduceCategory.vegetables, unit: 'kg', price: 30),
  ProduceItem(id: 'carrot', name: 'Carrot', category: ProduceCategory.vegetables, unit: 'kg', price: 50),
  ProduceItem(id: 'beans', name: 'French Beans', category: ProduceCategory.vegetables, unit: 'kg', price: 60),
  ProduceItem(id: 'cucumber', name: 'Cucumber', category: ProduceCategory.vegetables, unit: 'kg', price: 30),
  ProduceItem(id: 'brinjal', name: 'Brinjal', category: ProduceCategory.vegetables, unit: 'kg', price: 45),
  ProduceItem(id: 'cauliflower', name: 'Cauliflower', category: ProduceCategory.vegetables, unit: 'piece', price: 40),
  ProduceItem(id: 'cabbage', name: 'Cabbage', category: ProduceCategory.vegetables, unit: 'piece', price: 30),
  ProduceItem(id: 'capsicum', name: 'Capsicum', category: ProduceCategory.vegetables, unit: 'kg', price: 70),
  ProduceItem(id: 'okra', name: 'Okra (Ladies Finger)', category: ProduceCategory.vegetables, unit: 'kg', price: 60),
  ProduceItem(id: 'beetroot', name: 'Beetroot', category: ProduceCategory.vegetables, unit: 'kg', price: 45),
  ProduceItem(id: 'pumpkin', name: 'Pumpkin', category: ProduceCategory.vegetables, unit: 'kg', price: 35),
  ProduceItem(id: 'radish', name: 'Radish', category: ProduceCategory.vegetables, unit: 'kg', price: 30),
  ProduceItem(id: 'green_chilli', name: 'Green Chilli', category: ProduceCategory.vegetables, unit: 'kg', price: 80),
  ProduceItem(id: 'bottle_gourd', name: 'Bottle Gourd', category: ProduceCategory.vegetables, unit: 'piece', price: 35),
  ProduceItem(id: 'ridge_gourd', name: 'Ridge Gourd', category: ProduceCategory.vegetables, unit: 'kg', price: 55),
  ProduceItem(id: 'cluster_beans', name: 'Cluster Beans', category: ProduceCategory.vegetables, unit: 'kg', price: 65),
  ProduceItem(id: 'sweet_potato', name: 'Sweet Potato', category: ProduceCategory.vegetables, unit: 'kg', price: 55),
  ProduceItem(id: 'ginger', name: 'Ginger', category: ProduceCategory.vegetables, unit: 'kg', price: 120),
  ProduceItem(id: 'garlic', name: 'Garlic', category: ProduceCategory.vegetables, unit: 'kg', price: 150),
  ProduceItem(id: 'drumstick', name: 'Drumstick', category: ProduceCategory.vegetables, unit: 'kg', price: 90),
];
