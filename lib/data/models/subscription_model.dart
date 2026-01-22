/// Subscription Model
/// サブスクリプション・課金モデル
///
/// Geminiビジネスレビューに基づく設計:
/// - 「現場ごと課金」はNG → 「ユーザー数による従量課金」または「月額固定SaaS」
/// - 「3現場目から有料」という制限が現実的
/// - 1〜2現場は全機能開放で依存状態を作ってから課金

import 'package:flutter/material.dart';

/// プランタイプ
enum PlanType {
  /// 無料プラン（2現場まで）
  free('free', 'フリー', 0),

  /// スタータープラン（5現場まで）
  starter('starter', 'スターター', 5000),

  /// プロフェッショナルプラン（20現場まで）
  professional('professional', 'プロフェッショナル', 15000),

  /// エンタープライズプラン（無制限）
  enterprise('enterprise', 'エンタープライズ', 50000);

  final String value;
  final String displayName;

  /// 月額料金（円）
  final int monthlyPriceYen;

  const PlanType(this.value, this.displayName, this.monthlyPriceYen);

  static PlanType fromString(String value) {
    return PlanType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PlanType.free,
    );
  }

  /// プランの色
  Color get color {
    switch (this) {
      case PlanType.free:
        return const Color(0xFF9E9E9E);
      case PlanType.starter:
        return const Color(0xFF4CAF50);
      case PlanType.professional:
        return const Color(0xFF2196F3);
      case PlanType.enterprise:
        return const Color(0xFF9C27B0);
    }
  }

  /// プランのアイコン
  IconData get icon {
    switch (this) {
      case PlanType.free:
        return Icons.card_giftcard;
      case PlanType.starter:
        return Icons.rocket_launch;
      case PlanType.professional:
        return Icons.workspace_premium;
      case PlanType.enterprise:
        return Icons.diamond;
    }
  }
}

/// プラン制限
class PlanLimits {
  /// 最大プロジェクト数
  final int maxProjects;

  /// 最大ユーザー数
  final int maxUsers;

  /// 最大ストレージ（GB）
  final int maxStorageGb;

  /// LINE通知数/月
  final int maxLineNotificationsPerMonth;

  /// エクスポート機能
  final bool canExport;

  /// API連携
  final bool canUseApi;

  /// カスタムレポート
  final bool canCustomReport;

  /// 優先サポート
  final bool hasPrioritySupport;

  const PlanLimits({
    required this.maxProjects,
    required this.maxUsers,
    required this.maxStorageGb,
    required this.maxLineNotificationsPerMonth,
    required this.canExport,
    required this.canUseApi,
    required this.canCustomReport,
    required this.hasPrioritySupport,
  });

  /// プランごとのデフォルト制限
  factory PlanLimits.forPlan(PlanType plan) {
    switch (plan) {
      case PlanType.free:
        return const PlanLimits(
          maxProjects: 2,
          maxUsers: 5,
          maxStorageGb: 1,
          maxLineNotificationsPerMonth: 200, // LINE無料枠
          canExport: false,
          canUseApi: false,
          canCustomReport: false,
          hasPrioritySupport: false,
        );

      case PlanType.starter:
        return const PlanLimits(
          maxProjects: 5,
          maxUsers: 20,
          maxStorageGb: 10,
          maxLineNotificationsPerMonth: 1000,
          canExport: true,
          canUseApi: false,
          canCustomReport: false,
          hasPrioritySupport: false,
        );

      case PlanType.professional:
        return const PlanLimits(
          maxProjects: 20,
          maxUsers: 100,
          maxStorageGb: 50,
          maxLineNotificationsPerMonth: 5000,
          canExport: true,
          canUseApi: true,
          canCustomReport: true,
          hasPrioritySupport: true,
        );

      case PlanType.enterprise:
        return const PlanLimits(
          maxProjects: -1, // 無制限
          maxUsers: -1, // 無制限
          maxStorageGb: -1, // 無制限
          maxLineNotificationsPerMonth: -1, // 無制限
          canExport: true,
          canUseApi: true,
          canCustomReport: true,
          hasPrioritySupport: true,
        );
    }
  }

