import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/common/about_screen.dart';
import '../screens/common/support_screen.dart';
import '../screens/customer/account_screen.dart';
import '../screens/login_screen.dart';
import '../state/app_state.dart';

/// The overflow menu shown in every role's app bar: account (customers only),
/// report an issue, about us and sign out.
class AppMenuButton extends StatelessWidget {
  final bool showAccount;

  const AppMenuButton({super.key, this.showAccount = false});

  Future<void> _signOut(BuildContext context) async {
    await context.read<AppState>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Menu',
      onSelected: (value) {
        switch (value) {
          case 'account':
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountScreen()));
          case 'support':
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SupportScreen()));
          case 'about':
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutScreen()));
          case 'logout':
            _signOut(context);
        }
      },
      itemBuilder: (_) => [
        if (showAccount)
          const PopupMenuItem(
            value: 'account',
            child: ListTile(leading: Icon(Icons.person_outline), title: Text('My account')),
          ),
        const PopupMenuItem(
          value: 'support',
          child: ListTile(leading: Icon(Icons.support_agent), title: Text('Report an issue')),
        ),
        const PopupMenuItem(
          value: 'about',
          child: ListTile(leading: Icon(Icons.info_outline), title: Text('About us')),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: ListTile(leading: Icon(Icons.logout), title: Text('Sign out')),
        ),
      ],
    );
  }
}
