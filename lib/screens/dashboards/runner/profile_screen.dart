import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../models/app_models.dart';

class RunnerProfileScreen extends StatelessWidget {
  const RunnerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final db = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Runner Profile')),
      body: StreamBuilder<AppUser?>(
        stream: authService.currentUserDataStream,
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final user = userSnapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildProfileHeader(user),
                const SizedBox(height: 24),
                _buildWalletCard(context, db, user.id),
                const SizedBox(height: 24),
                _buildStatsCard(context, db, user.id),
                const SizedBox(height: 32),
                Text('Account Actions', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.logout, color: AppTheme.gold),
                        title: const Text('Sign Out', style: TextStyle(color: Colors.white)),
                        onTap: () => authService.signOut(),
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

  Widget _buildProfileHeader(AppUser user) {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.gold,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 32, color: Colors.black, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user.phoneNumber, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green),
            ),
            child: const Text('VERIFIED RUNNER', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletCard(BuildContext context, DatabaseService db, String userId) {
    return StreamBuilder<DocumentSnapshot<Wallet>>(
      stream: db.walletsRef.doc(userId).snapshots(),
      builder: (context, snapshot) {
        final wallet = snapshot.data?.data();
        final balance = wallet?.balance ?? 0.0;

        return GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text('Available Earnings', style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 8),
              Text(
                'KES ${balance.toStringAsFixed(2)}',
                style: const TextStyle(color: AppTheme.gold, fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Payouts are processed automatically by Admin.')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.gold, foregroundColor: Colors.black),
                child: const Text('REQUEST CASHOUT'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(BuildContext context, DatabaseService db, String userId) {
    return StreamBuilder<List<Review>>(
      stream: db.streamRunnerReviews(userId),
      builder: (context, snapshot) {
        final reviews = snapshot.data ?? [];
        final rating = reviews.isEmpty ? 0.0 : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;

        return GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  const Icon(Icons.star, color: AppTheme.gold, size: 28),
                  const SizedBox(height: 8),
                  Text(rating.toStringAsFixed(1), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('${reviews.length} Reviews', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
              Container(height: 40, width: 1, color: Colors.white10),
              const Column(
                children: [
                  Icon(Icons.flash_on, color: Colors.blueAccent, size: 28),
                  SizedBox(height: 8),
                  Text('98%', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Completion', style: TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
