import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:wifi_scan/wifi_scan.dart';

import 'services/permission_service.dart';
import 'services/wifi_service.dart';
import 'services/bluetooth_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ConnectivityApp());
}

class ConnectivityApp extends StatelessWidget {
  const ConnectivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter WiFi & Bluetooth Setup',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F62FE),
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F62FE),
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system,
      home: const MainHomeScreen(),
    );
  }
}

class MainHomeScreen extends StatefulWidget {
  const MainHomeScreen({super.key});

  @override
  State<MainHomeScreen> createState() => _MainHomeScreenState();
}

class _MainHomeScreenState extends State<MainHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    bool granted = await PermissionService.requestAllPermissions();
    if (mounted && !granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beberapa izin lokasi / bluetooth belum diberikan.'),
        ),
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flutter WiFi & Bluetooth',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.shield_outlined),
            tooltip: 'Minta Izin',
            onPressed: () async {
              await _requestPermissions();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.wifi), text: 'Wi-Fi'),
            Tab(icon: Icon(Icons.bluetooth), text: 'Bluetooth'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          WifiTabScreen(),
          BluetoothTabScreen(),
        ],
      ),
    );
  }
}

/* ========================================================================= */
/*                               WI-FI TAB                                   */
/* ========================================================================= */

class WifiTabScreen extends StatefulWidget {
  const WifiTabScreen({super.key});

  @override
  State<WifiTabScreen> createState() => _WifiTabScreenState();
}

class _WifiTabScreenState extends State<WifiTabScreen> {
  final WifiService _wifiService = WifiService();
  WifiInfo _currentWifi = WifiInfo();
  List<WiFiAccessPoint> _accessPoints = [];
  bool _isScanning = false;
  StreamSubscription? _connectivitySub;

  @override
  void initState() {
    super.initState();
    _loadCurrentWifiInfo();
    _connectivitySub = _wifiService.onConnectivityChanged.listen((_) {
      _loadCurrentWifiInfo();
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentWifiInfo() async {
    final info = await _wifiService.getCurrentWifiInfo();
    if (mounted) {
      setState(() {
        _currentWifi = info;
      });
    }
  }

  Future<void> _scanWifi() async {
    setState(() {
      _isScanning = true;
    });

    bool canScan = await _wifiService.canScanWifi();
    if (!canScan) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pemindaian WiFi tidak didukung atau butuh izin lokasi.'),
          ),
        );
        setState(() {
          _isScanning = false;
        });
      }
      return;
    }

