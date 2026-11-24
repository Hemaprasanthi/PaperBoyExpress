import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/newspaper.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';
import '../../utils/app_constants.dart';
import '../../widgets/status_badge.dart';

class AdminSubscriptionEditScreen extends StatefulWidget {
  final Subscription subscription;

  const AdminSubscriptionEditScreen({super.key, required this.subscription});

  @override
  State<AdminSubscriptionEditScreen> createState() => _AdminSubscriptionEditScreenState();
}

class _AdminSubscriptionEditScreenState extends State<AdminSubscriptionEditScreen> {
  late String _selectedId;
  late Set<int> _selectedDays;
  late int _copiesPerDelivery;
  late DateTime _startDate;
  late DateTime _endDate;
  late TextEditingController _addressController;
  String? _selectedDeliveryBoy;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.subscription;
    _selectedId = s.newspaper.id;
    _selectedDays = {...s.selectedWeekdays};
    _copiesPerDelivery = s.copiesPerDelivery;
    _startDate = s.startDate;
    _endDate = s.endDate ?? s.startDate.add(const Duration(days: 30));
    _addressController = TextEditingController(text: s.address);
    _selectedDeliveryBoy = s.assignedDeliveryBoy;
  }

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      _startDate = picked;
      if (_endDate.isBefore(picked)) _endDate = picked;
    });
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 1095)),
    );
    if (picked != null) setState(() => _endDate = picked);
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
      newspaperId: _selectedId,
      selectedWeekdays: _selectedDays.toList(),
      copiesPerDelivery: _copiesPerDelivery,
      address: _addressController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
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

  Future<void> _setPause() async {
    final today = dateOnly(DateTime.now());
    final range = await showDateRangePicker(
      context: context,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Pause delivery (max $kMaxPauseDays days)',
      saveText: 'Pause',
    );
    if (range == null || !mounted) return;
    final error = await context
        .read<AppState>()
        .pauseSubscription(widget.subscription.id, range.start, range.end);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Pause saved')),
    );
  }

  Future<void> _deleteSubscription() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete this subscription?'),
        content: const Text(
          'This permanently removes the subscription. The customer\'s receipt is kept.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AppState>().deleteSubscription(widget.subscription.id);
    if (!mounted) return;
    Navigator.of(context).pop();
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
    final hasPause = isActive && current.hasPauseScheduledOrActive;

    // Keep the dropdown valid even if the newspaper was removed from the catalog.
    final newspaperItems = <Newspaper>[
      ...newspapers,
      if (!newspapers.any((n) => n.id == current.newspaper.id)) current.newspaper,
    ];

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
              SubscriptionStatusBadge(subscription: current),
            ],
          ),
          if (current.customerPhone != null)
            Text(current.customerPhone!, style: TextStyle(color: Colors.grey[600])),
          const Divider(height: 32),
          const Text('Newspaper', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedId,
            decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
            items: newspaperItems
                .map((n) => DropdownMenuItem(value: n.id, child: Text(n.name)))
                .toList(),
            onChanged: (v) => setState(() => _selectedId = v!),
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
          const Text('Start and end date', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickStartDate,
                  icon: const Icon(Icons.calendar_today, size: 18),
                  label: Text(formatDate(_startDate)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEndDate,
                  icon: const Icon(Icons.event, size: 18),
                  label: Text(formatDate(_endDate)),
                  style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ],
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
          const Divider(height: 32),
          const Text('Pause', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          if (hasPause) ...[
            Text(
              '${formatDate(current.pausedFrom!)} - ${formatDate(current.pausedUntil!)}',
              style: TextStyle(color: Colors.blue[800]),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => context.read<AppState>().resumeSubscription(current.id),
              icon: const Icon(Icons.play_circle_outline),
              label: const Text('Remove pause'),
            ),
          ] else
            OutlinedButton.icon(
              onPressed: isActive ? _setPause : null,
              icon: const Icon(Icons.pause_circle_outline),
              label: const Text('Pause deliveries (up to 1 month)'),
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
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _deleteSubscription,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete Subscription'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.all(16),
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
