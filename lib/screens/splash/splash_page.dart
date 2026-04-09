// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../auth/login_page.dart';

/// Splash screen shown on launch for 2 seconds before navigating to login.
/// Uses a deep-purple gradient background with the Wi logo mark.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  /// Drives the fade-in animation for the logo and tagline.
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  // ── Lifecycle ──────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();

    // Fade-in over 800 ms.
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );
    _animController.forward();

    // Navigate to login after 2 seconds.
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Deep-purple gradient background.
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.splashPurple, AppColors.darkPurple],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Logo mark ─────────────────────────────────────────────
                _WiLogoMark(),
                const SizedBox(height: 24),
                // ── App name tagline ───────────────────────────────────────
                const Text(
                  'Wi Tajikistan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 48),
                // ── Loading indicator ─────────────────────────────────────
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.sunglow,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded-square logo mark with a wisteria→sunglow gradient and bold "Wi".
class _WiLogoMark extends StatelessWidget {
  const _WiLogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        // Diagonal gradient from wisteria to amber.
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.wisteria, AppColors.sunglow],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.wisteria.withOpacity(0.45),
            blurRadius: 32,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Center(
        child: Text(
          'Wi',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: AppColors.white,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }
}
