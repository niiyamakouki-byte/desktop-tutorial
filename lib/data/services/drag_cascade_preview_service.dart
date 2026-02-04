/// Drag Cascade Preview Service
/// ドラッグ中のカスケードプレビュー計算サービス
///
/// タスクをドラッグ中に依存関係のある後続タスクの
/// リアルタイムプレビュー位置を計算する

import 'package:flutter/foundation.dart';
import '../models/task_model.dart';
import '../models/dependency_model.dart';

/// ドラッグ中のタスク位置情報
@immutable
class DragTaskPreview {
  final String taskId;
  final DateTime originalStart;
  final DateTime originalEnd;
  final DateTime previewStart;
  final DateTime previewEnd;
  final bool isDragged; // ドラッグ対象タスクか
  final bool isCascaded; // カスケードで影響を受けるか

  const DragTaskPreview({
    required this.taskId,
    required this.originalStart,
    required this.originalEnd,
    required this.previewStart,
    required this.previewEnd,
    required this.isDragged,
    required this.isCascaded,
  });

  /// 日数の変化
  int get deltaDays => previewStart.difference(originalStart).inDays;

  /// 変更があるか
  bool get hasChange => deltaDays != 0;
}

/// ドラッグカスケードプレビューの結果
@immutable
class DragCascadePreviewResult {
  /// ドラッグ対象タスクID
  final String draggedTaskId;

  /// 全ての影響を受けるタスクのプレビュー（ドラッグ対象含む）
  final List<DragTaskPreview> previews;

  /// 総影響タスク数（ドラッグ対象除く）
  final int cascadeCount;

  const DragCascadePreviewResult({
    required this.draggedTaskId,
    required this.previews,
    required this.cascadeCount,
  });

  /// 特定タスクのプレビューを取得
  DragTaskPreview? getPreview(String taskId) {
    try {
      return previews.firstWhere((p) => p.taskId == taskId);
    } catch (_) {
      return null;
    }
  }

  /// カスケードで影響を受けるタスクのみ
  List<DragTaskPreview> get cascadedPreviews =>
      previews.where((p) => p.isCascaded).toList();

  /// 影響を受けるタスクIDセット
  Set<String> get affectedTaskIds =>
      previews.where((p) => p.hasChange).map((p) => p.taskId).toSet();
}

/// ドラッグカスケードプレビューサービス
class DragCascadePreviewService extends ChangeNotifier {
  static final DragCascadePreviewService _instance =
      DragCascadePreviewService._internal();
  factory DragCascadePreviewService() => _instance;
  DragCascadePreviewService._internal();

  // データ
  List<Task> _tasks = [];
  List<TaskDependency> _dependencies = [];

  // 現在のプレビュー状態
  DragCascadePreviewResult? _currentPreview;
  bool _isDragging = false;

  // ゲッター
  DragCascadePreviewResult? get currentPreview => _currentPreview;
  bool get isDragging => _isDragging;
  bool get hasPreview => _currentPreview != null;

  /// 初期化
  void initialize({
    required List<Task> tasks,
    required List<TaskDependency> dependencies,
  }) {
    _tasks = List.from(tasks);
    _dependencies = List.from(dependencies);
  }

  /// タスクリストを更新
  void updateTasks(List<Task> tasks) {
    _tasks = List.from(tasks);
  }

  /// 依存関係を更新
  void updateDependencies(List<TaskDependency> dependencies) {
    _dependencies = List.from(dependencies);
  }

  /// ドラッグ開始
  void startDrag(String taskId) {
    _isDragging = true;
    _currentPreview = null;
    notifyListeners();
  }

