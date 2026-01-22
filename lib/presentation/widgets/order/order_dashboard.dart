import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/material_model.dart';
import '../common/glass_container.dart';

/// Order Dashboard Widget
/// Shows critical alerts, pending orders, and deadlines
class OrderDashboard extends StatelessWidget {
  final List<OrderAlert> alerts;
  final List<TaskConstructionMaterial> pendingMaterials;
  final List<PurchaseOrder> recentOrders;
  final Function(OrderAlert)? onAlertTap;
  final Function(TaskConstructionMaterial)? onMaterialTap;
  final Function(PurchaseOrder)? onOrderTap;
  final VoidCallback? onCreateOrder;
  final VoidCallback? onViewAllAlerts;

  const OrderDashboard({
    super.key,
    required this.alerts,
    required this.pendingMaterials,
    required this.recentOrders,
    this.onAlertTap,
    this.onMaterialTap,
    this.onOrderTap,
    this.onCreateOrder,
    this.onViewAllAlerts,
  });

  @override
  Widget build(BuildContext context) {
    final criticalAlerts = alerts.where((a) =>
      a.severity == AlertSeverity.critical || a.severity == AlertSeverity.high
    ).toList();

    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingL),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(),
          const SizedBox(height: AppConstants.paddingL),

          // Critical Alerts Banner
          if (criticalAlerts.isNotEmpty) ...[
            _buildCriticalAlertsBanner(criticalAlerts),
            const SizedBox(height: AppConstants.paddingL),
          ],

          // Main content grid
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left column: Pending Orders
                Expanded(
                  flex: 2,
                  child: _buildPendingOrdersSection(),
                ),
                const SizedBox(width: AppConstants.paddingL),

                // Right column: Alerts & Quick Actions
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildQuickActions(),
                      const SizedBox(height: AppConstants.paddingM),
                      Expanded(child: _buildAlertsSection()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final unorderedCount = pendingMaterials.where((m) => m.orderStatus == OrderStatus.notOrdered).length;
    final overdueCount = alerts.where((a) => a.type == AlertType.orderOverdue).length;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppColors.industrialGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.inventory_2_outlined,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: AppConstants.paddingM),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '発注管理ダッシュボード',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '未発注: $unorderedCount件 / 期限超過: $overdueCount件',
              style: TextStyle(
                fontSize: 12,
                color: overdueCount > 0 ? AppColors.constructionRed : AppColors.textSecondary,
                fontWeight: overdueCount > 0 ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
        const Spacer(),
        // Summary stats
        _buildStatCard('未発注', unorderedCount, AppColors.safetyYellow),
        const SizedBox(width: AppConstants.paddingM),
        _buildStatCard('発注済み', recentOrders.where((o) => o.status == OrderStatus.ordered).length, AppColors.accent),
        const SizedBox(width: AppConstants.paddingM),
        _buildStatCard('納品済み', recentOrders.where((o) => o.status == OrderStatus.delivered).length, AppColors.constructionGreen),
      ],
    );
  }

  Widget _buildStatCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'RobotoMono',
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlertsBanner(List<OrderAlert> criticalAlerts) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.constructionRed.withOpacity(0.15),
            AppColors.industrialOrange.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.constructionRed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.constructionRed.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.constructionRed,
              size: 24,
            ),
          ),
          const SizedBox(width: AppConstants.paddingM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.constructionRed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${criticalAlerts.length}件の緊急アラート',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  criticalAlerts.first.message,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onViewAllAlerts,
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('全て確認'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.constructionRed,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingOrdersSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.pending_actions, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  '発注待ち材料',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: onCreateOrder,
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('発注書作成'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // Material list
          Expanded(
            child: pendingMaterials.isEmpty
                ? const Center(
                    child: Text(
                      '発注待ちの材料はありません',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppConstants.paddingS),
                    itemCount: pendingMaterials.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _PendingMaterialCard(
                        taskMaterial: pendingMaterials[index],
                        onTap: () => onMaterialTap?.call(pendingMaterials[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: const EdgeInsets.all(AppConstants.paddingM),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'クイックアクション',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppConstants.paddingS),
          Row(
            children: [
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.note_add_outlined,
                  label: '発注書作成',
                  color: AppColors.primary,
                  onTap: onCreateOrder,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickActionButton(
                  icon: Icons.file_download_outlined,
                  label: 'CSV出力',
                  color: AppColors.constructionGreen,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlertsSection() {
    final displayAlerts = alerts.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppConstants.paddingM),
            decoration: const BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.notifications_active_outlined, color: AppColors.industrialOrange, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'アラート',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (alerts.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.industrialOrange,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${alerts.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: displayAlerts.isEmpty
                ? const Center(
                    child: Text(
                      'アラートはありません',
                      style: TextStyle(color: AppColors.textTertiary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(AppConstants.paddingS),
                    itemCount: displayAlerts.length,
                    itemBuilder: (context, index) {
                      return _AlertCard(
                        alert: displayAlerts[index],
                        onTap: () => onAlertTap?.call(displayAlerts[index]),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PendingMaterialCard extends StatelessWidget {
  final TaskConstructionMaterial taskMaterial;
  final VoidCallback? onTap;

  const _PendingMaterialCard({
    required this.taskMaterial,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final material = taskMaterial.material;
    // Mock task start date for demo
    final taskStartDate = DateTime.now().add(const Duration(days: 10));
    final daysUntil = taskMaterial.daysUntilOrderDeadline(taskStartDate);
    final isOverdue = taskMaterial.isOrderOverdue(taskStartDate);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.paddingS),
        child: Row(
          children: [
            // Urgency indicator
            Container(
              width: 4,
              height: 48,
              decoration: BoxDecoration(
                color: isOverdue
                    ? AppColors.constructionRed
                    : (daysUntil != null && daysUntil <= 3
                        ? AppColors.industrialOrange
                        : AppColors.safetyYellow),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppConstants.paddingS),
            // Material info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    material?.name ?? '不明な材料',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        material?.productCode ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '× ${taskMaterial.quantity} ${material?.unit ?? ''}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Deadline countdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (isOverdue)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.constructionRed.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      '期限超過',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.constructionRed,
                      ),
                    ),
                  )
                else if (daysUntil != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: daysUntil <= 3
                          ? AppColors.industrialOrange.withOpacity(0.15)
                          : AppColors.safetyYellow.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'あと${daysUntil}日',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: daysUntil <= 3
                            ? AppColors.industrialOrange
                            : AppColors.safetyYellow.withOpacity(0.8),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '納期: ${material?.leadTimeDays ?? 0}日',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  final OrderAlert alert;
  final VoidCallback? onTap;

  const _AlertCard({
    required this.alert,
    this.onTap,
  });

  Color get _severityColor {
    switch (alert.severity) {
      case AlertSeverity.critical:
        return AppColors.constructionRed;
      case AlertSeverity.high:
        return AppColors.industrialOrange;
      case AlertSeverity.medium:
        return AppColors.safetyYellow;
      case AlertSeverity.low:
        return AppColors.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppConstants.paddingS),
        decoration: BoxDecoration(
          color: _severityColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _severityColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(
              alert.severity == AlertSeverity.critical
                  ? Icons.error_rounded
                  : Icons.warning_amber_rounded,
              color: _severityColor,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _severityColor,
                    ),
                  ),
                  Text(
                    alert.message,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
