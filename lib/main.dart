import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/admin_provider.dart';
import 'theme/app_theme.dart';
import 'routes/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init warning (proceeding offline): $e');
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AdminProvider()..initFirebaseListeners(),
      child: const PrimeLifeCareAdminApp(),
    ),
  );
}

class PrimeLifeCareAdminApp extends StatelessWidget {
  const PrimeLifeCareAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Prime Life Care - Operations Admin Panel',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: appRouter,
    );
  }
}
