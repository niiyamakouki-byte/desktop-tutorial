import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// タスクカスケードサービス
///
/// タスク間の依存関係に基づく連動スライド
/// - 先行タスクが遅延 → 後続タスクを自動スライド
/// - 玉突き事故を防止
class TaskCascadeService extends ChangeNotifier {
  static final TaskCascadeService _instance = TaskCascadeService._internal();
  factory TaskCascadeService() => _instance;
  TaskCascadeService._internal();

  List<Task> _tasks = [];
  List<Dependency> _dependencies = [];

  /// 初期化
  void initialize({
    required List<Task> tasks,
    required List<Dependency> dependencies,
  }) {
    _tasks = List.from(tasks);
    _dependencies = List.from(dependencies);
  }

  /// タスクリストを更新
  void updateTasks(List<Task> tasks) {
    _tasks = List.from(tasks);
    notifyListeners();
  }

  /// 依存関係リストを更新
  void updateDependencies(List<Dependency> dependencies) {
    _dependencies = List.from(dependencies);
    notifyListeners();
  }

  /// タスクの日程変更をシミュレート
  ///
  /// [taskId]: 変更するタスクID
  /// [newStart]: 新しい開始日
  /// [newEnd]: 新しい終了日
  /// [enableCascade]: カスケード処理を有効にするか
  ///
  /// 戻り値: 影響を受けるタスクの変更情報
  TaskCascadeResult simulateDateChange({
    required String taskId,
    required DateTime newStart,
    required DateTime newEnd,
    bool enableCascade = true,
  }) {
    final task = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Task not found: $taskId'),
    );

    final originalStart = task.startDate;
    final originalEnd = task.endDate;
    final deltaDays = newEnd.difference(originalEnd).inDays;

    final affectedTasks = <TaskChangeInfo>[
      TaskChangeInfo(
        task: task,
        originalStart: originalStart,
        originalEnd: originalEnd,
        newStart: newStart,
        newEnd: newEnd,
        reason: TaskChangeReason.directChange,
      ),
    ];

    // カスケード処理
    if (enableCascade && deltaDays > 0) {
      _cascadeToSuccessors(
        taskId: taskId,
        newEndDate: newEnd,
        affectedTasks: affectedTasks,
        visitedIds: {taskId},
      );
    }

