import 'package:flutter/material.dart';
import '../../models/payment.dart';
import '../../models/veggie_order.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency.dart';

class NewspaperReceiptScreen extends StatelessWidget {
  final Payment payment;

  const NewspaperReceiptScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return _ReceiptScaffold(
      title: 'Newspaper receipt',
      amount: payment.totalAmount,
      receiptNo: payment.receiptNo,
      paidAt: payment.paidAt,
      method: payment.method,
      transactionRef: payment.transactionRef,
      children: [
        _Row(icon: Icons.newspaper, label: 'Newspaper', value: payment.newspaperName),
        _Row(
          icon: Icons.copy_all,
          label: 'Copies per delivery',
          value: '${payment.copiesPerDelivery}',
        ),
        _Row(
          icon: Icons.date_range,
          label: 'Subscription period',
          value: '${formatDate(payment.periodStart)} – ${formatDate(payment.periodEnd)}',
        ),
        if (payment.totalDeliveries != null)
          _Row(
            icon: Icons.local_shipping_outlined,
            label: 'Deliveries',
            value: '${payment.totalDeliveries}',
          ),
        const Divider(height: 28),
        _Row(icon: Icons.newspaper_outlined, label: 'Paper charges', value: formatInr(payment.paperCharge)),
        _Row(
          icon: Icons.local_shipping_outlined,
          label: 'Delivery charges',
          value: formatInr(payment.deliveryCharge),
        ),
        _Row(icon: Icons.receipt_outlined, label: 'GST', value: formatInr(payment.gstAmount)),
      ],
    );
  }
}

class GreensReceiptScreen extends StatelessWidget {
  final VeggieOrder order;

  const GreensReceiptScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return _ReceiptScaffold(
      title: 'Greens & vegetables receipt',
      amount: order.totalAmount,
      receiptNo: order.receiptNo,
      paidAt: order.paidAt,
      method: order.paymentMethod,
      transactionRef: order.transactionRef,
      children: [
        for (final line in order.lines)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${line.name}  x${line.quantity}'
                    '${line.unit.isEmpty ? '' : ' ${line.unit}'}',
                  ),
                ),
                if (line.unitPrice > 0) Text(formatInr(line.total)),
              ],
            ),
          ),
        const Divider(height: 28),
        _Row(icon: Icons.location_on_outlined, label: 'Delivery address', value: order.address),
        _Row(
          icon: Icons.schedule,
          label: 'Delivery by',
          value: formatDateTime(order.expectedDeliveryBy),
        ),
      ],
    );
  }
}

class _ReceiptScaffold extends StatelessWidget {
  final String title;
  final double amount;
  final String? receiptNo;
  final DateTime? paidAt;
  final String? method;
  final String? transactionRef;
  final List<Widget> children;

  const _ReceiptScaffold({
    required this.title,
    required this.amount,
    required this.receiptNo,
    required this.paidAt,
    required this.method,
    required this.transactionRef,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FA),
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green[600]),
                const SizedBox(height: 12),
                Text(formatInr(amount),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('Paid',
                      style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
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
                  if (receiptNo != null)
                    _Row(icon: Icons.tag, label: 'Receipt no.', value: receiptNo!),
                  if (paidAt != null)
                    _Row(icon: Icons.event_available, label: 'Paid on', value: formatDateTime(paidAt!)),
                  if (method != null)
                    _Row(
                      icon: Icons.account_balance_wallet_outlined,
                      label: 'Payment method',
                      value: method!,
                    ),
                  if (transactionRef != null)
                    _Row(icon: Icons.confirmation_number_outlined, label: 'UPI reference', value: transactionRef!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Row({required this.icon, required this.label, required this.value});

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
