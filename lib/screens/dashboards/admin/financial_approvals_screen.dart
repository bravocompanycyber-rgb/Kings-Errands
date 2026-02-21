import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/app_models.dart';
import '../../../services/database_service.dart';
import '../../../services/auth_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';

class FinancialApprovalsScreen extends StatefulWidget {
  const FinancialApprovalsScreen({super.key});

  @override
  State<FinancialApprovalsScreen> createState() => _FinancialApprovalsScreenState();
}

class _FinancialApprovalsScreenState extends State<FinancialApprovalsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financials'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Approvals'),
            Tab(text: 'Payouts'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildApprovalsTab(),
          _buildPayoutsTab(),
          _buildTransactionsTab(),
        ],
      ),
    );
  }

  Widget _buildApprovalsTab() {
    final db = context.read<DatabaseService>();
    final auth = context.read<AuthService>();
    return StreamBuilder<List<Errand>>(
      stream: db.errandsRef
          .where('status', isEqualTo: 'awaiting_payment')
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final errands = snapshot.data!;
        if (errands.isEmpty) return const Center(child: Text('No pending approvals.', style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: errands.length,
          itemBuilder: (context, index) {
            final errand = errands[index];
            final mpesaController = TextEditingController();
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: Text(errand.title, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold))),
                        Text('KES ${errand.estimatedPrice}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (errand.mpesaCode != null && errand.mpesaCode!.isNotEmpty)
                      Column(
                        children: [
                          const Text('Customer Provided Code:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text(errand.mpesaCode!, style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                          const SizedBox(height: 12),
                        ],
                      )
                    else
                      Column(
                        children: [
                          TextField(
                            controller: mpesaController,
                            style: const TextStyle(color: Colors.white),
                            decoration: const InputDecoration(labelText: 'Enter Confirmation Code', labelStyle: TextStyle(color: AppTheme.gold)),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                onPressed: () {
                                  final code = 'CASH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                                  mpesaController.text = code;
                                },
                                child: const Text('GENERATE CASH CODE', style: TextStyle(color: Colors.blue, fontSize: 10)),
                              ),
                              TextButton(
                                onPressed: () {
                                  final code = 'BANK-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                                  mpesaController.text = code;
                                },
                                child: const Text('GENERATE BANK CODE', style: TextStyle(color: Colors.orange, fontSize: 10)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: Size(double.infinity, 45),
                      ),
                      onPressed: () async {
                        final code = (errand.mpesaCode != null && errand.mpesaCode!.isNotEmpty) 
                            ? errand.mpesaCode! 
                            : mpesaController.text.trim();
                            
                        if (code.isNotEmpty) {
                          final user = await auth.getCurrentUserData();
                          await db.approvePayment(errand.id, code, user?.id ?? 'admin');
                        } else {
                           ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter or verify the confirmation code')),
                          );
                        }
                      },
                      child: const Text('CONFIRM MATCH & APPROVE'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPayoutsTab() {
    final db = context.read<DatabaseService>();
    final auth = context.read<AuthService>();
    return StreamBuilder<SystemConfig>(
      stream: db.streamSystemConfig(),
      builder: (context, configSnapshot) {
        final commissionPercent = configSnapshot.data?.runnerCommissionPercentage ?? 80.0;

        return StreamBuilder<List<Errand>>(
          stream: db.errandsRef
              .where('status', isEqualTo: 'completed')
              .where('isPaidOut', isEqualTo: false)
              .snapshots()
              .map((s) => s.docs.map((d) => d.data()).toList()),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final errands = snapshot.data!;
            if (errands.isEmpty) return const Center(child: Text('No pending payouts.', style: TextStyle(color: Colors.white54)));

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: errands.length,
              itemBuilder: (context, index) {
                final errand = errands[index];
                final runnerPayout = errand.estimatedPrice * (commissionPercent / 100);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Errand: ${errand.title}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text('Runner ID: ${errand.runnerId}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        const Divider(color: Colors.white10, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Estimated Price:', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('KES ${errand.estimatedPrice}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Text('Runner Share ($commissionPercent%):', style: TextStyle(color: AppTheme.gold, fontSize: 14, fontWeight: FontWeight.bold)),
                                                        Text('KES ${runnerPayout.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.gold, fontSize: 14, fontWeight: FontWeight.bold)),
                                                      ],                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 40)),
                          onPressed: () async {
                            final user = await auth.getCurrentUserData();
                            await db.releasePayout(errand.id, errand.runnerId!, user?.id ?? 'admin');
                          },
                          child: const Text('RELEASE PAYOUT'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionsTab() {
    final db = context.read<DatabaseService>();
    return StreamBuilder<List<AppTransaction>>(
      stream: db.transactionsRef.orderBy('createdAt', descending: true).snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final txs = snapshot.data!;
        if (txs.isEmpty) return const Center(child: Text('No transaction history.', style: TextStyle(color: Colors.white54)));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: txs.length,
          itemBuilder: (context, index) {
            final tx = txs[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: tx.status == 'approved' ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                      child: Icon(
                        tx.mpesaCode.startsWith('PAYOUT') ? Icons.upload : Icons.download,
                        color: tx.status == 'approved' ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tx.mpesaCode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          Text(DateFormat.yMMMd().add_jm().format(tx.createdAt), style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('KES ${tx.amount.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold)),
                        Text(tx.status.toUpperCase(), style: TextStyle(color: tx.status == 'approved' ? Colors.green : Colors.orange, fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
