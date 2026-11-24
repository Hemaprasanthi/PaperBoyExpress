import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/newspaper.dart';
import '../../models/produce_item.dart';
import '../../state/app_state.dart';
import '../../utils/currency.dart';

/// Admin catalog management: add, edit, price and delete newspapers and
/// greens & vegetables.
class AdminCatalogScreen extends StatelessWidget {
  const AdminCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const DefaultTabController(
      length: 2,
      child: Column(
        children: [
          TabBar(
            tabs: [
              Tab(text: 'Newspapers', icon: Icon(Icons.newspaper)),
              Tab(text: 'Greens & Veg', icon: Icon(Icons.eco_outlined)),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [_NewspaperCatalog(), _ProduceCatalog()],
            ),
          ),
        ],
      ),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String title, String message) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed == true;
}

// ---------- Newspapers ----------

class _NewspaperCatalog extends StatelessWidget {
  const _NewspaperCatalog();

  Future<void> _edit(BuildContext context, {Newspaper? existing}) async {
    final appState = context.read<AppState>();
    final result = await showDialog<({String name, double price})>(
      context: context,
      builder: (_) => _NewspaperDialog(
        existing: existing,
        initialPrice: existing == null ? null : appState.basePriceFor(existing.id),
      ),
    );
    if (result == null) return;
    if (existing == null) {
      await appState.addNewspaper(result.name, result.price);
    } else {
      await appState.updateNewspaper(existing.id, name: result.name, price: result.price);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final newspapers = appState.newspapers;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_newspaper',
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Add newspaper'),
      ),
      body: !appState.newspapersLoaded
          ? const Center(child: CircularProgressIndicator())
          : newspapers.isEmpty
              ? const Center(child: Text('No newspapers in the catalog.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  children: [
                    for (final n in newspapers)
                      Card(
                        child: ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.newspaper)),
                          title: Text(n.name),
                          subtitle: Text('${formatInr(appState.basePriceFor(n.id))} / copy'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined),
                                tooltip: 'Edit',
                                onPressed: () => _edit(context, existing: n),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Delete',
                                onPressed: () async {
                                  final ok = await _confirmDelete(
                                    context,
                                    'Delete ${n.name}?',
                                    'It will no longer be offered to customers. Existing '
                                        'subscriptions keep their name and price.',
                                  );
                                  if (ok) await appState.deleteNewspaper(n.id);
                                },
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

class _NewspaperDialog extends StatefulWidget {
  final Newspaper? existing;
  final double? initialPrice;

  const _NewspaperDialog({this.existing, this.initialPrice});

  @override
  State<_NewspaperDialog> createState() => _NewspaperDialogState();
}

class _NewspaperDialogState extends State<_NewspaperDialog> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _price = TextEditingController(
        text: widget.initialPrice == null ? '' : widget.initialPrice!.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add newspaper' : 'Edit newspaper'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price per copy', prefixText: '₹ '),
              validator: (v) {
                final p = double.tryParse((v ?? '').trim());
                return (p == null || p < 0) ? 'Enter a valid price' : null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, (name: _name.text.trim(), price: double.parse(_price.text.trim())));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

// ---------- Greens & vegetables ----------

class _ProduceCatalog extends StatelessWidget {
  const _ProduceCatalog();

  Future<void> _edit(BuildContext context, {ProduceItem? existing}) async {
    final appState = context.read<AppState>();
    final result = await showDialog<ProduceItem>(
      context: context,
      builder: (_) => _ProduceDialog(existing: existing),
    );
    if (result == null) return;
    if (existing == null) {
      await appState.addProduce(result);
    } else {
      await appState.updateProduce(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final items = appState.produce;

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_produce',
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Add item'),
      ),
      body: !appState.produceLoaded
          ? const Center(child: CircularProgressIndicator())
          : items.isEmpty
              ? const Center(child: Text('No greens or vegetables in the catalog.'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
                  children: [
                    for (final category in ProduceCategory.values) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
                        child: Text(category.label,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                      for (final item in items.where((i) => i.category == category))
                        Card(
                          child: ListTile(
                            title: Text(item.name),
                            subtitle: Text(
                              '${formatInr(item.price)} / ${item.unit}'
                              '${item.available ? '' : ' · Out of stock'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Switch(
                                  value: item.available,
                                  onChanged: (v) => appState.updateProduce(ProduceItem(
                                    id: item.id,
                                    name: item.name,
                                    category: item.category,
                                    unit: item.unit,
                                    price: item.price,
                                    available: v,
                                  )),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined),
                                  tooltip: 'Edit',
                                  onPressed: () => _edit(context, existing: item),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Delete',
                                  onPressed: () async {
                                    final ok = await _confirmDelete(
                                      context,
                                      'Delete ${item.name}?',
                                      'It will be removed from the catalog.',
                                    );
                                    if (ok) await appState.deleteProduce(item.id);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
    );
  }
}

class _ProduceDialog extends StatefulWidget {
  final ProduceItem? existing;

  const _ProduceDialog({this.existing});

  @override
  State<_ProduceDialog> createState() => _ProduceDialogState();
}

class _ProduceDialogState extends State<_ProduceDialog> {
  late final TextEditingController _name;
  late final TextEditingController _unit;
  late final TextEditingController _price;
  late ProduceCategory _category;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _unit = TextEditingController(text: e?.unit ?? 'kg');
    _price = TextEditingController(text: e == null ? '' : e.price.toStringAsFixed(2));
    _category = e?.category ?? ProduceCategory.vegetables;
  }

  @override
  void dispose() {
    _name.dispose();
    _unit.dispose();
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'Add item' : 'Edit item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ProduceCategory>(
                value: _category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: ProduceCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _unit,
                decoration: const InputDecoration(labelText: 'Unit (e.g. kg, bundle, piece)'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a unit' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _price,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Price per unit', prefixText: '₹ '),
                validator: (v) {
                  final p = double.tryParse((v ?? '').trim());
                  return (p == null || p < 0) ? 'Enter a valid price' : null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              ProduceItem(
                id: widget.existing?.id ?? '',
                name: _name.text.trim(),
                category: _category,
                unit: _unit.text.trim(),
                price: double.parse(_price.text.trim()),
                available: widget.existing?.available ?? true,
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
