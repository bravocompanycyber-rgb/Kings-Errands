import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/app_models.dart';
import '../theme/app_theme.dart';

class ErrandListItem extends StatelessWidget {
  final Errand errand;

  const ErrandListItem({super.key, required this.errand});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              errand.title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(context, Icons.location_on, 'From: ${errand.pickupLocation}'),
            const SizedBox(height: 4),
            _buildInfoRow(context, Icons.flag, 'To: ${errand.deliveryLocation}'),
            const SizedBox(height: 12),
            const Divider(color: AppTheme.gold, thickness: 0.5),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildStatusChip(errand.status),
                    if (errand.isBulky) ...[
                      const SizedBox(width: 8),
                      const Chip(label: Text('Bulky', style: TextStyle(fontSize: 10, color: Colors.black)), backgroundColor: AppTheme.gold, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    ],
                    if (errand.hasStopOver) ...[
                      const SizedBox(width: 8),
                      const Chip(label: Text('Stop Over', style: TextStyle(fontSize: 10, color: Colors.white)), backgroundColor: Colors.purple, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                    ],
                  ],
                ),
                if (errand.status == 'in progress' && errand.verificationCode != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.gold.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.gold, width: 1),
                    ),
                    child: Column(
                      children: [
                        const Text('CODE FOR RUNNER', style: TextStyle(color: Colors.white70, fontSize: 8)),
                        Text(errand.verificationCode!, style: const TextStyle(color: AppTheme.gold, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 2)),
                      ],
                    ),
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'KES ${errand.estimatedPrice.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.gold, fontWeight: FontWeight.bold),
                    ),
                    if (errand.surcharge > 0)
                      Text(
                        '+ KES ${errand.surcharge.toStringAsFixed(2)} Surcharge',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.orange, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ],
            ),
             const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'Posted: ${DateFormat.yMMMd().add_jm().format(errand.createdAt)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.gold, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String chipText;

    switch (status.toLowerCase()) {
      case 'pending':
        chipColor = Colors.orange;
        chipText = 'Pending';
        break;
      case 'in progress':
        chipColor = Colors.blue;
        chipText = 'In Progress';
        break;
      case 'completed':
        chipColor = Colors.green;
        chipText = 'Completed';
        break;
      case 'cancelled':
        chipColor = Colors.red;
        chipText = 'Cancelled';
        break;
      default:
        chipColor = Colors.grey;
        chipText = status.toUpperCase();
    }

    return Chip(
      label: Text(chipText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      backgroundColor: chipColor,
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      labelPadding: EdgeInsets.zero,
    );
  }
}
