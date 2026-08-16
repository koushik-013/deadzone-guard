import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mqtt_service.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import 'zone_detail_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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

  String _systemLabel(MqttService mqtt) {
    switch (mqtt.systemStatus) {
      case 'DEAD_ZONE':
        return 'Dead Zone';
      case 'BACKUP_ACTIVE':
        return 'Backup Active';
      default:
        return 'System Healthy';
    }
  }

  Color _systemColor(AppColors c, MqttService mqtt) {
    switch (mqtt.systemStatus) {
      case 'DEAD_ZONE':
        return c.critical;
      case 'BACKUP_ACTIVE':
        return c.danger;
      default:
        return c.safe;
    }
  }

  @override
  Widget build(BuildContext context) {
    final mqtt = context.watch<MqttService>();
    final c = AppColors.of(context);

    final isDeadZone = mqtt.systemStatus == 'DEAD_ZONE';
    final activeData = mqtt.activeNodeData;

    int alertCount = 0;
    final recentAlerts = <SensorData>[];

    // Only the currently active node is monitored — the backup node
    // stays on standby until the primary goes offline, so its old
    // readings must not raise alerts.
    if (activeData != null) {
      final activeNode = activeData.nodeNumber;

      if (mqtt.isNodeOnline(activeNode) &&
          _effectiveStatus(activeData, mqtt) != 'SAFE') {
        alertCount++;
      }

      for (final h in mqtt.getHistory(activeNode)) {
        if (h.overallStatus.toUpperCase() != 'SAFE' &&
            recentAlerts.length < 3) {
          recentAlerts.add(h);
        }
      }
    }

    final sysColor = _systemColor(c, mqtt);

    return SafeArea(
      child: RefreshIndicator(
        color: c.accent,
        backgroundColor: c.surface,
        onRefresh: () async {
          mqtt.refresh();
          await Future.delayed(
            const Duration(milliseconds: 800),
          );
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // ── Header ──
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, Admin',
                        style: TextStyle(
                          color: c.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        mqtt.isConnected
                            ? 'All systems operational'
                            : 'Connecting to MQTT...',
                        style: TextStyle(
                          color: c.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: sysColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: sysColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _systemLabel(mqtt),
                        style: TextStyle(
                          color: sysColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // ── SOS banner ──
            if (mqtt.isSosActive)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: c.sosBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: c.sosBorder, width: 1.5),
                  boxShadow: c.cardShadow,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color:
                            c.sosBorder.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sos_rounded,
                        color: c.sosText,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SOS ACTIVE',
                            style: TextStyle(
                              color: c.sosText,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'বাঁচাও বাঁচাও, আমরা বিপদে আছি!',
                            style: TextStyle(
                              color: c.sosTextSoft,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close_rounded,
                          color: c.sosText),
                      onPressed: () => mqtt.stopSos(),
                    ),
                  ],
                ),
              ),

            // ── Stat grid (2 x 2) ──
            Row(
              children: [
                _statCard(
                  c,
                  'Monitoring',
                  activeData != null
                      ? 'Node ${activeData.nodeNumber}'
                      : '—',
                  Icons.grid_view_rounded,
                  c.accent,
                ),
                const SizedBox(width: 10),
                _statCard(
                  c,
                  'Active Alerts',
                  '$alertCount',
                  Icons.notifications_active_rounded,
                  c.critical,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _statCard(
                  c,
                  'Sensor Node',
                  activeData != null
                      ? (mqtt.systemStatus ==
                              'BACKUP_ACTIVE'
                          ? 'Backup'
                          : 'Primary')
                      : 'Offline',
                  Icons.router_rounded,
                  activeData != null
                      ? (mqtt.systemStatus ==
                              'BACKUP_ACTIVE'
                          ? c.danger
                          : c.safe)
                      : c.textMuted,
                ),
                const SizedBox(width: 10),
                _statCard(
                  c,
                  'Connection',
                  mqtt.isConnected ? 'Live' : 'Off',
                  Icons.wifi_rounded,
                  mqtt.isConnected ? c.safe : c.critical,
                ),
              ],
            ),

            const SizedBox(height: 22),

            // ── Dead zone banner ──
            if (isDeadZone)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: c.deadZoneBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: c.deadZoneBorder, width: 1.5),
                  boxShadow: c.cardShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: c.deadZoneIcon
                            .withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.sensors_off_rounded,
                        color: c.deadZoneIcon,
                        size: 36,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'DEAD ZONE',
                      style: TextStyle(
                        color: c.deadZoneText,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 3,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'কোনো sensor সাড়া দিচ্ছে না',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.deadZoneIcon,
                        fontSize: 13,
                      ),
                    ),
                    if (mqtt
                        .deadZoneAlerts.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        mqtt.deadZoneAlerts.first,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.deadZoneText,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            // ── Backup banner ──
            if (mqtt.systemStatus == 'BACKUP_ACTIVE')
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: c.danger
                      .withOpacity(c.isDark ? 0.12 : 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: c.danger.withOpacity(0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.swap_horiz_rounded,
                      color: c.danger,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Node 1 offline — Node 3 (Backup) active',
                        style: TextStyle(
                          color: c.danger,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Active zone card ──
            if (activeData != null) ...[
              Text(
                'ACTIVE ZONE',
                style: TextStyle(
                  color: c.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              _activeNodeCard(context, mqtt, activeData),
            ],

            // ── Recent alerts ──
            if (recentAlerts.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'RECENT ALERTS',
                style: TextStyle(
                  color: c.textMuted,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 10),
              ...recentAlerts.map(
                (a) => _alertTile(c, a),
              ),
            ],

            if (!isDeadZone && activeData == null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: c.surface,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: c.border),
                        ),
                        child: Icon(
                          mqtt.isConnected
                              ? Icons.sensors_rounded
                              : Icons.wifi_off_rounded,
                          color: c.textMuted,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        mqtt.isConnected
                            ? 'Sensor data-র জন্য অপেক্ষা করছি...'
                            : 'MQTT-তে connect হচ্ছি...',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: c.textMuted,
                          fontSize: 13.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────
  //  WIDGETS
  // ────────────────────────────────
  Widget _statCard(
    AppColors c,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
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
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(icon, color: color, size: 17),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _activeNodeCard(
    BuildContext context,
    MqttService mqtt,
    SensorData data,
  ) {
    final c = AppColors.of(context);
    final status = _effectiveStatus(data, mqtt);
    final statusColor = c.statusColor(status);
    final mlResult = mqtt.getMLResult(data.nodeNumber);
    final confidence =
        mqtt.getMLConfidence(data.nodeNumber);
    final reason = mqtt.getMLReason(data.nodeNumber);
    final isBackup =
        mqtt.systemStatus == 'BACKUP_ACTIVE';
    final isVibrating =
        data.vibration.toUpperCase() == 'VIBRATING';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  ZoneDetailScreen(data: data),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: statusColor.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: c.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          statusColor.withOpacity(0.12),
                      borderRadius:
                          BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isVibrating
                          ? Icons.warning_rounded
                          : Icons.sensors_rounded,
                      color: statusColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Node ${data.nodeNumber}',
                          style: TextStyle(
                            color: c.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        if (isBackup) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets
                                .symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: c.danger
                                  .withOpacity(0.15),
                              borderRadius:
                                  BorderRadius.circular(
                                      6),
                            ),
                            child: Text(
                              'BACKUP',
                              style: TextStyle(
                                color: c.danger,
                                fontSize: 9,
                                fontWeight:
                                    FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          statusColor.withOpacity(0.14),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _valueChip(
                      c,
                      Icons
                          .local_fire_department_rounded,
                      'MQ2',
                      '${data.mq2Value}'),
                  const SizedBox(width: 8),
                  _valueChip(c, Icons.air_rounded,
                      'MQ135', '${data.mq135Value}'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _valueChip(
                      c,
                      Icons.thermostat_rounded,
                      'Temp',
                      '${data.temp}°C'),
                  const SizedBox(width: 8),
                  _valueChip(
                      c,
                      Icons.water_drop_rounded,
                      'Hum',
                      '${data.humidity}%'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.vibration_rounded,
                    size: 14,
                    color:
                        isVibrating ? c.critical : c.safe,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    data.vibration,
                    style: TextStyle(
                      color: isVibrating
                          ? c.critical
                          : c.safe,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: c.textMuted,
                    size: 20,
                  ),
                ],
              ),
              if (mlResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.accent.withOpacity(
                        c.isDark ? 0.08 : 0.06),
                    borderRadius:
                        BorderRadius.circular(12),
                    border: Border.all(
                      color: c.accent.withOpacity(0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.psychology_rounded,
                            size: 15,
                            color: c.accent,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'ML: $mlResult',
                              style: TextStyle(
                                color: c.accent,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w700,
                              ),
                            ),
                          ),
                          if (confidence != null)
                            Text(
                              '${(confidence * 100).toStringAsFixed(1)}%',
                              style: TextStyle(
                                color: c.accent,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                        ],
                      ),
                      if (reason != null &&
                          reason.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reason,
                          style: TextStyle(
                            color: c.textSecondary,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _valueChip(AppColors c, IconData icon,
      String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 9),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: c.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: c.textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertTile(AppColors c, SensorData a) {
    final color = c.statusColor(a.overallStatus);
    final isVibrating =
        a.vibration.toUpperCase() == 'VIBRATING';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
        boxShadow: c.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isVibrating
                  ? Icons.vibration_rounded
                  : Icons.warning_amber_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  '${a.overallStatus} in Node ${a.nodeNumber}',
                  style: TextStyle(
                    color: c.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'MQ2 ${a.mq2Value} · MQ135 ${a.mq135Value} · ${a.temp}°C',
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
                horizontal: 9, vertical: 4),
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
