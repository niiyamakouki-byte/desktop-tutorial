import 'package:construction_project_manager/data/models/task_model.dart';
import 'package:construction_project_manager/data/services/progress_report_service.dart';
import 'package:flutter_test/flutter_test.dart';

Task _buildTask({
  required String id,
  required String status,
  required double progress,
  required DateTime start,
  required DateTime end,
}) {
  final now = DateTime(2026, 1, 1);
  return Task(
    id: id,
    projectId: 'proj_test',
    name: id,
    startDate: start,
    endDate: end,
    progress: progress,
    status: status,
    category: 'general',
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  group('ProgressReportService', () {
    final service = ProgressReportService();

    test('buildSummary returns correct counts', () {
      final tasks = [
        _buildTask(
          id: 't1',
          status: 'completed',
          progress: 1.0,
          start: DateTime(2025, 12, 1),
          end: DateTime(2025, 12, 5),
        ),
        _buildTask(
          id: 't2',
          status: 'in_progress',
          progress: 0.5,
          start: DateTime(2025, 12, 6),
          end: DateTime(2026, 12, 30),
        ),
      ];

      final summary = service.buildSummary(tasks);
      expect(summary.totalTasks, 2);
      expect(summary.completedTasks, 1);
      expect(summary.inProgressTasks, 1);
      expect(summary.averageProgress, closeTo(0.75, 0.001));
    });

    test('buildExcelCompatibleCsv contains key rows', () {
      final tasks = [
        _buildTask(
          id: 't1',
          status: 'completed',
          progress: 1.0,
          start: DateTime(2025, 12, 1),
          end: DateTime(2025, 12, 5),
        ),
      ];

      final csv = service.buildExcelCompatibleCsv(
        projectName: 'テストPJ',
        tasks: tasks,
      );

      expect(csv, contains('進捗レポート'));
      expect(csv, contains('テストPJ'));
      expect(csv, contains('タスク一覧'));
      expect(csv, contains('t1'));
    });

    test('exportExcel returns success for non-empty tasks', () async {
      final tasks = [
        _buildTask(
          id: 't1',
          status: 'completed',
          progress: 1.0,
          start: DateTime(2025, 12, 1),
          end: DateTime(2025, 12, 5),
        ),
      ];

      final result = await service.exportExcel(
        projectName: 'テストPJ',
        tasks: tasks,
      );

      expect(result.success, isTrue);
      expect(result.filePath, contains('/downloads/progress_'));
      expect(result.filePath, endsWith('.csv'));
    });
  });
}
