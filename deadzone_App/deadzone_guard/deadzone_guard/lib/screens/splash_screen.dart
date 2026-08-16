import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'onboarding_screen.dart';
import 'main_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));

    bool onboardingDone = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      onboardingDone =
          prefs.getBool('onboarding_done') ?? false;
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => onboardingDone
            ? const MainShell()
            : const OnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 3),

            // ── Logo ──
            Container(
              padding: const EdgeInsets.all(26),
              decoration: BoxDecoration(
                color: c.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: c.accent.withOpacity(0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 52,
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── App name ──
            RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: c.textPrimary,
                ),
                children: const [
                  TextSpan(text: 'DeadZone '),
                  TextSpan(
                    text: 'Guard',
                    style:
                        TextStyle(color: Color(0xFFDC2626)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'IoT-Based Fault-Tolerant\nIndustrial Safety Monitoring System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: c.textSecondary,
                  fontSize: 13.5,
                  height: 1.5,
                ),
              ),
            ),

            const Spacer(flex: 3),

            Text(
              'Securing People. Monitoring Zones.\nEnsuring Safety.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textMuted,
                fontSize: 12,
                height: 1.6,
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: c.accent,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
