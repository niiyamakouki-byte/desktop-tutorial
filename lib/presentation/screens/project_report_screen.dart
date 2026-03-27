import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/task_model.dart';
import '../../data/services/pdf_export_service.dart';
import '../../data/services/print_service.dart';
import '../../data/services/progress_report_service.dart';

class ProjectReportScreen extends StatefulWidget {
  final String projectName;
  final List<Task> tasks;

  const ProjectReportScreen({
    super.key,
    required this.projectName,
    required this.tasks,
  });

  @override
  State<ProjectReportScreen> createState() => _ProjectReportScreenState();
}

class _ProjectReportScreenState extends State<ProjectReportScreen> {
  final PDFExportService _pdfExportService = PDFExportService();
  final ProgressReportService _progressReportService = ProgressReportService();
  bool _isExporting = false;
  bool _isExportingExcel = false;

  int get _totalTasks => widget.tasks.length;

  int get _completedTasks =>
      widget.tasks.where((task) => task.status == 'completed' || task.progress >= 1).length;

  int get _inProgressTasks => widget.tasks
      .where((task) => task.status == 'in_progress' && task.progress > 0 && task.progress < 1)
      .length;

  int get _delayedTasks => widget.tasks
      .where((task) => task.status != 'completed' && DateTime.now().isAfter(task.endDate))
      .length;

  int get _nearDeadlineTasks => widget.tasks
      .where(
        (task) =>
            task.status != 'completed' &&
            task.endDate.difference(DateTime.now()).inDays >= 0 &&
            task.endDate.difference(DateTime.now()).inDays <= 3,
      )
      .length;

  double get _completionRate {
    if (_totalTasks == 0) return 0;
    return _completedTasks / _totalTasks;
  }

  Future<void> _handlePrint() async {
    final result = await const PrintService().printCurrentPage();
    if (!mounted) return;

    final message = result
        ? '印刷ダイアログを開きました'
        : 'この環境では直接印刷できないため、PDF出力を利用してください';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _handlePdfExport() async {
    setState(() => _isExporting = true);

    try {
      final result = await _pdfExportService.exportProjectSummaryPDF(
        projectName: widget.projectName,
        totalTasks: _totalTasks,
        completedTasks: _completedTasks,
        delayedTasks: _delayedTasks,
      );

      if (!mounted) return;

      final message = result.success
          ? 'PDF生成完了: ${result.filePath}'
          : 'PDF生成に失敗しました: ${result.errorMessage ?? '不明なエラー'}';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _handleExcelExport() async {
    setState(() => _isExportingExcel = true);
    try {
      final result = await _progressReportService.exportExcel(
        projectName: widget.projectName,
        tasks: widget.tasks,
      );

      if (!mounted) return;

      final message = result.success
          ? 'Excel出力完了: ${result.filePath}'
          : 'Excel出力に失敗しました: ${result.errorMessage ?? '不明なエラー'}';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) {
        setState(() => _isExportingExcel = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final delayedList = List<Task>.from(widget.tasks)
      ..sort((a, b) => b.daysOverdue.compareTo(a.daysOverdue));

    return Scaffold(
      appBar: AppBar(
        title: const Text('プロジェクト進捗レポート'),
        actions: [
          IconButton(
            onPressed: _handlePrint,
            icon: const Icon(Icons.print_outlined),
            tooltip: '印刷',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: _isExportingExcel ? null : _handleExcelExport,
                  icon: _isExportingExcel
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.table_view_outlined),
                  label: const Text('Excel出力'),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _isExporting ? null : _handlePdfExport,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('PDF出力'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.projectName,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 6),
            Text(
              '更新日時: ${DateTime.now().year}/${DateTime.now().month}/${DateTime.now().day}',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.analytics_outlined, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text('進捗サマリー', style: theme.textTheme.titleMedium),
                        const Spacer(),
                        Text(
                          '${(_completionRate * 100).toStringAsFixed(1)}%',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _completionRate,
                        minHeight: 10,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _MetricCard(
                  icon: Icons.assignment_outlined,
                  label: '総タスク数',
                  value: '$_totalTasks',
                  color: theme.colorScheme.primary,
                ),
                _MetricCard(
                  icon: Icons.check_circle_outline,
                  label: '完了',
                  value: '$_completedTasks',
                  color: AppColors.success,
                ),
                _MetricCard(
                  icon: Icons.schedule_outlined,
                  label: '進行中',
                  value: '$_inProgressTasks',
                  color: AppColors.info,
                ),
                _MetricCard(
                  icon: Icons.warning_amber_outlined,
                  label: '遅延',
                  value: '$_delayedTasks',
                  color: AppColors.error,
                ),
                _MetricCard(
                  icon: Icons.alarm_outlined,
                  label: '期限3日以内',
                  value: '$_nearDeadlineTasks',
                  color: AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('遅延状況', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 12),
                    _StatusBar(
                      label: '遅延率',
                      color: AppColors.error,
                      value: _totalTasks == 0 ? 0 : _delayedTasks / _totalTasks,
                    ),
                    const SizedBox(height: 8),
                    _StatusBar(
                      label: '完了率',
                      color: AppColors.success,
                      value: _completionRate,
                    ),
                    const SizedBox(height: 8),
                    _StatusBar(
                      label: '進行率',
                      color: AppColors.info,
                      value: _totalTasks == 0 ? 0 : _inProgressTasks / _totalTasks,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('遅延タスク一覧', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 10),
                    if (delayedList.where((task) => task.daysOverdue > 0).isEmpty)
                      Text(
                        '遅延タスクはありません',
                        style: theme.textTheme.bodyMedium,
                      )
                    else
                      ...delayedList.where((task) => task.daysOverdue > 0).take(8).map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  const Icon(Icons.circle, size: 8, color: AppColors.error),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      task.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '${task.daysOverdue}日遅延',
                                    style: const TextStyle(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160, maxWidth: 220),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w700,
                    ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final String label;
  final Color color;
  final double value;

  const _StatusBar({
    required this.label,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text('${(clamped * 100).toStringAsFixed(1)}%'),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: clamped,
            minHeight: 8,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}
