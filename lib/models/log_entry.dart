class LogEntry {
  final String deviceId;
  final DateTime timestamp;
  final String event; // "telemetry", "uv_on", "pump_on", dll.
  final Map<String, dynamic>? data;

  LogEntry({
    required this.deviceId,
    required this.timestamp,
    required this.event,
    this.data,
  });

  // Untuk serialisasi ke SharedPreferences (simpan log)
  Map<String, dynamic> toJson() => {
    'deviceId': deviceId,
    'timestamp': timestamp.toIso8601String(),
    'event': event,
    'data': data,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    deviceId: json['deviceId'],
    timestamp: DateTime.parse(json['timestamp']),
    event: json['event'],
    data: json['data'] != null ? Map<String, dynamic>.from(json['data']) : null,
  );
}
