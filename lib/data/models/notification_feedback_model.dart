/// Notification Feedback Model
/// LINE通知への返信フィードバックモデル
///
/// 職人がLINE上の[了解/不可]ボタンを押した結果を
/// スプレッドシートに書き戻し、監督画面で確認状況を表示するためのモデル

import 'package:flutter/material.dart';

/// 通知の種類
enum NotificationType {
  /// スケジュール変更通知
  scheduleChange('schedule_change', 'スケジュール変更', Icons.calendar_today),

  /// 雨天中止通知
  rainCancellation('rain_cancellation', '雨天中止', Icons.umbrella),

  /// 新規タスク割り当て
  taskAssignment('task_assignment', 'タスク割り当て', Icons.assignment),

  /// リマインダー
  reminder('reminder', 'リマインダー', Icons.alarm),

  /// 緊急連絡
  urgent('urgent', '緊急連絡', Icons.warning),

  /// 一般連絡
  general('general', '一般連絡', Icons.message);

  final String value;
  final String displayName;
  final IconData icon;

  const NotificationType(this.value, this.displayName, this.icon);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NotificationType.general,
    );
  }
}

/// フィードバックのステータス
enum FeedbackStatus {
  /// 送信済み（未読）
  sent('sent', '送信済み', Color(0xFF9E9E9E)),

  /// 既読（返信待ち）
  read('read', '既読', Color(0xFF2196F3)),

  /// 了解
  acknowledged('acknowledged', '了解', Color(0xFF4CAF50)),

  /// 不可（都合がつかない）
  declined('declined', '不可', Color(0xFFF44336)),

  /// 保留（検討中）
  pending('pending', '保留', Color(0xFFFF9800)),

  /// 期限切れ（返信なし）
  expired('expired', '期限切れ', Color(0xFF795548));

  final String value;
  final String displayName;
  final Color color;

  const FeedbackStatus(this.value, this.displayName, this.color);

  static FeedbackStatus fromString(String value) {
    return FeedbackStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => FeedbackStatus.sent,
    );
  }

  /// ポジティブな返信か
  bool get isPositive => this == acknowledged;

  /// ネガティブな返信か
  bool get isNegative => this == declined || this == expired;

  /// 返信済みか
  bool get hasResponded =>
      this == acknowledged || this == declined || this == pending;
}

/// 通知フィードバック
class NotificationFeedback {
  /// フィードバックID
  final String id;

  /// 通知ID（どの通知への返信か）
  final String notificationId;

  /// プロジェクトID
  final String projectId;

  /// タスクID（関連するタスクがある場合）
  final String? taskId;

  /// 受信者のLINE UID
  final String recipientUid;

  /// 受信者名
  final String recipientName;

  /// 通知の種類
  final NotificationType notificationType;

  /// 通知メッセージ
  final String message;

  /// フィードバックステータス
  final FeedbackStatus status;

  /// 返信コメント（任意）
  final String? responseComment;

  /// 送信日時
  final DateTime sentAt;

  /// 既読日時
  final DateTime? readAt;

  /// 返信日時
  final DateTime? respondedAt;

  /// 返信期限
  final DateTime? deadline;

  const NotificationFeedback({
    required this.id,
    required this.notificationId,
    required this.projectId,
    this.taskId,
    required this.recipientUid,
    required this.recipientName,
    required this.notificationType,
    required this.message,
    required this.status,
    this.responseComment,
    required this.sentAt,
    this.readAt,
    this.respondedAt,
    this.deadline,
  });

  NotificationFeedback copyWith({
    String? id,
    String? notificationId,
    String? projectId,
    String? taskId,
    String? recipientUid,
    String? recipientName,
    NotificationType? notificationType,
    String? message,
    FeedbackStatus? status,
    String? responseComment,
    DateTime? sentAt,
    DateTime? readAt,
    DateTime? respondedAt,
    DateTime? deadline,
  }) {
    return NotificationFeedback(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      projectId: projectId ?? this.projectId,
      taskId: taskId ?? this.taskId,
      recipientUid: recipientUid ?? this.recipientUid,
      recipientName: recipientName ?? this.recipientName,
      notificationType: notificationType ?? this.notificationType,
      message: message ?? this.message,
      status: status ?? this.status,
      responseComment: responseComment ?? this.responseComment,
      sentAt: sentAt ?? this.sentAt,
      readAt: readAt ?? this.readAt,
      respondedAt: respondedAt ?? this.respondedAt,
      deadline: deadline ?? this.deadline,
    );
  }

  /// 期限切れか
  bool get isExpired {
    if (deadline == null) return false;
    if (status.hasResponded) return false;
    return DateTime.now().isAfter(deadline!);
  }

  /// 返信待ち時間（時間単位）
  int get waitingHours {
    if (status.hasResponded && respondedAt != null) {
      return respondedAt!.difference(sentAt).inHours;
    }
    return DateTime.now().difference(sentAt).inHours;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'notificationId': notificationId,
        'projectId': projectId,
        'taskId': taskId,
        'recipientUid': recipientUid,
        'recipientName': recipientName,
        'notificationType': notificationType.value,
        'message': message,
        'status': status.value,
        'responseComment': responseComment,
        'sentAt': sentAt.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
        'respondedAt': respondedAt?.toIso8601String(),
        'deadline': deadline?.toIso8601String(),
      };

