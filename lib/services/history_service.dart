import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryRecord {
  final String id;
  final DateTime timestamp;
  final String deviceName;
  final String deviceId;
  final String action; // 'Rekomendasi' or 'Manual'
  final double dosis;
  final String details;

  HistoryRecord({
    required this.id,
    required this.timestamp,
    required this.deviceName,
    required this.deviceId,
    required this.action,
    required this.dosis,
    this.details = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'timestamp': timestamp.toIso8601String(),
        'deviceName': deviceName,
        'deviceId': deviceId,
        'action': action,
        'dosis': dosis,
        'details': details,
      };

  factory HistoryRecord.fromJson(Map<String, dynamic> json) => HistoryRecord(
        id: json['id'],
        timestamp: DateTime.parse(json['timestamp']),
        deviceName: json['deviceName'],
        deviceId: json['deviceId'],
        action: json['action'],
        dosis: (json['dosis'] ?? 0.0).toDouble(),
        details: json['details'] ?? '',
      );
}

class HistoryService extends ChangeNotifier {
  static const String _storageKey = 'ferticore_history';
  List<HistoryRecord> _records = [];

  List<HistoryRecord> get records => _records;

  HistoryService() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_storageKey);
    if (data != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(data);
        _records = jsonList.map((e) => HistoryRecord.fromJson(e)).toList();
        // Urutkan dari yang terbaru
        _records.sort((a, b) => b.timestamp.compareTo(a.timestamp));
        notifyListeners();
      } catch (e) {
        debugPrint('Error parsing history: $e');
      }
    }
  }

  Future<void> addRecord({
    required String deviceName,
    required String deviceId,
    required String action,
    required double dosis,
    String details = '',
  }) async {
    final newRecord = HistoryRecord(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      deviceName: deviceName.isEmpty ? 'Unknown Device' : deviceName,
      deviceId: deviceId,
      action: action,
      dosis: dosis,
      details: details,
    );

    _records.insert(0, newRecord); // Tambahkan ke urutan paling atas
    notifyListeners();
    await _saveHistory();
  }

  Future<void> clearHistory() async {
    _records.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(_records.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }
}
