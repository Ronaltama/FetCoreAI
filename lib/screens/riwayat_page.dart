import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ferticore_ai/services/history_service.dart';
import 'package:ferticore_ai/theme/theme.dart';
import 'package:intl/intl.dart';

class RiwayatPage extends StatelessWidget {
  const RiwayatPage({super.key});

  @override
  Widget build(BuildContext context) {
    final history = Provider.of<HistoryService>(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingLG),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Riwayat Pemupukan',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (history.records.isNotEmpty)
                  TextButton.icon(
                    onPressed: () => _showClearDialog(context, history),
                    icon: const Icon(Icons.delete_outline, color: AppTheme.errorColor),
                    label: const Text('Hapus', style: TextStyle(color: AppTheme.errorColor)),
                  ),
              ],
            ),
          ),
          Expanded(
            child: history.records.isEmpty
                ? const Center(child: Text('Belum ada riwayat.'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingLG),
                    itemCount: history.records.length,
                    itemBuilder: (context, index) {
                      final record = history.records[index];
                      return _buildRecordCard(context, record);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showClearDialog(BuildContext context, HistoryService history) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Riwayat?'),
        content: const Text('Semua data riwayat pemupukan akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          TextButton(
            onPressed: () {
              history.clearHistory();
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecordCard(BuildContext context, HistoryRecord record) {
    final formattedDate = DateFormat('dd MMM yyyy, HH:mm').format(record.timestamp);

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMD),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingMD),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textGrey),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: record.action == 'Rekomendasi'
                        ? AppTheme.successColor.withValues(alpha: 0.1)
                        : AppTheme.infoColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.action,
                    style: TextStyle(
                      fontSize: 12,
                      color: record.action == 'Rekomendasi' ? AppTheme.successColor : AppTheme.infoColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Text(
              '${record.dosis} gram',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryBlue,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSM),
            Row(
              children: [
                const Icon(Icons.router, size: 16, color: AppTheme.textGrey),
                const SizedBox(width: 4),
                Text(record.deviceName, style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            if (record.details.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                record.details,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
