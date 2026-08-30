import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/newspaper.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';

class CheckoutScreen extends StatefulWidget {
  final Newspaper newspaper;
  final List<int> selectedWeekdays;
  final int copiesPerDelivery;
  final String address;
  final DateTime startDate;

  const CheckoutScreen({
    super.key,
    required this.newspaper,
    required this.selectedWeekdays,
    required this.copiesPerDelivery,
    required this.address,
    required this.startDate,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _cardController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _processing = false;

  double get _monthlyPrice =>
      widget.newspaper.pricePerCopy *
      widget.copiesPerDelivery *
      widget.selectedWeekdays.length *
      4.33;

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

  Future<void> _pay() async {
    // NOTE: this is a placeholder/mock payment flow — no real card
    // processing happens here. Wire up a real payment provider (Stripe,
    // etc.) before shipping this for real.
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    context.read<AppState>().createSubscription(
          newspaper: widget.newspaper,
          selectedWeekdays: widget.selectedWeekdays,
          copiesPerDelivery: widget.copiesPerDelivery,
          address: widget.address,
          startDate: widget.startDate,
        );

    setState(() => _processing = false);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Subscription confirmed'),
        content: Text(
          'You are now subscribed to ${widget.newspaper.name} '
          '($_weekdaysLabel, ${widget.copiesPerDelivery} copy each time), '
          'starting ${_formatDate(widget.startDate)}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    if (!mounted) return;
    // Pop checkout + select screens, back to customer home.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.newspaper.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Text('$_weekdaysLabel · ${widget.copiesPerDelivery} copy each'),
                  Text('Starts ${_formatDate(widget.startDate)}',
                      style: TextStyle(color: Colors.grey[600])),
                  Text(widget.address, style: TextStyle(color: Colors.grey[600])),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monthly total', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(
                        '\$${_monthlyPrice.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Card details (demo — not real)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          TextField(
            controller: _cardController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Card number',
              hintText: '4242 4242 4242 4242',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _expiryController,
                  decoration: const InputDecoration(
                    labelText: 'MM/YY',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _processing ? null : _pay,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: _processing
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : Text('Pay \$${_monthlyPrice.toStringAsFixed(2)}'),
          ),
        ],
      ),
    );
  }
}
