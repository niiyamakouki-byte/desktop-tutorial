/// Dependency Service
/// Manages task dependencies, schedule calculation, and auto-adjustment
/// 依存関係とスケジュール計算を管理するサービス

import 'package:flutter/foundation.dart';
import '../models/dependency_model.dart';
import '../models/task_model.dart';
import 'schedule_calculator.dart';

class DependencyService extends ChangeNotifier {
  // Dependencies storage
  final List<TaskDependency> _dependencies = [];

  // Cached schedule results
  Map<String, ScheduleResult> _scheduleCache = {};

  // Critical path cache
  List<String> _criticalPathIds = [];

  // Auto-scheduling enabled
  bool _autoScheduleEnabled = true;

  // Delay impact cache
  DelayImpact? _currentDelayImpact;

  // Getters
  List<TaskDependency> get dependencies => List.unmodifiable(_dependencies);
  Map<String, ScheduleResult> get scheduleResults => Map.unmodifiable(_scheduleCache);
  List<String> get criticalPathIds => List.unmodifiable(_criticalPathIds);
  bool get autoScheduleEnabled => _autoScheduleEnabled;
  DelayImpact? get currentDelayImpact => _currentDelayImpact;

  /// Check if a task is on the critical path
  bool isOnCriticalPath(String taskId) => _criticalPathIds.contains(taskId);

  /// Get schedule result for a task
  ScheduleResult? getScheduleResult(String taskId) => _scheduleCache[taskId];

  /// Get total float for a task
  int getTotalFloat(String taskId) => _scheduleCache[taskId]?.totalFloat ?? 0;

  /// Initialize with existing dependencies
  void initialize(List<TaskDependency> deps) {
    _dependencies.clear();
    _dependencies.addAll(deps);
    notifyListeners();
  }

  /// Add a new dependency
  /// Returns false if it would create a cycle
  bool addDependency({
    required String fromTaskId,
    required String toTaskId,
    DependencyType type = DependencyType.fs,
    int lagDays = 0,
  }) {
    // Check for duplicate
    final exists = _dependencies.any(
      (d) => d.fromTaskId == fromTaskId && d.toTaskId == toTaskId,
    );
    if (exists) return false;

    // Check for cycle
    if (ScheduleCalculator.wouldCreateCycle(
      fromTaskId: fromTaskId,
      toTaskId: toTaskId,
      existingDependencies: _dependencies,
    )) {
      return false;
    }

    final dependency = TaskDependency(
      id: 'dep_${DateTime.now().millisecondsSinceEpoch}_${_dependencies.length}',
      fromTaskId: fromTaskId,
      toTaskId: toTaskId,
      type: type,
      lagDays: lagDays,
    );

    _dependencies.add(dependency);
    notifyListeners();
    return true;
  }

  /// Remove a dependency
  void removeDependency(String dependencyId) {
    _dependencies.removeWhere((d) => d.id == dependencyId);
    notifyListeners();
  }

  /// Remove all dependencies for a task
  void removeDependenciesForTask(String taskId) {
    _dependencies.removeWhere(
      (d) => d.fromTaskId == taskId || d.toTaskId == taskId,
    );
    notifyListeners();
  }

  /// Update dependency type
  void updateDependencyType(String dependencyId, DependencyType type) {
    final index = _dependencies.indexWhere((d) => d.id == dependencyId);
    if (index >= 0) {
      _dependencies[index] = _dependencies[index].copyWith(type: type);
      notifyListeners();
    }
  }

  /// Update dependency lag
  void updateDependencyLag(String dependencyId, int lagDays) {
    final index = _dependencies.indexWhere((d) => d.id == dependencyId);
    if (index >= 0) {
      _dependencies[index] = _dependencies[index].copyWith(lagDays: lagDays);
      notifyListeners();
    }
  }

  /// Get dependencies where this task is the predecessor
  List<TaskDependency> getSuccessorDependencies(String taskId) {
    return _dependencies.where((d) => d.fromTaskId == taskId).toList();
  }

  /// Get dependencies where this task is the successor
  List<TaskDependency> getPredecessorDependencies(String taskId) {
    return _dependencies.where((d) => d.toTaskId == taskId).toList();
  }

  /// Get all successor task IDs
  List<String> getSuccessorIds(String taskId) {
    return _dependencies
        .where((d) => d.fromTaskId == taskId)
        .map((d) => d.toTaskId)
        .toList();
  }

  /// Get all predecessor task IDs
  List<String> getPredecessorIds(String taskId) {
    return _dependencies
        .where((d) => d.toTaskId == taskId)
        .map((d) => d.fromTaskId)
        .toList();
  }

