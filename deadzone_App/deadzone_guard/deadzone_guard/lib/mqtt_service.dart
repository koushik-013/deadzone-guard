import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'models/sensor_data.dart';

class MqttService extends ChangeNotifier {
  static const String _broker = '10.64.249.52';
  static const String _topic = 'deadzone/sensors';
  static const String _alertTopic = 'deadzone/alerts';
  static const String _mlTopic = 'deadzone/ml_result';
  static const String _sosTopic = 'deadzone/sos';

  static const int primaryNode = 1;
  static const int backupNode = 3;

  static const Duration dangerDelay = Duration(seconds: 5);
  static const Duration nodeTimeout = Duration(seconds: 30);
  static const int maxHistoryPerNode = 100;

  late MqttServerClient _client;
  final FlutterTts _tts = FlutterTts();

  final Map<int, SensorData> nodeData = {};
  final Map<int, List> historyData = {};
  final Map<int, String> mlResults = {};
  final Map<int, double> mlConfidences = {};
  final Map<int, String> mlReasons = {};
  final Map<int, DateTime> _lastSeen = {};
  final Map<int, DateTime> _dangerStartedAt = {};
  final Map<int, bool> _dangerAlertSpoken = {};
  final Map<int, String> _dangerReason = {};

  final List deadZoneAlerts = [];

  bool isSosActive = false;
  bool isConnected = false;
  bool _connecting = false;
  bool _ttsReady = false;
  bool _deadZoneAlertSpoken = false;

  Timer? _statusTimer;
  StreamSubscription<List<MqttReceivedMessage>>? _messageSubscription;

  MqttService() {
    _initTts();
    _startStatusTimer();
    _connect();
  }

  Future _initTts() async {
    try {
      await _tts.setLanguage('bn-BD');
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _ttsReady = true;
    } catch (_) {
      try {
        await _tts.setLanguage('bn-IN');
        await _tts.setSpeechRate(0.45);
        await _tts.setVolume(1.0);
        await _tts.setPitch(1.0);
        _ttsReady = true;
      } catch (e) {
        debugPrint('TTS unavailable: $e');
      }
    }
  }

  Future _speak(String text) async {
    if (!_ttsReady) await _initTts();
    if (!_ttsReady || !isConnected) return;

    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (e) {
      debugPrint('TTS error: $e');
    }
  }

  void _startStatusTimer() {
    _statusTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!isConnected) {
          _deadZoneAlertSpoken = false;
          notifyListeners();
          return;
        }

        if (systemStatus == 'DEAD_ZONE') {
          _handleDeadZoneAlert();
        } else {
          _deadZoneAlertSpoken = false;
        }

