class Device {
  final String id;
  int battery;
  bool isNight;
  bool uvOn;
  bool pumpOn;
  DateTime? lastSeen;

  Device({
    required this.id,
    this.battery = 0,
    this.isNight = false,
    this.uvOn = false,
    this.pumpOn = false,
    this.lastSeen,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'battery': battery,
    'isNight': isNight,
    'uvOn': uvOn,
    'pumpOn': pumpOn,
    'lastSeen': lastSeen?.toIso8601String(),
  };

  factory Device.fromJson(Map<String, dynamic> json) => Device(
    id: json['id'] as String,
    battery: json['battery'] as int? ?? 0,
    isNight: json['isNight'] as bool? ?? false,
    uvOn: json['uvOn'] as bool? ?? false,
    pumpOn: json['pumpOn'] as bool? ?? false,
    lastSeen: json['lastSeen'] != null
        ? DateTime.parse(json['lastSeen'] as String)
        : null,
  );
}
