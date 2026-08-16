import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mqtt_service.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import 'history_screen.dart';

class ZoneDetailScreen extends StatelessWidget {
  final SensorData data;

  const ZoneDetailScreen({
    super.key,
    required this.data,
  });

  String _effectiveStatus(SensorData data, MqttService mqtt) {
    if (data.vibration.toUpperCase() == 'VIBRATING') {
      return 'DANGER';
    }

    final ml = mqtt.getMLResult(data.nodeNumber);

    if (ml == null || ml.isEmpty) {
      return data.overallStatus;
    }

    switch (ml.toUpperCase()) {
      case 'DANGER':
        return 'DANGER';
      case 'CRITICAL':
        return 'CRITICAL';
      case 'UNHEALTHY':
        return 'CRITICAL';
      case 'UNHEALTHY FOR SENSITIVE GROUPS':
      case 'UNHEALTHY FOR SENSITIVE GROUP':
        return 'DANGER';
      case 'MODERATE':
        return 'MODERATE';
      case 'GOOD':
        return 'SAFE';
      default:
        return data.overallStatus;
    }
  }

  void _openHistory(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryScreen(
          nodeNumber: data.nodeNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = context.watch<MqttService>();
    final c = AppColors.of(context);

    final status = _effectiveStatus(data, mqtt);
    final statusColor = c.statusColor(status);
    final mlResult = mqtt.getMLResult(data.nodeNumber);
    final confidence = mqtt.getMLConfidence(data.nodeNumber);
    final reason = mqtt.getMLReason(data.nodeNumber);
    final isVibrating =
        data.vibration.toUpperCase() == 'VIBRATING';

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text('Node ${data.nodeNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Sensor History',
            onPressed: () => _openHistory(context),
          ),
          const ThemeToggleButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          // ── Status hero card ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: statusColor.withOpacity(0.35),
                width: 1.2,
              ),
              boxShadow: c.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isVibrating
                        ? Icons.warning_rounded
                        : Icons.sensors_rounded,
                    color: statusColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT STATUS',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // ── ML prediction card ──
          if (mlResult != null)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: c.accent.withOpacity(0.35),
                ),
                boxShadow: c.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: c.accent.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.psychology_rounded,
                          color: c.accent,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'ML PREDICTION',
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const Spacer(),
                      if (confidence != null)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                c.accent.withOpacity(0.12),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${(confidence * 100).toStringAsFixed(1)}%',
                            style: TextStyle(
                              color: c.accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    mlResult,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                  if (confidence != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            confidence.clamp(0.0, 1.0).toDouble(),
                        backgroundColor: c.surfaceAlt,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(
                          c.accent,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ],
                  if (reason != null &&
                      reason.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Reason: $reason',
                      style: TextStyle(
                        color: c.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // ── Vibration warning ──
          if (isVibrating)
            Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: c.danger
                    .withOpacity(c.isDark ? 0.12 : 0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: c.danger.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_rounded,
                    color: c.danger,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Vibration detected — Zone marked as DANGER',
                      style: TextStyle(
                        color: c.danger,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          Text(
            'SENSOR READINGS',
            style: TextStyle(
              color: c.textMuted,
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 10),

          _sensorRow(
            c,
            Icons.local_fire_department_rounded,
            'MQ2 · LPG / Smoke',
            data.mq2Value,
            4095,
            data.mq2Status,
          ),
          _sensorRow(
            c,
            Icons.air_rounded,
            'MQ135 · Air Quality',
            data.mq135Value,
            4095,
            data.mq135Status,
          ),
          _sensorRow(
            c,
            Icons.thermostat_rounded,
            'Temperature',
            data.temp.toInt(),
            60,
            'INFO',
            subtitle: '${data.temp}°C',
          ),
          _sensorRow(
            c,
            Icons.water_drop_rounded,
            'Humidity',
            data.humidity.toInt(),
            100,
            'INFO',
            subtitle: '${data.humidity}%',
          ),

          const SizedBox(height: 4),

          // ── Vibration card ──
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: c.border),
              boxShadow: c.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: c.purple.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.vibration_rounded,
                    color: c.purple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Vibration',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: (isVibrating ? c.critical : c.safe)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data.vibration,
                    style: TextStyle(
                      color:
                          isVibrating ? c.critical : c.safe,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── History button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openHistory(context),
              icon: const Icon(Icons.history_rounded),
              label: const Text(
                'View Sensor History',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: c.accent
                    .withOpacity(c.isDark ? 0.14 : 0.1),
                foregroundColor: c.accent,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sensorRow(
    AppColors c,
    IconData icon,
    String label,
    int value,
    int max,
    String status, {
    String? subtitle,
  }) {
    Color barColor;

    switch (status.toUpperCase()) {
      case 'CRITICAL':
        barColor = c.critical;
        break;
      case 'DANGER':
        barColor = c.danger;
        break;
      default:
        barColor = c.accent;
    }

    double progress = max > 0 ? value / max : 0;
    progress = progress.clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: barColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                subtitle ?? value.toString(),
                style: TextStyle(
                  color: c.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: animated,
                  backgroundColor: c.surfaceAlt,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(barColor),
                  minHeight: 7,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
