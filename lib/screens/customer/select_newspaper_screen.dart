import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/newspaper.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';
import '../../utils/currency.dart';
import 'checkout_screen.dart';

class SelectNewspaperScreen extends StatefulWidget {
  const SelectNewspaperScreen({super.key});

  @override
  State<SelectNewspaperScreen> createState() => _SelectNewspaperScreenState();
}

class _SelectNewspaperScreenState extends State<SelectNewspaperScreen> {
  Newspaper? _selected;
  final Set<int> _selectedDays = {}; // DateTime.monday..sunday
  int _copiesPerDelivery = 1;
  DateTime? _startDate;
  final _addressController = TextEditingController();
  final _zipController = TextEditingController();

  double get _estimatedMonthly {
    if (_selected == null || _selectedDays.isEmpty) return 0;
    final appState = context.read<AppState>();
    final zip = _zipController.text.trim();
    final price = appState.priceFor(_selected!.id, zip: zip.isEmpty ? null : zip);
    return price * _copiesPerDelivery * _selectedDays.length * 4.33;
  }

  bool get _canContinue =>
      _selected != null &&
      _selectedDays.isNotEmpty &&
      _startDate != null &&
      _addressController.text.trim().isNotEmpty;

  Future<void> _pickStartDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill address and zip code from the customer's saved profile.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final profile = context.read<AppState>().currentCustomerProfile;
      if (profile != null) {
        setState(() {
          if (_addressController.text.isEmpty) _addressController.text = profile.address;
          if (_zipController.text.isEmpty) _zipController.text = profile.zipCode;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final newspapers = context.watch<AppState>().newspapers;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Newspaper')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('1. Pick a newspaper', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...newspapers.map(
            (n) => RadioListTile<Newspaper>(
              value: n,
              groupValue: _selected,
              onChanged: (v) => setState(() => _selected = v),
              title: Text(n.name),
              subtitle: Text(
                '${formatInr(context.watch<AppState>().priceFor(n.id, zip: _zipController.text.trim().isEmpty ? null : _zipController.text.trim()))} / copy',
              ),
              dense: true,
            ),
          ),
          const Divider(height: 32),
          const Text('2. Which days should it be delivered?',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kWeekdayLabels.entries.map((entry) {
              final dayValue = entry.key;
              final label = entry.value;
              final selected = _selectedDays.contains(dayValue);
              return FilterChip(
                label: Text(label),
                selected: selected,
                onSelected: (isSelected) {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.add(dayValue);
                    } else {
                      _selectedDays.remove(dayValue);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedDays.isEmpty
                ? 'Pick at least one day'
                : '${_selectedDays.length} day(s) a week',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const Divider(height: 32),
          const Text('3. Copies per delivery', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _copiesPerDelivery > 1
                    ? () => setState(() => _copiesPerDelivery--)
                    : null,
              ),
              Text('$_copiesPerDelivery', style: const TextStyle(fontSize: 20)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _copiesPerDelivery < 10
                    ? () => setState(() => _copiesPerDelivery++)
                    : null,
              ),
            ],
          ),
          const Divider(height: 32),
          const Text('4. Start date', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickStartDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(
              _startDate == null ? 'Choose a start date' : _formatDate(_startDate!),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.centerLeft,
            ),
          ),
          const Divider(height: 32),
          const Text('5. Delivery address', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'e.g. 123 Main St, Apt 4B, Springfield',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _zipController,
            keyboardType: TextInputType.number,
            onChanged: (_) => setState(() {}), // pricing may change with zip
            decoration: const InputDecoration(
              labelText: 'Zip code (optional - pricing may vary by area)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          if (_selected != null && _selectedDays.isNotEmpty)
            Card(
              color: Colors.indigo.withOpacity(0.06),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated monthly cost'),
                    Text(
                      formatInr(_estimatedMonthly),
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _canContinue
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CheckoutScreen(
                          newspaper: _selected!,
                          selectedWeekdays: _selectedDays.toList(),
                          copiesPerDelivery: _copiesPerDelivery,
                          address: _addressController.text.trim(),
                          startDate: _startDate!,
                          zipCode: _zipController.text.trim().isEmpty
                              ? null
                              : _zipController.text.trim(),
                        ),
                      ),
                    );
                  }
                : null,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }
}
