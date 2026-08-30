import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../login_screen.dart';
import 'select_newspaper_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final username = appState.currentUser!.username;
    final subs = appState.subscriptionsForCustomer(username);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Subscriptions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () {
              context.read<AppState>().logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: subs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.newspaper, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No subscriptions yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Subscribe to a newspaper to get it delivered on your schedule.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: subs.length,
              itemBuilder: (context, index) {
                final s = subs[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.newspaper)),
                    title: Text(s.newspaper.name),
                    subtitle: Text(
                      '${s.copiesPerDelivery}x copy · ${s.weekdaysLabel}\n'
                      'Starts ${s.startDate.day}/${s.startDate.month}/${s.startDate.year} · ${s.address}',
                    ),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${s.monthlyPrice.toStringAsFixed(2)}/mo',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          s.assignedDeliveryBoy == null ? 'Unassigned' : 'Delivery set',
                          style: TextStyle(
                            fontSize: 11,
                            color: s.assignedDeliveryBoy == null
                                ? Colors.orange
                                : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const SelectNewspaperScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Subscribe'),
      ),
    );
  }
}
