import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../login_screen.dart';

/// Delivery boy view.
/// By design this screen ONLY renders newspaper name, delivery frequency,
/// and address for subscriptions the admin has assigned to this delivery
/// account. It never reads/displays customer identity, phone, price, copy
/// count, or any other subscription's data.
class DeliveryHomeScreen extends StatelessWidget {
  const DeliveryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final username = appState.currentUser!.username;
    final assigned = appState.subscriptionsAssignedTo(username);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Deliveries'),
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
      body: assigned.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No deliveries assigned yet',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back once admin assigns addresses to you.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: assigned.length,
              itemBuilder: (context, index) {
                final s = assigned[index];
                return Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.newspaper)),
                    // Only newspaper name, frequency, and address are shown -
                    // nothing about the customer, price, or copy count.
                    title: Text(s.newspaper.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${s.weekdaysLabel}\n${s.address}'),
                    isThreeLine: true,
                  ),
                );
              },
            ),
    );
  }
}