  /// ドラッグ中のプレビュー計算
  ///
  /// [taskId]: ドラッグ中のタスクID
  /// [deltaDays]: 移動日数（正: 後ろに、負: 前に）
  DragCascadePreviewResult? calculatePreview({
    required String taskId,
    required int deltaDays,
  }) {
    if (!_isDragging) return null;

    final task = _tasks.firstWhere(
      (t) => t.id == taskId,
      orElse: () => throw Exception('Task not found: $taskId'),
    );

    final newStart = task.startDate.add(Duration(days: deltaDays));
    final newEnd = task.endDate.add(Duration(days: deltaDays));

    final previews = <DragTaskPreview>[
      // ドラッグ対象タスク
      DragTaskPreview(
        taskId: taskId,
        originalStart: task.startDate,
        originalEnd: task.endDate,
        previewStart: newStart,
        previewEnd: newEnd,
        isDragged: true,
        isCascaded: false,
      ),
    ];

    // カスケードが発生するのは後ろにずらす場合のみ
    if (deltaDays > 0) {
      _calculateCascade(
        taskId: taskId,
        newEndDate: newEnd,
        previews: previews,
        visitedIds: {taskId},
      );
    }

    _currentPreview = DragCascadePreviewResult(
      draggedTaskId: taskId,
      previews: previews,
      cascadeCount: previews.where((p) => p.isCascaded).length,
    );

    notifyListeners();
    return _currentPreview;
  }

  /// 後続タスクへのカスケード計算
  void _calculateCascade({
    required String taskId,
    required DateTime newEndDate,
    required List<DragTaskPreview> previews,
    required Set<String> visitedIds,
  }) {
    // このタスクに依存している後続タスクを取得（FS依存）
    final successorDeps = _dependencies.where(
      (d) => d.fromTaskId == taskId && d.type == DependencyType.fs,
    );

    for (final dep in successorDeps) {
      if (visitedIds.contains(dep.toTaskId)) continue;
      visitedIds.add(dep.toTaskId);

      final successor = _tasks.firstWhere(
        (t) => t.id == dep.toTaskId,
        orElse: () => throw Exception('Successor not found: ${dep.toTaskId}'),
      );

      // 先行タスク終了日 + ラグ + 1日
      final minStartDate = newEndDate.add(Duration(days: dep.lagDays + 1));

      // 後続タスクの開始日が最小開始日より前なら調整が必要
      if (successor.startDate.isBefore(minStartDate)) {
        final shiftDays = minStartDate.difference(successor.startDate).inDays;
        final newSuccessorStart =
            successor.startDate.add(Duration(days: shiftDays));
        final newSuccessorEnd =
            successor.endDate.add(Duration(days: shiftDays));

        previews.add(DragTaskPreview(
          taskId: successor.id,
          originalStart: successor.startDate,
          originalEnd: successor.endDate,
          previewStart: newSuccessorStart,
          previewEnd: newSuccessorEnd,
          isDragged: false,
          isCascaded: true,
        ));

        // 再帰的に後続タスクを処理
        _calculateCascade(
          taskId: successor.id,
          newEndDate: newSuccessorEnd,
          previews: previews,
          visitedIds: visitedIds,
        );
      }
    }
  }

  /// ドラッグ終了
  void endDrag() {
    _isDragging = false;
    _currentPreview = null;
    notifyListeners();
  }

  /// プレビューをクリア
  void clearPreview() {
    _currentPreview = null;
    notifyListeners();
  }

  /// タスク取得ヘルパー
  Task? getTask(String taskId) {
    try {
      return _tasks.firstWhere((t) => t.id == taskId);
    } catch (_) {
      return null;
    }
  }

  /// 後続タスクID取得
  List<String> getDirectSuccessorIds(String taskId) {
    return _dependencies
        .where((d) => d.fromTaskId == taskId)
        .map((d) => d.toTaskId)
        .toList();
  }

  /// 全後続タスクID取得（再帰的）
  Set<String> getAllSuccessorIds(String taskId) {
    final result = <String>{};
    final visited = <String>{taskId};

    void collect(String id) {
      for (final dep in _dependencies.where((d) => d.fromTaskId == id)) {
        if (!visited.contains(dep.toTaskId)) {
          visited.add(dep.toTaskId);
          result.add(dep.toTaskId);
          collect(dep.toTaskId);
        }
      }
    }

    collect(taskId);
    return result;
  }
}
