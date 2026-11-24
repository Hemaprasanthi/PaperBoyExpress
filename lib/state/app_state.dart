import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/newspaper.dart';
import '../models/subscription.dart';
import '../models/customer_profile.dart';
import '../models/newspaper_pricing.dart';
import '../models/payment.dart';
import '../models/app_notification.dart';
import '../models/veggie_order.dart';
import '../models/produce_item.dart';
import '../models/issue.dart';
import '../data/mock_data.dart';
import '../data/veggie_data.dart';
import '../utils/app_constants.dart';

typedef SubscriptionQuote = ({
  int deliveries,
  double paper,
  double delivery,
  double gst,
  double total,
});

double _round2(double v) => (v * 100).roundToDouble() / 100;

class AppState extends ChangeNotifier {
  AppUser? currentUser;
  CustomerProfile? currentCustomerProfile; // set for real customer accounts and the demo customer

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
  final CollectionReference<Map<String, dynamic>> _phoneIndexRef =
      FirebaseFirestore.instance.collection('phoneIndex');
  final CollectionReference<Map<String, dynamic>> _pricingRef =
      FirebaseFirestore.instance.collection('pricing');
  final CollectionReference<Map<String, dynamic>> _paymentsRef =
      FirebaseFirestore.instance.collection('payments');
  final CollectionReference<Map<String, dynamic>> _deliveryChargesRef =
      FirebaseFirestore.instance.collection('deliveryCharges');
  final CollectionReference<Map<String, dynamic>> _settingsRef =
      FirebaseFirestore.instance.collection('settings');
  final CollectionReference<Map<String, dynamic>> _notificationsRef =
      FirebaseFirestore.instance.collection('notifications');
  final CollectionReference<Map<String, dynamic>> _veggieOrdersRef =
      FirebaseFirestore.instance.collection('veggieOrders');
  final CollectionReference<Map<String, dynamic>> _newspapersRef =
      FirebaseFirestore.instance.collection('newspapers');
  final CollectionReference<Map<String, dynamic>> _produceRef =
      FirebaseFirestore.instance.collection('produce');
  final CollectionReference<Map<String, dynamic>> _issuesRef =
      FirebaseFirestore.instance.collection('issues');

  DocumentReference<Map<String, dynamic>> get _gstSettingRef => _settingsRef.doc('gst');

  List<QueryDocumentSnapshot<Map<String, dynamic>>> _rawSubscriptions = [];
  List<Subscription> _subscriptions = [];
  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  bool subscriptionsLoaded = false;

  List<Newspaper> _newspapers = [];
  List<Newspaper> get newspapers => List.unmodifiable(_newspapers);
  bool newspapersLoaded = false;

  List<ProduceItem> _produce = [];
  List<ProduceItem> get produce => List.unmodifiable(_produce);
  bool produceLoaded = false;

  Map<String, NewspaperPricing> _pricing = {};
  bool pricingLoaded = false;

  List<Payment> _payments = [];
  List<Payment> get payments => List.unmodifiable(_payments);
  bool paymentsLoaded = false;

  Map<String, double> _deliveryCharges = {}; // zip -> charge
  double gstPercent = 18.0;

  List<AppNotification> _notifications = [];
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  List<VeggieOrder> _veggieOrders = [];
  List<VeggieOrder> get veggieOrders => List.unmodifiable(_veggieOrders);

  List<CustomerProfile> _customers = [];
  List<CustomerProfile> get customers => List.unmodifiable(_customers);

  List<Issue> _issues = [];
  List<Issue> get issues => List.unmodifiable(_issues);

