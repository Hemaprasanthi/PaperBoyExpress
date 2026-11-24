import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency.dart';
import '../../widgets/status_badge.dart';

class SubscriptionDetailScreen extends StatefulWidget {
  final Subscription subscription;

  const SubscriptionDetailScreen({super.key, required this.subscription});

  @override
  State<SubscriptionDetailScreen> createState() => _SubscriptionDetailScreenState();
}

class _SubscriptionDetailScreenState extends State<SubscriptionDetailScreen> {
  bool _cancelling = false;
  bool _pauseBusy = false;

  Future<void> _pickPauseAndSave(Subscription current) async {
    final today = dateOnly(DateTime.now());
    var lastDate = today.add(const Duration(days: 90));
    if (current.endDate != null && dateOnly(current.endDate!).isBefore(lastDate)) {
      lastDate = dateOnly(current.endDate!);
    }
    if (lastDate.isBefore(today)) return;

    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: lastDate,
      helpText: 'Pause delivery (max $kMaxPauseDays days)',
      saveText: 'Pause',
    );
    if (range == null || !mounted) return;

    setState(() => _pauseBusy = true);
    final error = await context
        .read<AppState>()
        .pauseSubscription(widget.subscription.id, range.start, range.end);
    if (!mounted) return;
    setState(() => _pauseBusy = false);

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(error ??
          'Delivery paused from ${formatDate(range.start)} to ${formatDate(range.end)}. '
              'It resumes automatically after that.'),
    ));
  }

  Future<void> _resumeNow() async {
    setState(() => _pauseBusy = true);
    await context.read<AppState>().resumeSubscription(widget.subscription.id);
    if (!mounted) return;
    setState(() => _pauseBusy = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pause removed - deliveries will continue as scheduled.')),
    );
  }

  Future<void> _confirmAndCancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Discontinue subscription?'),
        content: const Text(
          'Deliveries will stop. Amounts you have already paid aren\'t refunded '
          'automatically - please contact support if you need help with that.\n\n'
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

    if (confirmed != true || !mounted) return;

    setState(() => _cancelling = true);
    await context.read<AppState>().cancelSubscription(widget.subscription.id);
    if (!mounted) return;
    setState(() => _cancelling = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription discontinued.')),
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
    final status = current.displayStatus;
    final isActive = current.status == SubscriptionStatus.active && !current.isExpired;
    final isPending = current.status == SubscriptionStatus.pendingApproval;
    final isPaused = status == SubscriptionDisplayStatus.paused;
    final hasPause = isActive && current.hasPauseScheduledOrActive;
    final statusColor = subscriptionStatusColor(status);

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
                label: Text(status.label),
                backgroundColor: statusColor.withValues(alpha: 0.15),
                labelStyle: TextStyle(color: statusColor.shade800, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (current.pendingNewPrice != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700], size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'A price change to ${formatInr(current.pendingNewPrice!)}/copy is awaiting your response. Check Notifications.',
                        style: TextStyle(color: Colors.blue[900], fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const Divider(height: 32),
          _DetailRow(icon: Icons.calendar_today, label: 'Delivery days', value: current.weekdaysLabel),
          _DetailRow(
            icon: Icons.copy_all,
            label: 'Copies per delivery',
            value: '${current.copiesPerDelivery}',
          ),
          _DetailRow(icon: Icons.event, label: 'Start date', value: formatDate(current.startDate)),
          if (current.endDate != null)
            _DetailRow(icon: Icons.event_busy, label: 'End date', value: formatDate(current.endDate!)),
          _DetailRow(icon: Icons.location_on_outlined, label: 'Delivery address', value: current.address),
          _DetailRow(
            icon: Icons.local_shipping_outlined,
            label: 'Delivery assigned',
            value: current.assignedDeliveryBoy ?? 'Not yet assigned',
          ),
          _DetailRow(
            icon: Icons.currency_rupee,
            label: current.endDate == null ? 'Paper charges (monthly est.)' : 'Paper charges (prepaid)',
            value: formatInr(current.periodPrice),
          ),
          const SizedBox(height: 32),
          if (hasPause) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.pause_circle_outline, color: Colors.blue[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${isPaused ? 'Paused' : 'Pause scheduled'}: '
                      '${formatDate(current.pausedFrom!)} - ${formatDate(current.pausedUntil!)}. '
                      'Delivery resumes automatically after that.',
                      style: TextStyle(color: Colors.blue[900], fontSize: 12.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pauseBusy ? null : _resumeNow,
              icon: const Icon(Icons.play_circle_outline),
              label: Text(isPaused ? 'Resume Delivery Now' : 'Remove Scheduled Pause'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 12),
          ] else if (isActive) ...[
            OutlinedButton.icon(
              onPressed: _pauseBusy ? null : () => _pickPauseAndSave(current),
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text('Pause Delivery (up to 1 month)'),
              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16)),
            ),
            const SizedBox(height: 12),
          ],
          if (isActive || isPending)
            FilledButton.icon(
              onPressed: _cancelling ? null : _confirmAndCancel,
              icon: _cancelling
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cancel_outlined),
              label: Text(_cancelling
                  ? 'Cancelling...'
                  : (isPending ? 'Withdraw Request' : 'Discontinue Subscription')),
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
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.grey),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      status == SubscriptionDisplayStatus.completed
                          ? 'This subscription has ended.'
                          : 'This subscription has been discontinued.',
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
