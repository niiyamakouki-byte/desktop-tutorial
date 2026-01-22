import 'user_model.dart';

/// Task model for construction project tasks displayed in Gantt chart
class Task {
  final String id;
  final String projectId;
  final String name;
  final String? description;
  final DateTime startDate;
  final DateTime endDate;
  final double progress;
  final String status;
  final String priority;
  final String category;
  final String? parentId;
  final List<String> dependsOn;
  final List<User> assignees;
  final bool isExpanded;
  final bool isMilestone;
  final int level;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// フェーズID（バトンパス方式の工程管理用）
  final String? phaseId;

  /// 担当業者名
  final String? contractorName;

  const Task({
    required this.id,
    required this.projectId,
    required this.name,
    this.description,
    required this.startDate,
    required this.endDate,
    this.progress = 0.0,
    required this.status,
    this.priority = 'medium',
    required this.category,
    this.parentId,
    this.dependsOn = const [],
    this.assignees = const [],
    this.isExpanded = true,
    this.isMilestone = false,
    this.level = 0,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.phaseId,
    this.contractorName,
  });

  Task copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? progress,
    String? status,
    String? priority,
    String? category,
    String? parentId,
    List<String>? dependsOn,
    List<User>? assignees,
    bool? isExpanded,
    bool? isMilestone,
    int? level,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? phaseId,
    String? contractorName,
  }) {
    return Task(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      parentId: parentId ?? this.parentId,
      dependsOn: dependsOn ?? this.dependsOn,
      assignees: assignees ?? this.assignees,
      isExpanded: isExpanded ?? this.isExpanded,
      isMilestone: isMilestone ?? this.isMilestone,
      level: level ?? this.level,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      phaseId: phaseId ?? this.phaseId,
      contractorName: contractorName ?? this.contractorName,
    );
  }

  int get durationDays => endDate.difference(startDate).inDays + 1;

  bool get isOverdue {
    return status != 'completed' && DateTime.now().isAfter(endDate);
  }

  bool get hasChildren => false; // Will be computed dynamically

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'projectId': projectId,
      'name': name,
      'description': description,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'progress': progress,
      'status': status,
      'priority': priority,
      'category': category,
      'parentId': parentId,
      'dependsOn': dependsOn,
      'assignees': assignees.map((a) => a.toJson()).toList(),
      'isExpanded': isExpanded,
      'isMilestone': isMilestone,
      'level': level,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'phaseId': phaseId,
      'contractorName': contractorName,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String,
      priority: json['priority'] as String? ?? 'medium',
      category: json['category'] as String,
      parentId: json['parentId'] as String?,
      dependsOn: (json['dependsOn'] as List?)?.cast<String>() ?? [],
      assignees: (json['assignees'] as List?)
              ?.map((a) => User.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      isExpanded: json['isExpanded'] as bool? ?? true,
      isMilestone: json['isMilestone'] as bool? ?? false,
      level: json['level'] as int? ?? 0,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      phaseId: json['phaseId'] as String?,
      contractorName: json['contractorName'] as String?,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Task category for construction projects
class TaskCategory {
  static const String foundation = 'foundation';
  static const String structure = 'structure';
  static const String electrical = 'electrical';
  static const String plumbing = 'plumbing';
  static const String finishing = 'finishing';
  static const String inspection = 'inspection';
  static const String general = 'general';

  static const Map<String, String> labels = {
    foundation: '基礎工事',
    structure: '構造',
    electrical: '電気設備',
    plumbing: '配管',
    finishing: '仕上げ',
    inspection: '検査',
    general: '一般',
  };

  static String getLabel(String category) {
    return labels[category] ?? category;
  }
}

/// Extension to handle task tree operations
extension TaskTreeExtension on List<Task> {
  List<Task> getChildren(String? parentId) {
    return where((task) => task.parentId == parentId).toList();
  }

  List<Task> getVisibleTasks() {
    final result = <Task>[];
    final expandedIds = <String>{};

    // First pass: collect expanded task IDs
    for (final task in this) {
      if (task.isExpanded) {
        expandedIds.add(task.id);
      }
    }

    // Second pass: add visible tasks
    void addVisibleChildren(String? parentId) {
      for (final task in where((t) => t.parentId == parentId)) {
        result.add(task);
        if (task.isExpanded) {
          addVisibleChildren(task.id);
        }
      }
    }

    addVisibleChildren(null);
    return result;
  }

  bool hasChildren(String taskId) {
    return any((task) => task.parentId == taskId);
  }
}
