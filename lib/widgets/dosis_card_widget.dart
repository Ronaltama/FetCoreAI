import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ferticore_ai/services/ble_service.dart';
import 'package:ferticore_ai/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DosisCardWidget extends StatelessWidget {
  final BleService ble;

  const DosisCardWidget({super.key, required this.ble});

  @override
  Widget build(BuildContext context) {
    final isConnected = ble.isConnected;
    final isLive = ble.isLive;
    final status = ble.activeDeviceStatus;
    final hasData = status != null;
    final dosis = status?.gramasi ?? 0.0;
    final isMotorRunning = status?.isMotorRunning ?? false;
    final deviceName = ble.connectedDevice?.advName.isNotEmpty == true 
        ? ble.connectedDevice!.advName 
        : (ble.savedDeviceName ?? "FERTICORE-01");

    String syncInfo = "Belum ada data";
    if (ble.lastSyncTime != null) {
      syncInfo = DateFormat('dd MMM, HH:mm').format(ble.lastSyncTime!);
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(
          color: isLive ? AppTheme.primaryBlue.withValues(alpha: 0.4) : AppTheme.borderColor,
          width: isLive ? 1.5 : 1.0,
        ),
        color: AppTheme.surfaceLight,
        boxShadow: isLive ? [
          BoxShadow(
            color: AppTheme.primaryBlue.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ] : null,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingXL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingMD),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryBlueLight, AppTheme.primaryBlue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(Icons.scale, color: Colors.white, size: 20),
              ),
              const SizedBox(width: AppTheme.spacingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dosis Saat Ini',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      isConnected
                          ? '$deviceName (Online)'
                          : '$deviceName (Offline)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isConnected ? AppTheme.successColor : AppTheme.textGrey,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Tombol konek cepat jika offline
              if (!isConnected && ble.savedDeviceId != null)
                TextButton.icon(
                  onPressed: ble.isConnecting ? null : () => ble.connectSavedDevice(),
                  icon: ble.isConnecting 
                      ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 16),
                  label: Text(ble.isConnecting ? 'Konek...' : 'Konek'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppTheme.primaryBlue,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Value
          Center(
            child: Column(
              children: [
                Text(
                  hasData ? dosis.toStringAsFixed(2) : '--',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: isLive ? AppTheme.primaryBlue : (hasData ? AppTheme.textDark : AppTheme.textGrey),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  isLive 
                      ? 'mL (Real-time dari Alat)' 
                      : (hasData ? 'mL (Data Terakhir: $syncInfo)' : 'Hubungkan alat untuk sinkronisasi'),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isLive ? AppTheme.primaryBlue : AppTheme.textGrey,
                    fontWeight: isLive ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Status indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Online / Offline Status Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMD,
                  vertical: AppTheme.spacingSM,
                ),
                decoration: BoxDecoration(
                  color: (isLive 
                          ? AppTheme.successColor 
                          : (hasData ? AppTheme.warningColor : AppTheme.textGrey))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  border: Border.all(
                    color: (isLive 
                            ? AppTheme.successColor 
                            : (hasData ? AppTheme.warningColor : AppTheme.textGrey))
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isLive 
                          ? Icons.check_circle 
                          : (isConnected ? Icons.sync : (hasData ? Icons.cloud_done : Icons.cloud_off)),
                      size: 14,
                      color: isLive 
                          ? AppTheme.successColor 
                          : (hasData ? AppTheme.warningColor : AppTheme.textGrey),
                    ),
                    const SizedBox(width: AppTheme.spacingSM),
                    Text(
                      isLive 
                          ? 'Online (Live)' 
                          : (isConnected 
                              ? 'Menunggu Data...' 
                              : (hasData ? 'Offline (Tersimpan)' : 'Belum Ada Data')),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: isLive 
                                ? AppTheme.successColor 
                                : (hasData ? AppTheme.warningColor : AppTheme.textGrey),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),

              // Motor tabur status
              if (isConnected)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMD,
                    vertical: AppTheme.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: (isMotorRunning ? AppTheme.accentGreen : AppTheme.textGrey)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.rotate_right_rounded,
                        size: 14,
                        color: isMotorRunning ? AppTheme.accentGreen : AppTheme.textGrey,
                      ),
                      const SizedBox(width: AppTheme.spacingSM),
                      Text(
                      isMotorRunning ? 'Pompa: Aktif' : 'Pompa: Standby',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isMotorRunning ? AppTheme.accentGreen : AppTheme.textGrey,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
