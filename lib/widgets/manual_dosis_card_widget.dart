import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ferticore_ai/services/ble_service.dart';
import 'package:ferticore_ai/services/history_service.dart';
import 'package:ferticore_ai/theme/theme.dart';

class ManualDosisCardWidget extends StatefulWidget {
  const ManualDosisCardWidget({super.key});

  @override
  State<ManualDosisCardWidget> createState() => _ManualDosisCardWidgetState();
}

class _ManualDosisCardWidgetState extends State<ManualDosisCardWidget> {
  final TextEditingController _manualDosisController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _manualDosisController.dispose();
    super.dispose();
  }

  void _showFeedback(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.errorColor : AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMD),
        ),
      ),
    );
  }

  void _applyDosis() async {
    setState(() => _isLoading = true);

    final text = _manualDosisController.text;
    final dosis = double.tryParse(text);

    if (dosis == null || dosis <= 0) {
      _showFeedback('Masukkan dosis yang valid (angka positif)', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    final ble = Provider.of<BleService>(context, listen: false);
    final history = Provider.of<HistoryService>(context, listen: false);

    if (!ble.isConnected) {
      _showFeedback('Alat belum terhubung. Sambungkan di menu Device.', isError: true);
      setState(() => _isLoading = false);
      return;
    }

    ble.setDosis(dosis);

    // Save to history
    await history.addRecord(
      deviceName: ble.connectedDevice?.advName ?? 'FETCORE-01',
      deviceId: ble.connectedDevice?.remoteId.str ?? '',
      action: 'Manual',
      dosis: dosis,
      details: 'Pengaturan dosis manual ${dosis.toStringAsFixed(1)} mL',
    );

    _showFeedback('Dosis ${dosis.toStringAsFixed(1)} mL berhasil dikirim ke alat!');
    _manualDosisController.clear();

    await Future.delayed(const Duration(milliseconds: 500));
    setState(() => _isLoading = false);
  }

  void _triggerDispense() {
    final ble = Provider.of<BleService>(context, listen: false);
    if (!ble.isConnected) {
      _showFeedback('Alat belum terhubung. Sambungkan di menu Device.', isError: true);
      return;
    }
    ble.triggerMotor();
    _showFeedback('Perintah Aktifkan Pompa dikirim ke alat!');
  }

  @override
  Widget build(BuildContext context) {
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
                    colors: [AppTheme.infoColor, Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppTheme.radiusMD),
                ),
                child: const Icon(
                  Icons.touch_app_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacingLG),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pengatur Dosis Manual',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      'Terapkan dosis khusus sesuai kebutuhan',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Input field
          TextField(
            controller: _manualDosisController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enabled: !_isLoading,
            decoration: InputDecoration(
              labelText: 'Masukkan Dosis (mL)',
              hintText: 'Contoh: 15.5',
              prefixIcon: const Icon(Icons.water_drop_rounded),
              suffixText: 'mL',
              errorText:
                  _manualDosisController.text.isNotEmpty &&
                      double.tryParse(_manualDosisController.text) == null
                  ? 'Format tidak valid'
                  : null,
            ),
            onChanged: (value) => setState(() {}),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Info section
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMD),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTheme.radiusMD),
              border: Border.all(
                color: AppTheme.infoColor.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: AppTheme.infoColor, size: 18),
                const SizedBox(width: AppTheme.spacingMD),
                Expanded(
                  child: Text(
                    'Dosis (mL) akan langsung dikirim dan ditampilkan di OLED alat',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXL),

          // Apply & Trigger buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _applyDosis,
                  icon: _isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 18),
                  label: Text(_isLoading ? 'Mengirim...' : 'Terapkan Dosis'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _triggerDispense,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('Aktifkan Pompa'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentGreen,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
