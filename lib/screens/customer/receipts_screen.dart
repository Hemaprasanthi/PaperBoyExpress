import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/payment.dart';
import '../../models/veggie_order.dart';
import '../../state/app_state.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency.dart';
import 'receipt_detail_screens.dart';

/// Paid receipts, split into newspaper and greens & vegetables sub tabs.
class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    if (appState.currentUser == null) return const SizedBox.shrink();
    final username = appState.currentUser!.username;
    final newspaperReceipts = appState.receiptsForCustomer(username);
    final greensReceipts =
        appState.veggieOrdersForCustomer(username).where((o) => o.paidAt != null).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            tabs: [
              Tab(text: 'Newspapers', icon: Icon(Icons.newspaper)),
              Tab(text: 'Greens & Veg', icon: Icon(Icons.eco_outlined)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _ReceiptList(
                  emptyText: 'Receipts for your newspaper subscriptions will show up here.',
                  children: newspaperReceipts.map((p) => _NewspaperReceiptTile(payment: p)).toList(),
                ),
                _ReceiptList(
                  emptyText: 'Receipts for your greens & vegetable orders will show up here.',
                  children: greensReceipts.map((o) => _GreensReceiptTile(order: o)).toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ReceiptList extends StatelessWidget {
  final String emptyText;
  final List<Widget> children;

  const _ReceiptList({required this.emptyText, required this.children});

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text('No receipts yet',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(emptyText, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }
    return ListView(padding: const EdgeInsets.all(12), children: children);
  }
}

class _NewspaperReceiptTile extends StatelessWidget {
  final Payment payment;

  const _NewspaperReceiptTile({required this.payment});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => NewspaperReceiptScreen(payment: payment)),
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.green[50],
          child: Icon(Icons.receipt_long, color: Colors.green[700]),
        ),
        title: Text(payment.newspaperName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${formatDate(payment.periodStart)} – ${formatDate(payment.periodEnd)}\n'
          '${payment.receiptNo ?? 'Receipt'}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Text(formatInr(payment.totalAmount),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _GreensReceiptTile extends StatelessWidget {
  final VeggieOrder order;

  const _GreensReceiptTile({required this.order});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => GreensReceiptScreen(order: order)),
        ),
        leading: CircleAvatar(
          backgroundColor: Colors.green[50],
          child: Icon(Icons.eco, color: Colors.green[700]),
        ),
        title: Text(order.itemsSummary,
            maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
        subtitle: Text(
          '${formatDateTime(order.orderedAt)}\n${order.receiptNo ?? 'Receipt'}',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
        isThreeLine: true,
        trailing: Text(formatInr(order.totalAmount),
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
