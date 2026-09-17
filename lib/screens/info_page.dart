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
                    subtitle: 'Adaptor Ponsel',
                    status: ble.isBluetoothOn ? 'Aktif' : 'Nonaktif',
                    isActive: ble.isBluetoothOn,
                    icon: Icons.bluetooth,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingLG),
                Expanded(
                  child: _buildStatusCard(
                    title: 'Status Alat',
                    subtitle: 'ESP32 BLE',
                    status: ble.isConnected 
                        ? 'Online' 
                        : (ble.savedDeviceId != null ? 'Offline (Tersimpan)' : 'Belum Terpasang'),
                    isActive: ble.isConnected,
                    icon: Icons.bluetooth_connected,
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingXL),

            // ================= PANDUAN RINGKAS =================
            Text('Petunjuk Pengoperasian', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingLG),
            _guideCard(context),

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
            child: const Icon(Icons.water_drop_rounded, color: AppTheme.primaryBlue, size: 24),
          ),
          const SizedBox(width: AppTheme.spacingLG),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('FETCORE AI', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  'Sistem Kontrol Dosing Pupuk Cair Presisi via Bluetooth BLE',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard({
    required String title,
    required String subtitle,
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Text(subtitle, style: const TextStyle(fontSize: 10, color: AppTheme.textGrey)),
          const SizedBox(height: 6),
          Text(
            status,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isActive ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingLG),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          _guideItem(
            Icons.bluetooth_searching,
            '1. Hubungkan Alat',
            'Buka menu Device untuk memindai sinyal "FETCORE-01" dan hubungkan.',
          ),
          const Divider(height: 16),
          _guideItem(
            Icons.speed_rounded,
            '2. Kalibrasi Pompa',
            'Atur durasi ms per 5 mL di menu Device agar takaran semprot presisi.',
          ),
          const Divider(height: 16),
          _guideItem(
            Icons.touch_app,
            '3. Atur & Semprot Dosis',
            'Terapkan dosis dari menu Manual atau Rekomendasi AI, lalu klik "Aktifkan Pompa" atau tekan tombol Pin 33 di alat.',
          ),
        ],
      ),
    );
  }

  Widget _guideItem(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.primaryBlue, size: 20),
        const SizedBox(width: AppTheme.spacingMD),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
            ],
          ),
        ),
      ],
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
          Text('v2.1 (BLE Edition)', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}