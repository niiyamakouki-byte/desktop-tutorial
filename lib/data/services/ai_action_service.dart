import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/ai_action_model.dart';
import '../models/models.dart';

/// AIアクションサービス
///
/// AIが提案するアクションを生成・管理する
/// 工程遅延、コスト超過、リスク検知を自動で行う
class AIActionService extends ChangeNotifier {
  /// シングルトンインスタンス
  static final AIActionService _instance = AIActionService._internal();
  factory AIActionService() => _instance;
  AIActionService._internal();

  /// アクションキャッシュ
  final List<AIAction> _actions = [];

  /// 現在のアクション一覧（読み取り専用）
  List<AIAction> get actions => List.unmodifiable(_actions);

  /// アクティブなアクション（未完了・未却下）
  List<AIAction> get activeActions =>
      _actions.where((a) => !a.isCompleted && !a.isDismissed).toList();

  /// 緊急アクション
  List<AIAction> get urgentActions =>
      activeActions.where((a) => a.isUrgent).toList();

  /// タスクに関連するアクション
  List<AIAction> getActionsForTask(String taskId) {
    return _actions.where((a) => a.relatedTaskId == taskId).toList();
  }

  /// アクションを完了としてマーク
  void markCompleted(String actionId) {
    final index = _actions.indexWhere((a) => a.id == actionId);
    if (index >= 0) {
      _actions[index] = _actions[index].copyWith(isCompleted: true);
      notifyListeners();
    }
  }

  /// アクションを却下としてマーク
  void dismissAction(String actionId) {
    final index = _actions.indexWhere((a) => a.id == actionId);
    if (index >= 0) {
      _actions[index] = _actions[index].copyWith(isDismissed: true);
      notifyListeners();
    }
  }

  /// タスク一覧からAIアクションを生成
  Future<void> analyzeTasksAndGenerateActions(List<Task> tasks) async {
    _actions.clear();

    final now = DateTime.now();

    for (final task in tasks) {
      // 遅延検知
      if (task.delayStatus == DelayStatus.overdue) {
        _actions.add(_generateDelayAlert(task, now));
      }

      // リスク検知
      if (task.delayStatus == DelayStatus.atRisk) {
        _actions.add(_generateRiskWarning(task, now));
      }

      // 待ち状態検知
      if (task.delayStatus == DelayStatus.blocked) {
        _actions.add(_generateBlockedSuggestion(task, now));
      }
    }

    // デモ用の追加アクション
    _addDemoActions(now);

    notifyListeners();
  }

  /// 遅延アラートを生成
  AIAction _generateDelayAlert(Task task, DateTime now) {
    final daysOverdue = task.daysOverdue;
    final vendor = task.contractorName ?? '担当業者';

    return AIAction(
      id: 'alert_delay_${task.id}',
      title: '[遅延リスク] ${task.name}が${daysOverdue}日遅延',
      description: '$vendorの工程が遅延しています。後続工程に影響が出る前に、'
          '日程調整の連絡をしますか？',
      type: AIActionType.alert,
      actionLabel: '$vendorにLINEで連絡',
      executionType: ActionExecutionType.sendLine,
      actionPayload: {
        'taskId': task.id,
        'vendorName': vendor,
        'message': '【日程調整のお願い】\n${task.name}について、'
            '現在${daysOverdue}日の遅延が発生しています。\n'
            '予定の調整をお願いできますでしょうか。',
      },
      relatedTaskId: task.id,
      relatedVendorName: vendor,
      createdAt: now,
      deadline: now.add(const Duration(hours: 24)),
      priority: 90 + daysOverdue,
      impactDays: daysOverdue,
    );
  }

  /// リスク警告を生成
  AIAction _generateRiskWarning(Task task, DateTime now) {
    final daysRemaining = task.daysRemaining;
    final progress = (task.progress * 100).round();

    return AIAction(
      id: 'warning_risk_${task.id}',
      title: '[進捗注意] ${task.name}の進捗が遅れています',
      description: '期限まで${daysRemaining}日ですが、進捗は$progress%です。'
          '予定通りの完了が難しい可能性があります。',
      type: AIActionType.warning,
      actionLabel: '詳細を確認',
      executionType: ActionExecutionType.viewDetails,
      actionPayload: {
        'taskId': task.id,
      },
      relatedTaskId: task.id,
      createdAt: now,
      priority: 70,
      impactDays: daysRemaining,
    );
  }

