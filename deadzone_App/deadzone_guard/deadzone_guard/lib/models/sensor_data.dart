class SensorData {
  final int nodeNumber;
  final int mq2Value;
  final String mq2Status;
  final int mq135Value;
  final String mq135Status;
  final String overallStatus;
  final double temp;
  final double humidity;
  final String vibration;
  final DateTime timestamp;

  SensorData({
    required this.nodeNumber,
    required this.mq2Value,
    required this.mq2Status,
    required this.mq135Value,
    required this.mq135Status,
    required this.overallStatus,
    required this.temp,
    required this.humidity,
    required this.vibration,
    required this.timestamp,
  });

  factory SensorData.fromMqttString(String raw) {
    final Map<String, String> parts = {};

    for (final item in raw.split('|')) {
      final index = item.indexOf(':');

      if (index > 0) {
        final key = item.substring(0, index).trim();
        final value = item.substring(index + 1).trim();
        parts[key] = value;
      }
    }

    final vibration =
        (parts['VIB'] ?? 'STABLE').toUpperCase();

    final originalStatus =
        (parts['STATUS'] ?? 'SAFE').toUpperCase();

    String finalStatus = originalStatus;

    if (vibration == 'VIBRATING') {
      finalStatus = 'DANGER';
    }

    return SensorData(
      nodeNumber:
          int.tryParse(parts['NODE'] ?? '0') ?? 0,
      mq2Value:
          int.tryParse(parts['MQ2'] ?? '0') ?? 0,
      mq2Status:
          (parts['MQ2S'] ?? 'SAFE').toUpperCase(),
      mq135Value:
          int.tryParse(parts['MQ135'] ?? '0') ?? 0,
      mq135Status:
          (parts['MQ135S'] ?? 'SAFE').toUpperCase(),
      overallStatus: finalStatus,
      temp:
          double.tryParse(parts['TEMP'] ?? '0') ?? 0,
      humidity:
          double.tryParse(parts['HUM'] ?? '0') ?? 0,
      vibration: vibration,
      timestamp: DateTime.now(),
    );
  }
}
