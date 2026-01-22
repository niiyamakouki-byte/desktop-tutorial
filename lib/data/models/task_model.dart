import 'package:flutter/material.dart';
import 'user_model.dart';

/// 遅延ステータス（3層）
enum DelayStatus {
  /// 順調（問題なし）
  onTrack('on_track', '順調', Color(0xFF4CAF50), Icons.check_circle),

  /// リスク（期限間近＋進捗不足）
  atRisk('at_risk', 'リスク', Color(0xFFFFC107), Icons.access_time),

  /// 待ち状態（何かを待っている）
  blocked('blocked', '待ち', Color(0xFFFF9800), Icons.hourglass_empty),

  /// 超過（期日を過ぎて未完了）
  overdue('overdue', '超過', Color(0xFFF44336), Icons.warning);

  final String value;
  final String displayName;
  final Color color;
  final IconData icon;

  const DelayStatus(this.value, this.displayName, this.color, this.icon);

  static DelayStatus fromString(String value) {
    return DelayStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DelayStatus.onTrack,
    );
  }
}

/// 待ち理由
enum BlockingReason {
  /// 前工程待ち
  predecessor('predecessor', '前工程待ち', Icons.schedule),

  /// 材料待ち
  material('material', '材料待ち', Icons.inventory),

  /// 承認待ち
  approval('approval', '承認待ち', Icons.approval),

  /// 施主確認待ち
  clientConfirmation('client_confirmation', '施主確認待ち', Icons.person),

  /// 天候待ち
  weather('weather', '天候待ち', Icons.cloud),

  /// 検査待ち
  inspection('inspection', '検査待ち', Icons.fact_check),

  /// その他
  other('other', 'その他', Icons.more_horiz);

  final String value;
  final String displayName;
  final IconData icon;

  const BlockingReason(this.value, this.displayName, this.icon);

  static BlockingReason fromString(String value) {
    return BlockingReason.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BlockingReason.other,
    );
  }
}

/// 添付状況
class AttachmentStatus {
  /// 図面あり
  final bool hasDrawing;

  /// 最新図面か
  final bool isLatestDrawing;

  /// 写真数
  final int photoCount;

  /// 今日追加した写真数
  final int todayPhotoCount;

  /// 未読コメント数
  final int unreadComments;

  /// 要対応コメントあり
  final bool hasActionRequired;

  const AttachmentStatus({
    this.hasDrawing = false,
    this.isLatestDrawing = false,
    this.photoCount = 0,
    this.todayPhotoCount = 0,
    this.unreadComments = 0,
    this.hasActionRequired = false,
  });

  factory AttachmentStatus.fromJson(Map<String, dynamic> json) {
    return AttachmentStatus(
      hasDrawing: json['hasDrawing'] as bool? ?? false,
      isLatestDrawing: json['isLatestDrawing'] as bool? ?? false,
      photoCount: json['photoCount'] as int? ?? 0,
      todayPhotoCount: json['todayPhotoCount'] as int? ?? 0,
      unreadComments: json['unreadComments'] as int? ?? 0,
      hasActionRequired: json['hasActionRequired'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'hasDrawing': hasDrawing,
        'isLatestDrawing': isLatestDrawing,
        'photoCount': photoCount,
        'todayPhotoCount': todayPhotoCount,
        'unreadComments': unreadComments,
        'hasActionRequired': hasActionRequired,
      };

  /// 何かしらの添付があるか
  bool get hasAny =>
      hasDrawing || photoCount > 0 || unreadComments > 0;
}

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

  /// 担当者名（個人名）
  final String? assigneeName;

  /// 待ち理由（ブロックされている場合）
  final BlockingReason? blockingReason;

  /// 待ち理由の詳細
  final String? blockingDetails;

  /// 添付状況
  final AttachmentStatus attachmentStatus;

  /// 遅延理由（天候など）
  final String? delayReason;

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
    this.assigneeName,
    this.blockingReason,
    this.blockingDetails,
    this.attachmentStatus = const AttachmentStatus(),
    this.delayReason,
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
    String? assigneeName,
    BlockingReason? blockingReason,
    String? blockingDetails,
    AttachmentStatus? attachmentStatus,
    String? delayReason,
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
      assigneeName: assigneeName ?? this.assigneeName,
      blockingReason: blockingReason ?? this.blockingReason,
      blockingDetails: blockingDetails ?? this.blockingDetails,
      attachmentStatus: attachmentStatus ?? this.attachmentStatus,
      delayReason: delayReason ?? this.delayReason,
    );
  }

  int get durationDays => endDate.difference(startDate).inDays + 1;

  bool get isOverdue {
    return status != 'completed' && DateTime.now().isAfter(endDate);
  }

  /// 遅延ステータスを計算
  DelayStatus get delayStatus {
    if (status == 'completed') return DelayStatus.onTrack;

    // 超過チェック
    if (DateTime.now().isAfter(endDate)) {
      return DelayStatus.overdue;
    }

    // 待ちチェック
    if (blockingReason != null) {
      return DelayStatus.blocked;
    }

    // リスクチェック（期限まで3日以内 & 進捗70%未満）
    final daysUntilDue = endDate.difference(DateTime.now()).inDays;
    if (daysUntilDue <= 3 && progress < 0.7) {
      return DelayStatus.atRisk;
    }

    return DelayStatus.onTrack;
  }

  /// 超過日数（マイナスは残り日数）
  int get daysOverdue {
    return DateTime.now().difference(endDate).inDays;
  }

  /// 残り日数（マイナスは超過日数）
  int get daysRemaining {
    return endDate.difference(DateTime.now()).inDays;
  }

  /// 期限表示テキスト
  String get deadlineText {
    if (status == 'completed') return '完了';

    final days = daysRemaining;
    if (days < 0) {
      return '超過+${-days}日';
    } else if (days == 0) {
      return '今日まで';
    } else if (days == 1) {
      return '明日まで';
    } else {
      return '残り${days}日';
    }
  }

  /// 担当者表示テキスト
  String get assigneeDisplayText {
    if (contractorName != null && assigneeName != null) {
      return '$contractorName/$assigneeName';
    }
    return contractorName ?? assigneeName ?? '';
  }

  /// 今日のタスクか
  bool get isToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayEnd = today.add(const Duration(days: 1));
    return startDate.isBefore(todayEnd) && endDate.isAfter(today.subtract(const Duration(days: 1)));
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
      'assigneeName': assigneeName,
      'blockingReason': blockingReason?.value,
      'blockingDetails': blockingDetails,
      'attachmentStatus': attachmentStatus.toJson(),
      'delayReason': delayReason,
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
      assigneeName: json['assigneeName'] as String?,
      blockingReason: json['blockingReason'] != null
          ? BlockingReason.fromString(json['blockingReason'] as String)
          : null,
      blockingDetails: json['blockingDetails'] as String?,
      attachmentStatus: json['attachmentStatus'] != null
          ? AttachmentStatus.fromJson(json['attachmentStatus'] as Map<String, dynamic>)
          : const AttachmentStatus(),
      delayReason: json['delayReason'] as String?,
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
