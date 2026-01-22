import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'user_model.dart';

/// 変更されたフィールドの種類
enum TaskFieldType {
  name('name', 'タスク名', Icons.title),
  description('description', '説明', Icons.description),
  startDate('startDate', '開始日', Icons.event),
  endDate('endDate', '終了日', Icons.event_available),
  progress('progress', '進捗', Icons.trending_up),
  status('status', 'ステータス', Icons.flag),
  priority('priority', '優先度', Icons.priority_high),
  assignees('assignees', '担当者', Icons.people),
  contractorName('contractorName', '担当業者', Icons.business),
  assigneeName('assigneeName', '担当者名', Icons.person),
  blockingReason('blockingReason', '待ち理由', Icons.hourglass_empty),
  dependencies('dependencies', '依存関係', Icons.link),
  phaseId('phaseId', 'フェーズ', Icons.category),
  notes('notes', 'メモ', Icons.note),
  other('other', 'その他', Icons.more_horiz);

  final String value;
  final String displayName;
  final IconData icon;

  const TaskFieldType(this.value, this.displayName, this.icon);

  static TaskFieldType fromString(String value) {
    return TaskFieldType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TaskFieldType.other,
    );
  }
}

/// 個別のフィールド変更
@immutable
class FieldChange {
  /// 変更されたフィールド
  final TaskFieldType field;

  /// 変更前の値（JSON表現）
  final dynamic oldValue;

  /// 変更後の値（JSON表現）
  final dynamic newValue;

  const FieldChange({
    required this.field,
    this.oldValue,
    this.newValue,
  });

  factory FieldChange.fromJson(Map<String, dynamic> json) {
    return FieldChange(
      field: TaskFieldType.fromString(json['field'] as String),
      oldValue: json['oldValue'],
      newValue: json['newValue'],
    );
  }

  Map<String, dynamic> toJson() => {
        'field': field.value,
        'oldValue': oldValue,
        'newValue': newValue,
      };

  /// 表示用の変更テキスト
  String get displayText {
    switch (field) {
      case TaskFieldType.startDate:
      case TaskFieldType.endDate:
        return '${_formatDate(oldValue)} → ${_formatDate(newValue)}';
      case TaskFieldType.progress:
        return '${_formatProgress(oldValue)} → ${_formatProgress(newValue)}';
      case TaskFieldType.status:
        return '${_getStatusLabel(oldValue)} → ${_getStatusLabel(newValue)}';
      case TaskFieldType.priority:
        return '${_getPriorityLabel(oldValue)} → ${_getPriorityLabel(newValue)}';
      default:
        final oldStr = oldValue?.toString() ?? '(なし)';
        final newStr = newValue?.toString() ?? '(なし)';
        return '$oldStr → $newStr';
    }
  }

  /// 短縮表示テキスト
  String get shortDisplayText {
    switch (field) {
      case TaskFieldType.startDate:
      case TaskFieldType.endDate:
        return _formatDate(newValue);
      case TaskFieldType.progress:
        return _formatProgress(newValue);
      case TaskFieldType.status:
        return _getStatusLabel(newValue);
      default:
        return newValue?.toString() ?? '';
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return '(なし)';
    try {
      final date = DateTime.parse(value.toString());
      return '${date.month}/${date.day}';
    } catch (_) {
      return value.toString();
    }
  }

  String _formatProgress(dynamic value) {
    if (value == null) return '0%';
    final progress = (value as num).toDouble();
    return '${(progress * 100).toInt()}%';
  }

  String _getStatusLabel(dynamic value) {
    const statusLabels = {
      'not_started': '未着手',
      'in_progress': '進行中',
      'completed': '完了',
      'on_hold': '保留',
    };
    return statusLabels[value?.toString()] ?? value?.toString() ?? '不明';
  }

  String _getPriorityLabel(dynamic value) {
    const priorityLabels = {
      'low': '低',
      'medium': '中',
      'high': '高',
      'urgent': '緊急',
    };
    return priorityLabels[value?.toString()] ?? value?.toString() ?? '中';
  }
}

/// タスク変更履歴モデル
///
/// 誰がいつ何を変えたかを記録する
@immutable
class TaskChangeHistory {
  /// 履歴ID
  final String id;

