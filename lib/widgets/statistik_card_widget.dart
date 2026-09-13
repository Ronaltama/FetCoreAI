import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ferticore_ai/models/device_status.dart';
import 'package:ferticore_ai/services/ble_service.dart';
import 'package:ferticore_ai/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

class StatistikCardWidget extends StatefulWidget {
  final DeviceStatus? status;
  final BleService ble;

  const StatistikCardWidget({
    super.key,
    required this.status,
    required this.ble,
  });

  @override
  State<StatistikCardWidget> createState() => _StatistikCardWidgetState();
}

class _StatistikCardWidgetState extends State<StatistikCardWidget> {
  void _showResetStatsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLG),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingXL),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingLG),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.warning_rounded,
                  color: AppTheme.warningColor,
                  size: 32,
                ),
              ),
              const SizedBox(height: AppTheme.spacingLG),
              Text(
                'Reset Statistik',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTheme.spacingMD),
              Text(
                'Yakin ingin mereset semua statistik penggunaan? Total volume dan sesi akan kembali ke 0.',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textGrey),
              ),
              const SizedBox(height: AppTheme.spacingXL),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingLG),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.errorColor,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        widget.ble.resetStats();
                        _showFeedback(widget.ble.isConnected
                            ? 'Statistik di-reset pada alat & aplikasi'
                            : 'Statistik lokal di-reset');
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFeedback(String message, {bool isError = false}) {
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
    final totalVolume = widget.status?.totalVolume ?? 0.0;
    final rataRata = widget.status?.rataRata ?? 0.0;
    final totalSesi = widget.status?.totalSesi ?? 0;
    final isLive = widget.ble.isLive;
    final hasData = widget.status != null;

    String syncTimeText = "";
    if (widget.ble.lastSyncTime != null) {
      syncTimeText = DateFormat('dd MMM HH:mm').format(widget.ble.lastSyncTime!);
    }

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
          // Heading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppTheme.spacingMD),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.accentGreen, Color(0xFF16A34A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingLG),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Statistik Penggunaan',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        isLive 
                            ? 'Sinkronisasi Live' 
                            : (hasData ? 'Tersimpan (Sync: $syncTimeText)' : 'Belum ada rekaman data'),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isLive ? AppTheme.successColor : AppTheme.textGrey,
                          fontWeight: isLive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Stats Grid
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  context,
                  'Total Volume',
                  '${totalVolume.toStringAsFixed(1)} g',
                  Icons.balance,
                ),
                Container(width: 1, height: 60, color: AppTheme.borderColor),
                _buildStatItem(
                  context,
                  'Rata-rata',
                  '${rataRata.toStringAsFixed(1)} g',
                  Icons.trending_up,
                ),
                Container(width: 1, height: 60, color: AppTheme.borderColor),
                _buildStatItem(
                  context,
                  'Total Sesi',
                  '$totalSesi',
                  Icons.repeat,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Reset Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showResetStatsDialog,
              icon: const Icon(Icons.restart_alt_rounded, color: AppTheme.errorColor, size: 18),
              label: const Text('Reset Statistik', style: TextStyle(color: AppTheme.errorColor)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.errorColor.withValues(alpha: 0.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primaryBlue, size: 22),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: AppTheme.spacingSM),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
