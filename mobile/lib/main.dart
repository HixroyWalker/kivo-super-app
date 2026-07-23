import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/wallet/screens/wallet_screen.dart';
import 'features/marketplace/screens/marketplace_screen.dart';
import 'features/messaging/screens/messaging_screen.dart';
import 'features/accounting/screens/accounting_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Add firebase options for environment
  // await Firebase.initializeApp();
  runApp(const KivoApp());
}

class KivoApp extends StatelessWidget {
  const KivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kivo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/marketplace': (context) => const MarketplaceScreen(),
        '/messaging': (context) => const MessagingScreen(),
        '/accounting': (context) => const AccountingScreen(),
      },
    );
  }
}
