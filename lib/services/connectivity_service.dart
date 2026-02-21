import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  Stream<ConnectivityResult> get connectivityStream {
    return _connectivity.onConnectivityChanged.map((results) => results.first);
  }

  Future<ConnectivityResult> get initialConnectivity async {
    final results = await _connectivity.checkConnectivity();
    return results.first;
  }
}
