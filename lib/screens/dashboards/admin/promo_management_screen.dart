import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../services/database_service.dart';
import '../../../models/app_models.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';

class PromoManagementScreen extends StatefulWidget {
  const PromoManagementScreen({super.key});

  @override
  State<PromoManagementScreen> createState() => _PromoManagementScreenState();
}

class _PromoManagementScreenState extends State<PromoManagementScreen> {
  final _codeController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime? _expiryDate;

  void _showPromoDialog() {
    _codeController.clear();
    _amountController.clear();
    _expiryDate = null;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Add Promo Code', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _codeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Promo Code', labelStyle: TextStyle(color: AppTheme.gold)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Discount Amount (Ksh)', labelStyle: TextStyle(color: AppTheme.gold)),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_expiryDate == null ? 'Select Expiry Date' : 'Expires: ${DateFormat.yMMMd().format(_expiryDate!)}', style: const TextStyle(color: Colors.white)),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now().add(const Duration(days: 7)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _expiryDate = date);
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final db = context.read<DatabaseService>();
              final code = _codeController.text;
              final amount = double.tryParse(_amountController.text) ?? 0.0;
              final expiry = _expiryDate ?? DateTime.now().add(const Duration(days: 7));

              await db.sendPromoCode(code: code, discountAmount: amount, expiryDate: expiry);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Promo code sent successfully')));
            },
            child: const Text('SEND'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<PromoCode>>(
        stream: db.promoCodesRef.snapshots().map((s) => s.docs.map((d) => d.data()).toList()),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final promos = snapshot.data!;

          if (promos.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 64, color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text('No promo codes created yet.', style: TextStyle(color: Colors.white54)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _showPromoDialog,
                    child: const Text('CREATE YOUR FIRST PROMO'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              final promo = promos[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassCard(
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(promo.code, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('Ksh ${promo.discountAmount} off • Expires ${DateFormat.yMMMd().format(promo.expiryDate)}', style: const TextStyle(color: AppTheme.gold)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(promo.isActive ? Icons.check_circle : Icons.cancel, color: promo.isActive ? Colors.green : Colors.red, size: 20),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Promo?'),
                                content: const Text('This will permanently remove this code.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
                                  ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('DELETE')),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              await db.pricingAddonsRef.doc(promo.id).delete();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPromoDialog(),
        backgroundColor: AppTheme.gold,
        child: const Icon(Icons.send, color: Colors.black),
      ),
    );
  }
}
