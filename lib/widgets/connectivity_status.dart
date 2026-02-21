import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ConnectivityStatus extends StatelessWidget {
  const ConnectivityStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final connectivityResult = Provider.of<ConnectivityResult>(context);
    final isOffline = connectivityResult == ConnectivityResult.none;

    return isOffline
        ? Container(
            color: Colors.red,
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: const Text(
              'You are offline. Some features might be unavailable.',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
          )
        : const SizedBox.shrink();
  }
}
