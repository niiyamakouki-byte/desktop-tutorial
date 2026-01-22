/// Phase Cascade Service
/// フェーズ連動スライドサービス - バトンパス方式の工程管理

import 'package:flutter/foundation.dart';
import '../models/phase_model.dart';
import '../models/task_model.dart';

/// フェーズ連動サービス
///
/// 「バトンパス」方式でフェーズ間の依存関係を管理。
/// あるフェーズが遅延すると、後続フェーズを自動的にスライドさせる。
class PhaseCascadeService extends ChangeNotifier {
  List<Phase> _phases = [];
  List<Task> _tasks = [];

  // Getters
  List<Phase> get phases => List.unmodifiable(_phases);
  List<Task> get tasks => List.unmodifiable(_tasks);

  /// 初期化
  void initialize({
    required List<Phase> phases,
    required List<Task> tasks,
  }) {
    _phases = List.from(phases);
    _tasks = List.from(tasks);
    notifyListeners();
  }

  /// フェーズを追加
  void addPhase(Phase phase) {
    _phases.add(phase);
    _phases.sort((a, b) => a.order.compareTo(b.order));
    notifyListeners();
  }

  /// タスクを追加
  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  /// フェーズの日程を計算
  PhaseSchedule calculatePhaseSchedule(String phaseId) {
    final phaseTasks = _tasks.where((t) => t.phaseId == phaseId).toList();

    if (phaseTasks.isEmpty) {
      return PhaseSchedule(
        phaseId: phaseId,
        startDate: DateTime.now(),
        endDate: DateTime.now(),
        taskCount: 0,
      );
    }

    DateTime startDate = phaseTasks.first.startDate;
    DateTime endDate = phaseTasks.first.endDate;

    for (final task in phaseTasks) {
      if (task.startDate.isBefore(startDate)) {
        startDate = task.startDate;
      }
      if (task.endDate.isAfter(endDate)) {
        endDate = task.endDate;
      }
    }

    return PhaseSchedule(
      phaseId: phaseId,
      startDate: startDate,
      endDate: endDate,
      taskCount: phaseTasks.length,
    );
  }

  /// 全フェーズの日程を計算
  Map<String, PhaseSchedule> calculateAllPhaseSchedules() {
    final schedules = <String, PhaseSchedule>{};
    for (final phase in _phases) {
      schedules[phase.id] = calculatePhaseSchedule(phase.id);
    }
    return schedules;
  }

  /// フェーズをスライド（カスケード処理）
  ///
  /// [phaseId]: スライドするフェーズID
  /// [daysToShift]: スライドする日数
  /// [cascade]: 後続フェーズもスライドするか
  ///
  /// 戻り値: 影響を受けたタスクのリスト
  CascadeResult shiftPhase({
    required String phaseId,
    required int daysToShift,
    bool cascade = true,
  }) {
    if (daysToShift == 0) {
      return CascadeResult(
        shiftedTasks: [],
        affectedPhases: [],
        totalDaysShifted: 0,
      );
    }

    final phase = _phases.firstWhere(
      (p) => p.id == phaseId,
      orElse: () => throw Exception('Phase not found: $phaseId'),
    );

    final affectedPhases = <Phase>[phase];
    final shiftedTasks = <TaskShiftInfo>[];

    // 1. 対象フェーズのタスクをスライド
    _shiftTasksInPhase(phaseId, daysToShift, shiftedTasks);

    // 2. カスケード処理（後続フェーズへの影響）
    if (cascade) {
      _cascadeToNextPhases(phase, daysToShift, affectedPhases, shiftedTasks);
    }

    notifyListeners();

    return CascadeResult(
      shiftedTasks: shiftedTasks,
      affectedPhases: affectedPhases,
      totalDaysShifted: daysToShift,
    );
  }

