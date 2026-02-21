import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../models/app_models.dart';
import 'user_management_screen.dart';
import 'rates_management_screen.dart';
import 'promo_management_screen.dart';
import 'admin_settings_screen.dart';
import 'financial_approvals_screen.dart';
import 'broadcast_screen.dart';
import 'analytics_screen.dart';
import 'admin_profile_screen.dart';
import 'audit_log_screen.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/connectivity_status.dart';
import '../../notification_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const UserManagementScreen(),
    const FinancialApprovalsScreen(),
    const RatesManagementScreen(),
    const PromoManagementScreen(),
    const BroadcastScreen(),
    const AnalyticsScreen(),
    const AuditLogScreen(),
    const AdminSettingsScreen(),
    const AdminProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: StreamBuilder<AppUser?>(
          stream: authService.currentUserDataStream,
          builder: (context, snapshot) {
            final fullName = snapshot.data?.name ?? '';
            final userName = (fullName.trim().isEmpty) ? 'Admin' : fullName.split(' ').first;
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Welcome, $userName', style: const TextStyle(color: AppTheme.gold, fontSize: 16)),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications, color: AppTheme.gold),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppTheme.gold),
            onPressed: () => _onItemTapped(8),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.background,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.maroon),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.admin_panel_settings, size: 60, color: AppTheme.gold),
                  SizedBox(height: 10),
                  Text('ADMIN PANEL', style: TextStyle(color: AppTheme.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _buildDrawerItem(0, Icons.people_alt, 'User Management'),
            _buildDrawerItem(1, Icons.account_balance_wallet, 'Financial Approvals'),
            _buildDrawerItem(2, Icons.map, 'Rates Management'),
            _buildDrawerItem(3, Icons.confirmation_number, 'Promo Codes'),
            _buildDrawerItem(4, Icons.broadcast_on_home, 'System Broadcast'),
            _buildDrawerItem(5, Icons.analytics, 'Analytics'),
            _buildDrawerItem(6, Icons.history_edu, 'Audit Logs'),
            _buildDrawerItem(7, Icons.settings, 'System Config'),
            _buildDrawerItem(8, Icons.person, 'My Profile'),
            const Divider(color: Colors.white24),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                authService.signOut();
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const ConnectivityStatus(),
          Expanded(child: _widgetOptions.elementAt(_selectedIndex)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.background,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.people_alt),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Rates',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.confirmation_number),
            label: 'Promos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu),
            label: 'More',
          ),
        ],
        currentIndex: _selectedIndex > 3 ? 4 : _selectedIndex,
        selectedItemColor: AppTheme.gold,
        unselectedItemColor: Colors.white54,
        onTap: (index) {
          if (index == 4) {
            Scaffold.of(context).openDrawer();
          } else {
            _onItemTapped(index);
          }
        },
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: _selectedIndex == index ? AppTheme.gold : Colors.white70),
      title: Text(title, style: TextStyle(color: _selectedIndex == index ? AppTheme.gold : Colors.white)),
      selected: _selectedIndex == index,
      onTap: () {
        _onItemTapped(index);
        Navigator.pop(context);
      },
    );
  }
}
