import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_models.dart';
import '../../../services/database_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/errand_list_item.dart';
import '../../../widgets/glass_card.dart';

class ErrandHistoryScreen extends StatelessWidget {
  final String userId;
  final String userName;

  const ErrandHistoryScreen({super.key, required this.userId, required this.userName});

  @override
  Widget build(BuildContext context) {
    final db = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: Text('$userName\'s History')),
      body: StreamBuilder<List<Errand>>(
        stream: db.streamCustomerErrands(userId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final errands = snapshot.data!;
          
          if (errands.isEmpty) {
            return const Center(child: Text('No errands found for this user.', style: TextStyle(color: Colors.white54)));
          }

          final totalSpent = errands.fold(0.0, (sum, e) => sum + e.estimatedPrice);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          const Text('Total Errands', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('${errands.length}', style: const TextStyle(color: AppTheme.gold, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Container(height: 30, width: 1, color: Colors.white10),
                      Column(
                        children: [
                          const Text('Total Value', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          Text('KES ${totalSpent.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: errands.length,
                  itemBuilder: (context, index) => ErrandListItem(errand: errands[index]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
