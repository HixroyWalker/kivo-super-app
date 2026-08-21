import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/dark_theme.dart';
import 'core/services/auth_provider.dart';
import 'core/services/wallet_provider.dart';
import 'core/services/marketplace_provider.dart';
import 'core/services/chat_provider.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/dashboard/screens/dashboard_screen.dart';
import 'features/wallet/screens/wallet_screen.dart';
import 'features/marketplace/screens/marketplace_screen.dart';
import 'features/messaging/screens/messaging_screen.dart';
import 'features/accounting/screens/accounting_screen.dart';
import 'features/merchant/screens/pos_cashier_screen.dart';
import 'features/merchant/screens/merchant_kyc_screen.dart';
import 'features/notifications/screens/notifications_screen.dart';
import 'features/ads/screens/ads_screen.dart';
import 'core/services/social_feed_provider.dart';
import 'core/services/voice_soundbox_service.dart';
import 'core/services/recurring_transfer_service.dart';
import 'ui/screens/social/social_feed_screen.dart';
import 'ui/screens/social/create_post_screen.dart';
import 'ui/screens/wallet/standing_orders_screen.dart';
import 'features/profile/screens/profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
    await AdMobService.initialize();
  } catch (e) {
    debugPrint('Firebase/AdMob init fallback: $e');
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => WalletProvider()),
        ChangeNotifierProvider(create: (_) => MarketplaceProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => SocialFeedProvider()),
        ChangeNotifierProvider(create: (_) => VoiceSoundboxService()),
        ChangeNotifierProvider(create: (_) => RecurringTransferService()),
      ],
      child: const KivoApp(),
    ),
  );
}

class KivoApp extends StatelessWidget {
  const KivoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kivo Super App',
      debugShowCheckedModeBanner: false,
      theme: KivoDarkTheme.darkTheme,
      home: const AuthGate(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/main': (context) => const MainShell(),
        '/dashboard': (context) => const DashboardScreen(),
        '/wallet': (context) => const WalletScreen(),
        '/marketplace': (context) => const MarketplaceScreen(),
        '/messaging': (context) => const MessagingScreen(),
        '/accounting': (context) => const AccountingScreen(),
        '/merchant_pos': (context) => const PosCashierScreen(),
        '/merchant_kyc': (context) => const MerchantKycScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/ads': (context) => const AdsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/social_feed': (context) => const SocialFeedScreen(),
        '/create_post': (context) => const CreatePostScreen(),
        '/standing_orders': (context) => const StandingOrdersScreen(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isAuthenticated) {
      return const MainShell();
    } else {
      return const LoginScreen();
    }
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    WalletScreen(),
    MarketplaceScreen(),
    MessagingScreen(),
    AccountingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadChats = context.watch<ChatProvider>().threads.fold<int>(0, (sum, t) => sum + t.unreadCount);
    final cartCount = context.watch<MarketplaceProvider>().cartCount;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: KivoDarkTheme.surface,
          border: Border(
            top: BorderSide(
              color: Colors.white.withOpacity(0.08),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            const NavigationDestination(
              icon: Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: Icon(Icons.account_balance_wallet),
              label: 'Wallet',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.storefront_outlined),
              ),
              selectedIcon: Badge(
                isLabelVisible: cartCount > 0,
                label: Text('$cartCount'),
                child: const Icon(Icons.storefront),
              ),
              label: 'Market',
            ),
            NavigationDestination(
              icon: Badge(
                isLabelVisible: unreadChats > 0,
                label: Text('$unreadChats'),
                child: const Icon(Icons.chat_bubble_outline),
              ),
              selectedIcon: Badge(
                isLabelVisible: unreadChats > 0,
                label: Text('$unreadChats'),
                child: const Icon(Icons.chat_bubble),
              ),
              label: 'Message',
            ),
            const NavigationDestination(
              icon: Icon(Icons.analytics_outlined),
              selectedIcon: Icon(Icons.analytics),
              label: 'Business',
            ),
          ],
        ),
      ),
    );
  }
}