  /// 待ち状態提案を生成
  AIAction _generateBlockedSuggestion(Task task, DateTime now) {
    final reason = task.blockingReason?.displayName ?? '不明な理由';

    String actionLabel;
    ActionExecutionType executionType;

    switch (task.blockingReason) {
      case BlockingReason.material:
        actionLabel = '発注状況を確認';
        executionType = ActionExecutionType.viewDetails;
        break;
      case BlockingReason.approval:
        actionLabel = '承認を依頼';
        executionType = ActionExecutionType.sendLine;
        break;
      case BlockingReason.clientConfirmation:
        actionLabel = '施主に確認連絡';
        executionType = ActionExecutionType.call;
        break;
      case BlockingReason.predecessor:
        actionLabel = '前工程を確認';
        executionType = ActionExecutionType.viewDetails;
        break;
      default:
        actionLabel = '詳細を確認';
        executionType = ActionExecutionType.viewDetails;
    }

    return AIAction(
      id: 'suggestion_blocked_${task.id}',
      title: '[待ち状態] ${task.name} - $reason',
      description: 'このタスクは「$reason」で待機中です。'
          '解消のためのアクションを取りますか？',
      type: AIActionType.suggestion,
      actionLabel: actionLabel,
      executionType: executionType,
      actionPayload: {
        'taskId': task.id,
        'blockingReason': task.blockingReason?.value,
      },
      relatedTaskId: task.id,
      createdAt: now,
      priority: 60,
    );
  }

  /// デモ用アクションを追加
  void _addDemoActions(DateTime now) {
    // コスト警告デモ
    _actions.add(AIAction(
      id: 'demo_cost_warning',
      title: '[コスト警告] 塗装工事の請求が予算超過',
      description: 'A資材店からの請求額が予算を5%（¥45,000）超過しています。'
          '詳細を確認して、予算調整が必要か検討してください。',
      type: AIActionType.warning,
      actionLabel: '詳細を確認',
      executionType: ActionExecutionType.viewDetails,
      actionPayload: {
        'categoryId': 'painting',
        'budgetAmount': 900000,
        'actualAmount': 945000,
        'vendorName': 'A資材店',
      },
      relatedVendorName: 'A資材店',
      createdAt: now.subtract(const Duration(hours: 2)),
      priority: 75,
      impactAmount: 45000,
    ));

    // 天候リスク提案
    _actions.add(AIAction(
      id: 'demo_weather_suggestion',
      title: '[天気予報] 明後日から3日間の降水予報',
      description: '外構工事に影響が出る可能性があります。'
          '該当タスクの日程を事前に調整しますか？',
      type: AIActionType.suggestion,
      actionLabel: '日程調整を検討',
      executionType: ActionExecutionType.reschedule,
      actionPayload: {
        'weatherForecast': 'rain',
        'affectedDays': 3,
        'startDate': now.add(const Duration(days: 2)).toIso8601String(),
      },
      createdAt: now.subtract(const Duration(hours: 1)),
      priority: 65,
      impactDays: 3,
    ));

    // 人件費増加予測
    _actions.add(AIAction(
      id: 'demo_labor_cost',
      title: '[コスト予測] 工期延長による人件費増加',
      description: '現在の遅延（合計5日）が継続した場合、'
          '人件費が約¥150,000増加する見込みです。',
      type: AIActionType.warning,
      actionLabel: '対策を検討',
      executionType: ActionExecutionType.viewDetails,
      actionPayload: {
        'totalDelayDays': 5,
        'laborCostPerDay': 30000,
        'estimatedIncrease': 150000,
      },
      createdAt: now.subtract(const Duration(minutes: 30)),
      priority: 70,
      impactAmount: 150000,
    ));

    // 見積依頼提案
    _actions.add(AIAction(
      id: 'demo_rfq_suggestion',
      title: '[提案] 電気工事の見積取得',
      description: '来週開始予定の電気工事について、'
          '複数業者への見積依頼がまだ完了していません。',
      type: AIActionType.suggestion,
      actionLabel: '見積依頼を送信',
      executionType: ActionExecutionType.sendLine,
      actionPayload: {
        'taskCategory': 'electrical',
        'vendors': ['田中電気', 'ABC電設', 'スマート電工'],
      },
      createdAt: now.subtract(const Duration(hours: 4)),
      priority: 55,
    ));
  }

  /// デモデータで初期化
  void initializeDemoData() {
    final now = DateTime.now();
    _actions.clear();
    _addDemoActions(now);
    notifyListeners();
  }

  /// 工程遅延によるコスト影響を計算
  ///
  /// [delayDays] 遅延日数
  /// [laborCostPerDay] 1日あたりの人件費
  Map<String, dynamic> calculateDelayImpact({
    required int delayDays,
    double laborCostPerDay = 30000,
    double materialStorageCost = 5000,
    double overheadPerDay = 10000,
  }) {
    final laborCost = delayDays * laborCostPerDay;
    final storageCost = delayDays * materialStorageCost;
    final overhead = delayDays * overheadPerDay;
    final totalCost = laborCost + storageCost + overhead;

    return {
      'delayDays': delayDays,
      'laborCost': laborCost,
      'storageCost': storageCost,
      'overheadCost': overhead,
      'totalCost': totalCost,
      'breakdown': {
        '人件費増加': laborCost,
        '資材保管費': storageCost,
        '間接費': overhead,
      },
    };
  }

  /// アクションをクリア
  void clearActions() {
    _actions.clear();
    notifyListeners();
  }
}
