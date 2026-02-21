import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/connectivity_service.dart';
import 'services/database_service.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboards/customer_dashboard.dart';
import 'screens/dashboards/runner_dashboard.dart';
import 'screens/dashboards/admin/admin_dashboard.dart';
import 'models/app_models.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        Provider<ConnectivityService>(create: (_) => ConnectivityService()),
        StreamProvider<User?>(
          create: (context) => context.read<AuthService>().user,
          initialData: null,
        ),
        StreamProvider<ConnectivityResult>(
          create: (context) => context.read<ConnectivityService>().connectivityStream,
          initialData: ConnectivityResult.mobile,
        ),
      ],
      child: MaterialApp(
        title: 'Kings Errands',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashScreen(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    if (user != null) {
      return FutureBuilder<AppUser?>(
        future: context.read<AuthService>().getCurrentUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          final userData = snapshot.data;
          if (userData == null) return const LoginScreen();

          switch (userData.role) {
            case 'admin':
              return const AdminDashboard();
            case 'runner':
              return const RunnerDashboard();
            case 'customer':
            default:
              return const CustomerDashboard();
          }
        },
      );
    } else {
      return const LoginScreen();
    }
  }
}