    return TaskCascadeResult(
      changedTasks: affectedTasks,
      totalDeltaDays: deltaDays,
      hasConflicts: _checkConflicts(affectedTasks),
    );
  }

  /// タスクの日程変更を適用
  ///
  /// [result]: シミュレート結果
  void applyDateChanges(TaskCascadeResult result) {
    for (final change in result.changedTasks) {
      final index = _tasks.indexWhere((t) => t.id == change.task.id);
      if (index >= 0) {
        _tasks[index] = change.task.copyWith(
          startDate: change.newStart,
          endDate: change.newEnd,
        );
      }
    }
    notifyListeners();
  }

  /// 後続タスクへのカスケード処理
  void _cascadeToSuccessors({
    required String taskId,
    required DateTime newEndDate,
    required List<TaskChangeInfo> affectedTasks,
    required Set<String> visitedIds,
  }) {
    // このタスクに依存している後続タスクを取得
    final successorDeps = _dependencies.where((d) => d.predecessorId == taskId);

    for (final dep in successorDeps) {
      if (visitedIds.contains(dep.successorId)) continue;
      visitedIds.add(dep.successorId);

      final successor = _tasks.firstWhere(
        (t) => t.id == dep.successorId,
        orElse: () => throw Exception('Successor not found'),
      );

      // 先行タスク終了日 + バッファ日数
      final minStartDate = newEndDate.add(Duration(days: dep.lagDays + 1));

      // 後続タスクの開始日が先行タスク終了日より前なら調整が必要
      if (successor.startDate.isBefore(minStartDate)) {
        final shiftDays = minStartDate.difference(successor.startDate).inDays;
        final newSuccessorStart = successor.startDate.add(Duration(days: shiftDays));
        final newSuccessorEnd = successor.endDate.add(Duration(days: shiftDays));

        affectedTasks.add(TaskChangeInfo(
          task: successor,
          originalStart: successor.startDate,
          originalEnd: successor.endDate,
          newStart: newSuccessorStart,
          newEnd: newSuccessorEnd,
          reason: TaskChangeReason.cascade,
          triggeredBy: taskId,
        ));

        // 再帰的に後続タスクを処理
        _cascadeToSuccessors(
          taskId: successor.id,
          newEndDate: newSuccessorEnd,
          affectedTasks: affectedTasks,
          visitedIds: visitedIds,
        );
      }
    }
  }

  /// 後続タスクを取得（直接依存のみ）
  List<Task> getDirectSuccessors(String taskId) {
    final successorIds = _dependencies
        .where((d) => d.predecessorId == taskId)
        .map((d) => d.successorId)
        .toSet();

    return _tasks.where((t) => successorIds.contains(t.id)).toList();
  }

  /// 先行タスクを取得（直接依存のみ）
  List<Task> getDirectPredecessors(String taskId) {
    final predecessorIds = _dependencies
        .where((d) => d.successorId == taskId)
        .map((d) => d.predecessorId)
        .toSet();

    return _tasks.where((t) => predecessorIds.contains(t.id)).toList();
  }

  /// 全ての後続タスクを取得（再帰的）
  List<Task> getAllSuccessors(String taskId) {
    final result = <Task>[];
    final visitedIds = <String>{taskId};

    void collectSuccessors(String id) {
      for (final successor in getDirectSuccessors(id)) {
        if (!visitedIds.contains(successor.id)) {
          visitedIds.add(successor.id);
          result.add(successor);
          collectSuccessors(successor.id);
        }
      }
    }

    collectSuccessors(taskId);
    return result;
  }

  /// 依存関係チェーン（遅延トレース用）
  List<DependencyChain> traceDependencyChain(String taskId) {
    final chains = <DependencyChain>[];
    final visited = <String>{};

    void trace(String id, List<String> path) {
      if (visited.contains(id)) return;
      visited.add(id);

      final currentPath = [...path, id];
      final predecessors = getDirectPredecessors(id);

      if (predecessors.isEmpty) {
        // チェーンの終端
        chains.add(DependencyChain(
          taskIds: currentPath.reversed.toList(),
          tasks: currentPath.reversed
              .map((tid) => _tasks.firstWhere((t) => t.id == tid))
              .toList(),
        ));
      } else {
        for (final pred in predecessors) {
          trace(pred.id, currentPath);
        }
      }
    }

    trace(taskId, []);
    return chains;
  }

  /// 衝突チェック
  bool _checkConflicts(List<TaskChangeInfo> changes) {
    // 同じリソース（担当者・業者）が同時期に複数タスクを持つかチェック
    // 簡易版では日付の重複のみチェック
    for (var i = 0; i < changes.length; i++) {
      for (var j = i + 1; j < changes.length; j++) {
        final a = changes[i];
        final b = changes[j];

        // 同じ担当者で日付が重複
        if (a.task.assigneeName != null &&
            a.task.assigneeName == b.task.assigneeName) {
          if (_datesOverlap(a.newStart, a.newEnd, b.newStart, b.newEnd)) {
            return true;
          }
        }
      }
    }
    return false;
  }

  bool _datesOverlap(DateTime s1, DateTime e1, DateTime s2, DateTime e2) {
    return !(e1.isBefore(s2) || s1.isAfter(e2));
  }

  /// クリティカルパス計算
  List<String> calculateCriticalPath() {
    if (_tasks.isEmpty) return [];

    // 全タスクの最早開始時刻・最遅開始時刻を計算
    final earliestStart = <String, DateTime>{};
    final latestStart = <String, DateTime>{};

    // トポロジカルソート順に処理
    final sorted = _topologicalSort();

    // 最早開始時刻（前進計算）
    for (final taskId in sorted) {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final predecessors = getDirectPredecessors(taskId);

      if (predecessors.isEmpty) {
        earliestStart[taskId] = task.startDate;
      } else {
        DateTime maxEnd = DateTime(1970);
        for (final pred in predecessors) {
          final predEnd = earliestStart[pred.id]!
              .add(Duration(days: pred.durationDays));
          if (predEnd.isAfter(maxEnd)) {
            maxEnd = predEnd;
          }
        }
        earliestStart[taskId] = maxEnd;
      }
    }

    // 最遅開始時刻（後退計算）
    final projectEnd = _tasks
        .map((t) => t.endDate)
        .reduce((a, b) => a.isAfter(b) ? a : b);

    for (final taskId in sorted.reversed) {
      final task = _tasks.firstWhere((t) => t.id == taskId);
      final successors = getDirectSuccessors(taskId);

      if (successors.isEmpty) {
        latestStart[taskId] = projectEnd.subtract(
          Duration(days: task.durationDays),
        );
      } else {
        DateTime minStart = DateTime(2100);
        for (final succ in successors) {
          final succLatest = latestStart[succ.id]!;
          if (succLatest.isBefore(minStart)) {
            minStart = succLatest;
          }
        }
        latestStart[taskId] = minStart.subtract(
          Duration(days: task.durationDays),
        );
      }
    }

    // クリティカルパス（フロート=0のタスク）
    final criticalPath = <String>[];
    for (final taskId in sorted) {
      final earliest = earliestStart[taskId]!;
      final latest = latestStart[taskId]!;
      final floatDays = latest.difference(earliest).inDays;

      if (floatDays <= 0) {
        criticalPath.add(taskId);
      }
    }

    return criticalPath;
  }

  /// トポロジカルソート
  List<String> _topologicalSort() {
    final inDegree = <String, int>{};
    final adjList = <String, List<String>>{};

    for (final task in _tasks) {
      inDegree[task.id] = 0;
      adjList[task.id] = [];
    }

    for (final dep in _dependencies) {
      inDegree[dep.successorId] = (inDegree[dep.successorId] ?? 0) + 1;
      adjList[dep.predecessorId]?.add(dep.successorId);
    }

    final queue = <String>[];
    final result = <String>[];

    for (final entry in inDegree.entries) {
      if (entry.value == 0) {
        queue.add(entry.key);
      }
    }

    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      result.add(current);

      for (final neighbor in adjList[current] ?? []) {
        inDegree[neighbor] = inDegree[neighbor]! - 1;
        if (inDegree[neighbor] == 0) {
          queue.add(neighbor);
        }
      }
    }

    return result;
  }
}

