enum NotificationType { subscriptionApproved, priceChange, paymentReminder, general }

class AppNotification {
  final String id;
  final String customerUsername;
  final NotificationType type;
  final String title;
  final String message;
  final String? subscriptionId;
  final String? paymentId;
  final bool requiresAction; // true for price changes needing accept/decline
  final String? actionTaken; // null | 'accepted' | 'declined'
  final double? oldPrice;
  final double? newPrice;
  final bool alsoSentAsSms; // simulated - logged, not actually texted (no SMS gateway yet)
  final bool read;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.customerUsername,
    required this.type,
    required this.title,
    required this.message,
    this.subscriptionId,
    this.paymentId,
    this.requiresAction = false,
    this.actionTaken,
    this.oldPrice,
    this.newPrice,
    this.alsoSentAsSms = false,
    this.read = false,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'customerUsername': customerUsername,
      'type': type.name,
      'title': title,
      'message': message,
      'subscriptionId': subscriptionId,
      'paymentId': paymentId,
      'requiresAction': requiresAction,
      'actionTaken': actionTaken,
      'oldPrice': oldPrice,
      'newPrice': newPrice,
      'alsoSentAsSms': alsoSentAsSms,
      'read': read,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(String id, Map<String, dynamic> map) {
    return AppNotification(
      id: id,
      customerUsername: map['customerUsername'] as String,
      type: NotificationType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      title: map['title'] as String,
      message: map['message'] as String,
      subscriptionId: map['subscriptionId'] as String?,
      paymentId: map['paymentId'] as String?,
      requiresAction: map['requiresAction'] as bool? ?? false,
      actionTaken: map['actionTaken'] as String?,
      oldPrice: (map['oldPrice'] as num?)?.toDouble(),
      newPrice: (map['newPrice'] as num?)?.toDouble(),
      alsoSentAsSms: map['alsoSentAsSms'] as bool? ?? false,
      read: map['read'] as bool? ?? false,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
