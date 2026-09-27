import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';
import '../../utils/currency.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionDetailScreen({super.key, required this.subscription});

  @override
  State<SubscriptionDetailScreen> createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  bool _cancelling = false;

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _confirmAndCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discontinue subscription?'),
        content: const Text(
          "You've already paid for this month, so delivery will continue as "
          "normal until the end of the current billing month. After that, "
          "it will be discontinued and you won't be charged again.\n\n"
          'Are you sure you want to cancel?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep subscription'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Yes, discontinue'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _cancelling = true);
    await context.read<AppState>().cancelSubscription(widget.subscription.id);
    if (!mounted) return;
    setState(() => _cancelling = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Subscription will be discontinued after this month ends.'),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the live app state so this screen updates if the subscription
    // changes elsewhere (e.g. admin assigns delivery while this is open).
    final appState = context.watch<AppState>();
    final current = appState.subscriptions.firstWhere(
      (s) => s.id == widget.subscription.id,
      orElse: () => widget.subscription,
    );
    final isActive = current.status == SubscriptionStatus.active;

    return Scaffold(
      appBar: AppBar(title: const Text('Subscription Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  current.newspaper.name,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Chip(
                label: Text(isActive ? 'Active' : 'Cancelled'),
                backgroundColor: isActive ? Colors.green[100] : Colors.grey[300],
                labelStyle: TextStyle(
                  color: isActive ? Colors.green[800] : Colors.grey[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _DetailRow(icon: Icons.calendar_today, label: 'Delivery days', value: current.weekdaysLabel),
          _DetailRow(
            icon: Icons.copy_all,
            label: 'Copies per delivery',
            value: '${current.copiesPerDelivery}',
          ),
          _DetailRow(icon: Icons.event, label: 'Start date', value: _formatDate(current.startDate)),
          _DetailRow(icon: Icons.location_on_outlined, label: 'Delivery address', value: current.address),
          _DetailRow(
            icon: Icons.local_shipping_outlined,
            label: 'Delivery assigned',
            value: current.assignedDeliveryBoy ?? 'Not yet assigned',
          ),
          _DetailRow(
            icon: Icons.currency_rupee,
            label: 'Monthly cost',
            value: formatInr(current.monthlyPrice),
          ),
          const SizedBox(height: 32),
          if (isActive)
            FilledButton.icon(
              onPressed: _cancelling ? null : _confirmAndCancel,
              icon: _cancelling
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(_cancelling ? 'Cancelling...' : 'Discontinue Subscription'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.all(16),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This subscription has been discontinued. '
                      'Delivery will stop at the end of the paid month.',
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
