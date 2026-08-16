import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mqtt_service.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final mqtt = context.watch<MqttService>();
    final c = AppColors.of(context);

    // Only the active node raises alerts. The backup node stays on
    // standby until the primary goes offline, so its stored readings
    // must not appear here.
    final alerts = <SensorData>[];
    final activeData = mqtt.activeNodeData;

    if (activeData != null) {
      for (final h in mqtt.getHistory(activeData.nodeNumber)) {
        if (h.overallStatus.toUpperCase() != 'SAFE') {
          alerts.add(h);
        }
      }
    }

    final deadZoneAlerts = mqtt.deadZoneAlerts;
    final hasAny =
        alerts.isNotEmpty || deadZoneAlerts.isNotEmpty;

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding:
                const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alerts',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  hasAny
                      ? '${alerts.length + deadZoneAlerts.length} alerts recorded'
                      : 'No active alerts',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: !hasAny
                ? Center(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Container(
                          padding:
                              const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: c.safe
                                .withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.verified_rounded,
                            color: c.safe,
                            size: 44,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'All Clear',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'No danger readings recorded yet',
                          style: TextStyle(
                            color: c.textMuted,
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(
                        16, 0, 16, 24),
                    children: [
                      // ── Dead zone alerts ──
                      for (final msg in deadZoneAlerts)
                        Container(
                          margin: const EdgeInsets.only(
                              bottom: 8),
                          padding:
                              const EdgeInsets.all(13),
                          decoration: BoxDecoration(
                            color: c.surface,
                            borderRadius:
                                BorderRadius.circular(14),
                            border: Border.all(
                                color: c.deadZoneBorder),
                            boxShadow: c.cardShadow,
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding:
                                    const EdgeInsets.all(
                                        8),
                                decoration:
                                    BoxDecoration(
                                  color: c.deadZoneIcon
                                      .withOpacity(0.12),
                                  borderRadius:
                                      BorderRadius
                                          .circular(10),
                                ),
                                child: Icon(
                                  Icons
                                      .sensors_off_rounded,
                                  color: c.deadZoneIcon,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Text(
                                  msg,
                                  style: TextStyle(
                                    color:
                                        c.textSecondary,
                                    fontSize: 12.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // ── Sensor alerts ──
                      for (final a in alerts)
                        _alertCard(c, a),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _alertCard(AppColors c, SensorData a) {
    final color = c.statusColor(a.overallStatus);
    final isVibrating =
        a.vibration.toUpperCase() == 'VIBRATING';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.25),
        ),
        boxShadow: c.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              isVibrating
                  ? Icons.vibration_rounded
                  : Icons.warning_amber_rounded,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  isVibrating
                      ? 'Vibration in Node ${a.nodeNumber}'
                      : 'High risk in Node ${a.nodeNumber}',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'MQ2 ${a.mq2Value} · MQ135 ${a.mq135Value} · ${a.temp}°C · ${a.humidity}%',
                  style: TextStyle(
                    color: c.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              a.overallStatus,
              style: TextStyle(
                color: color,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
