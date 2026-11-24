import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/newspaper.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency.dart';
import '../common/upi_payment_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final Newspaper newspaper;
  final List<int> selectedWeekdays;
  final int copiesPerDelivery;
  final String address;
  final DateTime startDate;
  final DateTime endDate;
  final String? zipCode;

  const CheckoutScreen({
    super.key,
    required this.newspaper,
    required this.selectedWeekdays,
    required this.copiesPerDelivery,
    required this.address,
    required this.startDate,
    required this.endDate,
    this.zipCode,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  String get _weekdaysLabel {
    final sorted = [...widget.selectedWeekdays]..sort();
    return sorted.map((d) => kWeekdayLabels[d]).join(', ');
  }

  SubscriptionQuote _quote(AppState appState) => appState.quoteSubscription(
        newspaperId: widget.newspaper.id,
        weekdays: widget.selectedWeekdays,
        copies: widget.copiesPerDelivery,
        startDate: widget.startDate,
        endDate: widget.endDate,
        zip: widget.zipCode,
      );

  Future<void> _pay() async {
    final appState = context.read<AppState>();
    final quote = _quote(appState);

    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UpiPaymentScreen(
          amount: quote.total,
          description: '${widget.newspaper.name} subscription',
          onPaid: (ref) async {
            final error = await appState.createSubscription(
              newspaper: widget.newspaper,
              selectedWeekdays: widget.selectedWeekdays,
              copiesPerDelivery: widget.copiesPerDelivery,
              address: widget.address,
              startDate: widget.startDate,
              endDate: widget.endDate,
              zipCode: widget.zipCode,
              transactionRef: ref,
            );
            if (error != null) throw Exception(error);
          },
        ),
      ),
    );
    if (paid != true || !mounted) return;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green[600], size: 48),
        title: const Text('Subscription confirmed'),
        content: Text(
          'Payment received. Your ${widget.newspaper.name} deliveries start on '
          '${formatDate(widget.startDate)}. You can find the receipt in the Receipts tab.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final b = _quote(appState);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FA),
      appBar: AppBar(title: const Text('Confirm & Pay')),
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
                          color: Colors.deepPurple.withValues(alpha: 0.1),
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
                  _Row(label: 'Start date', value: formatDate(widget.startDate)),
                  _Row(label: 'End date', value: formatDate(widget.endDate)),
                  _Row(label: 'Total deliveries', value: '${b.deliveries}'),
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
                  const Text('Amount to pay',
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
                    'Payment is due up front. Your subscription is confirmed as soon as the UPI payment is done.',
                    style: TextStyle(color: Colors.orange[900], fontSize: 12.5),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: b.deliveries == 0 ? null : _pay,
            icon: const Icon(Icons.qr_code_2),
            label: Text('Pay ${formatInr(b.total)} with UPI'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
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