  /// 対象タスクID
  final String taskId;

  /// プロジェクトID
  final String projectId;

  /// 変更を行ったユーザー
  final User? changedBy;

  /// 変更を行ったユーザーID（userがnullの場合の参照用）
  final String changedByUserId;

  /// 変更日時
  final DateTime changedAt;

  /// 変更種別
  final ChangeType changeType;

  /// 変更されたフィールド一覧
  final List<FieldChange> changes;

  /// 変更理由（任意）
  final String? reason;

  /// コメント（任意）
  final String? comment;

  /// デバイス情報（モバイル/PC等）
  final String? deviceInfo;

  const TaskChangeHistory({
    required this.id,
    required this.taskId,
    required this.projectId,
    this.changedBy,
    required this.changedByUserId,
    required this.changedAt,
    required this.changeType,
    required this.changes,
    this.reason,
    this.comment,
    this.deviceInfo,
  });

  factory TaskChangeHistory.fromJson(Map<String, dynamic> json) {
    return TaskChangeHistory(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      projectId: json['projectId'] as String,
      changedBy: json['changedBy'] != null
          ? User.fromJson(json['changedBy'] as Map<String, dynamic>)
          : null,
      changedByUserId: json['changedByUserId'] as String,
      changedAt: DateTime.parse(json['changedAt'] as String),
      changeType: ChangeType.fromString(json['changeType'] as String),
      changes: (json['changes'] as List<dynamic>?)
              ?.map((e) => FieldChange.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reason: json['reason'] as String?,
      comment: json['comment'] as String?,
      deviceInfo: json['deviceInfo'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskId': taskId,
        'projectId': projectId,
        'changedBy': changedBy?.toJson(),
        'changedByUserId': changedByUserId,
        'changedAt': changedAt.toIso8601String(),
        'changeType': changeType.value,
        'changes': changes.map((e) => e.toJson()).toList(),
        'reason': reason,
        'comment': comment,
        'deviceInfo': deviceInfo,
      };

  /// 変更者の表示名
  String get changedByName =>
      changedBy?.name ?? '不明なユーザー';

  /// 相対時間表示（〇分前、〇時間前等）
  String get timeAgo {
    final diff = DateTime.now().difference(changedAt);
    if (diff.inSeconds < 60) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    if (diff.inDays < 7) return '${diff.inDays}日前';
    return '${changedAt.month}/${changedAt.day}';
  }

  /// 変更サマリー（1行表示用）
  String get summary {
    if (changeType == ChangeType.created) {
      return 'タスクを作成しました';
    }
    if (changeType == ChangeType.deleted) {
      return 'タスクを削除しました';
    }
    if (changes.isEmpty) {
      return '${changeType.displayName}しました';
    }
    if (changes.length == 1) {
      return '${changes.first.field.displayName}を変更しました';
    }
    return '${changes.length}項目を変更しました';
  }

  /// 詳細サマリー（複数行表示用）
  List<String> get detailedSummary {
    if (changeType == ChangeType.created) {
      return ['タスクを作成しました'];
    }
    if (changeType == ChangeType.deleted) {
      return ['タスクを削除しました'];
    }
    return changes.map((c) => '${c.field.displayName}: ${c.displayText}').toList();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskChangeHistory && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// 変更種別
enum ChangeType {
  created('created', '作成'),
  updated('updated', '更新'),
  deleted('deleted', '削除'),
  statusChange('status_change', 'ステータス変更'),
  scheduleChange('schedule_change', '日程変更'),
  progressChange('progress_change', '進捗更新'),
  assigneeChange('assignee_change', '担当者変更'),
  dragDrop('drag_drop', 'ドラッグ移動');

  final String value;
  final String displayName;

  const ChangeType(this.value, this.displayName);

  static ChangeType fromString(String value) {
    return ChangeType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ChangeType.updated,
    );
  }

  IconData get icon {
    switch (this) {
      case ChangeType.created:
        return Icons.add_circle;
      case ChangeType.updated:
        return Icons.edit;
      case ChangeType.deleted:
        return Icons.delete;
      case ChangeType.statusChange:
        return Icons.flag;
      case ChangeType.scheduleChange:
        return Icons.calendar_today;
      case ChangeType.progressChange:
        return Icons.trending_up;
      case ChangeType.assigneeChange:
        return Icons.person;
      case ChangeType.dragDrop:
        return Icons.open_with;
    }
  }

  Color get color {
    switch (this) {
      case ChangeType.created:
        return const Color(0xFF4CAF50);
      case ChangeType.updated:
        return const Color(0xFF2196F3);
      case ChangeType.deleted:
        return const Color(0xFFF44336);
      case ChangeType.statusChange:
        return const Color(0xFFFF9800);
      case ChangeType.scheduleChange:
        return const Color(0xFF9C27B0);
      case ChangeType.progressChange:
        return const Color(0xFF00BCD4);
      case ChangeType.assigneeChange:
        return const Color(0xFFE91E63);
      case ChangeType.dragDrop:
        return const Color(0xFF607D8B);
    }
  }
}

/// 変更履歴フィルター
class ChangeHistoryFilter {
  final List<ChangeType>? changeTypes;
  final List<TaskFieldType>? fieldTypes;
  final String? userId;
  final DateTime? fromDate;
  final DateTime? toDate;

  const ChangeHistoryFilter({
    this.changeTypes,
    this.fieldTypes,
    this.userId,
    this.fromDate,
    this.toDate,
  });

  bool matches(TaskChangeHistory history) {
    if (changeTypes != null &&
        changeTypes!.isNotEmpty &&
        !changeTypes!.contains(history.changeType)) {
      return false;
    }
    if (userId != null && history.changedByUserId != userId) {
      return false;
    }
    if (fromDate != null && history.changedAt.isBefore(fromDate!)) {
      return false;
    }
    if (toDate != null && history.changedAt.isAfter(toDate!)) {
      return false;
    }
    if (fieldTypes != null && fieldTypes!.isNotEmpty) {
      final historyFields = history.changes.map((c) => c.field).toSet();
      if (!fieldTypes!.any((f) => historyFields.contains(f))) {
        return false;
      }
    }
    return true;
  }
}

/// 変更履歴のグループ化ユーティリティ
extension TaskChangeHistoryListExtension on List<TaskChangeHistory> {
  /// 日付でグループ化
  Map<String, List<TaskChangeHistory>> groupByDate() {
    final result = <String, List<TaskChangeHistory>>{};
    for (final history in this) {
      final dateKey =
          '${history.changedAt.year}-${history.changedAt.month.toString().padLeft(2, '0')}-${history.changedAt.day.toString().padLeft(2, '0')}';
      result.putIfAbsent(dateKey, () => []).add(history);
    }
    return result;
  }

  /// ユーザーでグループ化
  Map<String, List<TaskChangeHistory>> groupByUser() {
    final result = <String, List<TaskChangeHistory>>{};
    for (final history in this) {
      result.putIfAbsent(history.changedByUserId, () => []).add(history);
    }
    return result;
  }

  /// フィルタ適用
  List<TaskChangeHistory> applyFilter(ChangeHistoryFilter filter) {
    return where((h) => filter.matches(h)).toList();
  }

  /// 最新N件を取得
  List<TaskChangeHistory> latest(int count) {
    final sorted = [...this]
      ..sort((a, b) => b.changedAt.compareTo(a.changedAt));
    return sorted.take(count).toList();
  }
}