  AppState() {
    _listen(_subscriptionsRef, (snapshot) {
      _rawSubscriptions = snapshot.docs;
      _rebuildSubscriptions();
      subscriptionsLoaded = true;
      notifyListeners();
    });

    _listen(_newspapersRef, (snapshot) {
      _newspapers = snapshot.docs.map((doc) => Newspaper.fromMap(doc.id, doc.data())).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      newspapersLoaded = true;
      _rebuildSubscriptions();
      notifyListeners();
    });

    _listen(_produceRef, (snapshot) {
      _produce = snapshot.docs.map((doc) => ProduceItem.fromMap(doc.id, doc.data())).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      produceLoaded = true;
      notifyListeners();
    });

    _listen(_pricingRef, (snapshot) {
      _pricing = {
        for (final doc in snapshot.docs) doc.id: NewspaperPricing.fromMap(doc.id, doc.data()),
      };
      pricingLoaded = true;
      notifyListeners();
    });

    _listen(_paymentsRef, (snapshot) {
      _payments = snapshot.docs.map((doc) => Payment.fromMap(doc.id, doc.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      paymentsLoaded = true;
      notifyListeners();
    });

    _listen(_deliveryChargesRef, (snapshot) {
      _deliveryCharges = {
        for (final doc in snapshot.docs) doc.id: (doc.data()['charge'] as num).toDouble(),
      };
      notifyListeners();
    });

    _gstSettingRef.snapshots().listen((doc) {
      if (doc.exists && doc.data()!['percent'] != null) {
        gstPercent = (doc.data()!['percent'] as num).toDouble();
        notifyListeners();
      }
    }, onError: (Object e) => debugPrint('Firestore listen error: $e'));

    _listen(_notificationsRef, (snapshot) {
      _notifications = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    });

    _listen(_veggieOrdersRef, (snapshot) {
      _veggieOrders = snapshot.docs.map((doc) => VeggieOrder.fromMap(doc.id, doc.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    });

    _listen(_customersRef, (snapshot) {
      _customers = snapshot.docs.map((doc) => CustomerProfile.fromMap(doc.id, doc.data())).toList()
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      notifyListeners();
    });

    _listen(_issuesRef, (snapshot) {
      _issues = snapshot.docs.map((doc) => Issue.fromMap(doc.id, doc.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    });

    _seedCatalogIfNeeded();
  }

  void _listen(
    Query<Map<String, dynamic>> query,
    void Function(QuerySnapshot<Map<String, dynamic>>) onData,
  ) {
    query.snapshots().listen(onData, onError: (Object e) => debugPrint('Firestore listen error: $e'));
  }

  void _rebuildSubscriptions() {
    _subscriptions = _rawSubscriptions
        .map((doc) => Subscription.fromMap(doc.id, doc.data(), _newspaperById))
        .toList();
  }

  /// Writes the default newspapers and produce to Firestore the first time the
  /// app runs, so the admin has a catalog to manage.
  Future<void> _seedCatalogIfNeeded() async {
    try {
      final flag = _settingsRef.doc('catalog');
      if ((await flag.get()).exists) return;
      final batch = _db.batch();
      for (final n in kNewspapers) {
        batch.set(_newspapersRef.doc(n.id), n.toMap());
      }
      for (final p in kDefaultProduce) {
        batch.set(_produceRef.doc(p.id), p.toMap());
      }
      batch.set(flag, {'seededAt': DateTime.now().toIso8601String()});
      await batch.commit();
    } catch (e) {
      debugPrint('Catalog seeding failed: $e');
    }
  }

  /// Looks a newspaper up in the live catalog. If it has since been deleted,
  /// returns a stand-in that keeps the name stored with the subscription.
  Newspaper _newspaperById(String id, [String? storedName]) {
    for (final n in _newspapers) {
      if (n.id == id) return n;
    }
    return Newspaper(id: id, name: storedName ?? 'Discontinued newspaper', pricePerCopy: 0);
  }

  // ---------- Catalog: newspapers (admin) ----------

  Future<void> addNewspaper(String name, double price) async {
    await _newspapersRef.add({'name': name.trim(), 'pricePerCopy': price});
  }

  Future<void> updateNewspaper(String id, {required String name, required double price}) async {
    await _newspapersRef.doc(id).update({'name': name.trim()});
    if (price != basePriceFor(id)) await setBasePrice(id, price);
  }

  /// Existing subscriptions keep working: they store the newspaper's name and locked price.
  Future<void> deleteNewspaper(String id) async {
    await _newspapersRef.doc(id).delete();
    await _pricingRef.doc(id).delete();
  }

  // ---------- Catalog: greens & vegetables (admin) ----------

  Future<void> addProduce(ProduceItem item) async {
    await _produceRef.add(item.toMap());
  }

  Future<void> updateProduce(ProduceItem item) async {
    await _produceRef.doc(item.id).set(item.toMap());
  }

  Future<void> deleteProduce(String id) async {
    await _produceRef.doc(id).delete();
  }

  // ---------- Pricing ----------

  /// The base price for a newspaper: the admin-set price if one exists,
  /// otherwise the catalog price.
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

  double deliveryChargeForZip(String? zip) {
    if (zip == null) return 0;
    return _deliveryCharges[zip] ?? 0;
  }

  Map<String, double> get allDeliveryCharges => Map.unmodifiable(_deliveryCharges);

  Future<void> setDeliveryCharge(String zip, double charge) async {
    await _deliveryChargesRef.doc(zip).set({'charge': charge});
  }

  Future<void> removeDeliveryCharge(String zip) async {
    await _deliveryChargesRef.doc(zip).delete();
  }

  Future<void> setGstPercent(double percent) async {
    await _gstSettingRef.set({'percent': percent});
  }

  /// Subscriptions are prepaid at a locked-in price, so a price change only
  /// applies to subscriptions bought afterwards.
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

  // ---------- Auth: demo admin/delivery/customer + real customer accounts ----------

  /// True for the hardcoded demo logins (real accounts are created with an empty password).
  bool get isDemoAccount => currentUser != null && currentUser!.password.isNotEmpty;

  /// Looks up the internal sign-in email for a phone number, which stays the
  /// same even after the customer changes their phone.
  Future<String> _authEmailForPhone(String phone) async {
    try {
      final doc = await _phoneIndexRef.doc(digitsOnly(phone)).get();
      final email = doc.data()?['authEmail'] as String?;
      if (email != null) return email;
    } catch (e) {
      debugPrint('Phone index lookup failed: $e');
    }
    return authEmailForPhone(phone);
  }

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
      // The demo customer gets a profile in the greens pilot zip so greens are visible.
      currentCustomerProfile = currentUser!.role == UserRole.customer
          ? const CustomerProfile(
              uid: 'customer',
              name: 'Demo Customer',
              address: '12, Demo Street, Bengaluru',
              zipCode: kVeggiePilotZip,
              phone: '0000000000',
            )
          : null;
      notifyListeners();
      return null;
    }

    // 2. Otherwise, treat it as a real customer login (email or phone).
    String authEmail;
    if (trimmed.contains('@') && !trimmed.endsWith('@customers.paperboyexpress.app')) {
      final indexDoc = await _emailIndexRef.doc(trimmed.toLowerCase()).get();
      if (!indexDoc.exists) {
        return 'No account found with that email';
      }
      authEmail = await _authEmailForPhone(indexDoc.data()!['phone'] as String);
    } else {
      authEmail = await _authEmailForPhone(trimmed);
    }

    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: authEmail,
        password: password,
      );
      final uid = credential.user!.uid;
      final profileDoc = await _customersRef.doc(uid).get();
      if (!profileDoc.exists) {
        await _auth.signOut();
        return 'This account is no longer available. Please contact support.';
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
    required String zipCode,
    required String phone,
    String? email,
    required String password,
  }) async {
    final authEmail = authEmailForPhone(phone);
    final phoneKey = digitsOnly(phone);
    try {
      if ((await _phoneIndexRef.doc(phoneKey).get()).exists) {
        return 'An account with this phone number already exists';
      }
    } catch (e) {
      debugPrint('Phone index check failed: $e');
    }

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
        zipCode: zipCode.trim(),
        phone: phone.trim(),
        email: (email == null || email.trim().isEmpty) ? null : email.trim(),
        authEmail: authEmail,
      );
      await _customersRef.doc(uid).set(profile.toMap());
      await _phoneIndexRef.doc(phoneKey).set({'authEmail': authEmail, 'uid': uid});

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

  // ---------- Customer accounts: edit & delete ----------

  /// Updates a customer's details. Used by customers (their own account) and by
  /// the admin. Changing the phone number only changes how they sign in - the
  /// underlying login email stays the same.
  Future<String?> updateCustomerProfile(
    String uid, {
    required String name,
    required String address,
    required String zipCode,
    required String phone,
  }) async {
    final doc = await _customersRef.doc(uid).get();
    if (!doc.exists) return 'Account not found';
    final old = CustomerProfile.fromMap(uid, doc.data()!);

    final newPhone = phone.trim();
    final oldKey = digitsOnly(old.phone);
    final newKey = digitsOnly(newPhone);
    final phoneChanged = newKey != oldKey;

    if (phoneChanged) {
      if (newKey.length < 7) return 'Enter a valid phone number';
      final indexDoc = await _phoneIndexRef.doc(newKey).get();
      final clash = await _customersRef.where('phone', isEqualTo: newPhone).limit(2).get();
      if (indexDoc.exists || clash.docs.any((d) => d.id != uid)) {
        return 'That phone number is already registered';
      }
    }

    final updated = CustomerProfile(
      uid: uid,
      name: name.trim(),
      address: address.trim(),
      zipCode: zipCode.trim(),
      phone: newPhone,
      email: old.email,
      authEmail: old.loginEmail,
    );

    final batch = _db.batch();
    batch.set(_customersRef.doc(uid), updated.toMap());
    if (phoneChanged) {
      batch.set(_phoneIndexRef.doc(newKey), {'authEmail': updated.loginEmail, 'uid': uid});
      batch.delete(_phoneIndexRef.doc(oldKey));
      if (old.email != null) {
        batch.set(_emailIndexRef.doc(old.email!.toLowerCase()), {'phone': newPhone});
      }
    }
    final subs = await _subscriptionsRef.where('customerUsername', isEqualTo: uid).get();
    for (final s in subs.docs) {
      batch.update(s.reference, {'customerName': updated.name, 'customerPhone': updated.phone});
    }
    final orders = await _veggieOrdersRef.where('customerUsername', isEqualTo: uid).get();
    for (final o in orders.docs) {
      batch.update(o.reference, {'customerName': updated.name});
    }
    await batch.commit();

    if (currentCustomerProfile?.uid == uid) {
      currentCustomerProfile = updated;
    }
    notifyListeners();
    return null;
  }

  /// Removes everything stored about a customer in Firestore.
  Future<void> _deleteCustomerData(String uid) async {
    final profileDoc = await _customersRef.doc(uid).get();
    final refs = <DocumentReference>[];
    for (final col in [_subscriptionsRef, _paymentsRef, _notificationsRef, _veggieOrdersRef]) {
      final snap = await col.where('customerUsername', isEqualTo: uid).get();
      refs.addAll(snap.docs.map((d) => d.reference));
    }
    if (profileDoc.exists) {
      final p = CustomerProfile.fromMap(uid, profileDoc.data()!);
      refs.add(_phoneIndexRef.doc(digitsOnly(p.phone)));
      if (p.email != null) refs.add(_emailIndexRef.doc(p.email!.toLowerCase()));
      refs.add(profileDoc.reference);
    }
    for (var i = 0; i < refs.length; i += 400) {
      final batch = _db.batch();
      for (final r in refs.skip(i).take(400)) {
        batch.delete(r);
      }
      await batch.commit();
    }
  }

  /// Deletes the signed-in customer's account after re-checking their password.
  Future<String?> deleteMyAccount(String password) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) return 'You are not signed in';
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        return 'Incorrect password';
      }
      return e.message ?? 'Could not verify your password';
    }

