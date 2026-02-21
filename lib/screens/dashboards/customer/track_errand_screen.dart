import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/app_models.dart';
import '../../../services/auth_service.dart';
import '../../../services/database_service.dart';
import '../../../widgets/errand_list_item.dart';

class TrackErrandScreen extends StatelessWidget {
  const TrackErrandScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<AuthService>();
    final databaseService = context.read<DatabaseService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Track My Errands')),
      body: StreamBuilder<AppUser?>(
        stream: authService.currentUserDataStream,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!userSnapshot.hasData || userSnapshot.data == null) {
            return const Center(child: Text('You must be logged in to view your errands.'));
          }

          final customerId = userSnapshot.data!.id;

          return StreamBuilder<List<Errand>>(
            stream: databaseService.streamCustomerErrands(customerId),
            builder: (context, errandSnapshot) {
              if (errandSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!errandSnapshot.hasData || errandSnapshot.data!.isEmpty) {
                return const Center(child: Text('You have not posted any errands yet.'));
              }

              final errands = errandSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: errands.length,
                itemBuilder: (context, index) {
                  final errand = errands[index];
                  return ErrandListItem(errand: errand);
                },
              );
            },
          );
        },
      ),
    );
  }
}
