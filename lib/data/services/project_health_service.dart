/// Project Health & Cost Analysis Service
/// プロジェクト健全性分析と遅延コスト計算サービス

import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/project_health_model.dart';
import '../models/dependency_model.dart';
import '../models/material_model.dart';
import 'schedule_calculator.dart';

class ProjectHealthService extends ChangeNotifier {
  // Configuration
  AlertThresholdConfig _alertConfig = const AlertThresholdConfig();
  Map<String, TaskLaborConfig> _laborConfigs = {};

  // Cached results
  ProjectHealthScore? _lastHealthScore;
  DelayCostBreakdown? _lastDelayCost;
  CriticalPathProgress? _lastCriticalPathProgress;

  // Default labor rates
  static const double defaultHourlyRate = 15000; // ¥15,000/hour
  static const int defaultWorkersPerTask = 3;
  static const double defaultEquipmentDailyRate = 50000;
  static const double defaultStorageDailyRate = 10000;
  static const double defaultOverheadDailyRate = 30000;

  // Getters
  AlertThresholdConfig get alertConfig => _alertConfig;
  Map<String, TaskLaborConfig> get laborConfigs => Map.unmodifiable(_laborConfigs);
  ProjectHealthScore? get lastHealthScore => _lastHealthScore;
  DelayCostBreakdown? get lastDelayCost => _lastDelayCost;
  CriticalPathProgress? get lastCriticalPathProgress => _lastCriticalPathProgress;

  // ============== Configuration ==============

  /// Update alert threshold configuration
  void updateAlertConfig(AlertThresholdConfig config) {
    _alertConfig = config;
    notifyListeners();
  }

  /// Set labor config for a task
  void setTaskLaborConfig(String taskId, TaskLaborConfig config) {
    _laborConfigs[taskId] = config;
    notifyListeners();
  }

  /// Get labor config for a task (with default)
  TaskLaborConfig getTaskLaborConfig(String taskId, {Task? task}) {
    if (_laborConfigs.containsKey(taskId)) {
      return _laborConfigs[taskId]!;
    }

    // Create default based on task duration
    final estimatedHours = (task?.durationDays ?? 1) * 8.0 * defaultWorkersPerTask;
    return TaskLaborConfig(
      taskId: taskId,
      estimatedHours: estimatedHours,
      hourlyRate: defaultHourlyRate,
    );
  }

  // ============== Health Score Calculation ==============

  /// Calculate comprehensive project health score
  ProjectHealthScore calculateHealthScore({
    required List<Task> tasks,
    required List<TaskDependency> dependencies,
    List<OrderAlert>? alerts,
    List<PurchaseOrder>? orders,
    double? budget,
    double? actualSpend,
  }) {
    final now = DateTime.now();

    // Calculate schedule score
    final scheduleMetrics = _calculateScheduleMetrics(tasks, dependencies);

    // Calculate cost score
    final costMetrics = _calculateCostMetrics(tasks, budget, actualSpend);

    // Calculate resource score
    final resourceMetrics = _calculateResourceMetrics(tasks);

    // Calculate risk score
    final riskMetrics = _calculateRiskMetrics(
      tasks: tasks,
      alerts: alerts ?? [],
      orders: orders ?? [],
    );

    // Calculate critical path progress
    final criticalPathProgress = calculateCriticalPathProgress(
      tasks: tasks,
      dependencies: dependencies,
    );

    // Calculate delay cost
    final delayCost = calculateProjectDelayCost(
      tasks: tasks,
      dependencies: dependencies,
    );

    // Weighted overall score
    final overallScore = ProjectHealthScore.calculateWeightedScore(
      scheduleScore: scheduleMetrics['score']!,
      costScore: costMetrics['score']!,
      resourceScore: resourceMetrics['score']!,
      riskScore: riskMetrics['score']!,
    );

    _lastHealthScore = ProjectHealthScore(
      overallScore: overallScore,
      scheduleScore: scheduleMetrics['score']!,
      costScore: costMetrics['score']!,
      resourceScore: resourceMetrics['score']!,
      riskScore: riskMetrics['score']!,
      criticalPathProgress: criticalPathProgress.overallProgress,
      delayedTaskCount: scheduleMetrics['delayedCount']!.toInt(),
      totalDelayDays: scheduleMetrics['totalDelayDays']!.toInt(),
      estimatedDelayCost: delayCost.totalCost,
      pendingOrderCount: orders?.where((o) => o.status != OrderStatus.delivered).length ?? 0,
      criticalAlertCount: alerts?.where((a) => a.severity == AlertSeverity.critical).length ?? 0,
      status: ProjectHealthScore.getStatusFromScore(overallScore),
      calculatedAt: now,
    );

    notifyListeners();
    return _lastHealthScore!;
  }