  factory NotificationFeedback.fromJson(Map<String, dynamic> json) {
    return NotificationFeedback(
      id: json['id'] as String,
      notificationId: json['notificationId'] as String,
      projectId: json['projectId'] as String,
      taskId: json['taskId'] as String?,
      recipientUid: json['recipientUid'] as String,
      recipientName: json['recipientName'] as String,
      notificationType:
          NotificationType.fromString(json['notificationType'] as String),
      message: json['message'] as String,
      status: FeedbackStatus.fromString(json['status'] as String),
      responseComment: json['responseComment'] as String?,
      sentAt: DateTime.parse(json['sentAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : null,
      deadline: json['deadline'] != null
          ? DateTime.parse(json['deadline'] as String)
          : null,
    );
  }
}

/// 通知バッチ（一括送信）
class NotificationBatch {
  /// バッチID
  final String id;

  /// プロジェクトID
  final String projectId;

  /// 通知の種類
  final NotificationType type;

  /// 通知メッセージ
  final String message;

  /// 送信日時
  final DateTime sentAt;

  /// 送信者名（監督名）
  final String senderName;

  /// フィードバックリスト
  final List<NotificationFeedback> feedbacks;

  const NotificationBatch({
    required this.id,
    required this.projectId,
    required this.type,
    required this.message,
    required this.sentAt,
    required this.senderName,
    required this.feedbacks,
  });

  /// 総送信数
  int get totalCount => feedbacks.length;

  /// 了解数
  int get acknowledgedCount =>
      feedbacks.where((f) => f.status == FeedbackStatus.acknowledged).length;

  /// 不可数
  int get declinedCount =>
      feedbacks.where((f) => f.status == FeedbackStatus.declined).length;

  /// 未返信数
  int get pendingCount =>
      feedbacks.where((f) => !f.status.hasResponded).length;

  /// 完了率（%）
  double get completionRate {
    if (feedbacks.isEmpty) return 0;
    final responded = feedbacks.where((f) => f.status.hasResponded).length;
    return (responded / feedbacks.length) * 100;
  }

  /// 全員返信済みか
  bool get isAllResponded => pendingCount == 0;

  /// 問題ありか（不可や期限切れがある）
  bool get hasIssues =>
      feedbacks.any((f) => f.status.isNegative || f.isExpired);

  /// ステータスサマリ
  String get statusSummary {
    if (isAllResponded) {
      if (declinedCount == 0) {
        return '✅ 全員了解';
      } else {
        return '⚠️ $declinedCount名が不可';
      }
    } else {
      return '⏳ $pendingCount名が未返信';
    }
  }
}

/// 通知ダッシュボードサマリ
class NotificationDashboardSummary {
  /// 本日の送信数
  final int todaySentCount;

  /// 未返信数
  final int pendingCount;

  /// 了解率（%）
  final double acknowledgeRate;

  /// 平均返信時間（時間）
  final double avgResponseHours;

  /// 期限切れ数
  final int expiredCount;

  /// 不可数
  final int declinedCount;

  const NotificationDashboardSummary({
    required this.todaySentCount,
    required this.pendingCount,
    required this.acknowledgeRate,
    required this.avgResponseHours,
    required this.expiredCount,
    required this.declinedCount,
  });

  /// 健全性スコア（0-100）
  int get healthScore {
    // 了解率が高く、未返信・期限切れ・不可が少ないほど高スコア
    double score = acknowledgeRate;
    score -= (pendingCount * 2);
    score -= (expiredCount * 5);
    score -= (declinedCount * 3);
    return score.clamp(0, 100).round();
  }

  /// ステータスラベル
  String get statusLabel {
    if (healthScore >= 80) return '良好';
    if (healthScore >= 60) return '普通';
    if (healthScore >= 40) return '注意';
    return '要対応';
  }

  /// ステータス色
  Color get statusColor {
    if (healthScore >= 80) return const Color(0xFF4CAF50);
    if (healthScore >= 60) return const Color(0xFF2196F3);
    if (healthScore >= 40) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }
}

/// LINEボタンアクション（Flex Message用）
class LineButtonAction {
  final String label;
  final FeedbackStatus resultStatus;
  final Color color;

  const LineButtonAction({
    required this.label,
    required this.resultStatus,
    required this.color,
  });

  /// 標準のアクションボタンセット
  static List<LineButtonAction> get standardActions => [
        const LineButtonAction(
          label: '了解',
          resultStatus: FeedbackStatus.acknowledged,
          color: Color(0xFF4CAF50),
        ),
        const LineButtonAction(
          label: '不可',
          resultStatus: FeedbackStatus.declined,
          color: Color(0xFFF44336),
        ),
      ];

  /// 3択アクション（保留あり）
  static List<LineButtonAction> get threeWayActions => [
        const LineButtonAction(
          label: '了解',
          resultStatus: FeedbackStatus.acknowledged,
          color: Color(0xFF4CAF50),
        ),
        const LineButtonAction(
          label: '保留',
          resultStatus: FeedbackStatus.pending,
          color: Color(0xFFFF9800),
        ),
        const LineButtonAction(
          label: '不可',
          resultStatus: FeedbackStatus.declined,
          color: Color(0xFFF44336),
        ),
      ];
}
