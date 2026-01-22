/// Project Health & Cost Analysis Models
/// プロジェクト健全性と遅延コスト分析モデル

import 'task_model.dart';

/// Alert threshold configuration for material orders
/// 発注アラートの閾値設定
class AlertThresholdConfig {
  /// Days before deadline to trigger medium alert (default: 7)
  final int mediumThresholdDays;

  /// Days before deadline to trigger high alert (default: 3)
  final int highThresholdDays;

  /// Buffer days to add to lead time (default: 2)
  final int bufferDays;

  const AlertThresholdConfig({
    this.mediumThresholdDays = 7,
    this.highThresholdDays = 3,
    this.bufferDays = 2,
  });

  /// Copy with modified values
  AlertThresholdConfig copyWith({
    int? mediumThresholdDays,
    int? highThresholdDays,
    int? bufferDays,
  }) {
    return AlertThresholdConfig(
      mediumThresholdDays: mediumThresholdDays ?? this.mediumThresholdDays,
      highThresholdDays: highThresholdDays ?? this.highThresholdDays,
      bufferDays: bufferDays ?? this.bufferDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'mediumThresholdDays': mediumThresholdDays,
        'highThresholdDays': highThresholdDays,
        'bufferDays': bufferDays,
      };

  factory AlertThresholdConfig.fromJson(Map<String, dynamic> json) {
    return AlertThresholdConfig(
      mediumThresholdDays: json['mediumThresholdDays'] as int? ?? 7,
      highThresholdDays: json['highThresholdDays'] as int? ?? 3,
      bufferDays: json['bufferDays'] as int? ?? 2,
    );
  }
}

/// Task labor cost configuration
/// タスクの労務費設定
class TaskLaborConfig {
  final String taskId;
  final double estimatedHours;
  final double actualHours;
  final double hourlyRate; // ¥/hour

  const TaskLaborConfig({
    required this.taskId,
    this.estimatedHours = 0,
    this.actualHours = 0,
    this.hourlyRate = 15000, // Default: ¥15,000/hour (typical construction rate)
  });

  double get estimatedCost => estimatedHours * hourlyRate;
  double get actualCost => actualHours * hourlyRate;
  double get costVariance => actualCost - estimatedCost;

  /// Calculate delay cost for given days
  double calculateDelayCost(int delayDays, {int workersPerDay = 3}) {
    // Delay cost = workers × hours per day × hourly rate × delay days
    const hoursPerDay = 8.0;
    return workersPerDay * hoursPerDay * hourlyRate * delayDays;
  }

  TaskLaborConfig copyWith({
    String? taskId,
    double? estimatedHours,
    double? actualHours,
    double? hourlyRate,
  }) {
    return TaskLaborConfig(
      taskId: taskId ?? this.taskId,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      actualHours: actualHours ?? this.actualHours,
      hourlyRate: hourlyRate ?? this.hourlyRate,
    );
  }

  Map<String, dynamic> toJson() => {
        'taskId': taskId,
        'estimatedHours': estimatedHours,
        'actualHours': actualHours,
        'hourlyRate': hourlyRate,
      };

  factory TaskLaborConfig.fromJson(Map<String, dynamic> json) {
    return TaskLaborConfig(
      taskId: json['taskId'] as String,
      estimatedHours: (json['estimatedHours'] as num?)?.toDouble() ?? 0,
      actualHours: (json['actualHours'] as num?)?.toDouble() ?? 0,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 15000,
    );
  }
}

/// Project health score breakdown
/// プロジェクト健全性スコアの内訳
class ProjectHealthScore {
  /// Overall health score (0-100)
  final double overallScore;

  /// Schedule health score (0-100)
  final double scheduleScore;

  /// Cost health score (0-100)
  final double costScore;

  /// Resource health score (0-100)
  final double resourceScore;

  /// Risk health score (0-100)
  final double riskScore;

  /// Critical path progress percentage
  final double criticalPathProgress;

  /// Number of delayed tasks
  final int delayedTaskCount;

  /// Total delay days across all tasks
  final int totalDelayDays;

  /// Estimated delay cost in yen
  final double estimatedDelayCost;

  /// Number of pending material orders
  final int pendingOrderCount;

  /// Number of critical alerts
  final int criticalAlertCount;

  /// Health status description
  final HealthStatus status;

  /// Timestamp
  final DateTime calculatedAt;

  const ProjectHealthScore({
    required this.overallScore,
    required this.scheduleScore,
    required this.costScore,
    required this.resourceScore,
    required this.riskScore,
    required this.criticalPathProgress,
    required this.delayedTaskCount,
    required this.totalDelayDays,
    required this.estimatedDelayCost,
    required this.pendingOrderCount,
    required this.criticalAlertCount,
    required this.status,
    required this.calculatedAt,
  });

  /// Get health status from overall score
  static HealthStatus getStatusFromScore(double score) {
    if (score >= 80) return HealthStatus.excellent;
    if (score >= 60) return HealthStatus.good;
    if (score >= 40) return HealthStatus.warning;
    if (score >= 20) return HealthStatus.critical;
    return HealthStatus.emergency;
  }

