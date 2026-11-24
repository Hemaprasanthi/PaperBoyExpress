import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/newspaper.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';
import '../../utils/currency.dart';

class CheckoutScreen extends StatefulWidget {
  final Newspaper newspaper;
  final List<int> selectedWeekdays;
  final int copiesPerDelivery;
  final String address;
  final DateTime startDate;
  final String? zipCode;

  const CheckoutScreen({
    super.key,
    required this.newspaper,
    required this.selectedWeekdays,
    required this.copiesPerDelivery,
    required this.address,
    required this.startDate,
    this.zipCode,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _submitting = false;

  String get _weekdaysLabel {
    final sorted = [...widget.selectedWeekdays]..sort();
    return sorted.map((d) => kWeekdayLabels[d]).join(', ');
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  ({double paper, double delivery, double gst, double total}) _breakdown(AppState appState) {
    final price = appState.priceFor(widget.newspaper.id, zip: widget.zipCode);
    final paper = price * widget.copiesPerDelivery * widget.selectedWeekdays.length * 4.33;
    final delivery = appState.deliveryChargeForZip(widget.zipCode);
    final gst = (paper + delivery) * (appState.gstPercent / 100);
    return (paper: paper, delivery: delivery, gst: gst, total: paper + delivery + gst);
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    await context.read<AppState>().createSubscription(
          newspaper: widget.newspaper,
          selectedWeekdays: widget.selectedWeekdays,
          copiesPerDelivery: widget.copiesPerDelivery,
          address: widget.address,
          startDate: widget.startDate,
          zipCode: widget.zipCode,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.hourglass_top, color: Colors.orange[600], size: 48),
        title: const Text('Request submitted'),
        content: const Text(
          'Your subscription request has been sent for approval. '
          'We\'ll notify you as soon as it\'s accepted - your dashboard will '
          'update automatically once it is.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final b = _breakdown(appState);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FA),
      appBar: AppBar(title: const Text('Confirm Subscription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.newspaper, color: Colors.deepPurple),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.newspaper.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _Row(label: 'Delivery days', value: _weekdaysLabel),
                  _Row(label: 'Copies per delivery', value: '${widget.copiesPerDelivery}'),
                  _Row(label: 'Start date', value: _formatDate(widget.startDate)),
                  _Row(label: 'Address', value: widget.address),
                  if (widget.zipCode != null) _Row(label: 'Zip code', value: widget.zipCode!),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('First month\'s estimated bill',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 12),
                  _Row(label: 'Paper charges', value: formatInr(b.paper)),
                  _Row(label: 'Delivery charges', value: formatInr(b.delivery)),
                  _Row(
                    label: 'GST (${appState.gstPercent.toStringAsFixed(0)}%)',
                    value: formatInr(b.gst),
                  ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        formatInr(b.total),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[100]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange[800], size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'No payment is collected now. You\'ll be billed at the end of the month '
                    'from the Payments tab, once your subscription is approved and active.',
                    style: TextStyle(color: Colors.orange[900], fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submitting ? null : _submit,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: _submitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Submit for Approval'),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