    try {
      await _deleteCustomerData(user.uid);
      await user.delete();
    } on FirebaseException catch (e) {
      return e.message ?? 'Could not delete the account';
    }
    currentUser = null;
    currentCustomerProfile = null;
    notifyListeners();
    return null;
  }

  /// Admin: removes a customer's data and blocks them from signing in. The
  /// Firebase Auth record itself can only be removed from a server, so it
  /// stays, but sign-in is refused once the profile is gone.
  Future<void> adminDeleteCustomer(String uid) async {
    await _deleteCustomerData(uid);
  }

  // ---------- Customer: subscribing (prepaid via UPI) ----------

  SubscriptionQuote quoteSubscription({
    required String newspaperId,
    required List<int> weekdays,
    required int copies,
    required DateTime startDate,
    required DateTime endDate,
    String? zip,
  }) {
    final deliveries = countDeliveries(startDate, endDate, weekdays);
    final paper = _round2(priceFor(newspaperId, zip: zip) * copies * deliveries);
    final delivery = deliveryChargeForZip(zip);
    final gst = _round2((paper + delivery) * (gstPercent / 100));
    return (
      deliveries: deliveries,
      paper: paper,
      delivery: delivery,
      gst: gst,
      total: _round2(paper + delivery + gst),
    );
  }

  String _newReceiptNo(String prefix) => 'PBX-$prefix-${DateTime.now().millisecondsSinceEpoch}';

  /// Called once the UPI payment has been confirmed. Creates an active
  /// subscription and its paid receipt together. Returns an error message, or null.
  Future<String?> createSubscription({
    required Newspaper newspaper,
    required List<int> selectedWeekdays,
    required int copiesPerDelivery,
    required String address,
    required DateTime startDate,
    required DateTime endDate,
    required String transactionRef,
    String? zipCode,
  }) async {
    final today = dateOnly(DateTime.now());
    final start = dateOnly(startDate);
    final end = dateOnly(endDate);
    if (!start.isAfter(today)) return 'The start date must be after today';
    if (end.isBefore(start)) return 'The end date can\'t be before the start date';
    if (countDeliveries(start, end, selectedWeekdays) == 0) {
      return 'None of the selected days fall between the start and end date';
    }

    final quote = quoteSubscription(
      newspaperId: newspaper.id,
      weekdays: selectedWeekdays,
      copies: copiesPerDelivery,
      startDate: start,
      endDate: end,
      zip: zipCode,
    );
    final effectivePrice = priceFor(newspaper.id, zip: zipCode);
    final now = DateTime.now();

    final sub = Subscription(
      id: '',
      customerUsername: currentUser!.username,
      customerName: currentCustomerProfile?.name,
      customerPhone: currentCustomerProfile?.phone,
      newspaper: newspaper,
      selectedWeekdays: selectedWeekdays,
      copiesPerDelivery: copiesPerDelivery,
      address: address,
      startDate: start,
      endDate: end,
      zipCode: zipCode,
      pricePerCopyAtSignup: effectivePrice,
      status: SubscriptionStatus.active, // paid up front, so it needs no approval
    );

    final subRef = _subscriptionsRef.doc();
    final paymentRef = _paymentsRef.doc();
    final payment = Payment(
      id: '',
      subscriptionId: subRef.id,
      customerUsername: currentUser!.username,
      newspaperName: newspaper.name,
      copiesPerDelivery: copiesPerDelivery,
      periodStart: start,
      periodEnd: end,
      totalDeliveries: quote.deliveries,
      paperCharge: quote.paper,
      deliveryCharge: quote.delivery,
      gstAmount: quote.gst,
      totalAmount: quote.total,
      status: PaymentStatus.paid,
      createdAt: now,
      paidAt: now,
      method: 'UPI',
      receiptNo: _newReceiptNo('NEWS'),
      transactionRef: transactionRef,
    );

    final batch = _db.batch();
    batch.set(subRef, sub.toMap());
    batch.set(paymentRef, payment.toMap());
    await batch.commit();
    return null;
  }

  List<Subscription> subscriptionsForCustomer(String username) =>
      _subscriptions.where((s) => s.customerUsername == username).toList();

  /// Paid newspaper receipts for a customer, newest first.
  List<Payment> receiptsForCustomer(String username) => _payments
      .where((p) => p.customerUsername == username && p.status == PaymentStatus.paid)
      .toList();

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

  /// Pauses deliveries from [from] through [until] (both inclusive). The pause
  /// can't start in the past, last longer than [kMaxPauseDays], or run past the
  /// subscription's end date. Delivery resumes automatically the day after [until].
  Future<String?> pauseSubscription(String subscriptionId, DateTime from, DateTime until) async {
    final start = dateOnly(from);
    final end = dateOnly(until);
    if (start.isBefore(dateOnly(DateTime.now()))) {
      return 'A pause can\'t start in the past';
    }
    if (end.isBefore(start)) return 'End date must be after the start date';
    if (end.difference(start).inDays + 1 > kMaxPauseDays) {
      return 'You can pause for a maximum of $kMaxPauseDays days';
    }
    final sub = _subscriptions.firstWhere((s) => s.id == subscriptionId);
    if (sub.status != SubscriptionStatus.active) {
      return 'Only active subscriptions can be paused';
    }
    if (sub.endDate != null && end.isAfter(dateOnly(sub.endDate!))) {
      return 'The pause can\'t go beyond the subscription end date';
    }

    await _subscriptionsRef.doc(subscriptionId).update({
      'pausedFrom': start.toIso8601String(),
      'pausedUntil': end.toIso8601String(),
    });
    return null;
  }

  /// Ends a running pause early, or cancels one that hasn't started yet.
  Future<void> resumeSubscription(String subscriptionId) async {
    await _subscriptionsRef.doc(subscriptionId).update({
      'pausedFrom': null,
      'pausedUntil': null,
    });
  }

  /// Admin approves a pending subscription (older subscriptions only - new ones
  /// are active as soon as they're paid) and notifies the customer.
  Future<void> approveSubscription(String subscriptionId) async {
    final sub = _subscriptions.firstWhere((s) => s.id == subscriptionId);
    await _subscriptionsRef.doc(subscriptionId).update({'status': SubscriptionStatus.active.name});
    await _notificationsRef.add(AppNotification(
      id: '',
      customerUsername: sub.customerUsername,
      type: NotificationType.subscriptionApproved,
      title: 'Subscription approved',
      message:
          'Your subscription to ${sub.newspaper.name} has been accepted and is now active.',
      subscriptionId: subscriptionId,
      alsoSentAsSms: true,
      createdAt: DateTime.now(),
    ).toMap());
  }

  /// Customer accepts a price change from an older notification.
  Future<void> acceptPriceChange(String notificationId, String subscriptionId) async {
    final sub = _subscriptions.firstWhere((s) => s.id == subscriptionId);
    if (sub.pendingNewPrice != null) {
      await _subscriptionsRef.doc(subscriptionId).update({
        'pricePerCopyAtSignup': sub.pendingNewPrice,
        'pendingNewPrice': null,
      });
    }
    await _notificationsRef.doc(notificationId).update({'actionTaken': 'accepted', 'read': true});
  }

  /// Customer declines a price change: subscription is cancelled instead.
  Future<void> declinePriceChange(String notificationId, String subscriptionId) async {
    await cancelSubscription(subscriptionId);
    await _subscriptionsRef.doc(subscriptionId).update({'pendingNewPrice': null});
    await _notificationsRef.doc(notificationId).update({'actionTaken': 'declined', 'read': true});
  }

  Future<void> markNotificationRead(String notificationId) async {
    await _notificationsRef.doc(notificationId).update({'read': true});
  }

  List<AppNotification> notificationsForCustomer(String username) =>
      _notifications.where((n) => n.customerUsername == username).toList();

  int unreadNotificationCountFor(String username) =>
      notificationsForCustomer(username).where((n) => !n.read).length;

  // ---------- Fresh greens & vegetables - piloted in one zip code only ----------

  /// Called once the UPI payment has been confirmed. Delivery is promised
  /// within [kVeggieDeliveryWindow] of the order.
  Future<void> createVeggieOrder({
    required List<VeggieOrderLine> lines,
    required String zipCode,
    required String address,
    required String transactionRef,
  }) async {
    final now = DateTime.now();
    final order = VeggieOrder(
      id: '',
      customerUsername: currentUser!.username,
      customerName: currentCustomerProfile?.name,
      lines: lines,
      totalAmount: _round2(lines.fold<double>(0, (acc, l) => acc + l.total)),
      zipCode: zipCode,
      address: address,
      orderedAt: now,
      expectedDeliveryBy: now.add(kVeggieDeliveryWindow),
      createdAt: now,
      paidAt: now,
      paymentMethod: 'UPI',
      receiptNo: _newReceiptNo('GRN'),
      transactionRef: transactionRef,
    );
    await _veggieOrdersRef.add(order.toMap());
  }

  List<VeggieOrder> veggieOrdersForCustomer(String username) =>
      _veggieOrders.where((o) => o.customerUsername == username).toList();

  Future<void> assignVeggieDelivery(String orderId, String? deliveryUsername) async {
    await _veggieOrdersRef.doc(orderId).update({'assignedDeliveryBoy': deliveryUsername});
  }

  // ---------- Support ----------

  Future<void> submitIssue({required String subject, required String description}) async {
    final user = currentUser!;
    await _issuesRef.add(Issue(
      id: '',
      reporterUsername: user.username,
      reporterName: currentCustomerProfile?.name ?? user.username,
      reporterRole: user.role.name,
      subject: subject.trim(),
      description: description.trim(),
      createdAt: DateTime.now(),
    ).toMap());
  }

  Future<void> setIssueResolved(String issueId, bool resolved) async {
    await _issuesRef.doc(issueId).update({'resolved': resolved});
  }

  Future<void> deleteIssue(String issueId) async {
    await _issuesRef.doc(issueId).delete();
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
    required DateTime endDate,
  }) async {
    await _subscriptionsRef.doc(subscriptionId).update({
      'newspaperId': newspaperId,
      'newspaperName': _newspaperById(newspaperId).name,
      'selectedWeekdays': selectedWeekdays,
      'copiesPerDelivery': copiesPerDelivery,
      'address': address,
      'startDate': dateOnly(startDate).toIso8601String(),
      'endDate': dateOnly(endDate).toIso8601String(),
    });
  }

  Future<void> deleteSubscription(String subscriptionId) async {
    await _subscriptionsRef.doc(subscriptionId).delete();
  }

  // ---------- Delivery person: today's route only ----------

  /// Newspapers to deliver today: active, in date range, not paused.
  List<Subscription> todaysDeliveriesFor(String deliveryUsername) {
    final today = DateTime.now();
    return _subscriptions
        .where((s) => s.assignedDeliveryBoy == deliveryUsername && s.isDeliveryDay(today))
        .toList();
  }

  /// Greens orders placed today and assigned to this delivery person.
  List<VeggieOrder> todaysGreensDeliveriesFor(String deliveryUsername) {
    final today = dateOnly(DateTime.now());
    return _veggieOrders
        .where((o) =>
            o.assignedDeliveryBoy == deliveryUsername && dateOnly(o.orderedAt) == today)
        .toList()
      ..sort((a, b) => a.expectedDeliveryBy.compareTo(b.expectedDeliveryBy));
  }
}