  /// 日付ベースでスライド（雨天中止用）
  ///
  /// [targetDate]: この日以降のタスクをスライド
  /// [daysToShift]: スライドする日数
  /// [cascade]: 後続フェーズもスライドするか
  CascadeResult shiftFromDate({
    required DateTime targetDate,
    required int daysToShift,
    bool cascade = true,
  }) {
    if (daysToShift == 0) {
      return CascadeResult(
        shiftedTasks: [],
        affectedPhases: [],
        totalDaysShifted: 0,
      );
    }

    final targetDateOnly = DateTime(targetDate.year, targetDate.month, targetDate.day);
    final affectedPhases = <Phase>[];
    final shiftedTasks = <TaskShiftInfo>[];

    // 影響を受けるフェーズを特定
    final phaseSchedules = calculateAllPhaseSchedules();
    final affectedPhaseIds = <String>{};

    for (final entry in phaseSchedules.entries) {
      final schedule = entry.value;
      // フェーズの終了日がターゲット日以降なら影響を受ける
      if (!schedule.endDate.isBefore(targetDateOnly)) {
        affectedPhaseIds.add(entry.key);
      }
    }

    // 影響を受けるフェーズをorder順にソート
    final sortedPhases = _phases
        .where((p) => affectedPhaseIds.contains(p.id))
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    for (final phase in sortedPhases) {
      affectedPhases.add(phase);

      // フェーズ内のタスクをスライド
      for (final task in _tasks.where((t) => t.phaseId == phase.id)) {
        final taskStartOnly = DateTime(
          task.startDate.year,
          task.startDate.month,
          task.startDate.day,
        );

        // ターゲット日以降のタスクのみスライド
        if (!taskStartOnly.isBefore(targetDateOnly)) {
          final originalStart = task.startDate;
          final originalEnd = task.endDate;
          final newStart = task.startDate.add(Duration(days: daysToShift));
          final newEnd = task.endDate.add(Duration(days: daysToShift));

          // タスクを更新
          final taskIndex = _tasks.indexWhere((t) => t.id == task.id);
          if (taskIndex >= 0) {
            _tasks[taskIndex] = task.copyWith(
              startDate: newStart,
              endDate: newEnd,
            );

            shiftedTasks.add(TaskShiftInfo(
              task: _tasks[taskIndex],
              originalStart: originalStart,
              originalEnd: originalEnd,
              newStart: newStart,
              newEnd: newEnd,
              phaseId: phase.id,
              phaseName: phase.name,
            ));
          }
        }
      }
    }

    // カスケード処理（フェーズ間の重複チェック）
    if (cascade && sortedPhases.isNotEmpty) {
      _resolvePhasOverlaps(affectedPhases, shiftedTasks);
    }

    notifyListeners();

    return CascadeResult(
      shiftedTasks: shiftedTasks,
      affectedPhases: affectedPhases,
      totalDaysShifted: daysToShift,
    );
  }

  /// フェーズ内のタスクをスライド
  void _shiftTasksInPhase(
    String phaseId,
    int daysToShift,
    List<TaskShiftInfo> shiftedTasks,
  ) {
    final phase = _phases.firstWhere((p) => p.id == phaseId);

    for (var i = 0; i < _tasks.length; i++) {
      final task = _tasks[i];
      if (task.phaseId == phaseId) {
        final originalStart = task.startDate;
        final originalEnd = task.endDate;
        final newStart = task.startDate.add(Duration(days: daysToShift));
        final newEnd = task.endDate.add(Duration(days: daysToShift));

        _tasks[i] = task.copyWith(
          startDate: newStart,
          endDate: newEnd,
        );

        shiftedTasks.add(TaskShiftInfo(
          task: _tasks[i],
          originalStart: originalStart,
          originalEnd: originalEnd,
          newStart: newStart,
          newEnd: newEnd,
          phaseId: phaseId,
          phaseName: phase.name,
        ));
      }
    }
  }

  /// 後続フェーズへのカスケード処理
  void _cascadeToNextPhases(
    Phase sourcePhase,
    int initialShift,
    List<Phase> affectedPhases,
    List<TaskShiftInfo> shiftedTasks,
  ) {
    final sourceSchedule = calculatePhaseSchedule(sourcePhase.id);

    // 同じdependencyGroup内で、orderが大きい（後の）フェーズを取得
    final nextPhases = _phases.where((p) {
      // 同じプロジェクト
      if (p.projectId != sourcePhase.projectId) return false;
      // orderが大きい（後のフェーズ）
      if (p.order <= sourcePhase.order) return false;
      // dependencyGroupが同じ（または両方null）
      if (sourcePhase.dependencyGroup != p.dependencyGroup) return false;
      return true;
    }).toList()
      ..sort((a, b) => a.order.compareTo(b.order));

    for (final nextPhase in nextPhases) {
      final nextSchedule = calculatePhaseSchedule(nextPhase.id);

      // 前のフェーズの終了日が次のフェーズの開始日に食い込んでいるかチェック
      if (sourceSchedule.endDate.isAfter(nextSchedule.startDate) ||
          sourceSchedule.endDate.isAtSameMomentAs(nextSchedule.startDate)) {
        // 食い込んだ日数を計算（+1は予備日）
        final overlapDays =
            sourceSchedule.endDate.difference(nextSchedule.startDate).inDays + 1;

        if (overlapDays > 0) {
          affectedPhases.add(nextPhase);
          _shiftTasksInPhase(nextPhase.id, overlapDays, shiftedTasks);

          // 再帰的に次のフェーズもチェック
          _cascadeToNextPhases(nextPhase, overlapDays, affectedPhases, shiftedTasks);
        }
      }
    }
  }

