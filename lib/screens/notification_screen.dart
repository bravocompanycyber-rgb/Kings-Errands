import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: FutureBuilder<AppUser?>(
        future: auth.getCurrentUserData(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final userId = userSnapshot.data!.id;

          return StreamBuilder<List<NotificationModel>>(
            stream: db.notificationsRef
                .where('receiverId', isEqualTo: userId)
                .orderBy('timestamp', descending: true)
                .snapshots()
                .map((s) => s.docs.map((d) => d.data()).toList()),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final notifications = snapshot.data!;

              if (notifications.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 64, color: Colors.white24),
                      SizedBox(height: 16),
                      Text('No new notifications.', style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  notification.title,
                                  style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ),
                              Text(
                                DateFormat('MMM d, HH:mm').format(notification.timestamp),
                                style: const TextStyle(color: Colors.white30, fontSize: 10),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(notification.body, style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
