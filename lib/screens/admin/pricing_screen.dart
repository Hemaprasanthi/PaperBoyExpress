import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../utils/currency.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});

  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  final _zipController = TextEditingController();
  String? _selectedNewspaperId;
  final _overridePriceController = TextEditingController();

  Future<void> _editBasePrice(BuildContext context, String newspaperId, double current) async {
    final controller = TextEditingController(text: current.toStringAsFixed(2));
    final newPrice = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Set base price'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(prefixText: '₹ ', border: OutlineInputBorder()),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final parsed = double.tryParse(controller.text.trim());
              Navigator.pop(context, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newPrice != null && newPrice >= 0) {
      await context.read<AppState>().setBasePrice(newspaperId, newPrice);
    }
  }

  Future<void> _addZipOverride() async {
    final zip = _zipController.text.trim();
    final price = double.tryParse(_overridePriceController.text.trim());
    if (zip.isEmpty || _selectedNewspaperId == null || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a zip code, newspaper, and valid price')),
      );
      return;
    }
    await context.read<AppState>().setZipPrice(_selectedNewspaperId!, zip, price);
    _zipController.clear();
    _overridePriceController.clear();
    setState(() => _selectedNewspaperId = null);
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final newspapers = appState.newspapers;

    // Collect all zip overrides across every newspaper, grouped by zip.
    final Map<String, List<MapEntry<String, double>>> byZip = {};
    for (final n in newspapers) {
      final overrides = appState.zipOverridesFor(n.id);
      for (final entry in overrides.entries) {
        byZip.putIfAbsent(entry.key, () => []).add(MapEntry(n.id, entry.value));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Base prices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          'Default price per copy for each newspaper, used everywhere a zip-specific price isn\'t set.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...newspapers.map((n) {
          final price = appState.basePriceFor(n.id);
          return Card(
            child: ListTile(
              title: Text(n.name),
              trailing: TextButton(
                onPressed: () => _editBasePrice(context, n.id, price),
                child: Text(
                  formatInr(price),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          );
        }),
        const Divider(height: 40),
        const Text('Zip code overrides', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(
          'Set a different price for a specific zip code. Leave a newspaper without an '
          'override and it uses the base price above.',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _zipController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Zip code',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedNewspaperId,
                  decoration: const InputDecoration(
                    labelText: 'Newspaper',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: newspapers
                      .map((n) => DropdownMenuItem(value: n.id, child: Text(n.name)))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedNewspaperId = v),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _overridePriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Price for this zip',
                    prefixText: '₹ ',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _addZipOverride,
                  icon: const Icon(Icons.add),
                  label: const Text('Add / Update Override'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        if (byZip.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('No zip-specific prices set yet.', style: TextStyle(color: Colors.grey[600])),
          )
        else
          ...byZip.entries.map((zipEntry) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Zip: ${zipEntry.key}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...zipEntry.value.map((e) {
                      final newspaperName =
                          newspapers.firstWhere((n) => n.id == e.key).name;
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(child: Text(newspaperName)),
                            Text(
                              formatInr(e.value),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => context
                                  .read<AppState>()
                                  .removeZipPrice(e.key, zipEntry.key),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}
