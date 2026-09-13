import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/device_status.dart';

class BleService extends ChangeNotifier {
  static const String serviceUuid = "6E400001-B5A3-F393-E0A9-E50E24DCCA9E";
  static const String rxUuid = "6E400002-B5A3-F393-E0A9-E50E24DCCA9E"; // HP Write ke ESP
  static const String txUuid = "6E400003-B5A3-F393-E0A9-E50E24DCCA9E"; // HP Read/Notify dari ESP

  // Connection State (Single Device Dedicated)
  BluetoothDevice? _connectedDevice;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothDevice? get activeDevice => _connectedDevice; // Kompatibilitas
  List<BluetoothDevice> get connectedDevices => _connectedDevice != null ? [_connectedDevice!] : [];
  bool get isConnected => _connectedDevice != null;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  // Saved / Paired Device Info
  String? _savedDeviceId;
  String? _savedDeviceName;
  String? get savedDeviceId => _savedDeviceId;
  String? get savedDeviceName => _savedDeviceName;

  // Status & Telemetry (Offline First Caching)
  DeviceStatus? _liveStatus;
  DeviceStatus? _cachedStatus;
  DateTime? _lastSyncTime;

  DeviceStatus? get activeDeviceStatus => _liveStatus ?? _cachedStatus;
  DeviceStatus? get liveStatus => _liveStatus;
  DeviceStatus? get cachedStatus => _cachedStatus;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get isLive => _connectedDevice != null && _liveStatus != null;
  bool get hasData => activeDeviceStatus != null;

  BluetoothCharacteristic? _writeCharacteristic;
  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<BluetoothAdapterState>? _adapterSub;
  StreamSubscription<BluetoothConnectionState>? _deviceConnectionSub;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  List<ScanResult> _scanResults = [];
  List<ScanResult> get scanResults => _scanResults;

  bool _isBluetoothOn = false;
  bool get isBluetoothOn => _isBluetoothOn;

  BleService() {
    _init();
  }

  Future<void> _init() async {
    // 1. Load cached device & status dari SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    _savedDeviceId = prefs.getString('saved_device_id');
    _savedDeviceName = prefs.getString('saved_device_name');
    
    final statusJson = prefs.getString('cached_device_status');
    if (statusJson != null) {
      try {
        _cachedStatus = DeviceStatus.fromJson(jsonDecode(statusJson));
      } catch (e) {
        debugPrint("Error parsing cached status: $e");
      }
    }

    final syncTimeStr = prefs.getString('last_sync_time');
    if (syncTimeStr != null) {
      _lastSyncTime = DateTime.tryParse(syncTimeStr);
    }
    notifyListeners();

    // 2. Listen ke state adapter bluetooth
    _adapterSub = FlutterBluePlus.adapterState.listen((state) {
      _isBluetoothOn = (state == BluetoothAdapterState.on);
      notifyListeners();

      // Jika bluetooth menyala dan ada saved device, coba auto-connect
      if (_isBluetoothOn && _savedDeviceId != null && _connectedDevice == null && !_isConnecting) {
        connectSavedDevice();
      }
    });
  }

  @override
  void dispose() {
    _adapterSub?.cancel();
    _scanSub?.cancel();
    _deviceConnectionSub?.cancel();
    super.dispose();
  }

