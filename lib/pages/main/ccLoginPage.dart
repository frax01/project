import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:club/main.dart';
import 'login.dart';

class CcLoginPage extends StatelessWidget {
  const CcLoginPage({super.key});

  /// Check if we are in the CC date range.
  /// Production: 1 April 2026 – 10 May 2026.
  /// For testing: includes today (1 March 2026 – 10 May 2026).
  static bool isActive() {
    final now = DateTime.now();
    final start = DateTime(2026, 3, 1);
    final end = DateTime(2026, 5, 10, 23, 59, 59);
    return now.isAfter(start) && now.isBefore(end);
  }

  Future<void> _enterCC(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('cc', 'yes');
    await prefs.setString('ccRole', 'user');
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => MyApp(club: '', cc: 'yes', ccRole: 'user', nome: ''),
      ),
      (route) => false,
    );
  }

  void _goToClubLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const Login(skipCcCheck: true)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'images/champions.jpg',
            fit: BoxFit.cover,
          ),

          // Blue tinted overlay with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF00296B).withValues(alpha: 0.60),
                  const Color(0xFF001845).withValues(alpha: 0.85),
                  const Color(0xFF001233).withValues(alpha: 0.95),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 30),

                // CC Logo
                Hero(
                  tag: 'cc_logo',
                  child: Image.asset(
                    'images/logo_champions_bianco.png',
                    width: 200,
                    height: 200,
                  ),
                ),

                // Year
                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [
                      Color(0xFF89B4FA),
                      Color(0xFFB8D4FE),
                      Color(0xFF89B4FA),
                    ],
                  ).createShader(bounds),
                  child: const Text(
                    '2026',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                ),

                const Spacer(flex: 8),

                // Enter CC button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _enterCC(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0052CC),
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor:
                            const Color(0xFF0052CC).withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Entra',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Go to Club login button
                TextButton.icon(
                  onPressed: () => _goToClubLogin(context),
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Colors.white70,
                  ),
                  label: const Text(
                    'Vai al login del Club',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white38,
                    ),
                  ),
                ),

                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
