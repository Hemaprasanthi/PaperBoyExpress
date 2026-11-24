import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/customer_profile.dart';
import '../../state/app_state.dart';

/// Admin view of all customers: edit their details or delete them.
class AdminUsersTab extends StatelessWidget {
  const AdminUsersTab({super.key});

  Future<void> _edit(BuildContext context, CustomerProfile c) async {
    final appState = context.read<AppState>();
    final result = await showDialog<({String name, String address, String zip, String phone})>(
      context: context,
      builder: (_) => _EditCustomerDialog(customer: c),
    );
    if (result == null) return;
    final error = await appState.updateCustomerProfile(
      c.uid,
      name: result.name,
      address: result.address,
      zipCode: result.zip,
      phone: result.phone,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Customer updated')),
    );
  }

  Future<void> _delete(BuildContext context, CustomerProfile c) async {
    final appState = context.read<AppState>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Delete ${c.name}?'),
        content: const Text(
          'This removes the customer\'s profile, subscriptions, receipts and orders, '
          'and they will no longer be able to sign in. This can\'t be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete user'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await appState.adminDeleteCustomer(c.uid);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${c.name} was deleted')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final customers = context.watch<AppState>().customers;

    if (customers.isEmpty) {
      return const Center(child: Text('No customers yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final c = customers[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600)),
            subtitle: Text(
              '${c.phone}${c.email != null ? ' · ${c.email}' : ''}\n${c.address} · ${c.zipCode}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit',
                  onPressed: () => _edit(context, c),
                ),
                IconButton(
                  icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
                  tooltip: 'Delete user',
                  onPressed: () => _delete(context, c),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EditCustomerDialog extends StatefulWidget {
  final CustomerProfile customer;

  const _EditCustomerDialog({required this.customer});

  @override
  State<_EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends State<_EditCustomerDialog> {
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _zip;
  late final TextEditingController _phone;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c.name);
    _address = TextEditingController(text: c.address);
    _zip = TextEditingController(text: c.zipCode);
    _phone = TextEditingController(text: c.phone);
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _zip.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit customer'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Address'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _zip,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Zip code'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (v.replaceAll(RegExp(r'[^0-9]'), '').length < 7) return 'Enter a valid phone number';
                  return null;
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
            Navigator.pop(context, (
              name: _name.text,
              address: _address.text,
              zip: _zip.text,
              phone: _phone.text,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
