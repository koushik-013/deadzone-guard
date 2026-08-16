import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const SizedBox(height: 12),

          // ── Logo ──
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: c.accent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: c.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          Center(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: c.textPrimary,
                ),
                children: const [
                  TextSpan(text: 'DeadZone '),
                  TextSpan(
                    text: 'Guard',
                    style: TextStyle(
                        color: Color(0xFFDC2626)),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 6),

          Center(
            child: Text(
              'IoT-Based Fault-Tolerant\nIndustrial Safety Monitoring System',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),

          const SizedBox(height: 10),

          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: c.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Version 1.0.0',
                style: TextStyle(
                  color: c.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ── Description ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
              boxShadow: c.cardShadow,
            ),
            child: Text(
              'DeadZone Guard is designed to monitor industrial dead zones and hazardous areas in real-time using IoT sensors with a fault-tolerant system to ensure continuous safety.\n\n'
              'A primary sensor node (Node 1) continuously measures LPG/smoke (MQ2), air quality (MQ135), temperature, humidity and vibration. If the primary node fails, a backup node (Node 3) automatically takes over, so monitoring never stops. If no sensor responds at all, the area is flagged as a Dead Zone.',
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 13.5,
                height: 1.65,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Feature list ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
              boxShadow: c.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KEY FEATURES',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _feature(
                  c,
                  Icons.sensors_rounded,
                  'Real-time sensor monitoring',
                  'Live MQ2, MQ135, temperature, humidity and vibration data over MQTT.',
                ),
                _feature(
                  c,
                  Icons.psychology_rounded,
                  'ML-based air quality prediction',
                  'A machine learning model classifies air quality with confidence scores and reasons.',
                ),
                _feature(
                  c,
                  Icons.swap_horiz_rounded,
                  'Fault-tolerant backup node',
                  'Node 3 automatically activates when the primary node goes offline.',
                ),
                _feature(
                  c,
                  Icons.sos_rounded,
                  'One-tap SOS alert',
                  'Broadcast an emergency SOS message to the system instantly.',
                ),
                _feature(
                  c,
                  Icons.cloud_rounded,
                  'Cloud history & analytics',
                  'Sensor logs stored in Firebase with charts, filters and trends.',
                  isLast: true,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              '© 2026 DeadZone Guard\nAll rights reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.textMuted,
                fontSize: 11.5,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _feature(
    AppColors c,
    IconData icon,
    String title,
    String body, {
    bool isLast = false,
  }) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: c.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child:
                Icon(icon, size: 18, color: c.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
