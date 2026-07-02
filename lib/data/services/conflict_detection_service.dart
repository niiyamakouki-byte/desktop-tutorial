/// Conflict Detection Service
/// 職人のダブルブッキング検出サービス
///
/// フェーズ変更時に同一の職人が同日に複数現場に割り当てられる
/// 衝突（コンフリクト）を検出し、警告を生成する。

import '../models/models.dart';

/// 検出されたコンフリクト（衝突）
class WorkerConflict {
  /// 衝突が発生した日付
  final DateTime conflictDate;

  /// 衝突している職人/業者名
  final String workerName;

  /// 衝突しているタスクリスト
  final List<ConflictingTask> conflictingTasks;

  /// コンフリクトの深刻度
  final ConflictSeverity severity;

  const WorkerConflict({
    required this.conflictDate,
    required this.workerName,
    required this.conflictingTasks,
    required this.severity,
  });

  /// 影響を受けるプロジェクト数
  int get affectedProjectCount {
    return conflictingTasks.map((t) => t.projectId).toSet().length;
  }

  /// 警告メッセージを生成
  String get warningMessage {
    final projectNames = conflictingTasks.map((t) => t.projectName).toSet();
    final dateStr = '${conflictDate.month}/${conflictDate.day}';

    if (projectNames.length > 1) {
      return '⚠️ $dateStr: $workerNameさんが${projectNames.join("と")}で重複しています';
    } else {
      return '⚠️ $dateStr: $workerNameさんが同日に${conflictingTasks.length}件のタスクに割り当てられています';
    }
  }
}

/// 衝突しているタスク情報
class ConflictingTask {
  final String taskId;
  final String taskName;
  final String projectId;
  final String projectName;
  final String? phaseName;
  final DateTime startDate;
  final DateTime endDate;

  const ConflictingTask({
    required this.taskId,
    required this.taskName,
    required this.projectId,
    required this.projectName,
    this.phaseName,
    required this.startDate,
    required this.endDate,
  });
}

/// コンフリクトの深刻度
enum ConflictSeverity {
  /// 低：同一プロジェクト内での重複（許容される場合あり）
  low,
  /// 中：異なるプロジェクト間での重複
  medium,
  /// 高：3件以上の重複、または移動不可能な距離
  high,
  /// 致命的：物理的に不可能なスケジュール
  critical,
}

/// コンフリクト検出結果
class ConflictDetectionResult {
  /// 検出されたコンフリクト
  final List<WorkerConflict> conflicts;

  /// 検出に使用したタスク数
  final int analyzedTaskCount;

  /// 検出に使用したプロジェクト数
  final int analyzedProjectCount;

  /// 検出日時
  final DateTime detectedAt;

  const ConflictDetectionResult({
    required this.conflicts,
    required this.analyzedTaskCount,
    required this.analyzedProjectCount,
    required this.detectedAt,
  });

  /// コンフリクトがあるか
  bool get hasConflicts => conflicts.isNotEmpty;

  /// クリティカルなコンフリクトがあるか
  bool get hasCriticalConflicts =>
      conflicts.any((c) => c.severity == ConflictSeverity.critical);

  /// 高以上の深刻度のコンフリクト数
  int get highSeverityCount => conflicts
      .where((c) => c.severity == ConflictSeverity.high ||
                    c.severity == ConflictSeverity.critical)
      .length;

  /// サマリメッセージを生成
  String get summaryMessage {
    if (!hasConflicts) {
      return '✅ 職人の重複はありません';
    }

    final criticalCount = conflicts
        .where((c) => c.severity == ConflictSeverity.critical)
        .length;
    final highCount = conflicts
        .where((c) => c.severity == ConflictSeverity.high)
        .length;

    if (criticalCount > 0) {
      return '🚨 $criticalCount件の致命的な重複があります！';
    } else if (highCount > 0) {
      return '⚠️ $highCount件の重大な重複があります';
    } else {
      return '⚠️ ${conflicts.length}件の職人重複を検出';
    }
  }
}