  Map<String, double> _calculateScheduleMetrics(
    List<Task> tasks,
    List<TaskDependency> dependencies,
  ) {
    if (tasks.isEmpty) {
      return {'score': 100.0, 'delayedCount': 0.0, 'totalDelayDays': 0.0};
    }

    int delayedCount = 0;
    int totalDelayDays = 0;
    double totalProgress = 0;
    double expectedProgress = 0;

    final now = DateTime.now();

    for (final task in tasks) {
      if (task.isOverdue) {
        delayedCount++;
        final delayDays = now.difference(task.endDate).inDays;
        totalDelayDays += delayDays > 0 ? delayDays : 0;
      }

      totalProgress += task.progress;

      // Calculate expected progress based on time elapsed
      final taskDuration = task.endDate.difference(task.startDate).inDays + 1;
      final elapsed = now.difference(task.startDate).inDays;
      if (elapsed > 0 && elapsed < taskDuration) {
        expectedProgress += (elapsed / taskDuration) * 100;
      } else if (elapsed >= taskDuration) {
        expectedProgress += 100;
      }
    }

    final avgProgress = totalProgress / tasks.length;
    final avgExpected = expectedProgress / tasks.length;

    // Score: Start at 100, deduct for delays and progress gaps
    double score = 100.0;
    score -= delayedCount * 10; // -10 per delayed task
    score -= totalDelayDays * 2; // -2 per delay day
    if (avgExpected > 0) {
      final progressGap = avgExpected - avgProgress;
      if (progressGap > 0) {
        score -= progressGap * 0.5; // Deduct for being behind
      }
    }

    return {
      'score': score.clamp(0.0, 100.0),
      'delayedCount': delayedCount.toDouble(),
      'totalDelayDays': totalDelayDays.toDouble(),
    };
  }

  Map<String, double> _calculateCostMetrics(
    List<Task> tasks,
    double? budget,
    double? actualSpend,
  ) {
    if (budget == null || budget <= 0) {
      return {'score': 80.0}; // Default if no budget tracking
    }

    // Calculate based on budget variance
    final spend = actualSpend ?? 0;
    final variance = (spend - budget) / budget;

    double score = 100.0;
    if (variance > 0) {
      // Over budget - deduct more severely
      score -= variance * 100 * 2;
    } else if (variance < -0.1) {
      // Significantly under budget might indicate scope issues
      score -= (variance.abs() - 0.1) * 50;
    }

    return {'score': score.clamp(0.0, 100.0)};
  }

  Map<String, double> _calculateResourceMetrics(List<Task> tasks) {
    if (tasks.isEmpty) return {'score': 100.0};

    // Check for resource allocation issues
    int unassignedTasks = 0;
    int overloadedResources = 0;

    for (final task in tasks) {
      if (task.assignees.isEmpty && task.status != 'completed') {
        unassignedTasks++;
      }
    }

    double score = 100.0;
    score -= unassignedTasks * 5; // -5 per unassigned task

    return {'score': score.clamp(0.0, 100.0)};
  }

  Map<String, double> _calculateRiskMetrics({
    required List<Task> tasks,
    required List<OrderAlert> alerts,
    required List<PurchaseOrder> orders,
  }) {
    double score = 100.0;

    // Count alerts by severity
    for (final alert in alerts) {
      if (alert.isDismissed) continue;
      switch (alert.severity) {
        case AlertSeverity.critical:
          score -= 15;
          break;
        case AlertSeverity.high:
          score -= 10;
          break;
        case AlertSeverity.medium:
          score -= 5;
          break;
        case AlertSeverity.low:
          score -= 2;
          break;
      }
    }

    // Check pending orders with delivery risk
    for (final order in orders) {
      if (order.isDeliveryAtRisk) {
        score -= 10;
      }
    }

    return {'score': score.clamp(0.0, 100.0)};
  }

  // ============== Critical Path Progress ==============

