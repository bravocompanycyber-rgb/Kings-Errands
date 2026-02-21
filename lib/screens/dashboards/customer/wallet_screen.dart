import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../models/app_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final db = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Wallet')),
      body: StreamBuilder<AppUser?>(
        stream: auth.currentUserDataStream,
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final user = userSnapshot.data!;

          return Column(
            children: [
              _buildWalletHeader(user),
              if (user.debt > 0) _buildDebtAlert(user.debt),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Transaction History', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
                ),
              ),
              Expanded(
                child: StreamBuilder<List<AppTransaction>>(
                  stream: db.transactionsRef
                      .where('userId', isEqualTo: user.id)
                      .orderBy('createdAt', descending: true)
                      .snapshots()
                      .map((s) => s.docs.map((d) => d.data()).toList()),
                  builder: (context, txSnapshot) {
                    if (!txSnapshot.hasData) return const Center(child: CircularProgressIndicator());
                    final txs = txSnapshot.data!;
                    if (txs.isEmpty) return const Center(child: Text('No transactions yet.', style: TextStyle(color: Colors.white30)));

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: txs.length,
                      itemBuilder: (context, index) {
                        final tx = txs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GlassCard(
                            padding: const EdgeInsets.all(12),
                            child: ListTile(
                              leading: Icon(
                                tx.status == 'completed' ? Icons.payment : Icons.account_balance_wallet,
                                color: tx.status == 'completed' ? Colors.redAccent : Colors.greenAccent,
                              ),
                              title: Text(tx.status.replaceAll('_', ' ').toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              subtitle: Text(DateFormat.yMMMd().add_jm().format(tx.createdAt), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                              trailing: Text(
                                'KES ${tx.amount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: tx.status == 'completed' ? Colors.redAccent : Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWalletHeader(AppUser user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: const BoxDecoration(
        color: AppTheme.maroon,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const Text('TOTAL BALANCE', style: TextStyle(color: Colors.white70, letterSpacing: 2, fontSize: 12)),
          const SizedBox(height: 8),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('wallets').doc(user.id).snapshots(),
            builder: (context, snapshot) {
              final balance = snapshot.data?.data()?['balance'] ?? 0.0;
              return Text(
                'KES ${balance.toStringAsFixed(2)}',
                style: const TextStyle(color: AppTheme.gold, fontSize: 40, fontWeight: FontWeight.bold),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDebtAlert(double debt) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Outstanding Debt', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                Text('You have an unpaid balance of KES ${debt.toStringAsFixed(2)}. This will be added to your next errand.', style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
