import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _faqs = [
    (
      'What does "Dead Zone" mean?',
      'A Dead Zone means no sensor node is responding. Both the primary node (Node 1) and the backup node (Node 3) are offline, so the area is not being monitored. Check power and network connectivity of the nodes.'
    ),
    (
      'What is the Backup Node?',
      'Node 3 is a redundant sensor node. When the primary node (Node 1) goes offline, the system automatically switches to Node 3 so monitoring continues without interruption. A "BACKUP" badge is shown while it is active.'
    ),
    (
      'How does the ML prediction work?',
      'A machine learning model analyses the live sensor readings (MQ2, MQ135, temperature, humidity) and classifies the air quality — Good, Moderate, Unhealthy or Danger — along with a confidence score and reason.'
    ),
    (
      'What happens when I press SOS?',
      'An emergency SOS message is broadcast through the system so nearby devices and monitors are alerted immediately. You can cancel an active SOS from the dashboard banner.'
    ),
    (
      'Why is a zone marked DANGER when vibration is detected?',
      'Vibration can indicate structural instability or machinery failure, so any vibrating zone is automatically escalated to DANGER regardless of air quality readings.'
    ),
    (
      'Where is the history data stored?',
      'Recent readings are kept on the device for each node, and all sensor logs are stored in Firebase. The Analytics tab lets you filter cloud history by node, status and date, with charts and trends.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          // ── Header ──
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: c.accent.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.support_agent_rounded,
                    color: c.accent,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'How can we help you?',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          Text(
            'FREQUENTLY ASKED QUESTIONS',
            style: TextStyle(
              color: c.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),

          for (final (q, a) in _faqs)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: c.border),
                boxShadow: c.cardShadow,
              ),
              child: Theme(
                data: Theme.of(context).copyWith(
                  dividerColor: Colors.transparent,
                ),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 2,
                  ),
                  childrenPadding:
                      const EdgeInsets.fromLTRB(
                    15,
                    0,
                    15,
                    14,
                  ),
                  iconColor: c.accent,
                  collapsedIconColor: c.textMuted,
                  title: Text(
                    q,
                    style: TextStyle(
                      color: c.textPrimary,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        a,
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 12.5,
                          height: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // ── Troubleshooting ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
              boxShadow: c.cardShadow,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'TROUBLESHOOTING',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                _tip(c,
                    'App shows "Connecting to MQTT..." — check that your device has internet access and the MQTT broker is reachable.'),
                _tip(c,
                    'No data on the dashboard — pull down to refresh, or verify that the sensor nodes are powered on.'),
                _tip(c,
                    'Analytics shows "No data found" — reset the filters, or confirm the device can reach Firebase.',
                    isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tip(AppColors c, String text,
      {bool isLast = false}) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(
              Icons.check_circle_rounded,
              size: 15,
              color: c.accent,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: c.textSecondary,
                fontSize: 12.5,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