    bool started = await _wifiService.startScan();
    if (started) {
      await Future.delayed(const Duration(seconds: 3));
      final results = await _wifiService.getScannedAccessPoints();
      if (mounted) {
        setState(() {
          _accessPoints = results;
          _isScanning = false;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadCurrentWifiInfo();
        await _scanWifi();
      },
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Card Status Wi-Fi Terkoneksi
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Icon(
                          Icons.wifi,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Status Wi-Fi',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            Text(
                              _currentWifi.ssid ?? 'Tidak Terkoneksi',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _loadCurrentWifiInfo,
                      ),
                    ],
                  ),
                  if (_currentWifi.ipAddress != null) ...[
                    const Divider(height: 24),
                    Text('IP Address: ${_currentWifi.ipAddress}'),
                    if (_currentWifi.bssid != null)
                      Text('BSSID: ${_currentWifi.bssid}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tombol Scan Wi-Fi
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jaringan Sekitar (${_accessPoints.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              ElevatedButton.icon(
                onPressed: _isScanning ? null : _scanWifi,
                icon: _isScanning
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search),
                label: Text(_isScanning ? 'Memindai...' : 'Scan WiFi'),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // List Hasil Scan Wi-Fi
          if (_accessPoints.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Center(
                  child: Text(
                    _isScanning
                        ? 'Sedang mencari jaringan Wi-Fi...'
                        : 'Tekan "Scan WiFi" untuk mencari jaringan di sekitar.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else
            ..._accessPoints.map(
              (ap) => Card(
                margin: const EdgeInsets.only(bottom: 8.0),
                child: ListTile(
                  leading: const Icon(Icons.wifi_lock),
                  title: Text(ap.ssid.isEmpty ? '[Hidden SSID]' : ap.ssid),
                  subtitle: Text('Sinyal: ${ap.level} dBm | Frekuensi: ${ap.frequency} MHz'),
                  trailing: ElevatedButton(
                    onPressed: () {
                      _showConnectDialog(context, ap.ssid);
                    },
                    child: const Text('Konek'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showConnectDialog(BuildContext context, String ssid) {
    final passController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Konek ke $ssid'),
        content: TextField(
          controller: passController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password WiFi',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Permintaan menghubungkan ke $ssid telah diproses.',
                  ),
                ),
              );
            },
            child: const Text('Hubungkan'),
          ),
        ],
      ),
    );
  }
}

/* ========================================================================= */
/*                             BLUETOOTH TAB                                 */
/* ========================================================================= */

class BluetoothTabScreen extends StatefulWidget {
  const BluetoothTabScreen({super.key});

  @override
  State<BluetoothTabScreen> createState() => _BluetoothTabScreenState();
}

class _BluetoothTabScreenState extends State<BluetoothTabScreen> {
  final BluetoothServiceHelper _btService = BluetoothServiceHelper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<ble.BluetoothAdapterState>(
      stream: _btService.adapterState,
      initialData: ble.BluetoothAdapterState.unknown,
      builder: (context, snapshot) {
        final adapterState = snapshot.data;

        if (adapterState != ble.BluetoothAdapterState.on) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bluetooth_disabled,
                    size: 64,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bluetooth Tidak Aktif (${adapterState.toString().split('.').last})',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        await ble.FlutterBluePlus.turnOn();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Gagal mengaktifkan Bluetooth: $e'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Aktifkan Bluetooth'),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            // Controls section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: StreamBuilder<bool>(
                stream: _btService.isScanning,
                initialData: false,
                builder: (context, scanSnap) {
                  final isScanning = scanSnap.data ?? false;
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Perangkat BLE Sekitar',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () async {
                          if (isScanning) {
                            await _btService.stopScan();
                          } else {
                            try {
                              await _btService.startScan();
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString())),
                                );
                              }
                            }
                          }
                        },
                        icon: isScanning
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.bluetooth_searching),
                        label: Text(isScanning ? 'Hentikan' : 'Scan Bluetooth'),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Devices list
            Expanded(
              child: StreamBuilder<List<ble.ScanResult>>(
                stream: _btService.scanResults,
                initialData: const [],
                builder: (context, snapshot) {
                  final results = snapshot.data ?? [];
                  if (results.isEmpty) {
                    return const Center(
                      child: Text(
                        'Belum ada perangkat terdeteksi.\nTekan "Scan Bluetooth" untuk memulai.',
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final result = results[index];
                      final deviceName = result.device.platformName.isNotEmpty
                          ? result.device.platformName
                          : (result.advertisementData.advName.isNotEmpty
                              ? result.advertisementData.advName
                              : 'Perangkat Tanpa Nama');

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 4.0,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            child: Text('${result.rssi}'),
                          ),
                          title: Text(deviceName),
                          subtitle: Text(result.device.remoteId.str),
                          trailing: StreamBuilder<ble.BluetoothConnectionState>(
                            stream: result.device.connectionState,
                            initialData:
                                ble.BluetoothConnectionState.disconnected,
                            builder: (context, connSnap) {
                              final connState = connSnap.data;
                              final isConnected = connState ==
                                  ble.BluetoothConnectionState.connected;

                              return ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isConnected
                                      ? Colors.red.shade100
                                      : null,
                                ),
                                onPressed: () async {
                                  if (isConnected) {
                                    await _btService
                                        .disconnectDevice(result.device);
                                  } else {
                                    try {
                                      await _btService
                                          .connectDevice(result.device);
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Terhubung ke $deviceName',
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Gagal mengoneksikan: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                                child: Text(
                                  isConnected ? 'Putus' : 'Sambungkan',
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
