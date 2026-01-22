/// Delay Cost Visualization Widget
/// 遅延コスト可視化ウィジェット

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/project_health_model.dart';
import '../../../data/models/dependency_model.dart';

/// Delay cost breakdown card with bar chart
class DelayCostCard extends StatelessWidget {
  final DelayCostBreakdown costBreakdown;
  final bool showDetails;
  final VoidCallback? onTap;

  const DelayCostCard({
    super.key,
    required this.costBreakdown,
    this.showDetails = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.constructionRed.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.monetization_on,
                      color: AppColors.constructionRed,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '推定遅延コスト',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          _formatCurrency(costBreakdown.totalCost),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.constructionRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${costBreakdown.delayDays}日遅延',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '${_formatCurrency(costBreakdown.dailyRate)}/日',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              if (showDetails && costBreakdown.totalCost > 0) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Cost breakdown bars
                _buildCostBar('人件費', costBreakdown.laborCost, AppColors.primary),
                const SizedBox(height: 10),
                _buildCostBar('設備費', costBreakdown.equipmentCost, AppColors.industrialOrange),
                const SizedBox(height: 10),
                _buildCostBar('保管費', costBreakdown.materialStorageCost, AppColors.safetyYellow),
                const SizedBox(height: 10),
                _buildCostBar('諸経費', costBreakdown.overheadCost, AppColors.textSecondary),
                if (costBreakdown.penaltyCost > 0) ...[
                  const SizedBox(height: 10),
                  _buildCostBar('違約金', costBreakdown.penaltyCost, AppColors.constructionRed),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCostBar(String label, double amount, Color color) {
    final percentage = costBreakdown.totalCost > 0
        ? (amount / costBreakdown.totalCost)
        : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000000) {
      return '¥${(amount / 100000000).toStringAsFixed(1)}億';
    } else if (amount >= 10000) {
      return '¥${(amount / 10000).toStringAsFixed(0)}万';
    } else if (amount >= 1000) {
      return '¥${(amount / 1000).toStringAsFixed(1)}千';
    }
    return '¥${amount.toStringAsFixed(0)}';
  }
}

/// Delay impact visualization for specific task
class DelayImpactVisualization extends StatelessWidget {
  final String taskName;
  final DelayImpact impact;
  final DelayCostBreakdown directCost;
  final double cascadingCost;
  final List<AffectedTaskInfo> affectedTasks;

  const DelayImpactVisualization({
    super.key,
    required this.taskName,
    required this.impact,
    required this.directCost,
    required this.cascadingCost,
    this.affectedTasks = const [],
  });

  @override
  Widget build(BuildContext context) {
    final totalCost = directCost.totalCost + cascadingCost;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.constructionRed.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.constructionRed.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber,
                  color: AppColors.constructionRed,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '遅延影響シミュレーション',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.constructionRed,
                        ),
                      ),
                      Text(
                        '$taskName が ${impact.delayDays}日遅延した場合',
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
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Impact summary
                Row(
                  children: [
                    _buildImpactMetric(
                      'プロジェクト遅延',
                      '${impact.projectDelayDays}日',
                      Icons.schedule,
                    ),
                    const SizedBox(width: 16),
                    _buildImpactMetric(
                      '影響タスク',
                      '${impact.affectedTaskIds.length}件',
                      Icons.account_tree,
                    ),
                    const SizedBox(width: 16),
                    _buildImpactMetric(
                      '推定損失',
                      _formatCurrency(totalCost),
                      Icons.monetization_on,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Cost breakdown
                const Text(
                  'コスト内訳',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),

                // Waterfall chart
                _buildWaterfallChart(),

                // Affected tasks list
                if (affectedTasks.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const Text(
                    '影響を受けるタスク',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...affectedTasks.take(5).map(_buildAffectedTaskRow),
                  if (affectedTasks.length > 5)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '他 ${affectedTasks.length - 5} 件のタスク',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactMetric(String label, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.constructionRed),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.constructionRed,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterfallChart() {
    final totalCost = directCost.totalCost + cascadingCost;
    if (totalCost <= 0) {
      return const Text(
        '遅延コストなし',
        style: TextStyle(color: AppColors.textSecondary),
      );
    }

    return Column(
      children: [
        _buildCostRow('直接コスト', directCost.totalCost, totalCost, AppColors.industrialOrange),
        const SizedBox(height: 8),
        _buildCostRow('連鎖コスト', cascadingCost, totalCost, AppColors.constructionRed),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.constructionRed.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '合計推定損失',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                _formatCurrency(totalCost),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.constructionRed,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCostRow(String label, double amount, double total, Color color) {
    final percentage = total > 0 ? amount / total : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 20,
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage,
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 80,
          child: Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildAffectedTaskRow(AffectedTaskInfo task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: AppColors.constructionRed,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              task.name,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.constructionRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '+${task.delayDays}日',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.constructionRed,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 100000000) {
      return '¥${(amount / 100000000).toStringAsFixed(1)}億';
    } else if (amount >= 10000) {
      return '¥${(amount / 10000).toStringAsFixed(0)}万';
    } else if (amount >= 1000) {
      return '¥${(amount / 1000).toStringAsFixed(1)}千';
    }
    return '¥${amount.toStringAsFixed(0)}';
  }
}

/// Information about an affected task
class AffectedTaskInfo {
  final String id;
  final String name;
  final int delayDays;

  const AffectedTaskInfo({
    required this.id,
    required this.name,
    required this.delayDays,
  });
}

/// Compact delay cost indicator
class DelayCostIndicator extends StatelessWidget {
  final double totalCost;
  final int delayDays;

  const DelayCostIndicator({
    super.key,
    required this.totalCost,
    required this.delayDays,
  });

  @override
  Widget build(BuildContext context) {
    final hasCost = totalCost > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasCost
            ? AppColors.constructionRed.withOpacity(0.1)
            : AppColors.constructionGreen.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: hasCost
              ? AppColors.constructionRed.withOpacity(0.3)
              : AppColors.constructionGreen.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasCost ? Icons.trending_down : Icons.check_circle,
            color: hasCost
                ? AppColors.constructionRed
                : AppColors.constructionGreen,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '遅延コスト',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  hasCost ? _formatCurrency(totalCost) : 'なし',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: hasCost
                        ? AppColors.constructionRed
                        : AppColors.constructionGreen,
                  ),
                ),
              ],
            ),
          ),
          if (hasCost)
            Text(
              '$delayDays日',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 10000) {
      return '¥${(amount / 10000).toStringAsFixed(0)}万';
    }
    return '¥${amount.toStringAsFixed(0)}';
  }
}
