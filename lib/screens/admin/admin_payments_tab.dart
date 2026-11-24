import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart';
import '../../state/app_state.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency.dart';

/// Every UPI payment across newspapers and greens, newest first.
class AdminPaymentsTab extends StatelessWidget {
  const AdminPaymentsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final customerNames = {for (final c in appState.customers) c.uid: c.name};

    final rows = <({DateTime when, String title, String subtitle, double amount, bool greens})>[
      for (final Payment p in appState.payments.where((p) => p.status == PaymentStatus.paid))
        (
          when: p.paidAt ?? p.createdAt,
          title: '${customerNames[p.customerUsername] ?? p.customerUsername} · ${p.newspaperName}',
          subtitle: '${formatDate(p.periodStart)} – ${formatDate(p.periodEnd)}\n'
              '${p.receiptNo ?? ''} · ${p.method ?? ''} ${p.transactionRef ?? ''}',
          amount: p.totalAmount,
          greens: false,
        ),
      for (final o in appState.veggieOrders.where((o) => o.paidAt != null))
        (
          when: o.paidAt!,
          title: '${o.customerName ?? o.customerUsername} · Greens & vegetables',
          subtitle: '${o.itemsSummary}\n'
              '${o.receiptNo ?? ''} · ${o.paymentMethod ?? ''} ${o.transactionRef ?? ''}',
          amount: o.totalAmount,
          greens: true,
        ),
    ]..sort((a, b) => b.when.compareTo(a.when));

    if (rows.isEmpty) {
      return const Center(child: Text('No payments yet.'));
    }

    final total = rows.fold<double>(0, (sum, r) => sum + r.amount);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: Colors.green.withValues(alpha: 0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Total collected (${rows.length} payments)',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(formatInr(total),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
        ),
        for (final r in rows)
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green[50],
                child: Icon(r.greens ? Icons.eco : Icons.newspaper, color: Colors.green[700]),
              ),
              title: Text(r.title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: Text('${formatDateTime(r.when)}\n${r.subtitle}',
                  style: const TextStyle(fontSize: 12)),
              isThreeLine: true,
              trailing: Text(formatInr(r.amount), style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}