/// コンフリクト検出サービス
class ConflictDetectionService {
  /// 複数プロジェクトにまたがるコンフリクトを検出
  static ConflictDetectionResult detectConflicts({
    required List<Project> projects,
    required Map<String, List<Task>> tasksByProject,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final now = DateTime.now();
    fromDate ??= now;
    toDate ??= now.add(const Duration(days: 90)); // デフォルト3ヶ月先まで

    // 職人/業者ごとにタスクをグループ化
    final tasksByWorker = <String, List<_WorkerTaskInfo>>{};

    for (final project in projects) {
      final tasks = tasksByProject[project.id] ?? [];

      for (final task in tasks) {
        if (task.status == 'completed') continue;

        // タスクが期間外なら除外
        if (task.endDate.isBefore(fromDate) || task.startDate.isAfter(toDate)) {
          continue;
        }

        // 担当者を取得（contractorNameまたはassignees）
        final workers = <String>[];
        if (task.contractorName != null && task.contractorName!.isNotEmpty) {
          workers.add(task.contractorName!);
        }
        for (final assignee in task.assignees) {
          workers.add(assignee.name);
        }

        for (final worker in workers) {
          tasksByWorker.putIfAbsent(worker, () => []);
          tasksByWorker[worker]!.add(_WorkerTaskInfo(
            task: task,
            projectId: project.id,
            projectName: project.name,
          ));
        }
      }
    }

    // 各職人のコンフリクトを検出
    final conflicts = <WorkerConflict>[];

    for (final entry in tasksByWorker.entries) {
      final workerName = entry.key;
      final workerTasks = entry.value;

      if (workerTasks.length < 2) continue;

      // 日付ごとにタスクをグループ化
      final tasksByDate = <DateTime, List<_WorkerTaskInfo>>{};

      for (final taskInfo in workerTasks) {
        final task = taskInfo.task;
        var current = task.startDate;

        while (!current.isAfter(task.endDate)) {
          if (!current.isBefore(fromDate) && !current.isAfter(toDate)) {
            final dateKey = DateTime(current.year, current.month, current.day);
            tasksByDate.putIfAbsent(dateKey, () => []);
            tasksByDate[dateKey]!.add(taskInfo);
          }
          current = current.add(const Duration(days: 1));
        }
      }

      // 同日に複数タスクがある日をコンフリクトとして検出
      for (final dateEntry in tasksByDate.entries) {
        final date = dateEntry.key;
        final tasksOnDate = dateEntry.value;

        if (tasksOnDate.length < 2) continue;

        // ユニークなタスクIDでフィルタ（同じタスクの重複カウントを防ぐ）
        final uniqueTasks = <String, _WorkerTaskInfo>{};
        for (final t in tasksOnDate) {
          uniqueTasks[t.task.id] = t;
        }

        if (uniqueTasks.length < 2) continue;

        // 深刻度を判定
        final projectIds = uniqueTasks.values.map((t) => t.projectId).toSet();
        ConflictSeverity severity;

        if (projectIds.length > 1) {
          // 異なるプロジェクト間
          if (uniqueTasks.length >= 3) {
            severity = ConflictSeverity.critical;
          } else {
            severity = ConflictSeverity.high;
          }
        } else {
          // 同一プロジェクト内
          if (uniqueTasks.length >= 3) {
            severity = ConflictSeverity.medium;
          } else {
            severity = ConflictSeverity.low;
          }
        }

        conflicts.add(WorkerConflict(
          conflictDate: date,
          workerName: workerName,
          conflictingTasks: uniqueTasks.values.map((info) => ConflictingTask(
            taskId: info.task.id,
            taskName: info.task.name,
            projectId: info.projectId,
            projectName: info.projectName,
            startDate: info.task.startDate,
            endDate: info.task.endDate,
          )).toList(),
          severity: severity,
        ));
      }
    }

    // 日付でソート
    conflicts.sort((a, b) => a.conflictDate.compareTo(b.conflictDate));

    return ConflictDetectionResult(
      conflicts: conflicts,
      analyzedTaskCount: tasksByProject.values.fold(0, (sum, tasks) => sum + tasks.length),
      analyzedProjectCount: projects.length,
      detectedAt: DateTime.now(),
    );
  }

  /// 単一プロジェクト内でのコンフリクトを検出
  static ConflictDetectionResult detectProjectConflicts({
    required Project project,
    required List<Task> tasks,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return detectConflicts(
      projects: [project],
      tasksByProject: {project.id: tasks},
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  /// 日程変更によって発生する新しいコンフリクトをプレビュー
  static ConflictDetectionResult previewConflictsAfterChange({
    required List<Project> projects,
    required Map<String, List<Task>> currentTasksByProject,
    required String targetProjectId,
    required List<Task> updatedTasks,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    // 変更後のタスクマップを作成
    final updatedTasksByProject = Map<String, List<Task>>.from(currentTasksByProject);
    updatedTasksByProject[targetProjectId] = updatedTasks;

    return detectConflicts(
      projects: projects,
      tasksByProject: updatedTasksByProject,
      fromDate: fromDate,
      toDate: toDate,
    );
  }

  /// 日程変更前後でコンフリクトの差分を取得
  static ConflictDiff compareConflicts({
    required ConflictDetectionResult before,
    required ConflictDetectionResult after,
  }) {
    final beforeKeys = before.conflicts
        .map((c) => '${c.workerName}_${c.conflictDate.toIso8601String()}')
        .toSet();
    final afterKeys = after.conflicts
        .map((c) => '${c.workerName}_${c.conflictDate.toIso8601String()}')
        .toSet();

    final newConflictKeys = afterKeys.difference(beforeKeys);
    final resolvedConflictKeys = beforeKeys.difference(afterKeys);

    return ConflictDiff(
      newConflicts: after.conflicts
          .where((c) => newConflictKeys.contains(
              '${c.workerName}_${c.conflictDate.toIso8601String()}'))
          .toList(),
      resolvedConflicts: before.conflicts
          .where((c) => resolvedConflictKeys.contains(
              '${c.workerName}_${c.conflictDate.toIso8601String()}'))
          .toList(),
      unchangedConflicts: after.conflicts
          .where((c) => !newConflictKeys.contains(
              '${c.workerName}_${c.conflictDate.toIso8601String()}'))
          .toList(),
    );
  }
}

/// 内部用：職人のタスク情報
class _WorkerTaskInfo {
  final Task task;
  final String projectId;
  final String projectName;

  _WorkerTaskInfo({
    required this.task,
    required this.projectId,
    required this.projectName,
  });
}

/// コンフリクト差分
class ConflictDiff {
  /// 新たに発生したコンフリクト
  final List<WorkerConflict> newConflicts;

  /// 解消されたコンフリクト
  final List<WorkerConflict> resolvedConflicts;

  /// 変化なしのコンフリクト
  final List<WorkerConflict> unchangedConflicts;

  const ConflictDiff({
    required this.newConflicts,
    required this.resolvedConflicts,
    required this.unchangedConflicts,
  });

  /// 新しいコンフリクトがあるか
  bool get hasNewConflicts => newConflicts.isNotEmpty;

  /// 改善されたか（コンフリクトが減った）
  bool get improved => resolvedConflicts.length > newConflicts.length;

  /// 悪化したか（コンフリクトが増えた）
  bool get worsened => newConflicts.length > resolvedConflicts.length;

  /// 差分サマリメッセージ
  String get summaryMessage {
    if (newConflicts.isEmpty && resolvedConflicts.isEmpty) {
      return 'コンフリクト状況に変化なし';
    }

    final parts = <String>[];
    if (newConflicts.isNotEmpty) {
      parts.add('⚠️ ${newConflicts.length}件の新しい重複');
    }
    if (resolvedConflicts.isNotEmpty) {
      parts.add('✅ ${resolvedConflicts.length}件の重複が解消');
    }
    return parts.join('、');
  }
}
