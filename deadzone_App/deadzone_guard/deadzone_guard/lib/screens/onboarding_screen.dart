import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme/app_theme.dart';
import 'main_shell.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() =>
      _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [
    _OnboardPage(
      icon: Icons.sensors_rounded,
      title: 'Smart Monitoring\nfor Safer Industries',
      body:
          'Real-time monitoring of industrial dead zones and hazardous areas using IoT sensors — gas, temperature, humidity and vibration.',
    ),
    _OnboardPage(
      icon: Icons.shield_rounded,
      title: 'Fault-Tolerant\nAlways Reliable',
      body:
          'Redundant backup nodes and ML-based predictions ensure continuous protection, even when the primary sensor fails.',
    ),
  ];

  Future<void> _finish() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_done', true);
    } catch (_) {}

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final isLast = _page == _pages.length - 1;

    return Scaffold(
      backgroundColor: c.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) =>
                    setState(() => _page = i),
                itemBuilder: (context, i) {
                  final p = _pages[i];
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.body,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 48),
                        Container(
                          padding:
                              const EdgeInsets.all(44),
                          decoration: BoxDecoration(
                            color: c.accent
                                .withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Container(
                            padding:
                                const EdgeInsets.all(36),
                            decoration: BoxDecoration(
                              color: c.accent
                                  .withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              p.icon,
                              size: 84,
                              color: c.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Dots ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                final active = i == _page;
                return AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(
                      horizontal: 4),
                  width: active ? 22 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: active
                        ? c.accent
                        : c.accent.withOpacity(0.25),
                    borderRadius:
                        BorderRadius.circular(4),
                  ),
                );
              }),
            ),

            // ── Skip / Next ──
            Padding(
              padding:
                  const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _finish,
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () {
                      if (isLast) {
                        _finish();
                      } else {
                        _controller.nextPage(
                          duration: const Duration(
                              milliseconds: 300),
                          curve: Curves.easeOut,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding:
                          const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      isLast ? 'Get Started' : 'Next',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardPage {
  final IconData icon;
  final String title;
  final String body;

  const _OnboardPage({
    required this.icon,
    required this.title,
    required this.body,
  });
}