  /// プロジェクト数が制限内か
  bool isProjectCountAllowed(int count) {
    if (maxProjects == -1) return true;
    return count <= maxProjects;
  }

  /// ユーザー数が制限内か
  bool isUserCountAllowed(int count) {
    if (maxUsers == -1) return true;
    return count <= maxUsers;
  }
}

/// サブスクリプション
class Subscription {
  /// サブスクリプションID
  final String id;

  /// 組織ID
  final String organizationId;

  /// プランタイプ
  final PlanType plan;

  /// ステータス
  final SubscriptionStatus status;

  /// 開始日
  final DateTime startDate;

  /// 次回請求日
  final DateTime? nextBillingDate;

  /// キャンセル日
  final DateTime? cancelledAt;

  /// 現在のプロジェクト数
  final int currentProjectCount;

  /// 現在のユーザー数
  final int currentUserCount;

  /// 今月の通知送信数
  final int currentMonthNotifications;

  /// トライアル期間中か
  final bool isTrial;

  /// トライアル終了日
  final DateTime? trialEndDate;

  const Subscription({
    required this.id,
    required this.organizationId,
    required this.plan,
    required this.status,
    required this.startDate,
    this.nextBillingDate,
    this.cancelledAt,
    this.currentProjectCount = 0,
    this.currentUserCount = 0,
    this.currentMonthNotifications = 0,
    this.isTrial = false,
    this.trialEndDate,
  });

  /// プランの制限
  PlanLimits get limits => PlanLimits.forPlan(plan);

  /// プロジェクトを追加できるか
  bool get canAddProject => limits.isProjectCountAllowed(currentProjectCount + 1);

  /// ユーザーを追加できるか
  bool get canAddUser => limits.isUserCountAllowed(currentUserCount + 1);

  /// 通知を送信できるか
  bool get canSendNotification {
    if (limits.maxLineNotificationsPerMonth == -1) return true;
    return currentMonthNotifications < limits.maxLineNotificationsPerMonth;
  }

  /// 残り通知数
  int get remainingNotifications {
    if (limits.maxLineNotificationsPerMonth == -1) return -1;
    return limits.maxLineNotificationsPerMonth - currentMonthNotifications;
  }

  /// アップグレードが必要か
  bool get needsUpgrade {
    return !canAddProject || !canAddUser || !canSendNotification;
  }

