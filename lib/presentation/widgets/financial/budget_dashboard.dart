import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/financial_model.dart';

/// 予算ダッシュボード
///
/// プロジェクトの予算消化状況を視覚化
/// モバイルでは「今日の利益見込み」を最上部に表示
class BudgetDashboard extends StatelessWidget {
  /// 予算サマリー
  final ProjectBudgetSummary summary;

  /// 予算アイテム一覧
  final List<BudgetItem> budgetItems;

  /// コンパクト表示か（モバイル用）
  final bool compact;

  /// 詳細表示コールバック
  final VoidCallback? onViewDetails;

  const BudgetDashboard({
    super.key,
    required this.summary,
    this.budgetItems = const [],
    this.compact = false,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactDashboard();
    }
    return _buildFullDashboard();
  }

  Widget _buildCompactDashboard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            summary.isOverBudget
                ? AppColors.error.withOpacity(0.1)
                : AppColors.success.withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: summary.isOverBudget
              ? AppColors.error.withOpacity(0.3)
              : AppColors.success.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '今日の利益見込み',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              if (onViewDetails != null)
                TextButton(
                  onPressed: onViewDetails,
                  child: const Text(
                    '詳細',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatCurrency(summary.todayProfitForecast),
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: summary.todayProfitForecast >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                summary.todayProfitForecast >= 0 ? '黒字予想' : '赤字予想',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 消化率バー
          _buildConsumptionBar(),
        ],
      ),
    );
  }

  Widget _buildFullDashboard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ヘッダー
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                size: 24,
                color: AppColors.primary,
              ),
              const SizedBox(width: 12),
              Text(
                '予算管理',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (summary.isOverBudget)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: AppColors.error.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.warning_amber,
                        size: 14,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '予算超過',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // サマリーカード
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  '総予算',
                  _formatCurrency(summary.totalBudget),
                  Icons.attach_money,
                  AppColors.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  '実績',
                  _formatCurrency(summary.totalActual),
                  Icons.receipt,
                  summary.isOverBudget ? AppColors.error : AppColors.success,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  '残予算',
                  _formatCurrency(summary.remainingBudget),
                  Icons.savings,
                  summary.remainingBudget >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // 消化率
          Text(
            '予算消化率',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildConsumptionBar(),
          const SizedBox(height: 20),

          // カテゴリ別内訳
          Text(
            'カテゴリ別内訳',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...summary.categoryBreakdown.entries.map((entry) {
            return _buildCategoryRow(entry.key, entry.value);
          }),

          // 利益見込み
          if (summary.todayProfitForecast != 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: summary.todayProfitForecast >= 0
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    summary.todayProfitForecast >= 0
                        ? Icons.trending_up
                        : Icons.trending_down,
                    color: summary.todayProfitForecast >= 0
                        ? AppColors.success
                        : AppColors.error,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '利益見込み',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatCurrency(summary.todayProfitForecast),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: summary.todayProfitForecast >= 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionBar() {
    final rate = summary.consumptionRate.clamp(0.0, 150.0);
    final isOver = rate > 100;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isOver ? AppColors.error : AppColors.primary,
              ),
            ),
            if (isOver)
              Text(
                '+${_formatCurrency(summary.overage)} 超過',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.error,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.divider,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: (rate / 150).clamp(0.0, 1.0),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isOver
                        ? [AppColors.warning, AppColors.error]
                        : [AppColors.primary, AppColors.success],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
            // 100%ライン
            Positioned(
              left: 0,
              right: 0,
              child: FractionallySizedBox(
                widthFactor: 100 / 150,
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 2,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryRow(
    BudgetCategory category,
    BudgetCategorySummary categorySummary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: category.color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              category.icon,
              size: 16,
              color: category.color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      category.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${_formatCurrency(categorySummary.actual)} / ${_formatCurrency(categorySummary.budget)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: categorySummary.isOverBudget
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: (categorySummary.consumptionRate / 100)
                        .clamp(0.0, 1.0),
                    backgroundColor: AppColors.divider,
                    valueColor: AlwaysStoppedAnimation(
                      categorySummary.isOverBudget
                          ? AppColors.error
                          : category.color,
                    ),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount.abs() >= 100000000) {
      return '¥${(amount / 100000000).toStringAsFixed(1)}億';
    }
    if (amount.abs() >= 10000) {
      return '¥${(amount / 10000).toStringAsFixed(0)}万';
    }
    return '¥${amount.toStringAsFixed(0)}';
  }
}

/// 予算超過アラートカード
class BudgetOverageAlert extends StatelessWidget {
  /// 超過カテゴリ
  final BudgetCategory category;

  /// 予算額
  final double budgetAmount;

  /// 実績額
  final double actualAmount;

  /// 業者名
  final String? vendorName;

  /// 詳細表示コールバック
  final VoidCallback? onViewDetails;

  const BudgetOverageAlert({
    super.key,
    required this.category,
    required this.budgetAmount,
    required this.actualAmount,
    this.vendorName,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final overage = actualAmount - budgetAmount;
    final overageRate = ((overage / budgetAmount) * 100).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.warning.withOpacity(0.15),
            AppColors.error.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.warning_amber,
                  size: 20,
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '予算超過注意',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      '${category.label}${vendorName != null ? ' ($vendorName)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '予算を$overageRate%超過しています',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              Text(
                '+¥${(overage / 10000).toStringAsFixed(1)}万',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
            ],
          ),
          if (onViewDetails != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: onViewDetails,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.warning,
                  side: BorderSide(color: AppColors.warning),
                ),
                child: const Text('詳細を確認'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
