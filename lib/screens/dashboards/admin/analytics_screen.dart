import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../models/app_models.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<Statistics?>(
        stream: db.streamStatistics(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final stats = snapshot.data ?? Statistics(
            totalRevenue: 0,
            totalErrandsCount: 0,
            totalUsersCount: 0,
            dailyActiveRunners: 0,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SYSTEM ANALYTICS',
                  style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    _buildStatCard('TOTAL REVENUE', 'KES ${stats.totalRevenue.toStringAsFixed(2)}', Icons.payments, Colors.greenAccent),
                    _buildStatCard('TOTAL ERRANDS', '${stats.totalErrandsCount}', Icons.shopping_bag, Colors.blueAccent),
                    _buildStatCard('TOTAL USERS', '${stats.totalUsersCount}', Icons.people, Colors.orangeAccent),
                    _buildStatCard('ACTIVE RUNNERS', '${stats.dailyActiveRunners}', Icons.directions_run, Colors.purpleAccent),
                  ],
                ),
                const SizedBox(height: 32),
                const Text(
                  'ADMIN CONTROLS',
                  style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                        title: const Text('Cleanup Old Data', style: TextStyle(color: Colors.white)),
                        subtitle: const Text('Delete audit logs and notifications older than 30 days.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                        onTap: () async {
                           await db.cleanupOldData();
                           if (context.mounted) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cleanup scheduled.')));
                           }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white54, fontSize: 10, letterSpacing: 1)),
        ],
      ),
    );
  }
}
