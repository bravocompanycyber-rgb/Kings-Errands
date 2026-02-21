import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_models.dart';
import '../../services/database_service.dart';
import '../../theme/app_theme.dart';
import '../glass_card.dart';
import '../../screens/dashboards/admin/errand_history_screen.dart';

class UserListTile extends StatelessWidget {
  final AppUser user;

  const UserListTile({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: AppTheme.gold,
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.black),
            ),
          ),
          title: Text(user.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${user.role} • ${user.email}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone, size: 12, color: AppTheme.gold),
                  const SizedBox(width: 4),
                  SelectableText(
                    user.phoneNumber,
                    style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(user.isBlocked ? Icons.lock : Icons.lock_open, color: user.isBlocked ? Colors.red : Colors.green),
                onPressed: () => db.updateUserBlockedStatus(user.id, !user.isBlocked),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                onSelected: (value) async {
                  if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete User?'),
                        content: const Text('This action is irreversible.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE')),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await db.deleteUser(user.id);
                    }
                  } else if (value == 'history') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ErrandHistoryScreen(userId: user.id, userName: user.name),
                      ),
                    );
                  } else {
                    await db.updateUserRole(user.id, value);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'history', child: ListTile(leading: Icon(Icons.history), title: Text('Errand History'))),
                  const PopupMenuItem(value: 'customer', child: Text('Make Customer')),
                  const PopupMenuItem(value: 'runner', child: Text('Make Runner')),
                  const PopupMenuItem(value: 'admin', child: Text('Make Admin')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete User', style: TextStyle(color: Colors.red))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
