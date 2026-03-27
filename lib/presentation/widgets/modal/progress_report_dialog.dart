import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/models.dart';
import '../../../data/services/progress_report_service.dart';

class ProgressReportDialog extends StatefulWidget {
  final String projectName;
  final List<Task> tasks;

  const ProgressReportDialog({
    super.key,
    required this.projectName,
    required this.tasks,
  });

  static Future<void> show({
    required BuildContext context,
    required String projectName,
    required List<Task> tasks,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => ProgressReportDialog(
        projectName: projectName,
        tasks: tasks,
      ),
    );
  }

  @override
  State<ProgressReportDialog> createState() => _ProgressReportDialogState();
}

class _ProgressReportDialogState extends State<ProgressReportDialog> {
  late final ProgressReportService _service;
  bool _exportingPdf = false;
  bool _exportingExcel = false;

  @override
  void initState() {
    super.initState();
    _service = ProgressReportService();
  }

  Future<void> _exportPdf() async {
    setState(() => _exportingPdf = true);
    final result = await _service.exportPdf(
      projectName: widget.projectName,
      tasks: widget.tasks,
    );
    if (!mounted) return;
    setState(() => _exportingPdf = false);
    _showResult(result);
  }

  Future<void> _exportExcel() async {
    setState(() => _exportingExcel = true);
    final result = await _service.exportExcel(
      projectName: widget.projectName,
      tasks: widget.tasks,
    );
    if (!mounted) return;
    setState(() => _exportingExcel = false);
    _showResult(result);
  }

  void _showResult(ProgressReportExportResult result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? '出力完了: ${result.filePath}'
              : (result.errorMessage ?? '出力に失敗しました'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summary = _service.buildSummary(widget.tasks);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        width: 520,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.summarize_outlined, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    '進捗レポート出力',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Text(
                widget.projectName,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              _SummaryRow(label: '総タスク数', value: '${summary.totalTasks}'),
              _SummaryRow(label: '完了', value: '${summary.completedTasks}'),
              _SummaryRow(label: '進行中', value: '${summary.inProgressTasks}'),
              _SummaryRow(label: '遅延', value: '${summary.delayedTasks}'),
              _SummaryRow(
                label: '平均進捗',
                value: '${(summary.averageProgress * 100).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _exportingExcel ? null : _exportExcel,
                      icon: _exportingExcel
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.table_view_outlined),
                      label: const Text('Excel出力'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _exportingPdf ? null : _exportPdf,
                      icon: _exportingPdf
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.picture_as_pdf_outlined),
                      label: const Text('PDF出力'),
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
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
