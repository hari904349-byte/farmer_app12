import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // ✅ ADD THIS

import 'core/theme/app_theme.dart';
import 'core/language_provider.dart';
import 'onboarding/onboarding_screen.dart';

// DASHBOARDS
import 'farmer/farmer_dashboard.dart';
import 'customer/customer_home.dart';
import 'delivery/delivery_home.dart';

// RESET PASSWORD
import 'auth/reset_password_page.dart';

final GlobalKey<NavigatorState> navigatorKey =
GlobalKey<NavigatorState>();

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

  // ✅ LISTEN AFTER APP STARTS
  WidgetsBinding.instance.addPostFrameCallback((_) {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.event == AuthChangeEvent.passwordRecovery) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => const ResetPasswordPage(),
          ),
        );
      }
    });
  });
}

class FarmFreshConnectApp extends StatelessWidget {
  const FarmFreshConnectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          debugShowCheckedModeBanner: false,
          title: 'Farm Fresh Connect',
          theme: AppTheme.lightTheme,

          // ✅ CORRECT LOCALIZATION SETUP
          locale: Locale(languageProvider.language),
          supportedLocales: const [
            Locale('en'),
            Locale('ta'),
            Locale('hi'),
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],

          home: const OnboardingScreen(),
          routes: {
            '/farmer_dashboard': (_) => const FarmerDashboard(),
            '/customer_dashboard': (_) => const CustomerHome(),
            '/delivery_dashboard': (_) => const DeliveryHome(),
          },
        );
      },
    );
  }
}
