import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/device_provider.dart';
import '../models/log_entry.dart';
import '../theme/app_theme.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});
  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  String? _filterDeviceId;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final devices = provider.devices;

    final List<LogEntry> logs = _filterDeviceId == null
        ? provider.allLogs
        : provider.logsForDevice(_filterDeviceId!);

    final Map<String, Color> deviceColors = {};
    for (int i = 0; i < devices.length; i++) {
      final hue = (i * 137.5) % 360;
      deviceColors[devices[i].id] = HSLColor.fromAHSL(
        1.0,
        hue,
        0.7,
        0.55,
      ).toColor();
    }

    int extraIdx = devices.length;
    for (final log in logs) {
      if (!deviceColors.containsKey(log.deviceId)) {
        final hue = (extraIdx * 137.5) % 360;
        deviceColors[log.deviceId] = HSLColor.fromAHSL(
          1.0,
          hue,
          0.7,
          0.55,
        ).toColor();
        extraIdx++;
      }
    }

    List<LineChartBarData> chartLines = [];

    if (_filterDeviceId != null) {
      final deviceLogs = logs
          .where(
            (l) =>
                l.event == 'telemetry' &&
                l.data != null &&
                l.data!['bat'] != null,
          )
          .take(20)
          .toList();

      final spots = <FlSpot>[];
      double x = 0;
      for (final log in deviceLogs.reversed) {
        spots.add(FlSpot(x, (log.data!['bat'] as num).toDouble()));
        x++;
      }

      if (spots.isNotEmpty) {
        chartLines.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.4,
            gradient: LinearGradient(
              colors: [context.colors.accentBlue, context.colors.primaryGreen],
            ),
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  context.colors.primaryGreen.withValues(alpha: 0.3),
                  context.colors.primaryGreen.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            dotData: const FlDotData(show: false),
          ),
        );
      }
    } else {
      final multiDeviceLogs = logs
          .where(
            (l) =>
                l.event == 'telemetry' &&
                l.data != null &&
                l.data!['bat'] != null,
          )
          .take(60)
          .toList();

      final Map<String, List<FlSpot>> deviceSpots = {};
      final Map<String, double> deviceXCounter = {};

      for (final log in multiDeviceLogs.reversed) {
        deviceSpots.putIfAbsent(log.deviceId, () => []);
        deviceXCounter.putIfAbsent(log.deviceId, () => 0);

        double currentX = deviceXCounter[log.deviceId]!;
        deviceSpots[log.deviceId]!.add(
          FlSpot(currentX, (log.data!['bat'] as num).toDouble()),
        );
        deviceXCounter[log.deviceId] = currentX + 1;
      }

      deviceSpots.forEach((deviceId, spots) {
        if (spots.isNotEmpty) {
          chartLines.add(
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: deviceColors[deviceId] ?? context.colors.primaryGreen,
              barWidth: 3,
              isStrokeCapRound: true,
              belowBarData: BarAreaData(show: false),
              dotData: const FlDotData(show: false),
            ),
          );
        }
      });
    }

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
          'Info & Riwayat Log',
          style: TextStyle(color: context.colors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + kToolbarHeight + 16,
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  Text(
                    'Filter Perangkat:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: context.colors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _filterDeviceId,
                          hint: Text(
                            'Semua',
                            style: TextStyle(color: context.colors.textPrimary),
                          ),
                          dropdownColor: context.colors.surfaceBg,
                          icon: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: context.colors.primaryGreen,
                          ),
                          isExpanded: true,
                          items: [
                            DropdownMenuItem(
                              value: null,
                              child: Text(
                                'Semua',
                                style: TextStyle(
                                  color: context.colors.textPrimary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ...devices.map(
                              (d) => DropdownMenuItem(
                                value: d.id,
                                child: Text(
                                  'Device ${(d.id.length >= 6 ? d.id.substring(0, 6) : d.id).toUpperCase()}',
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: (val) =>
                              setState(() => _filterDeviceId = val),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (chartLines.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.colors.cardBg,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: context.colors.borderStroke),
                ),
                height: 260,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.colors.primaryGreen.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.show_chart_rounded,
                            color: context.colors.primaryGreen,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Tren Baterai',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: context.colors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 25,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: context.colors.borderStroke,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text(
                                    '${value.toInt()}%',
                                    style: TextStyle(
                                      color: context.colors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  );
                                },
                              ),
                            ),
                            bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: chartLines,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.colors.surfaceBg.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.colors.borderStroke),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.cardBg,
                      ),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: context.colors.primaryGreen,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pestzone Spray v1.0',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: context.colors.textPrimary,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Broker: broker.hivemq.com',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.colors.textSecondary.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.colors.primaryGreen.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${logs.length} log',
                        style: TextStyle(
                          color: context.colors.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 16)),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Riwayat Aktivitas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.colors.textPrimary,
                    ),
                  ),
                  if (logs.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: context.colors.dangerRed,
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: context.colors.cardBg,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: Text(
                              'Hapus Riwayat',
                              style: TextStyle(
                                color: context.colors.textPrimary,
                              ),
                            ),
                            content: Text(
                              _filterDeviceId == null
                                  ? 'Apakah Anda yakin ingin menghapus SEMUA riwayat aktivitas?'
                                  : 'Apakah Anda yakin ingin menghapus riwayat aktivitas untuk perangkat ini?',
                              style: TextStyle(
                                color: context.colors.textSecondary,
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  'Batal',
                                  style: TextStyle(
                                    color: context.colors.textSecondary,
                                  ),
                                ),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: context.colors.dangerRed,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                ),
                                onPressed: () {
                                  context.read<DeviceProvider>().clearLogs(
                                    deviceId: _filterDeviceId,
                                  );

                                  Navigator.pop(ctx);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _filterDeviceId == null
                                            ? 'Semua riwayat berhasil dihapus'
                                            : 'Riwayat perangkat berhasil dihapus',
                                      ),
                                      backgroundColor: context.colors.dangerRed,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text(
                                  'Hapus',
                                  style: TextStyle(color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      tooltip: 'Hapus Riwayat',
                    ),
                ],
              ),
            ),
          ),

          logs.isEmpty
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 64,
                            color: context.colors.surfaceBg,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Belum ada log aktivitas',
                            style: TextStyle(
                              color: context.colors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : SliverPadding(
                  padding: const EdgeInsets.only(bottom: 100),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final log = logs[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 6,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: context.colors.cardBg,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: context.colors.borderStroke,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            leading: _LogIcon(event: log.event),
                            title: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        (deviceColors[log.deviceId] ??
                                                context.colors.textSecondary)
                                            .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color:
                                          (deviceColors[log.deviceId] ??
                                                  context.colors.textSecondary)
                                              .withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    log.deviceId.length >= 4
                                        ? log.deviceId
                                              .substring(0, 4)
                                              .toUpperCase()
                                        : log.deviceId.toUpperCase(),
                                    style: TextStyle(
                                      color:
                                          deviceColors[log.deviceId] ??
                                          context.colors.textSecondary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  log.event.toUpperCase(),
                                  style: TextStyle(
                                    color: context.colors.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Text(
                              DateFormat(
                                'dd MMM yyyy • HH:mm:ss',
                              ).format(log.timestamp),
                              style: TextStyle(
                                color: context.colors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            trailing: _buildLogTrailing(context, log),
                          ),
                        ),
                      );
                    }, childCount: logs.length),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildLogTrailing(BuildContext context, LogEntry log) {
    if (log.data == null) return const SizedBox();
    if (log.data!.containsKey('bat')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: context.colors.warningOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${log.data!['bat']}%',
          style: TextStyle(
            color: context.colors.warningOrange,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    if (log.data!.containsKey('duration')) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: context.colors.accentBlue.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          '${log.data!['duration']}s',
          style: TextStyle(
            color: context.colors.accentBlue,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      );
    }
    if (log.data!.containsKey('source')) {
      return Text(
        '${log.data!['source']}',
        style: TextStyle(
          color: context.colors.textSecondary,
          fontSize: 11,
          fontStyle: FontStyle.italic,
        ),
      );
    }
    return const SizedBox();
  }
}

class _LogIcon extends StatelessWidget {
  final String event;
  const _LogIcon({required this.event});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    if (event.contains('uv')) {
      icon = Icons.lightbulb_rounded;
      color = context.colors.accentPurple;
    } else if (event.contains('pump')) {
      icon = Icons.water_drop_rounded;
      color = context.colors.accentBlue;
    } else if (event.contains('schedule')) {
      icon = Icons.schedule_rounded;
      color = context.colors.warningOrange;
    } else if (event.contains('telemetry')) {
      icon = Icons.sensors_rounded;
      color = context.colors.primaryGreen;
    } else {
      icon = Icons.circle;
      color = context.colors.offlineGrey;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}
