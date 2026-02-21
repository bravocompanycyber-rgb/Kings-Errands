import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../models/app_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';

class AuditLogScreen extends StatelessWidget {
  const AuditLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<AuditLog>>(
        stream: db.auditLogsRef.orderBy('timestamp', descending: true).snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final logs = snapshot.data!;
          
          if (logs.isEmpty) {
            return const Center(child: Text('No audit logs available.', style: TextStyle(color: Colors.white54)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final log = logs[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(log.action.toUpperCase(), style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 12)),
                          Text(DateFormat('MMM d, HH:mm:ss').format(log.timestamp), style: const TextStyle(color: Colors.white30, fontSize: 10)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      if (log.details.isNotEmpty)
                        Text(log.details, style: const TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Admin ID: ${log.adminId.isEmpty ? "System" : log.adminId}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      Text('Errand ID: ${log.errandId}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
