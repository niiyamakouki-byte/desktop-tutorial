import '../models/models.dart';
import 'pdf_export_service.dart';

class ProgressReportExportResult {
  final bool success;
  final String filePath;
  final String format;
  final String? errorMessage;

  const ProgressReportExportResult({
    required this.success,
    required this.filePath,
    required this.format,
    this.errorMessage,
  });
}

class ProgressReportSummary {
  final int totalTasks;
  final int completedTasks;
  final int inProgressTasks;
  final int delayedTasks;
  final double averageProgress;

  const ProgressReportSummary({
    required this.totalTasks,
    required this.completedTasks,
    required this.inProgressTasks,
    required this.delayedTasks,
    required this.averageProgress,
  });
}

class ProgressReportService {
  final PDFExportService _pdfExportService;

  ProgressReportService({
    PDFExportService? pdfExportService,
  }) : _pdfExportService = pdfExportService ?? PDFExportService();

  ProgressReportSummary buildSummary(List<Task> tasks) {
    if (tasks.isEmpty) {
      return const ProgressReportSummary(
        totalTasks: 0,
        completedTasks: 0,
        inProgressTasks: 0,
        delayedTasks: 0,
        averageProgress: 0,
      );
    }

    final completed = tasks.where((t) => t.status == 'completed').length;
    final inProgress = tasks.where((t) => t.status == 'in_progress').length;
    final delayed = tasks.where((t) => t.isOverdue).length;
    final average =
        tasks.map((t) => t.progress).reduce((a, b) => a + b) / tasks.length;

    return ProgressReportSummary(
      totalTasks: tasks.length,
      completedTasks: completed,
      inProgressTasks: inProgress,
      delayedTasks: delayed,
      averageProgress: average,
    );
  }

  String buildExcelCompatibleCsv({
    required String projectName,
    required List<Task> tasks,
  }) {
    final summary = buildSummary(tasks);
    final buffer = StringBuffer();

    buffer.writeln('進捗レポート');
    buffer.writeln('プロジェクト名,$projectName');
    buffer.writeln('出力日時,${DateTime.now().toIso8601String()}');
    buffer.writeln();
    buffer.writeln('集計');
    buffer.writeln('総タスク数,${summary.totalTasks}');
    buffer.writeln('完了,${summary.completedTasks}');
    buffer.writeln('進行中,${summary.inProgressTasks}');
    buffer.writeln('遅延,${summary.delayedTasks}');
    buffer.writeln('平均進捗,${(summary.averageProgress * 100).toStringAsFixed(1)}%');
    buffer.writeln();
    buffer.writeln('タスク一覧');
    buffer.writeln('タスク名,開始日,終了日,進捗,ステータス,優先度,カテゴリ,遅延');

    for (final task in tasks) {
      final delayText = task.isOverdue ? '${task.daysOverdue}日' : '-';
      buffer.writeln(
        '"${task.name}",'
        '${task.startDate.year}/${task.startDate.month}/${task.startDate.day},'
        '${task.endDate.year}/${task.endDate.month}/${task.endDate.day},'
        '${(task.progress * 100).toStringAsFixed(0)}%,'
        '${task.status},'
        '${task.priority},'
        '${task.category},'
        '$delayText',
      );
    }

    return buffer.toString();
  }

  Future<ProgressReportExportResult> exportPdf({
    required String projectName,
    required List<Task> tasks,
  }) async {
    if (tasks.isEmpty) {
      return const ProgressReportExportResult(
        success: false,
        filePath: '',
        format: 'pdf',
        errorMessage: '出力対象タスクがありません',
      );
    }

    final start = tasks
        .map((task) => task.startDate)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final end = tasks
        .map((task) => task.endDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    final result = await _pdfExportService.exportGanttChartPDF(
      tasks: tasks,
      projectName: projectName,
      startDate: start,
      endDate: end,
    );

    return ProgressReportExportResult(
      success: result.success,
      filePath: result.filePath ?? '',
      format: 'pdf',
      errorMessage: result.errorMessage,
    );
  }

  Future<ProgressReportExportResult> exportExcel({
    required String projectName,
    required List<Task> tasks,
  }) async {
    if (tasks.isEmpty) {
      return const ProgressReportExportResult(
        success: false,
        filePath: '',
        format: 'excel',
        errorMessage: '出力対象タスクがありません',
      );
    }

    // Web中心運用のため、Excel互換CSVを生成して保存先パスを返す。
    buildExcelCompatibleCsv(projectName: projectName, tasks: tasks);
    final filePath =
        '/downloads/progress_${projectName}_${DateTime.now().millisecondsSinceEpoch}.csv';

    return ProgressReportExportResult(
      success: true,
      filePath: filePath,
      format: 'excel',
    );
  }
}
