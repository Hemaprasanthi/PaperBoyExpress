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
  bool _processing = false;

  static const _phonepePurple = Color(0xFF5F259F);

  double get _monthlyPrice {
    final price = context.read<AppState>().priceFor(widget.newspaper.id, zip: widget.zipCode);
    return price * widget.copiesPerDelivery * widget.selectedWeekdays.length * 4.33;
  }

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

  Future<void> _completeOrder({required String method, required Duration delay}) async {
    setState(() => _processing = true);
    if (delay > Duration.zero) {
      await Future.delayed(delay);
    }

    if (!mounted) return;

    await context.read<AppState>().createSubscription(
          newspaper: widget.newspaper,
          selectedWeekdays: widget.selectedWeekdays,
          copiesPerDelivery: widget.copiesPerDelivery,
          address: widget.address,
          startDate: widget.startDate,
          zipCode: widget.zipCode,
          paymentMethod: method,
        );

    setState(() => _processing = false);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green[600], size: 48),
        title: const Text('Subscription confirmed'),
        content: Text(
          'You are now subscribed to ${widget.newspaper.name} '
          '($_weekdaysLabel, ${widget.copiesPerDelivery} copy each time), '
          'starting ${_formatDate(widget.startDate)}.',
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
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FA),
      appBar: AppBar(title: const Text('Payment')),
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
                          color: _phonepePurple.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.newspaper, color: _phonepePurple),
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
                  _SummaryRow(label: 'Delivery days', value: _weekdaysLabel),
                  _SummaryRow(label: 'Copies per delivery', value: '${widget.copiesPerDelivery}'),
                  _SummaryRow(label: 'Start date', value: _formatDate(widget.startDate)),
                  _SummaryRow(label: 'Address', value: widget.address),
                  const Divider(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monthly total',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        formatInr(_monthlyPrice),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: _phonepePurple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            color: _phonepePurple,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.account_balance_wallet, color: Colors.white),
                      SizedBox(width: 10),
                      Text(
                        'Pay via PhonePe',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'UPI · Secure checkout',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _processing
                          ? null
                          : () => _completeOrder(
                                method: 'PhonePe',
                                delay: const Duration(milliseconds: 1200),
                              ),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _phonepePurple,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _processing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: _phonepePurple),
                            )
                          : Text(
                              'Pay ${formatInr(_monthlyPrice)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed: _processing
                  ? null
                  : () => _completeOrder(
                        method: 'Skipped (Test Mode)',
                        delay: Duration.zero,
                      ),
              icon: const Icon(Icons.fast_forward, size: 18),
              label: const Text('Skip Payment (Test Mode)'),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Real PhonePe payments aren\'t wired up yet — either button marks this as paid.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}
