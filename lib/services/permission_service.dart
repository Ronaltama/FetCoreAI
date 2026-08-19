import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Request permissions needed for Bluetooth & Wi-Fi scanning
  static Future<bool> requestAllPermissions() async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      // Desktop platforms (Linux/Windows/macOS) don't use Android runtime permissions
      return true;
    }

    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();

    bool allGranted = true;
    statuses.forEach((permission, status) {
      if (!status.isGranted && !status.isLimited) {
        allGranted = false;
      }
    });

    return allGranted;
  }
}
