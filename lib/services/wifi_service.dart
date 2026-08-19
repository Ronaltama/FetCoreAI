import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';

class WifiInfo {
  final String? ssid;
  final String? ipAddress;
  final String? bssid;

  WifiInfo({this.ssid, this.ipAddress, this.bssid});
}

class WifiService {
  final NetworkInfo _networkInfo = NetworkInfo();
  final Connectivity _connectivity = Connectivity();

  /// Stream of network connectivity changes
  Stream<List<ConnectivityResult>> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged;

  /// Get current Wi-Fi connection info (SSID, IP, BSSID)
  Future<WifiInfo> getCurrentWifiInfo() async {
    try {
      String? ssid = await _networkInfo.getWifiName();
      String? ip = await _networkInfo.getWifiIP();
      String? bssid = await _networkInfo.getWifiBSSID();

      // Strip quotes if name is surrounded by quotes
      if (ssid != null && ssid.startsWith('"') && ssid.endsWith('"')) {
        ssid = ssid.substring(1, ssid.length - 1);
      }

      return WifiInfo(ssid: ssid, ipAddress: ip, bssid: bssid);
    } catch (e) {
      return WifiInfo();
    }
  }

  /// Check if Wi-Fi scan is supported on current platform
  Future<bool> canScanWifi() async {
    try {
      final can = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
      return can == CanGetScannedResults.yes;
    } catch (_) {
      return false;
    }
  }

  /// Start scanning for nearby Wi-Fi access points
  Future<bool> startScan() async {
    try {
      final canStart = await WiFiScan.instance.canStartScan(askPermissions: true);
      if (canStart == CanStartScan.yes) {
        return await WiFiScan.instance.startScan();
      }
    } catch (_) {}
    return false;
  }

  /// Get list of scanned Wi-Fi access points
  Future<List<WiFiAccessPoint>> getScannedAccessPoints() async {
    try {
      final canGet = await WiFiScan.instance.canGetScannedResults(askPermissions: true);
      if (canGet == CanGetScannedResults.yes) {
        return await WiFiScan.instance.getScannedResults();
      }
    } catch (_) {}
    return [];
  }
}
