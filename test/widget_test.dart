import 'package:flutter_test/flutter_test.dart';
import 'package:ferticore_ai/models/device_status.dart';

void main() {
  group('DeviceStatus Model Tests', () {
    test('DeviceStatus fromJson parses firmware payload correctly', () {
      final json = {
        'dosis_ml': 15.0,
        'isPompaOn': true,
        'totalVolume': 45.5,
        'totalSesi': 3,
        'rataRata': 15.17,
        'cal_ms': 3200,
      };

      final status = DeviceStatus.fromJson(json);

      expect(status.gramasi, 15.0);
      expect(status.isMotorRunning, true);
      expect(status.totalVolume, 45.5);
      expect(status.totalSesi, 3);
      expect(status.rataRata, 15.17);
      expect(status.calMs, 3200);
    });

    test('DeviceStatus toJson includes cal_ms and backward compatible fields', () {
      final status = DeviceStatus(
        gramasi: 20.0,
        isMotorRunning: false,
        totalVolume: 100.0,
        totalSesi: 5,
        rataRata: 20.0,
        calMs: 2500,
      );

      final json = status.toJson();

      expect(json['dosis_ml'], 20.0);
      expect(json['isPompaOn'], false);
      expect(json['totalVolume'], 100.0);
      expect(json['totalSesi'], 5);
      expect(json['cal_ms'], 2500);
    });
  });
}