  /// Calculate weighted average
  static double calculateWeightedScore({
    required double scheduleScore,
    required double costScore,
    required double resourceScore,
    required double riskScore,
  }) {
    // Weights: Schedule 40%, Cost 25%, Resource 15%, Risk 20%
    return scheduleScore * 0.40 +
        costScore * 0.25 +
        resourceScore * 0.15 +
        riskScore * 0.20;
  }

  Map<String, dynamic> toJson() => {
        'overallScore': overallScore,
        'scheduleScore': scheduleScore,
        'costScore': costScore,
        'resourceScore': resourceScore,
        'riskScore': riskScore,
        'criticalPathProgress': criticalPathProgress,
        'delayedTaskCount': delayedTaskCount,
        'totalDelayDays': totalDelayDays,
        'estimatedDelayCost': estimatedDelayCost,
        'pendingOrderCount': pendingOrderCount,
        'criticalAlertCount': criticalAlertCount,
        'status': status.name,
        'calculatedAt': calculatedAt.toIso8601String(),
      };
}

/// Health status enum
enum HealthStatus {
  excellent, // 80-100: Green, excellent condition
  good, // 60-79: Blue, good but needs monitoring
  warning, // 40-59: Yellow, issues detected
  critical, // 20-39: Orange, significant problems
  emergency, // 0-19: Red, immediate action required
}

extension HealthStatusExtension on HealthStatus {
  String get label {
    switch (this) {
      case HealthStatus.excellent:
        return '優良';
      case HealthStatus.good:
        return '良好';
      case HealthStatus.warning:
        return '注意';
      case HealthStatus.critical:
        return '警告';
      case HealthStatus.emergency:
        return '緊急';
    }
  }

  String get description {
    switch (this) {
      case HealthStatus.excellent:
        return 'プロジェクトは順調に進行しています';
      case HealthStatus.good:
        return '概ね良好ですが、一部注意が必要です';
      case HealthStatus.warning:
        return '複数の課題が発生しています';
      case HealthStatus.critical:
        return '重大な問題が発生しています';
      case HealthStatus.emergency:
        return '緊急対応が必要です';
    }
  }
}

/// Delay cost breakdown by category
class DelayCostBreakdown {
  final double laborCost;
  final double equipmentCost;
  final double materialStorageCost;
  final double overheadCost;
  final double penaltyCost;
  final int delayDays;

  const DelayCostBreakdown({
    required this.laborCost,
    required this.equipmentCost,
    required this.materialStorageCost,
    required this.overheadCost,
    required this.penaltyCost,
    required this.delayDays,
  });

  double get totalCost =>
      laborCost + equipmentCost + materialStorageCost + overheadCost + penaltyCost;

  double get dailyRate => delayDays > 0 ? totalCost / delayDays : 0;

  /// Create from delay calculation with default rates
  factory DelayCostBreakdown.calculate({
    required int delayDays,
    int workers = 5,
    double hourlyRate = 15000,
    double equipmentDailyRate = 50000,
    double storageDailyRate = 10000,
    double overheadDailyRate = 30000,
    double penaltyDailyRate = 0,
  }) {
    const hoursPerDay = 8.0;
    return DelayCostBreakdown(
      laborCost: workers * hoursPerDay * hourlyRate * delayDays,
      equipmentCost: equipmentDailyRate * delayDays,
      materialStorageCost: storageDailyRate * delayDays,
      overheadCost: overheadDailyRate * delayDays,
      penaltyCost: penaltyDailyRate * delayDays,
      delayDays: delayDays,
    );
  }

  Map<String, dynamic> toJson() => {
        'laborCost': laborCost,
        'equipmentCost': equipmentCost,
        'materialStorageCost': materialStorageCost,
        'overheadCost': overheadCost,
        'penaltyCost': penaltyCost,
        'totalCost': totalCost,
        'delayDays': delayDays,
        'dailyRate': dailyRate,
      };
}

/// Critical path progress tracking
class CriticalPathProgress {
  final List<CriticalPathTask> tasks;
  final double overallProgress;
  final int completedTasks;
  final int totalTasks;
  final int delayedTasks;
  final DateTime? earliestCompletion;
  final DateTime? latestCompletion;

  const CriticalPathProgress({
    required this.tasks,
    required this.overallProgress,
    required this.completedTasks,
    required this.totalTasks,
    required this.delayedTasks,
    this.earliestCompletion,
    this.latestCompletion,
  });

  bool get isOnTrack => delayedTasks == 0;
  int get remainingTasks => totalTasks - completedTasks;
}

/// Individual critical path task info
class CriticalPathTask {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final double progress;
  final bool isDelayed;
  final int delayDays;
  final int order;

  const CriticalPathTask({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.progress,
    required this.isDelayed,
    required this.delayDays,
    required this.order,
  });

  factory CriticalPathTask.fromTask(Task task, int order, {int delayDays = 0}) {
    return CriticalPathTask(
      id: task.id,
      name: task.name,
      startDate: task.startDate,
      endDate: task.endDate,
      progress: task.progress,
      isDelayed: task.isOverdue || delayDays > 0,
      delayDays: delayDays,
      order: order,
    );
  }
}
