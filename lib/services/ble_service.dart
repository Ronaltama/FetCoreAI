import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/device_status.dart';

class BleService extends ChangeNotifier {
  static const String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String rxUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // HP Write ke ESP
  static const String txUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // HP Read/Notify dari ESP

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  List<ScanResult> _scanResults = [];
  List<ScanResult> get scanResults => _scanResults;

  final List<BluetoothDevice> _connectedDevices = [];
  List<BluetoothDevice> get connectedDevices => _connectedDevices;

  final Map<String, BluetoothCharacteristic> _writeCharacteristics = {};

  BluetoothDevice? _activeDevice;
  BluetoothDevice? get activeDevice => _activeDevice;

  final Map<String, DeviceStatus> _deviceStatuses = {};

  DeviceStatus? getStatus(String deviceId) => _deviceStatuses[deviceId];
  DeviceStatus? get activeDeviceStatus => _activeDevice != null ? _deviceStatuses[_activeDevice!.remoteId.str] : null;

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  
  bool _isBluetoothOn = false;
  bool get isBluetoothOn => _isBluetoothOn;

  BleService() {
    _init();
  }

  void _init() {
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      _isBluetoothOn = (state == BluetoothAdapterState.on);
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  Future<void> startScan() async {
    if (!_isBluetoothOn || _isScanning) return;
    _isScanning = true;
    _scanResults.clear();
    notifyListeners();

    _scanSub?.cancel();
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
    
    // Wait for scan to stop
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
    
    _isScanning = false;
    _scanSub?.cancel();
    notifyListeners();
  }
  
  Future<void> stopScan() async {
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      notifyListeners();
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await device.connect(autoConnect: false);
      
      // Listen to connection state to handle unexpected disconnects
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
           _handleDeviceDisconnect(device);
        }
      });

      if (!_connectedDevices.any((d) => d.remoteId == device.remoteId)) {
        _connectedDevices.add(device);
      }
      
      _activeDevice ??= device;
      
      // Discover services
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == serviceUuid) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString().toUpperCase() == txUuid) {
              await c.setNotifyValue(true);
              c.lastValueStream.listen((value) {
                _onDataReceived(device.remoteId.str, value);
              });
            } else if (c.uuid.toString().toUpperCase() == rxUuid) {
              _writeCharacteristics[device.remoteId.str] = c;
            }
          }
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error connecting to device: $e");
    }
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      debugPrint("Error disconnecting device: $e");
    }
    _handleDeviceDisconnect(device);
  }
  
  void _handleDeviceDisconnect(BluetoothDevice device) {
    _connectedDevices.removeWhere((d) => d.remoteId == device.remoteId);
    _writeCharacteristics.remove(device.remoteId.str);
    _deviceStatuses.remove(device.remoteId.str);
    
    if (_activeDevice?.remoteId == device.remoteId) {
      _activeDevice = _connectedDevices.isNotEmpty ? _connectedDevices.first : null;
    }
    notifyListeners();
  }

  void setActiveDevice(BluetoothDevice device) {
    if (_connectedDevices.any((d) => d.remoteId == device.remoteId)) {
      _activeDevice = device;
      notifyListeners();
    }
  }

  void _onDataReceived(String deviceId, List<int> data) {
    if (data.isEmpty) return;
    try {
      String jsonStr = utf8.decode(data);
      // Clean up string if necessary (e.g. trailing null bytes)
      jsonStr = jsonStr.trim();
      var jsonMap = jsonDecode(jsonStr);
      _deviceStatuses[deviceId] = DeviceStatus.fromJson(jsonMap);
      notifyListeners();
    } catch (e) {
      debugPrint("BleService: Error parsing JSON from $deviceId: $e - Data: ${utf8.decode(data)}");
    }
  }

  Future<void> sendToActive(Map<String, dynamic> data) async {
    if (_activeDevice == null) return;
    await _sendToDevice(_activeDevice!.remoteId.str, data);
  }

  Future<void> broadcast(Map<String, dynamic> data) async {
    for (var device in _connectedDevices) {
      await _sendToDevice(device.remoteId.str, data);
    }
  }

  Future<void> _sendToDevice(String deviceId, Map<String, dynamic> data) async {
    var c = _writeCharacteristics[deviceId];
    if (c != null) {
      String jsonStr = jsonEncode(data);
      List<int> bytes = utf8.encode(jsonStr);
      try {
        await c.write(bytes, withoutResponse: false);
      } catch (e) {
        debugPrint("BleService: Error writing to $deviceId: $e");
      }
    } else {
      debugPrint("BleService: No write characteristic found for $deviceId");
    }
  }

  // Perintah ke ESP32
  void setDosis(double value) => sendToActive({'set_dosis': value});
  void broadcastDosis(double value) => broadcast({'set_dosis': value});
  void resetStats() => sendToActive({'reset_stats': true});
}
