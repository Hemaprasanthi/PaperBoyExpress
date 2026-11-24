import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_notification.dart';
import '../../state/app_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.currentUser == null) return const SizedBox.shrink();
    final notifications = appState.notificationsForCustomer(appState.currentUser!.username);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: notifications.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text('No notifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final n = notifications[index];
                if (!n.read && !n.requiresAction) {
                  // Mark general/informational notifications as read once shown.
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    context.read<AppState>().markNotificationRead(n.id);
                  });
                }
                return _NotificationCard(notification: n);
              },
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final AppNotification notification;

  const _NotificationCard({required this.notification});

  IconData get _icon {
    switch (notification.type) {
      case NotificationType.subscriptionApproved:
        return Icons.check_circle_outline;
      case NotificationType.priceChange:
        return Icons.price_change_outlined;
      case NotificationType.paymentReminder:
        return Icons.notifications_active_outlined;
      case NotificationType.general:
        return Icons.info_outline;
    }
  }

  Color get _color {
    switch (notification.type) {
      case NotificationType.subscriptionApproved:
        return Colors.green;
      case NotificationType.priceChange:
        return Colors.blue;
      case NotificationType.paymentReminder:
        return Colors.orange;
      case NotificationType.general:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final needsResponse = notification.requiresAction && notification.actionTaken == null;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: _color.withOpacity(0.1),
                  child: Icon(_icon, color: _color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(notification.message,
                          style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                      if (notification.alsoSentAsSms)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '(Simulated SMS - real SMS provider not yet connected)',
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (needsResponse) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => context
                          .read<AppState>()
                          .declinePriceChange(notification.id, notification.subscriptionId!),
                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Decline & Cancel'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => context
                          .read<AppState>()
                          .acceptPriceChange(notification.id, notification.subscriptionId!),
                      child: const Text('Accept New Price'),
                    ),
                  ),
                ],
              ),
            ] else if (notification.actionTaken != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  notification.actionTaken == 'accepted'
                      ? 'You accepted this price change.'
                      : 'You declined - subscription was cancelled.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: notification.actionTaken == 'accepted' ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
