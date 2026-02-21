import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../models/app_models.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final db = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Global Settings & Profile')),
      body: StreamBuilder<AppUser?>(
        stream: authService.currentUserDataStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final user = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Wallet Balance', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        // Future: Fetch real wallet balance
                        const Text('KES 0.00', style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(height: 40, width: 1, color: Colors.white10),
                    Column(
                      children: [
                        const Text('Outstanding Debt', style: TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(height: 4),
                        Text('KES ${user.debt.toStringAsFixed(2)}', style: TextStyle(color: user.debt > 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
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
                      subtitle: const Text('Log out of your account on this device.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () => authService.signOut(),
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      title: const Text('Terminate Account', style: TextStyle(color: Colors.redAccent)),
                      subtitle: const Text('Permanently delete your account and all data. This cannot be undone.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () => _showTerminateAccountDialog(context, authService, db, user.id),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Center(
                child: Text('Kings Errands™ v1.0.0', style: TextStyle(color: Colors.white24, fontSize: 10)),
              ),
            ],
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
          Text(user.email, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          Text(user.phoneNumber, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold),
            ),
            child: Text(user.role.toUpperCase(), style: const TextStyle(color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTerminateAccountDialog(BuildContext context, AuthService auth, DatabaseService db, String userId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Terminate Account?', style: TextStyle(color: Colors.white)),
        content: const Text('Are you absolutely sure? All your data, including wallet balance and errand history, will be permanently deleted.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              // Note: For Firebase Auth account deletion, re-authentication is often required.
              // For this demo, we will delete the Firestore documents.
              await db.deleteUser(userId);
              await auth.signOut();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account terminated.')));
              }
            },
            child: const Text('TERMINATE'),
          ),
        ],
      ),
    );
  }
}
