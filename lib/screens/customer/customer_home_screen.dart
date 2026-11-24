import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';
import '../../utils/currency.dart';
import '../login_screen.dart';
import 'select_newspaper_screen.dart';
import 'subscription_detail_screen.dart';
import 'payments_screen.dart';
import 'notifications_screen.dart';
import 'vegetables_screen.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    if (appState.currentUser == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final unread = appState.unreadNotificationCountFor(appState.currentUser!.username);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            appState.currentCustomerProfile != null
                ? 'Hi, ${appState.currentCustomerProfile!.name.split(' ').first}'
                : 'My Account',
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Subscriptions', icon: Icon(Icons.newspaper)),
              Tab(text: 'Payments', icon: Icon(Icons.receipt_long_outlined)),
              Tab(text: 'Fresh Greens', icon: Icon(Icons.eco_outlined)),
            ],
          ),
          actions: [
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  tooltip: 'Notifications',
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                    );
                  },
                ),
                if (unread > 0)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$unread',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                    ),
                  ),
              ],
            ),
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
        body: const TabBarView(
          children: [
            _SubscriptionsTab(),
            PaymentsScreen(),
            VegetablesScreen(),
          ],
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
      ),
    );
  }
}

class _SubscriptionsTab extends StatelessWidget {
  const _SubscriptionsTab();

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final username = appState.currentUser!.username;
    final subs = appState.subscriptionsForCustomer(username);

    if (subs.isEmpty) {
      return Center(
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: subs.length,
      itemBuilder: (context, index) {
        final s = subs[index];
        final isActive = s.status == SubscriptionStatus.active;
        final isPending = s.status == SubscriptionStatus.pendingApproval;
        final isPaused = isActive && s.isPausedNow;
        final statusLabel =
            isPending ? 'Pending Approval' : (isPaused ? 'Paused' : (isActive ? 'Active' : 'Cancelled'));
        final badgeBg = isPending
            ? Colors.orange[50]
            : (isPaused ? Colors.blue[50] : (isActive ? Colors.green[50] : Colors.grey[200]));
        final badgeFg = isPending
            ? Colors.orange[700]
            : (isPaused ? Colors.blue[700] : (isActive ? Colors.green[700] : Colors.grey[700]));
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(color: Colors.grey.withOpacity(0.15)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => SubscriptionDetailScreen(subscription: s),
                ),
              );
            },
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple.withOpacity(0.08),
              child: const Icon(Icons.newspaper, color: Colors.deepPurple),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(s.newspaper.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(12)),
                  child: Text(
                    statusLabel,
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: badgeFg),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              '${s.copiesPerDelivery}x copy · ${s.weekdaysLabel}\n'
              'Starts ${s.startDate.day}/${s.startDate.month}/${s.startDate.year} · ${s.address}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatInr(s.monthlyPrice)}/mo',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