        notifyListeners();
      },
    );
  }

  bool isNodeOnline(int node) {
    if (!isConnected) return false;

    final lastSeen = _lastSeen[node];
    if (lastSeen == null) return false;

    return DateTime.now().difference(lastSeen) < nodeTimeout;
  }

  SensorData? get activeNodeData {
    if (isNodeOnline(primaryNode)) return nodeData[primaryNode];
    if (isNodeOnline(backupNode)) return nodeData[backupNode];
    return null;
  }

  String get systemStatus {
    if (!isConnected) return 'OFFLINE';

    final node1Online = isNodeOnline(primaryNode);
    final node3Online = isNodeOnline(backupNode);

    if (!node1Online && !node3Online) return 'DEAD_ZONE';
    if (!node1Online && node3Online) return 'BACKUP_ACTIVE';

    return 'NORMAL';
  }

  int get onlineNodeCount {
    int count = 0;
    if (isNodeOnline(primaryNode)) count++;
    if (isNodeOnline(backupNode)) count++;
    return count;
  }

  void _checkDangerVoice(
    int node,
    String prediction,
    String reason,
  ) {
    if (!isConnected) return;

    final normalizedPrediction = prediction.toUpperCase().trim();
    final normalizedReason = reason.toUpperCase().trim();

    final isDanger =
        normalizedPrediction == 'DANGER' ||
        normalizedPrediction == 'CRITICAL' ||
        normalizedPrediction == 'UNHEALTHY' ||
        normalizedPrediction == 'UNHEALTHY FOR SENSITIVE GROUPS' ||
        normalizedPrediction == 'UNHEALTHY FOR SENSITIVE GROUP';

    if (!isDanger) {
      _dangerStartedAt.remove(node);
      _dangerAlertSpoken[node] = false;
      _dangerReason.remove(node);
      return;
    }

    String currentReason;

    if (normalizedReason.contains('VIBRATION')) {
      currentReason = 'VIBRATION';
    } else if (normalizedReason.contains('GAS') ||
        normalizedReason.contains('MQ2') ||
        normalizedReason.contains('MQ135')) {
      currentReason = 'GAS';
    } else {
      currentReason = 'GAS';
    }

    final previousReason = _dangerReason[node];

    if (previousReason != currentReason) {
      _dangerStartedAt[node] = DateTime.now();
      _dangerAlertSpoken[node] = false;
      _dangerReason[node] = currentReason;
      return;
    }

    _dangerReason[node] = currentReason;
    _dangerStartedAt.putIfAbsent(node, () => DateTime.now());

    final startedAt = _dangerStartedAt[node];
    if (startedAt == null) return;

    final elapsed = DateTime.now().difference(startedAt);

    if (elapsed >= dangerDelay &&
        !(_dangerAlertSpoken[node] ?? false)) {
      _dangerAlertSpoken[node] = true;

      if (currentReason == 'VIBRATION') {
        _speak(
          'ভূমিকম্প! ভূমিকম্প!',
        );
      } else {
        _speak(
          'পালাও! পালাও! বিপজ্জনক গ্যাস শনাক্ত হয়েছে',
        );
      }
    }
  }

  void _handleDeadZoneAlert() {
    if (!isConnected) {
      _deadZoneAlertSpoken = false;
      return;
    }

    if (_deadZoneAlertSpoken) return;

    _deadZoneAlertSpoken = true;

    _speak(
      'সতর্কতা! আমরা ডেড জোনে আছি। কোনো সেন্সর সাড়া দিচ্ছে না।',
    );
  }

  Future triggerSos() async {
    isSosActive = true;
    notifyListeners();

    await _speak('বাঁচাও বাঁচাও, আমরা বিপদে আছি');

    _publishMessage(
      _sosTopic,
      'SOS|STATUS:ACTIVE|MSG:Emergency help needed immediately',
    );

    _publishMessage(
      _alertTopic,
      'SOS|STATUS:ACTIVE|MSG:Worker triggered SOS emergency',
    );

    await _saveSosToFirebase();
  }

  Future _saveSosToFirebase() async {
    try {
      final activeData =
          activeNodeData ?? nodeData[primaryNode] ?? nodeData[backupNode];

      await FirebaseFirestore.instance.collection('sos_logs').add({
        'timestamp': FieldValue.serverTimestamp(),
        'status': 'ACTIVE',
        'node': activeData?.nodeNumber ?? 0,
        'temperature': activeData?.temp ?? 0,
        'humidity': activeData?.humidity ?? 0,
        'mq2': activeData?.mq2Value ?? 0,
        'mq135': activeData?.mq135Value ?? 0,
        'vibration': activeData?.vibration ?? 'UNKNOWN',
        'message': 'SOS triggered by user',
      });
    } catch (e) {
      debugPrint('SOS Firebase error: $e');
    }
  }

  void stopSos() {
    isSosActive = false;
    _tts.stop();

    notifyListeners();

    _publishMessage(
      _sosTopic,
      'SOS|STATUS:CANCELLED|MSG:SOS cancelled by user',
    );
  }

  void refresh() {
    nodeData.clear();
    historyData.clear();
    _lastSeen.clear();
    deadZoneAlerts.clear();
    mlResults.clear();
    mlConfidences.clear();
    mlReasons.clear();
    isSosActive = false;
    _dangerStartedAt.clear();
    _dangerAlertSpoken.clear();
    _dangerReason.clear();
    _deadZoneAlertSpoken = false;

    notifyListeners();
  }

  Future _connect() async {
    if (_connecting) return;

    _connecting = true;

    final clientId =
        'DeadZoneApp_${DateTime.now().millisecondsSinceEpoch}';

    _client = MqttServerClient(_broker, clientId);
    _client.port = 1883;
    _client.keepAlivePeriod = 20;
    _client.autoReconnect = true;
    _client.resubscribeOnAutoReconnect = true;
    _client.onConnected = _onConnected;
    _client.onDisconnected = _onDisconnected;
    _client.logging(on: false);

    _client.connectionMessage = MqttConnectMessage()
        .withClientIdentifier(clientId)
        .startClean();

    try {
      await _client.connect();
    } catch (e) {
      debugPrint('MQTT Error: $e');

      try {
        _client.disconnect();
      } catch (_) {}

      _connecting = false;
      isConnected = false;
      _lastSeen.clear();
      _deadZoneAlertSpoken = false;

      notifyListeners();

      Future.delayed(
        const Duration(seconds: 5),
        _connect,
      );

      return;
    }

    _connecting = false;

    if (_client.connectionStatus?.state ==
        MqttConnectionState.connected) {
      isConnected = true;
      _subscribeTopics();
      _listenMessages();
      notifyListeners();
    }
  }

  void _subscribeTopics() {
    _client.subscribe(_topic, MqttQos.atLeastOnce);
    _client.subscribe(_alertTopic, MqttQos.atLeastOnce);
    _client.subscribe(_mlTopic, MqttQos.atLeastOnce);
    _client.subscribe(_sosTopic, MqttQos.atLeastOnce);
  }

  void _publishMessage(String topic, String message) {
    try {
      if (_client.connectionStatus?.state !=
          MqttConnectionState.connected) {
        return;
      }

      final builder = MqttClientPayloadBuilder();
      builder.addString(message);

      _client.publishMessage(
        topic,
        MqttQos.atLeastOnce,
        builder.payload!,
      );
    } catch (e) {
      debugPrint('Publish error: $e');
    }
  }

  void _listenMessages() {
    _messageSubscription?.cancel();

    _messageSubscription = _client.updates?.listen((messages) {
      for (final msg in messages) {
        final recMess = msg.payload as MqttPublishMessage;

        final payload =
            MqttPublishPayload.bytesToStringAsString(
          recMess.payload.message,
        );

        if (msg.topic == _mlTopic) {
          _handleMLResult(payload);
        } else if (msg.topic == _alertTopic) {
          _handleAlert(payload);
        } else if (msg.topic == _sosTopic) {
          _handleSosMessage(payload);
        } else if (msg.topic == _topic) {
          _handleSensorData(payload);
        }
      }
    });
  }

  void _handleSensorData(String payload) {
    try {
      final data = SensorData.fromMqttString(payload);

      if (data.nodeNumber == 0 || !isConnected) return;

      nodeData[data.nodeNumber] = data;
      _lastSeen[data.nodeNumber] = DateTime.now();
      _deadZoneAlertSpoken = false;

      historyData.putIfAbsent(
        data.nodeNumber,
        () => <SensorData>[],
      );

      historyData[data.nodeNumber]!.insert(0, data);

      if (historyData[data.nodeNumber]!.length >
          maxHistoryPerNode) {
        historyData[data.nodeNumber]!.removeLast();
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Sensor parse error: $e');
    }
  }

  void _handleMLResult(String payload) {
    try {
      if (!isConnected) return;

      final decoded = jsonDecode(payload);

      final int node =
          int.tryParse(decoded['node']?.toString() ?? '') ?? 0;

      if (node == 0) return;

      final prediction =
          decoded['prediction']?.toString() ?? 'UNKNOWN';

      final reason =
          decoded['reason']?.toString() ?? '';

      final confidenceRaw = decoded['confidence'];

      double confidence = 0;

      if (confidenceRaw is num) {
        confidence = confidenceRaw.toDouble();
      } else {
        confidence =
            double.tryParse(
              confidenceRaw?.toString() ?? '0',
            ) ??
            0;
      }

      if (confidence > 1) {
        confidence /= 100;
      }

      mlResults[node] = prediction;
      mlConfidences[node] = confidence;
      mlReasons[node] = reason;

      _checkDangerVoice(
        node,
        prediction,
        reason,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('ML parse error: $e');
    }
  }

  void _handleAlert(String payload) {
    if (!isConnected) return;

    if (payload.contains('SOS|STATUS:ACTIVE')) {
      isSosActive = true;
    }

    if (payload.contains('DEADZONE') &&
        payload.contains('STATUS:DEAD')) {
      _handleDeadZoneAlert();
    }

    deadZoneAlerts.insert(0, payload);

    if (deadZoneAlerts.length > 10) {
      deadZoneAlerts.removeLast();
    }

    notifyListeners();
  }

  void _handleSosMessage(String payload) {
    if (!isConnected) return;

    if (payload.contains('STATUS:ACTIVE')) {
      isSosActive = true;

      _speak(
        'বাঁচাও বাঁচাও, আমরা বিপদে আছি',
      );
    } else if (payload.contains('STATUS:CANCELLED')) {
      isSosActive = false;
    }

    notifyListeners();
  }

  List getHistory(int nodeNumber) =>
      historyData[nodeNumber] ?? [];

  String? getMLResult(int nodeNumber) =>
      mlResults[nodeNumber];

  double? getMLConfidence(int nodeNumber) =>
      mlConfidences[nodeNumber];

  String? getMLReason(int nodeNumber) =>
      mlReasons[nodeNumber];

  void clearHistory(int nodeNumber) {
    historyData[nodeNumber]?.clear();
    notifyListeners();
  }

  void _onConnected() {
    isConnected = true;
    _connecting = false;
    _subscribeTopics();
    notifyListeners();
  }

  void _onDisconnected() {
    isConnected = false;
    _lastSeen.clear();
    _deadZoneAlertSpoken = false;
    _dangerStartedAt.clear();
    _dangerAlertSpoken.clear();
    _dangerReason.clear();

    notifyListeners();

    if (!_connecting) {
      Future.delayed(
        const Duration(seconds: 5),
        _connect,
      );
    }
  }

  void disconnect() {
    _messageSubscription?.cancel();
    _statusTimer?.cancel();

    try {
      _client.disconnect();
    } catch (_) {}

    _tts.stop();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _statusTimer?.cancel();

    try {
      _client.disconnect();
    } catch (_) {}

    _tts.stop();

    super.dispose();
  }
}