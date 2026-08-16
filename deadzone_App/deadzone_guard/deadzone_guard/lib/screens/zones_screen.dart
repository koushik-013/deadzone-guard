import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../mqtt_service.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';
import 'zone_detail_screen.dart';

class ZonesScreen extends StatelessWidget {
  const ZonesScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    final mqtt = context.watch<MqttService>();
    final c = AppColors.of(context);

    final nodes = [
      (MqttService.primaryNode, 'Primary Node'),
      (MqttService.backupNode, 'Backup Node'),
    ];

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          Text(
            'Zone Status',
            style: TextStyle(
              color: c.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'All monitored zones and their live status',
            style: TextStyle(
              color: c.textSecondary,
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 18),
          for (final (node, role) in nodes)
            _zoneCard(context, mqtt, node, role),
        ],
      ),
    );
  }

  Widget _zoneCard(
    BuildContext context,
    MqttService mqtt,
    int node,
    String role,
  ) {
    final c = AppColors.of(context);
    final data = mqtt.nodeData[node];
    final online = mqtt.isNodeOnline(node);

    // The backup node only monitors when it has taken over from the
    // primary — otherwise it sits on standby and reports no status.
    final isActiveNode =
        mqtt.activeNodeData?.nodeNumber == node;

    final String status;
    if (isActiveNode && data != null && online) {
      status = _effectiveStatus(data, mqtt);
    } else if (node == MqttService.backupNode) {
      status = 'STANDBY';
    } else {
      status = 'OFFLINE';
    }

    final isIdle =
        status == 'OFFLINE' || status == 'STANDBY';

    final statusColor =
        isIdle ? c.textMuted : c.statusColor(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: (data != null && isActiveNode)
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        ZoneDetailScreen(data: data),
                  ),
                );
              }
            : null,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isIdle
                  ? c.border
                  : statusColor.withOpacity(0.3),
            ),
            boxShadow: c.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  status == 'STANDBY'
                      ? Icons.pause_circle_outline_rounded
                      : (isActiveNode && online
                          ? Icons.sensors_rounded
                          : Icons.sensors_off_rounded),
                  color: statusColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Node $node',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      status == 'STANDBY'
                          ? '$role · waiting for failover'
                          : (isActiveNode &&
                                  data != null &&
                                  online
                              ? '$role · MQ2 ${data.mq2Value} · ${data.temp}°C'
                              : role),
                      style: TextStyle(
                        color: c.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              if (data != null && isActiveNode) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: c.textMuted,
                  size: 20,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
