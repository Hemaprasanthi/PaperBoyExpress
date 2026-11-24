import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart';
import '../../state/app_state.dart';
import '../../utils/currency.dart';
import 'payment_detail_screen.dart';
import 'pay_payment_screen.dart';

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.currentUser == null) {
      return const SizedBox.shrink();
    }
    final payments = appState.paymentsForCustomer(appState.currentUser!.username);

    final pending = payments.where((p) => p.status == PaymentStatus.pending).toList();
    final paid = payments.where((p) => p.status == PaymentStatus.paid).toList();

    final now = DateTime.now();
    final dueSoon = pending.where((p) => p.periodEnd.difference(now).inDays <= 5).toList();

    if (payments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('No payments yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(
                'Once you subscribe to a newspaper, your payments will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (dueSoon.isNotEmpty) ...[
          _ReminderBanner(payments: dueSoon),
          const SizedBox(height: 16),
        ],
        if (pending.isNotEmpty) ...[
          _SectionHeader(title: 'Pending', count: pending.length, color: Colors.orange),
          const SizedBox(height: 8),
          ...pending.map((p) => _PaymentCard(payment: p)),
          const SizedBox(height: 24),
        ],
        _SectionHeader(title: 'Payment History', count: paid.length, color: Colors.green),
        const SizedBox(height: 8),
        if (paid.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('No completed payments yet.', style: TextStyle(color: Colors.grey[600])),
          )
        else
          ...paid.map((p) => _PaymentCard(payment: p)),
      ],
    );
  }
}

class _ReminderBanner extends StatelessWidget {
  final List<Payment> payments;

  const _ReminderBanner({required this.payments});

  @override
  Widget build(BuildContext context) {
    final total = payments.fold<double>(0, (sum, p) => sum + p.totalAmount);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.notifications_active, color: Colors.orange[800]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              payments.length == 1
                  ? 'Your payment of ${formatInr(total)} is due soon. Pay before the month ends.'
                  : '${payments.length} payments totalling ${formatInr(total)} are due soon.',
              style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color color;

  const _SectionHeader({required this.title, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('$count', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
      ],
    );
  }
}

class _PaymentCard extends StatelessWidget {
  final Payment payment;

  const _PaymentCard({required this.payment});

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
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => PaymentDetailScreen(payment: payment)),
              );
            },
            leading: CircleAvatar(
              backgroundColor: isPaid ? Colors.green[50] : Colors.orange[50],
              child: Icon(
                isPaid ? Icons.check_circle_outline : Icons.hourglass_empty,
                color: isPaid ? Colors.green[700] : Colors.orange[700],
              ),
            ),
            title: Text(payment.newspaperName, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${_formatDate(payment.periodStart)} – ${_formatDate(payment.periodEnd)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(formatInr(payment.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  isPaid ? 'Completed' : 'Pending',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: isPaid ? Colors.green[700] : Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          if (!isPaid)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PayPaymentScreen(payment: payment)),
                    );
                  },
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 18),
                  label: const Text('Pay Now'),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFF5F259F)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
