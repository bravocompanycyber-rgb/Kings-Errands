import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/app_models.dart';
import '../../../widgets/glass_card.dart';
import '../../../theme/app_theme.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final db = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Errand & Payment History')),
      body: FutureBuilder<AppUser?>(
        future: auth.getCurrentUserData(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final user = userSnapshot.data!;

          return StreamBuilder<List<AppTransaction>>(
            stream: db.transactionsRef
                .where('userId', isEqualTo: user.id)
                .orderBy('createdAt', descending: true)
                .snapshots()
                .map((s) => s.docs.map((d) => d.data()).toList()),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final txs = snapshot.data!;
              if (txs.isEmpty) return const Center(child: Text('No transaction history found.', style: TextStyle(color: Colors.white54)));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: txs.length,
                itemBuilder: (context, index) {
                  final tx = txs[index];
                  final isPayout = tx.mpesaCode.startsWith('PAYOUT');
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: GlassCard(
                      padding: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPayout ? Colors.green.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                          child: Icon(
                            isPayout ? Icons.account_balance_wallet : Icons.shopping_bag,
                            color: isPayout ? Colors.green : Colors.blue,
                          ),
                        ),
                        title: Text(
                          isPayout ? 'Earnings Payout' : 'Errand Payment',
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tx.mpesaCode, style: const TextStyle(color: AppTheme.gold, fontSize: 10)),
                            Text(DateFormat.yMMMd().add_jm().format(tx.createdAt), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                        trailing: Text(
                          'KES ${tx.amount.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isPayout ? Colors.greenAccent : Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
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
