import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart';
import '../../state/app_state.dart';
import '../../utils/currency.dart';

class PayPaymentScreen extends StatefulWidget {
  final Payment payment;

  const PayPaymentScreen({super.key, required this.payment});

  @override
  State<PayPaymentScreen> createState() => _PayPaymentScreenState();
}

class _PayPaymentScreenState extends State<PayPaymentScreen> {
  bool _processing = false;
  static const _phonepePurple = Color(0xFF5F259F);

  Future<void> _pay({required String method, required Duration delay}) async {
    setState(() => _processing = true);
    if (delay > Duration.zero) await Future.delayed(delay);
    if (!mounted) return;

    await context.read<AppState>().markPaymentPaid(widget.payment.id, method);

    if (!mounted) return;
    setState(() => _processing = false);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.check_circle, color: Colors.green[600], size: 48),
        title: const Text('Payment successful'),
        content: Text(
          'Your payment of ${formatInr(widget.payment.totalAmount)} for '
          '${widget.payment.newspaperName} is complete.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.payment;
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FA),
      appBar: AppBar(title: const Text('Pay Now')),
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
                  Text(p.newspaperName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 4),
                  Text('${p.copiesPerDelivery}x copy per delivery',
                      style: TextStyle(color: Colors.grey[600])),
                  const Divider(height: 28),
                  _Row(label: 'Paper charges', value: formatInr(p.paperCharge)),
                  _Row(label: 'Delivery charges', value: formatInr(p.deliveryCharge)),
                  _Row(label: 'GST', value: formatInr(p.gstAmount)),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        formatInr(p.totalAmount),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 20, color: _phonepePurple),
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
                      Text('Pay via PhonePe',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('UPI · Secure checkout',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _processing
                          ? null
                          : () => _pay(method: 'PhonePe', delay: const Duration(milliseconds: 1200)),
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
                          : Text('Pay ${formatInr(p.totalAmount)}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: TextButton.icon(
              onPressed:
                  _processing ? null : () => _pay(method: 'Skipped (Test Mode)', delay: Duration.zero),
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

class _Row extends StatelessWidget {
  final String label;
  final String value;

  const _Row({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
