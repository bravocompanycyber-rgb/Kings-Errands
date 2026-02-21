import 'package:flutter/material.dart';
import 'customer/faq_screen.dart';
import 'customer/post_errand_screen.dart';
import 'customer/profile_screen.dart';
import 'customer/track_errand_screen.dart';
import 'customer/transaction_history_screen.dart';
import 'customer/wallet_screen.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../models/app_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/connectivity_status.dart';
import '../../../widgets/dashboard_grid_item.dart';

import '../notification_screen.dart';

class CustomerDashboard extends StatelessWidget {
  const CustomerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    final List<Map<String, dynamic>> gridItems = [
      {
        'icon': Icons.add_location_alt,
        'title': 'Post an Errand',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PostErrandScreen())),
      },
      {
        'icon': Icons.track_changes,
        'title': 'Track Errand',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrackErrandScreen())),
      },
      {
        'icon': Icons.wallet,
        'title': 'My Wallet',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
      },
      {
        'icon': Icons.receipt_long,
        'title': 'Transaction History',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TransactionHistoryScreen())),
      },
      {
        'icon': Icons.manage_accounts,
        'title': 'Profile Settings',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
      },
      {
        'icon': Icons.quiz,
        'title': 'Help & FAQ',
        'onTap': () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQScreen())),
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<AppUser?>(
          stream: authService.currentUserDataStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Welcome!', style: TextStyle(color: AppTheme.gold, fontSize: 16));
            }
            final userName = snapshot.data?.name.split(' ').first ?? 'User';
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Welcome, $userName! Need a King\'s hand today?', style: const TextStyle(color: AppTheme.gold, fontSize: 14)),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppTheme.gold),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.gold),
            onPressed: () => authService.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityStatus(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.1,
                ),
                itemCount: gridItems.length,
                itemBuilder: (context, index) {
                  return DashboardGridItem(
                    icon: gridItems[index]['icon'],
                    title: gridItems[index]['title'],
                    onTap: gridItems[index]['onTap'],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
