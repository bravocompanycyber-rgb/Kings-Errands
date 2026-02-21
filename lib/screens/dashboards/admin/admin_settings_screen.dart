import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../models/app_models.dart';
import 'faq_management_screen.dart';

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<SystemConfig>(
        stream: db.streamSystemConfig(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final config = snapshot.data ?? SystemConfig(
            eulaText: '',
            contactEmail: '',
            minWithdrawalAmount: 0,
            appVersion: '1.0.0',
            runnerCommissionPercentage: 80.0,
          );

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text('Financial Configuration', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.percent, color: AppTheme.gold),
                      title: const Text('Runner Commission', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Current Share: ${config.runnerCommissionPercentage}%', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: const Icon(Icons.edit, color: AppTheme.gold, size: 20),
                      onTap: () => _showCommissionDialog(context, db, config),
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.monetization_on, color: AppTheme.gold),
                      title: const Text('Min. Withdrawal Amount', style: TextStyle(color: Colors.white)),
                      subtitle: Text('Current: KES ${config.minWithdrawalAmount}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      trailing: const Icon(Icons.edit, color: AppTheme.gold, size: 20),
                      onTap: () => _showMinWithdrawalDialog(context, db, config),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Legal & Compliance', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.description, color: AppTheme.gold),
                      title: const Text('Terms & Conditions (EULA)', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Update the global EULA text for all users.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () => _showUpdateEULADialog(context, db, config),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              Text('Maintenance', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.history, color: AppTheme.gold),
                      title: const Text('Clear Audit Logs', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Permanently delete all logs to save database space.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () => _showClearLogsDialog(context, db),
                    ),
                    const Divider(color: Colors.white10),
                    ListTile(
                      leading: const Icon(Icons.quiz, color: AppTheme.gold),
                      title: const Text('Manage FAQs', style: TextStyle(color: Colors.white)),
                      subtitle: const Text('Add or edit help content for all roles.', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FAQManagementScreen())),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              Center(
                child: Text('App Version: ${config.appVersion}', style: const TextStyle(color: Colors.white24, fontSize: 10)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCommissionDialog(BuildContext context, DatabaseService db, SystemConfig config) {
    final controller = TextEditingController(text: config.runnerCommissionPercentage.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Runner Commission', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Percentage (%)', labelStyle: TextStyle(color: AppTheme.gold)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0 && val <= 100) {
                final newConfig = SystemConfig(
                  eulaText: config.eulaText,
                  contactEmail: config.contactEmail,
                  minWithdrawalAmount: config.minWithdrawalAmount,
                  appVersion: config.appVersion,
                  runnerCommissionPercentage: val,
                );
                await db.updateSystemConfig(newConfig);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showMinWithdrawalDialog(BuildContext context, DatabaseService db, SystemConfig config) {
    final controller = TextEditingController(text: config.minWithdrawalAmount.toString());
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Min. Withdrawal', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Amount (KES)', labelStyle: TextStyle(color: AppTheme.gold)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text);
              if (val != null && val >= 0) {
                final newConfig = SystemConfig(
                  eulaText: config.eulaText,
                  contactEmail: config.contactEmail,
                  minWithdrawalAmount: val,
                  appVersion: config.appVersion,
                  runnerCommissionPercentage: config.runnerCommissionPercentage,
                );
                await db.updateSystemConfig(newConfig);
                if (context.mounted) Navigator.pop(context);
              }
            },
            child: const Text('SAVE'),
          ),
        ],
      ),
    );
  }

  void _showUpdateEULADialog(BuildContext context, DatabaseService db, SystemConfig config) {
    final controller = TextEditingController(text: config.eulaText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Update EULA', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 10,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          decoration: const InputDecoration(labelText: 'EULA Content', labelStyle: TextStyle(color: AppTheme.gold)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final newConfig = SystemConfig(
                eulaText: controller.text,
                contactEmail: config.contactEmail,
                minWithdrawalAmount: config.minWithdrawalAmount,
                appVersion: config.appVersion,
                runnerCommissionPercentage: config.runnerCommissionPercentage,
              );
              await db.updateSystemConfig(newConfig);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );
  }

  void _showClearLogsDialog(BuildContext context, DatabaseService db) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Confirm Clear Logs', style: TextStyle(color: Colors.white)),
        content: const Text('This will delete ALL audit logs for space saving. This action is IRREVERSIBLE.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await db.clearAuditLogs();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Audit logs cleared.')));
              }
            },
            child: const Text('CLEAR ALL'),
          ),
        ],
      ),
    );
  }
}
