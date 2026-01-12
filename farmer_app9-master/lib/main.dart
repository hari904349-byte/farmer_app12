import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';


import 'core/theme/app_theme.dart';
import 'core/language_provider.dart';
import 'onboarding/onboarding_screen.dart';

// DASHBOARDS
import 'farmer/farmer_dashboard.dart';
import 'customer/customer_home.dart';
import 'delivery/delivery_home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vksplwkzcpswzxssmuvn.supabase.co',
    anonKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZrc3Bsd2t6Y3Bzd3p4c3NtdXZuIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc2NzQ1MjUsImV4cCI6MjA4MzI1MDUyNX0.qHOEZUDZosuW3dRz6uVETLHj9Kanhvi0Wvb4IHNrmmo',
  );

  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider()..loadLanguage(),
      child: const FarmFreshConnectApp(),
    ),
  );
}

class FarmFreshConnectApp extends StatelessWidget {
  const FarmFreshConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Farm Fresh Connect',
      theme: AppTheme.lightTheme,

      // Entry point
      home: const OnboardingScreen(),

      routes: {
        '/farmer_dashboard': (context) => const FarmerDashboard(),
        '/customer_dashboard': (context) => const CustomerHome(),
        '/delivery_dashboard': (context) => const DeliveryHome(),
      },
    );
  }
}
