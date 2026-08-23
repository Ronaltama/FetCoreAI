import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';
import '../theme/app_theme.dart';

class ControlScreen extends StatefulWidget {
  final String? initialDeviceId;

  const ControlScreen({super.key, this.initialDeviceId});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  String? _selectedDeviceId;

  final _uvStartController = TextEditingController(text: '18:00');
  final _uvStopController = TextEditingController(text: '23:00');
  final _pumpTimeController = TextEditingController(text: '06:00');
  final _pumpDurationController = TextEditingController(text: '15');
  final _manualPumpDurationController = TextEditingController(text: '10');

  @override
  void initState() {
    super.initState();
    _selectedDeviceId = widget.initialDeviceId;
  }

  @override
  void didUpdateWidget(ControlScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDeviceId != oldWidget.initialDeviceId) {
      setState(() {
        _selectedDeviceId = widget.initialDeviceId;
      });
    }
  }

  @override
  void dispose() {
    _uvStartController.dispose();
    _uvStopController.dispose();
    _pumpTimeController.dispose();
    _pumpDurationController.dispose();
    _manualPumpDurationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(
    BuildContext context,
    TextEditingController controller,
  ) async {
    TimeOfDay initial = TimeOfDay.now();
    if (controller.text.contains(':')) {
      final parts = controller.text.split(':');
      initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? initial.hour,
        minute: int.tryParse(parts[1]) ?? initial.minute,
      );
    }

    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (picked != null) {
      final h = picked.hour.toString().padLeft(2, '0');
      final m = picked.minute.toString().padLeft(2, '0');
      setState(() {
        controller.text = '$h:$m';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DeviceProvider>();
    final devices = provider.devices;

    if (_selectedDeviceId != null &&
        !devices.any((d) => d.id == _selectedDeviceId)) {
      _selectedDeviceId = null;
    }

    final device = _selectedDeviceId != null
        ? provider.getDevice(_selectedDeviceId!)
        : null;

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
          'Kontrol & Penjadwalan',
          style: TextStyle(color: context.colors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          20,
          MediaQuery.of(context).padding.top + kToolbarHeight + 16,
          20,
          100,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.colors.cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: context.colors.borderStroke),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.colors.primaryGreen.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.router_rounded,
                          color: context.colors.primaryGreen,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Pilih Perangkat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: context.colors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedDeviceId,
                    decoration: InputDecoration(
                      hintText: 'Pilih perangkat...',
                      hintStyle: TextStyle(color: context.colors.textSecondary),
                      prefixIcon: Icon(
                        Icons.sensors_rounded,
                        color: context.colors.textSecondary,
                      ),
                      fillColor: context.colors.surfaceBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    dropdownColor: context.colors.surfaceBg,
                    icon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: context.colors.primaryGreen,
                    ),
                    items: devices
                        .map(
                          (d) => DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              'Device ${(d.id.length >= 6 ? d.id.substring(0, 6) : d.id).toUpperCase()}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: context.colors.textPrimary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) => setState(() => _selectedDeviceId = val),
                  ),
                ],
              ),
            ),

            if (device != null) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  color: context.colors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.colors.borderStroke),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _StatusItem(
                      icon: Icons.lightbulb_rounded,
                      label: 'UV Light',
                      isOn: device.uvOn,
                      color: context.colors.accentPurple,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: context.colors.borderStroke,
                    ),
                    _StatusItem(
                      icon: Icons.water_drop_rounded,
                      label: 'Water Pump',
                      isOn: device.pumpOn,
                      color: context.colors.accentBlue,
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: context.colors.borderStroke,
                    ),
                    _StatusItem(
                      icon: Icons.battery_charging_full_rounded,
                      label: 'Baterai',
                      value: '${device.battery}%',
                      color: context.colors.warningOrange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              Text(
                'Kontrol Manual',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ControlButton(
                      icon: Icons.lightbulb_rounded,
                      label: 'UV Light',
                      isOn: device.uvOn,
                      color: context.colors.accentPurple,
                      onToggle: (val) {
                        provider.sendCommand(device.id, {
                          'uv_action': val ? 'ON' : 'OFF',
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Perintah UV Light ${val ? 'dinyalakan' : 'dimatikan'} dikirim. Akan diproses saat alat aktif.',
                            ),
                            backgroundColor: context.colors.accentPurple,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _ControlButton(
                      icon: Icons.water_drop_rounded,
                      label: 'Water Pump',
                      isOn: device.pumpOn,
                      color: context.colors.accentBlue,
                      onToggle: (val) {
                        provider.sendCommand(device.id, {
                          'pump_action': val ? 'ON' : 'OFF',
                        });

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Perintah Water Pump ${val ? 'dinyalakan' : 'dimatikan'} dikirim. Akan diproses saat alat aktif.',
                            ),
                            backgroundColor: context.colors.accentBlue,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colors.cardBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: context.colors.borderStroke),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Penyiraman Khusus',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: context.colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            'Durasi (detik)',
                            _manualPumpDurationController,
                            Icons.timer_rounded,
                            context,
                          ),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            int dur =
                                int.tryParse(
                                  _manualPumpDurationController.text,
                                ) ??
                                10;
                            provider.sendCommand(device.id, {
                              'pump_action': 'ON',
                              'duration_sec': dur,
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Perintah dikirim. Akan diproses saat alat aktif.',
                                ),
                                backgroundColor: context.colors.accentBlue,
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.colors.accentBlue,
                            padding: const EdgeInsets.all(16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Text(
                'Penjadwalan Otomatis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: context.colors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              _ScheduleCard(
                icon: Icons.wb_sunny_rounded,
                title: 'Jadwal UV Light',
                color: context.colors.accentPurple,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimeField(
                          'Jam Mulai',
                          _uvStartController,
                          Icons.wb_twilight_rounded,
                          () => _selectTime(context, _uvStartController),
                          context,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTimeField(
                          'Jam Selesai',
                          _uvStopController,
                          Icons.nights_stay_rounded,
                          () => _selectTime(context, _uvStopController),
                          context,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: const Text(
                        'Simpan Jadwal UV',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        int start =
                            int.tryParse(
                              _uvStartController.text.split(':')[0],
                            ) ??
                            18;
                        int stop =
                            int.tryParse(
                              _uvStopController.text.split(':')[0],
                            ) ??
                            23;
                        provider.sendCommand(device.id, {
                          'uv_start': start,
                          'uv_stop': stop,
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Perintah dikirim. Akan diproses saat alat aktif.',
                            ),
                            backgroundColor: context.colors.accentPurple,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.accentPurple,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _ScheduleCard(
                icon: Icons.water_rounded,
                title: 'Jadwal Penyiraman',
                color: context.colors.accentBlue,
                children: [
                  Row(
                    children: [
                      Expanded(
                        flex: 5,
                        child: _buildTimeField(
                          'Waktu Siram',
                          _pumpTimeController,
                          Icons.access_time_rounded,
                          () => _selectTime(context, _pumpTimeController),
                          context,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 4,
                        child: _buildTextField(
                          'Durasi (s)',
                          _pumpDurationController,
                          null,
                          context,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: const Text(
                        'Simpan Jadwal Pompa',
                        style: TextStyle(color: Colors.white),
                      ),
                      onPressed: () {
                        final parts = _pumpTimeController.text.split(':');
                        int h = int.tryParse(parts[0]) ?? 6;
                        int m = int.tryParse(parts[1]) ?? 0;
                        int d =
                            int.tryParse(_pumpDurationController.text) ?? 15;
                        provider.sendCommand(device.id, {
                          'pump_schedule': {
                            'hour': h,
                            'minute': m,
                            'duration_sec': d,
                          },
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Perintah dikirim. Akan diproses saat alat aktif.',
                            ),
                            backgroundColor: context.colors.accentBlue,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.accentBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ] else if (devices.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: [
                    Icon(
                      Icons.sensors_off_rounded,
                      size: 80,
                      color: context.colors.surfaceBg,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Belum ada perangkat terhubung',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: context.colors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData? icon,
    BuildContext context,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: context.colors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.colors.textSecondary),
        prefixIcon: icon != null
            ? Icon(icon, size: 20, color: context.colors.textSecondary)
            : null,
        fillColor: context.colors.surfaceBg,
      ),
    );
  }

  Widget _buildTimeField(
    String label,
    TextEditingController controller,
    IconData icon,
    VoidCallback onTap,
    BuildContext context,
  ) {
    return TextField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: context.colors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.colors.textSecondary),
        prefixIcon: Icon(icon, size: 20, color: context.colors.textSecondary),
        fillColor: context.colors.surfaceBg,
      ),
    );
  }
}

class _StatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool? isOn;
  final String? value;
  final Color color;

  const _StatusItem({
    required this.icon,
    required this.label,
    this.isOn,
    this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: isOn != null
              ? (isOn! ? color : context.colors.offlineGrey)
              : color,
          size: 28,
        ),
        const SizedBox(height: 8),
        Text(
          value ?? (isOn != null ? (isOn! ? 'ON' : 'OFF') : ''),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isOn == true ? color : context.colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isOn;
  final ValueChanged<bool> onToggle;
  final Color color;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.isOn,
    required this.onToggle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!isOn),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutExpo,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: isOn ? color.withValues(alpha: 0.15) : context.colors.cardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isOn ? color : context.colors.borderStroke,
            width: 2,
          ),
          boxShadow: isOn
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isOn ? color : context.colors.surfaceBg,
                shape: BoxShape.circle,
                boxShadow: isOn
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
                          blurRadius: 12,
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                size: 36,
                color: isOn ? Colors.white : context.colors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: context.colors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isOn
                    ? color.withValues(alpha: 0.2)
                    : context.colors.surfaceBg,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isOn ? 'ACTIVE' : 'INACTIVE',
                style: TextStyle(
                  color: isOn ? color : context.colors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _ScheduleCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.colors.cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: context.colors.borderStroke),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: context.colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }
}
