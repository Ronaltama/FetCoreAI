import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MqttService {
  late MqttServerClient client;

  MqttService() {
    client = MqttServerClient(broker, 'flutter_placeholder');
  }

  static const String broker = 'broker.hivemq.com';
  static const int port = 1883;
  static const String telemetryTopic = 'tanisolution/+/telemetry';

  void Function(String deviceId, String event, Map<String, dynamic>? data)?
  onTelemetry;

  List<Map<String, dynamic>> _commandQueue = [];
  final String _storageKey = 'mqtt_cmd_queue';

  bool get isConnected {
    try {
      return client.connectionStatus?.state == MqttConnectionState.connected;
    } catch (_) {
      return false;
    }
  }

  Future<void> _loadQueueFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? jsonString = prefs.getString(_storageKey);

      if (jsonString != null && jsonString.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(jsonString);
        _commandQueue = List<Map<String, dynamic>>.from(
          decoded.map((x) => Map<String, dynamic>.from(x)),
        );
        debugPrint(
          'Antrean dimuat dari storage: ${_commandQueue.length} pesan',
        );
      }
    } catch (e) {
      debugPrint('Gagal memuat antrean dari storage: $e');
    }
  }

  Future<void> _saveQueueToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String jsonString = jsonEncode(_commandQueue);
      await prefs.setString(_storageKey, jsonString);
    } catch (e) {
      debugPrint('Gagal menyimpan antrean ke storage: $e');
    }
  }

  Future<void> connect() async {
    try {
      if (isConnected) {
        debugPrint('MQTT already connected');
        return;
      }
    } catch (_) {}

    await _loadQueueFromStorage();

    client = MqttServerClient(
      broker,
      'flutter_app_${DateTime.now().millisecondsSinceEpoch}',
    );

    client.port = port;
    client.keepAlivePeriod = 20;
    client.autoReconnect = true;
    client.resubscribeOnAutoReconnect = true;

    client.onConnected = _onConnected;
    client.onDisconnected = _onDisconnected;

    final connMsg = MqttConnectMessage()
        .withClientIdentifier(client.clientIdentifier)
        .startClean();

    client.connectionMessage = connMsg;

    try {
      debugPrint('Connecting to MQTT broker...');
      await client.connect().timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('MQTT connection error: $e');
      disconnect();
      return;
    }

    if (client.connectionStatus?.state == MqttConnectionState.connected) {
      debugPrint('MQTT connected successfully');
      client.subscribe(telemetryTopic, MqttQos.atLeastOnce);
      client.updates?.listen(_onMessage);
    } else {
      debugPrint('MQTT failed: ${client.connectionStatus}');
    }
  }

  void _onConnected() {
    debugPrint('MQTT connected');
    _processQueue();
  }

  void _onDisconnected() {
    debugPrint('MQTT disconnected');
  }

  void _onMessage(List<MqttReceivedMessage<MqttMessage>> messages) {
    for (final msg in messages) {
      if (msg.payload is MqttPublishMessage) {
        final topic = msg.topic;
        final publishMessage = msg.payload as MqttPublishMessage;
        final payload = MqttPublishPayload.bytesToStringAsString(
          publishMessage.payload.message,
        );

        final parts = topic.split('/');

        if (parts.length == 3 &&
            parts[0] == 'tanisolution' &&
            parts[2] == 'telemetry') {
          final deviceId = parts[1];

          try {
            final json = jsonDecode(payload);

            if (json.containsKey('bat') &&
                json.containsKey('is_night') &&
                json.containsKey('uv')) {
              final Map<String, dynamic> data = Map<String, dynamic>.from(json);
              onTelemetry?.call(deviceId, 'telemetry', data);
            } else if (json.containsKey('event')) {
              final String event = json['event'];
              final data = (json['data'] is Map)
                  ? Map<String, dynamic>.from(json['data'])
                  : null;

              onTelemetry?.call(deviceId, event, data);
            }
          } catch (e) {
            debugPrint('JSON parse error: $e');
          }
        }
      }
    }
  }

  void publishCommand(String deviceId, Map<String, dynamic> command) {
    if (!isConnected) {
      debugPrint('Offline: Menyimpan perintah ke memori permanen');
      _commandQueue.add({'deviceId': deviceId, 'command': command});
      _saveQueueToStorage();
      return;
    }

    _sendToBroker(deviceId, command);
  }

  void _sendToBroker(String deviceId, Map<String, dynamic> command) {
    final topic = 'tanisolution/$deviceId/command';
    final payload = jsonEncode(command);

    debugPrint('Publish topic: $topic');
    debugPrint('Payload: $payload');

    final builder = MqttClientPayloadBuilder();
    builder.addString(payload);

    try {
      client.publishMessage(topic, MqttQos.atLeastOnce, builder.payload!);
      debugPrint('Publish success');
    } catch (e) {
      debugPrint('Publish error: $e');
    }
  }

  Future<void> _processQueue() async {
    if (_commandQueue.isEmpty) return;

    debugPrint('Memproses ${_commandQueue.length} pesan tertunda...');

    final List<Map<String, dynamic>> tempQueue = List.from(_commandQueue);

    for (var item in tempQueue) {
      _sendToBroker(item['deviceId'], item['command']);
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _commandQueue.clear();
    await _saveQueueToStorage();
    debugPrint('Antrean berhasil dikirim dan dibersihkan.');
  }

  void disconnect() {
    try {
      client.disconnect();
    } catch (e) {
      debugPrint('Disconnect error: $e');
    }
  }
}