/// タスク変更理由
enum TaskChangeReason {
  /// 直接変更
  directChange,

  /// カスケード（連動）
  cascade,

  /// リソース競合解消
  conflictResolution,
}

/// タスク変更情報
@immutable
class TaskChangeInfo {
  final Task task;
  final DateTime originalStart;
  final DateTime originalEnd;
  final DateTime newStart;
  final DateTime newEnd;
  final TaskChangeReason reason;
  final String? triggeredBy;

  const TaskChangeInfo({
    required this.task,
    required this.originalStart,
    required this.originalEnd,
    required this.newStart,
    required this.newEnd,
    required this.reason,
    this.triggeredBy,
  });

  int get deltaDays => newEnd.difference(originalEnd).inDays;

  bool get hasChanged =>
      originalStart != newStart || originalEnd != newEnd;
}

/// カスケード処理結果
@immutable
class TaskCascadeResult {
  final List<TaskChangeInfo> changedTasks;
  final int totalDeltaDays;
  final bool hasConflicts;

  const TaskCascadeResult({
    required this.changedTasks,
    required this.totalDeltaDays,
    this.hasConflicts = false,
  });

  /// 直接変更されたタスク
  TaskChangeInfo? get directChange => changedTasks.firstWhere(
        (c) => c.reason == TaskChangeReason.directChange,
        orElse: () => changedTasks.first,
      );

  /// カスケードで変更されたタスク
  List<TaskChangeInfo> get cascadedChanges => changedTasks
      .where((c) => c.reason == TaskChangeReason.cascade)
      .toList();

  /// カスケード数
  int get cascadeCount => cascadedChanges.length;
}

/// 依存関係チェーン
@immutable
class DependencyChain {
  final List<String> taskIds;
  final List<Task> tasks;

  const DependencyChain({
    required this.taskIds,
    required this.tasks,
  });

  int get length => taskIds.length;

  /// チェーン内で遅延しているタスクを取得
  List<Task> get delayedTasks =>
      tasks.where((t) => t.delayStatus == DelayStatus.overdue).toList();

  /// チェーンの最初の遅延タスク（根本原因）
  Task? get rootCause {
    for (final task in tasks) {
      if (task.delayStatus == DelayStatus.overdue) {
        return task;
      }
    }
    return null;
  }
}
