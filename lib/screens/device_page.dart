import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ferticore_ai/services/ble_service.dart';
import 'package:ferticore_ai/theme/theme.dart';

class DevicePage extends StatelessWidget {
  const DevicePage({super.key});

  void _showFeedback(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

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
            // Status Bluetooth HP jika non-aktif
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
                      child: Text(
                        'Bluetooth HP belum aktif. Silakan nyalakan Bluetooth untuk menyambung ke alat.',
                        style: TextStyle(color: AppTheme.errorColor, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),

            // Header Halaman
            Text(
              'Pengaturan & Kontrol Alat',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              'Kelola sambungan dan kalibrasi unit FertiCore Anda',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
            ),
            const SizedBox(height: AppTheme.spacingXL),

            // KARTU UTAMA: STATUS ALAT (Dedicated Single Device)
            _buildDeviceStatusCard(context, ble),
            const SizedBox(height: AppTheme.spacingXL),

            // KARTU KONTROL HARDWARE & KALIBRASI
            _buildHardwareToolsCard(context, ble),
            const SizedBox(height: AppTheme.spacingXL),

            // KARTU PENCARIAN & GANTI PERANGKAT
            _buildScanSection(context, ble),
          ],
        ),
      ),
    );
  }

  // 1. KARTU STATUS PERANGKAT UTAMA
  Widget _buildDeviceStatusCard(BuildContext context, BleService ble) {
    final isConnected = ble.isConnected;
    final isConnecting = ble.isConnecting;
    final savedDevice = ble.savedDeviceId;
    final deviceName = isConnected
        ? (ble.connectedDevice?.advName.isNotEmpty == true ? ble.connectedDevice!.advName : 'FERTICORE-01')
        : (ble.savedDeviceName ?? 'FERTICORE-01');

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: isConnected ? AppTheme.successColor.withValues(alpha: 0.5) : AppTheme.borderColor,
          width: isConnected ? 1.5 : 1.0,
        ),
        boxShadow: AppTheme.shadowMD,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  color: (isConnected ? AppTheme.successColor : AppTheme.textGrey).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isConnected ? Icons.bluetooth_connected : Icons.bluetooth,
                  color: isConnected ? AppTheme.successColor : AppTheme.textGrey,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppTheme.spacingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      savedDevice != null || isConnected ? deviceName : 'Belum Ada Alat Terhubung',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isConnected
                          ? 'Status: Terhubung (Online)'
                          : (isConnecting
                              ? 'Status: Sedang Menyambung...'
                              : (savedDevice != null ? 'Status: Terputus (Tersimpan)' : 'Belum Terpasang')),
                      style: TextStyle(
                        fontSize: 12,
                        color: isConnected ? AppTheme.successColor : (isConnecting ? AppTheme.primaryBlue : AppTheme.textGrey),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingLG),
          const Divider(height: 1),
          const SizedBox(height: AppTheme.spacingMD),

          // Action Buttons
          if (isConnected)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => ble.requestSync(),
                    icon: const Icon(Icons.sync, size: 18),
                    label: const Text('Tarik Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ble.disconnectDevice();
                      _showFeedback(context, 'Alat berhasil diputuskan');
                    },
                    icon: const Icon(Icons.link_off, size: 18, color: AppTheme.errorColor),
                    label: const Text('Putuskan', style: TextStyle(color: AppTheme.errorColor)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.5)),
                    ),
                  ),
                ),
              ],
            )
          else if (savedDevice != null)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isConnecting ? null : () => ble.connectSavedDevice(),
                    icon: isConnecting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.bluetooth_connected, size: 18),
                    label: Text(isConnecting ? 'Menyambung...' : 'Hubungkan Alat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMD),
                IconButton(
                  tooltip: 'Lupakan Alat',
                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                  onPressed: () {
                    ble.forgetDevice();
                    _showFeedback(context, 'Alat dilupakan. Silakan scan alat baru.');
                  },
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (!ble.isBluetoothOn) ? null : () => ble.startScan(),
                icon: const Icon(Icons.search, size: 18),
                label: const Text('Cari & Pasang Alat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryBlue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // 2. KARTU KONTROL HARDWARE & KALIBRASI
  Widget _buildHardwareToolsCard(BuildContext context, BleService ble) {
    final isConnected = ble.isConnected;

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppTheme.primaryBlue, size: 20),
              const SizedBox(width: AppTheme.spacingMD),
              Text(
                'Kontrol & Kalibrasi Hardware',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMD),

          // Tool 1: Tare Timbangan (Zeroing)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.scale, color: AppTheme.primaryBlue, size: 20),
            ),
            title: const Text('Nol-kan Timbangan (Tare)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Kalibrasi bobot wadah kosong menjadi 0.00 gram', style: TextStyle(fontSize: 12)),
            trailing: OutlinedButton(
              onPressed: isConnected
                  ? () {
                      ble.tareScale();
                      _showFeedback(context, 'Perintah Tare (Nol-kan Timbangan) terkirim');
                    }
                  : null,
              child: const Text('Tare'),
            ),
          ),
          const Divider(),

          // Tool 2: Uji Motor Tabur
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.rotate_right_rounded, color: AppTheme.accentGreen, size: 20),
            ),
            title: const Text('Mulai Penaburan Uji', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            subtitle: const Text('Nyalakan motor penabur untuk menguji 1 sesi pemupukan', style: TextStyle(fontSize: 12)),
            trailing: ElevatedButton(
              onPressed: isConnected
                  ? () {
                      ble.triggerMotor();
                      _showFeedback(context, 'Perintah Mulai Tabur terkirim ke alat!');
                    }
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Mulai Tabur'),
            ),
          ),
        ],
      ),
    );
  }

  // 3. BAGIAN SCAN & GANTI PERANGKAT
  Widget _buildScanSection(BuildContext context, BleService ble) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Cari / Ganti Alat (BLE Scan)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            ElevatedButton.icon(
              onPressed: (!ble.isBluetoothOn) ? null : (ble.isScanning ? ble.stopScan : ble.startScan),
              icon: Icon(ble.isScanning ? Icons.stop : Icons.search, size: 16),
              label: Text(ble.isScanning ? 'Stop' : 'Scan'),
              style: ElevatedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingMD),

        if (ble.isScanning && ble.scanResults.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppTheme.spacingXL),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 12),
                  Text('Memindai sinyal Bluetooth ESP32...', style: TextStyle(color: AppTheme.textGrey, fontSize: 12)),
                ],
              ),
            ),
          )
        else if (ble.scanResults.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: const Center(
              child: Text(
                'Tekan Scan untuk mencari perangkat ESP32 di sekitar.',
                style: TextStyle(color: AppTheme.textGrey, fontSize: 13),
              ),
            ),
          )
        else
          ...ble.scanResults.map((result) {
            final device = result.device;
            if (device.advName.isEmpty) return const SizedBox.shrink();
            final isThisConnected = ble.connectedDevice?.remoteId == device.remoteId;

            return Card(
              margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
              child: ListTile(
                leading: const Icon(Icons.bluetooth, color: AppTheme.primaryBlue),
                title: Text(device.advName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${device.remoteId.str} | RSSI: ${result.rssi} dBm'),
                trailing: isThisConnected
                    ? const Chip(label: Text('Aktif', style: TextStyle(color: AppTheme.successColor, fontSize: 11)))
                    : ElevatedButton(
                        onPressed: () async {
                          await ble.connectToDevice(device);
                          if (context.mounted) {
                            _showFeedback(context, 'Tersambung ke ${device.advName}');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryBlue,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                        ),
                        child: const Text('Pasang'),
                      ),
              ),
            );
          }),
      ],
    );
  }
}
