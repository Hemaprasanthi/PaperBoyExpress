import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/newspaper.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';

class AdminSubscriptionEditScreen extends StatefulWidget {
  final Subscription subscription;

  const AdminSubscriptionEditScreen({super.key, required this.subscription});

  @override
  State<AdminSubscriptionEditScreen> createState() => _AdminSubscriptionEditScreenState();
}

class _AdminSubscriptionEditScreenState extends State<AdminSubscriptionEditScreen> {
  late Newspaper _selected;
  late Set<int> _selectedDays;
  late int _copiesPerDelivery;
  late DateTime _startDate;
  late TextEditingController _addressController;
  String? _selectedDeliveryBoy;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.subscription;
    _selected = s.newspaper;
    _selectedDays = {...s.selectedWeekdays};
    _copiesPerDelivery = s.copiesPerDelivery;
    _startDate = s.startDate;
    _addressController = TextEditingController(text: s.address);
    _selectedDeliveryBoy = s.assignedDeliveryBoy;
  }

  String _formatDate(DateTime d) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _save() async {
    if (_selectedDays.isEmpty || _addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one day and enter an address')),
      );
      return;
    }

    setState(() => _saving = true);
    final appState = context.read<AppState>();

    await appState.adminUpdateSubscription(
      widget.subscription.id,
      newspaperId: _selected.id,
      selectedWeekdays: _selectedDays.toList(),
      copiesPerDelivery: _copiesPerDelivery,
      address: _addressController.text.trim(),
      startDate: _startDate,
    );

    if (_selectedDeliveryBoy != widget.subscription.assignedDeliveryBoy) {
      if (_selectedDeliveryBoy == null) {
        await appState.unassignDelivery(widget.subscription.id);
      } else {
        await appState.assignDelivery(widget.subscription.id, _selectedDeliveryBoy!);
      }
    }

    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription updated')),
    );
    Navigator.of(context).pop();
  }

  Future<void> _approve() async {
    setState(() => _saving = true);
    await context.read<AppState>().approveSubscription(widget.subscription.id);
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subscription approved - customer notified')),
    );
  }

  Future<void> _toggleStatus(SubscriptionStatus current) async {
    final appState = context.read<AppState>();
    if (current == SubscriptionStatus.active) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Cancel this subscription?'),
          content: const Text('This marks the subscription as cancelled for the customer.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Cancel subscription'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await appState.cancelSubscription(widget.subscription.id);
        if (mounted) setState(() {});
      }
    } else {
      await appState.reactivateSubscription(widget.subscription.id);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final newspapers = appState.newspapers;
    final deliveryBoys = appState.deliveryBoys;
    // Re-read the live subscription so status reflects any change immediately.
    final current = appState.subscriptions.firstWhere(
      (s) => s.id == widget.subscription.id,
      orElse: () => widget.subscription,
    );
    final isActive = current.status == SubscriptionStatus.active;
    final isPending = current.status == SubscriptionStatus.pendingApproval;
    final statusLabel = isPending ? 'Pending Approval' : (isActive ? 'Active' : 'Cancelled');
    final statusColor = isPending ? Colors.orange : (isActive ? Colors.green : Colors.grey);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Subscription')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  current.customerName ?? current.customerUsername,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              Chip(
                label: Text(statusLabel),
                backgroundColor: statusColor.withOpacity(0.15),
              ),
            ],
          ),
          if (current.customerPhone != null)
            Text(current.customerPhone!, style: TextStyle(color: Colors.grey[600])),
          const Divider(height: 32),
          const Text('Newspaper', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<Newspaper>(
            value: _selected,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            items: newspapers
                .map((n) => DropdownMenuItem(value: n, child: Text(n.name)))
                .toList(),
            onChanged: (v) => setState(() => _selected = v!),
          ),
          const Divider(height: 32),
          const Text('Delivery days', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: kWeekdayLabels.entries.map((entry) {
              final selected = _selectedDays.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (v) => setState(() {
                  if (v) {
                    _selectedDays.add(entry.key);
                  } else {
                    _selectedDays.remove(entry.key);
                  }
                }),
              );
            }).toList(),
          ),
          const Divider(height: 32),
          const Text('Copies per delivery', style: TextStyle(fontWeight: FontWeight.bold)),
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
          const Text('Start date', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickStartDate,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_formatDate(_startDate)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.centerLeft,
            ),
          ),
          const Divider(height: 32),
          const Text('Address', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const Divider(height: 32),
          const Text('Assigned delivery', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _selectedDeliveryBoy,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            items: [
              const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
              ...deliveryBoys.map((d) => DropdownMenuItem<String?>(value: d, child: Text(d))),
            ],
            onChanged: (v) => setState(() => _selectedDeliveryBoy = v),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? 'Saving...' : 'Save Changes'),
            style: FilledButton.styleFrom(padding: const EdgeInsets.all(16)),
          ),
          const SizedBox(height: 12),
          if (isPending)
            FilledButton.icon(
              onPressed: _saving ? null : _approve,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Approve Subscription'),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green[700],
                padding: const EdgeInsets.all(16),
              ),
            )
          else
            OutlinedButton.icon(
              onPressed: () => _toggleStatus(current.status),
              icon: Icon(isActive ? Icons.cancel_outlined : Icons.replay),
              label: Text(isActive ? 'Cancel Subscription' : 'Reactivate Subscription'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                foregroundColor: isActive ? Colors.red : Colors.green[700],
              ),
            ),
        ],
      ),
    );
  }
}
