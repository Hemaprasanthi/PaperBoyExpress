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
import '../data/mock_data.dart';
import '../data/veggie_data.dart';

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
  final CollectionReference<Map<String, dynamic>> _deliveryChargesRef =
      FirebaseFirestore.instance.collection('deliveryCharges');
  final DocumentReference<Map<String, dynamic>> _gstSettingRef =
      FirebaseFirestore.instance.collection('settings').doc('gst');
  final CollectionReference<Map<String, dynamic>> _notificationsRef =
      FirebaseFirestore.instance.collection('notifications');
  final CollectionReference<Map<String, dynamic>> _veggieOrdersRef =
      FirebaseFirestore.instance.collection('veggieOrders');

  List<Subscription> _subscriptions = [];
  List<Subscription> get subscriptions => List.unmodifiable(_subscriptions);
  bool subscriptionsLoaded = false;

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
      _generateDueReminders();
    });

    _deliveryChargesRef.snapshots().listen((snapshot) {
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
    });

    _notificationsRef.snapshots().listen((snapshot) {
      _notifications = snapshot.docs
          .map((doc) => AppNotification.fromMap(doc.id, doc.data()))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    });

    _veggieOrdersRef.snapshots().listen((snapshot) {
      _veggieOrders = snapshot.docs.map((doc) => VeggieOrder.fromMap(doc.id, doc.data())).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
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

  /// When admin changes a newspaper's price, any active subscriptions that
  /// are affected get a notification requiring accept/decline - the new
  /// price never applies automatically.
  Future<void> setBasePrice(String newspaperId, double price) async {
    final oldPrice = basePriceFor(newspaperId);
    await _pricingRef.doc(newspaperId).set({'basePrice': price}, SetOptions(merge: true));
    if (price == oldPrice) return;

    final affected = _subscriptions.where((s) =>
        s.status == SubscriptionStatus.active &&
        s.newspaper.id == newspaperId &&
        !(s.zipCode != null && zipOverridesFor(newspaperId).containsKey(s.zipCode)));
    for (final s in affected) {
      await _notifyPriceChange(s, oldPrice: s.effectivePricePerCopy, newPrice: price);
    }
  }

  Future<void> setZipPrice(String newspaperId, String zip, double price) async {
    final oldPrice = priceFor(newspaperId, zip: zip);
    await _pricingRef.doc(newspaperId).set({
      'basePrice': basePriceFor(newspaperId), // ensure basePrice exists even on first write
      'zipOverrides': {..._pricing[newspaperId]?.zipOverrides ?? {}, zip: price},
    }, SetOptions(merge: true));
    if (price == oldPrice) return;

    final affected = _subscriptions.where((s) =>
        s.status == SubscriptionStatus.active && s.newspaper.id == newspaperId && s.zipCode == zip);
    for (final s in affected) {
      await _notifyPriceChange(s, oldPrice: s.effectivePricePerCopy, newPrice: price);
    }
  }

  Future<void> removeZipPrice(String newspaperId, String zip) async {
    final updated = {...(_pricing[newspaperId]?.zipOverrides ?? {})}..remove(zip);
    await _pricingRef.doc(newspaperId).set({
      'zipOverrides': updated,
    }, SetOptions(merge: true));
  }

  Future<void> _notifyPriceChange(
    Subscription s, {
    required double oldPrice,
    required double newPrice,
  }) async {
    await _subscriptionsRef.doc(s.id).update({'pendingNewPrice': newPrice});
    await _notificationsRef.add(AppNotification(
      id: '',
      customerUsername: s.customerUsername,
      type: NotificationType.priceChange,
      title: 'Price change for ${s.newspaper.name}',
      message: 'The price for ${s.newspaper.name} is changing from ${_fmt(oldPrice)} to '
          '${_fmt(newPrice)} per copy, effective from your next billing month. '
          'If you don\'t agree, your subscription will be cancelled.',
      subscriptionId: s.id,
      requiresAction: true,
      oldPrice: oldPrice,
      newPrice: newPrice,
      alsoSentAsSms: true,
      createdAt: DateTime.now(),
    ).toMap());
  }

  String _fmt(double v) => '\u20b9${v.toStringAsFixed(2)}';

  // ---------- Auth: demo admin/delivery + real customer accounts ----------

  /// [identifier] can be: the demo usernames ("admin", "delivery", "customer"),
  /// a real customer's phone number, or a real customer's email (if they set one).
  Future<String?> login(String identifier, String password) async {
    final trimmed = identifier.trim();

    // 1. Check the 3 hardcoded demo accounts first - these are the ONLY
    // demo accounts in the app; every other login goes through real
    // Firebase Auth below.
    final demoMatch = kUsers.where(
      (u) => u.username == trimmed && u.password == password,
    );
    if (demoMatch.isNotEmpty) {
      currentUser = demoMatch.first;
      // The demo customer gets a profile in the greens pilot zip so Fresh Greens is visible.
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
    required String zipCode,
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
        zipCode: zipCode.trim(),
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

  // ---------- Customer: subscribing (no payment collected yet - billed at month end) ----------
  Future<void> createSubscription({
    required Newspaper newspaper,
    required List<int> selectedWeekdays,
    required int copiesPerDelivery,
    required String address,
    required DateTime startDate,
    String? zipCode,
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
      status: SubscriptionStatus.pendingApproval,
    );

    final paperCharge = effectivePrice * copiesPerDelivery * selectedWeekdays.length * 4.33;
    final deliveryCharge = deliveryChargeForZip(zipCode);
    final gstAmount = (paperCharge + deliveryCharge) * (gstPercent / 100);
    final total = paperCharge + deliveryCharge + gstAmount;
    final periodEnd = DateTime(startDate.year, startDate.month + 1, startDate.day);

    final subRef = _subscriptionsRef.doc();
    final paymentRef = _paymentsRef.doc();

    final payment = Payment(
      id: '',
      subscriptionId: subRef.id,
      customerUsername: currentUser!.username,
      newspaperName: newspaper.name,
      copiesPerDelivery: copiesPerDelivery,
      periodStart: startDate,
      periodEnd: periodEnd,
      paperCharge: paperCharge,
      deliveryCharge: deliveryCharge,
      gstAmount: gstAmount,
      totalAmount: total,
      status: PaymentStatus.pending, // billed at month end, not now
      createdAt: DateTime.now(),
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

  /// Called from the Payments tab when a customer pays a specific due payment.
  Future<void> markPaymentPaid(String paymentId, String method) async {
    await _paymentsRef.doc(paymentId).update({
      'status': PaymentStatus.paid.name,
      'paidAt': DateTime.now().toIso8601String(),
      'method': method,
    });
  }

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
  /// can't start in the past or last longer than [kMaxPauseDays]. Delivery
  /// resumes automatically the day after [until].
  Future<String?> pauseSubscription(String subscriptionId, DateTime from, DateTime until) async {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(until.year, until.month, until.day);
    final today = DateTime.now();
    if (start.isBefore(DateTime(today.year, today.month, today.day))) {
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

  /// Admin approves a pending subscription request - flips it active and
  /// notifies the customer (simulated SMS log for now).
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

  /// Customer accepts a price change: applies the new price going forward.
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

  // ---------- Fresh greens (vegetables) - piloted in one zip code only ----------
  Future<void> createVeggieOrder({
    required Map<String, int> items, // veggie id -> qty
    required double totalAmount,
    required String zipCode,
    required String address,
  }) async {
    final now = DateTime.now();
    final expectedDeliveryBy = now.add(kVeggieDeliveryWindow);

    final order = VeggieOrder(
      id: '',
      customerUsername: currentUser!.username,
      customerName: currentCustomerProfile?.name,
      items: items,
      totalAmount: totalAmount,
      zipCode: zipCode,
      address: address,
      orderedAt: now,
      expectedDeliveryBy: expectedDeliveryBy,
      createdAt: now,
    );
    await _veggieOrdersRef.add(order.toMap());
  }

  List<VeggieOrder> veggieOrdersForCustomer(String username) =>
      _veggieOrders.where((o) => o.customerUsername == username).toList();

  /// Client-side reminder generation: whenever payments refresh, check the
  /// current customer's own pending payments and log a one-time "payment
  /// due soon" notification (simulated SMS) starting 3 days before due date.
  /// This runs only for the logged-in customer's own data.
  Future<void> _generateDueReminders() async {
    if (currentUser == null || currentUser!.role != UserRole.customer) return;
    final username = currentUser!.username;
    final myPending = paymentsForCustomer(username).where((p) => p.status == PaymentStatus.pending);
    final now = DateTime.now();

    for (final p in myPending) {
      final daysUntilDue = p.periodEnd.difference(now).inDays;
      if (daysUntilDue > 3) continue; // only remind within the last 3 days (or overdue)

      final alreadyReminded = _notifications.any(
        (n) => n.paymentId == p.id && n.type == NotificationType.paymentReminder,
      );
      if (alreadyReminded) continue;

      await _notificationsRef.add(AppNotification(
        id: '',
        customerUsername: username,
        type: NotificationType.paymentReminder,
        title: 'Payment due soon',
        message: daysUntilDue >= 0
            ? 'Your payment of ${_fmt(p.totalAmount)} for ${p.newspaperName} is due in '
                '$daysUntilDue day(s). Please pay from the Payments tab.'
            : 'Your payment of ${_fmt(p.totalAmount)} for ${p.newspaperName} is overdue. '
                'Please pay from the Payments tab.',
        paymentId: p.id,
        subscriptionId: p.subscriptionId,
        alsoSentAsSms: true,
        createdAt: now,
      ).toMap());
    }
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
  // Only active, non-paused subscriptions are shown - once cancelled or while
  // paused, delivery doesn't need to see it on their route.
  List<Subscription> subscriptionsAssignedTo(String deliveryUsername) => _subscriptions
      .where((s) =>
          s.assignedDeliveryBoy == deliveryUsername &&
          s.status == SubscriptionStatus.active &&
          !s.isPausedNow)
      .toList();
}
