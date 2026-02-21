import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_models.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';

class ActiveTaskScreen extends StatelessWidget {
  const ActiveTaskScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final runnerId = authService.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Errand'),
      ),
      body: runnerId == null
          ? const Center(child: Text('User not logged in.'))
          : StreamBuilder<Errand?>(
              stream: databaseService.getActiveErrand(runnerId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data == null) {
                  return const Center(
                    child: Text(
                      'No active errand at the moment.',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  );
                }

                final errand = snapshot.data!;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildErrandDetailCard(errand),
                      const SizedBox(height: 24),
                      _buildCustomerInfoCard(context, errand.customerId),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ElevatedButton(
                            onPressed: () =>
                                _showConfirmationDialog(context, errand, databaseService),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.maroon,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                              textStyle: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            child: const Text('Mark as Complete'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => _showSurchargeDialog(context, errand, databaseService),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.gold,
                              side: const BorderSide(color: AppTheme.gold),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                            ),
                            child: const Text('Request Surcharge'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton(
                            onPressed: () => _showPostponeDialog(context, errand, databaseService),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.orange,
                              side: const BorderSide(color: Colors.orange),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 15),
                            ),
                            child: const Text('Postpone'),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildErrandDetailCard(Errand errand) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errand.title,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.gold),
            ),
            const SizedBox(height: 12),
            Text(
              errand.description,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Divider(height: 30, thickness: 1, color: Colors.white10),
            _buildLocationRow(Icons.location_on, 'Pickup', errand.pickupLocation),
            const SizedBox(height: 12),
            _buildLocationRow(Icons.pin_drop, 'Delivery', errand.deliveryLocation),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(IconData icon, String label, String location) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.gold, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.gold)),
              const SizedBox(height: 4),
              Text(location, style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoCard(BuildContext context, String customerId) {
    return FutureBuilder<AppUser?>(
      future: Provider.of<DatabaseService>(context, listen: false).getUser(customerId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: Text('Loading customer details...'));
        }

        final customer = snapshot.data!;
        return Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Customer Information',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.gold),
                ),
                const SizedBox(height: 12),
                Text('Name: ${customer.name}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
                const SizedBox(height: 8),
                Text('Phone: ${customer.phoneNumber}',
                    style: const TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSurchargeDialog(BuildContext context, Errand errand, DatabaseService db) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Request Surcharge', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('If the customer provided a wrong location or the scope is larger than described, enter the additional amount (Ksh) and a reason.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Additional Amount (Ksh)', labelStyle: TextStyle(color: AppTheme.gold)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                await db.reportBulkyErrand(errand.id, 'Inaccurate Scope/Location', amount);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Surcharge request sent to customer.')));
                }
              }
            },
            child: const Text('REQUEST'),
          ),
        ],
      ),
    );
  }

  void _showPostponeDialog(BuildContext context, Errand errand, DatabaseService db) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.background,
        title: const Text('Postpone Errand', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter reason for postponement (e.g., Heavy Rain, Security issues). This will alert the customer.', style: TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'Reason', labelStyle: TextStyle(color: AppTheme.gold)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                await db.postponeErrand(errand.id, controller.text);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Errand postponed.')));
                }
              }
            },
            child: const Text('POSTPONE'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(
      BuildContext context, Errand errand, DatabaseService databaseService) {
    final vCodeController = TextEditingController();
    final amountController = TextEditingController(text: errand.estimatedPrice.toString());
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.background,
          title: const Text('Confirm Completion', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('1. Ask customer for the 6-character Code.', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const Text('2. Confirm the total amount received.', style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 16),
              TextField(
                controller: vCodeController,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 4),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(labelText: 'Verification Code', labelStyle: TextStyle(color: AppTheme.gold)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Total Amount Received (KES)', labelStyle: TextStyle(color: AppTheme.gold)),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            ElevatedButton(
              child: const Text('VERIFY & COMPLETE'),
              onPressed: () async {
                try {
                  final received = double.tryParse(amountController.text) ?? 0.0;
                  await databaseService.completeErrand(
                    errand.id, 
                    errand.runnerId!, 
                    vCodeController.text.trim().toUpperCase(),
                    received,
                  );
                  if (context.mounted) {
                    Navigator.of(dialogContext).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Errand verified and payment confirmed!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
