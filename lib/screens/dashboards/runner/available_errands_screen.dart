import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_models.dart';
import '../../../services/database_service.dart';
import '../../../widgets/errand_list_item.dart';
import 'errand_details_screen.dart';

class AvailableErrandsScreen extends StatelessWidget {
  const AvailableErrandsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final databaseService = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Available Errands')),
      body: StreamBuilder<List<Errand>>(
        stream: databaseService.streamRunnerErrands(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No errands available at the moment.'));
          }

          final errands = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: errands.length,
            itemBuilder: (context, index) {
              final errand = errands[index];
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ErrandDetailsScreen(errand: errand),
                  ),
                ),
                child: ErrandListItem(errand: errand),
              );
            },
          );
        },
      ),
    );
  }
}
