import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mqtt_service.dart';
import '../theme/app_theme.dart';
import 'about_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final theme = context.watch<ThemeProvider>();
    final mqtt = context.watch<MqttService>();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Settings',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),

          const SizedBox(height: 20),

          // ── Appearance ──
          _sectionLabel(c, 'APPEARANCE'),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
              boxShadow: c.cardShadow,
            ),
            child: Column(
              children: [
                _themeOption(
                  context,
                  theme,
                  ThemeMode.light,
                  'Light',
                  Icons.light_mode_rounded,
                ),
                _themeOption(
                  context,
                  theme,
                  ThemeMode.dark,
                  'Dark',
                  Icons.dark_mode_rounded,
                ),
                _themeOption(
                  context,
                  theme,
                  ThemeMode.system,
                  'System Default',
                  Icons.brightness_auto_rounded,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── System ──
          _sectionLabel(c, 'SYSTEM'),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
              boxShadow: c.cardShadow,
            ),
            child: Column(
              children: [
                _infoRow(
                  c,
                  Icons.wifi_rounded,
                  'MQTT Connection',
                  mqtt.isConnected
                      ? 'Connected'
                      : 'Disconnected',
                  mqtt.isConnected ? c.safe : c.critical,
                ),
                Divider(
                    height: 1,
                    color: c.border,
                    indent: 52),
                _infoRow(
                  c,
                  Icons.router_rounded,
                  'Nodes Online',
                  '${mqtt.onlineNodeCount} / 2',
                  c.accent,
                ),
                Divider(
                    height: 1,
                    color: c.border,
                    indent: 52),
                _infoRow(
                  c,
                  Icons.monitor_heart_rounded,
                  'System Status',
                  mqtt.systemStatus,
                  c.textSecondary,
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // ── Support ──
          _sectionLabel(c, 'SUPPORT'),
          Container(
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
              boxShadow: c.cardShadow,
            ),
            child: Column(
              children: [
                _navRow(
                  context,
                  c,
                  Icons.help_rounded,
                  'Help & Support',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const HelpScreen(),
                      ),
                    );
                  },
                ),
                Divider(
                    height: 1,
                    color: c.border,
                    indent: 52),
                _navRow(
                  context,
                  c,
                  Icons.info_rounded,
                  'About',
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const AboutScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          Center(
            child: Text(
              'DeadZone Guard · Version 1.0.0',
              style: TextStyle(
                color: c.textMuted,
                fontSize: 11.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(AppColors c, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9, left: 2),
      child: Text(
        text,
        style: TextStyle(
          color: c.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
        ),
      ),
    );
  }

  Widget _themeOption(
    BuildContext context,
    ThemeProvider theme,
    ThemeMode mode,
    String label,
    IconData icon,
  ) {
    final c = AppColors.of(context);
    final selected = theme.mode == mode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () =>
            context.read<ThemeProvider>().setMode(mode),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: selected
                ? c.accent.withOpacity(0.08)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? c.accent
                    : c.textSecondary,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: selected
                        ? c.accent
                        : c.textPrimary,
                    fontSize: 14,
                    fontWeight: selected
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: c.accent,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(
    AppColors c,
    IconData icon,
    String label,
    String value,
    Color valueColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 13,
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: c.textSecondary),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navRow(
    BuildContext context,
    AppColors c,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),
          child: Row(
            children: [
              Icon(icon,
                  size: 20, color: c.textSecondary),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 14,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: c.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
