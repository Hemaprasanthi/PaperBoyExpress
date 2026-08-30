import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../login_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final subs = appState.allSubscriptions;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All Subscriptions', icon: Icon(Icons.list_alt)),
              Tab(text: 'Assign Delivery', icon: Icon(Icons.local_shipping)),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
            onPressed: () async {
              await context.read<AppState>().logout();
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _AllSubscriptionsTab(subs: subs),
            _AssignDeliveryTab(subs: subs),
          ],
        ),
      ),
    );
  }
}

class _AllSubscriptionsTab extends StatelessWidget {
  final List subs;
  const _AllSubscriptionsTab({required this.subs});

  @override
  Widget build(BuildContext context) {
    if (subs.isEmpty) {
      return const Center(child: Text('No subscriptions yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: subs.length,
      itemBuilder: (context, index) {
        final s = subs[index];
        return Card(
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('${s.customerName ?? s.customerUsername} · ${s.newspaper.name}'),
            subtitle: Text(
              '${s.customerPhone != null ? "${s.customerPhone}\n" : ""}'
              '${s.copiesPerDelivery}x copy · ${s.weekdaysLabel}\n'
              'Starts ${s.startDate.day}/${s.startDate.month}/${s.startDate.year} · ${s.address}\n'
              'Delivery: ${s.assignedDeliveryBoy ?? "Unassigned"}',
            ),
            isThreeLine: true,
            trailing: Text(
              '\$${s.monthlyPrice.toStringAsFixed(2)}/mo',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      },
    );
  }
}

class _AssignDeliveryTab extends StatelessWidget {
  final List subs;
  const _AssignDeliveryTab({required this.subs});

  @override
  Widget build(BuildContext context) {
    final appState = context.read<AppState>();

    if (subs.isEmpty) {
      return const Center(child: Text('No subscriptions to assign yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: subs.length,
      itemBuilder: (context, index) {
        final s = subs[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${s.newspaper.name} → ${s.customerName ?? s.customerUsername}',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(s.address, style: TextStyle(color: Colors.grey[600])),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: s.assignedDeliveryBoy,
                        decoration: const InputDecoration(
                          labelText: 'Delivery boy',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: appState.deliveryBoys
                            .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            appState.assignDelivery(s.id, value);
                          }
                        },
                      ),
                    ),
                    if (s.assignedDeliveryBoy != null)
                      IconButton(
                        icon: const Icon(Icons.close),
                        tooltip: 'Unassign',
                        onPressed: () => appState.unassignDelivery(s.id),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
