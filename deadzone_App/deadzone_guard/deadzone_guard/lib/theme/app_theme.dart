// ═══════════════════════════════════════════════════════════════════
//  app_theme.dart  —  DeadZone Guard Theme System
//
//  HOW TO WIRE THIS UP (main.dart):
//
//  1. Add to pubspec.yaml dependencies:
//         shared_preferences: ^2.2.0
//
//  2. In main.dart:
//
//     import 'package:provider/provider.dart';
//     import 'theme/app_theme.dart';
//
//     void main() async {
//       WidgetsFlutterBinding.ensureInitialized();
//       final themeProvider = ThemeProvider();
//       await themeProvider.load();
//       runApp(
//         MultiProvider(
//           providers: [
//             ChangeNotifierProvider(create: (_) => MqttService()),
//             ChangeNotifierProvider.value(value: themeProvider),
//           ],
//           child: const MyApp(),
//         ),
//       );
//     }
//
//     class MyApp extends StatelessWidget {
//       const MyApp({super.key});
//       @override
//       Widget build(BuildContext context) {
//         final theme = context.watch<ThemeProvider>();
//         return MaterialApp(
//           title: 'DeadZone Guard',
//           debugShowCheckedModeBanner: false,
//           theme: AppTheme.light,
//           darkTheme: AppTheme.dark,
//           themeMode: theme.mode,
//           home: const DashboardScreen(),
//         );
//       }
//     }
// ═══════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ───────────────────────────────────────────────
//  SEMANTIC COLOR TOKENS  (dark + light variants)
// ───────────────────────────────────────────────
class AppColors {
  final Brightness brightness;

  // Surfaces
  final Color background;
  final Color surface;       // cards
  final Color surfaceAlt;    // inputs / nested surfaces
  final Color border;

  // Text
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  // Status
  final Color critical;
  final Color danger;
  final Color moderate;
  final Color safe;
  final Color accent;   // info / ML
  final Color purple;   // vibration

  // SOS
  final Color sosBg;
  final Color sosBorder;
  final Color sosText;
  final Color sosTextSoft;

  // Dead zone
  final Color deadZoneBg;
  final Color deadZoneBorder;
  final Color deadZoneIcon;
  final Color deadZoneText;

  const AppColors({
    required this.brightness,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.critical,
    required this.danger,
    required this.moderate,
    required this.safe,
    required this.accent,
    required this.purple,
    required this.sosBg,
    required this.sosBorder,
    required this.sosText,
    required this.sosTextSoft,
    required this.deadZoneBg,
    required this.deadZoneBorder,
    required this.deadZoneIcon,
    required this.deadZoneText,
  });

  bool get isDark => brightness == Brightness.dark;

  static const AppColors darkColors = AppColors(
    brightness: Brightness.dark,
    background: Color(0xFF0B1220),
    surface: Color(0xFF16213A),
    surfaceAlt: Color(0xFF0F172A),
    border: Color(0xFF27324A),
    textPrimary: Color(0xFFF1F5F9),
    textSecondary: Color(0xFF94A3B8),
    textMuted: Color(0xFF64748B),
    critical: Color(0xFFF87171),
    danger: Color(0xFFFB923C),
    moderate: Color(0xFFFACC15),
    safe: Color(0xFF4ADE80),
    accent: Color(0xFF60A5FA),
    purple: Color(0xFFA78BFA),
    sosBg: Color(0xFF7F1D1D),
    sosBorder: Color(0xFFDC2626),
    sosText: Color(0xFFF87171),
    sosTextSoft: Color(0xFFFCA5A5),
    deadZoneBg: Color(0xFF1C1917),
    deadZoneBorder: Color(0xFF57534E),
    deadZoneIcon: Color(0xFF78716C),
    deadZoneText: Color(0xFFA8A29E),
  );

