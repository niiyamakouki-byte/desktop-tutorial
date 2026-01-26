import 'package:flutter/material.dart';

/// AIアクション種別
enum AIActionType {
  /// 警告（緊急度高）
  alert('alert', 'アラート', Color(0xFFF44336), Icons.warning_amber),

  /// 注意（中程度）
  warning('warning', '注意', Color(0xFFFF9800), Icons.info_outline),

  /// 提案（改善案）
  suggestion('suggestion', '提案', Color(0xFF2196F3), Icons.lightbulb_outline),

  /// 確認（要アクション）
  confirmation('confirmation', '確認', Color(0xFF9C27B0), Icons.help_outline);

  final String value;
  final String label;
  final Color color;
  final IconData icon;

  const AIActionType(this.value, this.label, this.color, this.icon);

  static AIActionType fromString(String value) {
    return AIActionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AIActionType.suggestion,
    );
  }
}

/// アクションの実行タイプ
enum ActionExecutionType {
  /// LINE送信
  sendLine('send_line', 'LINEで連絡'),

  /// 日程変更
  reschedule('reschedule', '日程変更'),

  /// 詳細確認
  viewDetails('view_details', '詳細確認'),

  /// 承認
  approve('approve', '承認'),

  /// 発注
  order('order', '発注'),

  /// 電話連絡
  call('call', '電話連絡'),

  /// カスタム
  custom('custom', 'カスタム');

  final String value;
  final String label;

  const ActionExecutionType(this.value, this.label);

  static ActionExecutionType fromString(String value) {
    return ActionExecutionType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ActionExecutionType.custom,
    );
  }

  IconData get icon {
    switch (this) {
      case ActionExecutionType.sendLine:
        return Icons.send;
      case ActionExecutionType.reschedule:
        return Icons.calendar_today;
      case ActionExecutionType.viewDetails:
        return Icons.visibility;
      case ActionExecutionType.approve:
        return Icons.check_circle;
      case ActionExecutionType.order:
        return Icons.shopping_cart;
      case ActionExecutionType.call:
        return Icons.phone;
      case ActionExecutionType.custom:
        return Icons.more_horiz;
    }
  }
}

/// AIアクションモデル
///
/// AIが提案する実行可能なアクションを表現
/// 現場監督がワンタップでアクションを起こせる
class AIAction {
  /// アクションID
  final String id;

  /// タイトル（短く明確に）
  final String title;

  /// 説明（状況の詳細）
  final String description;

  /// アクション種別
  final AIActionType type;

  /// アクションボタンのラベル
  final String actionLabel;

  /// アクション実行タイプ
  final ActionExecutionType executionType;

  /// アクション実行時のペイロード
  final Map<String, dynamic> actionPayload;

  /// 関連タスクID（あれば）
  final String? relatedTaskId;

  /// 関連業者名（あれば）
  final String? relatedVendorName;

  /// 生成日時
  final DateTime createdAt;

  /// 期限（緊急度判定用）
  final DateTime? deadline;

  /// 完了済みか
  final bool isCompleted;

  /// 却下済みか
  final bool isDismissed;

  /// 優先度（0-100、高いほど優先）
  final int priority;

  /// 影響額（金額関連の場合）
  final double? impactAmount;

  /// 影響日数（日程関連の場合）
  final int? impactDays;

  const AIAction({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.actionLabel,
    required this.executionType,
    this.actionPayload = const {},
    this.relatedTaskId,
    this.relatedVendorName,
    required this.createdAt,
    this.deadline,
    this.isCompleted = false,
    this.isDismissed = false,
    this.priority = 50,
    this.impactAmount,
    this.impactDays,
  });

