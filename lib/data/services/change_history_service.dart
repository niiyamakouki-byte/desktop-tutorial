import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

/// 変更履歴サービス
///
/// タスクの変更履歴を記録・管理する
/// 誰がいつ何を変えたかを追跡
class ChangeHistoryService extends ChangeNotifier {
  /// シングルトンインスタンス
  static final ChangeHistoryService _instance = ChangeHistoryService._internal();
  factory ChangeHistoryService() => _instance;
  ChangeHistoryService._internal();

  /// 変更履歴のキャッシュ（taskId -> List<TaskChangeHistory>）
  final Map<String, List<TaskChangeHistory>> _historyCache = {};

  /// プロジェクト全体の履歴（最新順）
  final Map<String, List<TaskChangeHistory>> _projectHistory = {};

  /// 最大保持件数（タスク毎）
  static const int maxHistoryPerTask = 100;

  /// 最大保持件数（プロジェクト毎）
  static const int maxHistoryPerProject = 500;

  /// 現在のユーザーID（認証連携時にセット）
  String? _currentUserId;
  User? _currentUser;

  /// 現在のユーザーをセット
  void setCurrentUser(User user) {
    _currentUser = user;
    _currentUserId = user.id;
  }

  /// タスクの変更履歴を取得
  List<TaskChangeHistory> getHistoryForTask(String taskId) {
    return List.unmodifiable(_historyCache[taskId] ?? []);
  }

  /// プロジェクトの変更履歴を取得
  List<TaskChangeHistory> getHistoryForProject(String projectId, {int? limit}) {
    final history = _projectHistory[projectId] ?? [];
    if (limit != null && limit < history.length) {
      return List.unmodifiable(history.take(limit).toList());
    }
    return List.unmodifiable(history);
  }

  /// 最近の変更履歴を取得（全プロジェクト）
  List<TaskChangeHistory> getRecentHistory({int limit = 20}) {
    final allHistory = <TaskChangeHistory>[];
    for (final history in _projectHistory.values) {
      allHistory.addAll(history);
    }
    allHistory.sort((a, b) => b.changedAt.compareTo(a.changedAt));
    return allHistory.take(limit).toList();
  }

  /// タスク変更を記録
  ///
  /// [oldTask] 変更前のタスク（nullの場合は新規作成）
  /// [newTask] 変更後のタスク（nullの場合は削除）
  /// [changeType] 変更種別
  /// [reason] 変更理由（任意）
  /// [comment] コメント（任意）
  Future<TaskChangeHistory> recordChange({
    Task? oldTask,
    Task? newTask,
    required ChangeType changeType,
    String? reason,
    String? comment,
  }) async {
    final taskId = newTask?.id ?? oldTask?.id;
    final projectId = newTask?.projectId ?? oldTask?.projectId;

    if (taskId == null || projectId == null) {
      throw ArgumentError('taskId and projectId are required');
    }

    // 変更されたフィールドを検出
    final changes = _detectChanges(oldTask, newTask);

    // 履歴エントリを作成
    final history = TaskChangeHistory(
      id: _generateId(),
      taskId: taskId,
      projectId: projectId,
      changedBy: _currentUser,
      changedByUserId: _currentUserId ?? 'unknown',
      changedAt: DateTime.now(),
      changeType: changeType,
      changes: changes,
      reason: reason,
      comment: comment,
      deviceInfo: defaultTargetPlatform.toString(),
    );

    // キャッシュに追加
    _addToCache(taskId, projectId, history);

    // 変更を通知
    notifyListeners();

    // TODO: サーバーに送信（非同期）
    // await _syncToServer(history);

    return history;
  }

  /// 日程変更を記録（ドラッグ操作用）
  Future<TaskChangeHistory> recordScheduleChange({
    required Task oldTask,
    required Task newTask,
    String? reason,
  }) async {
    return recordChange(
      oldTask: oldTask,
      newTask: newTask,
      changeType: ChangeType.dragDrop,
      reason: reason ?? 'ドラッグで日程変更',
    );
  }

