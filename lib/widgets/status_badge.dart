import 'package:flutter/material.dart';
import '../models/subscription.dart';

MaterialColor subscriptionStatusColor(SubscriptionDisplayStatus status) {
  switch (status) {
    case SubscriptionDisplayStatus.pending:
      return Colors.orange;
    case SubscriptionDisplayStatus.active:
      return Colors.green;
    case SubscriptionDisplayStatus.paused:
      return Colors.blue;
    case SubscriptionDisplayStatus.completed:
      return Colors.teal;
    case SubscriptionDisplayStatus.cancelled:
      return Colors.grey;
  }
}

class SubscriptionStatusBadge extends StatelessWidget {
  final Subscription subscription;

  const SubscriptionStatusBadge({super.key, required this.subscription});

  @override
  Widget build(BuildContext context) {
    final status = subscription.displayStatus;
    final color = subscriptionStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.shade50, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color.shade800),
      ),
    );
  }
}
