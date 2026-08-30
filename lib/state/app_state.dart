import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/newspaper.dart';
import '../models/subscription.dart';
import '../data/mock_data.dart';

class AppState extends ChangeNotifier {
  AppUser? currentUser;

  final List<Newspaper> newspapers = kNewspapers;

  // Only one delivery account for now, but kept as a list so admin UI
  // is ready for more delivery boys later without code changes.
  final List<String> deliveryBoys =
      kUsers.where((u) => u.role == UserRole.delivery).map((u) => u.username).toList();

  final List<Subscription> _subscriptions = [];
  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);

  // ---------- Auth ----------
  String? login(String username, String password) {
    final match = kUsers.where(
      (u) => u.username == username && u.password == password,
    );
    if (match.isEmpty) {
      return 'Invalid username or password';
    }
    currentUser = match.first;
    notifyListeners();
    return null; // no error
  }

  void logout() {
    currentUser = null;
    notifyListeners();
  }

  // ---------- Customer ----------
  Subscription createSubscription({
    required Newspaper newspaper,
    required List<int> selectedWeekdays,
    required int copiesPerDelivery,
    required String address,
    required DateTime startDate,
  }) {
    final sub = Subscription(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      customerUsername: currentUser!.username,
      newspaper: newspaper,
      selectedWeekdays: selectedWeekdays,
      copiesPerDelivery: copiesPerDelivery,
      address: address,
      startDate: startDate,
    );
    _subscriptions.add(sub);
    notifyListeners();
    return sub;
  }

  List<Subscription> subscriptionsForCustomer(String username) =>
      _subscriptions.where((s) => s.customerUsername == username).toList();

  // ---------- Admin ----------
  List<Subscription> get allSubscriptions => subscriptions;

  void assignDelivery(String subscriptionId, String deliveryUsername) {
    final sub = _subscriptions.firstWhere((s) => s.id == subscriptionId);
    sub.assignedDeliveryBoy = deliveryUsername;
    notifyListeners();
  }

  void unassignDelivery(String subscriptionId) {
    final sub = _subscriptions.firstWhere((s) => s.id == subscriptionId);
    sub.assignedDeliveryBoy = null;
    notifyListeners();
  }

  // ---------- Delivery boy ----------
  // Delivery boy should ONLY see newspaper name + address for subscriptions
  // the admin has assigned to him. Screen layer enforces we never show
  // customer identity or price to this role.
  List<Subscription> subscriptionsAssignedTo(String deliveryUsername) =>
      _subscriptions.where((s) => s.assignedDeliveryBoy == deliveryUsername).toList();
}