  static const AppColors lightColors = AppColors(
    brightness: Brightness.light,
    background: Color(0xFFF5F7FB),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFEFF3F9),
    border: Color(0xFFE3E8F0),
    textPrimary: Color(0xFF0F172A),
    textSecondary: Color(0xFF475569),
    textMuted: Color(0xFF94A3B8),
    critical: Color(0xFFDC2626),
    danger: Color(0xFFEA580C),
    moderate: Color(0xFFCA8A04),
    safe: Color(0xFF16A34A),
    accent: Color(0xFF2563EB),
    purple: Color(0xFF7C3AED),
    sosBg: Color(0xFFFEE2E2),
    sosBorder: Color(0xFFDC2626),
    sosText: Color(0xFFB91C1C),
    sosTextSoft: Color(0xFF991B1B),
    deadZoneBg: Color(0xFFF5F5F4),
    deadZoneBorder: Color(0xFFD6D3D1),
    deadZoneIcon: Color(0xFF78716C),
    deadZoneText: Color(0xFF57534E),
  );

  /// Resolve the token set from the active theme.
  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? darkColors
          : lightColors;

  // ── Status helpers ──
  Color statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'CRITICAL':
      case 'UNHEALTHY':
        return critical;
      case 'DANGER':
      case 'UNHEALTHY FOR SENSITIVE GROUPS':
      case 'UNHEALTHY FOR SENSITIVE GROUP':
        return danger;
      case 'MODERATE':
        return moderate;
      default:
        return safe;
    }
  }

  /// Soft, tinted background behind a status card.
  Color statusBg(String status) =>
      statusColor(status).withOpacity(isDark ? 0.12 : 0.08);

  /// Card shadow — soft in light mode, none in dark mode
  /// (dark mode relies on borders instead).
  List<BoxShadow> get cardShadow => isDark
      ? const []
      : [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ];
}

// ───────────────────────────────────────────────
//  THEME DATA
// ───────────────────────────────────────────────
class AppTheme {
  static ThemeData get dark => _build(AppColors.darkColors);
  static ThemeData get light => _build(AppColors.lightColors);

  static ThemeData _build(AppColors c) {
    final base = c.isDark ? ThemeData.dark() : ThemeData.light();

    return base.copyWith(
      brightness: c.brightness,
      scaffoldBackgroundColor: c.background,
      colorScheme: base.colorScheme.copyWith(
        brightness: c.brightness,
        primary: c.accent,
        secondary: c.accent,
        surface: c.surface,
        error: c.critical,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: c.background,
        foregroundColor: c.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: c.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: c.textSecondary),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.surface,
        contentTextStyle: TextStyle(color: c.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      dividerColor: c.border,
      popupMenuTheme: PopupMenuThemeData(
        color: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: TextStyle(color: c.textPrimary, fontSize: 14),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: c.surface,
        headerForegroundColor: c.textPrimary,
      ),
    );
  }
}

// ───────────────────────────────────────────────
//  THEME PROVIDER  (light / dark / system + persistence)
// ───────────────────────────────────────────────
class ThemeProvider extends ChangeNotifier {
  static const _prefKey = 'app_theme_mode';

  ThemeMode _mode = ThemeMode.light;
  ThemeMode get mode => _mode;

  /// Call once at startup (before runApp) to restore the saved choice.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_prefKey);
      switch (saved) {
        case 'light':
          _mode = ThemeMode.light;
          break;
        case 'dark':
          _mode = ThemeMode.dark;
          break;
        case 'system':
          _mode = ThemeMode.system;
          break;
      }
    } catch (_) {
      // Persistence unavailable — keep default.
    }
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, mode.name);
    } catch (_) {}
  }
}

// ───────────────────────────────────────────────
//  THEME TOGGLE BUTTON  (drop into any AppBar actions)
// ───────────────────────────────────────────────
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final c = AppColors.of(context);

    IconData iconFor(ThemeMode m) {
      switch (m) {
        case ThemeMode.light:
          return Icons.light_mode_rounded;
        case ThemeMode.dark:
          return Icons.dark_mode_rounded;
        case ThemeMode.system:
          return Icons.brightness_auto_rounded;
      }
    }

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Theme',
      position: PopupMenuPosition.under,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, anim) => RotationTransition(
          turns: Tween(begin: 0.7, end: 1.0).animate(anim),
          child: FadeTransition(opacity: anim, child: child),
        ),
        child: Icon(
          iconFor(theme.mode),
          key: ValueKey(theme.mode),
          color: c.accent,
        ),
      ),
      onSelected: (m) => context.read<ThemeProvider>().setMode(m),
      itemBuilder: (context) => [
        _item(context, ThemeMode.light, 'Light',
            Icons.light_mode_rounded, theme.mode),
        _item(context, ThemeMode.dark, 'Dark',
            Icons.dark_mode_rounded, theme.mode),
        _item(context, ThemeMode.system, 'System',
            Icons.brightness_auto_rounded, theme.mode),
      ],
    );
  }

  PopupMenuItem<ThemeMode> _item(
    BuildContext context,
    ThemeMode mode,
    String label,
    IconData icon,
    ThemeMode current,
  ) {
    final c = AppColors.of(context);
    final selected = mode == current;

    return PopupMenuItem<ThemeMode>(
      value: mode,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: selected ? c.accent : c.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: selected ? c.accent : c.textPrimary,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          if (selected)
            Icon(Icons.check_rounded, size: 16, color: c.accent),
        ],
      ),
    );
  }
}
