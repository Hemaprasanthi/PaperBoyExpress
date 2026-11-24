import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/newspaper.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency.dart';
import 'checkout_screen.dart';

class SelectNewspaperScreen extends StatefulWidget {
  const SelectNewspaperScreen({super.key});

  @override
  State<SelectNewspaperScreen> createState() => _SelectNewspaperScreenState();
}

class _SelectNewspaperScreenState extends State<SelectNewspaperScreen> {
  String? _selectedId;
  final Set<int> _selectedDays = {}; // DateTime.monday..sunday
  int _copiesPerDelivery = 1;
  DateTime? _startDate;
  DateTime? _endDate;
  final _addressController = TextEditingController();
  final _zipController = TextEditingController();

  DateTime get _tomorrow {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  String? get _zip => _zipController.text.trim().isEmpty ? null : _zipController.text.trim();

  int get _deliveryCount => (_startDate == null || _endDate == null)
      ? 0
      : countDeliveries(_startDate!, _endDate!, _selectedDays);

  double _estimatedPaper(AppState appState) {
    if (_selectedId == null) return 0;
    return appState.priceFor(_selectedId!, zip: _zip) * _copiesPerDelivery * _deliveryCount;
  }

  bool get _canContinue =>
      _selectedId != null &&
      _selectedDays.isNotEmpty &&
      _startDate != null &&
      _endDate != null &&
      _deliveryCount > 0 &&
      _addressController.text.trim().isNotEmpty;

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? _tomorrow,
      firstDate: _tomorrow,
      lastDate: _tomorrow.add(const Duration(days: 365)),
      helpText: 'Start date (from tomorrow)',
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
    });
  }

  Future<void> _pickEndDate() async {
    final start = _startDate;
    if (start == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose a start date first')),
      );
      return;
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? start.add(const Duration(days: 29)),
      firstDate: start,
      lastDate: start.add(const Duration(days: 730)),
      helpText: 'End date',
    );
    if (picked != null) setState(() => _endDate = picked);
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
  void dispose() {
    _addressController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final newspapers = appState.newspapers;

    return Scaffold(
      appBar: AppBar(title: const Text('Choose Your Newspaper')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('1. Pick a newspaper', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (!appState.newspapersLoaded)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (newspapers.isEmpty)
            Text('No newspapers are available right now.', style: TextStyle(color: Colors.grey[600]))
          else
            ...newspapers.map(
              (Newspaper n) => RadioListTile<String>(
                value: n.id,
                groupValue: _selectedId,
                onChanged: (v) => setState(() => _selectedId = v),
                title: Text(n.name),
                subtitle: Text('${formatInr(appState.priceFor(n.id, zip: _zip))} / copy'),
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
              final selected = _selectedDays.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (isSelected) {
                  setState(() {
                    if (isSelected) {
                      _selectedDays.add(entry.key);
                    } else {
                      _selectedDays.remove(entry.key);
                    }
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedDays.isEmpty ? 'Pick at least one day' : '${_selectedDays.length} day(s) a week',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const Divider(height: 32),
          const Text('3. Copies per delivery', style: TextStyle(fontWeight: FontWeight.bold)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _copiesPerDelivery > 1 ? () => setState(() => _copiesPerDelivery--) : null,
              ),
              Text('$_copiesPerDelivery', style: const TextStyle(fontSize: 20)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: _copiesPerDelivery < 10 ? () => setState(() => _copiesPerDelivery++) : null,
              ),
            ],
          ),
          const Divider(height: 32),
          const Text('4. Start and end date', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Deliveries can start from tomorrow.', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(_startDate == null ? 'Start date' : formatDate(_startDate!)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEndDate,
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(_endDate == null ? 'End date' : formatDate(_endDate!)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
          ),
          if (_startDate != null && _endDate != null && _selectedDays.isNotEmpty && _deliveryCount == 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'None of the selected days fall between these dates.',
                style: TextStyle(color: Colors.red[700], fontSize: 12),
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
          if (_selectedId != null && _deliveryCount > 0)
            Card(
              color: Colors.indigo.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Paper charges ($_deliveryCount deliveries)'),
                    Text(
                      formatInr(_estimatedPaper(appState)),
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
                          newspaper: newspapers.firstWhere((n) => n.id == _selectedId),
                          selectedWeekdays: _selectedDays.toList(),
                          copiesPerDelivery: _copiesPerDelivery,
                          address: _addressController.text.trim(),
                          startDate: _startDate!,
                          endDate: _endDate!,
                          zipCode: _zip,
                        ),
                      ),
                    );
                  }
                : null,
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
            child: const Text('Continue to payment'),
          ),
        ],
      ),
    );
  }
}