  /// Calculate critical path progress
  CriticalPathProgress calculateCriticalPathProgress({
    required List<Task> tasks,
    required List<TaskDependency> dependencies,
  }) {
    if (tasks.isEmpty) {
      return const CriticalPathProgress(
        tasks: [],
        overallProgress: 0,
        completedTasks: 0,
        totalTasks: 0,
        delayedTasks: 0,
      );
    }

    // Calculate schedule to get critical path
    final schedule = ScheduleCalculator.calculateSchedule(
      tasks: tasks,
      dependencies: dependencies,
    );

    // Get critical tasks
    final criticalTaskIds = schedule.entries
        .where((e) => e.value.isCritical)
        .map((e) => e.key)
        .toList();

    final criticalTasks = tasks
        .where((t) => criticalTaskIds.contains(t.id))
        .toList();

    // Sort by earliest start
    criticalTasks.sort((a, b) {
      final aSchedule = schedule[a.id];
      final bSchedule = schedule[b.id];
      if (aSchedule == null || bSchedule == null) return 0;
      return aSchedule.earliestStart.compareTo(bSchedule.earliestStart);
    });

    // Build critical path task list with progress
    final criticalPathTasks = <CriticalPathTask>[];
    int completedCount = 0;
    int delayedCount = 0;
    double totalProgress = 0;

    for (int i = 0; i < criticalTasks.length; i++) {
      final task = criticalTasks[i];
      final isDelayed = task.isOverdue;
      final delayDays = isDelayed
          ? DateTime.now().difference(task.endDate).inDays
          : 0;

      criticalPathTasks.add(CriticalPathTask.fromTask(
        task,
        i + 1,
        delayDays: delayDays > 0 ? delayDays : 0,
      ));

      if (task.status == 'completed' || task.progress >= 100) {
        completedCount++;
      }
      if (isDelayed) {
        delayedCount++;
      }
      totalProgress += task.progress;
    }

    final overallProgress = criticalTasks.isEmpty
        ? 0.0
        : totalProgress / criticalTasks.length;

    // Find earliest and latest completion dates
    DateTime? earliestCompletion;
    DateTime? latestCompletion;

    for (final entry in schedule.entries) {
      if (criticalTaskIds.contains(entry.key)) {
        final ef = entry.value.earliestFinish;
        final lf = entry.value.latestFinish;

        if (earliestCompletion == null || ef.isAfter(earliestCompletion)) {
          earliestCompletion = ef;
        }
        if (latestCompletion == null || lf.isAfter(latestCompletion)) {
          latestCompletion = lf;
        }
      }
    }

    _lastCriticalPathProgress = CriticalPathProgress(
      tasks: criticalPathTasks,
      overallProgress: overallProgress,
      completedTasks: completedCount,
      totalTasks: criticalTasks.length,
      delayedTasks: delayedCount,
      earliestCompletion: earliestCompletion,
      latestCompletion: latestCompletion,
    );

    return _lastCriticalPathProgress!;
  }

  // ============== Delay Cost Calculation ==============

  /// Calculate total project delay cost
  DelayCostBreakdown calculateProjectDelayCost({
    required List<Task> tasks,
    required List<TaskDependency> dependencies,
  }) {
    int totalDelayDays = 0;
    int totalWorkers = 0;

    for (final task in tasks) {
      if (task.isOverdue) {
        final delayDays = DateTime.now().difference(task.endDate).inDays;
        if (delayDays > 0) {
          totalDelayDays += delayDays;
          // Estimate workers from assignees or default
          final workers = task.assignees.isNotEmpty
              ? task.assignees.length
              : defaultWorkersPerTask;
          totalWorkers += workers;
        }
      }
    }

    final avgWorkers = totalDelayDays > 0 && tasks.isNotEmpty
        ? (totalWorkers / tasks.where((t) => t.isOverdue).length).round()
        : defaultWorkersPerTask;

    _lastDelayCost = DelayCostBreakdown.calculate(
      delayDays: totalDelayDays,
      workers: avgWorkers,
      hourlyRate: defaultHourlyRate,
      equipmentDailyRate: defaultEquipmentDailyRate,
      storageDailyRate: defaultStorageDailyRate,
      overheadDailyRate: defaultOverheadDailyRate,
    );

    return _lastDelayCost!;
  }

