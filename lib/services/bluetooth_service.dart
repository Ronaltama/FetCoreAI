import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothServiceHelper {
  /// Stream of Bluetooth adapter status (on, off, unavailable, etc.)
  Stream<BluetoothAdapterState> get adapterState => FlutterBluePlus.adapterState;

  /// Stream of scanned BLE results
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  /// Is Bluetooth actively scanning
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  /// Start BLE scanning
  Future<void> startScan({Duration timeout = const Duration(seconds: 15)}) async {
    // Check if adapter is supported
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception("Bluetooth Low Energy is not supported on this device.");
    }
    await FlutterBluePlus.startScan(timeout: timeout);
  }

  /// Stop scanning
  Future<void> stopScan() async {
    await FlutterBluePlus.stopScan();
  }

  /// Connect to a Bluetooth device
  Future<void> connectDevice(BluetoothDevice device) async {
    await device.connect(license: License.nonprofit);
  }

  /// Disconnect from a Bluetooth device
  Future<void> disconnectDevice(BluetoothDevice device) async {
    await device.disconnect();
  }

  /// Discover services of a connected device
  Future<List<BluetoothService>> discoverServices(BluetoothDevice device) async {
    return await device.discoverServices();
  }
}