  /// フェーズ間の重複を解消
  void _resolvePhasOverlaps(
    List<Phase> affectedPhases,
    List<TaskShiftInfo> shiftedTasks,
  ) {
    final sortedPhases = List<Phase>.from(affectedPhases)
      ..sort((a, b) => a.order.compareTo(b.order));

    for (var i = 0; i < sortedPhases.length - 1; i++) {
      final currentPhase = sortedPhases[i];
      final nextPhase = sortedPhases[i + 1];

      // 同じdependencyGroupでない場合はスキップ
      if (currentPhase.dependencyGroup != nextPhase.dependencyGroup) continue;

      final currentSchedule = calculatePhaseSchedule(currentPhase.id);
      final nextSchedule = calculatePhaseSchedule(nextPhase.id);

      // 重複チェック
      if (currentSchedule.endDate.isAfter(nextSchedule.startDate) ||
          currentSchedule.endDate.isAtSameMomentAs(nextSchedule.startDate)) {
        final overlapDays =
            currentSchedule.endDate.difference(nextSchedule.startDate).inDays + 1;

        if (overlapDays > 0) {
          _shiftTasksInPhase(nextPhase.id, overlapDays, shiftedTasks);
        }
      }
    }
  }

  /// フェーズごとにタスクをグループ化
  Map<String, List<Task>> getTasksByPhase() {
    final grouped = <String, List<Task>>{};
    for (final phase in _phases) {
      grouped[phase.id] = _tasks.where((t) => t.phaseId == phase.id).toList();
    }
    // フェーズなしのタスク
    final noPhase = _tasks.where((t) => t.phaseId == null).toList();
    if (noPhase.isNotEmpty) {
      grouped['_no_phase'] = noPhase;
    }
    return grouped;
  }

  /// フェーズの順序を取得
  int? getPhaseOrder(String? phaseId) {
    if (phaseId == null) return null;
    try {
      return _phases.firstWhere((p) => p.id == phaseId).order;
    } catch (_) {
      return null;
    }
  }

  /// フェーズを取得
  Phase? getPhase(String? phaseId) {
    if (phaseId == null) return null;
    try {
      return _phases.firstWhere((p) => p.id == phaseId);
    } catch (_) {
      return null;
    }
  }

  /// プレビュー：スライドの影響を計算（実際には適用しない）
  CascadeResult previewShiftFromDate({
    required DateTime targetDate,
    required int daysToShift,
    bool cascade = true,
  }) {
    // 現在の状態をコピー
    final originalTasks = List<Task>.from(_tasks);

    // シミュレーション実行
    final result = shiftFromDate(
      targetDate: targetDate,
      daysToShift: daysToShift,
      cascade: cascade,
    );

    // 元に戻す
    _tasks = originalTasks;

    return result;
  }

