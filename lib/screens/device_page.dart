import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ferticore_ai/services/ble_service.dart';
import 'package:ferticore_ai/theme/theme.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  @override
  Widget build(BuildContext context) {
    final ble = Provider.of<BleService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Bluetooth HP
            if (!ble.isBluetoothOn)
              Container(
                margin: const EdgeInsets.only(bottom: AppTheme.spacingLG),
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: AppTheme.errorColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                  border: Border.all(color: AppTheme.errorColor.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bluetooth_disabled, color: AppTheme.errorColor),
                    SizedBox(width: AppTheme.spacingMD),
                    Expanded(
                      child: Text('Bluetooth pada HP Anda belum aktif. Silakan aktifkan Bluetooth.',
                          style: TextStyle(color: AppTheme.errorColor)),
                    ),
                  ],
                ),
              ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Manajemen Perangkat',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                ElevatedButton.icon(
                  onPressed: (!ble.isBluetoothOn) ? null : (ble.isScanning ? ble.stopScan : ble.startScan),
                  icon: Icon(ble.isScanning ? Icons.stop : Icons.search),
                  label: Text(ble.isScanning ? 'Stop' : 'Scan'),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // Connected Devices
            Text(
              'Perangkat Terhubung (${ble.connectedDevices.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            if (ble.connectedDevices.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingXL),
                  child: Text('Belum ada perangkat terhubung.'),
                ),
              )
            else
              ...ble.connectedDevices.map((d) => _buildConnectedDevice(context, d, ble)),

            const SizedBox(height: AppTheme.spacingXL),

            // Scan Results
            Text(
              'Perangkat Tersedia',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppTheme.spacingMD),
            if (ble.scanResults.isEmpty && !ble.isScanning)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingXL),
                  child: Text('Tidak ada perangkat terdeteksi. Mulai scan.'),
                ),
              )
            else if (ble.isScanning && ble.scanResults.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spacingXL),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              ...ble.scanResults.map((r) => _buildScanResult(context, r, ble)),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectedDevice(BuildContext context, BluetoothDevice device, BleService ble) {
    final isActive = ble.activeDevice?.remoteId == device.remoteId;
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: isActive ? AppTheme.primaryBlue : Colors.transparent,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
      ),
      child: ListTile(
        leading: const Icon(Icons.bluetooth_connected, color: AppTheme.primaryBlue, size: 30),
        title: Text(
          device.advName.isEmpty ? 'Unknown Device' : device.advName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(device.remoteId.str),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isActive)
              TextButton(
                onPressed: () => ble.setActiveDevice(device),
                child: const Text('Set Aktif'),
              ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Aktif', style: TextStyle(color: AppTheme.primaryBlue, fontSize: 12)),
              ),
            IconButton(
              icon: const Icon(Icons.link_off, color: AppTheme.errorColor),
              tooltip: 'Disconnect',
              onPressed: () => ble.disconnectDevice(device),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanResult(BuildContext context, ScanResult result, BleService ble) {
    final device = result.device;
    if (device.advName.isEmpty) return const SizedBox.shrink();
    
    final isConnected = ble.connectedDevices.any((d) => d.remoteId == device.remoteId);
    if (isConnected) return const SizedBox.shrink(); // Hide if already connected

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: ListTile(
        leading: const Icon(Icons.bluetooth, color: AppTheme.textGrey, size: 30),
        title: Text(device.advName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${device.remoteId.str}\nRSSI: ${result.rssi} dBm'),
        isThreeLine: true,
        trailing: ElevatedButton(
          onPressed: () => ble.connectToDevice(device),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Hubungkan'),
        ),
      ),
    );
  }
}