  /// 推奨アップグレード先
  PlanType? get recommendedUpgrade {
    if (!needsUpgrade) return null;

    final neededProjects = currentProjectCount + 1;
    final neededUsers = currentUserCount + 1;

    for (final plan in PlanType.values) {
      if (plan.index <= this.plan.index) continue;

      final limits = PlanLimits.forPlan(plan);
      if (limits.isProjectCountAllowed(neededProjects) &&
          limits.isUserCountAllowed(neededUsers)) {
        return plan;
      }
    }

    return PlanType.enterprise;
  }

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      organizationId: json['organizationId'] as String,
      plan: PlanType.fromString(json['plan'] as String),
      status: SubscriptionStatus.fromString(json['status'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      nextBillingDate: json['nextBillingDate'] != null
          ? DateTime.parse(json['nextBillingDate'] as String)
          : null,
      cancelledAt: json['cancelledAt'] != null
          ? DateTime.parse(json['cancelledAt'] as String)
          : null,
      currentProjectCount: json['currentProjectCount'] as int? ?? 0,
      currentUserCount: json['currentUserCount'] as int? ?? 0,
      currentMonthNotifications: json['currentMonthNotifications'] as int? ?? 0,
      isTrial: json['isTrial'] as bool? ?? false,
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.parse(json['trialEndDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'organizationId': organizationId,
        'plan': plan.value,
        'status': status.value,
        'startDate': startDate.toIso8601String(),
        'nextBillingDate': nextBillingDate?.toIso8601String(),
        'cancelledAt': cancelledAt?.toIso8601String(),
        'currentProjectCount': currentProjectCount,
        'currentUserCount': currentUserCount,
        'currentMonthNotifications': currentMonthNotifications,
        'isTrial': isTrial,
        'trialEndDate': trialEndDate?.toIso8601String(),
      };
}

/// サブスクリプションステータス
enum SubscriptionStatus {
  /// アクティブ
  active('active', '有効'),

  /// トライアル
  trial('trial', 'トライアル'),

  /// 支払い保留
  pastDue('past_due', '支払い保留'),

  /// キャンセル済み
  cancelled('cancelled', 'キャンセル済み'),

  /// 期限切れ
  expired('expired', '期限切れ');

  final String value;
  final String displayName;

  const SubscriptionStatus(this.value, this.displayName);

  static SubscriptionStatus fromString(String value) {
    return SubscriptionStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => SubscriptionStatus.expired,
    );
  }

  bool get isActive =>
      this == SubscriptionStatus.active || this == SubscriptionStatus.trial;
}

/// 使用量統計
class UsageStats {
  /// 今月のプロジェクト数
  final int projectCount;

  /// 今月のユーザー数
  final int userCount;

  /// 今月の通知送信数
  final int notificationCount;

  /// 今月のストレージ使用量（MB）
  final int storageUsedMb;

  /// 今月のAPI呼び出し数
  final int apiCallCount;

  const UsageStats({
    required this.projectCount,
    required this.userCount,
    required this.notificationCount,
    required this.storageUsedMb,
    required this.apiCallCount,
  });

  factory UsageStats.fromJson(Map<String, dynamic> json) {
    return UsageStats(
      projectCount: json['projectCount'] as int? ?? 0,
      userCount: json['userCount'] as int? ?? 0,
      notificationCount: json['notificationCount'] as int? ?? 0,
      storageUsedMb: json['storageUsedMb'] as int? ?? 0,
      apiCallCount: json['apiCallCount'] as int? ?? 0,
    );
  }
}

/// ROI計算（営業トーク用）
/// 「職人の手待ち日当（1日2〜3万円）を1回防ぐだけで月額料金の元が取れる」
class RoiCalculator {
  /// 1日あたりの職人日当（円）
  static const int dailyWorkerWage = 25000;

  /// 手待ちによる機会損失
  static int calculateIdleLoss({
    required int idleDays,
    required int workerCount,
  }) {
    return dailyWorkerWage * idleDays * workerCount;
  }

  /// ROI（投資対効果）を計算
  static double calculateRoi({
    required PlanType plan,
    required int preventedIdleDays,
    required int workerCount,
  }) {
    final monthlyCost = plan.monthlyPriceYen;
    if (monthlyCost == 0) return double.infinity;

    final savings = calculateIdleLoss(
      idleDays: preventedIdleDays,
      workerCount: workerCount,
    );

    return savings / monthlyCost;
  }

  /// 元が取れるまでの日数
  static int daysToBreakEven({
    required PlanType plan,
    required int workerCount,
  }) {
    final monthlyCost = plan.monthlyPriceYen;
    if (monthlyCost == 0) return 0;

    final dailySavings = dailyWorkerWage * workerCount;
    return (monthlyCost / dailySavings).ceil();
  }

  /// 営業メッセージを生成
  static String generateSalesPitch({
    required PlanType plan,
    required int workerCount,
  }) {
    final breakEvenDays = daysToBreakEven(plan: plan, workerCount: workerCount);

    if (plan == PlanType.free) {
      return 'まずは2現場まで無料でお試しください。';
    }

    return '月額${plan.monthlyPriceYen.toStringAsFixed(0)}円で、'
        '職人${workerCount}人の手待ちを${breakEvenDays}日防ぐだけで元が取れます。';
  }
}
