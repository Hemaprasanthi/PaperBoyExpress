import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/veggie_data.dart';
import '../../models/produce_item.dart';
import '../../models/veggie_order.dart';
import '../../state/app_state.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency.dart';
import '../common/upi_payment_screen.dart';

class VegetablesScreen extends StatefulWidget {
  const VegetablesScreen({super.key});

  @override
  State<VegetablesScreen> createState() => _VegetablesScreenState();
}

class _VegetablesScreenState extends State<VegetablesScreen> {
  final Map<String, int> _quantities = {};
  ProduceCategory? _filter; // null = show everything

  List<VeggieOrderLine> _lines(List<ProduceItem> catalog) {
    return [
      for (final item in catalog)
        if (item.available && (_quantities[item.id] ?? 0) > 0)
          VeggieOrderLine(
            id: item.id,
            name: item.name,
            unit: item.unit,
            unitPrice: item.price,
            quantity: _quantities[item.id]!,
          ),
    ];
  }

  double _total(List<VeggieOrderLine> lines) => lines.fold(0, (sum, l) => sum + l.total);

  Future<void> _checkout(List<ProduceItem> catalog, String zip, String address) async {
    final lines = _lines(catalog);
    if (lines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to order')),
      );
      return;
    }
    final appState = context.read<AppState>();
    final total = _total(lines);

    final paid = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => UpiPaymentScreen(
          amount: total,
          description: 'Greens & vegetables order',
          onPaid: (ref) => appState.createVeggieOrder(
            lines: lines,
            zipCode: zip,
            address: address,
            transactionRef: ref,
          ),
        ),
      ),
    );
    if (paid != true || !mounted) return;
    setState(_quantities.clear);

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.eco, color: Colors.green[600], size: 48),
        title: const Text('Order placed!'),
        content: const Text(
          'Payment received. Your order is on its way and will reach you in about 15 minutes. '
          'You can find the receipt in the Receipts tab.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final profile = appState.currentCustomerProfile;
    final zip = profile?.zipCode;
    final isEligible = zip == kVeggiePilotZip;

    if (!isEligible) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco_outlined, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Not available in your area yet',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Fresh greens & vegetable delivery is currently piloted only in zip code $kVeggiePilotZip. '
                'We\'ll expand to more areas soon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final catalog = appState.produce;
    final visible = catalog.where((p) => _filter == null || p.category == _filter).toList();
    final lines = _lines(catalog);
    final total = _total(lines);
    final myOrders = appState.veggieOrdersForCustomer(appState.currentUser!.username);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.eco, color: Colors.green[800]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Farm-fresh greens & vegetables, delivered to your door in 15 minutes.',
                  style: TextStyle(color: Colors.green[900], fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final c in ProduceCategory.values)
              ChoiceChip(
                label: Text(c.label),
                selected: _filter == c,
                onSelected: (_) => setState(() => _filter = c),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (!appState.produceLoaded)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (visible.isEmpty)
          Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text('Nothing here yet - check back soon.',
                  style: TextStyle(color: Colors.grey[600])),
            ),
          )
        else
          ...visible.map((item) {
            final qty = _quantities[item.id] ?? 0;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.name,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: item.available ? null : Colors.grey,
                              )),
                          Text(
                            item.available
                                ? '${formatInr(item.price)} / ${item.unit} · ${item.category.label}'
                                : 'Out of stock',
                            style: TextStyle(
                              color: item.available ? Colors.grey[600] : Colors.red[300],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (item.available) ...[
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: qty > 0 ? () => setState(() => _quantities[item.id] = qty - 1) : null,
                      ),
                      Text('$qty', style: const TextStyle(fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                        onPressed: () => setState(() => _quantities[item.id] = qty + 1),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 12),
        if (total > 0)
          Card(
            color: Colors.green.withValues(alpha: 0.06),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total (${lines.length} item${lines.length == 1 ? '' : 's'})',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatInr(total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: total == 0 ? null : () => _checkout(catalog, zip!, profile!.address),
          icon: const Icon(Icons.qr_code_2),
          label: const Text('Pay with UPI'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.all(16),
          ),
        ),
        if (myOrders.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Text('Your orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...myOrders.map((o) => Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                      backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.eco, color: Colors.green)),
                  title: Text(o.itemsSummary, style: const TextStyle(fontSize: 13)),
                  subtitle: Text('Delivery by ${formatDateTime(o.expectedDeliveryBy)}',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  trailing: Text(formatInr(o.totalAmount),
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              )),
        ],
      ],
    );
  }
}
