import 'package:flutter/material.dart';
import '../../models/payment.dart';
import '../../utils/currency.dart';

class PaymentDetailScreen extends StatelessWidget {
  final Payment payment;

  const PaymentDetailScreen({super.key, required this.payment});

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isPaid = payment.status == PaymentStatus.paid;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F3FA),
      appBar: AppBar(title: const Text('Payment Details')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                Icon(
                  isPaid ? Icons.check_circle : Icons.hourglass_empty,
                  size: 64,
                  color: isPaid ? Colors.green[600] : Colors.orange[600],
                ),
                const SizedBox(height: 12),
                Text(
                  formatInr(payment.amount),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: isPaid ? Colors.green[50] : Colors.orange[50],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    isPaid ? 'Completed' : 'Pending',
                    style: TextStyle(
                      color: isPaid ? Colors.green[700] : Colors.orange[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DetailRow(icon: Icons.newspaper, label: 'Newspaper', value: payment.newspaperName),
                  _DetailRow(
                    icon: Icons.copy_all,
                    label: 'Copies per delivery',
                    value: '${payment.copiesPerDelivery}',
                  ),
                  _DetailRow(
                    icon: Icons.date_range,
                    label: 'Billing period',
                    value:
                        '${_formatDate(payment.periodStart)} – ${_formatDate(payment.periodEnd)}',
                  ),
                  _DetailRow(
                    icon: Icons.account_balance_wallet_outlined,
                    label: 'Payment method',
                    value: payment.method,
                  ),
                  if (payment.paidAt != null)
                    _DetailRow(
                      icon: Icons.event_available,
                      label: 'Paid on',
                      value: _formatDate(payment.paidAt!),
                    ),
                ],
              ),
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