  /// 進捗変更を記録
  Future<TaskChangeHistory> recordProgressChange({
    required Task oldTask,
    required Task newTask,
    String? comment,
  }) async {
    return recordChange(
      oldTask: oldTask,
      newTask: newTask,
      changeType: ChangeType.progressChange,
      comment: comment,
    );
  }

  /// ステータス変更を記録
  Future<TaskChangeHistory> recordStatusChange({
    required Task oldTask,
    required Task newTask,
    String? reason,
  }) async {
    return recordChange(
      oldTask: oldTask,
      newTask: newTask,
      changeType: ChangeType.statusChange,
      reason: reason,
    );
  }

  /// 変更されたフィールドを検出
  List<FieldChange> _detectChanges(Task? oldTask, Task? newTask) {
    final changes = <FieldChange>[];

    if (oldTask == null || newTask == null) {
      return changes; // 作成/削除時はフィールド変更なし
    }

    // 各フィールドをチェック
    if (oldTask.name != newTask.name) {
      changes.add(FieldChange(
        field: TaskFieldType.name,
        oldValue: oldTask.name,
        newValue: newTask.name,
      ));
    }

    if (oldTask.description != newTask.description) {
      changes.add(FieldChange(
        field: TaskFieldType.description,
        oldValue: oldTask.description,
        newValue: newTask.description,
      ));
    }

    if (oldTask.startDate != newTask.startDate) {
      changes.add(FieldChange(
        field: TaskFieldType.startDate,
        oldValue: oldTask.startDate.toIso8601String(),
        newValue: newTask.startDate.toIso8601String(),
      ));
    }

    if (oldTask.endDate != newTask.endDate) {
      changes.add(FieldChange(
        field: TaskFieldType.endDate,
        oldValue: oldTask.endDate.toIso8601String(),
        newValue: newTask.endDate.toIso8601String(),
      ));
    }

    if (oldTask.progress != newTask.progress) {
      changes.add(FieldChange(
        field: TaskFieldType.progress,
        oldValue: oldTask.progress,
        newValue: newTask.progress,
      ));
    }

    if (oldTask.status != newTask.status) {
      changes.add(FieldChange(
        field: TaskFieldType.status,
        oldValue: oldTask.status,
        newValue: newTask.status,
      ));
    }

    if (oldTask.priority != newTask.priority) {
      changes.add(FieldChange(
        field: TaskFieldType.priority,
        oldValue: oldTask.priority,
        newValue: newTask.priority,
      ));
    }

    if (oldTask.contractorName != newTask.contractorName) {
      changes.add(FieldChange(
        field: TaskFieldType.contractorName,
        oldValue: oldTask.contractorName,
        newValue: newTask.contractorName,
      ));
    }

    if (oldTask.assigneeName != newTask.assigneeName) {
      changes.add(FieldChange(
        field: TaskFieldType.assigneeName,
        oldValue: oldTask.assigneeName,
        newValue: newTask.assigneeName,
      ));
    }

    if (oldTask.blockingReason != newTask.blockingReason) {
      changes.add(FieldChange(
        field: TaskFieldType.blockingReason,
        oldValue: oldTask.blockingReason?.value,
        newValue: newTask.blockingReason?.value,
      ));
    }

    if (oldTask.phaseId != newTask.phaseId) {
      changes.add(FieldChange(
        field: TaskFieldType.phaseId,
        oldValue: oldTask.phaseId,
        newValue: newTask.phaseId,
      ));
    }

    if (oldTask.notes != newTask.notes) {
      changes.add(FieldChange(
        field: TaskFieldType.notes,
        oldValue: oldTask.notes,
        newValue: newTask.notes,
      ));
    }

    return changes;
  }

