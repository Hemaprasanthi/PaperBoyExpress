import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/app_state.dart';
import '../../utils/app_constants.dart';
import '../../widgets/app_menu.dart';
import '../login_screen.dart';

/// Delivery person's view: only what to deliver, where and when - for today.
/// Nothing here is editable and no customer or price details are shown.
class DeliveryHomeScreen extends StatelessWidget {
  const DeliveryHomeScreen({super.key});

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

    final username = appState.currentUser!.username;
    final papers = appState.todaysDeliveriesFor(username);
    final greens = appState.todaysGreensDeliveriesFor(username);
    final today = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Deliveries'),
        actions: const [AppMenuButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 12),
            child: Row(
              children: [
                Icon(Icons.today, color: Colors.grey[700], size: 20),
                const SizedBox(width: 8),
                Text(formatDate(today), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (papers.isEmpty && greens.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.local_shipping_outlined, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text('Nothing to deliver today',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Deliveries assigned to you by the admin will appear here on the day.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          if (papers.isNotEmpty) ...[
            const _SectionTitle('Newspapers'),
            ...papers.map((s) => Card(
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.newspaper)),
                    title: Text('${s.newspaper.name} x${s.copiesPerDelivery}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${s.address}\nToday, ${formatDate(today)}'),
                    isThreeLine: true,
                  ),
                )),
          ],
          if (greens.isNotEmpty) ...[
            const _SectionTitle('Greens & vegetables'),
            ...greens.map((o) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green[50],
                      child: Icon(Icons.eco, color: Colors.green[700]),
                    ),
                    title: Text(o.itemsSummary, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${o.address}\nDeliver by ${formatDateTime(o.expectedDeliveryBy)}'),
                    isThreeLine: true,
                  ),
                )),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}