  /// Recalculate schedule for all tasks
  void recalculateSchedule(List<Task> tasks) {
    _scheduleCache = ScheduleCalculator.calculateSchedule(
      tasks: tasks,
      dependencies: _dependencies,
    );

    // Update critical path
    _criticalPathIds = _scheduleCache.entries
        .where((e) => e.value.isCritical)
        .map((e) => e.key)
        .toList();

    notifyListeners();
  }

  /// Auto-adjust task dates based on dependencies
  /// Returns the adjusted task list
  List<Task> autoAdjustTasks(List<Task> tasks) {
    if (!_autoScheduleEnabled) return tasks;

    return ScheduleCalculator.autoAdjustSchedule(
      tasks: tasks,
      dependencies: _dependencies,
    );
  }

  /// Calculate and cache delay impact for a task
  void calculateDelayImpact({
    required Task task,
    required int delayDays,
    required List<Task> allTasks,
  }) {
    if (delayDays <= 0) {
      _currentDelayImpact = null;
    } else {
      _currentDelayImpact = ScheduleCalculator.calculateDelayImpact(
        delayedTask: task,
        delayDays: delayDays,
        tasks: allTasks,
        dependencies: _dependencies,
      );
    }
    notifyListeners();
  }

  /// Clear delay impact visualization
  void clearDelayImpact() {
    _currentDelayImpact = null;
    notifyListeners();
  }

  /// Toggle auto-scheduling
  void toggleAutoSchedule() {
    _autoScheduleEnabled = !_autoScheduleEnabled;
    notifyListeners();
  }

  /// Set auto-scheduling
  void setAutoSchedule(bool enabled) {
    _autoScheduleEnabled = enabled;
    notifyListeners();
  }

  /// Get all downstream task IDs (tasks affected by this one)
  Set<String> getDownstreamTaskIds(String taskId) {
    return ScheduleCalculator.getDownstreamTasks(
      taskId: taskId,
      dependencies: _dependencies,
    );
  }

  /// Get all upstream task IDs (tasks this one depends on)
  Set<String> getUpstreamTaskIds(String taskId) {
    return ScheduleCalculator.getUpstreamTasks(
      taskId: taskId,
      dependencies: _dependencies,
    );
  }

  /// Check if adding dependency would create a cycle
  bool wouldCreateCycle(String fromTaskId, String toTaskId) {
    return ScheduleCalculator.wouldCreateCycle(
      fromTaskId: fromTaskId,
      toTaskId: toTaskId,
      existingDependencies: _dependencies,
    );
  }

  /// Get dependency between two tasks
  TaskDependency? getDependency(String fromTaskId, String toTaskId) {
    try {
      return _dependencies.firstWhere(
        (d) => d.fromTaskId == fromTaskId && d.toTaskId == toTaskId,
      );
    } catch (_) {
      return null;
    }
  }

  /// Check if dependency exists
  bool hasDependency(String fromTaskId, String toTaskId) {
    return _dependencies.any(
      (d) => d.fromTaskId == fromTaskId && d.toTaskId == toTaskId,
    );
  }

  /// Export dependencies as JSON
  List<Map<String, dynamic>> toJson() {
    return _dependencies.map((d) => d.toJson()).toList();
  }

  /// Import dependencies from JSON
  void fromJson(List<dynamic> json) {
    _dependencies.clear();
    for (final item in json) {
      _dependencies.add(TaskDependency.fromJson(item as Map<String, dynamic>));
    }
    notifyListeners();
  }

  /// Clear all dependencies
  void clear() {
    _dependencies.clear();
    _scheduleCache.clear();
    _criticalPathIds.clear();
    _currentDelayImpact = null;
    notifyListeners();
  }

  /// Initialize with mock data for testing
  void initializeMockDependencies(List<Task> tasks) {
    if (tasks.length < 2) return;

    _dependencies.clear();

    // Create some sample dependencies based on task order
    final sortedTasks = List<Task>.from(tasks)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    for (int i = 0; i < sortedTasks.length - 1; i++) {
      // Connect some tasks with FS dependencies
      if (i % 2 == 0 && i + 1 < sortedTasks.length) {
        _dependencies.add(TaskDependency(
          id: 'dep_mock_$i',
          fromTaskId: sortedTasks[i].id,
          toTaskId: sortedTasks[i + 1].id,
          type: DependencyType.fs,
          lagDays: 0,
        ));
      }
    }

    // Calculate initial schedule
    recalculateSchedule(tasks);
  }
}
