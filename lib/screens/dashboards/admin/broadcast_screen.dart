import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';
import '../../../models/app_models.dart';

class BroadcastScreen extends StatefulWidget {
  const BroadcastScreen({super.key});

  @override
  State<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends State<BroadcastScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final Map<String, bool> _targets = {
    'admin': false,
    'runner': false,
    'customer': false,
  };
  bool _isLoading = false;

  void _sendBroadcast() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    final selectedRoles = _targets.entries.where((e) => e.value).map((e) => e.key).toList();

    if (title.isEmpty || message.isEmpty || selectedRoles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and select at least one target group')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final db = context.read<DatabaseService>();

    try {
      final usersSnapshot = await db.usersRef.get();
      final targetUsers = usersSnapshot.docs
          .map((d) => d.data())
          .where((u) => selectedRoles.contains(u.role))
          .toList();

      for (var user in targetUsers) {
        await db.notificationsRef.add(NotificationModel(
          id: '',
          receiverId: user.id,
          title: title,
          body: message,
          isRead: false,
          timestamp: DateTime.now(),
        ));
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Broadcast sent to ${targetUsers.length} users!'), backgroundColor: Colors.green),
        );
        _titleController.clear();
        _messageController.clear();
        setState(() {
          _targets.updateAll((key, value) => false);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send broadcast: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SYSTEM BROADCAST',
              style: TextStyle(color: AppTheme.gold, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Send a notification to specific user groups.',
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 24),
            GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Notification Title',
                      labelStyle: TextStyle(color: AppTheme.gold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    maxLines: 5,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Message Body',
                      labelStyle: TextStyle(color: AppTheme.gold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text('TARGET GROUPS', style: TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ..._targets.keys.map((role) => CheckboxListTile(
              title: Text(role.toUpperCase(), style: const TextStyle(color: Colors.white)),
              value: _targets[role],
              activeColor: AppTheme.gold,
              checkColor: Colors.black,
              onChanged: (val) => setState(() => _targets[role] = val ?? false),
            )),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _sendBroadcast,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.gold,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.black)
                  : const Text('SEND BROADCAST', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
