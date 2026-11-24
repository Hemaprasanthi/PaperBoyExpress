import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/status_badge.dart';
import '../login_screen.dart';
import 'select_newspaper_screen.dart';
import 'subscription_detail_screen.dart';
import 'receipts_screen.dart';
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
              Tab(text: 'Receipts', icon: Icon(Icons.receipt_long_outlined)),
              Tab(text: 'Greens & Veg', icon: Icon(Icons.eco_outlined)),
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
            const AppMenuButton(showAccount: true),
          ],
        ),
        body: const TabBarView(
          children: [
            _SubscriptionsTab(),
            ReceiptsScreen(),
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
      itemCount: subs.length,
      itemBuilder: (context, index) {
        final s = subs[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
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
              backgroundColor: Colors.deepPurple.withValues(alpha: 0.08),
              child: const Icon(Icons.newspaper, color: Colors.deepPurple),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(s.newspaper.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                SubscriptionStatusBadge(subscription: s),
              ],
            ),
            subtitle: Text(
              '${s.copiesPerDelivery}x copy · ${s.weekdaysLabel}\n'
              '${formatDate(s.startDate)}${s.endDate != null ? ' – ${formatDate(s.endDate!)}' : ''}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            isThreeLine: true,
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${formatInr(s.periodPrice)}${s.periodPriceSuffix}',
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
