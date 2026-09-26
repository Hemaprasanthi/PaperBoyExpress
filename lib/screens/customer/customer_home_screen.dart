import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';
import '../login_screen.dart';
import 'select_newspaper_screen.dart';
import 'subscription_detail_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final username = appState.currentUser!.username;
    final subs = appState.subscriptionsForCustomer(username);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appState.currentCustomerProfile != null
              ? 'Hi, ${appState.currentCustomerProfile!.name.split(' ').first}'
              : 'My Subscriptions',
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
                final isActive = s.status == SubscriptionStatus.active;
                return Card(
                  child: ListTile(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SubscriptionDetailScreen(subscription: s),
                        ),
                      );
                    },
                    leading: const CircleAvatar(child: Icon(Icons.newspaper)),
                    title: Row(
                      children: [
                        Expanded(child: Text(s.newspaper.name)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green[100] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isActive ? 'Active' : 'Cancelled',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.green[800] : Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
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
                        const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
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
