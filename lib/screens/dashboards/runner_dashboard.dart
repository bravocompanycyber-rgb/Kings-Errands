import 'package:flutter/material.dart';
import 'runner/active_task_screen.dart';
import 'runner/available_errands_screen.dart';
import 'runner/earnings_screen.dart';
import 'customer/faq_screen.dart';
import 'customer/profile_screen.dart';
import '../placeholder_screen.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../models/app_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/connectivity_status.dart';

class RunnerDashboard extends StatefulWidget {
  const RunnerDashboard({super.key});

  @override
  State<RunnerDashboard> createState() => _RunnerDashboardState();
}

class _RunnerDashboardState extends State<RunnerDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _widgetOptions = <Widget>[
    const AvailableErrandsScreen(),
    const ActiveTaskScreen(),
    const EarningsScreen(),
    const PlaceholderScreen(title: 'Reviews Coming Soon'),
    const ProfileScreen(),
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text('Runner Mode', style: TextStyle(color: AppTheme.gold, fontSize: 16));
            }
            final userName = snapshot.data?.name.split(' ').first ?? 'Runner';
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text('Hail, King $userName! Ready for a quest?', style: const TextStyle(color: AppTheme.gold, fontSize: 14)),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: AppTheme.gold),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQScreen())),
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
          Expanded(child: _widgetOptions.elementAt(_selectedIndex)),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.background,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.store),
            label: 'Market',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.directions_run),
            label: 'Active',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.monetization_on),
            label: 'Earnings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star),
            label: 'Reviews',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
        selectedItemColor: AppTheme.gold,
        unselectedItemColor: Colors.white54,
        onTap: _onItemTapped,
      ),
    );
  }
}
