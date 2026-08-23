import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'reset_wifi_screen.dart';

class InfoScreen extends StatelessWidget {
  const InfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final devices = provider.devices;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: context.colors.bg.withValues(alpha: 0.5)),
          ),
        ),
        title: Text(
          'Pengaturan & Info',
          style: TextStyle(color: context.colors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + kToolbarHeight + 20,
          20,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle('Info Aplikasi', context),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.colors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.colors.borderStroke),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: context.colors.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.pest_control_rounded,
                      size: 48,
                      color: context.colors.primaryGreen,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Pestzone Spray',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Versi 1.0.0',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aplikasi pintar untuk mengontrol dan memonitor perangkat penyiram tanaman otomatis dan perangkap hama berbasis IoT (ESP32) melalui jaringan MQTT.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Tampilan', context),
            Container(
              decoration: BoxDecoration(
                color: context.colors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.colors.borderStroke),
              ),
              child: SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                title: Text(
                  'Mode Gelap',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: context.colors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  'Gunakan tema warna gelap',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.colors.textSecondary,
                  ),
                ),
                secondary: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.colors.accentPurple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    themeProvider.isDarkMode
                        ? Icons.dark_mode_rounded
                        : Icons.light_mode_rounded,
                    color: context.colors.accentPurple,
                  ),
                ),
                activeThumbColor: context.colors.primaryGreen,
                value: themeProvider.isDarkMode,
                onChanged: (bool value) {
                  themeProvider.toggleTheme();

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? 'Mode gelap diaktifkan'
                            : 'Mode terang diaktifkan',
                        style: TextStyle(color: context.colors.textPrimary),
                      ),
                      backgroundColor: context.colors.cardBg,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            _buildSectionTitle('Pengaturan Koneksi', context),
            Container(
              decoration: BoxDecoration(
                color: context.colors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.colors.borderStroke),
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ResetWifiScreen(),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.colors.dangerRed.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.wifi_protected_setup_rounded,
                            color: context.colors.dangerRed,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Reset WiFi Perangkat',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: context.colors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Hapus pengaturan WiFi yang tersimpan pada ESP32',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.colors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionTitle(
                  'Manajemen Perangkat',
                  context,
                  paddingBottom: 0,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${devices.length}',
                    style: TextStyle(
                      color: context.colors.primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (devices.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: context.colors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.colors.borderStroke),
                ),
                child: Center(
                  child: Text(
                    'Tidak ada perangkat tersimpan.',
                    style: TextStyle(color: context.colors.textSecondary),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: devices.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final device = devices[index];
                  final shortId = device.id.length >= 6
                      ? device.id.substring(0, 6).toUpperCase()
                      : device.id.toUpperCase();

                  return Container(
                    decoration: BoxDecoration(
                      color: context.colors.cardBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: context.colors.borderStroke),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.router_rounded,
                          color: context.colors.primaryGreen,
                        ),
                      ),
                      title: Text(
                        'Device $shortId',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: context.colors.textPrimary,
                        ),
                      ),
                      subtitle: Text(
                        'ID: ${device.id}',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.colors.textSecondary,
                        ),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: context.colors.dangerRed,
                        onPressed: () =>
                            _confirmDelete(context, device.id, shortId),
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    BuildContext context, {
    double paddingBottom = 16,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: paddingBottom),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: context.colors.textPrimary,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    String fullId,
    String shortId,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Hapus Perangkat',
          style: TextStyle(color: context.colors.textPrimary),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus Device $shortId dari aplikasi? Semua log terkait juga akan dihapus.',
          style: TextStyle(color: context.colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Batal',
              style: TextStyle(color: context.colors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: context.colors.dangerRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<DeviceProvider>().deleteDevice(fullId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Device $shortId berhasil dihapus.'),
          backgroundColor: context.colors.primaryGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }
}