  /// キャッシュに追加
  void _addToCache(String taskId, String projectId, TaskChangeHistory history) {
    // タスク毎のキャッシュ
    _historyCache.putIfAbsent(taskId, () => []);
    _historyCache[taskId]!.insert(0, history);
    if (_historyCache[taskId]!.length > maxHistoryPerTask) {
      _historyCache[taskId]!.removeLast();
    }

    // プロジェクト毎のキャッシュ
    _projectHistory.putIfAbsent(projectId, () => []);
    _projectHistory[projectId]!.insert(0, history);
    if (_projectHistory[projectId]!.length > maxHistoryPerProject) {
      _projectHistory[projectId]!.removeLast();
    }
  }

  /// ID生成
  String _generateId() {
    return 'ch_${DateTime.now().millisecondsSinceEpoch}_${_idCounter++}';
  }

  static int _idCounter = 0;

  /// キャッシュをクリア
  void clearCache() {
    _historyCache.clear();
    _projectHistory.clear();
    notifyListeners();
  }

  /// 特定タスクのキャッシュをクリア
  void clearTaskHistory(String taskId) {
    _historyCache.remove(taskId);
    // プロジェクト履歴からも該当タスクのものを削除
    for (final histories in _projectHistory.values) {
      histories.removeWhere((h) => h.taskId == taskId);
    }
    notifyListeners();
  }

  /// フィルタ付きで履歴を取得
  List<TaskChangeHistory> getFilteredHistory({
    String? taskId,
    String? projectId,
    ChangeHistoryFilter? filter,
    int? limit,
  }) {
    List<TaskChangeHistory> result;

    if (taskId != null) {
      result = getHistoryForTask(taskId);
    } else if (projectId != null) {
      result = getHistoryForProject(projectId);
    } else {
      result = getRecentHistory(limit: 100);
    }

    if (filter != null) {
      result = result.applyFilter(filter);
    }

    if (limit != null && limit < result.length) {
      result = result.take(limit).toList();
    }

    return result;
  }

  /// デモデータを生成
  void generateDemoHistory(List<Task> tasks, User currentUser) {
    setCurrentUser(currentUser);

    final now = DateTime.now();
    final demoUsers = [
      currentUser,
      User(
        id: 'user_demo_1',
        name: '田中 一郎',
        email: 'tanaka@example.com',
        role: UserRole.manager,
        createdAt: now,
        isOnline: false,
      ),
      User(
        id: 'user_demo_2',
        name: '鈴木 花子',
        email: 'suzuki@example.com',
        role: UserRole.worker,
        createdAt: now,
        isOnline: true,
      ),
    ];

    for (final task in tasks.take(5)) {
      // 日程変更履歴
      final scheduleHistory = TaskChangeHistory(
        id: _generateId(),
        taskId: task.id,
        projectId: task.projectId,
        changedBy: demoUsers[1],
        changedByUserId: demoUsers[1].id,
        changedAt: now.subtract(const Duration(hours: 3)),
        changeType: ChangeType.scheduleChange,
        changes: [
          FieldChange(
            field: TaskFieldType.endDate,
            oldValue: task.endDate.subtract(const Duration(days: 2)).toIso8601String(),
            newValue: task.endDate.toIso8601String(),
          ),
        ],
        reason: '天候不良のため',
      );
      _addToCache(task.id, task.projectId, scheduleHistory);

      // 進捗更新履歴
      final progressHistory = TaskChangeHistory(
        id: _generateId(),
        taskId: task.id,
        projectId: task.projectId,
        changedBy: demoUsers[2],
        changedByUserId: demoUsers[2].id,
        changedAt: now.subtract(const Duration(hours: 1)),
        changeType: ChangeType.progressChange,
        changes: [
          FieldChange(
            field: TaskFieldType.progress,
            oldValue: 0.5,
            newValue: task.progress,
          ),
        ],
        comment: '午前作業完了',
      );
      _addToCache(task.id, task.projectId, progressHistory);
    }

    notifyListeners();
  }
}