  /// Calculate delay cost for a specific task
  DelayCostBreakdown calculateTaskDelayCost({
    required Task task,
    required int delayDays,
  }) {
    final laborConfig = getTaskLaborConfig(task.id, task: task);
    final workers = task.assignees.isNotEmpty
        ? task.assignees.length
        : defaultWorkersPerTask;

    return DelayCostBreakdown.calculate(
      delayDays: delayDays,
      workers: workers,
      hourlyRate: laborConfig.hourlyRate,
      equipmentDailyRate: defaultEquipmentDailyRate,
      storageDailyRate: defaultStorageDailyRate,
      overheadDailyRate: defaultOverheadDailyRate,
    );
  }

  /// Calculate delay impact with cost for a hypothetical delay
  Map<String, dynamic> simulateDelayImpact({
    required Task delayedTask,
    required int delayDays,
    required List<Task> allTasks,
    required List<TaskDependency> dependencies,
  }) {
    final impact = ScheduleCalculator.calculateDelayImpact(
      delayedTask: delayedTask,
      delayDays: delayDays,
      tasks: allTasks,
      dependencies: dependencies,
    );

    // Calculate costs
    final directCost = calculateTaskDelayCost(
      task: delayedTask,
      delayDays: delayDays,
    );

    // Calculate cascading cost for affected tasks
    double cascadingCost = 0;
    for (final entry in impact.taskDelayMap.entries) {
      final affectedTask = allTasks.firstWhere(
        (t) => t.id == entry.key,
        orElse: () => delayedTask,
      );
      final affectedCost = calculateTaskDelayCost(
        task: affectedTask,
        delayDays: entry.value,
      );
      cascadingCost += affectedCost.totalCost;
    }

    return {
      'impact': impact,
      'directCost': directCost,
      'cascadingCost': cascadingCost,
      'totalCost': directCost.totalCost + cascadingCost,
      'affectedTaskCount': impact.affectedTaskIds.length,
      'projectDelayDays': impact.projectDelayDays,
    };
  }

  // ============== Material Alert Deadline Calculation ==============

  /// Calculate order deadline with configurable buffer
  DateTime calculateOrderDeadline({
    required DateTime taskStartDate,
    required int leadTimeDays,
  }) {
    return taskStartDate.subtract(
      Duration(days: leadTimeDays + _alertConfig.bufferDays),
    );
  }

  /// Get days until order deadline
  int getDaysUntilOrderDeadline({
    required DateTime taskStartDate,
    required int leadTimeDays,
  }) {
    final deadline = calculateOrderDeadline(
      taskStartDate: taskStartDate,
      leadTimeDays: leadTimeDays,
    );
    return deadline.difference(DateTime.now()).inDays;
  }

  /// Get alert severity based on days until deadline
  AlertSeverity getAlertSeverity(int daysUntilDeadline) {
    if (daysUntilDeadline < 0) {
      return AlertSeverity.critical;
    } else if (daysUntilDeadline <= _alertConfig.highThresholdDays) {
      return AlertSeverity.high;
    } else if (daysUntilDeadline <= _alertConfig.mediumThresholdDays) {
      return AlertSeverity.medium;
    }
    return AlertSeverity.low;
  }

  /// Check if material needs ordering soon
  bool needsOrderingSoon({
    required DateTime taskStartDate,
    required int leadTimeDays,
  }) {
    final daysUntil = getDaysUntilOrderDeadline(
      taskStartDate: taskStartDate,
      leadTimeDays: leadTimeDays,
    );
    return daysUntil <= _alertConfig.mediumThresholdDays;
  }

  // ============== Export/Import ==============

  Map<String, dynamic> toJson() => {
        'alertConfig': _alertConfig.toJson(),
        'laborConfigs': _laborConfigs.map(
          (k, v) => MapEntry(k, v.toJson()),
        ),
      };

  void fromJson(Map<String, dynamic> json) {
    if (json['alertConfig'] != null) {
      _alertConfig = AlertThresholdConfig.fromJson(
        json['alertConfig'] as Map<String, dynamic>,
      );
    }
    if (json['laborConfigs'] != null) {
      final configs = json['laborConfigs'] as Map<String, dynamic>;
      _laborConfigs = configs.map(
        (k, v) => MapEntry(
          k,
          TaskLaborConfig.fromJson(v as Map<String, dynamic>),
        ),
      );
    }
    notifyListeners();
  }
}
