import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../mqtt_service.dart';
import '../models/sensor_data.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  final int nodeNumber;

  const HistoryScreen({
    super.key,
    required this.nodeNumber,
  });

  @override
  Widget build(BuildContext context) {
    final mqtt = context.watch<MqttService>();
    final c = AppColors.of(context);
    final history = mqtt.getHistory(nodeNumber);

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        title: Text('Node $nodeNumber History'),
        actions: [
          if (history.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Clear History',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    backgroundColor: c.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    title: Text(
                      'Clear history?',
                      style: TextStyle(
                        color: c.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    content: Text(
                      'All stored readings for Node $nodeNumber will be removed.',
                      style: TextStyle(
                        color: c.textSecondary,
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () =>
                            Navigator.pop(ctx),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: c.textSecondary,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          mqtt.clearHistory(nodeNumber);
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          'Clear',
                          style: TextStyle(
                            color: c.critical,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          const ThemeToggleButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: c.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: c.border),
                    ),
                    child: Icon(
                      Icons.history_toggle_off_rounded,
                      color: c.textMuted,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No history yet',
                    style: TextStyle(
                      color: c.textSecondary,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Readings will appear here as they arrive',
                    style: TextStyle(
                      color: c.textMuted,
                      fontSize: 12.5,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: history.length,
              itemBuilder: (context, index) {
                final data = history[index];
                return _historyCard(c, data, index);
              },
            ),
    );
  }

  Widget _historyCard(
      AppColors c, SensorData data, int index) {
    final statusColor = c.statusColor(data.overallStatus);
    final isLatest = index == 0;
    final isVibrating =
        data.vibration.toUpperCase() == 'VIBRATING';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isLatest
              ? c.accent.withOpacity(0.4)
              : c.border,
          width: isLatest ? 1.3 : 1,
        ),
        boxShadow: c.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isLatest)
                Container(
                  margin:
                      const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.accent.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LATEST',
                    style: TextStyle(
                      color: c.accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 9.5,
                      letterSpacing: 0.5,
                    ),
                  ),
                )
              else
                Text(
                  'Reading ${index + 1}',
                  style: TextStyle(
                    color: c.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data.overallStatus,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _miniValue(c,
                  Icons.local_fire_department_rounded,
                  'MQ2', '${data.mq2Value}'),
              const SizedBox(width: 8),
              _miniValue(c, Icons.air_rounded, 'MQ135',
                  '${data.mq135Value}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _miniValue(c, Icons.thermostat_rounded,
                  'Temp', '${data.temp}°C'),
              const SizedBox(width: 8),
              _miniValue(c, Icons.water_drop_rounded,
                  'Hum', '${data.humidity}%'),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.vibration_rounded,
                size: 14,
                color: isVibrating ? c.critical : c.safe,
              ),
              const SizedBox(width: 5),
              Text(
                data.vibration,
                style: TextStyle(
                  color:
                      isVibrating ? c.critical : c.safe,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniValue(
      AppColors c, IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: c.surfaceAlt,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: c.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: c.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                color: c.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