  // ================= SCANNING =================
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

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      await FlutterBluePlus.isScanning.where((val) => val == false).first;
    } catch (e) {
      debugPrint("Scan error: $e");
    } finally {
      _isScanning = false;
      _scanSub?.cancel();
      notifyListeners();
    }
  }

  Future<void> stopScan() async {
    if (_isScanning) {
      await FlutterBluePlus.stopScan();
      _isScanning = false;
      notifyListeners();
    }
  }

  // ================= KONEKSI (SINGLE DEVICE) =================
  Future<void> connectToDevice(BluetoothDevice device) async {
    if (_isConnecting) return;
    _isConnecting = true;
    notifyListeners();

    try {
      // Jika ada device lain yang tersambung, putuskan terlebih dahulu
      if (_connectedDevice != null && _connectedDevice!.remoteId != device.remoteId) {
        await _connectedDevice!.disconnect();
      }

      await device.connect(autoConnect: false, timeout: const Duration(seconds: 8));

      _connectedDevice = device;
      _savedDeviceId = device.remoteId.str;
      _savedDeviceName = device.advName.isNotEmpty ? device.advName : "FERTICORE-01";

      // Simpan ke SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_device_id', _savedDeviceId!);
      await prefs.setString('saved_device_name', _savedDeviceName!);

      // Listen connection state
      _deviceConnectionSub?.cancel();
      _deviceConnectionSub = device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleDeviceDisconnect();
        }
      });

      // Discover services & characteristics
      List<BluetoothService> services = await device.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString().toUpperCase() == serviceUuid) {
          for (BluetoothCharacteristic c in service.characteristics) {
            if (c.uuid.toString().toUpperCase() == txUuid) {
              await c.setNotifyValue(true);
              c.lastValueStream.listen((value) {
                _onDataReceived(value);
              });
            } else if (c.uuid.toString().toUpperCase() == rxUuid) {
              _writeCharacteristic = c;
            }
          }
        }
      }

      _isConnecting = false;
      notifyListeners();

      // Minta telemetry sinkronisasi awal
      requestSync();
    } catch (e) {
      debugPrint("Error connecting to device: $e");
      _isConnecting = false;
      _connectedDevice = null;
      notifyListeners();
    }
  }

  Future<void> connectSavedDevice() async {
    if (_savedDeviceId == null || _connectedDevice != null || _isConnecting) return;
    try {
      final device = BluetoothDevice.fromId(_savedDeviceId!);
      await connectToDevice(device);
    } catch (e) {
      debugPrint("Error auto connecting saved device: $e");
    }
  }

  Future<void> disconnectDevice([BluetoothDevice? device]) async {
    try {
      if (_connectedDevice != null) {
        await _connectedDevice!.disconnect();
      }
    } catch (e) {
      debugPrint("Error disconnecting: $e");
    }
    _handleDeviceDisconnect();
  }

  Future<void> forgetDevice() async {
    await disconnectDevice();
    _savedDeviceId = null;
    _savedDeviceName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_device_id');
    await prefs.remove('saved_device_name');
    notifyListeners();
  }

  void _handleDeviceDisconnect() {
    _connectedDevice = null;
    _writeCharacteristic = null;
    _liveStatus = null; // Kembali ke cached status
    notifyListeners();
  }

  // ================= PENANGANAN DATA (OFFLINE-FIRST) =================
  void _onDataReceived(List<int> data) {
    if (data.isEmpty) return;
    try {
      String jsonStr = utf8.decode(data).trim();
      var jsonMap = jsonDecode(jsonStr);
      _liveStatus = DeviceStatus.fromJson(jsonMap);
      _cachedStatus = _liveStatus;
      _lastSyncTime = DateTime.now();

      // Simpan ke offline cache lokal
      _saveStatusLocally(_cachedStatus!, _lastSyncTime!);

      notifyListeners();
    } catch (e) {
      debugPrint("BleService: Error parsing telemetry JSON: $e");
    }
  }

  Future<void> _saveStatusLocally(DeviceStatus status, DateTime syncTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_device_status', jsonEncode(status.toJson()));
      await prefs.setString('last_sync_time', syncTime.toIso8601String());
    } catch (e) {
      debugPrint("Error saving status locally: $e");
    }
  }

  // ================= PENGIRIMAN PERINTAH =================
  Future<void> sendData(Map<String, dynamic> data) async {
    if (_writeCharacteristic == null || _connectedDevice == null) {
      debugPrint("BleService: Cannot send data - no connected device");
      return;
    }

    try {
      String jsonStr = jsonEncode(data);
      List<int> bytes = utf8.encode(jsonStr);
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
    } catch (e) {
      debugPrint("BleService: Error writing command: $e");
    }
  }

  // Perintah Bisnis
  void setDosis(double value) => sendData({'set_dosis': value});
  void triggerMotor() => sendData({'trigger': true});
  void tareScale() => sendData({'tare': true});
  void requestSync() => sendData({'sync': true});
  
  void resetStats() async {
    sendData({'reset_stats': true});
    // Reset lokal juga
    _liveStatus = DeviceStatus(
      gramasi: activeDeviceStatus?.gramasi ?? 5.0,
      isMotorRunning: false,
      totalVolume: 0.0,
      totalSesi: 0,
      rataRata: 0.0,
    );
    _cachedStatus = _liveStatus;
    _lastSyncTime = DateTime.now();
    await _saveStatusLocally(_cachedStatus!, _lastSyncTime!);
    notifyListeners();
  }
}
