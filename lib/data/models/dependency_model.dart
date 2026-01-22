/// Dependency Model for Task Scheduling
/// Supports FS/SS/FF/SF dependency types with lag/lead time

/// Dependency type enumeration
/// FS: Finish-to-Start (most common - successor starts after predecessor finishes)
/// SS: Start-to-Start (successor starts when predecessor starts)
/// FF: Finish-to-Finish (successor finishes when predecessor finishes)
/// SF: Start-to-Finish (successor finishes when predecessor starts)
enum DependencyType {
  fs, // Finish-to-Start (デフォルト)
  ss, // Start-to-Start
  ff, // Finish-to-Finish
  sf, // Start-to-Finish
}

extension DependencyTypeExtension on DependencyType {
  String get label {
    switch (this) {
      case DependencyType.fs:
        return 'FS (終了→開始)';
      case DependencyType.ss:
        return 'SS (開始→開始)';
      case DependencyType.ff:
        return 'FF (終了→終了)';
      case DependencyType.sf:
        return 'SF (開始→終了)';
    }
  }

  String get shortLabel {
    switch (this) {
      case DependencyType.fs:
        return 'FS';
      case DependencyType.ss:
        return 'SS';
      case DependencyType.ff:
        return 'FF';
      case DependencyType.sf:
        return 'SF';
    }
  }

  String get description {
    switch (this) {
      case DependencyType.fs:
        return '先行タスク完了後に開始';
      case DependencyType.ss:
        return '先行タスク開始と同時に開始';
      case DependencyType.ff:
        return '先行タスク完了と同時に完了';
      case DependencyType.sf:
        return '先行タスク開始と同時に完了';
    }
  }

  static DependencyType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'fs':
        return DependencyType.fs;
      case 'ss':
        return DependencyType.ss;
      case 'ff':
        return DependencyType.ff;
      case 'sf':
        return DependencyType.sf;
      default:
        return DependencyType.fs;
    }
  }
}

/// Represents a dependency between two tasks
class TaskDependency {
  final String id;
  final String fromTaskId;     // 先行タスク (predecessor)
  final String toTaskId;       // 後続タスク (successor)
  final DependencyType type;   // 依存関係タイプ
  final int lagDays;           // ラグ日数 (正: 遅延, 負: リード)

  const TaskDependency({
    required this.id,
    required this.fromTaskId,
    required this.toTaskId,
    this.type = DependencyType.fs,
    this.lagDays = 0,
  });

  TaskDependency copyWith({
    String? id,
    String? fromTaskId,
    String? toTaskId,
    DependencyType? type,
    int? lagDays,
  }) {
    return TaskDependency(
      id: id ?? this.id,
      fromTaskId: fromTaskId ?? this.fromTaskId,
      toTaskId: toTaskId ?? this.toTaskId,
      type: type ?? this.type,
      lagDays: lagDays ?? this.lagDays,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fromTaskId': fromTaskId,
      'toTaskId': toTaskId,
      'type': type.shortLabel,
      'lagDays': lagDays,
    };
  }

  factory TaskDependency.fromJson(Map<String, dynamic> json) {
    return TaskDependency(
      id: json['id'] as String,
      fromTaskId: json['fromTaskId'] as String,
      toTaskId: json['toTaskId'] as String,
      type: DependencyTypeExtension.fromString(json['type'] as String? ?? 'fs'),
      lagDays: json['lagDays'] as int? ?? 0,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskDependency &&
        other.id == id &&
        other.fromTaskId == fromTaskId &&
        other.toTaskId == toTaskId &&
        other.type == type &&
        other.lagDays == lagDays;
  }

  @override
  int get hashCode =>
      id.hashCode ^
      fromTaskId.hashCode ^
      toTaskId.hashCode ^
      type.hashCode ^
      lagDays.hashCode;

  @override
  String toString() =>
      'TaskDependency($fromTaskId -> $toTaskId, ${type.shortLabel}, lag: $lagDays)';
}

/// Result of schedule calculation for a single task
class ScheduleResult {
  final String taskId;
  final DateTime earliestStart;    // 最早開始日
  final DateTime earliestFinish;   // 最早終了日
  final DateTime latestStart;      // 最遅開始日
  final DateTime latestFinish;     // 最遅終了日
  final int totalFloat;            // 全余裕日数 (トータルフロート)
  final int freeFloat;             // 自由余裕日数 (フリーフロート)
  final bool isCritical;           // クリティカルパス上か

  const ScheduleResult({
    required this.taskId,
    required this.earliestStart,
    required this.earliestFinish,
    required this.latestStart,
    required this.latestFinish,
    required this.totalFloat,
    required this.freeFloat,
    required this.isCritical,
  });

  @override
  String toString() =>
      'Schedule($taskId: ES=${earliestStart.day}, EF=${earliestFinish.day}, '
      'LS=${latestStart.day}, LF=${latestFinish.day}, TF=$totalFloat, critical=$isCritical)';
}

/// Impact analysis when a task is delayed
class DelayImpact {
  final String taskId;
  final int delayDays;                      // 遅延日数
  final List<String> affectedTaskIds;       // 影響を受けるタスクID
  final int projectDelayDays;               // プロジェクト全体の遅延日数
  final Map<String, int> taskDelayMap;      // 各タスクの遅延日数

  const DelayImpact({
    required this.taskId,
    required this.delayDays,
    required this.affectedTaskIds,
    required this.projectDelayDays,
    required this.taskDelayMap,
  });

  bool get hasProjectImpact => projectDelayDays > 0;
  bool get hasAnyImpact => affectedTaskIds.isNotEmpty;
}

/// Circular dependency error
class CircularDependencyException implements Exception {
  final List<String> cycle;
  final String message;

  CircularDependencyException(this.cycle)
      : message = 'Circular dependency detected: ${cycle.join(' -> ')}';

  @override
  String toString() => message;
}
