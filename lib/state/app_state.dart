import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/newspaper.dart';
import '../models/subscription.dart';
import '../models/customer_profile.dart';
import '../models/newspaper_pricing.dart';
import '../models/payment.dart';
import '../data/mock_data.dart';

class AppState extends ChangeNotifier {
  AppUser? currentUser;
  CustomerProfile? currentCustomerProfile; // only set when currentUser.role == customer via real signup

  final List<Newspaper> newspapers = kNewspapers;

  final List<String> deliveryBoys =
      kUsers.where((u) => u.role == UserRole.delivery).map((u) => u.username).toList();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CollectionReference<Map<String, dynamic>> _subscriptionsRef =
      FirebaseFirestore.instance.collection('subscriptions');
  final CollectionReference<Map<String, dynamic>> _customersRef =
      FirebaseFirestore.instance.collection('customers');
  final CollectionReference<Map<String, dynamic>> _emailIndexRef =
      FirebaseFirestore.instance.collection('emailIndex');
  final CollectionReference<Map<String, dynamic>> _pricingRef =
      FirebaseFirestore.instance.collection('pricing');
  final CollectionReference<Map<String, dynamic>> _paymentsRef =
      FirebaseFirestore.instance.collection('payments');

  List<Subscription> _subscriptions = [];
  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  bool subscriptionsLoaded = false;

  Map<String, NewspaperPricing> _pricing = {};
  bool pricingLoaded = false;

  List<Payment> _payments = [];
  List<Payment> get payments => List.unmodifiable(_payments);
  bool paymentsLoaded = false;

  AppState() {
    _subscriptionsRef.snapshots().listen((snapshot) {
      _subscriptions = snapshot.docs
          .map((doc) => Subscription.fromMap(doc.id, doc.data(), _newspaperById))
          .toList();
      subscriptionsLoaded = true;
      notifyListeners();
    });

    _pricingRef.snapshots().listen((snapshot) {
      _pricing = {
        for (final doc in snapshot.docs) doc.id: NewspaperPricing.fromMap(doc.id, doc.data()),
      };
      pricingLoaded = true;
      notifyListeners();
    });

    _paymentsRef.snapshots().listen((snapshot) {
      _payments = snapshot.docs.map((doc) => Payment.fromMap(doc.id, doc.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      paymentsLoaded = true;
      notifyListeners();
    });
  }

  Newspaper _newspaperById(String id) {
    return newspapers.firstWhere((n) => n.id == id, orElse: () => newspapers.first);
  }

  // ---------- Pricing ----------

  /// The base price for a newspaper: the admin-set price if one exists,
  /// otherwise the catalog default from mock_data.dart.
  double basePriceFor(String newspaperId) {
    return _pricing[newspaperId]?.basePrice ?? _newspaperById(newspaperId).pricePerCopy;
  }

  /// The price that actually applies for a newspaper at a given zip code -
  /// a zip-specific override if the admin set one, otherwise the base price.
  double priceFor(String newspaperId, {String? zip}) {
    final pricing = _pricing[newspaperId];
    if (pricing != null) return pricing.priceForZip(zip);
    return _newspaperById(newspaperId).pricePerCopy;
  }

  /// Zip overrides currently set for a newspaper, as {zip: price}.
  Map<String, double> zipOverridesFor(String newspaperId) =>
      _pricing[newspaperId]?.zipOverrides ?? {};

  Future<void> setBasePrice(String newspaperId, double price) async {
    await _pricingRef.doc(newspaperId).set({'basePrice': price}, SetOptions(merge: true));
  }

  Future<void> setZipPrice(String newspaperId, String zip, double price) async {
    await _pricingRef.doc(newspaperId).set({
      'basePrice': basePriceFor(newspaperId), // ensure basePrice exists even on first write
      'zipOverrides': {..._pricing[newspaperId]?.zipOverrides ?? {}, zip: price},
    }, SetOptions(merge: true));
  }

  Future<void> removeZipPrice(String newspaperId, String zip) async {
    final updated = {...(_pricing[newspaperId]?.zipOverrides ?? {})}..remove(zip);
    await _pricingRef.doc(newspaperId).set({
      'zipOverrides': updated,
    }, SetOptions(merge: true));
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
    String? zipCode,
    required String paymentMethod, // e.g. "PhonePe" or "Skipped (Test Mode)"
  }) async {
    final effectivePrice = priceFor(newspaper.id, zip: zipCode);
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
      zipCode: zipCode,
      pricePerCopyAtSignup: effectivePrice,
    );

    final amount = effectivePrice * copiesPerDelivery * selectedWeekdays.length * 4.33;
    final periodEnd = DateTime(startDate.year, startDate.month + 1, startDate.day);

    final subRef = _subscriptionsRef.doc();
    final paymentRef = _paymentsRef.doc();
    final now = DateTime.now();

    final payment = Payment(
      id: '',
      subscriptionId: subRef.id,
      customerUsername: currentUser!.username,
      newspaperName: newspaper.name,
      copiesPerDelivery: copiesPerDelivery,
      periodStart: startDate,
      periodEnd: periodEnd,
      amount: amount,
      status: PaymentStatus.paid, // everything is treated as successful for now (test mode)
      createdAt: now,
      paidAt: now,
      method: paymentMethod,
    );

    final batch = _db.batch();
    batch.set(subRef, sub.toMap());
    batch.set(paymentRef, payment.toMap());
    await batch.commit();
  }

  List<Subscription> subscriptionsForCustomer(String username) =>
      _subscriptions.where((s) => s.customerUsername == username).toList();

  List<Payment> paymentsForCustomer(String username) =>
      _payments.where((p) => p.customerUsername == username).toList();

  Future<void> cancelSubscription(String subscriptionId) async {
    await _subscriptionsRef.doc(subscriptionId).update({
      'status': SubscriptionStatus.cancelled.name,
    });
  }

  Future<void> reactivateSubscription(String subscriptionId) async {
    await _subscriptionsRef.doc(subscriptionId).update({
      'status': SubscriptionStatus.active.name,
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

  /// Full admin edit: lets admin change any editable field on a subscription.
  Future<void> adminUpdateSubscription(
    String subscriptionId, {
    required String newspaperId,
    required List<int> selectedWeekdays,
    required int copiesPerDelivery,
    required String address,
    required DateTime startDate,
  }) async {
    await _subscriptionsRef.doc(subscriptionId).update({
      'newspaperId': newspaperId,
      'selectedWeekdays': selectedWeekdays,
      'copiesPerDelivery': copiesPerDelivery,
      'address': address,
      'startDate': startDate.toIso8601String(),
    });
  }

  // ---------- Delivery boy ----------
  // Only active subscriptions are shown - once cancelled, delivery no
  // longer needs to see it on their route.
  List<Subscription> subscriptionsAssignedTo(String deliveryUsername) => _subscriptions
      .where((s) =>
          s.assignedDeliveryBoy == deliveryUsername && s.status == SubscriptionStatus.active)
      .toList();
}
