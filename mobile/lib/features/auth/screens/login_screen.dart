import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/dark_theme.dart';
import '../../../core/services/auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    auth.setSession('jwt_token_sample_session', 'usr_8923019');
    Navigator.pushReplacementNamed(context, '/main');
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    auth.setSession('jwt_token_sample_session', 'usr_8923019');
    Navigator.pushReplacementNamed(context, '/main');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0B0F14), Color(0xFF101922)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Glowing App Icon
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: KivoDarkTheme.primaryGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: KivoDarkTheme.primaryEmerald.withOpacity(0.35),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.flash_on, color: Colors.black, size: 48),
                ),
                const SizedBox(height: 24),
                const Text(
                  'KIVO',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'The Closed-Loop Super App for Jamaica 🇯🇲',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: KivoDarkTheme.textSecondary),
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: () => _handleGoogleSignIn(context),
                  icon: const Icon(Icons.g_mobiledata, size: 28),
                  label: const Text('Continue with Google'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                  ),
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: () => _handleAppleSignIn(context),
                  icon: const Icon(Icons.apple, size: 22),
                  label: const Text('Continue with Apple'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 54),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'By signing in, you agree to Kivo Security & TAJ compliance terms.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: KivoDarkTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
