import 'package:flutter/material.dart';
import 'package:ferticore_ai/services/ble_service.dart';
import 'package:ferticore_ai/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class DosisCardWidget extends StatelessWidget {
  final BleService ble;

  const DosisCardWidget({super.key, required this.ble});

  @override
  Widget build(BuildContext context) {
    final activeDevice = ble.activeDevice;
    final status = ble.activeDeviceStatus;
    final hasDevice = activeDevice != null;
    final hasData = status != null;
    final dosis = status?.gramasi ?? 0.0;
    final isMotorRunning = status?.isMotorRunning ?? false;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        border: Border.all(color: AppTheme.borderColor),
        color: AppTheme.surfaceLight,
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
                      'Dosis Saat Ini (Load Cell)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      hasDevice
                          ? '${activeDevice.advName.isNotEmpty ? activeDevice.advName : "ESP32"} (${activeDevice.remoteId.str})'
                          : 'Tidak ada perangkat terhubung',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: hasDevice ? AppTheme.primaryBlue : AppTheme.errorColor,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
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
                  hasDevice ? dosis.toStringAsFixed(2) : '--',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 48,
                    fontWeight: FontWeight.w700,
                    color: hasDevice ? AppTheme.primaryBlue : AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingSM),
                Text(
                  hasDevice ? 'gram (Data Real-time ESP32)' : 'Hubungkan alat via menu Device',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Status indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Device status indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMD,
                  vertical: AppTheme.spacingSM,
                ),
                decoration: BoxDecoration(
                  color: (hasDevice
                          ? (hasData ? AppTheme.successColor : AppTheme.warningColor)
                          : AppTheme.textGrey)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusSM),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasDevice
                          ? (hasData ? Icons.check_circle : Icons.sync)
                          : Icons.cancel_outlined,
                      size: 14,
                      color: hasDevice
                          ? (hasData ? AppTheme.successColor : AppTheme.warningColor)
                          : AppTheme.textGrey,
                    ),
                    const SizedBox(width: AppTheme.spacingSM),
                    Text(
                      !hasDevice
                          ? 'Offline'
                          : (hasData ? 'Terhubung (Online)' : 'Menunggu Telemetry...'),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: hasDevice
                                ? (hasData ? AppTheme.successColor : AppTheme.warningColor)
                                : AppTheme.textGrey,
                          ),
                    ),
                  ],
                ),
              ),

              // Motor tabur status
              if (hasDevice)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingMD,
                    vertical: AppTheme.spacingSM,
                  ),
                  decoration: BoxDecoration(
                    color: (isMotorRunning ? AppTheme.accentGreen : AppTheme.textGrey)
                        .withValues(alpha: 0.1),
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
                        isMotorRunning ? 'Motor: Menabur' : 'Motor: Standby',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isMotorRunning ? AppTheme.accentGreen : AppTheme.textGrey,
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