  /// モックデータを生成
  void initializeMockData(String projectId) {
    final now = DateTime.now();
    final baseDate = DateTime(now.year, now.month, now.day);

    // フェーズを生成
    _phases = [
      Phase(
        id: 'phase_1',
        projectId: projectId,
        name: '下地工事',
        order: 1,
        dependencyGroup: 'main',
        type: PhaseType.construction,
        createdAt: now,
        updatedAt: now,
      ),
      Phase(
        id: 'phase_2',
        projectId: projectId,
        name: '設備工事',
        order: 2,
        dependencyGroup: 'main',
        type: PhaseType.construction,
        createdAt: now,
        updatedAt: now,
      ),
      Phase(
        id: 'phase_3',
        projectId: projectId,
        name: '仕上げ工事',
        order: 3,
        dependencyGroup: 'main',
        type: PhaseType.finishing,
        createdAt: now,
        updatedAt: now,
      ),
      Phase(
        id: 'phase_4',
        projectId: projectId,
        name: '検査・引渡し',
        order: 4,
        dependencyGroup: 'main',
        type: PhaseType.handover,
        createdAt: now,
        updatedAt: now,
      ),
    ];

    // タスクを生成（各フェーズに複数タスク）
    _tasks = [
      // Phase 1: 下地工事
      _createMockTask('task_1_1', projectId, 'phase_1', '木工下地', 'A社（大工）',
          baseDate, baseDate.add(const Duration(days: 5)), now),
      _createMockTask('task_1_2', projectId, 'phase_1', '金物取付', 'A社（大工）',
          baseDate.add(const Duration(days: 2)), baseDate.add(const Duration(days: 6)), now),

      // Phase 2: 設備工事
      _createMockTask('task_2_1', projectId, 'phase_2', '電気配線', 'B社（電気）',
          baseDate.add(const Duration(days: 7)), baseDate.add(const Duration(days: 10)), now),
      _createMockTask('task_2_2', projectId, 'phase_2', '給排水配管', 'C社（配管）',
          baseDate.add(const Duration(days: 7)), baseDate.add(const Duration(days: 11)), now),
      _createMockTask('task_2_3', projectId, 'phase_2', '空調設備', 'D社（空調）',
          baseDate.add(const Duration(days: 8)), baseDate.add(const Duration(days: 12)), now),

      // Phase 3: 仕上げ工事
      _createMockTask('task_3_1', projectId, 'phase_3', 'クロス貼り', 'E社（内装）',
          baseDate.add(const Duration(days: 13)), baseDate.add(const Duration(days: 17)), now),
      _createMockTask('task_3_2', projectId, 'phase_3', '床仕上げ', 'E社（内装）',
          baseDate.add(const Duration(days: 14)), baseDate.add(const Duration(days: 18)), now),
      _createMockTask('task_3_3', projectId, 'phase_3', '塗装', 'F社（塗装）',
          baseDate.add(const Duration(days: 15)), baseDate.add(const Duration(days: 19)), now),

      // Phase 4: 検査・引渡し
      _createMockTask('task_4_1', projectId, 'phase_4', '社内検査', '自社',
          baseDate.add(const Duration(days: 20)), baseDate.add(const Duration(days: 21)), now),
      _createMockTask('task_4_2', projectId, 'phase_4', 'クリーニング', 'G社',
          baseDate.add(const Duration(days: 22)), baseDate.add(const Duration(days: 23)), now),
      _createMockTask('task_4_3', projectId, 'phase_4', '引渡し', '自社',
          baseDate.add(const Duration(days: 24)), baseDate.add(const Duration(days: 24)), now),
    ];

    notifyListeners();
  }

  Task _createMockTask(
    String id,
    String projectId,
    String phaseId,
    String name,
    String contractor,
    DateTime start,
    DateTime end,
    DateTime now,
  ) {
    return Task(
      id: id,
      projectId: projectId,
      name: name,
      startDate: start,
      endDate: end,
      status: 'not_started',
      category: 'general',
      phaseId: phaseId,
      contractorName: contractor,
      createdAt: now,
      updatedAt: now,
    );
  }
}

/// タスクシフト情報
class TaskShiftInfo {
  final Task task;
  final DateTime originalStart;
  final DateTime originalEnd;
  final DateTime newStart;
  final DateTime newEnd;
  final String phaseId;
  final String phaseName;

  const TaskShiftInfo({
    required this.task,
    required this.originalStart,
    required this.originalEnd,
    required this.newStart,
    required this.newEnd,
    required this.phaseId,
    required this.phaseName,
  });

  int get daysShifted => newStart.difference(originalStart).inDays;

  /// 新しい開始日が土日か
  bool get startsOnWeekend =>
      newStart.weekday == DateTime.saturday || newStart.weekday == DateTime.sunday;

  /// 新しい終了日が土日か
  bool get endsOnWeekend =>
      newEnd.weekday == DateTime.saturday || newEnd.weekday == DateTime.sunday;
}

/// カスケード結果
class CascadeResult {
  final List<TaskShiftInfo> shiftedTasks;
  final List<Phase> affectedPhases;
  final int totalDaysShifted;

  const CascadeResult({
    required this.shiftedTasks,
    required this.affectedPhases,
    required this.totalDaysShifted,
  });

  /// 影響を受けたタスク数
  int get affectedTaskCount => shiftedTasks.length;

  /// 影響を受けたフェーズ数
  int get affectedPhaseCount => affectedPhases.length;

  /// 土日にかかるタスク数
  int get weekendTaskCount =>
      shiftedTasks.where((t) => t.startsOnWeekend || t.endsOnWeekend).length;

  /// フェーズ別のシフト情報
  Map<String, List<TaskShiftInfo>> get tasksByPhase {
    final grouped = <String, List<TaskShiftInfo>>{};
    for (final info in shiftedTasks) {
      grouped.putIfAbsent(info.phaseId, () => []).add(info);
    }
    return grouped;
  }
}
