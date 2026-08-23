import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device.dart';
import '../models/log_entry.dart';
import '../services/mqtt_service.dart';

class DeviceProvider extends ChangeNotifier {
  final MqttService mqttService;
  final Map<String, Device> _devices = {};
  List<LogEntry> _logs = [];

  DeviceProvider(this.mqttService) {
    mqttService.onTelemetry = _handleTelemetry;
    _loadLogsFromStorage();
    _loadDevicesFromStorage();
    _initMqtt();
  }

  void _initMqtt() async {
    await mqttService.connect();
    notifyListeners();
  }

  Future<void> refresh() async {
    try {
      debugPrint('Refreshing MQTT connection...');
      await mqttService.connect();
      notifyListeners();
    } catch (e) {
      debugPrint('Refresh error: $e');
    }
  }

  // === HANDLE INCOMING TELEMETRY / EVENT ===
  void _handleTelemetry(
    String deviceId,
    String event,
    Map<String, dynamic>? data,
  ) {
    final now = DateTime.now();

    Device device;
    if (_devices.containsKey(deviceId)) {
      device = _devices[deviceId]!;
    } else {
      device = Device(id: deviceId);
      _devices[deviceId] = device;
    }
    device.lastSeen = now;

    if (event == 'telemetry' && data != null) {
      device.battery = data['bat'] ?? device.battery;
      device.isNight = data['is_night'] ?? device.isNight;
      device.uvOn = (data['uv'] == 1);
      device.pumpOn = (data['pump'] == 1);
    } else if (event == 'uv_on') {
      device.uvOn = true;
    } else if (event == 'uv_off') {
      device.uvOn = false;
    } else if (event == 'pump_on') {
      device.pumpOn = true;
    } else if (event == 'pump_off') {
      device.pumpOn = false;
    }

    final log = LogEntry(
      deviceId: deviceId,
      timestamp: now,
      event: event,
      data: data,
    );
    _logs.insert(0, log);

    _saveLogsToStorage();
    _saveDevicesToStorage();
    notifyListeners();
  }

  void sendCommand(String deviceId, Map<String, dynamic> command) {
    mqttService.publishCommand(deviceId, command);
  }

  Future<void> clearLogs({String? deviceId}) async {
    if (deviceId == null) {
      _logs.clear();
    } else {
      _logs.removeWhere((log) => log.deviceId == deviceId);
    }
    await _saveLogsToStorage();
    notifyListeners();
  }

  Future<void> deleteDevice(String deviceId) async {
    if (_devices.containsKey(deviceId)) {
      _devices.remove(deviceId);
      _logs.removeWhere((log) => log.deviceId == deviceId);

      await _saveDevicesToStorage();
      await _saveLogsToStorage();
      notifyListeners();
    }
  }

  List<Device> get devices => _devices.values.toList();

  Device? getDevice(String id) => _devices[id];

  List<LogEntry> get allLogs => _logs;

  List<LogEntry> logsForDevice(String id) =>
      _logs.where((log) => log.deviceId == id).toList();

  int get onlineCount => _devices.values.where((d) {
    if (d.lastSeen == null) return false;
    return DateTime.now().difference(d.lastSeen!).inMinutes < 5;
  }).length;

  bool get isMqttConnected => mqttService.isConnected;

  static const _logKey = 'device_logs';
  static const _deviceKey = 'saved_devices';

  Future<void> _saveDevicesToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _devices.values.map((e) => e.toJson()).toList();
    prefs.setString(_deviceKey, jsonEncode(jsonList));
  }

  Future<void> _loadDevicesFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_deviceKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      for (var item in jsonList) {
        final device = Device.fromJson(item);
        _devices[device.id] = device;
      }
      notifyListeners();
    }
  }

  Future<void> _saveLogsToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final logsToSave = _logs.take(1000).toList();
    final jsonList = logsToSave.map((e) => e.toJson()).toList();
    prefs.setString(_logKey, jsonEncode(jsonList));
  }

  Future<void> _loadLogsFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_logKey);
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      _logs = jsonList.map((e) => LogEntry.fromJson(e)).toList();
      notifyListeners();
    }
  }
}
