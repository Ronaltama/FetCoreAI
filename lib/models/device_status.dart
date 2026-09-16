class DeviceStatus {
  final double gramasi;
  final bool isMotorRunning;
  final double totalVolume;
  final int totalSesi;
  final double rataRata;

  DeviceStatus({
    required this.gramasi,
    required this.isMotorRunning,
    required this.totalVolume,
    required this.totalSesi,
    required this.rataRata,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      gramasi: (json['dosis_ml'] ?? json['gramasi'] ?? 0.0).toDouble(),
      isMotorRunning: (json['isPompaOn'] ?? json['isMotorRunning'] ?? false),
      totalVolume: (json['totalVolume'] ?? 0.0).toDouble(),
      totalSesi: json['totalSesi'] ?? 0,
      rataRata: (json['rataRata'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dosis_ml': gramasi,
      'gramasi': gramasi,
      'isPompaOn': isMotorRunning,
      'isMotorRunning': isMotorRunning,
      'totalVolume': totalVolume,
      'totalSesi': totalSesi,
      'rataRata': rataRata,
    };
  }
}