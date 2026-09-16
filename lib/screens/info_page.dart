import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ferticore_ai/services/ble_service.dart';
import 'package:ferticore_ai/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

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
            // ================= APP INFO =================
            _appInfo(context),
            const SizedBox(height: AppTheme.spacingXL),

            // ================= STATUS =================
            Text('Status Sistem', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingLG),
            Row(
              children: [
                Expanded(
                  child: _buildStatusCard(
                    title: 'Bluetooth HP',
                    status: ble.isBluetoothOn ? 'Aktif' : 'Nonaktif',
                    isActive: ble.isBluetoothOn,
                    icon: Icons.bluetooth,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingLG),
                Expanded(
                  child: _buildStatusCard(
                    title: 'Status Alat',
                    status: ble.isConnected 
                        ? 'Online (Terhubung)' 
                        : (ble.savedDeviceId != null ? 'Offline (Tersimpan)' : 'Belum Ada Alat'),
                    isActive: ble.isConnected,
                    icon: Icons.bluetooth_connected,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // ================= FEATURES =================
            Text('Fitur Utama', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingLG),
            ..._buildFeatures(context),

            const SizedBox(height: AppTheme.spacingXL),

            // ================= VERSION =================
            _versionCard(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _appInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.primaryBlue.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
            ),
            child: const Icon(Icons.info_rounded, color: AppTheme.primaryBlue, size: 24),
          ),
          const SizedBox(width: AppTheme.spacingLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FETCORE AI', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  'Sistem kontrol dosing pupuk cair presisi via Bluetooth',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFeatures(BuildContext context) {
    final features = [
      ('Monitoring Dosis', 'Pantau dosis pupuk secara real-time langsung dari perangkat via BLE', Icons.monitor_heart_rounded),
      ('Rekomendasi AI', 'Hitung dosis berbasis agronomi (komoditas, luas, HST)', Icons.lightbulb_rounded),
      ('Kontrol Manual & Remote Trigger', 'Atur dosis dan nyalakan penaburan langsung dari HP', Icons.touch_app_rounded),
      ('Offline-First & Auto-Reconnect', 'Koneksi otomatis dan data statistik tersimpan di memori HP meski alat offline', Icons.cloud_done_rounded),
      ('Riwayat Pemupukan', 'Log otomatis penggunaan pupuk tersimpan di aplikasi', Icons.history),
    ];

    return features.map((feature) {
      return Container(
        margin: const EdgeInsets.only(bottom: AppTheme.spacingLG),
        padding: const EdgeInsets.all(AppTheme.spacingLG),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
          border: Border.all(color: AppTheme.borderColor),
          color: AppTheme.surfaceLight,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppTheme.spacingMD),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              ),
              child: Icon(feature.$3, color: AppTheme.primaryBlue, size: 20),
            ),
            const SizedBox(width: AppTheme.spacingLG),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(feature.$1, style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: AppTheme.spacingSM),
                  Text(
                    feature.$2,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildStatusCard({
    required String title,
    required String status,
    required bool isActive,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(
          color: isActive
              ? AppTheme.successColor.withValues(alpha: 0.3)
              : AppTheme.errorColor.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: isActive ? AppTheme.successColor : AppTheme.errorColor, size: 32),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _versionCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor),
        color: Colors.grey.shade50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Versi Aplikasi', style: Theme.of(context).textTheme.bodySmall),
          Text('1.1.0 (BLE)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}