import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../models/app_models.dart';

class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final db = context.read<DatabaseService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<AppUser?>(
        stream: authService.currentUserDataStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final user = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildProfileHeader(user),
              const SizedBox(height: 32),
              const Text('Admin Controls', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
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
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.redAccent),
                      title: const Text('Terminate Admin Account', style: TextStyle(color: Colors.redAccent)),
                      onTap: () => _showTerminateAccountDialog(context, authService, db, user.id),
                    ),
                  ],
                ),
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
            backgroundColor: AppTheme.maroon,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
              style: const TextStyle(fontSize: 32, color: AppTheme.gold, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(user.email, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.gold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.gold),
            ),
            child: const Text('SYSTEM ADMINISTRATOR', style: TextStyle(color: AppTheme.gold, fontSize: 10, fontWeight: FontWeight.bold)),
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
        content: const Text('Are you sure? This will remove your admin access.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.deleteUser(userId);
              await auth.signOut();
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('TERMINATE'),
          ),
        ],
      ),
    );
  }
}
