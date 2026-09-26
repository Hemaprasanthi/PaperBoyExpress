import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/newspaper.dart';
import '../models/subscription.dart';
import '../models/customer_profile.dart';
import '../data/mock_data.dart';

class AppState extends ChangeNotifier {
  AppUser? currentUser;
  CustomerProfile? currentCustomerProfile; // only set when currentUser.role == customer via real signup

  final List<Newspaper> newspapers = kNewspapers;

  final List<String> deliveryBoys =
      kUsers.where((u) => u.role == UserRole.delivery).map((u) => u.username).toList();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CollectionReference<Map<String, dynamic>> _subscriptionsRef =
      FirebaseFirestore.instance.collection('subscriptions');
  final CollectionReference<Map<String, dynamic>> _customersRef =
      FirebaseFirestore.instance.collection('customers');
  final CollectionReference<Map<String, dynamic>> _emailIndexRef =
      FirebaseFirestore.instance.collection('emailIndex');

  List<Subscription> _subscriptions = [];
  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  bool subscriptionsLoaded = false;

  AppState() {
    _subscriptionsRef.snapshots().listen((snapshot) {
      _subscriptions = snapshot.docs
          .map((doc) => Subscription.fromMap(doc.id, doc.data(), _newspaperById))
          .toList();
      subscriptionsLoaded = true;
      notifyListeners();
    });
  }

  Newspaper _newspaperById(String id) {
    return newspapers.firstWhere((n) => n.id == id, orElse: () => newspapers.first);
  }

  // ---------- Auth: demo admin/delivery + real customer accounts ----------

  /// [identifier] can be: the demo usernames ("admin", "delivery", "customer"),
  /// a real customer's phone number, or a real customer's email (if they set one).
  Future<String?> login(String identifier, String password) async {
    final trimmed = identifier.trim();

    // 1. Check the 3 hardcoded demo accounts first.
    final demoMatch = kUsers.where(
      (u) => u.username == trimmed && u.password == password,
    );
    if (demoMatch.isNotEmpty) {
      currentUser = demoMatch.first;
      currentCustomerProfile = null;
      notifyListeners();
      return null;
    }

    // 2. Otherwise, treat it as a real customer login (email or phone).
    String authEmail;
    if (trimmed.contains('@') && !trimmed.endsWith('@customers.paperboyexpress.app')) {
      // Looks like a real email - resolve it to the phone-based auth email.
      final indexDoc = await _emailIndexRef.doc(trimmed.toLowerCase()).get();
      if (!indexDoc.exists) {
        return 'No account found with that email';
      }
      final phone = indexDoc.data()!['phone'] as String;
      authEmail = authEmailForPhone(phone);
    } else {
      // Treat as a phone number.
      authEmail = authEmailForPhone(trimmed);
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: authEmail,
        password: password,
      );
      final uid = credential.user!.uid;
      final profileDoc = await _customersRef.doc(uid).get();
      if (!profileDoc.exists) {
        return 'Account found but profile is missing. Please contact support.';
      }
      currentCustomerProfile = CustomerProfile.fromMap(uid, profileDoc.data()!);
      currentUser = AppUser(username: uid, password: '', role: UserRole.customer);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
          return 'Invalid phone/email or password';
        default:
          return e.message ?? 'Sign-in failed';
      }
    }
  }

  /// Creates a real customer account. Phone is required; email is optional
  /// and, if given, is stored purely as an alternate lookup for sign-in.
  Future<String?> signUp({
    required String name,
    required String address,
    required String phone,
    String? email,
    required String password,
  }) async {
    final authEmail = authEmailForPhone(phone);
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: authEmail,
        password: password,
      );
      final uid = credential.user!.uid;

      final profile = CustomerProfile(
        uid: uid,
        name: name.trim(),
        address: address.trim(),
        phone: phone.trim(),
        email: (email == null || email.trim().isEmpty) ? null : email.trim(),
      );
      await _customersRef.doc(uid).set(profile.toMap());

      if (profile.email != null) {
        await _emailIndexRef.doc(profile.email!.toLowerCase()).set({'phone': profile.phone});
      }

      currentCustomerProfile = profile;
      currentUser = AppUser(username: uid, password: '', role: UserRole.customer);
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'An account with this phone number already exists';
        case 'weak-password':
          return 'Password is too weak (use at least 6 characters)';
        default:
          return e.message ?? 'Sign-up failed';
      }
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    currentUser = null;
    currentCustomerProfile = null;
    notifyListeners();
  }

  // ---------- Customer ----------
  Future<void> createSubscription({
    required Newspaper newspaper,
    required List<int> selectedWeekdays,
    required int copiesPerDelivery,
    required String address,
    required DateTime startDate,
  }) async {
    final sub = Subscription(
      id: '',
      customerUsername: currentUser!.username,
      customerName: currentCustomerProfile?.name,
      customerPhone: currentCustomerProfile?.phone,
      newspaper: newspaper,
      selectedWeekdays: selectedWeekdays,
      copiesPerDelivery: copiesPerDelivery,
      address: address,
      startDate: startDate,
    );
    await _subscriptionsRef.add(sub.toMap());
  }

  List<Subscription> subscriptionsForCustomer(String username) =>
      _subscriptions.where((s) => s.customerUsername == username).toList();

  Future<void> cancelSubscription(String subscriptionId) async {
    await _subscriptionsRef.doc(subscriptionId).update({
      'status': SubscriptionStatus.cancelled.name,
    });
  }

  // ---------- Admin ----------
  List<Subscription> get allSubscriptions => subscriptions;

  Future<void> assignDelivery(String subscriptionId, String deliveryUsername) async {
    await _subscriptionsRef.doc(subscriptionId).update({'assignedDeliveryBoy': deliveryUsername});
  }

  Future<void> unassignDelivery(String subscriptionId) async {
    await _subscriptionsRef.doc(subscriptionId).update({'assignedDeliveryBoy': null});
  }

  // ---------- Delivery boy ----------
  // Only active subscriptions are shown - once cancelled, delivery no
  // longer needs to see it on their route.
  List<Subscription> subscriptionsAssignedTo(String deliveryUsername) => _subscriptions
      .where((s) =>
          s.assignedDeliveryBoy == deliveryUsername && s.status == SubscriptionStatus.active)
      .toList();
}
