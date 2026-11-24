import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/subscription.dart';
import '../../state/app_state.dart';
import '../../utils/app_constants.dart';
import '../../utils/currency.dart';
import '../../widgets/app_menu.dart';
import '../../widgets/status_badge.dart';
import 'admin_catalog_screen.dart';
import 'admin_issues_tab.dart';
import 'admin_payments_tab.dart';
import 'admin_subscription_edit_screen.dart';
import 'admin_users_tab.dart';
import 'pricing_screen.dart';

class AdminHomeScreen extends StatelessWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final subs = appState.allSubscriptions;

    return DefaultTabController(
      length: 7,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Admin Dashboard'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Subscriptions', icon: Icon(Icons.list_alt)),
              Tab(text: 'Assign Delivery', icon: Icon(Icons.local_shipping)),
              Tab(text: 'Catalog', icon: Icon(Icons.inventory_2_outlined)),
              Tab(text: 'Pricing', icon: Icon(Icons.sell_outlined)),
              Tab(text: 'Payments', icon: Icon(Icons.receipt_long_outlined)),
              Tab(text: 'Users', icon: Icon(Icons.people_outline)),
              Tab(text: 'Issues', icon: Icon(Icons.support_agent)),
            ],
          ),
          actions: const [AppMenuButton()],
        ),
        body: TabBarView(
          children: [
            _AllSubscriptionsTab(subs: subs),
            _AssignDeliveryTab(subs: subs),
            const AdminCatalogScreen(),
            const PricingScreen(),
            const AdminPaymentsTab(),
            const AdminUsersTab(),
            const AdminIssuesTab(),
          ],
        ),
      ),
    );
  }
}

class _AllSubscriptionsTab extends StatelessWidget {
  final List<Subscription> subs;
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
        final pause = s.status == SubscriptionStatus.active && s.hasPauseScheduledOrActive
            ? '\nPause: ${formatDate(s.pausedFrom!)} - ${formatDate(s.pausedUntil!)}'
            : '';
        return Card(
          child: ListTile(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AdminSubscriptionEditScreen(subscription: s),
                ),
              );
            },
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Row(
              children: [
                Expanded(
                  child: Text('${s.customerName ?? s.customerUsername} · ${s.newspaper.name}'),
                ),
                SubscriptionStatusBadge(subscription: s),
              ],
            ),
            subtitle: Text(
              '${s.customerPhone != null ? "${s.customerPhone}\n" : ""}'
              '${s.copiesPerDelivery}x copy · ${s.weekdaysLabel}\n'
              '${formatDate(s.startDate)}${s.endDate != null ? ' – ${formatDate(s.endDate!)}' : ''} · ${s.address}\n'
              'Delivery: ${s.assignedDeliveryBoy ?? "Unassigned"}$pause',
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

class _AssignDeliveryTab extends StatelessWidget {
  final List<Subscription> subs;
  const _AssignDeliveryTab({required this.subs});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final today = dateOnly(DateTime.now());
    final todaysGreens =
        appState.veggieOrders.where((o) => dateOnly(o.orderedAt) == today).toList();
    final assignable =
        subs.where((s) => s.status != SubscriptionStatus.cancelled && !s.isExpired).toList();

    if (assignable.isEmpty && todaysGreens.isEmpty) {
      return const Center(child: Text('Nothing to assign yet.'));
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (assignable.isNotEmpty) const _Heading('Newspaper subscriptions'),
        for (final s in assignable)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${s.newspaper.name} → ${s.customerName ?? s.customerUsername}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(s.address, style: TextStyle(color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  _DeliveryDropdown(
                    value: s.assignedDeliveryBoy,
                    deliveryBoys: appState.deliveryBoys,
                    onChanged: (v) => v == null
                        ? appState.unassignDelivery(s.id)
                        : appState.assignDelivery(s.id, v),
                  ),
                ],
              ),
            ),
          ),
        if (todaysGreens.isNotEmpty) const _Heading('Greens & vegetable orders today'),
        for (final o in todaysGreens)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.itemsSummary, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '${o.customerName ?? o.customerUsername} · ${o.address}\n'
                    'Deliver by ${formatDateTime(o.expectedDeliveryBy)}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  _DeliveryDropdown(
                    value: o.assignedDeliveryBoy,
                    deliveryBoys: appState.deliveryBoys,
                    onChanged: (v) => appState.assignVeggieDelivery(o.id, v),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _DeliveryDropdown extends StatelessWidget {
  final String? value;
  final List<String> deliveryBoys;
  final void Function(String? value) onChanged;

  const _DeliveryDropdown({
    required this.value,
    required this.deliveryBoys,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            value: value,
            decoration: const InputDecoration(
              labelText: 'Delivery person',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: deliveryBoys.map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
          ),
        ),
        if (value != null)
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Unassign',
            onPressed: () => onChanged(null),
          ),
      ],
    );
  }
}

class _Heading extends StatelessWidget {
  final String text;
  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