  /// JSONからモデルを生成
  factory AIAction.fromJson(Map<String, dynamic> json) {
    return AIAction(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: AIActionType.fromString(json['type'] as String),
      actionLabel: json['actionLabel'] as String,
      executionType: ActionExecutionType.fromString(json['executionType'] as String),
      actionPayload: json['actionPayload'] as Map<String, dynamic>? ?? {},
      relatedTaskId: json['relatedTaskId'] as String?,
      relatedVendorName: json['relatedVendorName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isDismissed: json['isDismissed'] as bool? ?? false,
      priority: json['priority'] as int? ?? 50,
      impactAmount: (json['impactAmount'] as num?)?.toDouble(),
      impactDays: json['impactDays'] as int?,
    );
  }

  /// モデルをJSONに変換
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'type': type.value,
        'actionLabel': actionLabel,
        'executionType': executionType.value,
        'actionPayload': actionPayload,
        'relatedTaskId': relatedTaskId,
        'relatedVendorName': relatedVendorName,
        'createdAt': createdAt.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
        'isCompleted': isCompleted,
        'isDismissed': isDismissed,
        'priority': priority,
        'impactAmount': impactAmount,
        'impactDays': impactDays,
      };

  /// コピーを作成
  AIAction copyWith({
    String? id,
    String? title,
    String? description,
    AIActionType? type,
    String? actionLabel,
    ActionExecutionType? executionType,
    Map<String, dynamic>? actionPayload,
    String? relatedTaskId,
    String? relatedVendorName,
    DateTime? createdAt,
    DateTime? deadline,
    bool? isCompleted,
    bool? isDismissed,
    int? priority,
    double? impactAmount,
    int? impactDays,
  }) {
    return AIAction(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      actionLabel: actionLabel ?? this.actionLabel,
      executionType: executionType ?? this.executionType,
      actionPayload: actionPayload ?? this.actionPayload,
      relatedTaskId: relatedTaskId ?? this.relatedTaskId,
      relatedVendorName: relatedVendorName ?? this.relatedVendorName,
      createdAt: createdAt ?? this.createdAt,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      isDismissed: isDismissed ?? this.isDismissed,
      priority: priority ?? this.priority,
      impactAmount: impactAmount ?? this.impactAmount,
      impactDays: impactDays ?? this.impactDays,
    );
  }

  /// 緊急度を判定
  bool get isUrgent {
    if (deadline == null) return type == AIActionType.alert;
    return DateTime.now().isAfter(deadline!.subtract(const Duration(hours: 24)));
  }

  /// 影響度のテキスト
  String? get impactText {
    if (impactAmount != null) {
      final amount = impactAmount!;
      if (amount >= 10000) {
        return '¥${(amount / 10000).toStringAsFixed(1)}万';
      }
      return '¥${amount.toStringAsFixed(0)}';
    }
    if (impactDays != null) {
      return '${impactDays}日';
    }
    return null;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AIAction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// AIアクションのフィルター
class AIActionFilter {
  final List<AIActionType>? types;
  final bool showCompleted;
  final bool showDismissed;
  final String? relatedTaskId;

  const AIActionFilter({
    this.types,
    this.showCompleted = false,
    this.showDismissed = false,
    this.relatedTaskId,
  });

  bool matches(AIAction action) {
    if (types != null && types!.isNotEmpty && !types!.contains(action.type)) {
      return false;
    }
    if (!showCompleted && action.isCompleted) {
      return false;
    }
    if (!showDismissed && action.isDismissed) {
      return false;
    }
    if (relatedTaskId != null && action.relatedTaskId != relatedTaskId) {
      return false;
    }
    return true;
  }
}

/// リスト拡張
extension AIActionListExtension on List<AIAction> {
  /// フィルタ適用
  List<AIAction> applyFilter(AIActionFilter filter) {
    return where((a) => filter.matches(a)).toList();
  }

  /// 優先度順にソート
  List<AIAction> sortByPriority() {
    return [...this]..sort((a, b) {
        // 緊急度で比較
        if (a.isUrgent && !b.isUrgent) return -1;
        if (!a.isUrgent && b.isUrgent) return 1;
        // 優先度で比較
        return b.priority.compareTo(a.priority);
      });
  }

  /// タイプ別にグループ化
  Map<AIActionType, List<AIAction>> groupByType() {
    final result = <AIActionType, List<AIAction>>{};
    for (final action in this) {
      result.putIfAbsent(action.type, () => []).add(action);
    }
    return result;
  }
}
