import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/veggie_data.dart';
import '../../state/app_state.dart';
import '../../utils/currency.dart';

class VegetablesScreen extends StatefulWidget {
  const VegetablesScreen({super.key});

  @override
  State<VegetablesScreen> createState() => _VegetablesScreenState();
}

class _VegetablesScreenState extends State<VegetablesScreen> {
  final Map<String, int> _quantities = {};
  bool _placing = false;

  double get _total {
    double sum = 0;
    for (final v in kVeggies) {
      sum += (_quantities[v.id] ?? 0) * v.pricePerBundle;
    }
    return sum;
  }

  Future<void> _placeOrder(String zip, String address) async {
    final items = {..._quantities}..removeWhere((_, qty) => qty == 0);
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one item to order')),
      );
      return;
    }

    setState(() => _placing = true);
    await context.read<AppState>().createVeggieOrder(
          items: items,
          totalAmount: _total,
          zipCode: zip,
          address: address,
        );
    if (!mounted) return;
    setState(() {
      _placing = false;
      _quantities.clear();
    });

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(Icons.eco, color: Colors.green[600], size: 48),
        title: const Text('Order placed!'),
        content: const Text(
          'Your greens are on their way and will reach you in about 15 minutes.',
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          FilledButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour == 0 ? 12 : (d.hour > 12 ? d.hour - 12 : d.hour);
    final ampm = d.hour >= 12 ? 'PM' : 'AM';
    return '${d.day} ${months[d.month - 1]}, $hour:${d.minute.toString().padLeft(2, '0')} $ampm';
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
                'Fresh greens delivery is currently piloted only in zip code $kVeggiePilotZip. '
                'We\'ll expand to more areas soon.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

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
                  'Farm-fresh greens, delivered to your door in 15 minutes.',
                  style: TextStyle(color: Colors.green[900], fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text('Choose your greens', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        ...kVeggies.map((v) {
          final qty = _quantities[v.id] ?? 0;
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withOpacity(0.15)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(v.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${formatInr(v.pricePerBundle)} / bundle',
                            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: qty > 0 ? () => setState(() => _quantities[v.id] = qty - 1) : null,
                  ),
                  Text('$qty', style: const TextStyle(fontSize: 16)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                    onPressed: () => setState(() => _quantities[v.id] = qty + 1),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        if (_total > 0)
          Card(
            elevation: 0,
            color: Colors.green.withOpacity(0.06),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(formatInr(_total),
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: _placing || _total == 0 ? null : () => _placeOrder(zip!, profile!.address),
          icon: _placing
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.shopping_basket_outlined),
          label: Text(_placing ? 'Placing order...' : 'Place Order'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green[700],
            padding: const EdgeInsets.all(16),
          ),
        ),
        if (myOrders.isNotEmpty) ...[
          const SizedBox(height: 28),
          const Text('Your greens orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          ...myOrders.map((o) {
            final itemsLabel = o.items.entries
                .map((e) => '${kVeggies.firstWhere((v) => v.id == e.key).name} x${e.value}')
                .join(', ');
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.withOpacity(0.15)),
              ),
              child: ListTile(
                leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9), child: Icon(Icons.eco, color: Colors.green)),
                title: Text(itemsLabel, style: const TextStyle(fontSize: 13)),
                subtitle: Text('Delivery by ${_formatDateTime(o.expectedDeliveryBy)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                trailing: Text(formatInr(o.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            );
          }),
        ],
      ],
    );
  }
}
