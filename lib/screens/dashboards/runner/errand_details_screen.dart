import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../models/app_models.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/glass_card.dart';

class ErrandDetailsScreen extends StatefulWidget {
  final Errand errand;

  const ErrandDetailsScreen({super.key, required this.errand});

  @override
  State<ErrandDetailsScreen> createState() => _ErrandDetailsScreenState();
}

class _ErrandDetailsScreenState extends State<ErrandDetailsScreen> {
  bool _isAccepting = false;

  Future<void> _acceptErrand() async {
    setState(() => _isAccepting = true);

    final db = context.read<DatabaseService>();
    final auth = context.read<AuthService>();
    final user = await auth.getCurrentUserData();

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You must be logged in to accept an errand.')),
        );
        setState(() => _isAccepting = false);
      }
      return;
    }

    try {
      await db.acceptErrand(widget.errand.id, user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Errand accepted!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept errand: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Errand Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GlassCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          widget.errand.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      if (widget.errand.isBulky)
                        const Chip(
                          label: Text('BULKY', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10)),
                          backgroundColor: AppTheme.gold,
                          padding: EdgeInsets.zero,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Posted ${DateFormat.yMMMd().add_jm().format(widget.errand.createdAt)}',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.errand.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 24),
                  _buildDetailRow(context, Icons.location_on, 'Pickup', widget.errand.pickupLocation),
                  if (widget.errand.hasStopOver && widget.errand.stopOverLocation != null) ...[
                    const SizedBox(height: 16),
                    _buildDetailRow(context, Icons.swap_calls, 'Stop Over', widget.errand.stopOverLocation!),
                  ],
                  const SizedBox(height: 16),
                  _buildDetailRow(context, Icons.flag, 'Drop-off', widget.errand.deliveryLocation),
                  const SizedBox(height: 16),
                  if (widget.errand.alternativeContact != null)
                    _buildDetailRow(context, Icons.contact_phone, 'Alt. Contact', widget.errand.alternativeContact!),
                  
                  const Divider(color: Colors.white24, height: 32),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Payment Type', style: TextStyle(color: Colors.white70)),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: widget.errand.paymentType == 'pay_now' ? Colors.green.withValues(alpha: 0.2) : Colors.blue.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: widget.errand.paymentType == 'pay_now' ? Colors.green : Colors.blue),
                            ),
                            child: Text(
                              widget.errand.paymentType == 'pay_now' ? 'PAY NOW (Verified)' : 'PAY LATER',
                              style: TextStyle(
                                color: widget.errand.paymentType == 'pay_now' ? Colors.green : Colors.blue,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Total Offer', style: TextStyle(color: Colors.white70)),
                          Text(
                            'KES ${widget.errand.estimatedPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppTheme.gold, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          if (widget.errand.surcharge > 0)
                            Text(
                              '(Incl. KES ${widget.errand.surcharge.toStringAsFixed(0)} Surcharge)',
                              style: const TextStyle(color: Colors.orange, fontSize: 10),
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.gold),
                  const SizedBox(height: 24),
                  _isAccepting
                      ? const Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            ElevatedButton(
                              onPressed: _acceptErrand,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 20),
                                backgroundColor: AppTheme.gold,
                                foregroundColor: Colors.black,
                              ),
                              child: Center(child: Text('ACCEPT ERRAND', style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold))),
                            ),
                            const SizedBox(height: 12),
                            TextButton.icon(
                              onPressed: () {
                                 showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: AppTheme.background,
                                      title: const Text('Report Scope Inaccuracy', style: TextStyle(color: Colors.white)),
                                      content: const Text('If you believe this errand has an inaccurate location or scope, please accept it first, then use the "Request Surcharge" feature from your active task screen.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
                                      ],
                                    ),
                                 );
                              },
                              icon: const Icon(Icons.report_problem, color: Colors.orange),
                              label: const Text('Report Inaccurate Scope/Location', style: TextStyle(color: Colors.orange)),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.gold, size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        )
      ],
    );
  }
}
