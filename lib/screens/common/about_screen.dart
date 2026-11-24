import 'package:flutter/material.dart';
import '../../utils/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('About us')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Icon(Icons.newspaper, size: 64, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'PaperBoy Express',
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Your morning, delivered.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 28),
          const _Section(
            icon: Icons.newspaper,
            title: 'Newspapers',
            body: 'Pick your favourite newspapers, choose the days and the dates, and we '
                'bring them to your door. You can pause deliveries for up to a month '
                'whenever you travel.',
          ),
          const _Section(
            icon: Icons.eco_outlined,
            title: 'Fresh greens & vegetables',
            body: 'Order farm-fresh greens and vegetables and get them delivered in about '
                '15 minutes, right now in select areas.',
          ),
          const _Section(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Simple payments',
            body: 'Pay securely with UPI. Every payment gives you a receipt you can find '
                'in the Receipts tab.',
          ),
          const _Section(
            icon: Icons.support_agent,
            title: 'We\'re here to help',
            body: '$kSupportPromise For urgent issues, call $kSupportContactName on '
                '$kSupportContactPhone, or write to $kSupportEmail.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _Section({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(body, style: TextStyle(color: Colors.grey[700], height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
