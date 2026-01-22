import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/ai_action_model.dart';

/// AIアクションカード
///
/// AIが提案するアクションをカード形式で表示
/// ワンタップでアクションを実行できる
/// 現場向けに大きなタッチターゲット（48px以上）を確保
class AIActionCard extends StatefulWidget {
  /// 表示するアクション
  final AIAction action;

  /// アクション実行時のコールバック
  final Function(AIAction action)? onAction;

  /// 却下時のコールバック
  final Function(AIAction action)? onDismiss;

  /// 詳細表示時のコールバック
  final Function(AIAction action)? onViewDetails;

  /// コンパクト表示か
  final bool compact;

  const AIActionCard({
    super.key,
    required this.action,
    this.onAction,
    this.onDismiss,
    this.onViewDetails,
    this.compact = false,
  });

  @override
  State<AIActionCard> createState() => _AIActionCardState();
}

class _AIActionCardState extends State<AIActionCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _animationController.reverse();
  }

  void _executeAction() {
    // 触覚フィードバック
    HapticFeedback.mediumImpact();
    widget.onAction?.call(widget.action);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactCard();
    }
    return _buildFullCard();
  }

  Widget _buildFullCard() {
    final action = widget.action;
    final type = action.type;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  type.color.withOpacity(0.15),
                  type.color.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: type.color.withOpacity(action.isUrgent ? 0.6 : 0.3),
                width: action.isUrgent ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: type.color.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onViewDetails != null
                      ? () => widget.onViewDetails!(action)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ヘッダー（アイコン + タイプ + 緊急バッジ）
                        Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: type.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                type.icon,
                                size: 20,
                                color: type.color,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: type.color,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                type.label,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            if (action.isUrgent) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 10,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 2),
                                    Text(
                                      '緊急',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            // 影響度表示
                            if (action.impactText != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  action.impactText!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: type.color,
                                  ),
                                ),
                              ),
                            // 却下ボタン
                            if (widget.onDismiss != null)
                              IconButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  widget.onDismiss!(action);
                                },
                                icon: const Icon(Icons.close, size: 18),
                                color: AppColors.textTertiary,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // タイトル
                        Text(
                          action.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // 説明
                        Text(
                          action.description,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // アクションボタン（現場向けに大きく）
                        GestureDetector(
                          onTapDown: _handleTapDown,
                          onTapUp: _handleTapUp,
                          onTapCancel: _handleTapCancel,
                          onTap: _executeAction,
                          child: Container(
                            width: double.infinity,
                            height: 52, // 現場向けに大きなタッチターゲット
                            decoration: BoxDecoration(
                              color: type.color,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: type.color.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  action.executionType.icon,
                                  size: 20,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  action.actionLabel,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // 関連情報
                        if (action.relatedVendorName != null ||
                            action.relatedTaskId != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              if (action.relatedVendorName != null) ...[
                                Icon(
                                  Icons.business,
                                  size: 12,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  action.relatedVendorName!,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary,
                                  ),
                                ),
                                const SizedBox(width: 12),
                              ],
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _formatTimeAgo(action.createdAt),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompactCard() {
    final action = widget.action;
    final type = action.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: type.color.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _executeAction,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: type.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    type.icon,
                    size: 16,
                    color: type.color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        action.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        action.actionLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: type.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: type.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'たった今';
    if (diff.inMinutes < 60) return '${diff.inMinutes}分前';
    if (diff.inHours < 24) return '${diff.inHours}時間前';
    return '${diff.inDays}日前';
  }
}

/// AIアクションリスト
///
/// 複数のAIアクションをリスト表示
class AIActionList extends StatelessWidget {
  /// 表示するアクション一覧
  final List<AIAction> actions;

  /// アクション実行時のコールバック
  final Function(AIAction action)? onAction;

  /// 却下時のコールバック
  final Function(AIAction action)? onDismiss;

  /// 詳細表示時のコールバック
  final Function(AIAction action)? onViewDetails;

  /// 最大表示件数
  final int maxItems;

  /// コンパクト表示か
  final bool compact;

  /// 空の時のウィジェット
  final Widget? emptyWidget;

  const AIActionList({
    super.key,
    required this.actions,
    this.onAction,
    this.onDismiss,
    this.onViewDetails,
    this.maxItems = 10,
    this.compact = false,
    this.emptyWidget,
  });

  @override
  Widget build(BuildContext context) {
    final sortedActions = actions.sortByPriority().take(maxItems).toList();

    if (sortedActions.isEmpty) {
      return emptyWidget ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 48,
                    color: AppColors.success.withOpacity(0.5),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '対応が必要な提案はありません',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedActions.length,
      itemBuilder: (context, index) {
        return AIActionCard(
          action: sortedActions[index],
          onAction: onAction,
          onDismiss: onDismiss,
          onViewDetails: onViewDetails,
          compact: compact,
        );
      },
    );
  }
}

/// AIアクションサマリーバー
///
/// 緊急アクションの件数をバーで表示
class AIActionSummaryBar extends StatelessWidget {
  /// アクション一覧
  final List<AIAction> actions;

  /// タップ時のコールバック
  final VoidCallback? onTap;

  const AIActionSummaryBar({
    super.key,
    required this.actions,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final activeActions =
        actions.where((a) => !a.isCompleted && !a.isDismissed).toList();
    final urgentCount = activeActions.where((a) => a.isUrgent).length;
    final alertCount =
        activeActions.where((a) => a.type == AIActionType.alert).length;
    final warningCount =
        activeActions.where((a) => a.type == AIActionType.warning).length;

    if (activeActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: urgentCount > 0
                ? [
                    AppColors.error.withOpacity(0.15),
                    AppColors.warning.withOpacity(0.1),
                  ]
                : [
                    AppColors.warning.withOpacity(0.1),
                    AppColors.info.withOpacity(0.05),
                  ],
          ),
          border: Border(
            bottom: BorderSide(color: AppColors.divider),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: urgentCount > 0
                    ? AppColors.error.withOpacity(0.15)
                    : AppColors.warning.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.auto_awesome,
                size: 18,
                color: urgentCount > 0 ? AppColors.error : AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'AI 推奨',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${activeActions.length}件の対応推奨',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (alertCount > 0) ...[
                        _buildCountChip(
                          'アラート',
                          alertCount,
                          AppColors.error,
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (warningCount > 0) ...[
                        _buildCountChip(
                          '注意',
                          warningCount,
                          AppColors.warning,
                        ),
                        const SizedBox(width: 8),
                      ],
                      _buildCountChip(
                        '提案',
                        activeActions.length - alertCount - warningCount,
                        AppColors.info,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountChip(String label, int count, Color color) {
    if (count <= 0) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$label $count',
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
