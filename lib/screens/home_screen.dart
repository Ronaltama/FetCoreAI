import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ferticore_ai/services/ble_service.dart';
import 'package:ferticore_ai/theme/theme.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:ferticore_ai/widgets/dosis_card_widget.dart';
import 'package:ferticore_ai/widgets/statistik_card_widget.dart';
import 'package:ferticore_ai/screens/device_page.dart';
import 'package:ferticore_ai/screens/aksi_page.dart';
import 'package:ferticore_ai/screens/riwayat_page.dart';
import 'package:ferticore_ai/screens/info_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ble = Provider.of<BleService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'FERTICORE AI',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(
              'Sistem Tabur Presisi (BLE)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: AppTheme.surfaceLight,
        foregroundColor: AppTheme.textDark,
        actions: [_buildConnectionStatus(ble)],
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(), // Hindari swipe agar tidak konflik dengan tab di dalam aksi_page
        children: [
          // Tab 1: Dashboard
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Column(
              children: [
                DosisCardWidget(ble: ble),
                const SizedBox(height: AppTheme.spacingXL),
                StatistikCardWidget(status: ble.activeDeviceStatus, ble: ble),
              ],
            ),
          ),
          // Tab 2: Device
          const DevicePage(),
          // Tab 3: Aksi
          const AksiPage(),
          // Tab 4: Riwayat
          const RiwayatPage(),
          // Tab 5: Setting (Info)
          const InfoPage(),
        ],
      ),
      // Modern Bottom Navigation Bar
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          boxShadow: AppTheme.shadowMD,
        ),
        child: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.primaryBlue,
          labelColor: AppTheme.primaryBlue,
          unselectedLabelColor: AppTheme.textGrey,
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, fontSize: 10),
          unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 10),
          labelPadding: EdgeInsets.zero,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_rounded), text: 'Dashboard'),
            Tab(icon: Icon(Icons.bluetooth), text: 'Device'),
            Tab(icon: Icon(Icons.touch_app), text: 'Aksi'),
            Tab(icon: Icon(Icons.history), text: 'Riwayat'),
            Tab(icon: Icon(Icons.settings), text: 'Setting'),
          ],
        ),
      ),
    );
  }

  // Connection status indicator
  Widget _buildConnectionStatus(BleService ble) {
    String statusText;
    Color color;
    IconData icon;

    if (!ble.isBluetoothOn) {
      statusText = 'BT Off';
      color = AppTheme.errorColor;
      icon = Icons.bluetooth_disabled;
    } else if (ble.isConnected) {
      statusText = 'Online';
      color = AppTheme.successColor;
      icon = Icons.bluetooth_connected;
    } else if (ble.isConnecting) {
      statusText = 'Menyambung...';
      color = AppTheme.primaryBlue;
      icon = Icons.sync;
    } else if (ble.isScanning) {
      statusText = 'Scanning...';
      color = AppTheme.warningColor;
      icon = Icons.search;
    } else if (ble.savedDeviceId != null) {
      statusText = 'Offline';
      color = AppTheme.warningColor;
      icon = Icons.cloud_off;
    } else {
      statusText = 'Terputus';
      color = AppTheme.textGrey;
      icon = Icons.bluetooth;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMD,
              vertical: AppTheme.spacingSM,
            ),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppTheme.spacingSM),
                Text(
                  statusText,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
